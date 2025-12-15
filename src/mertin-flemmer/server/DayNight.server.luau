--!strict
-- Day/Night cycle for Mertin-Flemmer
-- Controls lighting, atmosphere, and creature behavior

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config

-- Create RemoteEvent for time updates
local TimeUpdateRemote = Instance.new("RemoteEvent")
TimeUpdateRemote.Name = "TimeUpdate"
TimeUpdateRemote.Parent = ReplicatedStorage

-- Time state
local currentTime = 8 -- Start at 8 AM (safe daytime)
local currentState = Shared.TimeState.DAY
local dayCount = 1

-- Lighting presets
local LIGHTING_PRESETS = {
	Day = {
		ClockTime = 14,
		Brightness = 2,
		Ambient = Color3.fromRGB(120, 120, 130),
		OutdoorAmbient = Color3.fromRGB(130, 130, 140),
		FogEnd = 1000,
		FogColor = Color3.fromRGB(180, 190, 200),
	},
	Dusk = {
		ClockTime = 18,
		Brightness = 1,
		Ambient = Color3.fromRGB(100, 70, 50),
		OutdoorAmbient = Color3.fromRGB(120, 80, 60),
		FogEnd = 400,
		FogColor = Color3.fromRGB(100, 60, 40),
	},
	Night = {
		ClockTime = 0,
		Brightness = 0.1,
		Ambient = Color3.fromRGB(20, 20, 35),
		OutdoorAmbient = Color3.fromRGB(15, 15, 25),
		FogEnd = 150,
		FogColor = Color3.fromRGB(10, 10, 20),
	},
	Dawn = {
		ClockTime = 6,
		Brightness = 0.8,
		Ambient = Color3.fromRGB(80, 80, 100),
		OutdoorAmbient = Color3.fromRGB(100, 90, 110),
		FogEnd = 500,
		FogColor = Color3.fromRGB(120, 100, 130),
	},
}

-- Apply lighting preset with smooth transition
local function applyLighting(preset: { [string]: any }, duration: number)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	TweenService:Create(Lighting, tweenInfo, {
		ClockTime = preset.ClockTime,
		Brightness = preset.Brightness,
		Ambient = preset.Ambient,
		OutdoorAmbient = preset.OutdoorAmbient,
		FogEnd = preset.FogEnd,
		FogColor = preset.FogColor,
	}):Play()
end

-- Set time state
local function setTimeState(state: string)
	if state == currentState then return end

	local previousState = currentState
	currentState = state

	local preset = LIGHTING_PRESETS[state]
	if preset then
		local transitionTime = 5
		if state == Shared.TimeState.NIGHT or previousState == Shared.TimeState.NIGHT then
			transitionTime = 10 -- Slower transition for night
		end
		applyLighting(preset, transitionTime)
	end

	-- Broadcast to clients
	TimeUpdateRemote:FireAllClients({
		state = state,
		dayCount = dayCount,
		isNight = state == Shared.TimeState.NIGHT,
	})

	if state == Shared.TimeState.NIGHT then
		print("[DayNight] NIGHT FALLS - Day", dayCount, "- Creatures are now hostile!")
	elseif state == Shared.TimeState.DAY then
		dayCount = dayCount + 1
		print("[DayNight] SUNRISE - Day", dayCount, "- You survived the night!")
	else
		print("[DayNight] Transition to", state)
	end
end

-- Calculate time state from clock time
local function updateTimeState()
	if currentTime >= 7 and currentTime < 18 then
		setTimeState(Shared.TimeState.DAY)
	elseif currentTime >= 18 and currentTime < 20 then
		setTimeState(Shared.TimeState.DUSK)
	elseif currentTime >= 20 or currentTime < 5 then
		setTimeState(Shared.TimeState.NIGHT)
	else
		setTimeState(Shared.TimeState.DAWN)
	end
end

-- Time progression
local timeScale = 24 / (Config.DAY_LENGTH + Config.NIGHT_LENGTH) -- Hours per second

RunService.Heartbeat:Connect(function(dt)
	currentTime = currentTime + (timeScale * dt)
	if currentTime >= 24 then
		currentTime = currentTime - 24
	end

	Lighting.ClockTime = currentTime
	updateTimeState()
end)

-- Initialize
applyLighting(LIGHTING_PRESETS.Day, 0)
print("[DayNight] Cycle initialized - Day", dayCount)
print("[DayNight] Day length:", Config.DAY_LENGTH, "s | Night length:", Config.NIGHT_LENGTH, "s")
