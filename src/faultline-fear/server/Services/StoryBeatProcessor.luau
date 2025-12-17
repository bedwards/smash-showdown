--!strict
--[[
	Faultline Fear: Story Beat Processor

	The runtime engine that processes all story beats.
	Listens for triggers (zone entry, object collection, events)
	and executes effects (complete objectives, play dialogue, etc.)

	This is the bridge between StoryData and actual gameplay.

	Exports: Initialize(), ProcessTrigger(), FireEvent()
	Depends: StoryData, NarrativeService, CollectionService
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local StoryData = Shared.StoryData

local StoryBeatProcessor = {}

-- State
local triggeredBeats: { [Player]: { [string]: boolean } } = {}
local globalTriggeredBeats: { [string]: boolean } = {}
local timerBeats: { [string]: { startTime: number, beat: StoryData.StoryBeat } } = {}

-- Service references (set during initialization)
local NarrativeService: any = nil

-- Debounce tracking
local lastTriggerTime: { [string]: number } = {}
local DEBOUNCE_TIME = 0.5

-- ==========================================
-- TRIGGER MATCHING
-- ==========================================

local function matchesTriggerData(beatData: any, triggerData: any): boolean
	-- Check each field in beatData against triggerData
	if beatData.zoneId and beatData.zoneId ~= triggerData.zoneId then
		return false
	end
	if beatData.objectTag and beatData.objectTag ~= triggerData.objectTag then
		return false
	end
	if beatData.npcId and beatData.npcId ~= triggerData.npcId then
		return false
	end
	if beatData.eventId and beatData.eventId ~= triggerData.eventId then
		return false
	end
	return true
end

-- ==========================================
-- CONDITION CHECKING
-- ==========================================

local function checkConditions(conditions: any, player: Player): boolean
	if not NarrativeService then
		return true
	end

	-- Check completed objectives
	if conditions.objectivesComplete then
		for _, objectiveId in ipairs(conditions.objectivesComplete) do
			if not NarrativeService:IsObjectiveComplete(player, objectiveId) then
				return false
			end
		end
	end

	-- Check survivors rescued
	if conditions.survivorsRescued then
		if NarrativeService:GetSurvivorsRescued(player) < conditions.survivorsRescued then
			return false
		end
	end

	-- Check generator parts
	if conditions.generatorParts then
		if NarrativeService:GetGeneratorPartsCollected(player) < conditions.generatorParts then
			return false
		end
	end

	-- Check time of day (would need DayNightService reference)
	-- if conditions.timeOfDay then ... end

	return true
end

-- ==========================================
-- BEAT EXECUTION
-- ==========================================

local function executeBeat(beat: StoryData.StoryBeat, player: Player)
	if not NarrativeService then
		warn("[StoryBeatProcessor] NarrativeService not set!")
		return
	end

	local effects = beat.effects

	-- Complete objective
	if effects.completeObjective then
		NarrativeService:CompleteObjective(player, effects.completeObjective, 1)
	end

	-- Play dialogue
	if effects.playDialogue then
		NarrativeService:PlayDialogue(player, effects.playDialogue)
	end

	-- Trigger event (can cascade to other beats)
	if effects.triggerEvent then
		-- Fire to all players if global, otherwise just this player
		if beat.globalTrigger then
			for _, p in ipairs(Players:GetPlayers()) do
				StoryBeatProcessor:FireEvent(effects.triggerEvent, p)
			end
		else
			StoryBeatProcessor:FireEvent(effects.triggerEvent, player)
		end
	end

	-- Advance act
	if effects.advanceAct then
		NarrativeService:AdvanceAct(player)
	end

	print(string.format("[StoryBeatProcessor] Executed beat '%s' for %s", beat.id, player.Name))
end

-- ==========================================
-- CORE PROCESSING
-- ==========================================

function StoryBeatProcessor:TryExecuteBeat(beat: StoryData.StoryBeat, player: Player)
	-- Debounce check
	local debounceKey = beat.id .. "_" .. player.UserId
	local now = tick()
	if lastTriggerTime[debounceKey] and now - lastTriggerTime[debounceKey] < DEBOUNCE_TIME then
		return
	end

	-- Check if already triggered
	if beat.globalTrigger then
		if globalTriggeredBeats[beat.id] and not beat.repeatable then
			return
		end
	else
		triggeredBeats[player] = triggeredBeats[player] or {}
		if triggeredBeats[player][beat.id] and not beat.repeatable then
			return
		end
	end

	-- Check act requirement
	if beat.actRequired and NarrativeService then
		local currentAct = NarrativeService:GetCurrentAct(player)
		if currentAct ~= beat.actRequired then
			return
		end
	end

	-- Check conditions
	if beat.conditions then
		if not checkConditions(beat.conditions, player) then
			return
		end
	end

	-- Update debounce
	lastTriggerTime[debounceKey] = now

	-- Execute the beat
	executeBeat(beat, player)

	-- Mark as triggered
	if beat.globalTrigger then
		globalTriggeredBeats[beat.id] = true
	else
		triggeredBeats[player][beat.id] = true
	end
end

function StoryBeatProcessor:ProcessTrigger(triggerType: StoryData.TriggerType, triggerData: any, player: Player)
	for _, beat in pairs(StoryData.Beats) do
		if beat.triggerType == triggerType then
			if matchesTriggerData(beat.triggerData, triggerData) then
				self:TryExecuteBeat(beat, player)
			end
		end
	end
end

-- ==========================================
-- EVENT SYSTEM
-- ==========================================

function StoryBeatProcessor:FireEvent(eventId: string, player: Player)
	print(string.format("[StoryBeatProcessor] Event fired: %s for %s", eventId, player.Name))
	self:ProcessTrigger("event", { eventId = eventId }, player)

	-- Check for time_elapsed beats that depend on this event
	for _, beat in pairs(StoryData.Beats) do
		if beat.triggerType == "time_elapsed" then
			local afterEvent = beat.triggerData.afterEvent
			if afterEvent == eventId and beat.triggerData.delaySeconds then
				-- Start timer for this beat
				timerBeats[beat.id] = {
					startTime = tick(),
					beat = beat,
				}
				print(
					string.format(
						"[StoryBeatProcessor] Timer started for '%s' (%d seconds)",
						beat.id,
						beat.triggerData.delaySeconds
					)
				)
			end
		end
	end
end

function StoryBeatProcessor:FireEventForAll(eventId: string)
	for _, player in ipairs(Players:GetPlayers()) do
		self:FireEvent(eventId, player)
	end
end

-- ==========================================
-- TRIGGER SETUP
-- ==========================================

local function setupZoneTrigger(zone: BasePart)
	local zoneId = zone:GetAttribute("ZoneId")
	if not zoneId then
		warn("[StoryBeatProcessor] Zone missing ZoneId attribute:", zone:GetFullName())
		return
	end

	local playersInZone: { [Player]: boolean } = {}

	zone.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and not playersInZone[player] then
			playersInZone[player] = true
			StoryBeatProcessor:ProcessTrigger("zone_enter", { zoneId = zoneId }, player)
		end
	end)

	zone.TouchEnded:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			-- Delay to prevent rapid re-triggering
			task.delay(1, function()
				playersInZone[player] = nil
			end)
		end
	end)

	print(string.format("[StoryBeatProcessor] Zone trigger setup: %s", zoneId))
end

local function setupCollectibleTrigger(collectible: BasePart)
	local objectTag = collectible:GetAttribute("ObjectTag") or "StoryCollectible"

	-- Use ProximityPrompt if available
	local prompt = collectible:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Triggered:Connect(function(player)
			StoryBeatProcessor:ProcessTrigger("object_collect", { objectTag = objectTag }, player)
			-- Destroy after collection
			collectible:Destroy()
		end)
	else
		-- Fallback to touch - need to find a BasePart since Models don't have Touched
		local touchPart = collectible:FindFirstChildWhichIsA("BasePart")
		if touchPart then
			touchPart.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if player then
					StoryBeatProcessor:ProcessTrigger("object_collect", { objectTag = objectTag }, player)
					collectible:Destroy()
				end
			end)
		else
			warn(string.format("[StoryBeatProcessor] Collectible %s has no BasePart for touch", collectible.Name))
		end
	end

	print(string.format("[StoryBeatProcessor] Collectible trigger setup: %s", collectible.Name))
end

local function setupNPCTrigger(npc: Model)
	local objectTag = npc:GetAttribute("ObjectTag") or "StoryNPC"

	-- Find ProximityPrompt in NPC
	local prompt = npc:FindFirstChildOfClass("ProximityPrompt", true)
	if prompt then
		prompt.Triggered:Connect(function(player)
			StoryBeatProcessor:ProcessTrigger("npc_interact", { objectTag = objectTag }, player)
		end)
	end

	print(string.format("[StoryBeatProcessor] NPC trigger setup: %s", npc.Name))
end

-- ==========================================
-- TIMER PROCESSING
-- ==========================================

local function processTimers()
	local now = tick()

	for beatId, timerData in pairs(timerBeats) do
		local elapsed = now - timerData.startTime
		local delaySeconds = timerData.beat.triggerData.delaySeconds or 0

		if elapsed >= delaySeconds then
			-- Timer complete - execute for all players if global
			if timerData.beat.globalTrigger then
				for _, player in ipairs(Players:GetPlayers()) do
					StoryBeatProcessor:TryExecuteBeat(timerData.beat, player)
				end
			end
			timerBeats[beatId] = nil
			print(string.format("[StoryBeatProcessor] Timer completed: %s", beatId))
		end
	end
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function StoryBeatProcessor:SetNarrativeService(service: any)
	NarrativeService = service
end

function StoryBeatProcessor:Initialize()
	-- Setup zone triggers
	for _, zone in ipairs(CollectionService:GetTagged("StoryZone")) do
		setupZoneTrigger(zone)
	end

	-- Listen for new zones
	CollectionService:GetInstanceAddedSignal("StoryZone"):Connect(setupZoneTrigger)

	-- Setup collectible triggers
	for _, collectible in ipairs(CollectionService:GetTagged("StoryCollectible")) do
		setupCollectibleTrigger(collectible)
	end

	-- Listen for new collectibles
	CollectionService:GetInstanceAddedSignal("StoryCollectible"):Connect(setupCollectibleTrigger)

	-- Setup NPC triggers
	for _, npc in ipairs(CollectionService:GetTagged("StoryNPC")) do
		setupNPCTrigger(npc)
	end

	-- Listen for new NPCs
	CollectionService:GetInstanceAddedSignal("StoryNPC"):Connect(setupNPCTrigger)

	-- Setup specific tags (GeneratorPart, Rescuable, Food)
	for _, part in ipairs(CollectionService:GetTagged("GeneratorPart")) do
		part:SetAttribute("ObjectTag", "GeneratorPart")
		setupCollectibleTrigger(part)
	end
	CollectionService:GetInstanceAddedSignal("GeneratorPart"):Connect(function(part)
		part:SetAttribute("ObjectTag", "GeneratorPart")
		setupCollectibleTrigger(part)
	end)

	for _, part in ipairs(CollectionService:GetTagged("Food")) do
		part:SetAttribute("ObjectTag", "Food")
		setupCollectibleTrigger(part)
	end
	CollectionService:GetInstanceAddedSignal("Food"):Connect(function(part)
		part:SetAttribute("ObjectTag", "Food")
		setupCollectibleTrigger(part)
	end)

	for _, npc in ipairs(CollectionService:GetTagged("Rescuable")) do
		npc:SetAttribute("ObjectTag", "Rescuable")
		setupNPCTrigger(npc)
	end
	CollectionService:GetInstanceAddedSignal("Rescuable"):Connect(function(npc)
		npc:SetAttribute("ObjectTag", "Rescuable")
		setupNPCTrigger(npc)
	end)

	-- Start timer processor
	task.spawn(function()
		while true do
			processTimers()
			task.wait(1)
		end
	end)

	-- Clean up on player leave
	Players.PlayerRemoving:Connect(function(player)
		triggeredBeats[player] = nil
	end)

	print("[StoryBeatProcessor] Initialized")
end

-- ==========================================
-- DEBUG HELPERS
-- ==========================================

function StoryBeatProcessor:GetTriggeredBeats(player: Player): { string }
	local result = {}
	if triggeredBeats[player] then
		for beatId, _ in pairs(triggeredBeats[player]) do
			table.insert(result, beatId)
		end
	end
	return result
end

function StoryBeatProcessor:ResetPlayer(player: Player)
	triggeredBeats[player] = {}
	print(string.format("[StoryBeatProcessor] Reset beats for %s", player.Name))
end

return StoryBeatProcessor
