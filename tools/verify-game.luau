--[[
	Faultline Fear: Game Verification Script

	Runs in Roblox Studio via run-in-roblox to verify game setup.

	Usage:
		rojo build faultline-fear.project.json -o faultline-fear.rbxl
		run-in-roblox --place faultline-fear.rbxl --script tools/verify-game.luau

	This script runs validation checks and prints results to stdout.
	Exit codes:
		0 = All checks passed
		1 = Some checks failed
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

print("╔════════════════════════════════════════════════╗")
print("║     FAULTLINE FEAR VERIFICATION SCRIPT         ║")
print("╚════════════════════════════════════════════════╝")
print("")

local passed = 0
local failed = 0
local warnings = 0

local function check(name: string, condition: boolean, message: string?)
	if condition then
		passed += 1
		print(string.format("[✓] %s", name))
	else
		failed += 1
		print(string.format("[✗] %s", name))
		if message then
			print(string.format("    %s", message))
		end
	end
end

local function warn_check(name: string, condition: boolean, message: string?)
	if condition then
		passed += 1
		print(string.format("[✓] %s", name))
	else
		warnings += 1
		print(string.format("[⚠] %s (warning)", name))
		if message then
			print(string.format("    %s", message))
		end
	end
end

-- ==========================================
-- STRUCTURE CHECKS
-- ==========================================

print("--- Structure Checks ---")

-- Check ReplicatedStorage/Shared exists
local shared = ReplicatedStorage:FindFirstChild("Shared")
check("Shared folder exists", shared ~= nil)

if shared then
	-- Check critical modules exist
	local criticalModules = { "Config", "Heightmap", "AssetManifest", "InputService", "StoryData" }
	for _, moduleName in ipairs(criticalModules) do
		local module = shared:FindFirstChild(moduleName)
		check(string.format("Shared/%s exists", moduleName), module ~= nil)
	end
end

-- Check ServerScriptService/Server exists
local server = ServerScriptService:FindFirstChild("Server")
check("Server folder exists", server ~= nil)

if server then
	-- Check Main script exists
	local main = server:FindFirstChild("Main")
	check("Main.server script exists", main ~= nil)

	-- Check Services folder
	local services = server:FindFirstChild("Services")
	check("Services folder exists", services ~= nil)

	if services then
		local criticalServices = {
			"TerrainGenerator",
			"HungerService",
			"DayNightService",
			"EarthquakeService",
			"ValidationService",
		}
		for _, serviceName in ipairs(criticalServices) do
			local service = services:FindFirstChild(serviceName)
			check(string.format("Services/%s exists", serviceName), service ~= nil)
		end
	end
end

-- Check Workspace setup
print("")
print("--- Workspace Checks ---")

local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
check("SpawnLocation exists", spawnLocation ~= nil)

if spawnLocation then
	local pos = spawnLocation.Position
	check("SpawnLocation Y >= 0", pos.Y >= 0, string.format("Y = %d", pos.Y))
end

-- ==========================================
-- MODULE LOADING CHECKS
-- ==========================================

print("")
print("--- Module Loading Checks ---")

if shared then
	local function tryRequire(moduleName: string): boolean
		local module = shared:FindFirstChild(moduleName)
		if not module then
			return false
		end

		local success, result = pcall(function()
			return require(module)
		end)

		if not success then
			print(string.format("    Error: %s", tostring(result)))
		end

		return success
	end

	check("Config loads without error", tryRequire("Config"))
	check("Heightmap loads without error", tryRequire("Heightmap"))
	check("AssetManifest loads without error", tryRequire("AssetManifest"))
	check("InputService loads without error", tryRequire("InputService"))
	check("StoryData loads without error", tryRequire("StoryData"))
end

-- ==========================================
-- CONFIG VALIDATION
-- ==========================================

print("")
print("--- Config Validation ---")

if shared then
	local configModule = shared:FindFirstChild("Config")
	if configModule then
		local success, Config = pcall(function()
			return require(configModule)
		end)

		if success and Config then
			check("WORLD_SIZE defined", Config.WORLD_SIZE ~= nil)
			check("TERRAIN_SEED defined", Config.TERRAIN_SEED ~= nil)
			check("ZONES defined", Config.ZONES ~= nil)
			check("DAY_NIGHT defined", Config.DAY_NIGHT ~= nil)
			check("HUNGER defined", Config.HUNGER ~= nil)
			check("KEYBINDS defined", Config.KEYBINDS ~= nil)

			if Config.WORLD_SIZE then
				check("WORLD_SIZE reasonable", Config.WORLD_SIZE >= 1000 and Config.WORLD_SIZE <= 100000)
			end

			if Config.ZONES then
				local requiredZones = { "OCEAN", "BEACH", "COASTAL", "VALLEY", "FAULT_LINE", "FOREST", "MOUNTAIN" }
				for _, zone in ipairs(requiredZones) do
					check(string.format("Zone %s defined", zone), Config.ZONES[zone] ~= nil)
				end
			end
		end
	end
end

-- ==========================================
-- SUMMARY
-- ==========================================

print("")
print("════════════════════════════════════════════════")
print(string.format("Results: %d passed, %d warnings, %d failed", passed, warnings, failed))

if failed > 0 then
	print("")
	print("❌ VERIFICATION FAILED - Fix issues before publishing")
	-- Note: run-in-roblox doesn't support exit codes, but we print clear status
elseif warnings > 0 then
	print("")
	print("⚠️  VERIFICATION PASSED WITH WARNINGS - Review before publishing")
else
	print("")
	print("✅ ALL CHECKS PASSED - Ready to publish!")
end

print("════════════════════════════════════════════════")
