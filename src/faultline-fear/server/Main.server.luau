--!strict
--[[
	Faultline Fear: Server Entry Point

	LOADING SEQUENCE (critical for correct height queries):
	1. Create remote events (needed by services)
	2. Generate Heightmap (BLOCKING - all systems need this)
	3. Initialize services (can now query heights)
	4. Generate visual terrain (background, non-blocking)
	5. Server ready for players
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for shared modules
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config
local Heightmap = Shared.Heightmap

print("[FaultlineFear] Server starting...")
print("[FaultlineFear] Config loaded:", Config.WORLD_SIZE, "stud world")

-- ==========================================
-- STEP 1: CREATE REMOTE EVENTS
-- Must exist before services initialize
-- ==========================================

local function createRemotes()
	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage

	-- Hunger
	local hungerUpdate = Instance.new("RemoteEvent")
	hungerUpdate.Name = "HungerUpdate"
	hungerUpdate.Parent = remotes

	-- Earthquake
	local earthquakeEvent = Instance.new("RemoteEvent")
	earthquakeEvent.Name = "EarthquakeEvent"
	earthquakeEvent.Parent = remotes

	-- Day/Night
	local timeUpdate = Instance.new("RemoteEvent")
	timeUpdate.Name = "TimeUpdate"
	timeUpdate.Parent = remotes

	-- Objectives
	local objectiveUpdate = Instance.new("RemoteEvent")
	objectiveUpdate.Name = "ObjectiveUpdate"
	objectiveUpdate.Parent = remotes

	-- Story events (for dialogue, credits, etc.)
	local storyEvent = Instance.new("RemoteEvent")
	storyEvent.Name = "StoryEvent"
	storyEvent.Parent = remotes

	-- Dialogue
	local dialogueEvent = Instance.new("RemoteEvent")
	dialogueEvent.Name = "DialogueEvent"
	dialogueEvent.Parent = remotes

	-- Interact
	local interactRequest = Instance.new("RemoteFunction")
	interactRequest.Name = "InteractRequest"
	interactRequest.Parent = remotes

	-- Heightmap ready signal
	local heightmapReady = Instance.new("RemoteEvent")
	heightmapReady.Name = "HeightmapReady"
	heightmapReady.Parent = remotes

	print("[FaultlineFear] Remote events created")
	return remotes
end

local Remotes = createRemotes()

-- ==========================================
-- STEP 2: GENERATE HEIGHTMAP (BLOCKING)
-- This MUST complete before any gameplay systems start
-- All height queries depend on this data
-- ==========================================

print("[FaultlineFear] CRITICAL: Generating heightmap (all systems depend on this)...")
local heightmapStart = tick()

Heightmap:Generate(Config.TERRAIN_SEED)

local heightmapTime = tick() - heightmapStart
print(string.format("[FaultlineFear] Heightmap ready in %.2f seconds", heightmapTime))

-- Notify any waiting clients
local HeightmapReady = Remotes:FindFirstChild("HeightmapReady") :: RemoteEvent
HeightmapReady:FireAllClients()

-- ==========================================
-- STEP 3: LOAD SERVICES
-- Services can now safely query terrain heights
-- ==========================================

print("[FaultlineFear] Loading services...")

-- Phase 1: Foundation services
local TerrainGenerator = require(script.Services.TerrainGenerator)
local HungerService = require(script.Services.HungerService)
local DayNightService = require(script.Services.DayNightService)
local PlayerDataService = require(script.Services.PlayerDataService)

-- Phase 2: Core Gameplay services
local EarthquakeService = require(script.Services.EarthquakeService)
local MusicService = require(script.Services.MusicService)
local NarrativeService = require(script.Services.NarrativeService)
local StoryBeatProcessor = require(script.Services.StoryBeatProcessor)
local StoryZoneManager = require(script.Services.StoryZoneManager)
local CollectibleSpawner = require(script.Services.CollectibleSpawner)
local NPCService = require(script.Services.NPCService)
local CreatureService = require(script.Services.CreatureService)
local StructureSpawner = require(script.Services.StructureSpawner)
local PetService = require(script.Services.PetService)
local TerrainAssetSpawner = require(script.Services.TerrainAssetSpawner)
local AnimalService = require(script.Services.AnimalService)
local FlashlightService = require(script.Services.FlashlightService)
local CaveService = require(script.Services.CaveService)
local LiminalZoneService = require(script.Services.LiminalZoneService)
local SignService = require(script.Services.SignService)

-- Initialize all services
TerrainGenerator:Initialize()
HungerService:Initialize()
DayNightService:Initialize()
NarrativeService:Initialize()
PlayerDataService:Initialize() -- After NarrativeService (needs to sync)
EarthquakeService:Initialize()
MusicService:Initialize()

-- Connect services that need cross-references
EarthquakeService:SetMusicService(MusicService)
NarrativeService:SetEarthquakeService(EarthquakeService)
PlayerDataService:SetNarrativeService(NarrativeService)
CreatureService:SetDayNightService(DayNightService)
PetService:SetCreatureService(CreatureService)
PetService:SetEarthquakeService(EarthquakeService)
AnimalService:SetDayNightService(DayNightService)
FlashlightService:SetCreatureService(CreatureService)

-- Initialize creature spawning (after DayNightService connection)
CreatureService:Initialize()

-- Initialize pet companion (after creature service for danger detection)
PetService:Initialize()

-- Initialize wildlife (after DayNightService connection)
AnimalService:Initialize()

-- Initialize flashlight system
FlashlightService:Initialize()

-- Initialize cave system (safe zones, secrets)
CaveService:Initialize()

-- Initialize liminal space zones (eerie atmosphere, music muting)
LiminalZoneService:Initialize()

-- Initialize signage system (player guidance)
SignService:Initialize()

-- Initialize story zones BEFORE StoryBeatProcessor (it listens for StoryZone tags)
StoryZoneManager:Initialize()

-- Spawn structures (landmarks, beacons, buildings)
StructureSpawner:Initialize()

-- Spawn terrain assets (boulders, fault line edges, steam vents, cliffs)
TerrainAssetSpawner:Initialize()

-- Spawn collectibles BEFORE StoryBeatProcessor (it listens for collectible tags)
CollectibleSpawner:Initialize()

-- Spawn survivor NPCs BEFORE StoryBeatProcessor (it listens for Rescuable tags)
NPCService:Initialize()

-- Initialize story system (after NarrativeService, zones, collectibles, and NPCs)
StoryBeatProcessor:SetNarrativeService(NarrativeService)
StoryBeatProcessor:Initialize()

print("[FaultlineFear] Services initialized")

-- ==========================================
-- STEP 4: GENERATE VISUAL TERRAIN (BACKGROUND)
-- This can run async - gameplay doesn't depend on visuals
-- ==========================================

task.spawn(function()
	print("[FaultlineFear] Generating visual terrain in background...")
	local visualStart = tick()

	TerrainGenerator:GenerateVisualTerrain()

	local visualTime = tick() - visualStart
	print(string.format("[FaultlineFear] Visual terrain complete in %.2f seconds", visualTime))
end)

-- ==========================================
-- PLAYER HANDLING
-- ==========================================

local function onPlayerAdded(player: Player)
	print("[FaultlineFear] Player joined:", player.Name)

	-- Ensure player knows heightmap is ready (in case they joined during load)
	if Heightmap:IsGenerated() then
		HeightmapReady:FireClient(player)
	end

	-- Fire GAME_START event for story system (after character loads)
	player.CharacterAdded:Once(function()
		task.delay(2, function() -- Give a moment for UI to load
			StoryBeatProcessor:FireEvent("GAME_START", player)
		end)
	end)
end

local function onPlayerRemoving(player: Player)
	print("[FaultlineFear] Player left:", player.Name)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players already in game (Studio testing)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

-- ==========================================
-- INITIALIZATION COMPLETE
-- ==========================================

print("[FaultlineFear] ================================")
print("[FaultlineFear] Server ready!")
print("[FaultlineFear] Heightmap: READY (O(1) height queries)")
print("[FaultlineFear] Visual terrain: LOADING in background")
print("[FaultlineFear] ================================")
