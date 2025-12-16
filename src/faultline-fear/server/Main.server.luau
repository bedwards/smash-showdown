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

-- Phase 2: Core Gameplay services
local EarthquakeService = require(script.Services.EarthquakeService)
local MusicService = require(script.Services.MusicService)
local NarrativeService = require(script.Services.NarrativeService)
-- TODO: Add as implemented
-- local NPCService = require(script.Services.NPCService)

-- Initialize all services
TerrainGenerator:Initialize()
HungerService:Initialize()
DayNightService:Initialize()
EarthquakeService:Initialize()
MusicService:Initialize()
NarrativeService:Initialize()

-- Connect services that need cross-references
EarthquakeService:SetMusicService(MusicService)
NarrativeService:SetEarthquakeService(EarthquakeService)

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
