--!strict
-- Player controller for Smash Showdown
-- Handles movement, dashing, and combat input

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Combat = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Combat"))

-- State
local canDash = true
local isDashing = false
local isAttacking = false
local comboCount = 0
local lastAttackTime = 0

-- Get character and humanoid
local function getCharacter()
	return LocalPlayer.Character
end

local function getHumanoid()
	local char = getCharacter()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
	local char = getCharacter()
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Dash function
local function dash()
	if not canDash or isDashing then return end

	local humanoid = getHumanoid()
	local rootPart = getRootPart()
	if not humanoid or not rootPart then return end

	canDash = false
	isDashing = true

	-- Get movement direction or facing direction
	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude < 0.1 then
		moveDir = rootPart.CFrame.LookVector
	end

	-- Apply dash velocity
	local dashVelocity = Instance.new("BodyVelocity")
	dashVelocity.MaxForce = Vector3.new(1, 0, 1) * 50000
	dashVelocity.Velocity = moveDir * Combat.Stats.DASH_SPEED
	dashVelocity.Parent = rootPart

	-- Dash duration
	task.delay(Combat.Stats.DASH_DURATION, function()
		dashVelocity:Destroy()
		isDashing = false
	end)

	-- Dash cooldown
	task.delay(Combat.Stats.DASH_COOLDOWN, function()
		canDash = true
	end)

	print("[Controller] Dash!")
end

-- Light attack
local function lightAttack()
	if isAttacking then return end

	local now = tick()
	if now - lastAttackTime < Combat.Stats.COMBO_WINDOW then
		comboCount = math.min(comboCount + 1, Combat.Stats.MAX_COMBO)
	else
		comboCount = 1
	end
	lastAttackTime = now

	isAttacking = true
	print("[Controller] Light attack! Combo:", comboCount)

	-- Attack animation timing
	task.delay(Combat.Stats.LIGHT_WINDUP + Combat.Stats.LIGHT_ACTIVE + Combat.Stats.LIGHT_RECOVERY, function()
		isAttacking = false
	end)
end

-- Heavy attack (hold)
local function heavyAttack()
	if isAttacking then return end

	isAttacking = true
	comboCount = 0
	print("[Controller] Heavy attack!")

	task.delay(Combat.Stats.HEAVY_WINDUP + Combat.Stats.HEAVY_ACTIVE + Combat.Stats.HEAVY_RECOVERY, function()
		isAttacking = false
	end)
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Q = Dash
	if input.KeyCode == Enum.KeyCode.Q then
		dash()
	end

	-- Left click = Light attack
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		lightAttack()
	end

	-- Right click = Heavy attack
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		heavyAttack()
	end
end)

-- Character setup
local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.WalkSpeed = Combat.Stats.WALK_SPEED
	humanoid.JumpPower = Combat.Stats.JUMP_POWER

	print("[Controller] Character ready!")
end

if LocalPlayer.Character then
	onCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

print("[Controller] Controls: WASD=Move, Space=Jump, Q=Dash, LMB=Attack, RMB=Heavy")
