--!strict
-- Player controller for Mertin-Flemmer
-- Sprint, flashlight, and survival mechanics

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config

-- State
local isSprinting = false
local stamina = Config.MAX_STAMINA
local flashlightOn = false
local flashlight: SpotLight? = nil

-- Get character components
local function getCharacter()
	return LocalPlayer.Character
end

local function getHumanoid()
	local char = getCharacter()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getHead()
	local char = getCharacter()
	return char and char:FindFirstChild("Head") :: BasePart?
end

-- Create flashlight
local function createFlashlight()
	local head = getHead()
	if not head then return end

	if flashlight then
		flashlight:Destroy()
	end

	flashlight = Instance.new("SpotLight")
	flashlight.Brightness = 3
	flashlight.Range = 60
	flashlight.Angle = 45
	flashlight.Color = Color3.fromRGB(255, 250, 230)
	flashlight.Enabled = flashlightOn
	flashlight.Face = Enum.NormalId.Front
	flashlight.Parent = head
end

-- Toggle flashlight
local function toggleFlashlight()
	flashlightOn = not flashlightOn

	if flashlight then
		flashlight.Enabled = flashlightOn
	end

	print("[Controller] Flashlight:", flashlightOn and "ON" or "OFF")
end

-- Update sprint
local function updateSprint(dt: number)
	local humanoid = getHumanoid()
	if not humanoid then return end

	if isSprinting and stamina > 0 then
		humanoid.WalkSpeed = Config.SPRINT_SPEED
		stamina = math.max(0, stamina - Config.STAMINA_DRAIN * dt)
	else
		humanoid.WalkSpeed = Config.WALK_SPEED
		if not isSprinting then
			stamina = math.min(Config.MAX_STAMINA, stamina + Config.STAMINA_REGEN * dt)
		end
	end

	-- Stop sprinting if out of stamina
	if stamina <= 0 then
		isSprinting = false
	end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = true
	elseif input.KeyCode == Enum.KeyCode.F then
		toggleFlashlight()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = false
	end
end)

-- Game loop
RunService.Heartbeat:Connect(function(dt)
	updateSprint(dt)
end)

-- Character setup
local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.WalkSpeed = Config.WALK_SPEED

	-- Reset state
	stamina = Config.MAX_STAMINA
	isSprinting = false
	flashlightOn = false

	-- Create flashlight after head loads
	task.delay(0.5, createFlashlight)
end

if LocalPlayer.Character then
	onCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

print("[Controller] Controls: WASD=Move, Shift=Sprint, F=Flashlight")
