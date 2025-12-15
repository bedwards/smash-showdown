--!strict
-- Mertin-Flemmer shared configuration
-- Survival horror game inspired by 3008 and 99 Nights in the Forest

local Shared = {}

Shared.Config = {
	GAME_NAME = "Mertin-Flemmer",
	VERSION = "0.1.0",
	MAX_PLAYERS = 8,

	-- Day/Night cycle (in seconds)
	DAY_LENGTH = 180, -- 3 minutes of daytime
	NIGHT_LENGTH = 120, -- 2 minutes of nighttime
	DAWN_DURATION = 15,
	DUSK_DURATION = 15,

	-- Player stats
	MAX_HEALTH = 100,
	MAX_STAMINA = 100,
	MAX_HUNGER = 100,
	MAX_FEAR = 100,

	-- Stamina
	SPRINT_SPEED = 24,
	WALK_SPEED = 16,
	STAMINA_DRAIN = 10, -- per second while sprinting
	STAMINA_REGEN = 5, -- per second while not sprinting

	-- Hunger
	HUNGER_DRAIN = 1, -- per minute
	HUNGER_DAMAGE = 5, -- damage per tick when starving

	-- Fear
	FEAR_GAIN_DARKNESS = 2, -- per second in darkness
	FEAR_GAIN_CREATURE = 20, -- when creature spotted
	FEAR_DECAY_LIGHT = 5, -- per second near light

	-- Creatures
	CREATURE_DAMAGE = 15,
	CREATURE_SPEED_DAY = 8,
	CREATURE_SPEED_NIGHT = 20,

	-- Resources
	FLASHLIGHT_BATTERY = 120, -- seconds
	CAMPFIRE_DURATION = 300, -- seconds
}

-- Time of day states
Shared.TimeState = {
	DAY = "Day",
	DUSK = "Dusk",
	NIGHT = "Night",
	DAWN = "Dawn",
}

return Shared
