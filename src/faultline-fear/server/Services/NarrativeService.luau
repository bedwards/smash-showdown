--!strict
--[[
	Faultline Fear: Narrative Service (Server)

	Manages story progression for all players:
	- Tracks current act and objectives
	- Handles story events (The Big One, etc.)
	- Determines endings based on progress
	- Coordinates with other services

	The story has a DEFINITIVE END when players board the rescue helicopter.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BadgeService = game:GetService("BadgeService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config
local StoryData = require(ReplicatedStorage.Shared:WaitForChild("StoryData"))

export type PlayerProgress = {
	currentAct: StoryData.ActId,
	completedObjectives: { [string]: number }, -- objectiveId -> count
	survivorsRescued: number,
	generatorPartsCollected: number,
	startTime: number, -- tick() when they started
	completionTime: number?, -- tick() when they finished
	ending: StoryData.EndingId?,
}

local NarrativeService = {}

-- State
local playerProgress: { [Player]: PlayerProgress } = {}
local _globalEventsFired: { [string]: boolean } = {} -- Track one-time events

-- Remote events
local ObjectiveUpdateEvent: RemoteEvent = nil :: any
local StoryEventRemote: RemoteEvent = nil :: any
local DialogueRemote: RemoteEvent = nil :: any

-- References to other services (set during initialization)
local EarthquakeService: any = nil

-- ==========================================
-- PLAYER PROGRESS MANAGEMENT
-- ==========================================

local function createDefaultProgress(): PlayerProgress
	return {
		currentAct = "ACT_1_CALL",
		completedObjectives = {},
		survivorsRescued = 0,
		generatorPartsCollected = 0,
		startTime = tick(),
		completionTime = nil,
		ending = nil,
	}
end

function NarrativeService:GetPlayerProgress(player: Player): PlayerProgress
	if not playerProgress[player] then
		playerProgress[player] = createDefaultProgress()
	end
	return playerProgress[player]
end

function NarrativeService:ResetPlayerProgress(player: Player)
	playerProgress[player] = createDefaultProgress()
	self:NotifyProgressUpdate(player)
	print("[NarrativeService] Reset progress for:", player.Name)
end

-- ==========================================
-- OBJECTIVE TRACKING
-- ==========================================

function NarrativeService:CompleteObjective(player: Player, objectiveId: string, count: number?)
	local progress = self:GetPlayerProgress(player)
	local addCount = count or 1

	progress.completedObjectives[objectiveId] = (progress.completedObjectives[objectiveId] or 0) + addCount

	print(string.format("[NarrativeService] %s completed objective: %s (%d)", player.Name, objectiveId, progress.completedObjectives[objectiveId]))

	-- Check if act is complete
	self:CheckActCompletion(player)
	self:NotifyProgressUpdate(player)
end

function NarrativeService:GetObjectiveProgress(player: Player, objectiveId: string): number
	local progress = self:GetPlayerProgress(player)
	return progress.completedObjectives[objectiveId] or 0
end

function NarrativeService:IsObjectiveComplete(player: Player, objectiveId: string): boolean
	local progress = self:GetPlayerProgress(player)
	local act = StoryData.GetAct(progress.currentAct)

	for _, objective in ipairs(act.objectives) do
		if objective.id == objectiveId then
			local current = progress.completedObjectives[objectiveId] or 0
			local required = objective.requiredCount or 1
			return current >= required
		end
	end

	return false
end

-- ==========================================
-- SURVIVOR & SIGNAL TRACKING
-- ==========================================

function NarrativeService:RescueSurvivor(player: Player)
	local progress = self:GetPlayerProgress(player)
	progress.survivorsRescued += 1

	self:CompleteObjective(player, "rescue_survivors", 1)

	print(string.format("[NarrativeService] %s rescued survivor #%d", player.Name, progress.survivorsRescued))
end

function NarrativeService:CollectGeneratorPart(player: Player)
	local progress = self:GetPlayerProgress(player)
	progress.generatorPartsCollected += 1

	self:CompleteObjective(player, "collect_generator_parts", 1)

	print(string.format("[NarrativeService] %s collected generator part #%d", player.Name, progress.generatorPartsCollected))
end

function NarrativeService:GetSurvivorsRescued(player: Player): number
	return self:GetPlayerProgress(player).survivorsRescued
end

function NarrativeService:GetGeneratorPartsCollected(player: Player): number
	return self:GetPlayerProgress(player).generatorPartsCollected
end

-- ==========================================
-- ACT PROGRESSION
-- ==========================================

function NarrativeService:CheckActCompletion(player: Player)
	local progress = self:GetPlayerProgress(player)
	local currentAct = StoryData.GetAct(progress.currentAct)

	-- Check if all non-optional objectives are complete
	local allComplete = true
	for _, objective in ipairs(currentAct.objectives) do
		if not objective.isOptional then
			local current = progress.completedObjectives[objective.id] or 0
			local required = objective.requiredCount or 1
			if current < required then
				allComplete = false
				break
			end
		end
	end

	if allComplete then
		self:AdvanceAct(player)
	end
end

function NarrativeService:AdvanceAct(player: Player)
	local progress = self:GetPlayerProgress(player)
	local nextAct = StoryData.GetNextAct(progress.currentAct)

	if nextAct then
		local oldAct = progress.currentAct
		progress.currentAct = nextAct

		print(string.format("[NarrativeService] %s advanced from %s to %s", player.Name, oldAct, nextAct))

		-- Send story event to client
		if StoryEventRemote then
			StoryEventRemote:FireClient(player, {
				type = "act_change",
				oldAct = oldAct,
				newAct = nextAct,
				actData = StoryData.GetAct(nextAct),
			})
		end

		-- Check for special act triggers
		if nextAct == "ACT_5_RESOLUTION" then
			-- Game is nearly complete
			self:StartEndgame(player)
		end
	else
		-- No more acts - game complete!
		self:CompleteGame(player)
	end

	self:NotifyProgressUpdate(player)
end

function NarrativeService:SetAct(player: Player, actId: StoryData.ActId)
	local progress = self:GetPlayerProgress(player)
	progress.currentAct = actId
	self:NotifyProgressUpdate(player)
	print(string.format("[NarrativeService] Set %s to act: %s", player.Name, actId))
end

function NarrativeService:GetCurrentAct(player: Player): StoryData.ActId
	return self:GetPlayerProgress(player).currentAct
end

-- ==========================================
-- STORY EVENTS
-- ==========================================

function NarrativeService:TriggerStoryEvent(eventId: string)
	local event = StoryData.Events[eventId]
	if not event then
		warn("[NarrativeService] Unknown story event:", eventId)
		return
	end

	print("[NarrativeService] Story event triggered:", event.name)

	-- Fire to all clients
	if StoryEventRemote then
		StoryEventRemote:FireAllClients({
			type = "story_event",
			eventId = eventId,
			eventData = event,
		})
	end

	-- Handle specific events
	if eventId == "BIG_ONE" and EarthquakeService then
		-- Trigger The Big One earthquake
		EarthquakeService:TriggerBigOne()

		-- Advance all players to Act 3
		for _, player in Players:GetPlayers() do
			local progress = self:GetPlayerProgress(player)
			if progress.currentAct == "ACT_2_TRIALS" then
				progress.currentAct = "ACT_3_ORDEAL"
				self:NotifyProgressUpdate(player)
			end
		end
	end
end

-- ==========================================
-- DIALOGUE
-- ==========================================

function NarrativeService:PlayDialogue(player: Player, dialogueId: string)
	local dialogue = StoryData.GetDialogue(dialogueId)
	if not dialogue then
		warn("[NarrativeService] Unknown dialogue:", dialogueId)
		return
	end

	if DialogueRemote then
		DialogueRemote:FireClient(player, {
			type = "dialogue",
			dialogueId = dialogueId,
			dialogue = dialogue,
		})
	end

	print(string.format("[NarrativeService] Playing dialogue '%s' for %s", dialogueId, player.Name))
end

function NarrativeService:PlayDialogueForAll(dialogueId: string)
	local dialogue = StoryData.GetDialogue(dialogueId)
	if not dialogue then
		warn("[NarrativeService] Unknown dialogue:", dialogueId)
		return
	end

	if DialogueRemote then
		DialogueRemote:FireAllClients({
			type = "dialogue",
			dialogueId = dialogueId,
			dialogue = dialogue,
		})
	end
end

-- ==========================================
-- ENDGAME & COMPLETION
-- ==========================================

function NarrativeService:StartEndgame(player: Player)
	print(string.format("[NarrativeService] %s entered endgame (Act 5)", player.Name))

	-- Play rescue arrival dialogue
	self:PlayDialogue(player, "rescue_arrives")
end

function NarrativeService:CompleteGame(player: Player)
	local progress = self:GetPlayerProgress(player)

	-- Record completion time
	progress.completionTime = tick()
	local playTime = progress.completionTime - progress.startTime

	-- Determine ending based on survivors rescued
	local ending = StoryData.GetEndingForSurvivors(progress.survivorsRescued)
	progress.ending = ending.id

	print(string.format(
		"[NarrativeService] %s COMPLETED GAME! Ending: %s, Survivors: %d/%d, Time: %.1f minutes",
		player.Name,
		ending.name,
		progress.survivorsRescued,
		Config.OBJECTIVES.SURVIVORS_TOTAL,
		playTime / 60
	))

	-- Award badge if configured
	if ending.badgeId and ending.badgeId > 0 then
		local success, err = pcall(function()
			BadgeService:AwardBadge(player.UserId, ending.badgeId)
		end)
		if success then
			print("[NarrativeService] Badge awarded:", ending.badgeId)
		else
			warn("[NarrativeService] Failed to award badge:", err)
		end
	end

	-- Send completion event to client
	if StoryEventRemote then
		StoryEventRemote:FireClient(player, {
			type = "game_complete",
			ending = ending,
			playTime = playTime,
			survivorsRescued = progress.survivorsRescued,
			generatorPartsCollected = progress.generatorPartsCollected,
		})
	end
end

function NarrativeService:GetEnding(player: Player): StoryData.Ending?
	local progress = self:GetPlayerProgress(player)
	if progress.ending then
		return StoryData.Endings[progress.ending]
	end
	return nil
end

-- ==========================================
-- CLIENT NOTIFICATIONS
-- ==========================================

function NarrativeService:NotifyProgressUpdate(player: Player)
	local progress = self:GetPlayerProgress(player)
	local act = StoryData.GetAct(progress.currentAct)

	if ObjectiveUpdateEvent then
		ObjectiveUpdateEvent:FireClient(player, {
			currentAct = progress.currentAct,
			actName = act.name,
			objectives = act.objectives,
			completedObjectives = progress.completedObjectives,
			survivorsRescued = progress.survivorsRescued,
			generatorPartsCollected = progress.generatorPartsCollected,
		})
	end
end

-- ==========================================
-- SERVICE INJECTION
-- ==========================================

function NarrativeService:SetEarthquakeService(service: any)
	EarthquakeService = service
	print("[NarrativeService] EarthquakeService connected")
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function NarrativeService:Initialize()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")

	-- Create remote events if they don't exist
	local objectiveUpdate = remotes:FindFirstChild("ObjectiveUpdate")
	if objectiveUpdate then
		ObjectiveUpdateEvent = objectiveUpdate :: RemoteEvent
	end

	local storyEvent = remotes:FindFirstChild("StoryEvent")
	if not storyEvent then
		storyEvent = Instance.new("RemoteEvent")
		storyEvent.Name = "StoryEvent"
		storyEvent.Parent = remotes
	end
	StoryEventRemote = storyEvent :: RemoteEvent

	local dialogueEvent = remotes:FindFirstChild("DialogueEvent")
	if not dialogueEvent then
		dialogueEvent = Instance.new("RemoteEvent")
		dialogueEvent.Name = "DialogueEvent"
		dialogueEvent.Parent = remotes
	end
	DialogueRemote = dialogueEvent :: RemoteEvent

	-- Initialize progress for existing players
	for _, player in Players:GetPlayers() do
		playerProgress[player] = createDefaultProgress()
	end

	-- Handle new players
	Players.PlayerAdded:Connect(function(player)
		playerProgress[player] = createDefaultProgress()
		-- Send initial progress
		task.delay(1, function()
			self:NotifyProgressUpdate(player)
		end)
	end)

	-- Clean up on leave
	Players.PlayerRemoving:Connect(function(player)
		playerProgress[player] = nil
	end)

	print("[NarrativeService] Initialized")
	print("[NarrativeService] Story has", #StoryData.ActOrder, "acts")
	print("[NarrativeService] Endings available:", #StoryData.Endings)
end

return NarrativeService
