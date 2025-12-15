--!strict
-- Ball client - handles hit input and effects
-- Sends hit requests to server, receives updates for VFX

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Wait for remotes
local BallHitRemote = ReplicatedStorage:WaitForChild("BallHit") :: RemoteEvent
local BallUpdateRemote = ReplicatedStorage:WaitForChild("BallUpdate") :: RemoteEvent

-- State
local isCharging = false
local chargeStart = 0
local MAX_CHARGE_TIME = 1.0

-- Find the ball
local function getBall(): Part?
	return workspace:FindFirstChild("SmashBall") :: Part?
end

-- Get aim direction (towards mouse)
local function getAimDirection(): Vector3
	local character = LocalPlayer.Character
	if not character then return Vector3.new(0, 0, 1) end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return Vector3.new(0, 0, 1) end

	local mouse = LocalPlayer:GetMouse()
	local mousePos = Vector3.new(mouse.Hit.Position.X, mouse.Hit.Position.Y, mouse.Hit.Position.Z)

	local direction = (mousePos - rootPart.Position).Unit
	-- Add upward angle for arc
	direction = Vector3.new(direction.X, math.max(direction.Y, 0.3), direction.Z).Unit

	return direction
end

-- Check if player is near ball
local function isNearBall(): boolean
	local ball = getBall()
	if not ball then return false end

	local character = LocalPlayer.Character
	if not character then return false end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return false end

	return (rootPart.Position - ball.Position).Magnitude < 8
end

-- Visual effect: hit flash
local function playHitEffect(position: Vector3, color: Color3)
	local effect = Instance.new("Part")
	effect.Shape = Enum.PartType.Ball
	effect.Size = Vector3.new(3, 3, 3)
	effect.Position = position
	effect.Color = color
	effect.Material = Enum.Material.Neon
	effect.Anchored = true
	effect.CanCollide = false
	effect.Transparency = 0.3
	effect.Parent = workspace

	local tween = TweenService:Create(effect, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(8, 8, 8),
		Transparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		effect:Destroy()
	end)
end

-- Visual effect: damage number
local function showDamageNumber(position: Vector3, damage: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = nil

	local part = Instance.new("Part")
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = position
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
	label.TextColor3 = Color3.fromRGB(255, 100, 100)
	label.TextStrokeTransparency = 0.5
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = billboard

	-- Animate up and fade
	local startPos = position
	local endPos = position + Vector3.new(0, 5, 0)

	task.spawn(function()
		for i = 1, 30 do
			local t = i / 30
			part.Position = startPos:Lerp(endPos, t)
			label.TextTransparency = t
			label.TextStrokeTransparency = 0.5 + (t * 0.5)
			task.wait(1/60)
		end
		part:Destroy()
	end)
end

-- Screen shake
local function screenShake(intensity: number)
	local camera = workspace.CurrentCamera
	if not camera then return end

	local originalCFrame = camera.CFrame

	task.spawn(function()
		for i = 1, 5 do
			local offset = Vector3.new(
				(math.random() - 0.5) * intensity,
				(math.random() - 0.5) * intensity,
				0
			)
			camera.CFrame = originalCFrame * CFrame.new(offset)
			task.wait(0.02)
		end
		camera.CFrame = originalCFrame
	end)
end

-- Input handling for ball hits
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- E key to hit ball
	if input.KeyCode == Enum.KeyCode.E then
		if isNearBall() then
			isCharging = true
			chargeStart = tick()
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	-- Release E to swing
	if input.KeyCode == Enum.KeyCode.E and isCharging then
		isCharging = false

		local chargeTime = math.min(tick() - chargeStart, MAX_CHARGE_TIME)
		local power = 0.5 + (chargeTime / MAX_CHARGE_TIME) * 1.5 -- 0.5 to 2.0

		local direction = getAimDirection()
		BallHitRemote:FireServer(direction, power)
	end
end)

-- Handle ball updates from server
BallUpdateRemote.OnClientEvent:Connect(function(eventType: string, ...)
	if eventType == "hit" then
		local team: string, position: Vector3, velocity: Vector3 = ...
		local color = team == "red" and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 150, 255)
		playHitEffect(position, color)

	elseif eventType == "playerHit" then
		local playerName: string, damage: number, position: Vector3 = ...
		showDamageNumber(position, damage)

		-- Screen shake if it's us
		if playerName == LocalPlayer.Name then
			screenShake(damage / 10)
		else
			screenShake(damage / 20)
		end
	end
end)

print("[BallClient] Ready! Press E near ball to hit it.")
