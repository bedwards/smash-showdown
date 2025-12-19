--!strict
--[[
	Faultline Fear: Shared Module Entry Point

	Exports all shared modules for easy access.
	DRY PRINCIPLE: TerrainCore provides shared terrain functionality.

	Architecture:
	- TerrainCore (src/shared/TerrainCore) - Shared between all games
	  - Heightmap, PlacementUtils, TerrainConfig
	- Faultline Fear Shared - Game-specific modules
	  - Config (game settings, imports terrain from TerrainCore)
	  - StoryData, AssetManifest, etc.
]]

local Shared = {}

-- ==========================================
-- TERRAIN CORE (shared between all games)
-- ==========================================
-- Handle Lune test environment (no game service)
local TerrainCore: any
local success = pcall(function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	TerrainCore = require(ReplicatedStorage:WaitForChild("TerrainCore"))
end)

if success and TerrainCore then
	-- Export TerrainCore as a whole for direct access
	Shared.TerrainCore = TerrainCore

	-- Re-export key TerrainCore modules for convenience
	Shared.PlacementUtils = TerrainCore.PlacementUtils
	Shared.TerrainConfig = TerrainCore.Config
end

-- Heightmap is always loaded (has its own fallback for tests)
Shared.Heightmap = require(script.Heightmap)

-- ==========================================
-- GAME-SPECIFIC MODULES
-- ==========================================
Shared.Config = require(script.Config)
Shared.TerrainUtils = require(script.TerrainUtils)
Shared.InputService = require(script.InputService)
Shared.ObjectPool = require(script.ObjectPool)
Shared.StoryData = require(script.StoryData)
Shared.AssetManifest = require(script.AssetManifest)
Shared.AssetColors = require(script.AssetColors)

-- ==========================================
-- CONVENIENCE FUNCTIONS
-- ==========================================

-- Quick terrain height lookup (delegates to shared Heightmap)
Shared.getTerrainHeight = function(x: number, z: number): number
	return Shared.Heightmap:GetHeight(x, z)
end

-- Snap position to terrain (delegates to shared Heightmap)
Shared.snapToTerrain = function(position: Vector3, offset: number?): Vector3
	return Shared.Heightmap:SnapToTerrain(position, offset)
end

-- Audio utility: Check if a sound ID is valid (not a placeholder)
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
