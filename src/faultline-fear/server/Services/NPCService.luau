--!strict
--[[
	Faultline Fear: NPC Service

	Creates and manages survivor NPCs in the world.
	10 survivors are scattered across the island.

	Features:
	- Each survivor has unique name and personality
	- ProximityPrompt to rescue
	- Integration with StoryBeatProcessor
	- Survivors follow player after rescue (simplified)

	Exports: Initialize(), GetSurvivorCount(), RescueSurvivor()
	Depends: Config, CollectionService, NarrativeService
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config
local Heightmap = Shared.Heightmap

local NPCService = {}

-- State
local survivors: { [string]: Model } = {}
local rescuedSurvivors: { [Player]: { string } } = {}
local followingPlayers: { [string]: Player } = {} -- Which player each survivor follows
local npcsFolder: Folder = nil :: any

-- Following constants
local FOLLOW_DISTANCE = 5 -- Studs behind player
local FOLLOW_SPEED = 14 -- Walk speed when following
local MAX_FOLLOW_DISTANCE = 50 -- Teleport if too far

-- Survivor definitions - 10 unique NPCs
local SURVIVOR_DATA = {
	{
		id = "marcus",
		name = "Marcus",
		description = "A former park ranger who knows the island well",
		personality = "Leader, calm under pressure",
		zone = "COASTAL",
		offset = Vector3.new(-200, 0, 50),
		dialogue = {
			"Hey! Over here!",
			"I thought I was the only one...",
			"We need to get to higher ground.",
		},
		clothing = {
			shirtColor = Color3.fromRGB(139, 90, 43), -- Brown
			pantsColor = Color3.fromRGB(84, 84, 84), -- Dark grey
		},
	},
	{
		id = "elena",
		name = "Elena",
		description = "A tourist who was hiking when the quake hit",
		personality = "Resourceful, anxious",
		zone = "FOREST",
		offset = Vector3.new(100, 0, -150),
		dialogue = {
			"Thank goodness! I've been hiding here for hours.",
			"I lost my group when the ground split open.",
			"Please, we have to find the others!",
		},
		clothing = {
			shirtColor = Color3.fromRGB(0, 100, 200), -- Blue
			pantsColor = Color3.fromRGB(50, 50, 50),
		},
	},
	{
		id = "diego",
		name = "Diego",
		description = "Local fisherman who was out on the water",
		personality = "Practical, weathered",
		zone = "BEACH",
		offset = Vector3.new(150, 0, 0),
		dialogue = {
			"The waves were something else during the quake.",
			"My boat is gone. Everything is gone.",
			"But we're still here. That's what matters.",
		},
		clothing = {
			shirtColor = Color3.fromRGB(255, 200, 100), -- Yellow
			pantsColor = Color3.fromRGB(50, 80, 120), -- Navy
		},
	},
	{
		id = "sophia",
		name = "Sophia",
		description = "A young mother separated from her family",
		personality = "Determined, worried",
		zone = "VALLEY",
		offset = Vector3.new(-100, 0, 50),
		dialogue = {
			"My children... they were at the campsite.",
			"I have to find them. I have to.",
			"Please help me look for them!",
		},
		clothing = {
			shirtColor = Color3.fromRGB(200, 100, 150), -- Pink
			pantsColor = Color3.fromRGB(80, 80, 80),
		},
	},
	{
		id = "james",
		name = "James",
		description = "An elderly geologist who predicted the quake",
		personality = "Knowledgeable, regretful",
		zone = "FAULT_LINE",
		offset = Vector3.new(-150, 0, -50),
		dialogue = {
			"I warned them. I told them this would happen.",
			"The fault line has been unstable for years.",
			"There may be more quakes coming. Bigger ones.",
		},
		clothing = {
			shirtColor = Color3.fromRGB(255, 255, 255), -- White
			pantsColor = Color3.fromRGB(100, 80, 60), -- Khaki
		},
	},
	{
		id = "aisha",
		name = "Aisha",
		description = "A doctor from the mainland on vacation",
		personality = "Competent, focused",
		zone = "COASTAL",
		offset = Vector3.new(250, 0, -100),
		dialogue = {
			"I'm a doctor. Is anyone injured?",
			"We need to set up a triage area.",
			"Keep everyone calm. Panic causes more casualties.",
		},
		clothing = {
			shirtColor = Color3.fromRGB(50, 150, 50), -- Green
			pantsColor = Color3.fromRGB(60, 60, 60),
		},
	},
	{
		id = "tommy",
		name = "Tommy",
		description = "A teenage boy who lost his phone",
		personality = "Scared, trying to be brave",
		zone = "VALLEY",
		offset = Vector3.new(200, 0, -50),
		dialogue = {
			"Have you seen my parents?",
			"My phone died. I can't call anyone.",
			"I don't know what to do...",
		},
		clothing = {
			shirtColor = Color3.fromRGB(100, 100, 200), -- Light blue
			pantsColor = Color3.fromRGB(30, 30, 50), -- Dark jeans
		},
	},
	{
		id = "chen",
		name = "Chen",
		description = "A chef from the coastal resort",
		personality = "Practical, strong",
		zone = "COASTAL",
		offset = Vector3.new(-50, 0, 100),
		dialogue = {
			"The resort collapsed completely.",
			"I managed to grab some supplies.",
			"We should ration what we have.",
		},
		clothing = {
			shirtColor = Color3.fromRGB(255, 255, 255), -- White chef jacket
			pantsColor = Color3.fromRGB(30, 30, 30), -- Black
		},
	},
	{
		id = "maya",
		name = "Maya",
		description = "A wildlife photographer documenting the island",
		personality = "Observant, quiet",
		zone = "FOREST",
		offset = Vector3.new(-200, 0, 100),
		dialogue = {
			"I got some footage of the quake.",
			"The animals knew it was coming. They fled.",
			"If we survive this, the world needs to see.",
		},
		clothing = {
			shirtColor = Color3.fromRGB(150, 120, 90), -- Tan
			pantsColor = Color3.fromRGB(60, 80, 60), -- Olive
		},
	},
	{
		id = "carlos",
		name = "Carlos",
		description = "A maintenance worker from the radio tower",
		personality = "Knowledgeable about the tower, injured",
		zone = "MOUNTAIN",
		offset = Vector3.new(100, 0, -100),
		dialogue = {
			"*cough* The radio tower... it might still work.",
			"The generator is busted, but if you find parts...",
			"I can help you fix it. I know that machine.",
		},
		clothing = {
			shirtColor = Color3.fromRGB(255, 150, 0), -- Orange work shirt
			pantsColor = Color3.fromRGB(50, 50, 80), -- Work pants
		},
	},
}

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================

local function getZoneCenter(zoneName: string): Vector3?
	local zoneConfig = Config.ZONES[zoneName]
	if not zoneConfig then
		warn("[NPCService] Unknown zone:", zoneName)
		return nil
	end

	local centerZ = (zoneConfig.zMin + zoneConfig.zMax) / 2
	return Vector3.new(0, 0, centerZ)
end

local function getTerrainHeight(x: number, z: number): number
	if Heightmap and Heightmap.GetHeight then
		return Heightmap:GetHeight(x, z)
	end
	return 20
end

-- ==========================================
-- NPC CREATION
-- ==========================================

local function createSurvivorNPC(survivorDef: typeof(SURVIVOR_DATA[1])): Model
	-- Create humanoid model
	local model = Instance.new("Model")
	model.Name = "Survivor_" .. survivorDef.id

	-- Create body parts (simplified rig)
	local torso = Instance.new("Part")
	torso.Name = "HumanoidRootPart"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Anchored = true
	torso.CanCollide = false
	torso.BrickColor = BrickColor.new(survivorDef.clothing.shirtColor)
	torso.Material = Enum.Material.SmoothPlastic
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Position = torso.Position + Vector3.new(0, 1.5, 0)
	head.Anchored = true
	head.CanCollide = false
	head.BrickColor = BrickColor.new("Pastel brown")
	head.Material = Enum.Material.SmoothPlastic
	head.Parent = model

	-- Add humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = survivorDef.name
	humanoid.HealthDisplayDistance = 0
	humanoid.NameDisplayDistance = 20
	humanoid.Parent = model

	model.PrimaryPart = torso

	-- Add billboard GUI for name
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 100, 0, 30)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.AlwaysOnTop = false
	billboardGui.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = survivorDef.name
	nameLabel.Parent = billboardGui

	-- Add attributes
	model:SetAttribute("SurvivorId", survivorDef.id)
	model:SetAttribute("SurvivorName", survivorDef.name)
	model:SetAttribute("Description", survivorDef.description)
	model:SetAttribute("Personality", survivorDef.personality)
	model:SetAttribute("ObjectTag", "Rescuable")
	model:SetAttribute("IsRescued", false)

	-- Add CollectionService tags
	CollectionService:AddTag(model, "Rescuable")
	CollectionService:AddTag(model, "StoryNPC")

	-- Add ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Rescue"
	prompt.ObjectText = survivorDef.name
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0.5
	prompt.RequiresLineOfSight = false
	prompt.Parent = torso

	-- Handle rescue
	prompt.Triggered:Connect(function(player)
		NPCService:RescueSurvivor(player, survivorDef.id)
	end)

	-- Add subtle highlight effect
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.9
	highlight.OutlineTransparency = 0.5
	highlight.OutlineColor = Color3.fromRGB(255, 200, 100)
	highlight.Enabled = true
	highlight.Parent = model

	return model
end

-- ==========================================
-- RESCUE HANDLING
-- ==========================================

function NPCService:RescueSurvivor(player: Player, survivorId: string)
	local model = survivors[survivorId]
	if not model then
		warn("[NPCService] Unknown survivor:", survivorId)
		return
	end

	if model:GetAttribute("IsRescued") then
		-- Already rescued
		return
	end

	-- Mark as rescued
	model:SetAttribute("IsRescued", true)

	-- Track for this player
	rescuedSurvivors[player] = rescuedSurvivors[player] or {}
	table.insert(rescuedSurvivors[player], survivorId)

	-- Update visual - change highlight to green
	local highlight = model:FindFirstChildOfClass("Highlight")
	if highlight then
		highlight.OutlineColor = Color3.fromRGB(100, 255, 100)
		highlight.FillColor = Color3.fromRGB(100, 255, 100)
		highlight.FillTransparency = 0.7
	end

	-- Disable ProximityPrompt
	local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = false
	end

	-- Get survivor data for dialogue
	local survivorData = nil
	for _, data in ipairs(SURVIVOR_DATA) do
		if data.id == survivorId then
			survivorData = data
			break
		end
	end

	-- Play rescue dialogue via DialogueEvent
	if survivorData then
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		if remotes then
			local dialogueEvent = remotes:FindFirstChild("DialogueEvent")
			if dialogueEvent then
				(dialogueEvent :: RemoteEvent):FireClient(player, {
					name = survivorData.name,
					lines = survivorData.dialogue,
				})
			end
		end
	end

	print(string.format("[NPCService] %s rescued survivor: %s", player.Name, survivorId))

	-- Start following the player
	followingPlayers[survivorId] = player
	model:SetAttribute("FollowingPlayer", player.Name)

	-- StoryBeatProcessor will handle the rest via ObjectTag trigger
end

--[[
	Update survivor following behavior (called each frame).
]]
local function updateSurvivorFollowing()
	for survivorId, player in pairs(followingPlayers) do
		local model = survivors[survivorId]
		if not model or not model.Parent then
			followingPlayers[survivorId] = nil
			continue
		end

		local character = player.Character
		if not character then
			continue
		end

		local playerRoot = character:FindFirstChild("HumanoidRootPart")
		local survivorRoot = model.PrimaryPart
		if not playerRoot or not survivorRoot then
			continue
		end

		local playerPos = playerRoot.Position
		local survivorPos = survivorRoot.Position

		local distance = (playerPos - survivorPos).Magnitude

		-- Teleport if too far
		if distance > MAX_FOLLOW_DISTANCE then
			local behindPlayer = playerPos - playerRoot.CFrame.LookVector * FOLLOW_DISTANCE
			local terrainY = Heightmap:GetHeight(behindPlayer.X, behindPlayer.Z)
			model:PivotTo(CFrame.new(behindPlayer.X, terrainY + 2, behindPlayer.Z))
		elseif distance > FOLLOW_DISTANCE then
			-- Move toward player
			local direction = (playerPos - survivorPos).Unit
			local targetPos = survivorPos + direction * FOLLOW_SPEED * 0.016 -- ~60fps

			-- Keep on terrain
			local terrainY = Heightmap:GetHeight(targetPos.X, targetPos.Z)
			local newCFrame = CFrame.new(targetPos.X, terrainY + 2, targetPos.Z)

			-- Face the player
			local lookCFrame =
				CFrame.lookAt(newCFrame.Position, Vector3.new(playerPos.X, newCFrame.Position.Y, playerPos.Z))
			model:PivotTo(lookCFrame)
		end
	end
end

function NPCService:GetRescuedCount(player: Player): number
	local rescued = rescuedSurvivors[player]
	return if rescued then #rescued else 0
end

function NPCService:GetTotalSurvivorCount(): number
	return #SURVIVOR_DATA
end

-- ==========================================
-- SPAWNING
-- ==========================================

function NPCService:SpawnAllSurvivors()
	for _, survivorDef in ipairs(SURVIVOR_DATA) do
		local zoneCenter = getZoneCenter(survivorDef.zone)
		if not zoneCenter then
			continue
		end

		-- Calculate position
		local x = zoneCenter.X + survivorDef.offset.X
		local z = zoneCenter.Z + survivorDef.offset.Z
		local y = getTerrainHeight(x, z) + 2

		local position = Vector3.new(x, y, z)

		-- Create and place NPC
		local model = createSurvivorNPC(survivorDef)
		model:PivotTo(CFrame.new(position))
		model.Parent = npcsFolder

		survivors[survivorDef.id] = model

		print(
			string.format(
				"[NPCService] Spawned survivor '%s' at %s (zone: %s)",
				survivorDef.name,
				tostring(position),
				survivorDef.zone
			)
		)
	end

	print(string.format("[NPCService] Spawned %d survivors", #SURVIVOR_DATA))
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function NPCService:Initialize()
	-- Create folder
	npcsFolder = Instance.new("Folder")
	npcsFolder.Name = "Survivors"
	npcsFolder.Parent = Workspace

	-- Spawn all survivors
	self:SpawnAllSurvivors()

	-- Update following behavior each frame
	RunService.Heartbeat:Connect(updateSurvivorFollowing)

	-- Clean up tracking on player leave
	Players.PlayerRemoving:Connect(function(player)
		rescuedSurvivors[player] = nil
		-- Remove from followingPlayers
		for survivorId, followingPlayer in pairs(followingPlayers) do
			if followingPlayer == player then
				followingPlayers[survivorId] = nil
			end
		end
	end)

	print("[NPCService] Initialized")
end

return NPCService
