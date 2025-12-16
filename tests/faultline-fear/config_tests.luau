--!strict
--[[
	Config Validation Tests

	Tests that the game configuration is valid and consistent.
	Validates zones, constants, and relationships between config values.
]]

local fs = require("@lune/fs")

local TestAssert = _G.TestAssert :: {
	assertEquals: (any, any, string?) -> (),
	assertTrue: (any, string?) -> (),
	assertFalse: (any, string?) -> (),
	assertNil: (any, string?) -> (),
	assertNotNil: (any, string?) -> (),
	assertInRange: (number, number, number, string?) -> (),
}

-- ==========================================
-- READ AND PARSE CONFIG
-- ==========================================

-- Read the actual Config.luau file and extract values
local configPath = "src/faultline-fear/shared/Config.luau"
local configContent = ""

if fs.isFile(configPath) then
	configContent = fs.readFile(configPath)
else
	error("Config file not found at: " .. configPath)
end

-- Helper to extract number value from config
local function extractNumber(pattern: string): number?
	local match = string.match(configContent, pattern)
	if match then
		return tonumber(match)
	end
	return nil
end

-- Helper to check if pattern exists
local function hasPattern(pattern: string): boolean
	return string.match(configContent, pattern) ~= nil
end

-- ==========================================
-- TESTS
-- ==========================================

local tests = {}

-- Basic Config Structure
tests["Config file exists"] = function()
	TestAssert.assertTrue(#configContent > 0, "Config file should not be empty")
end

tests["Config exports a table"] = function()
	TestAssert.assertTrue(hasPattern("return%s+Config"), "Config should return Config table")
end

-- World Size
tests["WORLD_SIZE is defined and reasonable"] = function()
	local worldSize = extractNumber("WORLD_SIZE%s*=%s*(%d+)")
	TestAssert.assertNotNil(worldSize, "WORLD_SIZE should be defined")
	if worldSize then
		TestAssert.assertTrue(worldSize >= 1000, "WORLD_SIZE should be at least 1000 studs")
		TestAssert.assertTrue(worldSize <= 100000, "WORLD_SIZE should not exceed 100000 studs")
	end
end

-- Terrain Seed
tests["TERRAIN_SEED is defined"] = function()
	local seed = extractNumber("TERRAIN_SEED%s*=%s*(%d+)")
	TestAssert.assertNotNil(seed, "TERRAIN_SEED should be defined")
end

-- Ocean Level
tests["OCEAN_LEVEL is defined"] = function()
	local oceanLevel = extractNumber("OCEAN_LEVEL%s*=%s*(%-?%d+)")
	TestAssert.assertNotNil(oceanLevel, "OCEAN_LEVEL should be defined")
end

-- Fault Line
tests["FAULT_LINE_WIDTH is defined"] = function()
	local width = extractNumber("FAULT_LINE_WIDTH%s*=%s*(%d+)")
	TestAssert.assertNotNil(width, "FAULT_LINE_WIDTH should be defined")
	if width then
		TestAssert.assertTrue(width > 0, "FAULT_LINE_WIDTH should be positive")
	end
end

tests["FAULT_LINE_DEPTH is defined"] = function()
	local depth = extractNumber("FAULT_LINE_DEPTH%s*=%s*(%d+)")
	TestAssert.assertNotNil(depth, "FAULT_LINE_DEPTH should be defined")
	if depth then
		TestAssert.assertTrue(depth > 0, "FAULT_LINE_DEPTH should be positive")
	end
end

-- Mountain Height
tests["MOUNTAIN_MAX_HEIGHT is defined and reasonable"] = function()
	local maxHeight = extractNumber("MOUNTAIN_MAX_HEIGHT%s*=%s*(%d+)")
	TestAssert.assertNotNil(maxHeight, "MOUNTAIN_MAX_HEIGHT should be defined")
	if maxHeight then
		TestAssert.assertTrue(maxHeight >= 100, "MOUNTAIN_MAX_HEIGHT should be at least 100")
		TestAssert.assertTrue(maxHeight <= 1000, "MOUNTAIN_MAX_HEIGHT should not exceed 1000")
	end
end

-- Zones Configuration
tests["ZONES table is defined"] = function()
	TestAssert.assertTrue(hasPattern("ZONES%s*=%s*{"), "ZONES table should be defined")
end

tests["All required zones are defined"] = function()
	local requiredZones = { "OCEAN", "BEACH", "COASTAL", "VALLEY", "FAULT_LINE", "FOREST", "MOUNTAIN" }
	for _, zone in ipairs(requiredZones) do
		TestAssert.assertTrue(hasPattern(zone .. "%s*=%s*{"), string.format("Zone %s should be defined", zone))
	end
end

tests["Zone boundaries have zMin and zMax"] = function()
	-- Check at least one zone has both properties
	TestAssert.assertTrue(hasPattern("zMin%s*=%s*%-?%d+"), "Zones should have zMin property")
	TestAssert.assertTrue(hasPattern("zMax%s*=%s*%-?%d+"), "Zones should have zMax property")
end

-- Day/Night Configuration
tests["DAY_NIGHT configuration exists"] = function()
	TestAssert.assertTrue(hasPattern("DAY_NIGHT%s*=%s*{"), "DAY_NIGHT table should be defined")
end

tests["FULL_CYCLE_MINUTES is defined"] = function()
	local cycleMinutes = extractNumber("FULL_CYCLE_MINUTES%s*=%s*(%d+)")
	TestAssert.assertNotNil(cycleMinutes, "FULL_CYCLE_MINUTES should be defined")
	if cycleMinutes then
		TestAssert.assertTrue(cycleMinutes >= 1, "Day cycle should be at least 1 minute")
	end
end

-- Hunger Configuration
tests["HUNGER configuration exists"] = function()
	TestAssert.assertTrue(hasPattern("HUNGER%s*=%s*{"), "HUNGER table should be defined")
end

tests["HUNGER.MAX is defined"] = function()
	-- In HUNGER table, MAX = 100
	TestAssert.assertTrue(hasPattern("HUNGER%s*=%s*{"), "HUNGER table should be defined")
	TestAssert.assertTrue(hasPattern("MAX%s*=%s*%d+"), "HUNGER.MAX should be defined")
end

-- Keybinds
tests["KEYBINDS configuration exists"] = function()
	TestAssert.assertTrue(hasPattern("KEYBINDS%s*=%s*{"), "KEYBINDS table should be defined")
end

-- Performance Configuration
tests["PERFORMANCE configuration exists"] = function()
	TestAssert.assertTrue(hasPattern("PERFORMANCE%s*=%s*{"), "PERFORMANCE table should be defined")
end

-- Earthquake Configuration
tests["EARTHQUAKE configuration exists"] = function()
	TestAssert.assertTrue(hasPattern("EARTHQUAKE%s*=%s*{"), "EARTHQUAKE table should be defined")
end

-- Audio Configuration
tests["AUDIO section exists"] = function()
	-- Audio config is documented as a comment section
	TestAssert.assertTrue(hasPattern("AUDIO"), "AUDIO section should exist in config")
end

-- Strict Mode
tests["Config uses strict mode"] = function()
	TestAssert.assertTrue(hasPattern("^%-%-!strict"), "Config should use --!strict mode")
end

-- No Obvious Errors
tests["Config has no obvious syntax errors (balanced braces)"] = function()
	local openBraces = 0
	local closeBraces = 0

	for char in string.gmatch(configContent, "[{}]") do
		if char == "{" then
			openBraces += 1
		else
			closeBraces += 1
		end
	end

	TestAssert.assertEquals(openBraces, closeBraces, "Braces should be balanced")
end

return tests
