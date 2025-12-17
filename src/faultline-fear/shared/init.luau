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
Shared.ObjectPool = require(script.ObjectPool)
Shared.StoryData = require(script.StoryData)
Shared.AssetManifest = require(script.AssetManifest)

-- Re-export commonly used functions for convenience
-- These now use Heightmap internally for O(1) lookups
Shared.getTerrainHeight = function(x: number, z: number): number
	return Shared.Heightmap:GetHeight(x, z)
end

Shared.snapToTerrain = function(position: Vector3, offset: number?): Vector3
	return Shared.Heightmap:SnapToTerrain(position, offset)
end

-- Audio utility: Check if a sound ID is valid (not a placeholder)
-- Use this before creating Sound objects to avoid "Failed to load sound" errors
Shared.isValidSoundId = function(soundId: string | number): boolean
	if type(soundId) == "number" then
		return soundId > 0
	end
	if type(soundId) == "string" then
		return soundId ~= "" and soundId ~= "rbxassetid://0" and soundId ~= "rbxassetid://"
	end
	return false
end

return Shared
