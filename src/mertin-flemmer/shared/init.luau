--!strict
-- Mertin-Flemmer shared configuration
-- Survival horror game inspired by 3008 and 99 Nights in the Forest

local Shared = {}

-- ==========================================
-- TERRAIN HEIGHT CALCULATION
-- Must match AlpineTerrain.server.luau logic
-- Used by all systems to place items ON terrain
-- ==========================================

local TERRAIN_SIZE = 3500  -- Must match AlpineTerrain
local SEED = 12345

-- Simple noise using math.noise
local function noise2D(x: number, z: number, scale: number, seed: number): number
	return math.noise(x / scale + seed, z / scale + seed)
end

-- Multi-octave fractal noise
local function fbm(x: number, z: number, octaves: number, persistence: number, scale: number, seed: number): number
	local total = 0
	local frequency = 1
	local amplitude = 1
	local maxValue = 0

	for i = 1, octaves do
		total = total + noise2D(x * frequency, z * frequency, scale, seed + i * 100) * amplitude
		maxValue = maxValue + amplitude
		amplitude = amplitude * persistence
		frequency = frequency * 2
	end

	return total / maxValue
end

-- Ridge noise for mountain peaks
local function ridgeNoise(x: number, z: number, scale: number, seed: number): number
	local n = noise2D(x, z, scale, seed)
	return 1 - math.abs(n)
end

-- Mountain influence zones (must match AlpineTerrain)
local MOUNTAIN_ZONES = {
	{ center = { X = 300, Y = -400 }, radius = 400, height = 350 },
	{ center = { X = 400, Y = -200 }, radius = 350, height = 300 },
	{ center = { X = 200, Y = 200 }, radius = 300, height = 250 },
	{ center = { X = 350, Y = 350 }, radius = 400, height = 380 },
	{ center = { X = -350, Y = 300 }, radius = 250, height = 150 },
}

-- Valley paths (must match AlpineTerrain)
local VALLEY_PATHS = {
	{ startX = -400, startZ = -300, finishX = -100, finishZ = 300, width = 50 },
	{ startX = 100, startZ = -200, finishX = 300, finishZ = 200, width = 30 },
	{ startX = -200, startZ = 100, finishX = 150, finishZ = 350, width = 40 },
}

local function getDistanceToPath(x: number, z: number, path: typeof(VALLEY_PATHS[1])): number
	local pX, pZ = x, z
	local aX, aZ = path.startX, path.startZ
	local bX, bZ = path.finishX, path.finishZ

	local abX, abZ = bX - aX, bZ - aZ
	local apX, apZ = pX - aX, pZ - aZ

	local dotABAB = abX * abX + abZ * abZ
	local dotAPAB = apX * abX + apZ * abZ

	local t = math.clamp(dotAPAB / dotABAB, 0, 1)
	local closestX = aX + abX * t
	local closestZ = aZ + abZ * t

	local dx = pX - closestX
	local dz = pZ - closestZ
	return math.sqrt(dx * dx + dz * dz)
end

-- Calculate terrain height at any world position
-- This MUST match AlpineTerrain.server.luau calculateHeight function!
function Shared.getTerrainHeight(x: number, z: number): number
	-- Base gentle undulation (starts at 0, not +10, to match AlpineTerrain)
	local base = fbm(x, z, 3, 0.5, 500, SEED) * 30  -- 3 octaves, no +10

	-- Add gentle rolling hills
	local hills = fbm(x, z, 2, 0.6, 200, SEED + 1000) * 20  -- 2 octaves

	-- Mountain influence
	local mountainHeight = 0
	for _, zone in ipairs(MOUNTAIN_ZONES) do
		local dx = x - zone.center.X
		local dz = z - zone.center.Y
		local dist = math.sqrt(dx * dx + dz * dz)
		if dist < zone.radius then
			local influence = 1 - (dist / zone.radius)
			influence = influence ^ 1.5  -- Steeper near peaks

			-- Add ridge detail to mountains
			local ridge = ridgeNoise(x, z, 100, SEED + 2000) * 50
			local detail = fbm(x, z, 6, 0.5, 50, SEED + 3000) * 30

			local mtnHeight = zone.height * influence + ridge * influence + detail * influence
			mountainHeight = math.max(mountainHeight, mtnHeight)
		end
	end

	-- Valley carving (lower terrain near river paths)
	local valleyDepth = 0
	for _, path in ipairs(VALLEY_PATHS) do
		local dist = getDistanceToPath(x, z, path)
		if dist < path.width * 2 then
			local influence = 1 - math.min(1, dist / (path.width * 2))
			influence = influence ^ 2
			valleyDepth = math.max(valleyDepth, influence * 40)
		end
	end

	-- Combine
	local height = base + hills + mountainHeight - valleyDepth

	-- Flatten spawn area - spawn house is at (0, 0, -30)
	local distFromSpawn = math.sqrt(x * x + (z + 30) * (z + 30))
	if distFromSpawn < 100 then
		-- Very flat near spawn house
		local flatInfluence = 1 - (distFromSpawn / 100)
		height = height * (1 - flatInfluence) + 0 * flatInfluence
		height = math.max(height, 0)
	elseif distFromSpawn < 200 then
		height = math.max(height, 0)
	end

	-- Global floor - never below -5 (water level)
	height = math.max(height, -5)

	return height
end

-- Convenience: Get a Vector3 position with correct terrain Y
function Shared.getPositionOnTerrain(x: number, z: number, yOffset: number?): Vector3
	local height = Shared.getTerrainHeight(x, z)
	return Vector3.new(x, height + (yOffset or 0), z)
end

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

	-- Hunger (survival pressure - must keep eating!)
	HUNGER_DRAIN = 8, -- per minute (forces active foraging)
	HUNGER_DAMAGE = 10, -- damage per tick when starving
	HUNGER_FOOD_RESTORE = 25, -- restored per food item

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
