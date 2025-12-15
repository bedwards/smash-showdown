--!strict
-- Shared module entry point
-- Contains code and constants used by both server and client

local Shared = {}

-- Game configuration
Shared.Config = {
	GAME_NAME = "Smash Showdown",
	VERSION = "0.1.0",
	MAX_PLAYERS = 6,

	-- Match settings
	MATCH_DURATION = 180, -- 3 minutes
	RESPAWN_TIME = 3,

	-- Combat settings
	BASE_HEALTH = 100,
	BASE_DAMAGE = 10,
}

return Shared
