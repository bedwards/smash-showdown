--!strict
-- Hostile creatures for Mertin-Flemmer
-- Inspired by 99 Nights in the Forest and 3008
-- Multiple creature types with unique behaviors

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config

-- Wait for TimeUpdate remote
local TimeUpdateRemote = ReplicatedStorage:WaitForChild("TimeUpdate") :: RemoteEvent

-- Create creature alert remote
local CreatureAlertRemote = Instance.new("RemoteEvent")
CreatureAlertRemote.Name = "CreatureAlert"
CreatureAlertRemote.Parent = ReplicatedStorage

-- ==========================================
-- CREATURE TYPE DEFINITIONS
-- ==========================================

type CreatureType = {
	name: string,
	health: number,
	damage: number,
	speedDay: number,
	speedNight: number,
	attackRange: number,
	attackCooldown: number,
	invulnerable: boolean,
	fleeFromLight: boolean,
	fleeFromFlashlight: boolean,
	packAnimal: boolean,
	canFly: boolean,
	fearFactor: number,
	biomes: { string },
	spawnWeight: number,
	nightOnly: boolean,
	bloodNightOnly: boolean,
	buildCreature: (id: number) -> Model,
}

local CREATURE_TYPES: { [string]: CreatureType } = {}

-- ==========================================
-- THE DEER MONSTER (THE STALKER)
-- ==========================================
-- The iconic 99 Nights horror creature
-- Tall, antlered, invulnerable. Retreats from flashlight.
CREATURE_TYPES.DEER_MONSTER = {
	name = "The Stalker",
	health = 9999,
	damage = 50,
	speedDay = 0, -- Doesn't appear during day
	speedNight = 18,
	attackRange = 6,
	attackCooldown = 3,
	invulnerable = true,
	fleeFromLight = true,
	fleeFromFlashlight = true, -- Key mechanic!
	packAnimal = false,
	canFly = false,
	fearFactor = 50, -- Terrifying
	biomes = { "FOREST", "SWAMP" },
	spawnWeight = 5,
	nightOnly = true,
	bloodNightOnly = false,
	buildCreature = function(id: number): Model
		local creature = Instance.new("Model")
		creature.Name = "DeerMonster_" .. id

		-- Tall, skeletal body
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Size = Vector3.new(2, 10, 1.5)
		body.Color = Color3.fromRGB(25, 20, 15)
		body.Material = Enum.Material.SmoothPlastic
		body.Anchored = false
		body.CanCollide = true
		body.Parent = creature

		-- Deer skull head
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(2, 3, 4)
		head.Color = Color3.fromRGB(220, 210, 190)
		head.Material = Enum.Material.Bone
		head.Parent = creature

		-- Antlers (left)
		local leftAntler = Instance.new("Part")
		leftAntler.Name = "LeftAntler"
		leftAntler.Size = Vector3.new(0.3, 3, 0.3)
		leftAntler.Color = Color3.fromRGB(180, 160, 140)
		leftAntler.Material = Enum.Material.Bone
		leftAntler.Parent = creature

		local leftAntlerBranch = Instance.new("Part")
		leftAntlerBranch.Name = "LeftAntlerBranch"
		leftAntlerBranch.Size = Vector3.new(0.2, 1.5, 0.2)
		leftAntlerBranch.Color = Color3.fromRGB(180, 160, 140)
		leftAntlerBranch.Material = Enum.Material.Bone
		leftAntlerBranch.Parent = creature

		-- Antlers (right)
		local rightAntler = leftAntler:Clone()
		rightAntler.Name = "RightAntler"
		rightAntler.Parent = creature

		local rightAntlerBranch = leftAntlerBranch:Clone()
		rightAntlerBranch.Name = "RightAntlerBranch"
		rightAntlerBranch.Parent = creature

		-- Glowing eye sockets
		local leftEye = Instance.new("Part")
		leftEye.Name = "LeftEye"
		leftEye.Shape = Enum.PartType.Ball
		leftEye.Size = Vector3.new(0.6, 0.6, 0.3)
		leftEye.Color = Color3.fromRGB(255, 50, 0)
		leftEye.Material = Enum.Material.Neon
		leftEye.Parent = creature

		local rightEye = leftEye:Clone()
		rightEye.Name = "RightEye"
		rightEye.Parent = creature

		-- Long arms ending in claws
		local leftArm = Instance.new("Part")
		leftArm.Name = "LeftArm"
		leftArm.Size = Vector3.new(0.4, 8, 0.4)
		leftArm.Color = Color3.fromRGB(25, 20, 15)
		leftArm.Material = Enum.Material.SmoothPlastic
		leftArm.Parent = creature

		local rightArm = leftArm:Clone()
		rightArm.Name = "RightArm"
		rightArm.Parent = creature

		-- Claws
		local leftClaw = Instance.new("Part")
		leftClaw.Name = "LeftClaw"
		leftClaw.Size = Vector3.new(1.5, 0.3, 1.5)
		leftClaw.Color = Color3.fromRGB(200, 190, 170)
		leftClaw.Material = Enum.Material.Bone
		leftClaw.Parent = creature

		local rightClaw = leftClaw:Clone()
		rightClaw.Name = "RightClaw"
		rightClaw.Parent = creature

		-- Thin legs
		local leftLeg = Instance.new("Part")
		leftLeg.Name = "LeftLeg"
		leftLeg.Size = Vector3.new(0.5, 6, 0.5)
		leftLeg.Color = Color3.fromRGB(25, 20, 15)
		leftLeg.Material = Enum.Material.SmoothPlastic
		leftLeg.Parent = creature

		local rightLeg = leftLeg:Clone()
		rightLeg.Name = "RightLeg"
		rightLeg.Parent = creature

		-- HumanoidRootPart
		local rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Size = Vector3.new(2, 2, 1)
		rootPart.Transparency = 1
		rootPart.CanCollide = false
		rootPart.Parent = creature

		-- Humanoid
		local humanoid = Instance.new("Humanoid")
		humanoid.MaxHealth = 9999
		humanoid.Health = 9999
		humanoid.WalkSpeed = 18
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.Parent = creature

		-- Weld function
		local function weld(part0: BasePart, part1: BasePart, c0: CFrame)
			local motor = Instance.new("Motor6D")
			motor.Part0 = part0
			motor.Part1 = part1
			motor.C0 = c0
			motor.Parent = part0
		end

		creature.PrimaryPart = rootPart

		-- Position parts
		rootPart.Position = Vector3.new(0, 8, 0)
		body.Position = rootPart.Position
		head.Position = rootPart.Position + Vector3.new(0, 6.5, -1)
		leftEye.Position = head.Position + Vector3.new(-0.5, 0.3, -1.8)
		rightEye.Position = head.Position + Vector3.new(0.5, 0.3, -1.8)
		leftAntler.Position = head.Position + Vector3.new(-0.8, 2.5, 0)
		rightAntler.Position = head.Position + Vector3.new(0.8, 2.5, 0)
		leftAntlerBranch.Position = leftAntler.Position + Vector3.new(-0.7, 0.5, 0)
		rightAntlerBranch.Position = rightAntler.Position + Vector3.new(0.7, 0.5, 0)
		leftArm.Position = rootPart.Position + Vector3.new(-1.5, -1, 0)
		rightArm.Position = rootPart.Position + Vector3.new(1.5, -1, 0)
		leftClaw.Position = leftArm.Position + Vector3.new(0, -4, 0)
		rightClaw.Position = rightArm.Position + Vector3.new(0, -4, 0)
		leftLeg.Position = rootPart.Position + Vector3.new(-0.5, -8, 0)
		rightLeg.Position = rootPart.Position + Vector3.new(0.5, -8, 0)

		-- Weld all parts
		weld(rootPart, body, CFrame.new())
		weld(body, head, CFrame.new(0, 6.5, -1))
		weld(head, leftEye, CFrame.new(-0.5, 0.3, -1.8))
		weld(head, rightEye, CFrame.new(0.5, 0.3, -1.8))
		weld(head, leftAntler, CFrame.new(-0.8, 2.5, 0) * CFrame.Angles(0, 0, math.rad(-15)))
		weld(head, rightAntler, CFrame.new(0.8, 2.5, 0) * CFrame.Angles(0, 0, math.rad(15)))
		weld(leftAntler, leftAntlerBranch, CFrame.new(-0.7, 0.5, 0) * CFrame.Angles(0, 0, math.rad(-45)))
		weld(rightAntler, rightAntlerBranch, CFrame.new(0.7, 0.5, 0) * CFrame.Angles(0, 0, math.rad(45)))
		weld(body, leftArm, CFrame.new(-1.5, 2, 0))
		weld(body, rightArm, CFrame.new(1.5, 2, 0))
		weld(leftArm, leftClaw, CFrame.new(0, -4.5, 0))
		weld(rightArm, rightClaw, CFrame.new(0, -4.5, 0))
		weld(body, leftLeg, CFrame.new(-0.5, -8, 0))
		weld(body, rightLeg, CFrame.new(0.5, -8, 0))

		-- Creepy particle effect
		local particles = Instance.new("ParticleEmitter")
		particles.Color = ColorSequence.new(Color3.fromRGB(50, 30, 20))
		particles.Transparency = NumberSequence.new(0.7, 1)
		particles.Size = NumberSequence.new(0.5, 0)
		particles.Lifetime = NumberRange.new(1, 2)
		particles.Rate = 10
		particles.Speed = NumberRange.new(1, 3)
		particles.SpreadAngle = Vector2.new(180, 180)
		particles.Parent = body

		return creature
	end,
}

-- ==========================================
-- THE SHADOW (FACELESS EMPLOYEE)
-- ==========================================
-- Inspired by SCP-3008's employees
CREATURE_TYPES.SHADOW = {
	name = "The Shadow",
	health = 200,
	damage = 15,
	speedDay = 8,
	speedNight = 22,
	attackRange = 5,
	attackCooldown = 1.5,
	invulnerable = false,
	fleeFromLight = true,
	fleeFromFlashlight = false,
	packAnimal = false,
	canFly = false,
	fearFactor = 20,
	biomes = { "ALL" },
	spawnWeight = 30,
	nightOnly = false,
	bloodNightOnly = false,
	buildCreature = function(id: number): Model
		local creature = Instance.new("Model")
		creature.Name = "Shadow_" .. id

		-- Body (tall, thin, creepy)
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Size = Vector3.new(2, 8, 1)
		body.Color = Color3.fromRGB(20, 20, 25)
		body.Material = Enum.Material.SmoothPlastic
		body.Anchored = false
		body.CanCollide = true
		body.Parent = creature

		-- Head (featureless)
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Shape = Enum.PartType.Ball
		head.Size = Vector3.new(2.5, 3, 2)
		head.Color = Color3.fromRGB(15, 15, 20)
		head.Material = Enum.Material.SmoothPlastic
		head.Parent = creature

		-- Glowing eyes
		local leftEye = Instance.new("Part")
		leftEye.Name = "LeftEye"
		leftEye.Shape = Enum.PartType.Ball
		leftEye.Size = Vector3.new(0.4, 0.4, 0.2)
		leftEye.Color = Color3.fromRGB(255, 0, 0)
		leftEye.Material = Enum.Material.Neon
		leftEye.Transparency = 1
		leftEye.Parent = creature

		local rightEye = leftEye:Clone()
		rightEye.Name = "RightEye"
		rightEye.Parent = creature

		-- Arms
		local leftArm = Instance.new("Part")
		leftArm.Name = "LeftArm"
		leftArm.Size = Vector3.new(0.5, 6, 0.5)
		leftArm.Color = Color3.fromRGB(20, 20, 25)
		leftArm.Material = Enum.Material.SmoothPlastic
		leftArm.Parent = creature

		local rightArm = leftArm:Clone()
		rightArm.Name = "RightArm"
		rightArm.Parent = creature

		-- Legs
		local leftLeg = Instance.new("Part")
		leftLeg.Name = "LeftLeg"
		leftLeg.Size = Vector3.new(0.6, 5, 0.6)
		leftLeg.Color = Color3.fromRGB(20, 20, 25)
		leftLeg.Material = Enum.Material.SmoothPlastic
		leftLeg.Parent = creature

		local rightLeg = leftLeg:Clone()
		rightLeg.Name = "RightLeg"
		rightLeg.Parent = creature

		-- HumanoidRootPart
		local rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Size = Vector3.new(2, 2, 1)
		rootPart.Transparency = 1
		rootPart.CanCollide = false
		rootPart.Parent = creature

		-- Humanoid
		local humanoid = Instance.new("Humanoid")
		humanoid.MaxHealth = 200
		humanoid.Health = 200
		humanoid.WalkSpeed = 8
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.Parent = creature

		local function weld(part0: BasePart, part1: BasePart, c0: CFrame)
			local motor = Instance.new("Motor6D")
			motor.Part0 = part0
			motor.Part1 = part1
			motor.C0 = c0
			motor.Parent = part0
		end

		creature.PrimaryPart = rootPart

		rootPart.Position = Vector3.new(0, 6, 0)
		body.Position = rootPart.Position
		head.Position = rootPart.Position + Vector3.new(0, 5.5, 0)
		leftEye.Position = head.Position + Vector3.new(-0.5, 0.3, -1)
		rightEye.Position = head.Position + Vector3.new(0.5, 0.3, -1)
		leftArm.Position = rootPart.Position + Vector3.new(-1.5, -1, 0)
		rightArm.Position = rootPart.Position + Vector3.new(1.5, -1, 0)
		leftLeg.Position = rootPart.Position + Vector3.new(-0.5, -6, 0)
		rightLeg.Position = rootPart.Position + Vector3.new(0.5, -6, 0)

		weld(rootPart, body, CFrame.new())
		weld(body, head, CFrame.new(0, 5.5, 0))
		weld(head, leftEye, CFrame.new(-0.5, 0.3, -1))
		weld(head, rightEye, CFrame.new(0.5, 0.3, -1))
		weld(body, leftArm, CFrame.new(-1.5, 0, 0))
		weld(body, rightArm, CFrame.new(1.5, 0, 0))
		weld(body, leftLeg, CFrame.new(-0.5, -6.5, 0))
		weld(body, rightLeg, CFrame.new(0.5, -6.5, 0))

		return creature
	end,
}

-- ==========================================
-- WOLF
-- ==========================================
-- DEADLY pack hunters - will SHRED you at night without protection!
CREATURE_TYPES.WOLF = {
	name = "Wolf",
	health = 120,
	damage = 35, -- BRUTAL damage!
	speedDay = 16,
	speedNight = 32, -- TERRIFYINGLY FAST at night!
	attackRange = 5,
	attackCooldown = 0.3, -- RAPID attacks - death in seconds!
	invulnerable = false,
	fleeFromLight = true,
	fleeFromFlashlight = true,
	packAnimal = true,
	canFly = false,
	fearFactor = 30, -- More terrifying!
	biomes = { "FOREST", "SNOW", "ALL" }, -- EVERYWHERE!
	spawnWeight = 40, -- More common!
	nightOnly = false,
	bloodNightOnly = false,
	buildCreature = function(id: number): Model
		local creature = Instance.new("Model")
		creature.Name = "Wolf_" .. id

		-- Body
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Size = Vector3.new(2, 1.5, 4)
		body.Color = Color3.fromRGB(60, 55, 50)
		body.Material = Enum.Material.Fabric
		body.Anchored = false
		body.CanCollide = true
		body.Parent = creature

		-- Head
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1.5, 1.2, 2)
		head.Color = Color3.fromRGB(65, 60, 55)
		head.Material = Enum.Material.Fabric
		head.Parent = creature

		-- Snout
		local snout = Instance.new("Part")
		snout.Name = "Snout"
		snout.Size = Vector3.new(0.8, 0.6, 1.5)
		snout.Color = Color3.fromRGB(50, 45, 40)
		snout.Material = Enum.Material.Fabric
		snout.Parent = creature

		-- Eyes
		local leftEye = Instance.new("Part")
		leftEye.Name = "LeftEye"
		leftEye.Shape = Enum.PartType.Ball
		leftEye.Size = Vector3.new(0.3, 0.3, 0.2)
		leftEye.Color = Color3.fromRGB(255, 200, 50)
		leftEye.Material = Enum.Material.Neon
		leftEye.Parent = creature

		local rightEye = leftEye:Clone()
		rightEye.Name = "RightEye"
		rightEye.Parent = creature

		-- Ears
		local leftEar = Instance.new("Part")
		leftEar.Name = "LeftEar"
		leftEar.Size = Vector3.new(0.3, 0.6, 0.2)
		leftEar.Color = Color3.fromRGB(55, 50, 45)
		leftEar.Material = Enum.Material.Fabric
		leftEar.Parent = creature

		local rightEar = leftEar:Clone()
		rightEar.Name = "RightEar"
		rightEar.Parent = creature

		-- Legs (4)
		local frontLeftLeg = Instance.new("Part")
		frontLeftLeg.Name = "FrontLeftLeg"
		frontLeftLeg.Size = Vector3.new(0.4, 2, 0.4)
		frontLeftLeg.Color = Color3.fromRGB(55, 50, 45)
		frontLeftLeg.Material = Enum.Material.Fabric
		frontLeftLeg.Parent = creature

		local frontRightLeg = frontLeftLeg:Clone()
		frontRightLeg.Name = "FrontRightLeg"
		frontRightLeg.Parent = creature

		local backLeftLeg = frontLeftLeg:Clone()
		backLeftLeg.Name = "BackLeftLeg"
		backLeftLeg.Parent = creature

		local backRightLeg = frontLeftLeg:Clone()
		backRightLeg.Name = "BackRightLeg"
		backRightLeg.Parent = creature

		-- Tail
		local tail = Instance.new("Part")
		tail.Name = "Tail"
		tail.Size = Vector3.new(0.4, 0.4, 2)
		tail.Color = Color3.fromRGB(60, 55, 50)
		tail.Material = Enum.Material.Fabric
		tail.Parent = creature

		-- HumanoidRootPart
		local rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Size = Vector3.new(2, 2, 2)
		rootPart.Transparency = 1
		rootPart.CanCollide = false
		rootPart.Parent = creature

		-- Humanoid
		local humanoid = Instance.new("Humanoid")
		humanoid.MaxHealth = 80
		humanoid.Health = 80
		humanoid.WalkSpeed = 16
		humanoid.HipHeight = 1
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.Parent = creature

		local function weld(part0: BasePart, part1: BasePart, c0: CFrame)
			local motor = Instance.new("Motor6D")
			motor.Part0 = part0
			motor.Part1 = part1
			motor.C0 = c0
			motor.Parent = part0
		end

		creature.PrimaryPart = rootPart

		rootPart.Position = Vector3.new(0, 2, 0)
		body.Position = rootPart.Position
		head.Position = body.Position + Vector3.new(0, 0.5, -2.5)
		snout.Position = head.Position + Vector3.new(0, -0.2, -1.2)
		leftEye.Position = head.Position + Vector3.new(-0.4, 0.3, -0.7)
		rightEye.Position = head.Position + Vector3.new(0.4, 0.3, -0.7)
		leftEar.Position = head.Position + Vector3.new(-0.4, 0.7, 0)
		rightEar.Position = head.Position + Vector3.new(0.4, 0.7, 0)
		frontLeftLeg.Position = body.Position + Vector3.new(-0.7, -1.5, -1.2)
		frontRightLeg.Position = body.Position + Vector3.new(0.7, -1.5, -1.2)
		backLeftLeg.Position = body.Position + Vector3.new(-0.7, -1.5, 1.2)
		backRightLeg.Position = body.Position + Vector3.new(0.7, -1.5, 1.2)
		tail.Position = body.Position + Vector3.new(0, 0.3, 2.5)

		weld(rootPart, body, CFrame.new())
		weld(body, head, CFrame.new(0, 0.5, -2.5))
		weld(head, snout, CFrame.new(0, -0.2, -1.2))
		weld(head, leftEye, CFrame.new(-0.4, 0.3, -0.7))
		weld(head, rightEye, CFrame.new(0.4, 0.3, -0.7))
		weld(head, leftEar, CFrame.new(-0.4, 0.7, 0) * CFrame.Angles(0, 0, math.rad(-15)))
		weld(head, rightEar, CFrame.new(0.4, 0.7, 0) * CFrame.Angles(0, 0, math.rad(15)))
		weld(body, frontLeftLeg, CFrame.new(-0.7, -0.75, -1.2))
		weld(body, frontRightLeg, CFrame.new(0.7, -0.75, -1.2))
		weld(body, backLeftLeg, CFrame.new(-0.7, -0.75, 1.2))
		weld(body, backRightLeg, CFrame.new(0.7, -0.75, 1.2))
		weld(body, tail, CFrame.new(0, 0.3, 2.5) * CFrame.Angles(math.rad(-30), 0, 0))

		return creature
	end,
}

-- ==========================================
-- BEAR
-- ==========================================
-- Slow but extremely powerful
CREATURE_TYPES.BEAR = {
	name = "Bear",
	health = 500,
	damage = 35,
	speedDay = 10,
	speedNight = 14,
	attackRange = 6,
	attackCooldown = 2,
	invulnerable = false,
	fleeFromLight = false,
	fleeFromFlashlight = false,
	packAnimal = false,
	canFly = false,
	fearFactor = 30,
	biomes = { "FOREST", "SNOW" },
	spawnWeight = 10,
	nightOnly = false,
	bloodNightOnly = false,
	buildCreature = function(id: number): Model
		local creature = Instance.new("Model")
		creature.Name = "Bear_" .. id

		-- Massive body
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Size = Vector3.new(4, 3, 5)
		body.Color = Color3.fromRGB(70, 50, 35)
		body.Material = Enum.Material.Fabric
		body.Anchored = false
		body.CanCollide = true
		body.Parent = creature

		-- Head
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(2.5, 2, 2.5)
		head.Color = Color3.fromRGB(75, 55, 40)
		head.Material = Enum.Material.Fabric
		head.Parent = creature

		-- Snout
		local snout = Instance.new("Part")
		snout.Name = "Snout"
		snout.Size = Vector3.new(1.2, 1, 1.5)
		snout.Color = Color3.fromRGB(60, 45, 30)
		snout.Material = Enum.Material.Fabric
		snout.Parent = creature

		-- Eyes
		local leftEye = Instance.new("Part")
		leftEye.Name = "LeftEye"
		leftEye.Shape = Enum.PartType.Ball
		leftEye.Size = Vector3.new(0.4, 0.4, 0.2)
		leftEye.Color = Color3.fromRGB(20, 15, 10)
		leftEye.Material = Enum.Material.Glass
		leftEye.Parent = creature

		local rightEye = leftEye:Clone()
		rightEye.Name = "RightEye"
		rightEye.Parent = creature

		-- Small ears
		local leftEar = Instance.new("Part")
		leftEar.Name = "LeftEar"
		leftEar.Shape = Enum.PartType.Ball
		leftEar.Size = Vector3.new(0.6, 0.6, 0.3)
		leftEar.Color = Color3.fromRGB(70, 50, 35)
		leftEar.Material = Enum.Material.Fabric
		leftEar.Parent = creature

		local rightEar = leftEar:Clone()
		rightEar.Name = "RightEar"
		rightEar.Parent = creature

		-- Legs (4, thick)
		local frontLeftLeg = Instance.new("Part")
		frontLeftLeg.Name = "FrontLeftLeg"
		frontLeftLeg.Size = Vector3.new(1, 2.5, 1)
		frontLeftLeg.Color = Color3.fromRGB(65, 45, 30)
		frontLeftLeg.Material = Enum.Material.Fabric
		frontLeftLeg.Parent = creature

		local frontRightLeg = frontLeftLeg:Clone()
		frontRightLeg.Name = "FrontRightLeg"
		frontRightLeg.Parent = creature

		local backLeftLeg = frontLeftLeg:Clone()
		backLeftLeg.Name = "BackLeftLeg"
		backLeftLeg.Parent = creature

		local backRightLeg = frontLeftLeg:Clone()
		backRightLeg.Name = "BackRightLeg"
		backRightLeg.Parent = creature

		-- HumanoidRootPart
		local rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Size = Vector3.new(4, 3, 4)
		rootPart.Transparency = 1
		rootPart.CanCollide = false
		rootPart.Parent = creature

		-- Humanoid
		local humanoid = Instance.new("Humanoid")
		humanoid.MaxHealth = 500
		humanoid.Health = 500
		humanoid.WalkSpeed = 10
		humanoid.HipHeight = 1.5
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.Parent = creature

		local function weld(part0: BasePart, part1: BasePart, c0: CFrame)
			local motor = Instance.new("Motor6D")
			motor.Part0 = part0
			motor.Part1 = part1
			motor.C0 = c0
			motor.Parent = part0
		end

		creature.PrimaryPart = rootPart

		rootPart.Position = Vector3.new(0, 3, 0)
		body.Position = rootPart.Position
		head.Position = body.Position + Vector3.new(0, 1.5, -3)
		snout.Position = head.Position + Vector3.new(0, -0.3, -1.5)
		leftEye.Position = head.Position + Vector3.new(-0.6, 0.4, -0.8)
		rightEye.Position = head.Position + Vector3.new(0.6, 0.4, -0.8)
		leftEar.Position = head.Position + Vector3.new(-0.8, 0.9, 0)
		rightEar.Position = head.Position + Vector3.new(0.8, 0.9, 0)
		frontLeftLeg.Position = body.Position + Vector3.new(-1.3, -2.5, -1.5)
		frontRightLeg.Position = body.Position + Vector3.new(1.3, -2.5, -1.5)
		backLeftLeg.Position = body.Position + Vector3.new(-1.3, -2.5, 1.5)
		backRightLeg.Position = body.Position + Vector3.new(1.3, -2.5, 1.5)

		weld(rootPart, body, CFrame.new())
		weld(body, head, CFrame.new(0, 1.5, -3))
		weld(head, snout, CFrame.new(0, -0.3, -1.5))
		weld(head, leftEye, CFrame.new(-0.6, 0.4, -0.8))
		weld(head, rightEye, CFrame.new(0.6, 0.4, -0.8))
		weld(head, leftEar, CFrame.new(-0.8, 0.9, 0))
		weld(head, rightEar, CFrame.new(0.8, 0.9, 0))
		weld(body, frontLeftLeg, CFrame.new(-1.3, -1.25, -1.5))
		weld(body, frontRightLeg, CFrame.new(1.3, -1.25, -1.5))
		weld(body, backLeftLeg, CFrame.new(-1.3, -1.25, 1.5))
		weld(body, backRightLeg, CFrame.new(1.3, -1.25, 1.5))

		return creature
	end,
}

-- ==========================================
-- OWL (THE WATCHER)
-- ==========================================
-- Flying creature that watches and swoops
CREATURE_TYPES.OWL = {
	name = "The Watcher",
	health = 60,
	damage = 18,
	speedDay = 0,
	speedNight = 28,
	attackRange = 8,
	attackCooldown = 4,
	invulnerable = false,
	fleeFromLight = true,
	fleeFromFlashlight = true,
	packAnimal = false,
	canFly = true,
	fearFactor = 25,
	biomes = { "FOREST", "SWAMP" },
	spawnWeight = 15,
	nightOnly = true,
	bloodNightOnly = false,
	buildCreature = function(id: number): Model
		local creature = Instance.new("Model")
		creature.Name = "Owl_" .. id

		-- Body
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Size = Vector3.new(1.5, 2, 1.5)
		body.Color = Color3.fromRGB(80, 70, 60)
		body.Material = Enum.Material.Fabric
		body.Anchored = false
		body.CanCollide = false
		body.Parent = creature

		-- Head (large relative to body)
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Shape = Enum.PartType.Ball
		head.Size = Vector3.new(2, 1.8, 1.5)
		head.Color = Color3.fromRGB(90, 80, 70)
		head.Material = Enum.Material.Fabric
		head.Parent = creature

		-- Giant eyes
		local leftEye = Instance.new("Part")
		leftEye.Name = "LeftEye"
		leftEye.Shape = Enum.PartType.Ball
		leftEye.Size = Vector3.new(0.8, 0.8, 0.3)
		leftEye.Color = Color3.fromRGB(255, 200, 0)
		leftEye.Material = Enum.Material.Neon
		leftEye.Parent = creature

		local rightEye = leftEye:Clone()
		rightEye.Name = "RightEye"
		rightEye.Parent = creature

		-- Pupils
		local leftPupil = Instance.new("Part")
		leftPupil.Name = "LeftPupil"
		leftPupil.Shape = Enum.PartType.Ball
		leftPupil.Size = Vector3.new(0.3, 0.5, 0.15)
		leftPupil.Color = Color3.fromRGB(0, 0, 0)
		leftPupil.Material = Enum.Material.SmoothPlastic
		leftPupil.Parent = creature

		local rightPupil = leftPupil:Clone()
		rightPupil.Name = "RightPupil"
		rightPupil.Parent = creature

		-- Beak
		local beak = Instance.new("Part")
		beak.Name = "Beak"
		beak.Size = Vector3.new(0.4, 0.3, 0.5)
		beak.Color = Color3.fromRGB(40, 35, 30)
		beak.Material = Enum.Material.SmoothPlastic
		beak.Parent = creature

		-- Wings
		local leftWing = Instance.new("Part")
		leftWing.Name = "LeftWing"
		leftWing.Size = Vector3.new(3, 0.2, 2)
		leftWing.Color = Color3.fromRGB(70, 60, 50)
		leftWing.Material = Enum.Material.Fabric
		leftWing.Parent = creature

		local rightWing = leftWing:Clone()
		rightWing.Name = "RightWing"
		rightWing.Parent = creature

		-- Talons
		local leftTalon = Instance.new("Part")
		leftTalon.Name = "LeftTalon"
		leftTalon.Size = Vector3.new(0.4, 0.3, 0.6)
		leftTalon.Color = Color3.fromRGB(40, 35, 30)
		leftTalon.Material = Enum.Material.SmoothPlastic
		leftTalon.Parent = creature

		local rightTalon = leftTalon:Clone()
		rightTalon.Name = "RightTalon"
		rightTalon.Parent = creature

		-- HumanoidRootPart
		local rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Size = Vector3.new(2, 2, 2)
		rootPart.Transparency = 1
		rootPart.CanCollide = false
		rootPart.Parent = creature

		-- Humanoid
		local humanoid = Instance.new("Humanoid")
		humanoid.MaxHealth = 60
		humanoid.Health = 60
		humanoid.WalkSpeed = 28
		humanoid.HipHeight = 3
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.Parent = creature

		local function weld(part0: BasePart, part1: BasePart, c0: CFrame)
			local motor = Instance.new("Motor6D")
			motor.Part0 = part0
			motor.Part1 = part1
			motor.C0 = c0
			motor.Parent = part0
		end

		creature.PrimaryPart = rootPart

		rootPart.Position = Vector3.new(0, 15, 0) -- Starts high
		body.Position = rootPart.Position
		head.Position = body.Position + Vector3.new(0, 1.5, 0)
		leftEye.Position = head.Position + Vector3.new(-0.5, 0.2, -0.6)
		rightEye.Position = head.Position + Vector3.new(0.5, 0.2, -0.6)
		leftPupil.Position = leftEye.Position + Vector3.new(0, 0, -0.15)
		rightPupil.Position = rightEye.Position + Vector3.new(0, 0, -0.15)
		beak.Position = head.Position + Vector3.new(0, -0.3, -0.7)
		leftWing.Position = body.Position + Vector3.new(-2, 0.5, 0)
		rightWing.Position = body.Position + Vector3.new(2, 0.5, 0)
		leftTalon.Position = body.Position + Vector3.new(-0.4, -1.2, 0)
		rightTalon.Position = body.Position + Vector3.new(0.4, -1.2, 0)

		weld(rootPart, body, CFrame.new())
		weld(body, head, CFrame.new(0, 1.5, 0))
		weld(head, leftEye, CFrame.new(-0.5, 0.2, -0.6))
		weld(head, rightEye, CFrame.new(0.5, 0.2, -0.6))
		weld(leftEye, leftPupil, CFrame.new(0, 0, -0.15))
		weld(rightEye, rightPupil, CFrame.new(0, 0, -0.15))
		weld(head, beak, CFrame.new(0, -0.3, -0.7))
		weld(body, leftWing, CFrame.new(-2, 0.5, 0) * CFrame.Angles(0, 0, math.rad(-10)))
		weld(body, rightWing, CFrame.new(2, 0.5, 0) * CFrame.Angles(0, 0, math.rad(10)))
		weld(body, leftTalon, CFrame.new(-0.4, -1.2, 0))
		weld(body, rightTalon, CFrame.new(0.4, -1.2, 0))

		return creature
	end,
}

-- ==========================================
-- RAM (THE CHARGER)
-- ==========================================
-- Charges at players, can knock them down
CREATURE_TYPES.RAM = {
	name = "The Charger",
	health = 150,
	damage = 25,
	speedDay = 12,
	speedNight = 20,
	attackRange = 8,
	attackCooldown = 5,
	invulnerable = false,
	fleeFromLight = false,
	fleeFromFlashlight = false,
	packAnimal = false,
	canFly = false,
	fearFactor = 20,
	biomes = { "DESERT", "VOLCANIC" },
	spawnWeight = 15,
	nightOnly = false,
	bloodNightOnly = false,
	buildCreature = function(id: number): Model
		local creature = Instance.new("Model")
		creature.Name = "Ram_" .. id

		-- Body
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Size = Vector3.new(2.5, 2, 4)
		body.Color = Color3.fromRGB(100, 90, 80)
		body.Material = Enum.Material.Fabric
		body.Anchored = false
		body.CanCollide = true
		body.Parent = creature

		-- Head
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1.8, 1.5, 1.8)
		head.Color = Color3.fromRGB(90, 80, 70)
		head.Material = Enum.Material.Fabric
		head.Parent = creature

		-- Massive curved horns
		local leftHorn = Instance.new("Part")
		leftHorn.Name = "LeftHorn"
		leftHorn.Size = Vector3.new(0.6, 1.5, 2)
		leftHorn.Color = Color3.fromRGB(60, 50, 40)
		leftHorn.Material = Enum.Material.Bone
		leftHorn.Parent = creature

		local rightHorn = leftHorn:Clone()
		rightHorn.Name = "RightHorn"
		rightHorn.Parent = creature

		-- Eyes (angry, glowing red at night)
		local leftEye = Instance.new("Part")
		leftEye.Name = "LeftEye"
		leftEye.Shape = Enum.PartType.Ball
		leftEye.Size = Vector3.new(0.35, 0.35, 0.2)
		leftEye.Color = Color3.fromRGB(255, 100, 50)
		leftEye.Material = Enum.Material.Neon
		leftEye.Parent = creature

		local rightEye = leftEye:Clone()
		rightEye.Name = "RightEye"
		rightEye.Parent = creature

		-- Snout
		local snout = Instance.new("Part")
		snout.Name = "Snout"
		snout.Size = Vector3.new(1, 0.8, 1)
		snout.Color = Color3.fromRGB(80, 70, 60)
		snout.Material = Enum.Material.Fabric
		snout.Parent = creature

		-- Legs
		local frontLeftLeg = Instance.new("Part")
		frontLeftLeg.Name = "FrontLeftLeg"
		frontLeftLeg.Size = Vector3.new(0.5, 2, 0.5)
		frontLeftLeg.Color = Color3.fromRGB(85, 75, 65)
		frontLeftLeg.Material = Enum.Material.Fabric
		frontLeftLeg.Parent = creature

		local frontRightLeg = frontLeftLeg:Clone()
		frontRightLeg.Name = "FrontRightLeg"
		frontRightLeg.Parent = creature

		local backLeftLeg = frontLeftLeg:Clone()
		backLeftLeg.Name = "BackLeftLeg"
		backLeftLeg.Parent = creature

		local backRightLeg = frontLeftLeg:Clone()
		backRightLeg.Name = "BackRightLeg"
		backRightLeg.Parent = creature

		-- HumanoidRootPart
		local rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Size = Vector3.new(2.5, 2, 3)
		rootPart.Transparency = 1
		rootPart.CanCollide = false
		rootPart.Parent = creature

		-- Humanoid
		local humanoid = Instance.new("Humanoid")
		humanoid.MaxHealth = 150
		humanoid.Health = 150
		humanoid.WalkSpeed = 12
		humanoid.HipHeight = 1.2
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.Parent = creature

		local function weld(part0: BasePart, part1: BasePart, c0: CFrame)
			local motor = Instance.new("Motor6D")
			motor.Part0 = part0
			motor.Part1 = part1
			motor.C0 = c0
			motor.Parent = part0
		end

		creature.PrimaryPart = rootPart

		rootPart.Position = Vector3.new(0, 2.5, 0)
		body.Position = rootPart.Position
		head.Position = body.Position + Vector3.new(0, 0.5, -2.5)
		leftHorn.Position = head.Position + Vector3.new(-0.8, 0.8, 0.3)
		rightHorn.Position = head.Position + Vector3.new(0.8, 0.8, 0.3)
		leftEye.Position = head.Position + Vector3.new(-0.4, 0.2, -0.7)
		rightEye.Position = head.Position + Vector3.new(0.4, 0.2, -0.7)
		snout.Position = head.Position + Vector3.new(0, -0.3, -1)
		frontLeftLeg.Position = body.Position + Vector3.new(-0.8, -2, -1.2)
		frontRightLeg.Position = body.Position + Vector3.new(0.8, -2, -1.2)
		backLeftLeg.Position = body.Position + Vector3.new(-0.8, -2, 1.2)
		backRightLeg.Position = body.Position + Vector3.new(0.8, -2, 1.2)

		weld(rootPart, body, CFrame.new())
		weld(body, head, CFrame.new(0, 0.5, -2.5))
		weld(head, leftHorn, CFrame.new(-0.8, 0.8, 0.3) * CFrame.Angles(math.rad(-45), math.rad(-30), 0))
		weld(head, rightHorn, CFrame.new(0.8, 0.8, 0.3) * CFrame.Angles(math.rad(-45), math.rad(30), 0))
		weld(head, leftEye, CFrame.new(-0.4, 0.2, -0.7))
		weld(head, rightEye, CFrame.new(0.4, 0.2, -0.7))
		weld(head, snout, CFrame.new(0, -0.3, -1))
		weld(body, frontLeftLeg, CFrame.new(-0.8, -1, -1.2))
		weld(body, frontRightLeg, CFrame.new(0.8, -1, -1.2))
		weld(body, backLeftLeg, CFrame.new(-0.8, -1, 1.2))
		weld(body, backRightLeg, CFrame.new(0.8, -1, 1.2))

		return creature
	end,
}

-- ==========================================
-- WENDIGO (BLOOD NIGHT ONLY)
-- ==========================================
-- Appears only during Blood Nights - extremely dangerous
CREATURE_TYPES.WENDIGO = {
	name = "Wendigo",
	health = 800,
	damage = 60,
	speedDay = 0,
	speedNight = 26,
	attackRange = 7,
	attackCooldown = 1.5,
	invulnerable = false,
	fleeFromLight = false,
	fleeFromFlashlight = false,
	packAnimal = false,
	canFly = false,
	fearFactor = 80,
	biomes = { "FOREST", "SNOW" },
	spawnWeight = 5,
	nightOnly = true,
	bloodNightOnly = true,
	buildCreature = function(id: number): Model
		local creature = Instance.new("Model")
		creature.Name = "Wendigo_" .. id

		-- Emaciated body
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Size = Vector3.new(2, 12, 1.5)
		body.Color = Color3.fromRGB(40, 35, 30)
		body.Material = Enum.Material.SmoothPlastic
		body.Anchored = false
		body.CanCollide = true
		body.Parent = creature

		-- Skull head
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(2.5, 3.5, 3)
		head.Color = Color3.fromRGB(200, 190, 170)
		head.Material = Enum.Material.Bone
		head.Parent = creature

		-- Massive antlers
		local leftAntler = Instance.new("Part")
		leftAntler.Name = "LeftAntler"
		leftAntler.Size = Vector3.new(0.4, 5, 0.4)
		leftAntler.Color = Color3.fromRGB(150, 140, 120)
		leftAntler.Material = Enum.Material.Bone
		leftAntler.Parent = creature

		local rightAntler = leftAntler:Clone()
		rightAntler.Name = "RightAntler"
		rightAntler.Parent = creature

		-- Antler branches
		for i = 1, 3 do
			local leftBranch = Instance.new("Part")
			leftBranch.Name = "LeftBranch" .. i
			leftBranch.Size = Vector3.new(0.2, 1.5, 0.2)
			leftBranch.Color = Color3.fromRGB(150, 140, 120)
			leftBranch.Material = Enum.Material.Bone
			leftBranch.Parent = creature

			local rightBranch = leftBranch:Clone()
			rightBranch.Name = "RightBranch" .. i
			rightBranch.Parent = creature
		end

		-- Burning eye sockets
		local leftEye = Instance.new("Part")
		leftEye.Name = "LeftEye"
		leftEye.Shape = Enum.PartType.Ball
		leftEye.Size = Vector3.new(0.7, 0.7, 0.3)
		leftEye.Color = Color3.fromRGB(255, 100, 0)
		leftEye.Material = Enum.Material.Neon
		leftEye.Parent = creature

		local rightEye = leftEye:Clone()
		rightEye.Name = "RightEye"
		rightEye.Parent = creature

		-- Fire particles from eyes
		local fireParticles = Instance.new("ParticleEmitter")
		fireParticles.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 50, 0))
		fireParticles.Transparency = NumberSequence.new(0.3, 1)
		fireParticles.Size = NumberSequence.new(0.3, 0)
		fireParticles.Lifetime = NumberRange.new(0.3, 0.5)
		fireParticles.Rate = 20
		fireParticles.Speed = NumberRange.new(2, 4)
		fireParticles.SpreadAngle = Vector2.new(30, 30)
		fireParticles.Parent = leftEye

		local fireParticles2 = fireParticles:Clone()
		fireParticles2.Parent = rightEye

		-- Skeletal arms
		local leftArm = Instance.new("Part")
		leftArm.Name = "LeftArm"
		leftArm.Size = Vector3.new(0.5, 10, 0.5)
		leftArm.Color = Color3.fromRGB(45, 40, 35)
		leftArm.Material = Enum.Material.SmoothPlastic
		leftArm.Parent = creature

		local rightArm = leftArm:Clone()
		rightArm.Name = "RightArm"
		rightArm.Parent = creature

		-- Claws
		local leftClaw = Instance.new("Part")
		leftClaw.Name = "LeftClaw"
		leftClaw.Size = Vector3.new(2, 0.4, 2)
		leftClaw.Color = Color3.fromRGB(180, 170, 150)
		leftClaw.Material = Enum.Material.Bone
		leftClaw.Parent = creature

		local rightClaw = leftClaw:Clone()
		rightClaw.Name = "RightClaw"
		rightClaw.Parent = creature

		-- Legs
		local leftLeg = Instance.new("Part")
		leftLeg.Name = "LeftLeg"
		leftLeg.Size = Vector3.new(0.6, 8, 0.6)
		leftLeg.Color = Color3.fromRGB(40, 35, 30)
		leftLeg.Material = Enum.Material.SmoothPlastic
		leftLeg.Parent = creature

		local rightLeg = leftLeg:Clone()
		rightLeg.Name = "RightLeg"
		rightLeg.Parent = creature

		-- HumanoidRootPart
		local rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Size = Vector3.new(2, 2, 1)
		rootPart.Transparency = 1
		rootPart.CanCollide = false
		rootPart.Parent = creature

		-- Humanoid
		local humanoid = Instance.new("Humanoid")
		humanoid.MaxHealth = 800
		humanoid.Health = 800
		humanoid.WalkSpeed = 26
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.Parent = creature

		local function weld(part0: BasePart, part1: BasePart, c0: CFrame)
			local motor = Instance.new("Motor6D")
			motor.Part0 = part0
			motor.Part1 = part1
			motor.C0 = c0
			motor.Parent = part0
		end

		creature.PrimaryPart = rootPart

		rootPart.Position = Vector3.new(0, 10, 0)
		body.Position = rootPart.Position
		head.Position = rootPart.Position + Vector3.new(0, 8, 0)
		leftAntler.Position = head.Position + Vector3.new(-0.8, 4, 0)
		rightAntler.Position = head.Position + Vector3.new(0.8, 4, 0)
		leftEye.Position = head.Position + Vector3.new(-0.5, 0.5, -1.3)
		rightEye.Position = head.Position + Vector3.new(0.5, 0.5, -1.3)
		leftArm.Position = rootPart.Position + Vector3.new(-1.5, 0, 0)
		rightArm.Position = rootPart.Position + Vector3.new(1.5, 0, 0)
		leftClaw.Position = leftArm.Position + Vector3.new(0, -5.5, 0)
		rightClaw.Position = rightArm.Position + Vector3.new(0, -5.5, 0)
		leftLeg.Position = rootPart.Position + Vector3.new(-0.5, -10, 0)
		rightLeg.Position = rootPart.Position + Vector3.new(0.5, -10, 0)

		weld(rootPart, body, CFrame.new())
		weld(body, head, CFrame.new(0, 8, 0))
		weld(head, leftAntler, CFrame.new(-0.8, 4, 0) * CFrame.Angles(0, 0, math.rad(-20)))
		weld(head, rightAntler, CFrame.new(0.8, 4, 0) * CFrame.Angles(0, 0, math.rad(20)))
		weld(head, leftEye, CFrame.new(-0.5, 0.5, -1.3))
		weld(head, rightEye, CFrame.new(0.5, 0.5, -1.3))
		weld(body, leftArm, CFrame.new(-1.5, 4, 0))
		weld(body, rightArm, CFrame.new(1.5, 4, 0))
		weld(leftArm, leftClaw, CFrame.new(0, -5.5, 0))
		weld(rightArm, rightClaw, CFrame.new(0, -5.5, 0))
		weld(body, leftLeg, CFrame.new(-0.5, -10, 0))
		weld(body, rightLeg, CFrame.new(0.5, -10, 0))

		-- Smoke/mist effect
		local mist = Instance.new("ParticleEmitter")
		mist.Color = ColorSequence.new(Color3.fromRGB(30, 25, 20))
		mist.Transparency = NumberSequence.new(0.5, 1)
		mist.Size = NumberSequence.new(2, 0)
		mist.Lifetime = NumberRange.new(1, 2)
		mist.Rate = 15
		mist.Speed = NumberRange.new(1, 2)
		mist.SpreadAngle = Vector2.new(180, 180)
		mist.Parent = body

		return creature
	end,
}

-- ==========================================
-- STATE AND CONFIGURATION
-- ==========================================

local WORLD_SIZE = 3000  -- Must stay within terrain bounds (3500)
local SAFE_ZONE_RADIUS = 20 -- Safe zone around campfires
local FLASHLIGHT_RANGE = 40 -- How far flashlight reaches

-- Creature counts per type - LOTS of deadly creatures!
local CREATURE_COUNTS = {
	SHADOW = 25,    -- Shadows EVERYWHERE
	WOLF = 40,      -- MASSIVE wolf packs - they WILL find you!
	BEAR = 8,       -- More bears
	OWL = 15,       -- Owls watching from trees
	RAM = 10,       -- Mountain rams
	DEER_MONSTER = 8, -- MORE terrifying deer monsters!
	WENDIGO = 0,    -- Spawned during blood nights
}

-- State
local creatures: { [Model]: {
	type: string,
	typeData: CreatureType,
	lastAttack: number,
	packLeader: Model?,
	behavior: string,
	targetPlayer: Player?,
	isCharging: boolean,
	chargeTarget: Vector3?,
	spawnBiome: string,
} } = {}

local isNightTime = false
local isBloodNight = false
local nightCount = 0

-- ==========================================
-- BIOME DETECTION
-- ==========================================

local function getBiome(x: number, z: number): string
	local distance = math.sqrt(x * x + z * z)
	local angle = math.atan2(z, x)

	if distance < 500 then
		return "FOREST"
	end

	-- Direction-based biome assignment
	if angle >= -math.pi / 3 and angle < math.pi / 3 then
		return "SNOW"
	elseif angle >= math.pi / 3 and angle < 2 * math.pi / 3 then
		return "DESERT"
	elseif angle >= 2 * math.pi / 3 or angle < -2 * math.pi / 3 then
		return "VOLCANIC"
	elseif angle >= -2 * math.pi / 3 and angle < -math.pi / 3 then
		if distance < 2000 then
			return "SWAMP"
		else
			return "CRYSTAL"
		end
	end

	return "FOREST"
end

-- ==========================================
-- PERFORMANCE CACHES (updated periodically, not every frame)
-- ==========================================

local campfirePositions: { Vector3 } = {}
local playerFlashlights: { [Player]: { enabled: boolean, position: Vector3?, lookDir: Vector3? } } = {}
local lastCacheUpdate = 0
local CACHE_UPDATE_INTERVAL = 0.5  -- Update caches twice per second

local function updateCaches()
	local now = tick()
	if now - lastCacheUpdate < CACHE_UPDATE_INTERVAL then return end
	lastCacheUpdate = now

	-- Update campfire positions
	campfirePositions = {}
	local campfireFolder = workspace:FindFirstChild("Campfires")
	if campfireFolder then
		for _, obj in campfireFolder:GetChildren() do
			if obj:IsA("Model") then
				local fire = obj:FindFirstChild("Fire")
				if fire and fire:IsA("BasePart") then
					table.insert(campfirePositions, fire.Position)
				end
			end
		end
	end

	-- Also check for individual campfires in workspace (backwards compat)
	for _, obj in workspace:GetChildren() do
		if obj.Name == "Campfire" and obj:IsA("Model") then
			local fire = obj:FindFirstChild("Fire")
			if fire and fire:IsA("BasePart") then
				table.insert(campfirePositions, fire.Position)
			end
		end
	end

	-- Update player flashlight states
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then
			playerFlashlights[player] = { enabled = false }
			continue
		end

		local head = character:FindFirstChild("Head") :: BasePart?
		if not head then
			playerFlashlights[player] = { enabled = false }
			continue
		end

		-- Check for flashlight (just check common locations, not GetDescendants)
		local flashlightEnabled = false
		local tool = character:FindFirstChildOfClass("Tool")
		if tool then
			local light = tool:FindFirstChildOfClass("SpotLight")
			if light and light.Enabled then
				flashlightEnabled = true
			end
		end

		playerFlashlights[player] = {
			enabled = flashlightEnabled,
			position = head.Position,
			lookDir = head.CFrame.LookVector,
		}
	end
end

-- ==========================================
-- UTILITY FUNCTIONS (optimized)
-- ==========================================

-- Check if position is near a light source (uses cache)
local function isNearLight(position: Vector3): boolean
	for _, campfirePos in campfirePositions do
		if (campfirePos - position).Magnitude < SAFE_ZONE_RADIUS then
			return true
		end
	end
	return false
end

-- Check if creature is being hit by flashlight (uses cache)
local function isInFlashlight(creaturePos: Vector3): boolean
	for player, data in playerFlashlights do
		if not data.enabled or not data.position or not data.lookDir then continue end

		local toCreature = (creaturePos - data.position)
		local distance = toCreature.Magnitude

		if distance > FLASHLIGHT_RANGE then continue end

		local angle = math.acos(math.clamp(data.lookDir:Dot(toCreature.Unit), -1, 1))
		if math.deg(angle) < 30 then
			return true
		end
	end

	return false
end

-- Find closest player
local function findClosestPlayer(creaturePos: Vector3): (Player?, number)
	local closest: Player? = nil
	local closestDist = math.huge

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then continue end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then continue end

		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not rootPart then continue end

		local dist = (rootPart.Position - creaturePos).Magnitude
		if dist < closestDist then
			closestDist = dist
			closest = player
		end
	end

	return closest, closestDist
end

-- Find pack members nearby
local function findPackMembers(creature: Model, creatureType: string): { Model }
	local pack: { Model } = {}
	local myRoot = creature:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not myRoot then return pack end

	for otherCreature, data in creatures do
		if otherCreature == creature then continue end
		if data.type ~= creatureType then continue end

		local otherRoot = otherCreature:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not otherRoot then continue end

		if (otherRoot.Position - myRoot.Position).Magnitude < 50 then
			table.insert(pack, otherCreature)
		end
	end

	return pack
end

-- ==========================================
-- CREATURE SPAWNING
-- ==========================================

local function spawnCreature(creatureType: string, position: Vector3?): Model?
	local typeData = CREATURE_TYPES[creatureType]
	if not typeData then return nil end

	-- Generate spawn position if not provided
	local spawnPos = position
	local spawnBiome = "FOREST"

	if not spawnPos then
		-- Try to spawn in appropriate biome
		local attempts = 0
		repeat
			local angle = math.random() * math.pi * 2
			local distance = 200 + math.random() * (WORLD_SIZE - 200)
			local x = math.cos(angle) * distance
			local z = math.sin(angle) * distance
			-- Get terrain height at this position
			local terrainHeight = Shared.getTerrainHeight(x, z)
			spawnPos = Vector3.new(x, terrainHeight + 5, z)
			spawnBiome = getBiome(x, z)
			attempts += 1
		until table.find(typeData.biomes, spawnBiome) or table.find(typeData.biomes, "ALL") or attempts > 10
	else
		-- Adjust provided position to terrain height
		local terrainHeight = Shared.getTerrainHeight(spawnPos.X, spawnPos.Z)
		spawnPos = Vector3.new(spawnPos.X, terrainHeight + 5, spawnPos.Z)
		spawnBiome = getBiome(spawnPos.X, spawnPos.Z)
	end

	-- Build the creature
	local id = math.random(1, 99999)
	local creature = typeData.buildCreature(id)

	-- Position it
	creature:PivotTo(CFrame.new(spawnPos))
	creature.Parent = workspace

	-- Store creature data
	creatures[creature] = {
		type = creatureType,
		typeData = typeData,
		lastAttack = 0,
		packLeader = nil,
		behavior = "wander",
		targetPlayer = nil,
		isCharging = false,
		chargeTarget = nil,
		spawnBiome = spawnBiome,
	}

	return creature
end

-- ==========================================
-- CREATURE BEHAVIOR
-- ==========================================

local function updateCreature(creature: Model, data: typeof(creatures[any]))
	local humanoid = creature:FindFirstChildOfClass("Humanoid")
	local rootPart = creature:FindFirstChild("HumanoidRootPart") :: BasePart?

	if not humanoid or not rootPart then return end
	if humanoid.Health <= 0 then
		creatures[creature] = nil
		creature:Destroy()
		return
	end

	local creaturePos = rootPart.Position
	local typeData = data.typeData

	-- Night-only creatures disappear during day
	if typeData.nightOnly and not isNightTime then
		humanoid.WalkSpeed = 0
		-- Hide creature (move underground or make invisible)
		if creature:GetAttribute("Hidden") ~= true then
			creature:SetAttribute("Hidden", true)
			for _, part in creature:GetDescendants() do
				if part:IsA("BasePart") then
					part.Transparency = 1
				end
			end
		end
		return
	else
		if creature:GetAttribute("Hidden") == true then
			creature:SetAttribute("Hidden", false)
			for _, part in creature:GetDescendants() do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Transparency = 0
				end
			end
		end
	end

	-- Blood night only creatures
	if typeData.bloodNightOnly and not isBloodNight then
		return
	end

	-- Update speed based on time
	humanoid.WalkSpeed = isNightTime and typeData.speedNight or typeData.speedDay

	-- Update eye glow for night creatures
	local leftEye = creature:FindFirstChild("LeftEye") :: BasePart?
	local rightEye = creature:FindFirstChild("RightEye") :: BasePart?
	if leftEye and rightEye and leftEye.Material == Enum.Material.Neon then
		leftEye.Transparency = isNightTime and 0 or 0.8
		rightEye.Transparency = isNightTime and 0 or 0.8
	end

	-- Find target
	local target, distance = findClosestPlayer(creaturePos)

	-- Check light sources
	local nearLight = isNearLight(creaturePos)
	local inFlashlight = isInFlashlight(creaturePos)

	-- Flee from light/flashlight
	if (typeData.fleeFromLight and nearLight) or (typeData.fleeFromFlashlight and inFlashlight) then
		if target then
			local targetChar = target.Character
			if targetChar then
				local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
				if targetRoot then
					-- Flee away from player/light
					local awayDir = (creaturePos - targetRoot.Position).Unit
					humanoid:MoveTo(creaturePos + awayDir * 30)

					-- Alert players that creature is retreating
					if typeData.name == "The Stalker" and inFlashlight then
						for _, player in Players:GetPlayers() do
							CreatureAlertRemote:FireClient(player, "DEER_RETREATING")
						end
					end
				end
			end
		end
		return
	end

	-- Pack behavior for wolves
	if typeData.packAnimal then
		local pack = findPackMembers(creature, data.type)
		if #pack >= 2 and target and distance < 60 then
			-- Attack as pack!
			data.behavior = "hunt"
		end
	end

	-- Charging behavior for rams
	if data.type == "RAM" and isNightTime and target and distance < 40 and distance > 10 then
		if not data.isCharging and tick() - data.lastAttack > typeData.attackCooldown then
			data.isCharging = true
			local targetChar = target.Character
			if targetChar then
				local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
				if targetRoot then
					data.chargeTarget = targetRoot.Position
					humanoid.WalkSpeed = typeData.speedNight * 2 -- Double speed for charge
				end
			end
		end
	end

	-- Handle charging
	if data.isCharging and data.chargeTarget then
		local toTarget = (data.chargeTarget - creaturePos)
		if toTarget.Magnitude < 3 then
			data.isCharging = false
			data.chargeTarget = nil
			humanoid.WalkSpeed = isNightTime and typeData.speedNight or typeData.speedDay
		else
			humanoid:MoveTo(data.chargeTarget)
		end
	end

	-- Combat behavior
	if isNightTime and target and distance < 80 then
		local targetChar = target.Character
		if targetChar then
			local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
			if targetRoot then
				-- Check if target is safe
				if isNearLight(targetRoot.Position) then
					-- Can't attack, retreat
					local awayDir = (creaturePos - targetRoot.Position).Unit
					humanoid:MoveTo(creaturePos + awayDir * 20)
				else
					-- Chase!
					if not data.isCharging then
						humanoid:MoveTo(targetRoot.Position)
					end

					-- Attack if close enough
					if distance < typeData.attackRange then
						if tick() - data.lastAttack > typeData.attackCooldown then
							data.lastAttack = tick()

							local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
							if targetHumanoid then
								-- Invulnerable creatures can still attack
								targetHumanoid:TakeDamage(typeData.damage)

								-- Knockback
								local knockback = Instance.new("BodyVelocity")
								knockback.MaxForce = Vector3.new(40000, 40000, 40000)
								knockback.Velocity = (targetRoot.Position - creaturePos).Unit * 40 + Vector3.new(0, 20, 0)
								knockback.Parent = targetRoot
								task.delay(0.2, function()
									knockback:Destroy()
								end)

								-- Alert player
								CreatureAlertRemote:FireClient(target, "ATTACKED", typeData.name, typeData.damage)

								-- Increased knockback for rams/bears
								if data.type == "RAM" or data.type == "BEAR" then
									knockback.Velocity = (targetRoot.Position - creaturePos).Unit * 60 + Vector3.new(0, 30, 0)
								end
							end
						end
					end
				end
			end
		end
	else
		-- Day behavior or no target: wander
		if math.random() < 0.01 then
			local wanderPos = creaturePos + Vector3.new(
				(math.random() - 0.5) * 60,
				0,
				(math.random() - 0.5) * 60
			)
			humanoid:MoveTo(wanderPos)
		end
	end

	-- Flying creatures (owls) maintain altitude
	if typeData.canFly then
		local targetY = 15 + math.sin(tick() + rootPart.Position.X) * 5
		if math.abs(rootPart.Position.Y - targetY) > 2 then
			local bodyPos = rootPart:FindFirstChildOfClass("BodyPosition")
			if not bodyPos then
				bodyPos = Instance.new("BodyPosition")
				bodyPos.MaxForce = Vector3.new(0, 10000, 0)
				bodyPos.P = 5000
				bodyPos.Parent = rootPart
			end
			bodyPos.Position = Vector3.new(rootPart.Position.X, targetY, rootPart.Position.Z)
		end
	end
end

-- ==========================================
-- BLOOD NIGHT SYSTEM
-- ==========================================

local function triggerBloodNight()
	isBloodNight = true
	print("[Creature] BLOOD NIGHT HAS BEGUN!")

	-- Alert all players
	for _, player in Players:GetPlayers() do
		CreatureAlertRemote:FireClient(player, "BLOOD_NIGHT_START")
	end

	-- Spawn Wendigos
	for i = 1, 3 do
		local angle = (i / 3) * math.pi * 2
		local distance = 300 + math.random() * 200
		local pos = Vector3.new(math.cos(angle) * distance, 10, math.sin(angle) * distance)
		spawnCreature("WENDIGO", pos)
	end

	-- Make lighting blood red
	Lighting.Ambient = Color3.fromRGB(80, 20, 20)
	Lighting.OutdoorAmbient = Color3.fromRGB(60, 15, 15)

	-- Blood night ends at dawn
	task.spawn(function()
		repeat task.wait(1) until not isNightTime
		isBloodNight = false
		print("[Creature] Blood night has ended.")

		-- Destroy all Wendigos
		for creature, data in creatures do
			if data.type == "WENDIGO" then
				creature:Destroy()
				creatures[creature] = nil
			end
		end

		-- Reset lighting
		Lighting.Ambient = Color3.fromRGB(50, 50, 60)
		Lighting.OutdoorAmbient = Color3.fromRGB(40, 40, 50)
	end)
end

-- ==========================================
-- MAIN LOOP (optimized with throttling)
-- ==========================================

local lastTimeCheck = 0
local wasNight = false
local frameCount = 0
local CREATURE_UPDATE_INTERVAL = 3  -- Update creatures every 3 frames (20fps instead of 60)

RunService.Heartbeat:Connect(function()
	frameCount = frameCount + 1

	-- Update caches (handles its own throttling)
	updateCaches()

	local hour = Lighting.ClockTime

	-- Update night status
	local previousNight = isNightTime
	isNightTime = hour >= 20 or hour < 5

	-- Track night transitions
	if isNightTime and not wasNight then
		nightCount += 1
		print("[Creature] Night", nightCount, "has fallen. The creatures awaken...")

		-- Blood night every 5 nights
		if nightCount % 5 == 0 then
			task.delay(30, triggerBloodNight) -- Blood night starts 30 seconds into night
		end
	elseif not isNightTime and wasNight then
		print("[Creature] Dawn breaks. The creatures retreat...")
	end

	wasNight = isNightTime

	-- Throttle creature updates (every 3 frames = ~20fps)
	if frameCount % CREATURE_UPDATE_INTERVAL ~= 0 then return end

	-- Update all creatures
	for creature, data in creatures do
		if creature and creature.Parent then
			updateCreature(creature, data)
		else
			creatures[creature] = nil
		end
	end
end)

-- ==========================================
-- INITIALIZATION
-- ==========================================

task.spawn(function()
	-- Wait for world to generate
	task.wait(5)

	print("[Creature] Spawning creatures across the world...")

	-- Spawn each creature type
	for creatureType, count in CREATURE_COUNTS do
		for i = 1, count do
			spawnCreature(creatureType)
			task.wait(0.1) -- Stagger spawns
		end
	end

	local total = 0
	for _, count in CREATURE_COUNTS do
		total += count
	end

	print("[Creature] Spawned", total, "creatures across all biomes")
	print("[Creature] Types: Shadows, Wolves, Bears, Owls, Rams, Deer Monsters")
	print("[Creature] Blood Nights occur every 5 nights - beware the Wendigo!")
end)
