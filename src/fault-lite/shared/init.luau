--!strict
--[[
	Fault-Lite: Shared Module

	Re-exports TerrainCore for terrain functionality.
	Adds minimal Fault-Lite specific configuration.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = {}

-- Import TerrainCore from shared location
local TerrainCore = require(ReplicatedStorage:WaitForChild("TerrainCore"))

-- Re-export TerrainCore modules
Shared.TerrainConfig = TerrainCore.Config
Shared.Heightmap = TerrainCore.Heightmap
Shared.PlacementUtils = TerrainCore.PlacementUtils

-- Fault-Lite specific config (minimal)
Shared.Config = {
	-- Showcase area size (much smaller than full game)
	SHOWCASE_SIZE = 200, -- 200x200 stud flat area

	-- Spawn position
	SPAWN_POSITION = Vector3.new(0, 35, 0),

	-- Structure showcase offset from player
	STRUCTURE_OFFSET = Vector3.new(0, 0, 50), -- 50 studs in front

	-- Earthquake test durations
	EARTHQUAKE = {
		MINOR = { duration = 3, shake = 0.5 },
		MODERATE = { duration = 8, shake = 1.5 },
		MAJOR = { duration = 15, shake = 3.0 },
	},
}

return Shared
