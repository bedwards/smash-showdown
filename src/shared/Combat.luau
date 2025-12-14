--!strict
-- Combat configuration and utilities
-- Shared between client and server

local Combat = {}

-- Attack types
Combat.AttackType = {
	LIGHT = "Light",
	HEAVY = "Heavy",
	DASH = "Dash",
}

-- Combat stats
Combat.Stats = {
	-- Movement
	WALK_SPEED = 20,
	DASH_SPEED = 60,
	DASH_DURATION = 0.2,
	DASH_COOLDOWN = 0.8,
	JUMP_POWER = 60,

	-- Combat
	LIGHT_DAMAGE = 8,
	HEAVY_DAMAGE = 18,
	DASH_DAMAGE = 12,

	-- Timing (seconds)
	LIGHT_WINDUP = 0.1,
	LIGHT_ACTIVE = 0.15,
	LIGHT_RECOVERY = 0.2,

	HEAVY_WINDUP = 0.3,
	HEAVY_ACTIVE = 0.2,
	HEAVY_RECOVERY = 0.4,

	-- Combo
	COMBO_WINDOW = 0.5,
	MAX_COMBO = 4,

	-- Health
	MAX_HEALTH = 100,
	RESPAWN_TIME = 3,
}

-- Hitstun based on attack type
function Combat.getHitstun(attackType: string): number
	if attackType == Combat.AttackType.LIGHT then
		return 0.2
	elseif attackType == Combat.AttackType.HEAVY then
		return 0.5
	elseif attackType == Combat.AttackType.DASH then
		return 0.3
	end
	return 0.2
end

-- Knockback based on attack type
function Combat.getKnockback(attackType: string): number
	if attackType == Combat.AttackType.LIGHT then
		return 20
	elseif attackType == Combat.AttackType.HEAVY then
		return 50
	elseif attackType == Combat.AttackType.DASH then
		return 35
	end
	return 20
end

return Combat
