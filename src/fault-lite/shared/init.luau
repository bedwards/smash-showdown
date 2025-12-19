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

-- Re-export TerrainCore itself and its modules
Shared.TerrainCore = TerrainCore
Shared.TerrainConfig = TerrainCore.Config
Shared.Heightmap = TerrainCore.Heightmap
Shared.PlacementUtils = TerrainCore.PlacementUtils

-- Fault-Lite specific config (minimal)
-- Note: EARTHQUAKE config is now in TerrainConfig (shared with Faultline Fear)
Shared.Config = {
	-- Showcase area size (much smaller than full game)
	SHOWCASE_SIZE = 200, -- 200x200 stud flat area

	-- Spawn position
	SPAWN_POSITION = Vector3.new(0, 35, 0),

	-- Structure showcase offset from player
	STRUCTURE_OFFSET = Vector3.new(0, 0, 50), -- 50 studs in front

	-- EARTHQUAKE config is in TerrainConfig.EARTHQUAKE (DRY - single source of truth)
}

return Shared
