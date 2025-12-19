--!strict
--[[
	TerrainCore: Shared Terrain Module

	Provides terrain generation and height queries for all games.
	This is the single source of truth for terrain in this repository.

	Usage:
		local TerrainCore = require(ReplicatedStorage.TerrainCore)
		TerrainCore.Heightmap:Generate()
		local height = TerrainCore.Heightmap:GetHeight(x, z)
		local zone = TerrainCore.Heightmap:GetZone(x, z)
]]

local TerrainCore = {}

-- Export all modules
TerrainCore.Config = require(script.TerrainConfig)
TerrainCore.Heightmap = require(script.Heightmap)
TerrainCore.PlacementUtils = require(script.PlacementUtils)

return TerrainCore
