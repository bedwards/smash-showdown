--!strict
--[[
	TerrainCore: Shared Terrain Configuration

	Core terrain constants shared between Faultline Fear and Fault-Lite.
	This is the SINGLE SOURCE OF TRUTH for terrain parameters.

	Both games import this module to ensure terrain generation is identical.
]]

export type ZoneDefinition = {
	zMin: number,
	zMax: number,
}

export type Zones = {
	MOUNTAIN: ZoneDefinition,
	FOREST: ZoneDefinition,
	FAULT_LINE: ZoneDefinition,
	VALLEY: ZoneDefinition,
	COASTAL: ZoneDefinition,
	BEACH: ZoneDefinition,
	OCEAN: ZoneDefinition,
}

export type SpawnPoint = {
	name: string,
	x: number,
	z: number,
	description: string,
}

export type TerrainConfig = {
	WORLD_SIZE: number,
	TERRAIN_SEED: number,
	MOUNTAIN_MAX_HEIGHT: number,
	FAULT_LINE_DEPTH: number,
	FAULT_LINE_WIDTH: number,
	OCEAN_LEVEL: number,
	ZONES: Zones,
	SPAWN_POINTS: {SpawnPoint},
}

local TerrainConfig: TerrainConfig = {
	-- World dimensions
	WORLD_SIZE = 4000,

	-- Terrain generation
	TERRAIN_SEED = 12345,
	MOUNTAIN_MAX_HEIGHT = 500,
	FAULT_LINE_DEPTH = 50,
	FAULT_LINE_WIDTH = 30,
	OCEAN_LEVEL = 0,

	-- Zone boundaries (Z axis, south to north)
	ZONES = {
		OCEAN = { zMin = -2000, zMax = -1200 },      -- South
		BEACH = { zMin = -1200, zMax = -800 },
		COASTAL = { zMin = -800, zMax = -200 },
		VALLEY = { zMin = -200, zMax = 400 },
		FAULT_LINE = { zMin = 400, zMax = 800 },     -- Center
		FOREST = { zMin = 800, zMax = 1500 },
		MOUNTAIN = { zMin = 1500, zMax = 2000 },     -- North
	},

	-- Named spawn points for testing placement across zones
	-- Heights are calculated dynamically from heightmap
	SPAWN_POINTS = {
		{ name = "Spawn", x = 0, z = 0, description = "Default spawn (flat area)" },
		{ name = "Beach", x = 0, z = -1000, description = "Beach zone, near waterline" },
		{ name = "Boardwalk", x = 200, z = -950, description = "Beach boardwalk area" },
		{ name = "Coastal", x = 0, z = -500, description = "Coastal hills" },
		{ name = "Valley", x = 0, z = 100, description = "Valley floor" },
		{ name = "FaultEdge", x = 0, z = 500, description = "Edge of fault line" },
		{ name = "FaultCenter", x = 0, z = 600, description = "Center of fault rift" },
		{ name = "Forest", x = 0, z = 1100, description = "Forest zone, rolling hills" },
		{ name = "ForestClearing", x = 300, z = 1200, description = "Forest clearing" },
		{ name = "MountainBase", x = 0, z = 1550, description = "Base of mountains" },
		{ name = "MountainSlope", x = 0, z = 1750, description = "Mountain slope" },
	},
}

return TerrainConfig
