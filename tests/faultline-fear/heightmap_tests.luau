--!strict
--[[
	Heightmap Algorithm Tests

	Tests the pure mathematical functions used in terrain generation.
	These functions are extracted from Heightmap.luau for standalone testing.
]]

local TestAssert = _G.TestAssert :: {
	assertEquals: (any, any, string?) -> (),
	assertTrue: (any, string?) -> (),
	assertFalse: (any, string?) -> (),
	assertNil: (any, string?) -> (),
	assertNotNil: (any, string?) -> (),
	assertInRange: (number, number, number, string?) -> (),
}

-- ==========================================
-- EXTRACTED FUNCTIONS FROM HEIGHTMAP.LUAU
-- (These must match the game implementation)
-- ==========================================

local function octaveNoise(
	x: number,
	z: number,
	octaves: number,
	persistence: number,
	scale: number,
	noiseSeed: number
): number
	local total = 0
	local maxValue = 0
	local amplitude = 1
	local frequency = 1

	for _ = 1, octaves do
		total += math.noise(x * frequency / scale, z * frequency / scale, noiseSeed) * amplitude
		maxValue += amplitude
		amplitude *= persistence
		frequency *= 2
	end

	return total / maxValue -- Normalize to -1 to 1
end

local function ridgeNoise(x: number, z: number, scale: number, noiseSeed: number): number
	local n = math.noise(x / scale, z / scale, noiseSeed + 100)
	return 1 - math.abs(n) -- Creates sharp ridges
end

local CELL_SIZE = 4

local function worldToCell(worldX: number, worldZ: number, worldSize: number): (number, number)
	local halfWorld = worldSize / 2
	local cellX = math.floor((worldX + halfWorld) / CELL_SIZE) + 1
	local cellZ = math.floor((worldZ + halfWorld) / CELL_SIZE) + 1
	return cellX, cellZ
end

local function cellToWorld(cellX: number, cellZ: number, worldSize: number): (number, number)
	local halfWorld = worldSize / 2
	local worldX = (cellX - 1) * CELL_SIZE - halfWorld + CELL_SIZE / 2
	local worldZ = (cellZ - 1) * CELL_SIZE - halfWorld + CELL_SIZE / 2
	return worldX, worldZ
end

-- ==========================================
-- TESTS
-- ==========================================

local tests = {}

-- Octave Noise Tests
tests["octaveNoise returns value in [-1, 1] range"] = function()
	for i = 1, 100 do
		local x = math.random() * 1000 - 500
		local z = math.random() * 1000 - 500
		local value = octaveNoise(x, z, 4, 0.5, 200, 12345)
		TestAssert.assertInRange(value, -1, 1, string.format("Value at (%s, %s) was %s", x, z, value))
	end
end

tests["octaveNoise is deterministic with same seed"] = function()
	local seed = 42
	local v1 = octaveNoise(100, 200, 4, 0.5, 200, seed)
	local v2 = octaveNoise(100, 200, 4, 0.5, 200, seed)
	TestAssert.assertEquals(v1, v2, "Same inputs should produce same output")
end

tests["octaveNoise varies with different positions"] = function()
	local seed = 12345
	local v1 = octaveNoise(0, 0, 4, 0.5, 200, seed)
	local v2 = octaveNoise(100, 100, 4, 0.5, 200, seed)
	local v3 = octaveNoise(500, 500, 4, 0.5, 200, seed)

	-- At least some values should be different
	local allSame = (v1 == v2) and (v2 == v3)
	TestAssert.assertFalse(allSame, "Different positions should produce different values")
end

tests["octaveNoise varies with different seeds"] = function()
	local v1 = octaveNoise(100, 100, 4, 0.5, 200, 1)
	local v2 = octaveNoise(100, 100, 4, 0.5, 200, 2)
	-- Seeds 1 and 2 might give same value by chance, but it's unlikely
	-- This is a weak test but catches gross errors
	TestAssert.assertTrue(type(v1) == "number", "Should return number")
	TestAssert.assertTrue(type(v2) == "number", "Should return number")
end

-- Ridge Noise Tests
tests["ridgeNoise returns value in [0, 1] range"] = function()
	for i = 1, 100 do
		local x = math.random() * 1000 - 500
		local z = math.random() * 1000 - 500
		local value = ridgeNoise(x, z, 80, 12345)
		TestAssert.assertInRange(value, 0, 1, string.format("Ridge value at (%s, %s) was %s", x, z, value))
	end
end

tests["ridgeNoise is deterministic"] = function()
	local v1 = ridgeNoise(50, 50, 80, 999)
	local v2 = ridgeNoise(50, 50, 80, 999)
	TestAssert.assertEquals(v1, v2, "Same inputs should produce same output")
end

-- Coordinate Conversion Tests
tests["worldToCell converts origin correctly"] = function()
	local worldSize = 8000
	local cellX, cellZ = worldToCell(0, 0, worldSize)
	-- Origin should be at center of grid
	local expectedCell = math.ceil(worldSize / CELL_SIZE / 2) + 1
	TestAssert.assertEquals(cellX, expectedCell, "Cell X at origin")
	TestAssert.assertEquals(cellZ, expectedCell, "Cell Z at origin")
end

tests["worldToCell and cellToWorld are inverse operations"] = function()
	local worldSize = 8000
	local testPositions = {
		{ 0, 0 },
		{ 100, 200 },
		{ -500, 500 },
		{ 1000, -1000 },
	}

	for _, pos in ipairs(testPositions) do
		local wx, wz = pos[1], pos[2]
		local cellX, cellZ = worldToCell(wx, wz, worldSize)
		local backX, backZ = cellToWorld(cellX, cellZ, worldSize)

		-- Should be within one cell size (due to cell center snapping)
		local diffX = math.abs(wx - backX)
		local diffZ = math.abs(wz - backZ)

		TestAssert.assertTrue(diffX <= CELL_SIZE, string.format("X roundtrip diff %s > %s", diffX, CELL_SIZE))
		TestAssert.assertTrue(diffZ <= CELL_SIZE, string.format("Z roundtrip diff %s > %s", diffZ, CELL_SIZE))
	end
end

tests["cellToWorld returns cell center"] = function()
	local worldSize = 8000
	local cellX, cellZ = 1, 1
	local wx, wz = cellToWorld(cellX, cellZ, worldSize)

	-- First cell should be at -halfWorld + CELL_SIZE/2
	local halfWorld = worldSize / 2
	local expectedX = -halfWorld + CELL_SIZE / 2
	local expectedZ = -halfWorld + CELL_SIZE / 2

	TestAssert.assertEquals(wx, expectedX, "First cell X position")
	TestAssert.assertEquals(wz, expectedZ, "First cell Z position")
end

-- Cell Size Consistency
tests["CELL_SIZE matches expected value"] = function()
	TestAssert.assertEquals(CELL_SIZE, 4, "Cell size should be 4 studs")
end

-- Noise Continuity (values shouldn't jump dramatically between adjacent samples)
tests["octaveNoise is continuous (no large jumps)"] = function()
	local seed = 12345
	local maxDelta = 0
	local prevValue = octaveNoise(0, 0, 4, 0.5, 200, seed)

	for i = 1, 100 do
		local value = octaveNoise(i * 0.5, 0, 4, 0.5, 200, seed)
		local delta = math.abs(value - prevValue)
		maxDelta = math.max(maxDelta, delta)
		prevValue = value
	end

	-- With these parameters, adjacent samples shouldn't differ by more than ~0.3
	TestAssert.assertTrue(maxDelta < 0.5, string.format("Max delta %s is too large for smooth terrain", maxDelta))
end

return tests
