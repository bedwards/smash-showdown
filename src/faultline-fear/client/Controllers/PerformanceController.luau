--!strict
--[[
	Faultline Fear: Performance Controller

	Manages performance settings on the client:
	- Battery saver mode (reduces effects, update rates)
	- FPS monitoring
	- Quality level adjustments

	Battery saver can be toggled manually or auto-enabled on low battery.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config
local InputService = Shared.InputService

local PerformanceController = {}

-- State
local isBatterySaverEnabled: boolean = false
local originalSettings: {
	shadowsEnabled: boolean?,
	globalShadows: boolean?,
	brightness: number?,
} = {}

-- FPS tracking
local frameCount: number = 0
local lastFpsCheck: number = 0
local currentFps: number = 60

-- ==========================================
-- FPS MONITORING
-- ==========================================

local function updateFpsCounter()
	frameCount += 1

	local now = tick()
	if now - lastFpsCheck >= 1 then
		currentFps = frameCount
		frameCount = 0
		lastFpsCheck = now
	end
end

function PerformanceController:GetCurrentFPS(): number
	return currentFps
end

function PerformanceController:IsPerformanceGood(): boolean
	local targetFps = InputService:GetDeviceType() == "Mobile" and Config.PERFORMANCE.TARGET_FPS_MOBILE
		or Config.PERFORMANCE.TARGET_FPS_DESKTOP
	return currentFps >= targetFps * 0.8 -- 80% of target is acceptable
end

-- ==========================================
-- BATTERY SAVER MODE
-- ==========================================

function PerformanceController:EnableBatterySaver()
	if isBatterySaverEnabled then
		return
	end

	isBatterySaverEnabled = true
	print("[PerformanceController] Battery saver ENABLED")

	local settings = Config.PERFORMANCE.BATTERY_SAVER

	-- Store original settings for restoration
	originalSettings.globalShadows = Lighting.GlobalShadows
	originalSettings.brightness = Lighting.Brightness

	-- Apply battery saver settings
	if not settings.SHADOW_ENABLED then
		Lighting.GlobalShadows = false
	end

	-- Disable post-processing effects
	if not settings.POST_EFFECTS_ENABLED then
		for _, effect in Lighting:GetChildren() do
			if
				effect:IsA("BloomEffect")
				or effect:IsA("BlurEffect")
				or effect:IsA("ColorCorrectionEffect")
				or effect:IsA("DepthOfFieldEffect")
				or effect:IsA("SunRaysEffect")
			then
				effect.Enabled = false
			end
		end
	end

	print("[PerformanceController] Shadows:", settings.SHADOW_ENABLED)
	print("[PerformanceController] Post effects:", settings.POST_EFFECTS_ENABLED)
	print("[PerformanceController] Particle multiplier:", settings.PARTICLE_MULTIPLIER)
end

function PerformanceController:DisableBatterySaver()
	if not isBatterySaverEnabled then
		return
	end

	isBatterySaverEnabled = false
	print("[PerformanceController] Battery saver DISABLED")

	-- Restore original settings
	if originalSettings.globalShadows ~= nil then
		Lighting.GlobalShadows = originalSettings.globalShadows
	end

	-- Re-enable post-processing effects
	for _, effect in Lighting:GetChildren() do
		if
			effect:IsA("BloomEffect")
			or effect:IsA("BlurEffect")
			or effect:IsA("ColorCorrectionEffect")
			or effect:IsA("DepthOfFieldEffect")
			or effect:IsA("SunRaysEffect")
		then
			effect.Enabled = true
		end
	end

	print("[PerformanceController] Original settings restored")
end

function PerformanceController:ToggleBatterySaver()
	if isBatterySaverEnabled then
		self:DisableBatterySaver()
	else
		self:EnableBatterySaver()
	end
end

function PerformanceController:IsBatterySaverEnabled(): boolean
	return isBatterySaverEnabled
end

-- ==========================================
-- PARTICLE SYSTEM HELPER
-- ==========================================

--[[
	Get the particle emission rate multiplier.
	Other systems should call this when creating particles.
]]
function PerformanceController:GetParticleMultiplier(): number
	if isBatterySaverEnabled then
		return Config.PERFORMANCE.BATTERY_SAVER.PARTICLE_MULTIPLIER
	end
	return 1.0
end

--[[
	Get the update rate for non-critical systems.
	Returns a longer interval when battery saver is enabled.
]]
function PerformanceController:GetUpdateInterval(normalInterval: number): number
	if isBatterySaverEnabled then
		return normalInterval * 2 -- Double the interval
	end
	return normalInterval
end

-- ==========================================
-- AUTO BATTERY SAVER (Low Performance Detection)
-- ==========================================

local lowFpsCount: number = 0
local LOW_FPS_TRIGGER_COUNT = 5 -- Enable after 5 seconds of low FPS

local function checkAutoEnable()
	if isBatterySaverEnabled then
		return
	end

	local targetFps = InputService:GetDeviceType() == "Mobile" and Config.PERFORMANCE.TARGET_FPS_MOBILE
		or Config.PERFORMANCE.TARGET_FPS_DESKTOP

	if currentFps < targetFps * 0.5 then -- Below 50% of target
		lowFpsCount += 1
		if lowFpsCount >= LOW_FPS_TRIGGER_COUNT then
			print("[PerformanceController] Auto-enabling battery saver due to low FPS")
			PerformanceController:EnableBatterySaver()
		end
	else
		lowFpsCount = 0
	end
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function PerformanceController:Initialize()
	-- Start FPS counter
	RunService.RenderStepped:Connect(updateFpsCounter)

	-- Auto battery saver check (every second)
	task.spawn(function()
		while true do
			task.wait(1)
			checkAutoEnable()
		end
	end)

	-- On mobile, consider auto-enabling battery saver by default
	local deviceType = InputService:GetDeviceType()
	if deviceType == "Mobile" then
		print("[PerformanceController] Mobile device detected")
		-- Don't auto-enable, but let user know it's available
		print("[PerformanceController] Battery saver available (will auto-enable if FPS drops)")
	end

	-- Keyboard shortcut for battery saver (F9)
	if UserInputService.KeyboardEnabled then
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end
			if input.KeyCode == Enum.KeyCode.F9 then
				self:ToggleBatterySaver()
			end
		end)
		print("[PerformanceController] Press F9 to toggle battery saver")
	end

	print("[PerformanceController] Initialized")
	print("[PerformanceController] Target FPS:", deviceType == "Mobile" and Config.PERFORMANCE.TARGET_FPS_MOBILE or Config.PERFORMANCE.TARGET_FPS_DESKTOP)
end

return PerformanceController
