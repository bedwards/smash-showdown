--!strict
--[[
	Faultline Fear: Flashlight Controller (Client)

	Handles flashlight rendering, input, and effects.
	Syncs with server for battery management.

	Features:
	- Toggle on/off with F key
	- Light cone attached to character head
	- Battery drain/warning effects
	- Flicker when low battery
	- Visual feedback for other players

	Exports: Initialize()
	Depends: InputService
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local FlashlightController = {}

-- State
local isOn: boolean = false
local battery: number = 100 -- 0-100 percentage
local flashlight: SpotLight? = nil
local attachment: Attachment? = nil
local flickerTime: number = 0

-- Constants
local FLASHLIGHT_ANGLE = 45
local FLASHLIGHT_RANGE = 60
local FLASHLIGHT_BRIGHTNESS = 2
local LOW_BATTERY_THRESHOLD = 20
local FLICKER_INTENSITY = 0.3 -- How much brightness varies when flickering
local FLICKER_SPEED = 10 -- Flicker frequency

-- Remote events
local Remotes: Folder? = nil
local FlashlightToggle: RemoteEvent? = nil
local FlashlightUpdate: RemoteEvent? = nil

-- ==========================================
-- FLASHLIGHT CREATION
-- ==========================================

local function createFlashlight(character: Model): SpotLight?
	local head = character:FindFirstChild("Head")
	if not head then
		return nil
	end

	-- Create attachment for light
	local attach = Instance.new("Attachment")
	attach.Name = "FlashlightAttachment"
	attach.Position = Vector3.new(0, 0.2, -0.5) -- Slightly in front of face
	attach.Parent = head

	-- Create spotlight
	local light = Instance.new("SpotLight")
	light.Name = "Flashlight"
	light.Angle = FLASHLIGHT_ANGLE
	light.Range = FLASHLIGHT_RANGE
	light.Brightness = FLASHLIGHT_BRIGHTNESS
	light.Face = Enum.NormalId.Front
	light.Shadows = true
	light.Enabled = false
	light.Parent = attach

	attachment = attach
	return light
end

local function destroyFlashlight()
	if attachment then
		attachment:Destroy()
		attachment = nil
	end
	flashlight = nil
end

-- ==========================================
-- FLASHLIGHT CONTROL
-- ==========================================

local function setFlashlightEnabled(enabled: boolean)
	if not flashlight then
		return
	end

	isOn = enabled
	flashlight.Enabled = enabled

	-- Notify server
	if FlashlightToggle then
		FlashlightToggle:FireServer(enabled)
	end
end

local function toggleFlashlight()
	-- Don't allow toggle if no battery
	if battery <= 0 and not isOn then
		-- Play empty click sound?
		return
	end

	setFlashlightEnabled(not isOn)
end

-- ==========================================
-- BATTERY & EFFECTS
-- ==========================================

local function updateFlashlightEffects(dt: number)
	if not flashlight or not isOn then
		return
	end

	-- Flicker effect when low battery
	if battery <= LOW_BATTERY_THRESHOLD then
		flickerTime += dt * FLICKER_SPEED

		-- Random flicker intensity
		local flicker = 1 - (math.sin(flickerTime) * 0.5 + 0.5) * FLICKER_INTENSITY
		if battery <= 5 then
			-- More intense flicker when very low
			flicker = flicker * (0.5 + math.random() * 0.5)
		end

		flashlight.Brightness = FLASHLIGHT_BRIGHTNESS * flicker
	else
		flashlight.Brightness = FLASHLIGHT_BRIGHTNESS
	end

	-- Auto turn off when battery depleted
	if battery <= 0 and isOn then
		setFlashlightEnabled(false)
	end
end

-- ==========================================
-- INPUT HANDLING
-- ==========================================

local function handleFlashlightInput(
	actionName: string,
	inputState: Enum.UserInputState,
	_inputObject: InputObject
): Enum.ContextActionResult
	if actionName ~= "ToggleFlashlight" then
		return Enum.ContextActionResult.Pass
	end

	if inputState == Enum.UserInputState.Begin then
		toggleFlashlight()
		return Enum.ContextActionResult.Sink
	end

	return Enum.ContextActionResult.Pass
end

-- ==========================================
-- CHARACTER HANDLING
-- ==========================================

local function onCharacterAdded(character: Model)
	-- Wait for head to load
	local head = character:WaitForChild("Head", 5)
	if not head then
		return
	end

	-- Create flashlight
	flashlight = createFlashlight(character)

	-- Sync with server state
	if FlashlightToggle then
		FlashlightToggle:FireServer(isOn)
	end
end

local function onCharacterRemoving(_character: Model)
	destroyFlashlight()
	isOn = false
end

-- ==========================================
-- SERVER COMMUNICATION
-- ==========================================

local function onBatteryUpdate(newBattery: number)
	battery = newBattery
end

local function onOtherPlayerFlashlightToggle(player: Player, enabled: boolean)
	-- Show/hide other player's flashlight
	local character = player.Character
	if not character then
		return
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	local attach = head:FindFirstChild("FlashlightAttachment")
	if enabled and not attach then
		-- Create visual flashlight for other player
		attach = Instance.new("Attachment")
		attach.Name = "FlashlightAttachment"
		attach.Position = Vector3.new(0, 0.2, -0.5)
		attach.Parent = head

		local light = Instance.new("SpotLight")
		light.Name = "Flashlight"
		light.Angle = FLASHLIGHT_ANGLE
		light.Range = FLASHLIGHT_RANGE * 0.8 -- Slightly less range for others
		light.Brightness = FLASHLIGHT_BRIGHTNESS * 0.8
		light.Face = Enum.NormalId.Front
		light.Shadows = false -- No shadows for performance
		light.Enabled = true
		light.Parent = attach
	elseif not enabled and attach then
		attach:Destroy()
	elseif attach then
		local light = attach:FindFirstChild("Flashlight")
		if light and light:IsA("SpotLight") then
			light.Enabled = enabled
		end
	end
end

-- ==========================================
-- PUBLIC API
-- ==========================================

function FlashlightController:IsOn(): boolean
	return isOn
end

function FlashlightController:GetBattery(): number
	return battery
end

function FlashlightController:SetBattery(value: number)
	battery = math.clamp(value, 0, 100)
end

function FlashlightController:Initialize()
	-- Wait for remotes
	Remotes = ReplicatedStorage:WaitForChild("Remotes", 10) :: Folder?
	if Remotes then
		FlashlightToggle = Remotes:FindFirstChild("FlashlightToggle") :: RemoteEvent?
		FlashlightUpdate = Remotes:FindFirstChild("FlashlightUpdate") :: RemoteEvent?

		if FlashlightUpdate then
			FlashlightUpdate.OnClientEvent:Connect(function(updateType: string, data: any)
				if updateType == "battery" then
					onBatteryUpdate(data)
				elseif updateType == "playerToggle" then
					onOtherPlayerFlashlightToggle(data.player, data.enabled)
				end
			end)
		end
	end

	-- Bind input
	ContextActionService:BindAction("ToggleFlashlight", handleFlashlightInput, false, Enum.KeyCode.F)

	-- Handle character
	if Player.Character then
		task.spawn(onCharacterAdded, Player.Character)
	end
	Player.CharacterAdded:Connect(onCharacterAdded)
	Player.CharacterRemoving:Connect(onCharacterRemoving)

	-- Update loop for effects
	RunService.RenderStepped:Connect(updateFlashlightEffects)

	print("[FlashlightController] Initialized")
end

return FlashlightController
