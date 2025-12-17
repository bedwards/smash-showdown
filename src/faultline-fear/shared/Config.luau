--!strict
-- Faultline Fear: Single Source of Truth for all game constants
-- ALL configuration values go here. Never hardcode values in other files.

export type Config = typeof(Config)

local Config = {
	-- ==========================================
	-- DEBUG / LOADING CONTROL
	-- ==========================================
	-- LOAD_LEVEL controls how far the game loads (for debugging)
	-- 0 = Heightmap only (no visual terrain)
	-- 1 = + Visual terrain
	-- 2 = + Core services (hunger, day/night, earthquake)
	-- 3 = + Structures and terrain assets
	-- 4 = + NPCs and collectibles
	-- 5 = Full load (everything)
	LOAD_LEVEL = 5, -- Set to lower number to debug loading stages

	-- ==========================================
	-- WORLD DIMENSIONS
	-- ==========================================
	WORLD_SIZE = 4000, -- Total world size in studs
	WORLD_CENTER = Vector3.new(0, 0, 0),

	-- Cardinal directions (which edge has what)
	MOUNTAIN_EDGE = "North", -- Mountains cut off at north edge
	OCEAN_EDGE = "South", -- Ocean extends to south edge
	FAULT_LINE_DIRECTION = "EastWest", -- Fault runs parallel to shore

	-- Zone boundaries (Y is ignored, these are X/Z ranges)
	ZONES = {
		MOUNTAIN = { zMin = 1500, zMax = 2000 }, -- North
		FOREST = { zMin = 800, zMax = 1500 },
		FAULT_LINE = { zMin = 400, zMax = 800 }, -- Center
		VALLEY = { zMin = -200, zMax = 400 },
		COASTAL = { zMin = -800, zMax = -200 },
		BEACH = { zMin = -1200, zMax = -800 },
		OCEAN = { zMin = -2000, zMax = -1200 }, -- South
	},

	-- ==========================================
	-- TERRAIN
	-- ==========================================
	TERRAIN_SEED = 12345,
	MOUNTAIN_MAX_HEIGHT = 500,
	FAULT_LINE_DEPTH = 50, -- How deep the rift is
	FAULT_LINE_WIDTH = 30, -- Average width of the fault
	OCEAN_LEVEL = 0, -- Sea level Y coordinate

	-- ==========================================
	-- EARTHQUAKE SYSTEM
	-- ==========================================
	EARTHQUAKE = {
		MINOR_TREMOR = {
			magnitude = 0.3,
			interval = 300, -- seconds
			duration = 3,
			cameraShake = 0.5,
		},
		MODERATE = {
			magnitude = 0.6,
			interval = 900,
			duration = 8,
			cameraShake = 1.5,
			knockdown = true,
		},
		MAJOR = {
			magnitude = 0.9,
			interval = 3600,
			duration = 15,
			cameraShake = 3.0,
			knockdown = true,
			structuralDamage = true,
		},
		BIG_ONE = {
			magnitude = 1.0,
			duration = 30,
			cameraShake = 5.0,
			knockdown = true,
			structuralDamage = true,
			permanentChanges = true,
		},
		-- P-wave warning time before S-wave hits
		WARNING_TIME = 4, -- seconds
	},

	-- ==========================================
	-- SURVIVAL MECHANICS
	-- ==========================================
	HUNGER = {
		MAX = 100,
		DECAY_RATE = 0.5, -- per second
		SPRINT_MULTIPLIER = 2.0, -- decay faster when sprinting
		SWIM_MULTIPLIER = 1.5,

		-- Thresholds
		SLOW_THRESHOLD = 50, -- Below this, movement slows
		BLUR_THRESHOLD = 25, -- Below this, vision blurs
		DEATH_THRESHOLD = 0,

		-- Effects
		SLOW_SPEED_MULTIPLIER = 0.7,
		RESPAWN_HUNGER = 50, -- Hunger on respawn
	},

	STAMINA = {
		MAX = 100,
		SPRINT_DRAIN = 10, -- per second while sprinting
		SWIM_DRAIN = 15,
		CLIMB_DRAIN = 20,
		RECOVERY_RATE = 5, -- per second while resting
	},

	-- ==========================================
	-- DAY/NIGHT CYCLE
	-- ==========================================
	DAY_NIGHT = {
		-- Clock times (0-24)
		DAWN_START = 5,
		DAY_START = 6,
		DUSK_START = 20,
		NIGHT_START = 21,

		-- Real time duration
		FULL_CYCLE_MINUTES = 20, -- 20 real minutes = 1 game day

		-- Danger
		PREDATORS_ACTIVE_AT_NIGHT = true,
		NPC_SHELTER_AT_NIGHT = true,
	},

	-- ==========================================
	-- OBJECTIVES / PROGRESSION
	-- ==========================================
	OBJECTIVES = {
		GENERATOR_PARTS_TOTAL = 6,
		SURVIVORS_TOTAL = 10,

		-- Endings
		GOOD_ENDING_SURVIVORS = 8, -- Rescue 8+ for good ending
		BEST_ENDING_SURVIVORS = 10, -- Rescue all for best ending
	},

	-- ==========================================
	-- NPC & ANIMALS
	-- ==========================================
	ANIMALS = {
		-- Friendly (day only)
		DEER_COUNT = 10,
		BIRD_COUNT = 20,
		RABBIT_COUNT = 15,
		FISH_COUNT = 30,

		-- Hostile (night only)
		WOLF_PACK_SIZE = 3,
		WOLF_PACK_COUNT = 4,
		COYOTE_COUNT = 8,
		MOUNTAIN_LION_COUNT = 2, -- Rare, any time
	},

	-- ==========================================
	-- PET COMPANION
	-- ==========================================
	PET = {
		FOLLOW_DISTANCE = 4, -- studs behind player
		MAX_DISTANCE_BEFORE_TELEPORT = 50,
		DISTRACTION_CHANCE = 0.1, -- per minute
		DISTRACTION_DURATION = 10, -- seconds
		DIALOGUE_INTERVAL = 30, -- seconds between random quips
	},

	-- ==========================================
	-- AUDIO
	-- ==========================================
	MUSIC = {
		CROSSFADE_DURATION = 2, -- seconds
		DEFAULT_VOLUME = 0.5,
		EMERGENCY_BROADCAST_VOLUME = 0.8,
	},

	-- ==========================================
	-- UI / HUD
	-- ==========================================
	HUD = {
		-- Screen size thresholds
		SMALL_SCREEN_MAX = 500, -- pixels (short side)
		MEDIUM_SCREEN_MAX = 800,

		-- Toggle
		TOGGLE_KEY = Enum.KeyCode.Tab,
		TOUCH_HOLD_TIME = 1.0, -- seconds for long-press toggle

		-- Touch button size
		TOUCH_BUTTON_SIZE = 60, -- pixels
		TOUCH_BUTTON_SPACING = 10,
	},

	-- ==========================================
	-- PERFORMANCE
	-- ==========================================
	PERFORMANCE = {
		TARGET_FPS_DESKTOP = 60,
		TARGET_FPS_MOBILE = 30,

		LOD_DISTANCES = {
			HIGH = 50, -- Full detail within 50 studs
			MEDIUM = 200, -- Medium detail 50-200
			LOW = 500, -- Low detail beyond 200
		},

		STREAMING_ENABLED = true,

		-- Battery saver mode settings
		BATTERY_SAVER = {
			-- Reduced update frequencies
			HUD_UPDATE_RATE = 0.5, -- seconds (normal is real-time)
			ZONE_CHECK_RATE = 5, -- seconds (normal is 2)

			-- Visual reductions
			PARTICLE_MULTIPLIER = 0.3, -- 30% of normal particles
			SHADOW_ENABLED = false,
			POST_EFFECTS_ENABLED = false,

			-- LOD adjustments (closer culling)
			LOD_DISTANCE_MULTIPLIER = 0.5,
		},
	},

	-- ==========================================
	-- BADGES
	-- ==========================================
	BADGES = {
		SURVIVOR = 4228023429993265, -- Endure The Big One and complete the game
		EXPLORER = 4258190789797301, -- Visit all seven zones
		RESCUER = 732146320143385, -- Rescue all survivors
	},

	-- ==========================================
	-- INPUT
	-- ==========================================
	KEYBINDS = {
		EAT = Enum.KeyCode.One,
		USE_ITEM = Enum.KeyCode.Two,
		FLASHLIGHT = Enum.KeyCode.F,
		INTERACT = Enum.KeyCode.E,
		SPRINT = Enum.KeyCode.LeftShift,
		CALL_PET = Enum.KeyCode.P,
		TOGGLE_HUD = Enum.KeyCode.Tab,
	},
}

return Config
