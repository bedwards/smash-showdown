--!strict
--[[
	Fault-Lite: Server Main Script

	Minimal server for structure showcase testing.
	- Generates heightmap (shared with Faultline Fear)
	- Creates small terrain area around spawn
	- Spawns structures from cloud assets
	- Handles earthquake testing
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Wait for shared modules
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Heightmap = Shared.Heightmap
local Config = Shared.Config
local StructureEntity = Shared.TerrainCore.StructureEntity

-- ==========================================
-- REMOTE EVENTS
-- ==========================================

local Remotes = Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = ReplicatedStorage

local SpawnStructureEvent = Instance.new("RemoteEvent")
SpawnStructureEvent.Name = "SpawnStructure"
SpawnStructureEvent.Parent = Remotes

local TriggerEarthquakeEvent = Instance.new("RemoteEvent")
TriggerEarthquakeEvent.Name = "TriggerEarthquake"
TriggerEarthquakeEvent.Parent = Remotes

local ClearStructuresEvent = Instance.new("RemoteEvent")
ClearStructuresEvent.Name = "ClearStructures"
ClearStructuresEvent.Parent = Remotes

local HeightmapReady = Instance.new("RemoteEvent")
HeightmapReady.Name = "HeightmapReady"
HeightmapReady.Parent = Remotes

local ChangeSpawnPointEvent = Instance.new("RemoteEvent")
ChangeSpawnPointEvent.Name = "ChangeSpawnPoint"
ChangeSpawnPointEvent.Parent = Remotes

-- ==========================================
-- STATE
-- ==========================================

local structuresFolder: Folder
local currentStructure: Model?

-- ==========================================
-- TERRAIN GENERATION (Minimal)
-- ==========================================

-- Current spawn point for terrain generation
local currentSpawnX = 0
local currentSpawnZ = 0

local function generateTerrainAt(centerX: number, centerZ: number)
	print("[Fault-Lite] Generating terrain at X=" .. centerX .. ", Z=" .. centerZ)

	local terrain = Workspace.Terrain
	local showcaseSize = Config.SHOWCASE_SIZE
	local halfSize = showcaseSize / 2

	-- Get terrain height at center to determine Y range
	local centerHeight = Heightmap:GetHeight(centerX, centerZ)
	local minY = math.max(-50, centerHeight - 30)
	local maxY = centerHeight + 50

	local regionStart = Vector3.new(centerX - halfSize, minY, centerZ - halfSize)
	local regionEnd = Vector3.new(centerX + halfSize, maxY, centerZ + halfSize)

	local region = Region3.new(regionStart, regionEnd)
	region = region:ExpandToGrid(4)

	local size = region.Size / 4
	local sizeX = math.floor(size.X)
	local sizeY = math.floor(size.Y)
	local sizeZ = math.floor(size.Z)

	local materials = {}
	local occupancy = {}

	for x = 1, sizeX do
		materials[x] = {}
		occupancy[x] = {}
		for y = 1, sizeY do
			materials[x][y] = {}
			occupancy[x][y] = {}
			for z = 1, sizeZ do
				-- Get world position for this voxel
				local worldX = regionStart.X + (x - 0.5) * 4
				local worldZ = regionStart.Z + (z - 0.5) * 4
				local worldY = regionStart.Y + (y - 0.5) * 4

				local terrainHeight = Heightmap:GetHeight(worldX, worldZ)

				if worldY < terrainHeight then
					-- Use different materials based on zone
					local zone = Heightmap:GetZone(worldX, worldZ)
					local mat = Enum.Material.Grass
					if zone == "BEACH" or zone == "OCEAN" then
						mat = Enum.Material.Sand
					elseif zone == "MOUNTAIN" then
						mat = Enum.Material.Rock
					elseif zone == "FAULT_LINE" then
						mat = Enum.Material.Slate
					end
					materials[x][y][z] = mat
					occupancy[x][y][z] = 1
				else
					materials[x][y][z] = Enum.Material.Air
					occupancy[x][y][z] = 0
				end
			end
		end
	end

	terrain:WriteVoxels(region, 4, materials, occupancy)
	print("[Fault-Lite] Terrain generated at (" .. centerX .. ", " .. centerZ .. "), height=" .. math.floor(centerHeight))
end

local function generateMinimalTerrain()
	generateTerrainAt(currentSpawnX, currentSpawnZ)
end

-- ==========================================
-- STRUCTURE SPAWNING (Uses encapsulated StructureEntity)
-- ==========================================

local function clearCurrentStructure()
	if currentStructure then
		currentStructure:Destroy()
		currentStructure = nil
	end
end

--[[
	Spawns a structure at the given position using the encapsulated StructureEntity.
	All configuration (yOffset, sensitivity, rotation, colors) handled by StructureEntity.

	@param assetName The name of the asset to spawn
	@param x World X coordinate
	@param z World Z coordinate
	@param anchored Whether to anchor the structure (true) or let it drop (false)
	@param dropHeight Height above ground to drop from (only used if not anchored)
	@return The spawned model, or nil on failure
]]
local function spawnStructure(assetName: string, x: number, z: number, anchored: boolean, dropHeight: number?): Model?
	-- Validate asset name
	if not StructureEntity.isValidAsset(assetName) then
		warn("[Fault-Lite] Unknown asset: " .. assetName)
		return nil
	end

	-- Create entity and spawn using PlacementUtils (single source of truth)
	local entity = StructureEntity.new(assetName)
	return entity:spawn(x, z, {
		anchored = anchored,
		dropHeight = dropHeight or 8,
		parent = structuresFolder,
	})
end

--[[
	Spawns a structure with tilt for off-balance physics landing.
	@param assetName The name of the asset to spawn
	@param x World X coordinate
	@param z World Z coordinate
	@param dropHeight Height above ground to drop from
	@param tilt Tilt angle in degrees (causes off-balance landing)
	@return The spawned model, or nil on failure
]]
local function spawnStructureTilted(assetName: string, x: number, z: number, dropHeight: number, tilt: number): Model?
	-- Validate asset name
	if not StructureEntity.isValidAsset(assetName) then
		warn("[Fault-Lite] Unknown asset: " .. assetName)
		return nil
	end

	-- Create entity and spawn with tilt
	local entity = StructureEntity.new(assetName)
	return entity:spawn(x, z, {
		anchored = false,
		dropHeight = dropHeight,
		tilt = tilt,
		parent = structuresFolder,
	})
end

-- ==========================================
-- EARTHQUAKE SIMULATION
-- ==========================================

-- Get earthquake config from shared TerrainConfig (DRY - single source of truth)
local TerrainConfig = Shared.TerrainConfig

--[[
	Launch all unanchored structures into the air.
	Called when earthquake triggers - structures get thrown up and fall back down.
	Uses per-structure sensitivity from shared config (DRY).
]]
local function launchUnanchoredStructures(baseLaunchHeight: number)
	if baseLaunchHeight <= 0 then
		return
	end

	print("[Fault-Lite] Earthquake launch (base height: " .. baseLaunchHeight .. " studs)")

	local launchedCount = 0
	for _, model in structuresFolder:GetChildren() do
		if model:IsA("Model") then
			-- Check if ANY part is unanchored (if so, this is a droppable structure)
			local isUnanchored = false
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") and not part.Anchored then
					isUnanchored = true
					break
				end
			end

			if isUnanchored then
				-- Get per-structure sensitivity (stored as attribute, from shared config)
				local sensitivity = model:GetAttribute("Sensitivity") or 1.0
				local actualLaunchHeight = baseLaunchHeight * sensitivity

				if actualLaunchHeight > 0 then
					-- Move the model up by adjusted launch height
					local currentCFrame = model:GetPivot()
					model:PivotTo(currentCFrame + Vector3.new(0, actualLaunchHeight, 0))
					launchedCount = launchedCount + 1
					print("  " .. model.Name .. ": launched " .. string.format("%.1f", actualLaunchHeight) .. " studs (sensitivity=" .. sensitivity .. ")")
				end
			end
		end
	end

	print("[Fault-Lite] Launched " .. launchedCount .. " unanchored structures")
end

local function triggerEarthquake(earthquakeType: string)
	local config = TerrainConfig.EARTHQUAKE[earthquakeType]
	if not config then
		warn("[Fault-Lite] Unknown earthquake type: " .. earthquakeType)
		return
	end

	print("[Fault-Lite] Triggering earthquake: " .. earthquakeType .. " (launch=" .. config.launchHeight .. ")")

	-- Launch unanchored structures into the air
	launchUnanchoredStructures(config.launchHeight)

	-- Notify all clients (camera shake)
	TriggerEarthquakeEvent:FireAllClients(earthquakeType, config.duration, config.shake)

	-- If major earthquake, apply Big One terrain changes
	if earthquakeType == "MAJOR" then
		local applied = Heightmap:ApplyBigOneChanges()
		if applied then
			-- Regenerate terrain
			generateMinimalTerrain()
		end
	end
end

-- ==========================================
-- EVENT HANDLERS
-- ==========================================

--[[
	SpawnStructure remote event handler.
	Spawns FOUR versions of the structure for comparison:
	1. ANCHORED - Perfectly placed on ground, anchored (far left)
	2. ON GROUND - Placed on ground but NOT anchored (center-left)
	3. LOW DROP - Dropped from near ground (center-right)
	4. HIGH DROP - Dropped from high up (far right)
]]
SpawnStructureEvent.OnServerEvent:Connect(function(player, assetName, spawnPointName)
	print("[Fault-Lite] Spawning", assetName, "at", spawnPointName or "default")

	-- Find spawn point from TerrainConfig
	local spawnPoint = nil
	for _, point in ipairs(TerrainConfig.SPAWN_POINTS) do
		if point.name == spawnPointName then
			spawnPoint = point
			break
		end
	end

	-- Default to first spawn point if not found
	if not spawnPoint then
		spawnPoint = TerrainConfig.SPAWN_POINTS[1] or { name = "Spawn", x = 0, z = 0 }
	end

	-- Clear previous structures
	clearCurrentStructure()

	-- Calculate positions for quad spawn (spread across X axis)
	local forwardOffset = 60
	local spacing = 50  -- Increased from 30 to prevent rolling collisions
	local pos1 = spawnPoint.x - spacing * 1.5  -- Anchored (far left)
	local pos2 = spawnPoint.x - spacing * 0.5  -- On ground unanchored (center-left)
	local pos3 = spawnPoint.x + spacing * 0.5  -- Low drop (center-right)
	local pos4 = spawnPoint.x + spacing * 1.5  -- High drop (far right)
	local structZ = spawnPoint.z + forwardOffset

	-- Drop heights for comparison (tuned so water towers slowly crumble, not explode)
	-- Tilt makes structures less stable, so lower drop heights needed
	local LOW_DROP = 0.5   -- Drops from 0.5 studs - minimal settling
	local MED_DROP = 1     -- Drops from 1 stud - minor damage
	local HIGH_DROP = 3.5  -- Drops from 3.5 studs - significant damage
	local MED_TILT = 1.5   -- Slight tilt for off-balance landing
	local HIGH_TILT = 2.5  -- More tilt for dramatic landing

	-- Spawn ANCHORED version (far left, reference - no damage)
	local anchoredModel = spawnStructure(assetName, pos1, structZ, true)

	-- Spawn LOW DROP version (center-left, no tilt - lands flush)
	spawnStructure(assetName, pos2, structZ, false, LOW_DROP)

	-- Spawn MEDIUM DROP version (center-right, slight tilt)
	spawnStructureTilted(assetName, pos3, structZ, MED_DROP, MED_TILT)

	-- Spawn HIGH DROP version (far right, more tilt)
	spawnStructureTilted(assetName, pos4, structZ, HIGH_DROP, HIGH_TILT)

	-- Store reference (for clearing later)
	currentStructure = anchoredModel

	print("[Fault-Lite] Spawned quad structures at spawn point:", spawnPoint.name)
	print("  FAR LEFT: Anchored (reference, no damage)")
	print("  CENTER-LEFT: Drop " .. LOW_DROP .. " stud (flush landing)")
	print("  CENTER-RIGHT: Drop " .. MED_DROP .. " studs, tilt " .. MED_TILT .. "°")
	print("  FAR RIGHT: Drop " .. HIGH_DROP .. " studs, tilt " .. HIGH_TILT .. "°")
end)

TriggerEarthquakeEvent.OnServerEvent:Connect(function(player, earthquakeType)
	print("[Fault-Lite] Player", player.Name, "triggered earthquake:", earthquakeType)
	triggerEarthquake(earthquakeType)
end)

ClearStructuresEvent.OnServerEvent:Connect(function(player)
	print("[Fault-Lite] Player", player.Name, "clearing structures")
	clearCurrentStructure()
end)

--[[
	ChangeSpawnPoint: Regenerates terrain at a new spawn point location.
	Called from the Studio plugin when user selects a different spawn point.
]]
ChangeSpawnPointEvent.OnServerEvent:Connect(function(player, spawnPointName)
	print("[Fault-Lite] Player", player.Name, "changing spawn to:", spawnPointName)

	-- Find spawn point from TerrainConfig
	local spawnPoint = nil
	for _, point in ipairs(TerrainConfig.SPAWN_POINTS) do
		if point.name == spawnPointName then
			spawnPoint = point
			break
		end
	end

	if not spawnPoint then
		spawnPoint = TerrainConfig.SPAWN_POINTS[1] or { name = "Spawn", x = 0, z = 0 }
	end

	-- Update current spawn location
	currentSpawnX = spawnPoint.x
	currentSpawnZ = spawnPoint.z

	-- Clear old terrain and regenerate at new location
	Workspace.Terrain:Clear()
	generateTerrainAt(currentSpawnX, currentSpawnZ)

	-- Move SpawnLocation
	local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
	if spawnLocation then
		local terrainY = Heightmap:GetHeight(currentSpawnX, currentSpawnZ)
		spawnLocation.Position = Vector3.new(currentSpawnX, terrainY + 5, currentSpawnZ)
		print("[Fault-Lite] Moved SpawnLocation to", spawnPoint.name, "at Y=", math.floor(terrainY + 5))
	end

	-- Clear any existing structures
	clearCurrentStructure()
end)

-- ==========================================
-- INITIALIZATION
-- ==========================================

print("[Fault-Lite] Starting server...")

-- Create structures folder
structuresFolder = Instance.new("Folder")
structuresFolder.Name = "Structures"
structuresFolder.Parent = Workspace

-- Generate heightmap (uses shared TerrainCore)
print("[Fault-Lite] Generating heightmap...")
Heightmap:Generate()

-- Generate minimal terrain
generateMinimalTerrain()

-- Notify clients heightmap is ready
HeightmapReady:FireAllClients()

print("[Fault-Lite] Server ready!")
print("Available structures:", table.concat(StructureEntity.getAvailableAssets(), ", "))
