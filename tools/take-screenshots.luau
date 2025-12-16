--[[
	Faultline Fear: Screenshot Automation Script

	Takes screenshots of key game locations for visual verification.
	Requires roblox-screenshot server to be running:
		cd tools/roblox-screenshot && node .

	Usage in Studio:
		1. Start the screenshot server (see above)
		2. Open the game in Studio
		3. Run this script or paste into command bar

	Screenshots saved to: tools/roblox-screenshot/screenshots/
]]

-- Try to load the screenshotter module
local Screenshotter
local success = pcall(function()
	Screenshotter = require(2218503664)
end)

if not success then
	warn("Could not load Screenshotter module. Make sure you're in Studio.")
	warn("Alternative: Use the HTTP API directly")
	return
end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local SCREENSHOT_SERVER = "http://localhost:28081"

-- Screenshot locations to capture
local LOCATIONS = {
	{ name = "spawn", position = Vector3.new(0, 50, 0), description = "Spawn area" },
	{ name = "beach", position = Vector3.new(0, 10, -3500), description = "Beach zone" },
	{ name = "valley", position = Vector3.new(0, 30, -1000), description = "Valley zone" },
	{ name = "fault_line", position = Vector3.new(0, 50, 500), description = "Fault line" },
	{ name = "forest", position = Vector3.new(0, 100, 2000), description = "Forest zone" },
	{ name = "mountains", position = Vector3.new(0, 200, 3500), description = "Mountain zone" },
}

local function takeScreenshot(name: string)
	print(string.format("[Screenshot] Taking: %s", name))

	local result = Screenshotter:Screenshot({
		Name = "faultline-fear/" .. name,
		Overwrite = true,
	})

	if result.Success then
		print(string.format("[Screenshot] Saved: %s", result.Path or name))
	else
		warn(string.format("[Screenshot] Failed: %s - %s", name, result.Error or "unknown error"))
	end

	return result.Success
end

local function teleportCamera(position: Vector3)
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.new(position + Vector3.new(0, 10, 20), position)
		task.wait(0.5) -- Wait for rendering
	end
end

local function captureAllLocations()
	print("╔════════════════════════════════════════╗")
	print("║   FAULTLINE FEAR SCREENSHOT CAPTURE    ║")
	print("╚════════════════════════════════════════╝")

	local captured = 0
	local failed = 0

	for _, location in ipairs(LOCATIONS) do
		print(string.format("\n[%s] %s", location.name, location.description))
		teleportCamera(location.position)

		if takeScreenshot(location.name) then
			captured += 1
		else
			failed += 1
		end

		task.wait(1) -- Delay between screenshots
	end

	print("\n════════════════════════════════════════")
	print(string.format("Results: %d captured, %d failed", captured, failed))
	print("Screenshots in: tools/roblox-screenshot/screenshots/faultline-fear/")
	print("════════════════════════════════════════")
end

-- Also take a screenshot of current view
local function captureCurrentView()
	takeScreenshot("current_view_" .. os.time())
end

-- Export functions
return {
	captureAll = captureAllLocations,
	capture = takeScreenshot,
	captureCurrentView = captureCurrentView,
}
