--!strict
--[[
	Faultline Fear: Terrain Utilities

	IMPORTANT: This module now wraps Heightmap for primary height queries.
	Raycasting is only used for validation and finding visual mesh surfaces.

	For height queries, use Heightmap directly or the convenience functions:
		Shared.getTerrainHeight(x, z)  -- O(1) lookup
		Shared.snapToTerrain(position, offset)
]]

local Workspace = game:GetService("Workspace")

-- Heightmap is the source of truth
local Heightmap = require(script.Parent.Heightmap)

local TerrainUtils = {}

-- ==========================================
-- PRIMARY HEIGHT QUERIES (via Heightmap)
-- ==========================================

--[[
	Get the terrain height at a given X, Z position.
	Uses Heightmap for O(1) lookup.
]]
function TerrainUtils.getTerrainHeight(x: number, z: number): number
	return Heightmap:GetHeight(x, z)
end

--[[
	Get terrain height with smooth interpolation.
	Slightly slower but smoother for player/camera positioning.
]]
function TerrainUtils.getTerrainHeightSmooth(x: number, z: number): number
	return Heightmap:GetHeightInterpolated(x, z)
end

--[[
	Snap a position to terrain, optionally adding a vertical offset.
]]
function TerrainUtils.snapToTerrain(position: Vector3, offset: number?): Vector3
	return Heightmap:SnapToTerrain(position, offset)
end

--[[
	Check if a position is accessible (not buried or floating too high).
]]
function TerrainUtils.isPositionAccessible(position: Vector3, tolerance: number?): boolean
	local tol = tolerance or 5
	local terrainHeight = Heightmap:GetHeight(position.X, position.Z)
	local heightDiff = position.Y - terrainHeight
	return heightDiff >= -1 and heightDiff <= tol
end

--[[
	Get the terrain material at a given position.
]]
function TerrainUtils.getTerrainMaterial(x: number, z: number): Enum.Material
	return Heightmap:GetMaterial(x, z)
end

--[[
	Get the zone name at a position.
]]
function TerrainUtils.getZone(x: number, z: number): string
	return Heightmap:GetZone(x, z)
end

--[[
	Check if a position is underwater.
]]
function TerrainUtils.isUnderwater(position: Vector3): boolean
	local Config = require(script.Parent.Config)
	return position.Y < Config.OCEAN_LEVEL
end

--[[
	Get the slope angle at a position (0 = flat, 90 = vertical).
	Uses heightmap sampling for efficiency.
]]
function TerrainUtils.getSlopeAngle(x: number, z: number): number
	local cellSize = Heightmap:GetCellSize()

	-- Sample heights in a cross pattern
	local _hCenter = Heightmap:GetHeight(x, z) -- Reference point (unused but documents intent)
	local hNorth = Heightmap:GetHeight(x, z + cellSize)
	local hSouth = Heightmap:GetHeight(x, z - cellSize)
	local hEast = Heightmap:GetHeight(x + cellSize, z)
	local hWest = Heightmap:GetHeight(x - cellSize, z)

	-- Calculate gradient
	local gradX = (hEast - hWest) / (2 * cellSize)
	local gradZ = (hNorth - hSouth) / (2 * cellSize)

	-- Slope magnitude
	local slope = math.sqrt(gradX * gradX + gradZ * gradZ)

	-- Convert to angle
	return math.deg(math.atan(slope))
end

--[[
	Get terrain normal vector at a position.
]]
function TerrainUtils.getTerrainNormal(x: number, z: number): Vector3
	local cellSize = Heightmap:GetCellSize()

	local hCenter = Heightmap:GetHeight(x, z)
	local hEast = Heightmap:GetHeight(x + cellSize, z)
	local hNorth = Heightmap:GetHeight(x, z + cellSize)

	-- Calculate normal from triangle
	local v1 = Vector3.new(cellSize, hEast - hCenter, 0)
	local v2 = Vector3.new(0, hNorth - hCenter, cellSize)

	return v2:Cross(v1).Unit
end

-- ==========================================
-- FLATTENING (for building placement)
-- ==========================================

--[[
	Flatten an area for building placement.
	Returns the height the area was flattened to.
]]
function TerrainUtils.flattenArea(centerX: number, centerZ: number, radius: number, targetHeight: number?): number
	return Heightmap:FlattenArea(centerX, centerZ, radius, targetHeight)
end

-- ==========================================
-- BATCH OPERATIONS
-- ==========================================

--[[
	Get terrain heights for multiple positions at once.
]]
function TerrainUtils.getTerrainHeightsBatch(positions: { { x: number, z: number } }): { number }
	local heights = {}
	for i, pos in ipairs(positions) do
		heights[i] = Heightmap:GetHeight(pos.x, pos.z)
	end
	return heights
end

-- ==========================================
-- RAYCAST VALIDATION (for mesh collisions)
-- ==========================================

--[[
	Raycast to find the actual visual surface height.
	Use this when you need to find Blender mesh surfaces, not terrain.
	Falls back to Heightmap if no hit.
]]
function TerrainUtils.raycastSurfaceHeight(x: number, z: number): number
	local rayOrigin = Vector3.new(x, 1000, z)
	local rayDirection = Vector3.new(0, -2000, 0)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {} -- Hit everything

	local result = Workspace:Raycast(rayOrigin, rayDirection, params)

	if result then
		return result.Position.Y
	end

	-- Fallback to heightmap
	return Heightmap:GetHeight(x, z)
end

--[[
	Validate that visual terrain matches heightmap.
	Useful for debugging Blender imports.
]]
function TerrainUtils.validateTerrainAlignment(x: number, z: number, tolerance: number?): boolean
	local tol = tolerance or 2

	local heightmapHeight = Heightmap:GetHeight(x, z)
	local visualHeight = TerrainUtils.raycastSurfaceHeight(x, z)

	local diff = math.abs(heightmapHeight - visualHeight)
	if diff > tol then
		warn(
			string.format(
				"[TerrainUtils] Misalignment at (%.0f, %.0f): Heightmap=%.1f, Visual=%.1f, Diff=%.1f",
				x,
				z,
				heightmapHeight,
				visualHeight,
				diff
			)
		)
		return false
	end

	return true
end

-- ==========================================
-- CACHE MANAGEMENT (for legacy compatibility)
-- ==========================================

--[[
	Clear cache - now a no-op since Heightmap doesn't cache per-query.
]]
function TerrainUtils.clearCache()
	-- Heightmap data is the cache, regenerate if needed
	print("[TerrainUtils] clearCache called - Heightmap data is persistent")
end

--[[
	Get cache stats - returns Heightmap stats instead.
]]
function TerrainUtils.getCacheStats(): { entries: number, size: number }
	local cellCount = Heightmap:GetCellCount()
	return {
		entries = cellCount * cellCount,
		size = cellCount * cellCount * 8, -- 8 bytes per number (Lua number)
	}
end

return TerrainUtils
