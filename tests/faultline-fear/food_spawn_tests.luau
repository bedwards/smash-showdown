--[[
	Food Spawning Tests

	Tests for food item spawning near spawn and landmarks.
]]

local fs = require("@lune/fs")

local tests = {}

-- Read CollectibleSpawner
local spawnerPath = "src/faultline-fear/server/Services/CollectibleSpawner.luau"
local spawnerContent = fs.readFile(spawnerPath)

tests["CollectibleSpawner has LANDMARK_FOOD_SPAWNS"] = function()
	assert(spawnerContent:find("LANDMARK_FOOD_SPAWNS"), "LANDMARK_FOOD_SPAWNS table should exist")
end

tests["SpawnArea is first landmark food spawn"] = function()
	-- SpawnArea should be defined early in LANDMARK_FOOD_SPAWNS
	local spawnAreaPos = spawnerContent:find('name = "SpawnArea"')
	assert(spawnAreaPos, "SpawnArea should be defined in LANDMARK_FOOD_SPAWNS")
end

tests["SpawnArea has correct center position"] = function()
	-- Spawn point is at z = -1000
	assert(spawnerContent:find("center = Vector3.new%(0, 0, %-1000%)"), "SpawnArea center should match spawn point at z=-1000")
end

tests["SpawnArea has multiple food spawns"] = function()
	-- SpawnArea should have several food items
	-- Count Apple, Berries, Water Bottle, Granola Bar entries in SpawnArea section
	local spawnAreaStart = spawnerContent:find('name = "SpawnArea"')
	assert(spawnAreaStart, "SpawnArea should be defined")

	-- Get a chunk of text after SpawnArea definition
	local spawnAreaChunk = spawnerContent:sub(spawnAreaStart, spawnAreaStart + 1000)

	-- Count food types in the spawns
	local foodCount = 0
	for _ in spawnAreaChunk:gmatch('foodType = "') do
		foodCount = foodCount + 1
	end
	assert(foodCount >= 4, "SpawnArea should have at least 4 food spawn points, got " .. foodCount)
end

tests["Food items have hungerRestore attribute"] = function()
	assert(spawnerContent:find("hungerRestore"), "Food items should define hungerRestore values")
end

tests["FerrisWheel landmark has food spawns"] = function()
	assert(spawnerContent:find('name = "FerrisWheel"'), "FerrisWheel landmark should have food spawns")
end

tests["Lighthouse landmark has food spawns"] = function()
	assert(spawnerContent:find('name = "Lighthouse"'), "Lighthouse landmark should have food spawns")
end

tests["RadioTower landmark has food spawns"] = function()
	assert(spawnerContent:find('name = "RadioTower"'), "RadioTower landmark should have food spawns")
end

tests["WaterTower landmark has food spawns"] = function()
	assert(spawnerContent:find('name = "WaterTower"'), "WaterTower landmark should have food spawns")
end

tests["Bridge landmark has food spawns"] = function()
	assert(spawnerContent:find('name = "Bridge"'), "Bridge landmark should have food spawns")
end

tests["SpawnLandmarkFood function exists"] = function()
	assert(spawnerContent:find("SpawnLandmarkFood"), "SpawnLandmarkFood function should exist")
end

tests["SpawnFood function exists"] = function()
	assert(spawnerContent:find("SpawnFood"), "SpawnFood function should exist")
end

return tests
