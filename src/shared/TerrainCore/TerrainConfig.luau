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

export type EarthquakeConfig = {
	duration: number,      -- How long the screen shakes
	shake: number,         -- Shake intensity
	launchHeight: number,  -- How high unanchored structures get thrown
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
	EARTHQUAKE: {[string]: EarthquakeConfig},
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

	-- Earthquake configuration (shared between Fault-Lite and Faultline Fear)
	-- launchHeight = how high unanchored structures get thrown up
	-- Tuned down - structures are fragile!
	EARTHQUAKE = {
		-- Fault-Lite named types
		MINOR = { duration = 3, shake = 0.5, launchHeight = 2 },      -- Gentle bump
		MODERATE = { duration = 8, shake = 1.5, launchHeight = 3 },   -- Slightly more than minor
		MAJOR = { duration = 15, shake = 3.0, launchHeight = 15 },    -- The Big One

		-- Launch height multiplier for magnitude-based calculation (Faultline Fear)
		-- launchHeight = magnitude * LAUNCH_MULTIPLIER
		LAUNCH_MULTIPLIER = 15,
	},

	-- Per-structure configuration for placement and physics
	-- yOffset: Extra Y offset when placing on ground (fixes buried structures)
	-- sensitivity: Multiplier for earthquake launch height (lower = more fragile)
	-- dropMultiplier: Multiplier for initial drop heights (lower = gentler drops)
	-- rotationX/Y/Z: Rotation correction in degrees (fixes tilted models)
	STRUCTURES = {
		-- Default values for structures not listed
		DEFAULT = { yOffset = 0, sensitivity = 1.0, dropMultiplier = 1.0, rotationX = 0, rotationY = 0, rotationZ = 0 },

		-- Water tower works perfectly - don't change
		WaterTower = { yOffset = 0, sensitivity = 1.0, dropMultiplier = 1.0, rotationX = 0, rotationY = 0, rotationZ = 0 },

		-- Ferris wheel: buried when anchored, very fragile, needs rotation fix
		FerrisWheel = { yOffset = 8, sensitivity = 0.3, dropMultiplier = 0.3, rotationX = 0, rotationY = 0, rotationZ = 90 },

		-- Other structures (tune as needed)
		RadioTower = { yOffset = 0, sensitivity = 1.0, dropMultiplier = 1.0, rotationX = 0, rotationY = 0, rotationZ = 0 },
		Lighthouse = { yOffset = 0, sensitivity = 1.0, dropMultiplier = 1.0, rotationX = 0, rotationY = 0, rotationZ = 0 },
		AbandonedHouse = { yOffset = 0, sensitivity = 1.0, dropMultiplier = 1.0, rotationX = 0, rotationY = 0, rotationZ = 0 },
		Bridge = { yOffset = 0, sensitivity = 1.0, dropMultiplier = 1.0, rotationX = 0, rotationY = 0, rotationZ = 0 },
	},
}

--[[
	Calculate launch height from earthquake magnitude.
	Used by both Fault-Lite and Faultline Fear for consistent behavior.
	@param magnitude Earthquake magnitude (0.0 to 1.0)
	@return Launch height in studs
]]
function TerrainConfig.GetLaunchHeight(magnitude: number): number
	return magnitude * TerrainConfig.EARTHQUAKE.LAUNCH_MULTIPLIER
end

--[[
	Get structure-specific configuration.
	@param assetName The name of the structure asset
	@return Structure config with yOffset, sensitivity, dropMultiplier
]]
function TerrainConfig.GetStructureConfig(assetName: string): { yOffset: number, sensitivity: number, dropMultiplier: number }
	local config = TerrainConfig.STRUCTURES[assetName]
	if config then
		return config
	end
	return TerrainConfig.STRUCTURES.DEFAULT
end

return TerrainConfig
