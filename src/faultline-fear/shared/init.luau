--!strict
-- Faultline Fear: Shared Module Entry Point
-- Exports all shared modules for easy access

local Shared = {}

-- Core configuration
Shared.Config = require(script.Config)

-- Heightmap: THE source of truth for terrain height
Shared.Heightmap = require(script.Heightmap)

-- Utilities (TerrainUtils now wraps Heightmap for compatibility)
Shared.TerrainUtils = require(script.TerrainUtils)
Shared.InputService = require(script.InputService)

-- Re-export commonly used functions for convenience
-- These now use Heightmap internally for O(1) lookups
Shared.getTerrainHeight = function(x: number, z: number): number
	return Shared.Heightmap:GetHeight(x, z)
end

Shared.snapToTerrain = function(position: Vector3, offset: number?): Vector3
	return Shared.Heightmap:SnapToTerrain(position, offset)
end

return Shared
