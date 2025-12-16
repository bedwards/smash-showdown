--!strict
--[[
	Lune Test Runner for Faultline Fear

	Run with: lune run tests/run.luau

	This runner discovers and executes all test files in tests/faultline-fear/
	Tests should return a table of test functions.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

-- Colors for output
local GREEN = "\27[32m"
local RED = "\27[31m"
local YELLOW = "\27[33m"
local RESET = "\27[0m"

-- Test result tracking
local totalTests = 0
local passedTests = 0
local failedTests = 0
local errors: { string } = {}

-- Simple assertion helpers
local function assertEquals(actual: any, expected: any, message: string?)
	if actual ~= expected then
		local msg = message or string.format("Expected %s but got %s", tostring(expected), tostring(actual))
		error(msg, 2)
	end
end

local function assertTrue(value: any, message: string?)
	if not value then
		error(message or "Expected true but got false", 2)
	end
end

local function assertFalse(value: any, message: string?)
	if value then
		error(message or "Expected false but got true", 2)
	end
end

local function assertNil(value: any, message: string?)
	if value ~= nil then
		error(message or string.format("Expected nil but got %s", tostring(value)), 2)
	end
end

local function assertNotNil(value: any, message: string?)
	if value == nil then
		error(message or "Expected non-nil value but got nil", 2)
	end
end

local function assertInRange(value: number, min: number, max: number, message: string?)
	if value < min or value > max then
		local msg = message or string.format("Expected %s to be in range [%s, %s]", tostring(value), tostring(min), tostring(max))
		error(msg, 2)
	end
end

-- Export assertions for test files
local TestAssert = {
	assertEquals = assertEquals,
	assertTrue = assertTrue,
	assertFalse = assertFalse,
	assertNil = assertNil,
	assertNotNil = assertNotNil,
	assertInRange = assertInRange,
}

-- Run a single test
local function runTest(name: string, testFn: () -> ())
	totalTests += 1
	local success, err = pcall(testFn)

	if success then
		passedTests += 1
		print(string.format("  %s✓%s %s", GREEN, RESET, name))
	else
		failedTests += 1
		print(string.format("  %s✗%s %s", RED, RESET, name))
		print(string.format("    %sError: %s%s", RED, tostring(err), RESET))
		table.insert(errors, string.format("%s: %s", name, tostring(err)))
	end
end

-- Run a test suite (table of test functions)
local function runSuite(suiteName: string, tests: { [string]: () -> () })
	print(string.format("\n%s=== %s ===%s", YELLOW, suiteName, RESET))

	-- Sort test names for consistent ordering
	local testNames = {}
	for name in pairs(tests) do
		table.insert(testNames, name)
	end
	table.sort(testNames)

	for _, name in ipairs(testNames) do
		runTest(name, tests[name])
	end
end

-- Make TestAssert available globally for test files
-- (Lune modules can't require local files easily, so we use a global)
_G.TestAssert = TestAssert

-- Discover and run test files
print("\n╔════════════════════════════════════════╗")
print("║     FAULTLINE FEAR TEST RUNNER         ║")
print("╚════════════════════════════════════════╝")

local testDir = "tests/faultline-fear"

if not fs.isDir(testDir) then
	print(string.format("%sError: Test directory '%s' not found%s", RED, testDir, RESET))
	process.exit(1)
end

local files = fs.readDir(testDir)
local testFiles: { string } = {}

for _, file in ipairs(files) do
	if string.match(file, "%.luau$") then
		table.insert(testFiles, file)
	end
end

table.sort(testFiles)

if #testFiles == 0 then
	print(string.format("%sNo test files found in %s%s", YELLOW, testDir, RESET))
	process.exit(0)
end

print(string.format("\nFound %d test file(s)", #testFiles))

-- Run each test file
for _, file in ipairs(testFiles) do
	local filePath = testDir .. "/" .. file
	local content = fs.readFile(filePath)

	-- Load and execute the test file
	local chunk, loadErr = loadstring(content, filePath)
	if not chunk then
		print(string.format("%sError loading %s: %s%s", RED, file, tostring(loadErr), RESET))
		failedTests += 1
		continue
	end

	local success, result = pcall(chunk)
	if not success then
		print(string.format("%sError running %s: %s%s", RED, file, tostring(result), RESET))
		failedTests += 1
		continue
	end

	-- Result should be a table of test functions
	if type(result) == "table" then
		local suiteName = string.gsub(file, "%.luau$", "")
		runSuite(suiteName, result)
	else
		print(string.format("%sWarning: %s did not return a test table%s", YELLOW, file, RESET))
	end
end

-- Print summary
print("\n────────────────────────────────────────")
print(string.format("Results: %s%d passed%s, %s%d failed%s, %d total",
	GREEN, passedTests, RESET,
	failedTests > 0 and RED or GREEN, failedTests, RESET,
	totalTests
))

if failedTests > 0 then
	print(string.format("\n%sFailed tests:%s", RED, RESET))
	for _, err in ipairs(errors) do
		print(string.format("  • %s", err))
	end
	print("")
	process.exit(1)
else
	print(string.format("\n%s✅ All tests passed!%s\n", GREEN, RESET))
	process.exit(0)
end
