--!strict
--[[
	Fault-Lite: Client Main Script

	Minimal client for structure showcase testing.
	- Camera shake during earthquakes (triggered by plugin via server)
	- No in-game UI - all controls are in the Studio plugin
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local camera = workspace.CurrentCamera

-- Wait for remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local TriggerEarthquakeEvent = Remotes:WaitForChild("TriggerEarthquake") :: RemoteEvent
local HeightmapReady = Remotes:WaitForChild("HeightmapReady") :: RemoteEvent

-- ==========================================
-- STATE
-- ==========================================

local shakeIntensity = 0
local shakeDuration = 0
local shakeStartTime = 0
local isShaking = false

-- ==========================================
-- CAMERA SHAKE (Fixed - no compounding)
-- ==========================================

local function startShake(duration: number, intensity: number)
	shakeIntensity = intensity
	shakeDuration = duration
	shakeStartTime = tick()
	isShaking = true
	print("[Fault-Lite] Starting camera shake: duration=" .. duration .. ", intensity=" .. intensity)
end

local function updateShake()
	if not isShaking then
		return
	end

	local elapsed = tick() - shakeStartTime
	if elapsed >= shakeDuration then
		isShaking = false
		return
	end

	-- Calculate shake amount (fades out over time)
	local progress = elapsed / shakeDuration
	local fadeOut = 1 - progress
	local currentIntensity = shakeIntensity * fadeOut

	-- Random shake offset - apply FRESH each frame, don't compound
	local offsetX = (math.random() - 0.5) * 2 * currentIntensity
	local offsetY = (math.random() - 0.5) * 2 * currentIntensity

	-- Store original position and apply offset from it
	-- This prevents compounding drift
	if camera then
		local baseCF = camera.CFrame
		-- Apply offset in screen space (local to camera)
		camera.CFrame = baseCF * CFrame.new(offsetX, offsetY, 0)
	end
end

-- ==========================================
-- EVENT HANDLERS
-- ==========================================

TriggerEarthquakeEvent.OnClientEvent:Connect(function(earthquakeType: string, duration: number, intensity: number)
	print("[Fault-Lite] Earthquake received: " .. earthquakeType)
	startShake(duration, intensity)
end)

HeightmapReady.OnClientEvent:Connect(function()
	print("[Fault-Lite] Heightmap ready!")
end)

-- ==========================================
-- RENDER LOOP
-- ==========================================

RunService.RenderStepped:Connect(function()
	updateShake()
end)

-- ==========================================
-- INITIALIZATION
-- ==========================================

print("[Fault-Lite] Client ready!")
print("Use the Studio plugin to spawn structures and trigger earthquakes")
