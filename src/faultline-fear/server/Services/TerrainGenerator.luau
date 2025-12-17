--!strict
--[[
	Faultline Fear: Terrain Generator

	LOADING SEQUENCE:
	1. Generate Heightmap (fast, deterministic)
	2. Gameplay systems can now query heights
	3. Generate visual terrain FROM Heightmap (can stream)
	4. Player spawns when spawn area is ready

	This separation means:
	- Height queries are instant (O(1) from Heightmap)
	- Visual terrain can load progressively
	- Blender meshes can be added that match Heightmap exactly
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config
local Heightmap = Shared.Heightmap

local TerrainGenerator = {}

-- State
local isHeightmapReady: boolean = false
local isVisualTerrainReady: boolean = false

-- ==========================================
-- HEIGHTMAP GENERATION (Phase 1 - Required)
-- ==========================================

--[[
	Generate the heightmap data.
	This MUST complete before any gameplay systems start.
	Returns true when complete.
]]
function TerrainGenerator:GenerateHeightmap(): boolean
	if isHeightmapReady then
		print("[TerrainGenerator] Heightmap already generated")
		return true
	end

	print("[TerrainGenerator] Phase 1: Generating heightmap...")
	local startTime = tick()

	Heightmap:Generate(Config.TERRAIN_SEED)

	isHeightmapReady = true
	local elapsed = tick() - startTime
	print(string.format("[TerrainGenerator] Heightmap ready in %.2f seconds", elapsed))

	-- Log stats
	local stats = Heightmap:GetBlenderMetadata()
	print(
		string.format(
			"[TerrainGenerator] Grid: %dx%d cells, Height range: %.0f to %.0f",
			stats.cellCount,
			stats.cellCount,
			stats.minHeight,
			stats.maxHeight
		)
	)

	return true
end

--[[
	Check if heightmap is ready for queries.
]]
function TerrainGenerator:IsHeightmapReady(): boolean
	return isHeightmapReady
end

-- ==========================================
-- VISUAL TERRAIN GENERATION (Phase 2 - Can Stream)
-- ==========================================

--[[
	Generate visual Roblox terrain FROM the heightmap.
	This can run async while gameplay starts.
]]
function TerrainGenerator:GenerateVisualTerrain()
	-- Check the actual Heightmap module, not just internal flag
	if not Heightmap:IsGenerated() then
		error("[TerrainGenerator] Cannot generate visual terrain - heightmap not ready!")
	end

	if isVisualTerrainReady then
		print("[TerrainGenerator] Visual terrain already generated")
		return
	end

	print("[TerrainGenerator] Phase 2: Generating visual terrain...")
	local startTime = tick()

	local terrain = Workspace.Terrain
	terrain:Clear()

	local worldSize = Config.WORLD_SIZE
	local halfWorld = worldSize / 2
	local voxelSize = 4 -- Roblox terrain voxel resolution
	local chunkSize = 64

	-- Count chunks
	local totalChunks = 0
	for _ = -halfWorld, halfWorld - chunkSize, chunkSize do
		for _ = -halfWorld, halfWorld - chunkSize, chunkSize do
			totalChunks += 1
		end
	end

	-- Generate each chunk from heightmap data
	local generatedChunks = 0
	for chunkX = -halfWorld, halfWorld - chunkSize, chunkSize do
		for chunkZ = -halfWorld, halfWorld - chunkSize, chunkSize do
			self:GenerateVisualChunk(chunkX, chunkZ, chunkSize, voxelSize)
			generatedChunks += 1

			-- Progress update
			if generatedChunks % math.ceil(totalChunks / 10) == 0 then
				local progress = math.floor(generatedChunks / totalChunks * 100)
				print(string.format("[TerrainGenerator] Visual terrain: %d%%", progress))
			end

			-- Yield to prevent timeout
			if generatedChunks % 16 == 0 then
				task.wait()
			end
		end
	end

	-- Generate ocean water
	self:GenerateOcean()

	isVisualTerrainReady = true
	local elapsed = tick() - startTime
	print(string.format("[TerrainGenerator] Visual terrain complete in %.2f seconds", elapsed))

	-- Signal completion via attribute (for external scripts like screenshot capture)
	terrain:SetAttribute("VisualTerrainReady", true)
	terrain:SetAttribute("VisualTerrainGeneratedAt", tick())
end

--[[
	Generate a single chunk of visual terrain from heightmap.
]]
function TerrainGenerator:GenerateVisualChunk(startX: number, startZ: number, size: number, voxelSize: number)
	local terrain = Workspace.Terrain
	local voxelsPerAxis = math.floor(size / voxelSize)

	-- Pre-allocate 3D arrays
	local materials: { { { Enum.Material } } } = {}
	local occupancy: { { { number } } } = {}

	for xi = 1, voxelsPerAxis do
		materials[xi] = {}
		occupancy[xi] = {}

		for yi = 1, voxelsPerAxis do
			materials[xi][yi] = {}
			occupancy[xi][yi] = {}

			for zi = 1, voxelsPerAxis do
				materials[xi][yi][zi] = Enum.Material.Air
				occupancy[xi][yi][zi] = 0
			end
		end
	end

	-- Fill from heightmap
	for xi = 1, voxelsPerAxis do
		local worldX = startX + (xi - 0.5) * voxelSize

		for zi = 1, voxelsPerAxis do
			local worldZ = startZ + (zi - 0.5) * voxelSize

			-- Query heightmap (O(1) lookup!)
			local height = Heightmap:GetHeight(worldX, worldZ)
			local material = Heightmap:GetMaterial(worldX, worldZ)

			-- Fill voxels up to height
			for yi = 1, voxelsPerAxis do
				local worldY = (yi - 0.5) * voxelSize

				if worldY <= height then
					materials[xi][yi][zi] = material
					occupancy[xi][yi][zi] = 1
				elseif worldY <= height + voxelSize then
					-- Surface voxel - partial for smoothness
					local surfaceBlend = 1 - (worldY - height) / voxelSize
					occupancy[xi][yi][zi] = math.clamp(surfaceBlend, 0, 1)
					materials[xi][yi][zi] = material
				end
			end
		end
	end

	-- Write to terrain
	local region = Region3.new(Vector3.new(startX, 0, startZ), Vector3.new(startX + size, size, startZ + size))
		:ExpandToGrid(voxelSize)

	terrain:WriteVoxels(region, voxelSize, materials, occupancy)
end

--[[
	Generate ocean water.
]]
function TerrainGenerator:GenerateOcean()
	print("[TerrainGenerator] Generating ocean...")

	local terrain = Workspace.Terrain
	local halfWorld = Config.WORLD_SIZE / 2
	local zones = Config.ZONES
	local voxelSize = 4

	local oceanDepth = 30
	local oceanRegion = Region3.new(
		Vector3.new(-halfWorld, Config.OCEAN_LEVEL - oceanDepth, zones.OCEAN.zMin),
		Vector3.new(halfWorld, Config.OCEAN_LEVEL, zones.BEACH.zMax)
	):ExpandToGrid(voxelSize)

	terrain:FillRegion(oceanRegion, voxelSize, Enum.Material.Water)
end

--[[
	Check if visual terrain is ready.
]]
function TerrainGenerator:IsVisualTerrainReady(): boolean
	return isVisualTerrainReady
end

-- ==========================================
-- BUILDING PLACEMENT
-- ==========================================

--[[
	Prepare a flat area for a building.
	Call this BEFORE placing the building model.
	Returns the height the building should be placed at.
]]
function TerrainGenerator:PrepareBuilding(
	centerX: number,
	centerZ: number,
	radius: number,
	targetHeight: number?
): number
	if not Heightmap:IsGenerated() then
		error("[TerrainGenerator] Cannot prepare building - heightmap not ready!")
	end

	-- Flatten the heightmap area
	local flatHeight = Heightmap:FlattenArea(centerX, centerZ, radius, targetHeight)

	-- If visual terrain is ready, update it too
	if isVisualTerrainReady then
		-- Regenerate affected chunks
		local chunkSize = 64
		local minChunkX = math.floor((centerX - radius + Config.WORLD_SIZE / 2) / chunkSize) * chunkSize
			- Config.WORLD_SIZE / 2
		local maxChunkX = math.floor((centerX + radius + Config.WORLD_SIZE / 2) / chunkSize) * chunkSize
			- Config.WORLD_SIZE / 2
		local minChunkZ = math.floor((centerZ - radius + Config.WORLD_SIZE / 2) / chunkSize) * chunkSize
			- Config.WORLD_SIZE / 2
		local maxChunkZ = math.floor((centerZ + radius + Config.WORLD_SIZE / 2) / chunkSize) * chunkSize
			- Config.WORLD_SIZE / 2

		for chunkX = minChunkX, maxChunkX, chunkSize do
			for chunkZ = minChunkZ, maxChunkZ, chunkSize do
				self:GenerateVisualChunk(chunkX, chunkZ, chunkSize, 4)
			end
		end
	end

	return flatHeight
end

-- ==========================================
-- THE BIG ONE - TERRAIN REGENERATION
-- ==========================================

--[[
	Regenerate visual terrain for the fault line area after The Big One.
	This updates the Roblox Terrain voxels to match the modified heightmap.
]]
function TerrainGenerator:RegenerateFaultLineArea()
	if not Heightmap:IsGenerated() then
		warn("[TerrainGenerator] Cannot regenerate - heightmap not ready!")
		return
	end

	print("[TerrainGenerator] Regenerating fault line area after The Big One...")
	local startTime = tick()

	local zones = Config.ZONES
	local halfWorld = Config.WORLD_SIZE / 2
	local chunkSize = 64
	local voxelSize = 4

	-- Calculate affected Z range (fault line plus buffer)
	local affectedZMin = zones.FAULT_LINE.zMin - 150
	local affectedZMax = zones.FAULT_LINE.zMax + 150

	-- Convert to chunk coordinates
	local minChunkZ = math.floor((affectedZMin + halfWorld) / chunkSize) * chunkSize - halfWorld
	local maxChunkZ = math.ceil((affectedZMax + halfWorld) / chunkSize) * chunkSize - halfWorld

	-- Regenerate all chunks in the X direction for the affected Z range
	local chunksRegenerated = 0
	for chunkX = -halfWorld, halfWorld - chunkSize, chunkSize do
		for chunkZ = minChunkZ, maxChunkZ, chunkSize do
			-- Make sure chunk is within world bounds
			if chunkZ >= -halfWorld and chunkZ < halfWorld then
				self:GenerateVisualChunk(chunkX, chunkZ, chunkSize, voxelSize)
				chunksRegenerated += 1
			end
		end

		-- Yield to prevent timeout
		if chunksRegenerated % 8 == 0 then
			task.wait()
		end
	end

	local elapsed = tick() - startTime
	print(
		string.format(
			"[TerrainGenerator] Fault line regeneration complete: %d chunks in %.2fs",
			chunksRegenerated,
			elapsed
		)
	)
end

-- ==========================================
-- BLENDER EXPORT
-- ==========================================

--[[
	Export heightmap for Blender.
	Prints instructions and returns PGM data.
]]
function TerrainGenerator:ExportForBlender(): string
	if not Heightmap:IsGenerated() then
		error("[TerrainGenerator] Cannot export - heightmap not ready!")
	end

	local metadata = Heightmap:GetBlenderMetadata()
	local pgmData = Heightmap:ExportPGM()

	print("=== BLENDER EXPORT INSTRUCTIONS ===")
	print("1. Save the PGM data to a file (e.g., heightmap.pgm)")
	print("2. In Blender, create a plane:")
	print(string.format("   - Size: %d x %d (matching world size)", metadata.worldSize, metadata.worldSize))
	print("   - Subdivisions: " .. metadata.cellCount)
	print("3. Add Displace modifier:")
	print("   - Texture: Load heightmap.pgm as Image texture")
	print(string.format("   - Strength: %.0f (height range)", metadata.maxHeight - metadata.minHeight))
	print(string.format("   - Midlevel: %.3f", -metadata.minHeight / (metadata.maxHeight - metadata.minHeight)))
	print("4. Apply scale: 0.01 for Roblox import")
	print("5. Export as FBX with 'Apply Transform' checked")
	print("=== END INSTRUCTIONS ===")

	return pgmData
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function TerrainGenerator:Initialize()
	print("[TerrainGenerator] Initialized")
	print("[TerrainGenerator] Call GenerateHeightmap() then GenerateVisualTerrain()")
end

--[[
	Full generation (heightmap + visual).
	Use this for simple cases where you want everything at once.
]]
function TerrainGenerator:Generate()
	self:GenerateHeightmap()
	self:GenerateVisualTerrain()
end

return TerrainGenerator
