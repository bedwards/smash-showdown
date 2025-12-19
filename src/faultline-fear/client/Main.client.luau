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
local ProgressUpdate = Remotes:WaitForChild("ProgressUpdate") :: RemoteEvent

-- ==========================================
-- CONTROLLER INITIALIZATION
-- ==========================================

local HUDController = require(script.Parent.Controllers.HUDController)
local AudioController = require(script.Parent.Controllers.AudioController)
local TouchController = require(script.Parent.Controllers.TouchController)
local PerformanceController = require(script.Parent.Controllers.PerformanceController)
local CreditsController = require(script.Parent.Controllers.CreditsController)
local DialogueController = require(script.Parent.Controllers.DialogueController)
local BeaconController = require(script.Parent.Controllers.BeaconController)
local FlashlightController = require(script.Parent.Controllers.FlashlightController)
local LiminalZoneController = require(script.Parent.Controllers.LiminalZoneController)
local DebugOverlayController = require(script.Parent.Controllers.DebugOverlayController)
-- TODO: Initialize other controllers
-- local CameraController = require(script.Parent.Controllers.CameraController)

-- Initialize controllers
HUDController:Initialize()
AudioController:Initialize()
TouchController:Initialize() -- Only activates on touch devices
PerformanceController:Initialize() -- FPS monitoring, battery saver
CreditsController:Initialize() -- Ending sequence
DialogueController:Initialize() -- NPC dialogue UI
BeaconController:Initialize() -- Objective beacons
FlashlightController:Initialize() -- Flashlight with battery
LiminalZoneController:Initialize() -- Liminal space effects
DebugOverlayController:Initialize() -- F3 debug overlay (desktop only)

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

ProgressUpdate.OnClientEvent:Connect(function(progressData)
	HUDController:UpdateProgress(progressData)
	print("[FaultlineFear Client] Progress update:", progressData)
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
	local RunService = game:GetService("RunService")

	-- Sprint state
	local isSprinting = false
	local currentStamina = Config.STAMINA.MAX

	local function setSprintState(sprinting: boolean)
		if sprinting == isSprinting then
			return
		end
		isSprinting = sprinting

		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				-- Sprint speed: 24, Normal: 16
				humanoid.WalkSpeed = sprinting and 24 or 16
			end
		end
	end

	-- Stamina update loop
	RunService.Heartbeat:Connect(function(dt)
		local character = player.Character
		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end

		-- Only drain stamina when actually moving AND sprinting
		local isMoving = humanoid.MoveDirection.Magnitude > 0.1

		if isSprinting and isMoving then
			-- Drain stamina while sprinting
			currentStamina = math.max(0, currentStamina - Config.STAMINA.SPRINT_DRAIN * dt)

			-- Stop sprinting if out of stamina
			if currentStamina <= 0 then
				setSprintState(false)
			end
		else
			-- Recover stamina when not sprinting
			currentStamina = math.min(Config.STAMINA.MAX, currentStamina + Config.STAMINA.RECOVERY_RATE * dt)
		end

		-- Update HUD (if HUDController is available)
		if HUDController and HUDController.UpdateStamina then
			HUDController:UpdateStamina(currentStamina / Config.STAMINA.MAX)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		-- Note: HUD toggle (Tab) is handled by HUDController internally

		-- Sprint (hold shift)
		if input.KeyCode == Config.KEYBINDS.SPRINT then
			if currentStamina > 0 then
				setSprintState(true)
			end
		end

		-- Eat food
		if input.KeyCode == Config.KEYBINDS.EAT then
			-- TODO: Request eat from server
			print("[FaultlineFear Client] Eat food (not implemented)")
		end

		-- Flashlight handled by FlashlightController via ContextActionService

		-- Call pet
		if input.KeyCode == Config.KEYBINDS.CALL_PET then
			-- TODO: Call pet
			print("[FaultlineFear Client] Call pet (not implemented)")
		end
	end)

	UserInputService.InputEnded:Connect(function(input, _gameProcessed)
		-- Release sprint
		if input.KeyCode == Config.KEYBINDS.SPRINT then
			setSprintState(false)
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
