--!strict
--[[
	Faultline Fear: Server Entry Point

	LOADING STAGES (controlled by Config.LOAD_LEVEL):
	0 = Heightmap only
	1 = + Visual terrain
	2 = + Core services (hunger, day/night, earthquake)
	3 = + Structures and terrain assets
	4 = + NPCs and collectibles
	5 = Full load (story system, validation)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Disable auto character loading - we'll load manually when world is ready
Players.CharacterAutoLoads = false

-- Track total load time
local SERVER_START = tick()

local function logStage(stage: number, name: string)
	local elapsed = tick() - SERVER_START
	print(string.format("[LOAD] Stage %d complete: %s (%.2fs total)", stage, name, elapsed))
end

-- Wait for shared modules
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config
local Heightmap = Shared.Heightmap

local LOAD_LEVEL = Config.LOAD_LEVEL or 5

print("[FaultlineFear] ================================")
print("[FaultlineFear] Server starting...")
print("[FaultlineFear] LOAD_LEVEL:", LOAD_LEVEL)
print("[FaultlineFear] ================================")

-- ==========================================
-- REMOTES (always needed)
-- ==========================================

local function createRemotes()
	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage

	local events = {
		"HungerUpdate",
		"EarthquakeEvent",
		"TimeUpdate",
		"ObjectiveUpdate",
		"ProgressUpdate", -- Survivor count, generator parts
		"StoryEvent",
		"DialogueEvent",
		"HeightmapReady",
		"WorldReady",
		"LiminalEvent",
	}
	for _, name in events do
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = remotes
	end

	local interactRequest = Instance.new("RemoteFunction")
	interactRequest.Name = "InteractRequest"
	interactRequest.Parent = remotes

	return remotes
end

local Remotes = createRemotes()
local WorldReady = Remotes:FindFirstChild("WorldReady") :: RemoteEvent

-- Track if world is ready for player spawning
local worldIsReady = false

-- Spawn a player's character on terrain
local function spawnPlayerOnTerrain(player: Player)
	if not Heightmap:IsGenerated() then
		warn("[FaultlineFear] Cannot spawn player - heightmap not ready")
		return
	end

	-- Load character if not loaded
	if not player.Character then
		player:LoadCharacter()
	end

	-- Wait for character to load
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?

	if rootPart then
		-- Position on terrain at spawn point (Valley/Town area, near WaterTower)
		local spawnX, spawnZ = 0, 100
		local terrainHeight = Heightmap:GetHeight(spawnX, spawnZ)
		rootPart.CFrame = CFrame.new(spawnX, terrainHeight + 5, spawnZ)
		print(string.format("[FaultlineFear] Spawned %s at (%.0f, %.1f, %.0f)", player.Name, spawnX, terrainHeight + 5, spawnZ))
	end
end

-- Called when world loading reaches a stopping point
local function onWorldReady()
	worldIsReady = true
	WorldReady:FireAllClients()
	print("[FaultlineFear] World ready - spawning players")

	-- Spawn all waiting players
	for _, player in Players:GetPlayers() do
		task.spawn(spawnPlayerOnTerrain, player)
	end
end

-- Handle new players joining
local function onPlayerAdded(player: Player)
	print("[FaultlineFear] Player joined:", player.Name)

	if Heightmap:IsGenerated() then
		local HeightmapReady = Remotes:FindFirstChild("HeightmapReady") :: RemoteEvent
		HeightmapReady:FireClient(player)
	end

	if worldIsReady then
		-- World already ready, spawn immediately
		task.spawn(spawnPlayerOnTerrain, player)
		WorldReady:FireClient(player)
	end
	-- Otherwise they'll be spawned when onWorldReady() is called
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	print("[FaultlineFear] Player left:", player.Name)
end)

-- ==========================================
-- STAGE 0: HEIGHTMAP
-- ==========================================

print("[LOAD] Stage 0: Generating heightmap...")
Heightmap:Generate(Config.TERRAIN_SEED)

local HeightmapReady = Remotes:FindFirstChild("HeightmapReady") :: RemoteEvent
HeightmapReady:FireAllClients()

logStage(0, "Heightmap generated")

if LOAD_LEVEL == 0 then
	print("[LOAD] ✅ STOPPED at LOAD_LEVEL 0 (heightmap only)")
	print("[LOAD] You should see: Empty world, player spawns and falls")
	onWorldReady()
	return
end

-- ==========================================
-- STAGE 1: VISUAL TERRAIN
-- ==========================================

print("[LOAD] Stage 1: Generating visual terrain...")
local TerrainGenerator = require(script.Parent.Services.TerrainGenerator)
TerrainGenerator:Initialize()
TerrainGenerator:GenerateVisualTerrain()

logStage(1, "Visual terrain generated")

if LOAD_LEVEL == 1 then
	print("[LOAD] ✅ STOPPED at LOAD_LEVEL 1 (heightmap + terrain)")
	print("[LOAD] You should see: Terrain with grass/rock/sand, ocean water")
	onWorldReady()
	return
end

-- ==========================================
-- STAGE 2: CORE SERVICES
-- ==========================================

print("[LOAD] Stage 2: Initializing core services...")
local HungerService = require(script.Parent.Services.HungerService)
local DayNightService = require(script.Parent.Services.DayNightService)
local PlayerDataService = require(script.Parent.Services.PlayerDataService)
local EarthquakeService = require(script.Parent.Services.EarthquakeService)
local MusicService = require(script.Parent.Services.MusicService)
local NarrativeService = require(script.Parent.Services.NarrativeService)
local CreatureService = require(script.Parent.Services.CreatureService)
local PetService = require(script.Parent.Services.PetService)
local AnimalService = require(script.Parent.Services.AnimalService)
local FlashlightService = require(script.Parent.Services.FlashlightService)

HungerService:Initialize()
DayNightService:Initialize()
NarrativeService:Initialize()
PlayerDataService:Initialize()
EarthquakeService:Initialize()
MusicService:Initialize()

-- Connect cross-references
EarthquakeService:SetMusicService(MusicService)
NarrativeService:SetEarthquakeService(EarthquakeService)
PlayerDataService:SetNarrativeService(NarrativeService)
CreatureService:SetDayNightService(DayNightService)
PetService:SetCreatureService(CreatureService)
PetService:SetEarthquakeService(EarthquakeService)
AnimalService:SetDayNightService(DayNightService)
FlashlightService:SetCreatureService(CreatureService)

CreatureService:Initialize()
PetService:Initialize()
AnimalService:Initialize()
FlashlightService:Initialize()

logStage(2, "Core services initialized")

if LOAD_LEVEL == 2 then
	print("[LOAD] ✅ STOPPED at LOAD_LEVEL 2 (terrain + core services)")
	print("[LOAD] You should see: Terrain, hunger bar, day/night cycle working")
	onWorldReady()
	return
end

-- ==========================================
-- STAGE 3: STRUCTURES AND TERRAIN ASSETS
-- ==========================================

print("[LOAD] Stage 3: Spawning structures and terrain assets...")
local CaveService = require(script.Parent.Services.CaveService)
local LiminalZoneService = require(script.Parent.Services.LiminalZoneService)
local SignService = require(script.Parent.Services.SignService)
local StoryZoneManager = require(script.Parent.Services.StoryZoneManager)
local StructureSpawner = require(script.Parent.Services.StructureSpawner)
local TerrainAssetSpawner = require(script.Parent.Services.TerrainAssetSpawner)
local BuildingService = require(script.Parent.Services.BuildingService)

CaveService:Initialize()
LiminalZoneService:Initialize()
SignService:Initialize()
StoryZoneManager:Initialize()
StructureSpawner:Initialize()
TerrainAssetSpawner:Initialize()
BuildingService:Initialize()

logStage(3, "Structures and terrain assets spawned")

if LOAD_LEVEL == 3 then
	print("[LOAD] ✅ STOPPED at LOAD_LEVEL 3 (+ structures)")
	print("[LOAD] You should see: Terrain + buildings/signs/caves/liminal zones")
	onWorldReady()
	return
end

-- ==========================================
-- STAGE 4: NPCs AND COLLECTIBLES
-- ==========================================

print("[LOAD] Stage 4: Spawning NPCs and collectibles...")
local CollectibleSpawner = require(script.Parent.Services.CollectibleSpawner)
local NPCService = require(script.Parent.Services.NPCService)

CollectibleSpawner:Initialize()
NPCService:Initialize()

logStage(4, "NPCs and collectibles spawned")

if LOAD_LEVEL == 4 then
	print("[LOAD] ✅ STOPPED at LOAD_LEVEL 4 (+ NPCs/collectibles)")
	print("[LOAD] You should see: Terrain + structures + survivors + food/parts")
	onWorldReady()
	return
end

-- ==========================================
-- STAGE 5: FULL LOAD (STORY SYSTEM)
-- ==========================================

print("[LOAD] Stage 5: Initializing story system...")
local StoryBeatProcessor = require(script.Parent.Services.StoryBeatProcessor)
local ValidationService = require(script.Parent.Services.ValidationService)

StoryBeatProcessor:SetNarrativeService(NarrativeService)
StoryBeatProcessor:Initialize()
ValidationService:Initialize()

logStage(5, "Full load complete")

print("[LOAD] ✅ LOAD_LEVEL 5: Full game loaded")

-- Fire GAME_START for each player after they spawn (Level 5 only)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Once(function()
		task.delay(2, function()
			StoryBeatProcessor:FireEvent("GAME_START", player)
		end)
	end)
end)

onWorldReady()

-- ==========================================
-- DONE
-- ==========================================

local totalTime = tick() - SERVER_START
print("[FaultlineFear] ================================")
print(string.format("[FaultlineFear] Server ready in %.2f seconds", totalTime))
print("[FaultlineFear] ================================")
