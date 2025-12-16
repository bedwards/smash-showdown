--!strict
-- Faultline Fear: Day/Night Cycle Service
-- Controls time of day, lighting, and danger periods

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config

export type TimePeriod = "Dawn" | "Day" | "Dusk" | "Night"

export type TimeData = {
	clockTime: number, -- 0-24
	period: TimePeriod,
	isDangerous: boolean,
	minutesUntilDanger: number,
}

local DayNightService = {}

-- State
local currentClockTime: number = 8 -- Start at 8 AM
local timeScale: number = 1 -- Multiplier for time speed
local isPaused: boolean = false

-- Remote events
local TimeUpdate: RemoteEvent = nil :: any

-- Lighting presets for each period
local LightingPresets = {
	Dawn = {
		ClockTime = 5.5,
		Ambient = Color3.fromRGB(180, 180, 200),
		OutdoorAmbient = Color3.fromRGB(120, 140, 180),
		Brightness = 1,
		ColorShift_Top = Color3.fromRGB(200, 180, 160),
		ExposureCompensation = -0.5,
	},
	Day = {
		ClockTime = 12,
		Ambient = Color3.fromRGB(200, 200, 200),
		OutdoorAmbient = Color3.fromRGB(180, 180, 180),
		Brightness = 2,
		ColorShift_Top = Color3.fromRGB(255, 255, 255),
		ExposureCompensation = 0,
	},
	Dusk = {
		ClockTime = 20.5,
		Ambient = Color3.fromRGB(200, 150, 120),
		OutdoorAmbient = Color3.fromRGB(180, 120, 100),
		Brightness = 1.5,
		ColorShift_Top = Color3.fromRGB(255, 180, 100),
		ExposureCompensation = -0.3,
	},
	Night = {
		ClockTime = 0,
		Ambient = Color3.fromRGB(80, 90, 120),
		OutdoorAmbient = Color3.fromRGB(40, 50, 80),
		Brightness = 0.5,
		ColorShift_Top = Color3.fromRGB(100, 120, 180),
		ExposureCompensation = -1,
	},
}

-- ==========================================
-- TIME CALCULATIONS
-- ==========================================

--[[
	Get the current period based on clock time.
]]
function DayNightService:GetCurrentPeriod(): TimePeriod
	local dn = Config.DAY_NIGHT

	if currentClockTime >= dn.DAWN_START and currentClockTime < dn.DAY_START then
		return "Dawn"
	elseif currentClockTime >= dn.DAY_START and currentClockTime < dn.DUSK_START then
		return "Day"
	elseif currentClockTime >= dn.DUSK_START and currentClockTime < dn.NIGHT_START then
		return "Dusk"
	else
		return "Night"
	end
end

--[[
	Get the current time of day (0-24).
]]
function DayNightService:GetTimeOfDay(): number
	return currentClockTime
end

--[[
	Check if it's currently dangerous (night time with predators).
]]
function DayNightService:IsNightDangerous(): boolean
	if not Config.DAY_NIGHT.PREDATORS_ACTIVE_AT_NIGHT then
		return false
	end
	return self:GetCurrentPeriod() == "Night"
end

--[[
	Check if NPCs should be sheltering.
]]
function DayNightService:ShouldNPCsShelter(): boolean
	if not Config.DAY_NIGHT.NPC_SHELTER_AT_NIGHT then
		return false
	end
	local period = self:GetCurrentPeriod()
	return period == "Night" or period == "Dusk"
end

--[[
	Get minutes until danger (night) starts.
	Returns 0 if already night.
]]
function DayNightService:GetMinutesUntilDanger(): number
	local period = self:GetCurrentPeriod()
	if period == "Night" then
		return 0
	end

	local dn = Config.DAY_NIGHT
	local hoursUntilNight: number

	if currentClockTime < dn.NIGHT_START then
		hoursUntilNight = dn.NIGHT_START - currentClockTime
	else
		-- After night start (wrapping to next day)
		hoursUntilNight = (24 - currentClockTime) + dn.NIGHT_START
	end

	-- Convert game hours to real minutes
	local gameHoursPerRealMinute = 24 / dn.FULL_CYCLE_MINUTES
	return hoursUntilNight / gameHoursPerRealMinute
end

--[[
	Get full time data for clients.
]]
function DayNightService:GetTimeData(): TimeData
	return {
		clockTime = currentClockTime,
		period = self:GetCurrentPeriod(),
		isDangerous = self:IsNightDangerous(),
		minutesUntilDanger = self:GetMinutesUntilDanger(),
	}
end

-- ==========================================
-- TIME CONTROL
-- ==========================================

--[[
	Set the time scale multiplier.
	1 = normal, 2 = double speed, 0.5 = half speed.
]]
function DayNightService:SetTimeScale(scale: number)
	timeScale = math.max(0, scale)
	print("[DayNightService] Time scale set to:", timeScale)
end

--[[
	Pause time progression.
]]
function DayNightService:Pause()
	isPaused = true
	print("[DayNightService] Time paused")
end

--[[
	Resume time progression.
]]
function DayNightService:Resume()
	isPaused = false
	print("[DayNightService] Time resumed")
end

--[[
	Set the current time directly.
]]
function DayNightService:SetTime(clockTime: number)
	currentClockTime = clockTime % 24
	self:UpdateLighting()
	self:BroadcastTimeUpdate()
	print("[DayNightService] Time set to:", currentClockTime)
end

-- ==========================================
-- LIGHTING
-- ==========================================

--[[
	Update lighting based on current period.
	Uses smooth transitions.
]]
function DayNightService:UpdateLighting()
	-- Update clock time directly
	Lighting.ClockTime = currentClockTime

	-- Get target preset based on current period
	local period = self:GetCurrentPeriod()
	local preset = LightingPresets[period]
	if not preset then
		return
	end

	-- Tween lighting properties for smooth transition
	local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	local properties = {
		Ambient = preset.Ambient,
		OutdoorAmbient = preset.OutdoorAmbient,
		Brightness = preset.Brightness,
		ColorShift_Top = preset.ColorShift_Top,
		ExposureCompensation = preset.ExposureCompensation,
	}

	local tween = TweenService:Create(Lighting, tweenInfo, properties)
	tween:Play()
end

-- ==========================================
-- BROADCAST
-- ==========================================

function DayNightService:BroadcastTimeUpdate()
	if TimeUpdate then
		TimeUpdate:FireAllClients(self:GetTimeData())
	end
end

-- ==========================================
-- TIME TICK
-- ==========================================

local lastPeriod: TimePeriod? = nil
local lastBroadcast: number = 0

local function timeTick(deltaTime: number)
	if isPaused then
		return
	end

	-- Calculate time advancement
	-- 24 game hours per FULL_CYCLE_MINUTES real minutes
	local dn = Config.DAY_NIGHT
	local hoursPerSecond = 24 / (dn.FULL_CYCLE_MINUTES * 60)
	local advancement = hoursPerSecond * deltaTime * timeScale

	-- Advance time
	currentClockTime = (currentClockTime + advancement) % 24

	-- Update Roblox clock
	Lighting.ClockTime = currentClockTime

	-- Check for period change
	local currentPeriod = DayNightService:GetCurrentPeriod()
	if currentPeriod ~= lastPeriod then
		print("[DayNightService] Period changed to:", currentPeriod)
		lastPeriod = currentPeriod
		DayNightService:UpdateLighting()
		DayNightService:BroadcastTimeUpdate()
	end

	-- Broadcast time update every 10 seconds
	local now = tick()
	if now - lastBroadcast >= 10 then
		lastBroadcast = now
		DayNightService:BroadcastTimeUpdate()
	end
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function DayNightService:Initialize()
	-- Get remote event
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	TimeUpdate = remotes:WaitForChild("TimeUpdate") :: RemoteEvent

	-- Set initial lighting
	self:UpdateLighting()
	lastPeriod = self:GetCurrentPeriod()

	-- Start time tick
	RunService.Heartbeat:Connect(timeTick)

	-- Initial broadcast
	self:BroadcastTimeUpdate()

	print("[DayNightService] Initialized at", currentClockTime, "(" .. self:GetCurrentPeriod() .. ")")
	print("[DayNightService] Full cycle:", Config.DAY_NIGHT.FULL_CYCLE_MINUTES, "minutes")
end

return DayNightService
