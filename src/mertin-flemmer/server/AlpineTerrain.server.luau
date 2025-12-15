--!strict
-- Alpine Terrain Generator - OPTIMIZED VERSION
-- Uses WriteVoxels for batch terrain generation (100x faster)
--
-- IMPORTANT: This file uses Shared.getTerrainHeight() as the SINGLE SOURCE OF TRUTH
-- for terrain height calculations. Do NOT duplicate height logic here!

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for Shared module and import it
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

local terrain = Workspace.Terrain

-- ==========================================
-- CONFIGURATION
-- ==========================================

local TERRAIN_SIZE = 3500  -- Big epic world!
local RESOLUTION = 4       -- Terrain voxel size
local CHUNK_SIZE = 64      -- Chunks for WriteVoxels batching

-- Height parameters (for material selection only)
local WATER_LEVEL = -5
local SNOW_LINE = 250
local TREELINE = 180

-- Signal when terrain is ready
local TerrainReady = Instance.new("BindableEvent")
TerrainReady.Name = "TerrainReady"
TerrainReady.Parent = ReplicatedStorage

-- ==========================================
-- HEIGHT CALCULATION - USES SHARED MODULE
-- ==========================================

-- Single source of truth for terrain height
local function calculateHeight(x: number, z: number): number
	return Shared.getTerrainHeight(x, z)
end

-- ==========================================
-- MATERIAL SELECTION (simplified)
-- ==========================================

local function getMaterial(height: number, slope: number): Enum.Material
	if height > SNOW_LINE then
		return Enum.Material.Snow
	elseif slope > 0.7 then
		return Enum.Material.Rock
	elseif height > TREELINE then
		return Enum.Material.Ground
	elseif height < 20 then
		return Enum.Material.LeafyGrass
	else
		return Enum.Material.Grass
	end
end

-- ==========================================
-- OPTIMIZED TERRAIN GENERATION
-- Uses WriteVoxels for MASSIVE speed improvement
-- ==========================================

local function generateTerrainChunk(startX: number, startZ: number, size: number)
	local voxelsX = math.ceil(size / RESOLUTION)
	local voxelsZ = math.ceil(size / RESOLUTION)

	-- Pre-calculate all heights for this chunk
	local heights = {}
	local slopes = {}
	local maxHeight = -math.huge
	local minHeight = math.huge

	for ix = 0, voxelsX - 1 do
		heights[ix] = {}
		slopes[ix] = {}
		for iz = 0, voxelsZ - 1 do
			local worldX = startX + ix * RESOLUTION
			local worldZ = startZ + iz * RESOLUTION
			local h = calculateHeight(worldX, worldZ)
			heights[ix][iz] = h
			maxHeight = math.max(maxHeight, h)
			minHeight = math.min(minHeight, h)
		end
	end

	-- Calculate slopes
	for ix = 0, voxelsX - 2 do
		for iz = 0, voxelsZ - 2 do
			local h0 = heights[ix][iz]
			local hx = heights[ix + 1][iz]
			local hz = heights[ix][iz + 1]
			local dx = (hx - h0) / RESOLUTION
			local dz = (hz - h0) / RESOLUTION
			slopes[ix][iz] = math.sqrt(dx * dx + dz * dz)
		end
		slopes[ix][voxelsZ - 1] = 0
	end
	for iz = 0, voxelsZ - 1 do
		slopes[voxelsX - 1] = slopes[voxelsX - 1] or {}
		slopes[voxelsX - 1][iz] = 0
	end

	-- Determine Y range for this chunk
	local minY = math.floor(math.min(minHeight, WATER_LEVEL) / RESOLUTION) * RESOLUTION - RESOLUTION
	local maxY = math.ceil(maxHeight / RESOLUTION) * RESOLUTION + RESOLUTION
	local voxelsY = math.ceil((maxY - minY) / RESOLUTION)

	-- Limit Y range to prevent massive arrays
	voxelsY = math.min(voxelsY, 100)
	maxY = minY + voxelsY * RESOLUTION

	-- Create region
	local region = Region3.new(
		Vector3.new(startX, minY, startZ),
		Vector3.new(startX + size, maxY, startZ + size)
	):ExpandToGrid(RESOLUTION)

	-- Read current voxels (for proper sizing)
	local materials, occupancies = terrain:ReadVoxels(region, RESOLUTION)

	-- Fill arrays
	for ix = 1, #materials do
		for iy = 1, #materials[ix] do
			for iz = 1, #materials[ix][iy] do
				local worldX = startX + (ix - 1) * RESOLUTION
				local worldY = minY + (iy - 1) * RESOLUTION
				local worldZ = startZ + (iz - 1) * RESOLUTION

				local heightIdx = math.min(ix - 1, voxelsX - 1)
				local depthIdx = math.min(iz - 1, voxelsZ - 1)
				local height = heights[heightIdx] and heights[heightIdx][depthIdx] or 10
				local slope = slopes[heightIdx] and slopes[heightIdx][depthIdx] or 0

				if worldY <= height then
					materials[ix][iy][iz] = getMaterial(height, slope)
					if worldY > height - RESOLUTION then
						occupancies[ix][iy][iz] = math.max(0, (height - worldY + RESOLUTION) / RESOLUTION)
					else
						occupancies[ix][iy][iz] = 1
					end
				elseif worldY <= WATER_LEVEL then
					materials[ix][iy][iz] = Enum.Material.Water
					occupancies[ix][iy][iz] = 1
				else
					materials[ix][iy][iz] = Enum.Material.Air
					occupancies[ix][iy][iz] = 0
				end
			end
		end
	end

	-- Write all voxels at once (MUCH faster than individual FillRegion calls)
	terrain:WriteVoxels(region, RESOLUTION, materials, occupancies)
end

-- ==========================================
-- WILDFLOWER VALLEYS (reduced count)
-- ==========================================

local function createValleyFlowers()
	print("[Alpine] Creating valley wildflowers...")

	local colors = {
		Color3.fromRGB(255, 100, 100),
		Color3.fromRGB(255, 200, 100),
		Color3.fromRGB(200, 100, 255),
		Color3.fromRGB(255, 150, 200),
		Color3.fromRGB(100, 200, 255),
	}

	local flowers = Instance.new("Folder")
	flowers.Name = "Wildflowers"

	-- Create flower patches throughout valleys
	local patchCount = 0
	local step = 150  -- More patches for lush valleys

	for x = -TERRAIN_SIZE/2, TERRAIN_SIZE/2, step do
		for z = -TERRAIN_SIZE/2, TERRAIN_SIZE/2, step do
			local height = calculateHeight(x, z)

			if height < 40 and height > WATER_LEVEL + 5 then
				-- Create a small cluster of flowers (5-10 per patch)
				for _ = 1, math.random(5, 10) do
					local ox = x + (math.random() - 0.5) * 30
					local oz = z + (math.random() - 0.5) * 30
					local h = calculateHeight(ox, oz)

					local flower = Instance.new("Part")
					flower.Name = "Flower"
					flower.Size = Vector3.new(0.3, 0.8, 0.3)
					flower.Position = Vector3.new(ox, h + 0.4, oz)
					flower.Color = colors[math.random(1, #colors)]
					flower.Material = Enum.Material.SmoothPlastic
					flower.Anchored = true
					flower.CanCollide = false
					flower.CastShadow = false  -- Performance boost
					flower.Parent = flowers
				end
				patchCount = patchCount + 1
			end
		end
		task.wait()  -- Yield between rows
	end

	flowers.Parent = Workspace
	print("[Alpine] Created", patchCount, "wildflower patches")
end

-- ==========================================
-- WATER BODIES
-- ==========================================

local function createWaterBodies()
	print("[Alpine] Creating alpine lakes...")

	local lakes = {
		{ pos = Vector3.new(-150, WATER_LEVEL, 100), rx = 60, rz = 80, name = "Mirror Lake" },
		{ pos = Vector3.new(100, WATER_LEVEL, -150), rx = 40, rz = 50, name = "Shadow Pool" },
		{ pos = Vector3.new(-300, WATER_LEVEL, -100), rx = 70, rz = 60, name = "Crystal Lake" },
	}

	for _, lake in ipairs(lakes) do
		local part = Instance.new("Part")
		part.Name = lake.name
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(5, lake.rx * 2, lake.rz * 2)
		part.CFrame = CFrame.new(lake.pos) * CFrame.Angles(0, 0, math.rad(90))
		part.Color = Color3.fromRGB(40, 80, 140)
		part.Material = Enum.Material.Water
		part.Transparency = 0.3
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false
		part.Parent = Workspace
	end
end

-- ==========================================
-- MAIN GENERATION
-- ==========================================

local function generateAllTerrain()
	local startTime = tick()
	print("[Alpine] Starting OPTIMIZED terrain generation...")
	print("[Alpine] World size:", TERRAIN_SIZE, "studs")

	-- Generate terrain in chunks using WriteVoxels
	local chunkCount = math.ceil(TERRAIN_SIZE / CHUNK_SIZE)
	local halfSize = TERRAIN_SIZE / 2
	local totalChunks = chunkCount * chunkCount
	local processed = 0

	-- Generate center first (where player spawns)
	local centerChunks = {}
	local outerChunks = {}

	for cx = 0, chunkCount - 1 do
		for cz = 0, chunkCount - 1 do
			local startX = -halfSize + cx * CHUNK_SIZE
			local startZ = -halfSize + cz * CHUNK_SIZE
			local distFromCenter = math.sqrt(startX^2 + startZ^2)

			if distFromCenter < 300 then
				table.insert(centerChunks, {startX, startZ})
			else
				table.insert(outerChunks, {startX, startZ})
			end
		end
	end

	-- Generate center chunks first (player spawns here)
	print("[Alpine] Generating spawn area first...")
	for _, chunk in ipairs(centerChunks) do
		generateTerrainChunk(chunk[1], chunk[2], CHUNK_SIZE)
		processed = processed + 1
		task.wait()
	end

	print("[Alpine] Spawn area ready! Generating rest of world...")
	TerrainReady:Fire()  -- Signal that spawn area is ready

	-- Generate outer chunks
	for i, chunk in ipairs(outerChunks) do
		generateTerrainChunk(chunk[1], chunk[2], CHUNK_SIZE)
		processed = processed + 1

		if i % 20 == 0 then
			print("[Alpine] Progress:", math.floor(processed / totalChunks * 100) .. "%")
			task.wait()
		end
	end

	-- Add decorations
	createWaterBodies()
	createValleyFlowers()

	local elapsed = tick() - startTime
	print("[Alpine] Terrain generation complete in", string.format("%.1f", elapsed), "seconds!")
end

-- ==========================================
-- RUN
-- ==========================================

-- Check if terrain already exists
local existingTerrain = terrain:ReadVoxels(
	Region3.new(Vector3.new(-10, -10, -10), Vector3.new(10, 10, 10)),
	RESOLUTION
)

local hasExistingTerrain = false
for _, plane in ipairs(existingTerrain) do
	for _, row in ipairs(plane) do
		for _, mat in ipairs(row) do
			if mat ~= Enum.Material.Air then
				hasExistingTerrain = true
				break
			end
		end
		if hasExistingTerrain then break end
	end
	if hasExistingTerrain then break end
end

if not hasExistingTerrain then
	task.spawn(generateAllTerrain)
else
	print("[Alpine] Terrain already exists, skipping generation")
	TerrainReady:Fire()
end
