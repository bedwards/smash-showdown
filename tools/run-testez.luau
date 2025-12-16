--[[
	Faultline Fear: TestEZ Test Runner

	Runs BDD-style tests in Roblox Studio via TestEZ.

	Usage:
		rojo build faultline-fear.project.json -o faultline-fear.rbxl
		run-in-roblox --place faultline-fear.rbxl --script tools/run-testez.luau
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for DevPackages to load
local DevPackages = ReplicatedStorage:WaitForChild("DevPackages", 5)
if not DevPackages then
	print("ERROR: DevPackages not found in ReplicatedStorage")
	print("Make sure wally install has been run and project.json includes DevPackages")
	return
end

local TestEZ = require(DevPackages:WaitForChild("TestEZ"))

print("╔════════════════════════════════════════════════╗")
print("║     FAULTLINE FEAR TESTEZ RUNNER               ║")
print("╚════════════════════════════════════════════════╝")
print("")

-- Wait for Shared modules
local Shared = ReplicatedStorage:WaitForChild("Shared", 5)
if not Shared then
	print("ERROR: Shared folder not found")
	return
end

-- Load modules we want to test
local Config = require(Shared:WaitForChild("Config"))
local Heightmap = require(Shared:WaitForChild("Heightmap"))
local StoryData = require(Shared:WaitForChild("StoryData"))

-- ==========================================
-- SIMPLE TEST FRAMEWORK (using TestEZ expect)
-- ==========================================

local expect = TestEZ.Expectation.new

local passed = 0
local failed = 0

local function test(name: string, fn: () -> ())
	local success, err = pcall(fn)
	if success then
		passed += 1
		print(string.format("  ✓ %s", name))
	else
		failed += 1
		print(string.format("  ✗ %s", name))
		print(string.format("    Error: %s", tostring(err)))
	end
end

local function describe(suiteName: string, fn: () -> ())
	print(string.format("\n%s:", suiteName))
	fn()
end

-- ==========================================
-- CONFIG TESTS
-- ==========================================

describe("Config", function()
	test("WORLD_SIZE is defined", function()
		expect(Config.WORLD_SIZE).to.be.ok()
	end)

	test("TERRAIN_SEED is defined", function()
		expect(Config.TERRAIN_SEED).to.be.ok()
	end)

	test("ZONES has all required zones", function()
		expect(Config.ZONES.OCEAN).to.be.ok()
		expect(Config.ZONES.BEACH).to.be.ok()
		expect(Config.ZONES.COASTAL).to.be.ok()
		expect(Config.ZONES.VALLEY).to.be.ok()
		expect(Config.ZONES.FAULT_LINE).to.be.ok()
		expect(Config.ZONES.FOREST).to.be.ok()
		expect(Config.ZONES.MOUNTAIN).to.be.ok()
	end)

	test("DAY_NIGHT is configured", function()
		expect(Config.DAY_NIGHT).to.be.ok()
		expect(Config.DAY_NIGHT.FULL_CYCLE_MINUTES).to.be.ok()
	end)

	test("HUNGER is configured", function()
		expect(Config.HUNGER).to.be.ok()
		expect(Config.HUNGER.MAX).to.be.ok()
	end)

	test("KEYBINDS is defined", function()
		expect(Config.KEYBINDS).to.be.ok()
	end)
end)

-- ==========================================
-- HEIGHTMAP TESTS
-- ==========================================

describe("Heightmap", function()
	test("has required methods", function()
		expect(Heightmap.Generate).to.be.a("function")
		expect(Heightmap.GetHeight).to.be.a("function")
		expect(Heightmap.GetZone).to.be.a("function")
		expect(Heightmap.IsGenerated).to.be.a("function")
	end)

	-- Generate heightmap for further tests
	if not Heightmap:IsGenerated() then
		print("  (Generating heightmap...)")
		Heightmap:Generate(Config.TERRAIN_SEED)
	end

	test("is generated after Generate call", function()
		expect(Heightmap:IsGenerated()).to.equal(true)
	end)

	test("returns height for valid positions", function()
		local height = Heightmap:GetHeight(0, 0)
		expect(height).to.be.a("number")
	end)

	test("returns zone for valid positions", function()
		local zone = Heightmap:GetZone(0, 0)
		expect(zone).to.be.a("string")
	end)

	test("is deterministic (same input = same output)", function()
		local h1 = Heightmap:GetHeight(100, 100)
		local h2 = Heightmap:GetHeight(100, 100)
		expect(h1).to.equal(h2)
	end)

	test("returns Ocean zone for southern positions", function()
		local zone = Heightmap:GetZone(0, -3900)
		expect(zone).to.equal("Ocean")
	end)

	test("returns Mountains zone for northern positions", function()
		local zone = Heightmap:GetZone(0, 3900)
		expect(zone).to.equal("Mountains")
	end)
end)

-- ==========================================
-- STORYDATA TESTS
-- ==========================================

describe("StoryData", function()
	test("has Acts defined", function()
		expect(StoryData.Acts).to.be.ok()
	end)

	test("has Endings defined", function()
		expect(StoryData.Endings).to.be.ok()
	end)

	test("has Dialogue defined", function()
		expect(StoryData.Dialogue).to.be.ok()
	end)

	test("has at least 3 acts", function()
		local count = 0
		for _ in pairs(StoryData.Acts) do
			count += 1
		end
		expect(count >= 3).to.equal(true)
	end)
end)

-- ==========================================
-- SUMMARY
-- ==========================================

print("")
print("════════════════════════════════════════════════")
print(string.format("Results: %d passed, %d failed", passed, failed))

if failed > 0 then
	print("")
	print("❌ SOME TESTS FAILED")
else
	print("")
	print("✅ ALL TESTS PASSED")
end
print("════════════════════════════════════════════════")
