--!strict
-- Player controller for Smash Showdown
-- Handles movement, dashing, combat input, and visual feedback

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Combat = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Combat"))

-- Wait for remotes
local AttackRemote = ReplicatedStorage:WaitForChild("Attack") :: RemoteEvent
local CombatUpdateRemote = ReplicatedStorage:WaitForChild("CombatUpdate") :: RemoteEvent

-- State
local canDash = true
local isDashing = false
local isAttacking = false
local isBlocking = false
local isStunned = false
local comboCount = 0
local lastAttackTime = 0

-- Get character components
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

-- Visual effects
local function screenShake(intensity: number)
	local camera = workspace.CurrentCamera
	if not camera then return end

	task.spawn(function()
		local originalCFrame = camera.CFrame
		for i = 1, math.floor(intensity * 3) do
			local offset = Vector3.new(
				(math.random() - 0.5) * intensity,
				(math.random() - 0.5) * intensity,
				0
			)
			camera.CFrame = originalCFrame * CFrame.new(offset)
			task.wait(0.016)
		end
		camera.CFrame = originalCFrame
	end)
end

local function hitFreeze(duration: number)
	-- Brief pause for impact feel
	local humanoid = getHumanoid()
	if humanoid then
		local originalSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = 0
		task.delay(duration, function()
			if humanoid and humanoid.WalkSpeed == 0 then
				humanoid.WalkSpeed = originalSpeed
			end
		end)
	end
end

local function showHitEffect(position: Vector3, isFinal: boolean)
	local size = isFinal and 5 or 3
	local color = isFinal and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(255, 255, 255)

	local effect = Instance.new("Part")
	effect.Shape = Enum.PartType.Ball
	effect.Size = Vector3.new(size, size, size)
	effect.Position = position
	effect.Color = color
	effect.Material = Enum.Material.Neon
	effect.Anchored = true
	effect.CanCollide = false
	effect.Transparency = 0.3
	effect.Parent = workspace

	local tween = TweenService:Create(effect, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(size * 2, size * 2, size * 2),
		Transparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		effect:Destroy()
	end)
end

local function showDamageNumber(position: Vector3, damage: number, isComboFinisher: boolean)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 50)
	billboard.AlwaysOnTop = true

	local part = Instance.new("Part")
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = position + Vector3.new(math.random(-2, 2), 2, math.random(-2, 2))
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace

	billboard.Adornee = part
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = tostring(math.floor(damage))
	label.TextColor3 = isComboFinisher and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(255, 100, 100)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = billboard

	-- Animate
	task.spawn(function()
		local startPos = part.Position
		local endPos = startPos + Vector3.new(0, 4, 0)
		for i = 1, 30 do
			local t = i / 30
			part.Position = startPos:Lerp(endPos, t)
			label.TextTransparency = t * 0.8
			label.TextStrokeTransparency = t
			task.wait(1/60)
		end
		part:Destroy()
	end)
end

-- Dash function
local function dash()
	if not canDash or isDashing or isStunned or isBlocking then return end

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

	-- Visual trail
	local trail = Instance.new("Part")
	trail.Size = Vector3.new(2, 4, 0.5)
	trail.CFrame = rootPart.CFrame
	trail.Color = Color3.fromRGB(150, 200, 255)
	trail.Material = Enum.Material.Neon
	trail.Anchored = true
	trail.CanCollide = false
	trail.Transparency = 0.5
	trail.Parent = workspace

	TweenService:Create(trail, TweenInfo.new(0.3), { Transparency = 1 }):Play()
	task.delay(0.3, function() trail:Destroy() end)

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
end

-- Light attack
local function lightAttack()
	if isAttacking or isStunned or isBlocking then return end

	local now = tick()
	if now - lastAttackTime < Combat.Stats.COMBO_WINDOW then
		comboCount = math.min(comboCount + 1, Combat.Stats.MAX_COMBO)
	else
		comboCount = 1
	end
	lastAttackTime = now

	isAttacking = true

	-- Send to server
	AttackRemote:FireServer("light")

	-- Attack animation timing
	task.delay(Combat.Stats.LIGHT_WINDUP + Combat.Stats.LIGHT_ACTIVE + Combat.Stats.LIGHT_RECOVERY, function()
		isAttacking = false
	end)
end

-- Heavy attack
local function heavyAttack()
	if isAttacking or isStunned or isBlocking then return end

	isAttacking = true
	comboCount = 0

	-- Send to server
	AttackRemote:FireServer("heavy")

	task.delay(Combat.Stats.HEAVY_WINDUP + Combat.Stats.HEAVY_ACTIVE + Combat.Stats.HEAVY_RECOVERY, function()
		isAttacking = false
	end)
end

-- Block
local function startBlock()
	if isAttacking or isStunned then return end
	isBlocking = true

	local humanoid = getHumanoid()
	if humanoid then
		humanoid.WalkSpeed = 0
	end
end

local function endBlock()
	isBlocking = false

	local humanoid = getHumanoid()
	if humanoid then
		humanoid.WalkSpeed = Combat.Stats.WALK_SPEED
	end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Q then
		dash()
	elseif input.KeyCode == Enum.KeyCode.F then
		startBlock()
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		lightAttack()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		heavyAttack()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.F then
		endBlock()
	end
end)

-- Handle combat updates from server
CombatUpdateRemote.OnClientEvent:Connect(function(eventType: string, data: any)
	if eventType == "hit" then
		local hitData = data :: { attacker: string, target: string, damage: number, combo: number, position: Vector3, isFinalHit: boolean }

		showHitEffect(hitData.position, hitData.isFinalHit)
		showDamageNumber(hitData.position, hitData.damage, hitData.isFinalHit)

		-- Screen shake for everyone
		local shakeIntensity = hitData.isFinalHit and 1.5 or 0.5
		if hitData.target == LocalPlayer.Name then
			shakeIntensity = shakeIntensity * 2
		end
		screenShake(shakeIntensity)

		-- Hit freeze on final hit
		if hitData.isFinalHit then
			hitFreeze(0.05)
		end

	elseif eventType == "stunned" then
		local duration = data :: number
		isStunned = true
		task.delay(duration, function()
			isStunned = false
		end)

	elseif eventType == "swing" then
		-- Local swing feedback (animation trigger point)
		local swingData = data :: { combo: number, hitAnyone: boolean, attackType: string }
		-- Could trigger animations here
	end
end)

-- Character setup
local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.WalkSpeed = Combat.Stats.WALK_SPEED
	humanoid.JumpPower = Combat.Stats.JUMP_POWER

	-- Reset state
	canDash = true
	isDashing = false
	isAttacking = false
	isBlocking = false
	isStunned = false
	comboCount = 0
end

if LocalPlayer.Character then
	onCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

print("[Controller] Controls: WASD=Move, Space=Jump, Q=Dash, F=Block, LMB=Attack, RMB=Heavy, E=Hit Ball")
