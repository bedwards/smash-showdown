--!strict
-- Faultline Fear: Client Entry Point
-- Initializes all client-side controllers

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Wait for shared modules
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config
local InputService = Shared.InputService

print("[FaultlineFear Client] Starting...")

-- ==========================================
-- DEVICE DETECTION
-- ==========================================

local deviceType = InputService:GetDeviceType()
local screenSize = InputService:GetScreenSize()
local showTouchControls = InputService:ShouldShowTouchControls()

print("[FaultlineFear Client] Device:", deviceType)
print("[FaultlineFear Client] Screen:", screenSize)
print("[FaultlineFear Client] Touch controls:", showTouchControls)

-- Listen for input type changes (e.g., Bluetooth keyboard connected)
InputService:OnInputTypeChanged(function(newDeviceType)
	print("[FaultlineFear Client] Input type changed to:", newDeviceType)
	deviceType = newDeviceType
	-- TODO: Update UI accordingly
end)

-- Listen for screen size changes
InputService:OnScreenSizeChanged(function(newSize)
	print("[FaultlineFear Client] Screen size changed to:", newSize)
	screenSize = newSize
	-- TODO: Update HUD layout
end)

-- ==========================================
-- WAIT FOR REMOTES
-- ==========================================

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HungerUpdate = Remotes:WaitForChild("HungerUpdate") :: RemoteEvent
local EarthquakeEvent = Remotes:WaitForChild("EarthquakeEvent") :: RemoteEvent
local TimeUpdate = Remotes:WaitForChild("TimeUpdate") :: RemoteEvent
local ObjectiveUpdate = Remotes:WaitForChild("ObjectiveUpdate") :: RemoteEvent

-- ==========================================
-- CONTROLLER INITIALIZATION
-- ==========================================

local HUDController = require(script.Controllers.HUDController)
local AudioController = require(script.Controllers.AudioController)
local TouchController = require(script.Controllers.TouchController)
local PerformanceController = require(script.Controllers.PerformanceController)
local CreditsController = require(script.Controllers.CreditsController)
local DialogueController = require(script.Controllers.DialogueController)
local BeaconController = require(script.Controllers.BeaconController)
-- TODO: Initialize other controllers
-- local CameraController = require(script.Controllers.CameraController)

-- Initialize controllers
HUDController:Initialize()
AudioController:Initialize()
TouchController:Initialize() -- Only activates on touch devices
PerformanceController:Initialize() -- FPS monitoring, battery saver
CreditsController:Initialize() -- Ending sequence
DialogueController:Initialize() -- NPC dialogue UI
BeaconController:Initialize() -- Objective beacons

-- ==========================================
-- REMOTE EVENT HANDLERS
-- ==========================================

HungerUpdate.OnClientEvent:Connect(function(hungerData)
	HUDController:UpdateHunger(hungerData)
end)

EarthquakeEvent.OnClientEvent:Connect(function(earthquakeData)
	-- Show warning overlay
	if earthquakeData.warning then
		HUDController:ShowEarthquakeWarning(earthquakeData.magnitude or 0.5)
	else
		HUDController:HideEarthquakeWarning()
	end
	-- TODO: Camera shake, audio, particles
	-- CameraController:ShakeCamera(earthquakeData.magnitude)
	-- AudioController:PlayEarthquakeSounds(earthquakeData)
	print("[FaultlineFear Client] Earthquake!", earthquakeData)
end)

TimeUpdate.OnClientEvent:Connect(function(timeData)
	HUDController:UpdateTime(timeData)
end)

ObjectiveUpdate.OnClientEvent:Connect(function(objectiveData)
	HUDController:UpdateObjective(objectiveData)
end)

-- ==========================================
-- TOUCH CONTROLS (Mobile Only)
-- ==========================================

if showTouchControls then
	print("[FaultlineFear Client] Touch controls enabled via TouchController")
	-- TouchController handles all touch UI automatically
end

-- ==========================================
-- KEYBOARD CONTROLS (Desktop Only)
-- ==========================================

if InputService:HasPhysicalKeyboard() then
	local UserInputService = game:GetService("UserInputService")

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		-- Note: HUD toggle (Tab) is handled by HUDController internally

		-- Eat food
		if input.KeyCode == Config.KEYBINDS.EAT then
			-- TODO: Request eat from server
			print("[FaultlineFear Client] Eat food (not implemented)")
		end

		-- Flashlight
		if input.KeyCode == Config.KEYBINDS.FLASHLIGHT then
			-- TODO: Toggle flashlight
			print("[FaultlineFear Client] Toggle flashlight (not implemented)")
		end

		-- Call pet
		if input.KeyCode == Config.KEYBINDS.CALL_PET then
			-- TODO: Call pet
			print("[FaultlineFear Client] Call pet (not implemented)")
		end
	end)
end

-- ==========================================
-- CHARACTER SETUP
-- ==========================================

local function onCharacterAdded(_character: Model)
	print("[FaultlineFear Client] Character loaded")

	-- TODO: Setup character-specific client systems
	-- CameraController:SetupCamera(_character)
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- ==========================================
-- INITIALIZATION COMPLETE
-- ==========================================

print("[FaultlineFear Client] Initialized!")
print("[FaultlineFear Client] Waiting for controllers to be implemented...")
