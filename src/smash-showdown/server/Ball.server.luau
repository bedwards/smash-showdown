--!strict
-- Ball system for Smash Showdown
-- Server-authoritative ball physics and hit detection

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

-- Ball configuration
local BALL_CONFIG = {
	SIZE = 2,
	BASE_SPEED = 80,
	MAX_SPEED = 150,
	GRAVITY_SCALE = 0.5,
	BOUNCE_DAMPING = 0.8,
	HIT_DAMAGE = 15,
	HIT_COOLDOWN = 0.5,
}

-- State
local ball: Part? = nil
local lastHitPlayer: Player? = nil
local lastHitTeam: string = "neutral"
local lastHitTime: number = 0

-- Team colors
local TEAM_COLORS = {
	neutral = Color3.fromRGB(255, 255, 255),
	red = Color3.fromRGB(255, 80, 80),
	blue = Color3.fromRGB(80, 150, 255),
}

-- Create RemoteEvents
local function setupRemotes()
	local ballHitRemote = Instance.new("RemoteEvent")
	ballHitRemote.Name = "BallHit"
	ballHitRemote.Parent = ReplicatedStorage

	local ballUpdateRemote = Instance.new("RemoteEvent")
	ballUpdateRemote.Name = "BallUpdate"
	ballUpdateRemote.Parent = ReplicatedStorage

	return ballHitRemote, ballUpdateRemote
end

local BallHitRemote, BallUpdateRemote = setupRemotes()

-- Create the ball
local function createBall(): Part
	local newBall = Instance.new("Part")
	newBall.Name = "SmashBall"
	newBall.Shape = Enum.PartType.Ball
	newBall.Size = Vector3.new(BALL_CONFIG.SIZE, BALL_CONFIG.SIZE, BALL_CONFIG.SIZE)
	newBall.Position = Vector3.new(0, 10, 0)
	newBall.Color = TEAM_COLORS.neutral
	newBall.Material = Enum.Material.Neon
	newBall.Anchored = false
	newBall.CanCollide = true

	-- Physics properties
	local physProps = PhysicalProperties.new(
		0.5, -- Density (lighter)
		0.3, -- Friction
		0.9, -- Elasticity (bouncy)
		1, -- FrictionWeight
		1 -- ElasticityWeight
	)
	newBall.CustomPhysicalProperties = physProps

	-- Trail effect
	local attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, 0, 0)
	attachment0.Parent = newBall

	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment0
	trail.Lifetime = 0.3
	trail.MinLength = 0.1
	trail.FaceCamera = true
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Color = ColorSequence.new(TEAM_COLORS.neutral)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Parent = newBall

	-- Highlight effect
	local highlight = Instance.new("Highlight")
	highlight.FillColor = TEAM_COLORS.neutral
	highlight.FillTransparency = 0.5
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.OutlineTransparency = 0
	highlight.Parent = newBall

	newBall.Parent = workspace

	print("[Ball] Created at", newBall.Position)
	return newBall
end

-- Update ball color based on team
local function updateBallColor(team: string)
	if not ball then return end

	local color = TEAM_COLORS[team] or TEAM_COLORS.neutral
	ball.Color = color

	local trail = ball:FindFirstChildOfClass("Trail")
	if trail then
		trail.Color = ColorSequence.new(color)
	end

	local highlight = ball:FindFirstChildOfClass("Highlight")
	if highlight then
		highlight.FillColor = color
	end
end

-- Hit the ball
local function hitBall(player: Player, direction: Vector3, power: number)
	if not ball then return end

	local now = tick()
	if now - lastHitTime < BALL_CONFIG.HIT_COOLDOWN then return end

	lastHitTime = now
	lastHitPlayer = player
	-- Assign team based on spawn position (temporary - will use actual teams later)
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if rootPart then
			lastHitTeam = rootPart.Position.X < 0 and "red" or "blue"
		end
	end

	-- Apply velocity
	local speed = math.clamp(BALL_CONFIG.BASE_SPEED * power, BALL_CONFIG.BASE_SPEED, BALL_CONFIG.MAX_SPEED)
	local velocity = direction.Unit * speed

	-- Clear existing velocity
	ball.AssemblyLinearVelocity = velocity

	-- Update color
	updateBallColor(lastHitTeam)

	-- Broadcast hit
	BallUpdateRemote:FireAllClients("hit", lastHitTeam, ball.Position, velocity)

	print("[Ball] Hit by", player.Name, "team:", lastHitTeam, "speed:", speed)
end

-- Check if ball hits a player
local function checkPlayerCollision()
	if not ball then return end

	local ballPos = ball.Position
	local ballVelocity = ball.AssemblyLinearVelocity

	-- Only damage if ball is moving fast enough
	if ballVelocity.Magnitude < 20 then return end

	for _, player in Players:GetPlayers() do
		if player == lastHitPlayer then continue end

		local character = player.Character
		if not character then continue end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?

		if not humanoid or not rootPart then continue end
		if humanoid.Health <= 0 then continue end

		-- Check distance
		local distance = (rootPart.Position - ballPos).Magnitude
		if distance < 4 then
			-- HIT!
			local damage = BALL_CONFIG.HIT_DAMAGE * (ballVelocity.Magnitude / BALL_CONFIG.BASE_SPEED)
			damage = math.clamp(damage, 5, 30)

			humanoid:TakeDamage(damage)

			-- Knockback
			local knockbackDir = (rootPart.Position - ballPos).Unit
			local knockback = Instance.new("BodyVelocity")
			knockback.MaxForce = Vector3.new(50000, 50000, 50000)
			knockback.Velocity = knockbackDir * 40 + Vector3.new(0, 20, 0)
			knockback.Parent = rootPart

			task.delay(0.2, function()
				knockback:Destroy()
			end)

			-- Reset ball
			ball.AssemblyLinearVelocity = Vector3.zero
			lastHitPlayer = nil

			-- Broadcast hit
			BallUpdateRemote:FireAllClients("playerHit", player.Name, damage, rootPart.Position)

			print("[Ball] Hit", player.Name, "for", math.floor(damage), "damage!")
			break
		end
	end
end

-- Handle hit requests from clients
BallHitRemote.OnServerEvent:Connect(function(player: Player, direction: Vector3, power: number)
	if typeof(direction) ~= "Vector3" then return end
	if typeof(power) ~= "number" then return end

	-- Validate player is near ball
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart or not ball then return end

	local distance = (rootPart.Position - ball.Position).Magnitude
	if distance > 8 then return end -- Too far to hit

	power = math.clamp(power, 0.5, 2)
	hitBall(player, direction, power)
end)

-- Reset ball to center
local function resetBall()
	if ball then
		ball:Destroy()
	end

	ball = createBall()
	lastHitPlayer = nil
	lastHitTeam = "neutral"
	updateBallColor("neutral")
end

-- Game loop
RunService.Heartbeat:Connect(function()
	if ball then
		checkPlayerCollision()

		-- Reset if ball falls too far
		if ball.Position.Y < -50 then
			resetBall()
		end
	end
end)

-- Initialize
resetBall()
print("[Ball] System initialized!")
