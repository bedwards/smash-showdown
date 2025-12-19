--!strict
--[[
	TerrainCore: Shared Heightmap Module

	THE SINGLE SOURCE OF TRUTH FOR TERRAIN HEIGHT.
	Shared between Faultline Fear and Fault-Lite.

	This module generates identical terrain for both games.
	Uses TerrainConfig for all parameters.

	Usage:
		local TerrainCore = require(path.to.TerrainCore)
		TerrainCore.Heightmap:Generate()
		local height = TerrainCore.Heightmap:GetHeight(x, z)
]]

local TerrainConfig = require(script.Parent.TerrainConfig)

local Heightmap = {}

-- ==========================================
-- CONSTANTS
-- ==========================================

local CELL_SIZE = 4 -- Studs per heightmap cell (matches terrain voxel)
local DEFAULT_HEIGHT = 0

-- ==========================================
-- STATE
-- ==========================================

local heightData: { [number]: { [number]: number } } = {}
local isGenerated: boolean = false
local worldSize: number = 0
local cellCount: number = 0
local seed: number = 0

-- Flattened areas for buildings
local flatAreas: { [string]: { x: number, z: number, radius: number, height: number } } = {}

-- Big One state
local bigOneApplied: boolean = false

-- ==========================================
-- NOISE FUNCTIONS
-- ==========================================

local function octaveNoise(
	x: number,
	z: number,
	octaves: number,
	persistence: number,
	scale: number,
	noiseSeed: number
): number
	local total = 0
	local maxValue = 0
	local amplitude = 1
	local frequency = 1

	for _ = 1, octaves do
		total += math.noise(x * frequency / scale, z * frequency / scale, noiseSeed) * amplitude
		maxValue += amplitude
		amplitude *= persistence
		frequency *= 2
	end

	return total / maxValue
end

local function ridgeNoise(x: number, z: number, scale: number, noiseSeed: number): number
	local n = math.noise(x / scale, z / scale, noiseSeed + 100)
	return 1 - math.abs(n)
end

-- ==========================================
-- COORDINATE CONVERSION
-- ==========================================

local function worldToCell(worldX: number, worldZ: number): (number, number)
	local halfWorld = worldSize / 2
	local cellX = math.floor((worldX + halfWorld) / CELL_SIZE) + 1
	local cellZ = math.floor((worldZ + halfWorld) / CELL_SIZE) + 1
	return cellX, cellZ
end

local function cellToWorld(cellX: number, cellZ: number): (number, number)
	local halfWorld = worldSize / 2
	local worldX = (cellX - 1) * CELL_SIZE - halfWorld + CELL_SIZE / 2
	local worldZ = (cellZ - 1) * CELL_SIZE - halfWorld + CELL_SIZE / 2
	return worldX, worldZ
end

local function isValidCell(cellX: number, cellZ: number): boolean
	return cellX >= 1 and cellX <= cellCount and cellZ >= 1 and cellZ <= cellCount
end

-- ==========================================
-- HEIGHT CALCULATION
-- ==========================================

local function calculateBaseHeight(worldX: number, worldZ: number): number
	local zones = TerrainConfig.ZONES
	local baseNoise = octaveNoise(worldX, worldZ, 4, 0.5, 200, seed)

	-- OCEAN ZONE (south)
	if worldZ <= zones.OCEAN.zMax then
		return TerrainConfig.OCEAN_LEVEL - 10
	end

	-- BEACH ZONE
	if worldZ <= zones.BEACH.zMax then
		local t = (worldZ - zones.OCEAN.zMax) / (zones.BEACH.zMax - zones.OCEAN.zMax)
		return TerrainConfig.OCEAN_LEVEL + t * 5 + baseNoise * 2
	end

	-- COASTAL ZONE
	if worldZ <= zones.COASTAL.zMax then
		local t = (worldZ - zones.BEACH.zMax) / (zones.COASTAL.zMax - zones.BEACH.zMax)
		return 5 + t * 15 + baseNoise * 5
	end

	-- VALLEY ZONE
	if worldZ <= zones.VALLEY.zMax then
		local t = (worldZ - zones.COASTAL.zMax) / (zones.VALLEY.zMax - zones.COASTAL.zMax)
		return 20 + t * 10 + baseNoise * 3
	end

	-- FAULT LINE ZONE
	if worldZ <= zones.FAULT_LINE.zMax then
		local zoneCenter = (zones.FAULT_LINE.zMin + zones.FAULT_LINE.zMax) / 2
		local distFromCenter = math.abs(worldZ - zoneCenter)
		local halfWidth = TerrainConfig.FAULT_LINE_WIDTH / 2

		if distFromCenter < halfWidth then
			local riftDepth = TerrainConfig.FAULT_LINE_DEPTH * (1 - distFromCenter / halfWidth)
			return 30 - riftDepth + octaveNoise(worldX, worldZ, 2, 0.5, 50, seed) * 10
		else
			local t = (worldZ - zones.VALLEY.zMax) / (zones.FAULT_LINE.zMax - zones.VALLEY.zMax)
			return 30 + t * 20 + baseNoise * 8
		end
	end

	-- FOREST ZONE
	if worldZ <= zones.FOREST.zMax then
		local t = (worldZ - zones.FAULT_LINE.zMax) / (zones.FOREST.zMax - zones.FAULT_LINE.zMax)
		local hillNoise = octaveNoise(worldX, worldZ, 5, 0.6, 150, seed)
		return 50 + t * 80 + hillNoise * 40
	end

	-- MOUNTAIN ZONE
	if worldZ <= zones.MOUNTAIN.zMax then
		local t = (worldZ - zones.FOREST.zMax) / (zones.MOUNTAIN.zMax - zones.FOREST.zMax)
		local mountainNoise = octaveNoise(worldX, worldZ, 6, 0.7, 100, seed)
		local ridge = ridgeNoise(worldX, worldZ, 80, seed)
		local height = 130 + t * 200 + mountainNoise * 80 + ridge * 60
		return math.min(height, TerrainConfig.MOUNTAIN_MAX_HEIGHT)
	end

	return DEFAULT_HEIGHT
end

-- ==========================================
-- GENERATION
-- ==========================================

function Heightmap:Generate(terrainSeed: number?, customWorldSize: number?)
	seed = terrainSeed or TerrainConfig.TERRAIN_SEED
	worldSize = customWorldSize or TerrainConfig.WORLD_SIZE
	cellCount = math.ceil(worldSize / CELL_SIZE)

	print("[Heightmap] Generating", cellCount, "x", cellCount, "heightmap (seed:", seed, ")")
	local startTime = tick()

	heightData = {}

	for cellX = 1, cellCount do
		heightData[cellX] = {}
		for cellZ = 1, cellCount do
			local worldX, worldZ = cellToWorld(cellX, cellZ)
			heightData[cellX][cellZ] = calculateBaseHeight(worldX, worldZ)
		end

		if cellX % math.ceil(cellCount / 10) == 0 then
			local progress = math.floor(cellX / cellCount * 100)
			print("[Heightmap] Generation progress:", progress .. "%")
		end
	end

	isGenerated = true
	local elapsed = tick() - startTime
	print(string.format("[Heightmap] Generated in %.2f seconds", elapsed))
end

function Heightmap:LoadFromData(data: { [number]: { [number]: number } }, size: number, terrainSeed: number)
	heightData = data
	worldSize = size
	cellCount = math.ceil(size / CELL_SIZE)
	seed = terrainSeed
	isGenerated = true
	print("[Heightmap] Loaded from data")
end

function Heightmap:GetData(): { [number]: { [number]: number } }
	return heightData
end

-- ==========================================
-- HEIGHT QUERIES
-- ==========================================

function Heightmap:GetHeightAtCell(cellX: number, cellZ: number): number
	if not isGenerated then
		warn("[Heightmap] Not generated yet!")
		return DEFAULT_HEIGHT
	end

	if not isValidCell(cellX, cellZ) then
		return DEFAULT_HEIGHT
	end

	return heightData[cellX][cellZ]
end

function Heightmap:GetHeight(worldX: number, worldZ: number): number
	if not isGenerated then
		warn("[Heightmap] Not generated yet!")
		return DEFAULT_HEIGHT
	end

	-- Check flattened areas first
	for _, area in pairs(flatAreas) do
		local dx = worldX - area.x
		local dz = worldZ - area.z
		if dx * dx + dz * dz <= area.radius * area.radius then
			return area.height
		end
	end

	local cellX, cellZ = worldToCell(worldX, worldZ)
	return self:GetHeightAtCell(cellX, cellZ)
end

function Heightmap:GetHeightInterpolated(worldX: number, worldZ: number): number
	if not isGenerated then
		return DEFAULT_HEIGHT
	end

	-- Check flattened areas first
	for _, area in pairs(flatAreas) do
		local dx = worldX - area.x
		local dz = worldZ - area.z
		if dx * dx + dz * dz <= area.radius * area.radius then
			return area.height
		end
	end

	local halfWorld = worldSize / 2
	local fx = (worldX + halfWorld) / CELL_SIZE
	local fz = (worldZ + halfWorld) / CELL_SIZE

	local x0 = math.floor(fx)
	local z0 = math.floor(fz)
	local x1 = x0 + 1
	local z1 = z0 + 1

	local tx = fx - x0
	local tz = fz - z0

	x0, z0 = x0 + 1, z0 + 1
	x1, z1 = x1 + 1, z1 + 1

	local h00 = self:GetHeightAtCell(x0, z0)
	local h10 = self:GetHeightAtCell(x1, z0)
	local h01 = self:GetHeightAtCell(x0, z1)
	local h11 = self:GetHeightAtCell(x1, z1)

	local h0 = h00 * (1 - tx) + h10 * tx
	local h1 = h01 * (1 - tx) + h11 * tx
	return h0 * (1 - tz) + h1 * tz
end

function Heightmap:SnapToTerrain(position: Vector3, offset: number?): Vector3
	local height = self:GetHeightInterpolated(position.X, position.Z)
	return Vector3.new(position.X, height + (offset or 0), position.Z)
end

-- ==========================================
-- TERRAIN MODIFICATION
-- ==========================================

function Heightmap:FlattenArea(centerX: number, centerZ: number, radius: number, targetHeight: number?): number
	if not isGenerated then
		warn("[Heightmap] Cannot flatten - not generated yet!")
		return DEFAULT_HEIGHT
	end

	local height = targetHeight
	if not height then
		local total = 0
		local count = 0
		local cellRadius = math.ceil(radius / CELL_SIZE)
		local centerCellX, centerCellZ = worldToCell(centerX, centerZ)

		for dx = -cellRadius, cellRadius do
			for dz = -cellRadius, cellRadius do
				local cellX = centerCellX + dx
				local cellZ = centerCellZ + dz
				if isValidCell(cellX, cellZ) then
					local dist = math.sqrt(dx * dx + dz * dz) * CELL_SIZE
					if dist <= radius then
						total += heightData[cellX][cellZ]
						count += 1
					end
				end
			end
		end

		height = count > 0 and (total / count) or DEFAULT_HEIGHT
	end

	local key = string.format("%d_%d", math.floor(centerX), math.floor(centerZ))
	flatAreas[key] = {
		x = centerX,
		z = centerZ,
		radius = radius,
		height = height,
	}

	local cellRadius = math.ceil(radius / CELL_SIZE)
	local centerCellX, centerCellZ = worldToCell(centerX, centerZ)

	for dx = -cellRadius, cellRadius do
		for dz = -cellRadius, cellRadius do
			local cellX = centerCellX + dx
			local cellZ = centerCellZ + dz
			if isValidCell(cellX, cellZ) then
				local dist = math.sqrt(dx * dx + dz * dz) * CELL_SIZE
				if dist <= radius then
					local blend = 1 - (dist / radius)
					blend = blend * blend
					local originalHeight = heightData[cellX][cellZ]
					heightData[cellX][cellZ] = originalHeight + (height - originalHeight) * blend
				end
			end
		end
	end

	return height
end

function Heightmap:GetFlatAreas(): { [string]: { x: number, z: number, radius: number, height: number } }
	return flatAreas
end

-- ==========================================
-- ZONE DETECTION
-- ==========================================

function Heightmap:GetZone(worldX: number, worldZ: number): string
	local zones = TerrainConfig.ZONES
	local _ = worldX

	if worldZ <= zones.OCEAN.zMax then
		return "Ocean"
	elseif worldZ <= zones.BEACH.zMax then
		return "Beach"
	elseif worldZ <= zones.COASTAL.zMax then
		return "Coastal"
	elseif worldZ <= zones.VALLEY.zMax then
		return "Valley"
	elseif worldZ <= zones.FAULT_LINE.zMax then
		return "Fault Line"
	elseif worldZ <= zones.FOREST.zMax then
		return "Forest"
	else
		return "Mountains"
	end
end

function Heightmap:GetMaterial(worldX: number, worldZ: number): Enum.Material
	local zone = self:GetZone(worldX, worldZ)
	local height = self:GetHeight(worldX, worldZ)

	if zone == "Ocean" then
		return Enum.Material.Sand
	elseif zone == "Beach" then
		return Enum.Material.Sand
	elseif zone == "Coastal" then
		local noise = octaveNoise(worldX, worldZ, 2, 0.5, 50, seed)
		if noise > 0.2 then
			return Enum.Material.LeafyGrass
		else
			return Enum.Material.Grass
		end
	elseif zone == "Valley" then
		local noise = octaveNoise(worldX, worldZ, 2, 0.5, 40, seed)
		if noise > -0.1 then
			return Enum.Material.LeafyGrass
		else
			return Enum.Material.Grass
		end
	elseif zone == "Fault Line" then
		return Enum.Material.Rock
	elseif zone == "Forest" then
		local noise = octaveNoise(worldX, worldZ, 2, 0.5, 100, seed)
		if noise > 0.3 then
			return Enum.Material.Rock
		elseif noise > -0.2 then
			return Enum.Material.LeafyGrass
		else
			return Enum.Material.Grass
		end
	else
		if height > 350 then
			return Enum.Material.Snow
		elseif height > 250 then
			return Enum.Material.Rock
		else
			return Enum.Material.Ground
		end
	end
end

-- ==========================================
-- STATE QUERIES
-- ==========================================

function Heightmap:IsGenerated(): boolean
	return isGenerated
end

function Heightmap:GetWorldSize(): number
	return worldSize
end

function Heightmap:GetCellSize(): number
	return CELL_SIZE
end

function Heightmap:GetCellCount(): number
	return cellCount
end

function Heightmap:GetSeed(): number
	return seed
end

-- ==========================================
-- THE BIG ONE
-- ==========================================

function Heightmap:ApplyBigOneChanges(): boolean
	if bigOneApplied then
		print("[Heightmap] The Big One changes already applied")
		return false
	end

	if not isGenerated then
		warn("[Heightmap] Cannot apply Big One - heightmap not generated!")
		return false
	end

	print("[Heightmap] THE BIG ONE - Applying permanent terrain changes...")
	local startTime = tick()

	local zones = TerrainConfig.ZONES
	local faultZoneCenter = (zones.FAULT_LINE.zMin + zones.FAULT_LINE.zMax) / 2

	local originalWidth = TerrainConfig.FAULT_LINE_WIDTH
	local originalDepth = TerrainConfig.FAULT_LINE_DEPTH

	local newWidth = originalWidth * 3
	local newDepth = originalDepth * 1.6
	local newHalfWidth = newWidth / 2

	local modifiedCells = 0

	for cellX = 1, cellCount do
		for cellZ = 1, cellCount do
			local worldX, worldZ = cellToWorld(cellX, cellZ)

			if worldZ >= zones.FAULT_LINE.zMin - 100 and worldZ <= zones.FAULT_LINE.zMax + 100 then
				local distFromCenter = math.abs(worldZ - faultZoneCenter)
				local originalHeight = heightData[cellX][cellZ]
				local newHeight = originalHeight

				if distFromCenter < newHalfWidth then
					local riftFactor = 1 - (distFromCenter / newHalfWidth)
					local collapseNoise = octaveNoise(worldX, worldZ, 4, 0.6, 20, seed + 999) * 15
					local riftDepth = newDepth * riftFactor + collapseNoise
					newHeight = 30 - riftDepth

					if riftFactor > 0.7 then
						local debrisNoise = octaveNoise(worldX, worldZ, 2, 0.5, 10, seed + 1000) * 8
						newHeight = newHeight + math.abs(debrisNoise)
					end
				elseif distFromCenter < newHalfWidth + 30 then
					local edgeFactor = (distFromCenter - newHalfWidth) / 30
					local collapseNoise = octaveNoise(worldX, worldZ, 3, 0.5, 30, seed + 999) * 20
					local targetEdgeHeight = 30 - newDepth * 0.3 + collapseNoise
					newHeight = targetEdgeHeight + (originalHeight - targetEdgeHeight) * edgeFactor
				end

				if math.abs(newHeight - originalHeight) > 0.1 then
					heightData[cellX][cellZ] = newHeight
					modifiedCells += 1
				end
			end
		end
	end

	bigOneApplied = true
	local elapsed = tick() - startTime

	print(
		string.format(
			"[Heightmap] Big One complete: %d cells modified, fault widened to %.0f studs (%.2fs)",
			modifiedCells,
			newWidth,
			elapsed
		)
	)

	return true
end

function Heightmap:IsBigOneApplied(): boolean
	return bigOneApplied
end

function Heightmap:SetBigOneApplied(applied: boolean)
	bigOneApplied = applied
end

-- ==========================================
-- EXPORT FOR BLENDER
-- ==========================================

--[[
	Export heightmap as a format Blender can import.
	Returns a string in PGM (Portable Graymap) format.

	Save to file and import as displacement map in Blender.
]]
function Heightmap:ExportPGM(): string
	if not isGenerated then
		error("[Heightmap] Cannot export - not generated yet!")
	end

	-- Find min/max for normalization
	local minHeight = math.huge
	local maxHeight = -math.huge

	for cellX = 1, cellCount do
		for cellZ = 1, cellCount do
			local h = heightData[cellX][cellZ]
			minHeight = math.min(minHeight, h)
			maxHeight = math.max(maxHeight, h)
		end
	end

	local range = maxHeight - minHeight
	if range == 0 then
		range = 1
	end

	-- Build PGM file
	local lines = {
		"P2", -- ASCII grayscale format
		string.format("%d %d", cellCount, cellCount),
		"65535", -- Max value (16-bit)
	}

	for cellZ = 1, cellCount do
		local row = {}
		for cellX = 1, cellCount do
			local h = heightData[cellX][cellZ]
			local normalized = (h - minHeight) / range
			local value = math.floor(normalized * 65535)
			table.insert(row, tostring(value))
		end
		table.insert(lines, table.concat(row, " "))
	end

	print(
		string.format(
			"[Heightmap] Exported PGM: %dx%d, height range %.1f to %.1f",
			cellCount,
			cellCount,
			minHeight,
			maxHeight
		)
	)

	return table.concat(lines, "\n")
end

--[[
	Get metadata for Blender import.
]]
function Heightmap:GetBlenderMetadata(): {
	cellCount: number,
	cellSize: number,
	worldSize: number,
	minHeight: number,
	maxHeight: number,
	seed: number,
}
	local minHeight = math.huge
	local maxHeight = -math.huge

	for cellX = 1, cellCount do
		for cellZ = 1, cellCount do
			local h = heightData[cellX][cellZ]
			minHeight = math.min(minHeight, h)
			maxHeight = math.max(maxHeight, h)
		end
	end

	return {
		cellCount = cellCount,
		cellSize = CELL_SIZE,
		worldSize = worldSize,
		minHeight = minHeight,
		maxHeight = maxHeight,
		seed = seed,
	}
end

return Heightmap
