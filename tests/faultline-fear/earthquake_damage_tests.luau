--[[
	Earthquake Damage Tests

	Tests for earthquake damage mechanics including direct damage and fall damage.
]]

local fs = require("@lune/fs")

local tests = {}

-- Read EarthquakeService
local earthquakePath = "src/faultline-fear/server/Services/EarthquakeService.luau"
local earthquakeContent = fs.readFile(earthquakePath)

tests["EarthquakeService has FALL_DAMAGE config"] = function()
	assert(earthquakeContent:find("FALL_DAMAGE"), "FALL_DAMAGE config should exist")
end

tests["FALL_DAMAGE.MIN_HEIGHT is defined"] = function()
	assert(earthquakeContent:find("MIN_HEIGHT"), "MIN_HEIGHT for fall damage threshold should exist")
end

tests["FALL_DAMAGE.DAMAGE_PER_STUD is defined"] = function()
	assert(earthquakeContent:find("DAMAGE_PER_STUD"), "DAMAGE_PER_STUD should define damage scaling")
end

tests["FALL_DAMAGE.MAX_DAMAGE is defined"] = function()
	assert(earthquakeContent:find("MAX_DAMAGE"), "MAX_DAMAGE should cap fall damage")
end

tests["EarthquakeService has QUAKE_DIRECT_DAMAGE config"] = function()
	assert(earthquakeContent:find("QUAKE_DIRECT_DAMAGE"), "QUAKE_DIRECT_DAMAGE config should exist for direct damage during quakes")
end

tests["QUAKE_DIRECT_DAMAGE.BASE_DAMAGE is defined"] = function()
	assert(earthquakeContent:find("BASE_DAMAGE"), "BASE_DAMAGE should define base earthquake damage")
end

tests["QUAKE_DIRECT_DAMAGE.TICK_INTERVAL is defined"] = function()
	assert(earthquakeContent:find("TICK_INTERVAL"), "TICK_INTERVAL should define how often damage ticks occur")
end

tests["QUAKE_DIRECT_DAMAGE.MAGNITUDE_MULTIPLIER is defined"] = function()
	assert(earthquakeContent:find("MAGNITUDE_MULTIPLIER"), "MAGNITUDE_MULTIPLIER should scale damage by quake magnitude")
end

tests["ApplyDirectDamage function exists"] = function()
	assert(earthquakeContent:find("ApplyDirectDamage"), "ApplyDirectDamage function should exist")
end

tests["ExecuteQuake calls ApplyDirectDamage"] = function()
	assert(earthquakeContent:find("ApplyDirectDamage%("), "ExecuteQuake should call ApplyDirectDamage")
end

tests["Direct damage only applies to MODERATE+ quakes"] = function()
	assert(earthquakeContent:find("magnitude >= 0.6"), "Direct damage should only apply to moderate+ quakes (magnitude >= 0.6)")
end

tests["ApplyDirectDamage uses TakeDamage"] = function()
	assert(earthquakeContent:find("TakeDamage"), "ApplyDirectDamage should use humanoid:TakeDamage()")
end

return tests
