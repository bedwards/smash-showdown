--[[
	Faultline Fear: World Screenshot Capture

	Captures screenshots from multiple locations, angles, and zoom levels
	for visual verification of the game world.

	Usage:
		1. Start screenshot server: cd tools/roblox-screenshot && node .
		2. Build: rojo build faultline-fear.project.json -o faultline-fear.rbxl
		3. run-in-roblox --place faultline-fear.rbxl --script tools/capture-world-screenshots.luau

	Screenshots saved to: tools/roblox-screenshot/screenshots/world-verify/
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

-- Wait for shared modules
local Shared = ReplicatedStorage:WaitForChild("Shared", 5)
local Heightmap = Shared and require(Shared:WaitForChild("Heightmap"))
local Config = Shared and require(Shared:WaitForChild("Config"))

-- Generate heightmap if needed
if Heightmap and not Heightmap:IsGenerated() then
	print("[Screenshot] Generating heightmap...")
	Heightmap:Generate(Config.TERRAIN_SEED)
end

-- ==========================================
-- VISUAL TERRAIN GENERATION
-- run-in-roblox doesn't run Main.server, so we generate terrain here
-- ==========================================

local function generateVisualChunk(terrain, startX: number, startZ: number, size: number, voxelSize: number)
	local voxelsPerAxis = math.floor(size / voxelSize)

	-- Pre-allocate 3D arrays
	local materials: { { { Enum.Material } } } = {}
	local occupancy: { { { number } } } = {}

	for xi = 1, voxelsPerAxis do
		materials[xi] = {}
		occupancy[xi] = {}
		for yi = 1, voxelsPerAxis do
			materials[xi][yi] = {}
			occupancy[xi][yi] = {}
			for zi = 1, voxelsPerAxis do
				materials[xi][yi][zi] = Enum.Material.Air
				occupancy[xi][yi][zi] = 0
			end
		end
	end

	-- Fill from heightmap
	for xi = 1, voxelsPerAxis do
		local worldX = startX + (xi - 0.5) * voxelSize
		for zi = 1, voxelsPerAxis do
			local worldZ = startZ + (zi - 0.5) * voxelSize
			local height = Heightmap:GetHeight(worldX, worldZ)
			local material = Heightmap:GetMaterial(worldX, worldZ)

			for yi = 1, voxelsPerAxis do
				local worldY = (yi - 0.5) * voxelSize
				if worldY <= height then
					materials[xi][yi][zi] = material
					occupancy[xi][yi][zi] = 1
				elseif worldY <= height + voxelSize then
					local surfaceBlend = 1 - (worldY - height) / voxelSize
					occupancy[xi][yi][zi] = math.clamp(surfaceBlend, 0, 1)
					materials[xi][yi][zi] = material
				end
			end
		end
	end

	local region = Region3.new(
		Vector3.new(startX, 0, startZ),
		Vector3.new(startX + size, size, startZ + size)
	):ExpandToGrid(voxelSize)

	terrain:WriteVoxels(region, voxelSize, materials, occupancy)
end

local function generateVisualTerrain()
	print("[Screenshot] Generating visual terrain...")
	local startTime = tick()

	local terrain = Workspace.Terrain
	terrain:Clear()

	local worldSize = Config.WORLD_SIZE
	local halfWorld = worldSize / 2
	local voxelSize = 4
	local chunkSize = 64

	-- Count chunks for progress
	local totalChunks = 0
	for _ = -halfWorld, halfWorld - chunkSize, chunkSize do
		for _ = -halfWorld, halfWorld - chunkSize, chunkSize do
			totalChunks += 1
		end
	end

	local generatedChunks = 0
	for chunkX = -halfWorld, halfWorld - chunkSize, chunkSize do
		for chunkZ = -halfWorld, halfWorld - chunkSize, chunkSize do
			generateVisualChunk(terrain, chunkX, chunkZ, chunkSize, voxelSize)
			generatedChunks += 1

			if generatedChunks % math.ceil(totalChunks / 10) == 0 then
				local progress = math.floor(generatedChunks / totalChunks * 100)
				print(string.format("[Screenshot] Visual terrain: %d%%", progress))
			end

			if generatedChunks % 16 == 0 then
				task.wait()
			end
		end
	end

	-- Generate ocean water
	local oceanDepth = 30
	local oceanRegion = Region3.new(
		Vector3.new(-halfWorld, Config.OCEAN_LEVEL - oceanDepth, Config.ZONES.OCEAN.zMin),
		Vector3.new(halfWorld, Config.OCEAN_LEVEL, Config.ZONES.BEACH.zMax)
	)
	terrain:FillRegion(oceanRegion, 4, Enum.Material.Water)

	local elapsed = tick() - startTime
	print(string.format("[Screenshot] Visual terrain complete in %.2f seconds", elapsed))
end

-- Generate visual terrain (since Main.server doesn't run via run-in-roblox)
if Heightmap and Heightmap:IsGenerated() then
	generateVisualTerrain()
end

-- ==========================================
-- SCREENSHOT CONFIGURATION
-- ==========================================

-- Camera positions to capture
-- Each entry: { name, x, z, yOffset, pitch (degrees), yaw (degrees), fov }
-- NOTE: World is 4000 studs, ranging from -2000 to +2000 in X and Z
-- Zone boundaries (Z axis, south to north):
--   Ocean: -2000 to -1200, Beach: -1200 to -800, Coastal: -800 to -200
--   Valley: -200 to 400, Fault Line: 400 to 800, Forest: 800 to 1500
--   Mountains: 1500 to 2000
local CAMERA_SHOTS = {
	-- SPAWN AREA (Valley, z ~ 0)
	{ name = "spawn_overview", x = 0, z = 0, yOffset = 50, pitch = -30, yaw = 0, fov = 70 },
	{ name = "spawn_ground", x = 0, z = 0, yOffset = 5, pitch = 0, yaw = 45, fov = 70 },

	-- OCEAN / BEACH (South, z = -1200 to -2000)
	{ name = "ocean_view", x = 0, z = -1800, yOffset = 20, pitch = -10, yaw = 0, fov = 70 },
	{ name = "beach_panorama", x = 0, z = -1100, yOffset = 15, pitch = -5, yaw = 90, fov = 90 },
	{ name = "beach_looking_inland", x = 0, z = -1000, yOffset = 10, pitch = 5, yaw = 180, fov = 70 },
	{ name = "beach_wide", x = 200, z = -1050, yOffset = 30, pitch = -15, yaw = -45, fov = 90 },

	-- COASTAL ZONE (z = -800 to -200)
	{ name = "coastal_town_area", x = 0, z = -500, yOffset = 30, pitch = -20, yaw = 0, fov = 70 },
	{ name = "coastal_looking_south", x = 0, z = -600, yOffset = 20, pitch = -5, yaw = 180, fov = 70 },

	-- VALLEY (z = -200 to 400)
	{ name = "valley_overview", x = 0, z = 100, yOffset = 50, pitch = -25, yaw = 0, fov = 80 },
	{ name = "valley_ground_level", x = 100, z = 200, yOffset = 5, pitch = 0, yaw = 90, fov = 70 },

	-- FAULT LINE (z = 400 to 800, the dramatic rift!)
	{ name = "fault_line_approach", x = 0, z = 450, yOffset = 40, pitch = -20, yaw = 0, fov = 70 },
	{ name = "fault_line_edge", x = 0, z = 550, yOffset = 20, pitch = -30, yaw = 0, fov = 70 },
	{ name = "fault_line_looking_down", x = 0, z = 600, yOffset = 50, pitch = -60, yaw = 0, fov = 70 },
	{ name = "fault_line_panorama", x = 300, z = 650, yOffset = 30, pitch = -15, yaw = -90, fov = 100 },
	{ name = "fault_line_wide_east", x = 500, z = 600, yOffset = 40, pitch = -20, yaw = 180, fov = 80 },
	{ name = "fault_line_wide_west", x = -500, z = 600, yOffset = 40, pitch = -20, yaw = 180, fov = 80 },

	-- FOREST (z = 800 to 1500)
	{ name = "forest_entrance", x = 0, z = 900, yOffset = 30, pitch = -15, yaw = 0, fov = 70 },
	{ name = "forest_looking_back", x = 0, z = 1200, yOffset = 25, pitch = -10, yaw = 180, fov = 70 },
	{ name = "forest_hills", x = 200, z = 1400, yOffset = 60, pitch = -25, yaw = 45, fov = 80 },

	-- MOUNTAINS (North, z = 1500 to 2000)
	{ name = "mountain_approach", x = 0, z = 1550, yOffset = 80, pitch = -20, yaw = 0, fov = 70 },
	{ name = "mountain_peaks", x = 0, z = 1750, yOffset = 150, pitch = -15, yaw = 0, fov = 70 },
	{ name = "mountain_panorama", x = 300, z = 1850, yOffset = 200, pitch = -10, yaw = -90, fov = 100 },
	{ name = "mountain_looking_south", x = 0, z = 1950, yOffset = 250, pitch = -5, yaw = 180, fov = 80 },

	-- OVERVIEW SHOTS
	{ name = "world_center_high", x = 0, z = 0, yOffset = 500, pitch = -45, yaw = 0, fov = 90 },
	{ name = "world_north_view", x = 0, z = 0, yOffset = 400, pitch = -30, yaw = 0, fov = 90 },
	{ name = "world_south_view", x = 0, z = 0, yOffset = 400, pitch = -30, yaw = 180, fov = 90 },
}

-- ==========================================
-- SCREENSHOT SERVER COMMUNICATION
-- ==========================================

local SCREENSHOT_PORT = 28081
local SCREENSHOT_URL = "http://localhost:" .. SCREENSHOT_PORT

local function httpRequest(endpoint, data)
	local url = SCREENSHOT_URL .. endpoint
	print("[HTTP] Requesting: " .. url)
	local success, result = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(data or {}),
		})
	end)

	if not success then
		print("[HTTP] pcall failed: " .. tostring(result))
		return false, result
	end

	if result.Success then
		print("[HTTP] Success! Status: " .. tostring(result.StatusCode))
		return true, result.Body
	else
		print("[HTTP] Request failed. Status: " .. tostring(result.StatusCode) .. " Body: " .. tostring(result.Body))
		return false, result
	end
end

local function takeScreenshot(name)
	local success, result = httpRequest("/screenshot", {
		destination = "world-verify/" .. name,  -- Server adds .png automatically
	})
	return success
end

-- ==========================================
-- CAMERA CONTROL
-- ==========================================

local function positionCamera(shot)
	local camera = Workspace.CurrentCamera
	if not camera then
		warn("No camera found!")
		return false
	end

	-- Get terrain height at position
	local terrainY = 0
	if Heightmap and Heightmap:IsGenerated() then
		terrainY = Heightmap:GetHeight(shot.x, shot.z)
	end

	-- Calculate camera position
	local cameraY = terrainY + shot.yOffset
	local cameraPos = Vector3.new(shot.x, cameraY, shot.z)

	-- Calculate look direction from pitch and yaw
	local pitchRad = math.rad(shot.pitch)
	local yawRad = math.rad(shot.yaw)

	-- Direction vector
	local lookDir = Vector3.new(
		math.sin(yawRad) * math.cos(pitchRad),
		math.sin(pitchRad),
		math.cos(yawRad) * math.cos(pitchRad)
	)

	local lookAt = cameraPos + lookDir * 100

	-- Set camera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(cameraPos, lookAt)
	camera.FieldOfView = shot.fov or 70

	-- Wait for rendering
	task.wait(0.3)

	return true
end

-- ==========================================
-- MAIN CAPTURE LOOP
-- ==========================================

print("╔════════════════════════════════════════════════╗")
print("║   FAULTLINE FEAR WORLD SCREENSHOT CAPTURE      ║")
print("╚════════════════════════════════════════════════╝")
print("")

-- Test screenshot server connection (any response means server is up)
local serverOk = true
local testSuccess, testResult = pcall(function()
	return HttpService:RequestAsync({
		Url = SCREENSHOT_URL .. "/",
		Method = "GET",
	})
end)
if not testSuccess then
	serverOk = false
	print("ERROR: Screenshot server not reachable!")
	print("Error: " .. tostring(testResult))
	print("Start it with: cd tools/roblox-screenshot && node .")
	print("")
	print("Continuing anyway to position camera (no screenshots will be saved)")
else
	print("Screenshot server connected (port " .. SCREENSHOT_PORT .. ")")
end

print(string.format("Capturing %d screenshots...\n", #CAMERA_SHOTS))

local captured = 0
local failed = 0

for i, shot in ipairs(CAMERA_SHOTS) do
	print(string.format("[%d/%d] %s", i, #CAMERA_SHOTS, shot.name))

	-- Position camera
	if positionCamera(shot) then
		-- Get zone info
		local zone = "Unknown"
		if Heightmap and Heightmap:IsGenerated() then
			zone = Heightmap:GetZone(shot.x, shot.z)
		end

		local terrainY = 0
		if Heightmap and Heightmap:IsGenerated() then
			terrainY = Heightmap:GetHeight(shot.x, shot.z)
		end

		print(string.format("  Position: (%d, %d) Zone: %s TerrainY: %.1f", shot.x, shot.z, zone, terrainY))

		-- Take screenshot
		if serverOk then
			if takeScreenshot(shot.name) then
				captured += 1
				print("  ✓ Screenshot saved")
			else
				failed += 1
				print("  ✗ Screenshot failed")
			end
		end
	else
		failed += 1
		print("  ✗ Camera positioning failed")
	end

	task.wait(0.2)
end

print("")
print("════════════════════════════════════════════════")
print(string.format("Results: %d captured, %d failed", captured, failed))
print("Screenshots saved to: tools/roblox-screenshot/screenshots/world-verify/")
print("════════════════════════════════════════════════")
