--!strict
-- AI Bot opponent for Smash Showdown
-- Computer-controlled enemy that chases players and attacks

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

-- Bot configuration
local BOT_CONFIG = {
	HEALTH = 100,
	WALK_SPEED = 18,
	ATTACK_RANGE = 6,
	ATTACK_COOLDOWN = 1.0,
	CHASE_RANGE = 50,
	BALL_HIT_RANGE = 8,
	REACTION_TIME = 0.3,
	DAMAGE = 8,
}

-- Bot state
local bots: { Model } = {}
local botStates: { [Model]: {
	target: Player?,
	lastAttack: number,
	isAttacking: boolean,
} } = {}

-- Get remotes
local CombatUpdateRemote = ReplicatedStorage:WaitForChild("CombatUpdate") :: RemoteEvent
local BallUpdateRemote = ReplicatedStorage:WaitForChild("BallUpdate") :: RemoteEvent

-- Create a bot character
local function createBot(name: string, position: Vector3): Model
	-- Create humanoid rig
	local bot = Instance.new("Model")
	bot.Name = name

	-- HumanoidRootPart
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Position = position
	rootPart.Anchored = false
	rootPart.CanCollide = false
	rootPart.Transparency = 1
	rootPart.Parent = bot

	-- Torso
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Position = position
	torso.Color = Color3.fromRGB(200, 50, 50)
	torso.Material = Enum.Material.SmoothPlastic
	torso.Parent = bot

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.5, 1.5, 1.5)
	head.Position = position + Vector3.new(0, 1.75, 0)
	head.Color = Color3.fromRGB(255, 200, 150)
	head.Material = Enum.Material.SmoothPlastic
	head.Parent = bot

	-- Face
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = "rbxassetid://31117192" -- Angry face
	face.Parent = head

	-- Arms
	local leftArm = Instance.new("Part")
	leftArm.Name = "Left Arm"
	leftArm.Size = Vector3.new(1, 2, 1)
	leftArm.Position = position + Vector3.new(-1.5, 0, 0)
	leftArm.Color = Color3.fromRGB(255, 200, 150)
	leftArm.Material = Enum.Material.SmoothPlastic
	leftArm.Parent = bot

	local rightArm = Instance.new("Part")
	rightArm.Name = "Right Arm"
	rightArm.Size = Vector3.new(1, 2, 1)
	rightArm.Position = position + Vector3.new(1.5, 0, 0)
	rightArm.Color = Color3.fromRGB(255, 200, 150)
	rightArm.Material = Enum.Material.SmoothPlastic
	rightArm.Parent = bot

	-- Legs
	local leftLeg = Instance.new("Part")
	leftLeg.Name = "Left Leg"
	leftLeg.Size = Vector3.new(1, 2, 1)
	leftLeg.Position = position + Vector3.new(-0.5, -2, 0)
	leftLeg.Color = Color3.fromRGB(50, 50, 150)
	leftLeg.Material = Enum.Material.SmoothPlastic
	leftLeg.Parent = bot

	local rightLeg = Instance.new("Part")
	rightLeg.Name = "Right Leg"
	rightLeg.Size = Vector3.new(1, 2, 1)
	rightLeg.Position = position + Vector3.new(0.5, -2, 0)
	rightLeg.Color = Color3.fromRGB(50, 50, 150)
	rightLeg.Material = Enum.Material.SmoothPlastic
	rightLeg.Parent = bot

	-- Humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = BOT_CONFIG.HEALTH
	humanoid.Health = BOT_CONFIG.HEALTH
	humanoid.WalkSpeed = BOT_CONFIG.WALK_SPEED
	humanoid.Parent = bot

	-- Weld parts together
	local function weld(part0: BasePart, part1: BasePart, offset: CFrame)
		local weldConstraint = Instance.new("Motor6D")
		weldConstraint.Part0 = part0
		weldConstraint.Part1 = part1
		weldConstraint.C0 = offset
		weldConstraint.Parent = part0
	end

	weld(rootPart, torso, CFrame.new())
	weld(torso, head, CFrame.new(0, 1.5, 0))
	weld(torso, leftArm, CFrame.new(-1.5, 0, 0))
	weld(torso, rightArm, CFrame.new(1.5, 0, 0))
	weld(torso, leftLeg, CFrame.new(-0.5, -2, 0))
	weld(torso, rightLeg, CFrame.new(0.5, -2, 0))

	bot.PrimaryPart = rootPart
	bot.Parent = workspace

	-- Overhead health bar
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.new(0, 80, 0, 20)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Adornee = head
	billboard.Parent = bot

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 8)
	container.Position = UDim2.new(0, 0, 1, -8)
	container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	container.BorderSizePixel = 0
	container.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = container

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, -2, 1, -2)
	fill.Position = UDim2.new(0, 1, 0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	fill.BorderSizePixel = 0
	fill.Parent = container

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 2)
	fillCorner.Parent = fill

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 12)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "🤖 " .. name
	nameLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 11
	nameLabel.Parent = billboard

	-- Update health bar on damage
	humanoid.HealthChanged:Connect(function(health)
		local percent = health / humanoid.MaxHealth
		fill.Size = UDim2.new(percent, -2, 1, -2)
	end)

	-- Handle death
	humanoid.Died:Connect(function()
		print("[Bot]", name, "was destroyed!")
		task.delay(3, function()
			bot:Destroy()
			-- Respawn
			task.delay(2, function()
				spawnBot()
			end)
		end)
	end)

	return bot
end

-- Find closest player
local function findClosestPlayer(botPosition: Vector3): Player?
	local closestPlayer: Player? = nil
	local closestDistance = BOT_CONFIG.CHASE_RANGE

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then continue end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then continue end

		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not rootPart then continue end

		local distance = (rootPart.Position - botPosition).Magnitude
		if distance < closestDistance then
			closestDistance = distance
			closestPlayer = player
		end
	end

	return closestPlayer
end

-- Bot attack
local function botAttack(bot: Model, target: Model)
	local state = botStates[bot]
	if not state then return end

	local now = tick()
	if now - state.lastAttack < BOT_CONFIG.ATTACK_COOLDOWN then return end
	if state.isAttacking then return end

	state.lastAttack = now
	state.isAttacking = true

	-- Find target humanoid
	local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?

	if targetHumanoid and targetRoot and targetHumanoid.Health > 0 then
		-- Deal damage
		targetHumanoid:TakeDamage(BOT_CONFIG.DAMAGE)

		-- Knockback
		local botRoot = bot:FindFirstChild("HumanoidRootPart") :: BasePart?
		if botRoot then
			local knockbackDir = (targetRoot.Position - botRoot.Position).Unit
			local knockback = Instance.new("BodyVelocity")
			knockback.MaxForce = Vector3.new(30000, 30000, 30000)
			knockback.Velocity = knockbackDir * 25 + Vector3.new(0, 10, 0)
			knockback.Parent = targetRoot
			task.delay(0.15, function()
				knockback:Destroy()
			end)

			-- Notify clients
			CombatUpdateRemote:FireAllClients("hit", {
				attacker = bot.Name,
				target = "Player",
				damage = BOT_CONFIG.DAMAGE,
				combo = 1,
				position = targetRoot.Position,
				isFinalHit = false,
			})
		end

		print("[Bot]", bot.Name, "attacked for", BOT_CONFIG.DAMAGE, "damage!")
	end

	task.delay(0.3, function()
		if botStates[bot] then
			botStates[bot].isAttacking = false
		end
	end)
end

-- Hit the ball
local function tryHitBall(bot: Model)
	local ball = workspace:FindFirstChild("SmashBall") :: BasePart?
	if not ball then return end

	local botRoot = bot:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not botRoot then return end

	local distance = (ball.Position - botRoot.Position).Magnitude
	if distance > BOT_CONFIG.BALL_HIT_RANGE then return end

	-- Find a player to aim at
	local target = findClosestPlayer(botRoot.Position)
	local aimDir: Vector3

	if target and target.Character then
		local targetRoot = target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if targetRoot then
			aimDir = (targetRoot.Position - ball.Position).Unit
			aimDir = Vector3.new(aimDir.X, math.max(aimDir.Y, 0.2), aimDir.Z).Unit
		else
			aimDir = (botRoot.CFrame.LookVector + Vector3.new(0, 0.3, 0)).Unit
		end
	else
		aimDir = (botRoot.CFrame.LookVector + Vector3.new(0, 0.3, 0)).Unit
	end

	-- Hit the ball
	ball.AssemblyLinearVelocity = aimDir * 80

	-- Update ball color to red (bot team)
	ball.Color = Color3.fromRGB(255, 80, 80)
	local trail = ball:FindFirstChildOfClass("Trail")
	if trail then
		trail.Color = ColorSequence.new(Color3.fromRGB(255, 80, 80))
	end

	BallUpdateRemote:FireAllClients("hit", "red", ball.Position, ball.AssemblyLinearVelocity)

	print("[Bot] Hit the ball!")
end

-- Bot AI update
local function updateBot(bot: Model)
	local humanoid = bot:FindFirstChildOfClass("Humanoid")
	local rootPart = bot:FindFirstChild("HumanoidRootPart") :: BasePart?

	if not humanoid or not rootPart then return end
	if humanoid.Health <= 0 then return end

	local state = botStates[bot]
	if not state then return end

	-- Find target
	local target = findClosestPlayer(rootPart.Position)
	state.target = target

	-- Try to hit ball if nearby
	tryHitBall(bot)

	if target then
		local targetChar = target.Character
		if not targetChar then return end

		local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not targetRoot then return end

		local distance = (targetRoot.Position - rootPart.Position).Magnitude

		if distance <= BOT_CONFIG.ATTACK_RANGE then
			-- Attack!
			botAttack(bot, targetChar)
		else
			-- Chase
			humanoid:MoveTo(targetRoot.Position)
		end
	else
		-- Wander towards ball or center
		local ball = workspace:FindFirstChild("SmashBall") :: BasePart?
		if ball then
			humanoid:MoveTo(ball.Position)
		else
			humanoid:MoveTo(Vector3.new(0, 3, 0))
		end
	end
end

-- Spawn a bot
function spawnBot()
	local botNumber = #bots + 1
	local spawnPos = Vector3.new(20, 5, 0) -- Spawn on blue side

	local bot = createBot("Bot_" .. botNumber, spawnPos)
	table.insert(bots, bot)

	botStates[bot] = {
		target = nil,
		lastAttack = 0,
		isAttacking = false,
	}

	print("[Bot] Spawned", bot.Name)
end

-- Game loop
RunService.Heartbeat:Connect(function()
	for _, bot in bots do
		if bot and bot.Parent then
			updateBot(bot)
		end
	end
end)

-- Spawn initial bot when a player joins
Players.PlayerAdded:Connect(function(player)
	task.delay(2, function()
		if #bots == 0 then
			spawnBot()
		end
	end)
end)

-- Spawn bot if players already exist
if #Players:GetPlayers() > 0 then
	task.delay(2, function()
		if #bots == 0 then
			spawnBot()
		end
	end)
end

print("[Bot] System initialized!")
