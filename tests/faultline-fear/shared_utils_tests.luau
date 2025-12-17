--!strict
--[[
	Shared Utilities Tests

	Tests for utility functions in shared/init.luau.
	These tests validate audio utilities, terrain helpers, and other shared functions.
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
-- READ SHARED MODULE
-- ==========================================

local sharedPath = "src/faultline-fear/shared/init.luau"
local sharedContent = ""

if fs.isFile(sharedPath) then
	sharedContent = fs.readFile(sharedPath)
else
	error("Shared module not found at: " .. sharedPath)
end

-- Helper to check if pattern exists
local function hasPattern(pattern: string): boolean
	return string.match(sharedContent, pattern) ~= nil
end

-- ==========================================
-- TESTS
-- ==========================================

local tests = {}

-- Basic Structure
tests["Shared module file exists"] = function()
	TestAssert.assertTrue(#sharedContent > 0, "Shared module should not be empty")
end

tests["Shared module exports a table"] = function()
	TestAssert.assertTrue(hasPattern("return%s+Shared"), "Shared should return Shared table")
end

tests["Shared module uses strict mode"] = function()
	TestAssert.assertTrue(hasPattern("^%-%-!strict"), "Shared module should use --!strict mode")
end

-- ==========================================
-- isValidSoundId TESTS
-- ==========================================

tests["isValidSoundId function is defined"] = function()
	TestAssert.assertTrue(
		hasPattern("isValidSoundId%s*=%s*function"),
		"Shared.isValidSoundId should be defined"
	)
end

tests["isValidSoundId handles number type"] = function()
	-- Check that the function checks for number type
	TestAssert.assertTrue(
		hasPattern('type%(soundId%)%s*==%s*"number"'),
		"isValidSoundId should check for number type"
	)
end

tests["isValidSoundId handles string type"] = function()
	-- Check that the function checks for string type
	TestAssert.assertTrue(
		hasPattern('type%(soundId%)%s*==%s*"string"'),
		"isValidSoundId should check for string type"
	)
end

tests["isValidSoundId rejects zero numbers"] = function()
	-- Check that it returns false for soundId <= 0
	TestAssert.assertTrue(
		hasPattern("soundId%s*>%s*0"),
		"isValidSoundId should check that numeric IDs are > 0"
	)
end

tests["isValidSoundId rejects empty strings"] = function()
	-- Check that it handles empty string
	TestAssert.assertTrue(
		hasPattern('soundId%s*~=%s*""'),
		"isValidSoundId should reject empty strings"
	)
end

tests["isValidSoundId rejects rbxassetid://0"] = function()
	-- Check that it rejects the placeholder ID
	TestAssert.assertTrue(
		hasPattern('soundId%s*~=%s*"rbxassetid://0"'),
		"isValidSoundId should reject rbxassetid://0"
	)
end

tests["isValidSoundId rejects rbxassetid://"] = function()
	-- Check that it rejects empty rbxassetid
	TestAssert.assertTrue(
		hasPattern('soundId%s*~=%s*"rbxassetid://"'),
		"isValidSoundId should reject rbxassetid:// (no ID)"
	)
end

tests["isValidSoundId returns false for invalid types"] = function()
	-- Check that it has a fallback return false
	TestAssert.assertTrue(
		hasPattern("return%s+false"),
		"isValidSoundId should return false for invalid types"
	)
end

-- ==========================================
-- TERRAIN UTILITY TESTS
-- ==========================================

tests["getTerrainHeight function is defined"] = function()
	TestAssert.assertTrue(
		hasPattern("getTerrainHeight%s*=%s*function"),
		"Shared.getTerrainHeight should be defined"
	)
end

tests["snapToTerrain function is defined"] = function()
	TestAssert.assertTrue(
		hasPattern("snapToTerrain%s*=%s*function"),
		"Shared.snapToTerrain should be defined"
	)
end

tests["getTerrainHeight delegates to Heightmap"] = function()
	TestAssert.assertTrue(
		hasPattern("Heightmap:GetHeight"),
		"getTerrainHeight should delegate to Heightmap:GetHeight"
	)
end

tests["snapToTerrain delegates to Heightmap"] = function()
	TestAssert.assertTrue(
		hasPattern("Heightmap:SnapToTerrain"),
		"snapToTerrain should delegate to Heightmap:SnapToTerrain"
	)
end

-- ==========================================
-- MODULE EXPORTS TESTS
-- ==========================================

tests["Config module is exported"] = function()
	TestAssert.assertTrue(
		hasPattern("Shared%.Config%s*=%s*require"),
		"Shared.Config should be exported"
	)
end

tests["Heightmap module is exported"] = function()
	TestAssert.assertTrue(
		hasPattern("Shared%.Heightmap%s*=%s*require"),
		"Shared.Heightmap should be exported"
	)
end

tests["TerrainUtils module is exported"] = function()
	TestAssert.assertTrue(
		hasPattern("Shared%.TerrainUtils%s*=%s*require"),
		"Shared.TerrainUtils should be exported"
	)
end

tests["ObjectPool module is exported"] = function()
	TestAssert.assertTrue(
		hasPattern("Shared%.ObjectPool%s*=%s*require"),
		"Shared.ObjectPool should be exported"
	)
end

tests["StoryData module is exported"] = function()
	TestAssert.assertTrue(
		hasPattern("Shared%.StoryData%s*=%s*require"),
		"Shared.StoryData should be exported"
	)
end

tests["AssetManifest module is exported"] = function()
	TestAssert.assertTrue(
		hasPattern("Shared%.AssetManifest%s*=%s*require"),
		"Shared.AssetManifest should be exported"
	)
end

return tests
