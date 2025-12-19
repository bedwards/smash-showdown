--!strict
--[[
	Faultline Fear: Heightmap Re-export

	Re-exports the shared TerrainCore Heightmap for backward compatibility.
	ALL heightmap functionality lives in src/shared/TerrainCore/Heightmap.luau

	This file exists to maintain the existing require paths:
		local Heightmap = require(Shared.Heightmap)

	DRY PRINCIPLE: No duplicate logic - everything comes from TerrainCore.
]]

-- Handle Lune test environment (no game service)
local Heightmap: any
local success = pcall(function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TerrainCore = require(ReplicatedStorage:WaitForChild("TerrainCore"))
	Heightmap = TerrainCore.Heightmap
end)

-- Fallback for Lune tests - minimal stub
if not success then
	Heightmap = {
		GetHeight = function() return 0 end,
		GetZone = function() return "Valley" end,
		IsGenerated = function() return false end,
	}
end

return Heightmap
