--!strict
-- Hostile creatures for Mertin-Flemmer
-- Passive during day, aggressive at night

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config

-- Wait for TimeUpdate remote
local TimeUpdateRemote = ReplicatedStorage:WaitForChild("TimeUpdate") :: RemoteEvent

-- Creature configuration
local CREATURE_COUNT = 8
local SPAWN_RADIUS = 150
local SAFE_ZONE_RADIUS = 15 -- Stay away from campfires

-- State
local creatures: { Model } = {}
local isNightTime = false

-- Create a creature
local function createCreature(id: number): Model
	local creature = Instance.new("Model")
	creature.Name = "Creature_" .. id

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

	-- Glowing eyes (only visible at night)
	local leftEye = Instance.new("Part")
	leftEye.Name = "LeftEye"
	leftEye.Shape = Enum.PartType.Ball
	leftEye.Size = Vector3.new(0.4, 0.4, 0.2)
	leftEye.Color = Color3.fromRGB(255, 0, 0)
	leftEye.Material = Enum.Material.Neon
	leftEye.Transparency = 1 -- Hidden during day
	leftEye.Parent = creature

	local rightEye = leftEye:Clone()
	rightEye.Name = "RightEye"
	rightEye.Parent = creature

	-- Arms (long and thin)
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
	humanoid.WalkSpeed = Config.CREATURE_SPEED_DAY
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = creature

	-- Weld parts
	local function weld(part0: BasePart, part1: BasePart, c0: CFrame)
		local motor = Instance.new("Motor6D")
		motor.Part0 = part0
		motor.Part1 = part1
		motor.C0 = c0
		motor.Parent = part0
	end

	creature.PrimaryPart = rootPart

	-- Position parts relative to root
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

	-- Spawn at random position
	local angle = math.random() * math.pi * 2
	local distance = 50 + math.random() * (SPAWN_RADIUS - 50)
	local spawnPos = Vector3.new(math.cos(angle) * distance, 10, math.sin(angle) * distance)
	creature:PivotTo(CFrame.new(spawnPos))

	creature.Parent = workspace
	return creature
end

-- Check if position is near a light source (campfire)
local function isNearLight(position: Vector3): boolean
	for _, obj in workspace:GetDescendants() do
		if obj.Name == "Campfire" and obj:IsA("Model") then
			local fire = obj:FindFirstChild("Fire")
			if fire and fire:IsA("BasePart") then
				if (fire.Position - position).Magnitude < SAFE_ZONE_RADIUS then
					return true
				end
			end
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

-- Update creature behavior
local function updateCreature(creature: Model)
	local humanoid = creature:FindFirstChildOfClass("Humanoid")
	local rootPart = creature:FindFirstChild("HumanoidRootPart") :: BasePart?

	if not humanoid or not rootPart then return end
	if humanoid.Health <= 0 then return end

	local creaturePos = rootPart.Position

	-- Update speed based on time
	humanoid.WalkSpeed = isNightTime and Config.CREATURE_SPEED_NIGHT or Config.CREATURE_SPEED_DAY

	-- Update eye glow
	local leftEye = creature:FindFirstChild("LeftEye") :: BasePart?
	local rightEye = creature:FindFirstChild("RightEye") :: BasePart?
	if leftEye and rightEye then
		leftEye.Transparency = isNightTime and 0 or 1
		rightEye.Transparency = isNightTime and 0 or 1
	end

	-- Find target
	local target, distance = findClosestPlayer(creaturePos)

	if isNightTime and target then
		local targetChar = target.Character
		if targetChar then
			local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
			if targetRoot then
				-- Check if target is near light (safe)
				if isNearLight(targetRoot.Position) then
					-- Retreat from light
					local awayDir = (creaturePos - targetRoot.Position).Unit
					humanoid:MoveTo(creaturePos + awayDir * 20)
				else
					-- Chase!
					humanoid:MoveTo(targetRoot.Position)

					-- Attack if close
					if distance < 5 then
						local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
						if targetHumanoid then
							targetHumanoid:TakeDamage(Config.CREATURE_DAMAGE)
							-- Knockback
							local knockback = Instance.new("BodyVelocity")
							knockback.MaxForce = Vector3.new(30000, 30000, 30000)
							knockback.Velocity = (targetRoot.Position - creaturePos).Unit * 30 + Vector3.new(0, 15, 0)
							knockback.Parent = targetRoot
							task.delay(0.2, function()
								knockback:Destroy()
							end)
						end
					end
				end
			end
		end
	else
		-- Day behavior: wander slowly
		if math.random() < 0.01 then
			local wanderPos = creaturePos + Vector3.new(
				(math.random() - 0.5) * 40,
				0,
				(math.random() - 0.5) * 40
			)
			humanoid:MoveTo(wanderPos)
		end
	end
end

-- Handle time changes
TimeUpdateRemote.OnServerEvent:Connect(function() end) -- Clients only

-- Listen for time broadcasts (we need to track this ourselves)
local lastTimeCheck = 0
RunService.Heartbeat:Connect(function()
	local Lighting = game:GetService("Lighting")
	local hour = Lighting.ClockTime

	-- Update night status
	local wasNight = isNightTime
	isNightTime = hour >= 20 or hour < 5

	if isNightTime ~= wasNight then
		if isNightTime then
			print("[Creature] Night has fallen. The creatures awaken...")
		else
			print("[Creature] Dawn breaks. The creatures retreat...")
		end
	end

	-- Update all creatures
	for _, creature in creatures do
		if creature and creature.Parent then
			updateCreature(creature)
		end
	end
end)

-- Spawn creatures
for i = 1, CREATURE_COUNT do
	local creature = createCreature(i)
	table.insert(creatures, creature)
end

print("[Creature] Spawned", CREATURE_COUNT, "creatures")
