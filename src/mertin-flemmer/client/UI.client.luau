--!strict
-- UI for Mertin-Flemmer
-- Stamina bar, time of day, warnings

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config

-- Wait for remotes
local TimeUpdateRemote = ReplicatedStorage:WaitForChild("TimeUpdate") :: RemoteEvent

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MertinFlemmerUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Stamina bar
local staminaContainer = Instance.new("Frame")
staminaContainer.Name = "StaminaBar"
staminaContainer.Size = UDim2.new(0, 200, 0, 10)
staminaContainer.Position = UDim2.new(0.5, -100, 1, -50)
staminaContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
staminaContainer.BorderSizePixel = 0
staminaContainer.Parent = screenGui

local staminaCorner = Instance.new("UICorner")
staminaCorner.CornerRadius = UDim.new(0, 4)
staminaCorner.Parent = staminaContainer

local staminaFill = Instance.new("Frame")
staminaFill.Name = "Fill"
staminaFill.Size = UDim2.new(1, -4, 1, -4)
staminaFill.Position = UDim2.new(0, 2, 0, 2)
staminaFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
staminaFill.BorderSizePixel = 0
staminaFill.Parent = staminaContainer

local staminaFillCorner = Instance.new("UICorner")
staminaFillCorner.CornerRadius = UDim.new(0, 2)
staminaFillCorner.Parent = staminaFill

-- Time display
local timeDisplay = Instance.new("TextLabel")
timeDisplay.Name = "TimeDisplay"
timeDisplay.Size = UDim2.new(0, 150, 0, 40)
timeDisplay.Position = UDim2.new(0.5, -75, 0, 10)
timeDisplay.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
timeDisplay.BackgroundTransparency = 0.3
timeDisplay.Text = "Day 1"
timeDisplay.TextColor3 = Color3.new(1, 1, 1)
timeDisplay.Font = Enum.Font.GothamBold
timeDisplay.TextSize = 18
timeDisplay.Parent = screenGui

local timeCorner = Instance.new("UICorner")
timeCorner.CornerRadius = UDim.new(0, 8)
timeCorner.Parent = timeDisplay

-- Night warning
local nightWarning = Instance.new("TextLabel")
nightWarning.Name = "NightWarning"
nightWarning.Size = UDim2.new(1, 0, 0, 60)
nightWarning.Position = UDim2.new(0, 0, 0.3, 0)
nightWarning.BackgroundTransparency = 1
nightWarning.Text = "NIGHT IS FALLING"
nightWarning.TextColor3 = Color3.fromRGB(255, 50, 50)
nightWarning.TextStrokeTransparency = 0
nightWarning.TextStrokeColor3 = Color3.new(0, 0, 0)
nightWarning.Font = Enum.Font.GothamBlack
nightWarning.TextSize = 48
nightWarning.TextTransparency = 1
nightWarning.Parent = screenGui

-- Controls hint
local controlsHint = Instance.new("TextLabel")
controlsHint.Size = UDim2.new(0, 300, 0, 20)
controlsHint.Position = UDim2.new(0.5, -150, 1, -25)
controlsHint.BackgroundTransparency = 1
controlsHint.Text = "WASD: Move | Shift: Sprint | F: Flashlight"
controlsHint.TextColor3 = Color3.fromRGB(180, 180, 180)
controlsHint.Font = Enum.Font.Gotham
controlsHint.TextSize = 12
controlsHint.Parent = screenGui

-- Track stamina locally
local currentStamina = Config.MAX_STAMINA

-- Handle time updates
TimeUpdateRemote.OnClientEvent:Connect(function(data: { state: string, dayCount: number, isNight: boolean })
	timeDisplay.Text = "Day " .. data.dayCount .. " - " .. data.state

	if data.isNight then
		timeDisplay.TextColor3 = Color3.fromRGB(255, 100, 100)

		-- Show warning
		nightWarning.TextTransparency = 0
		local tween = TweenService:Create(nightWarning, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			TextTransparency = 1,
		})
		task.delay(1, function()
			tween:Play()
		end)
	else
		timeDisplay.TextColor3 = Color3.new(1, 1, 1)
	end
end)

-- Update stamina display
RunService.Heartbeat:Connect(function()
	-- Get stamina from character (simplified - in real game would use attributes)
	local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Estimate stamina based on walk speed
		local isSprinting = humanoid.WalkSpeed > Config.WALK_SPEED
		if isSprinting then
			currentStamina = math.max(0, currentStamina - Config.STAMINA_DRAIN * 0.016)
		else
			currentStamina = math.min(Config.MAX_STAMINA, currentStamina + Config.STAMINA_REGEN * 0.016)
		end

		local percent = currentStamina / Config.MAX_STAMINA
		staminaFill.Size = UDim2.new(percent, -4, 1, -4)
	end
end)

print("[UI] Mertin-Flemmer UI ready!")
