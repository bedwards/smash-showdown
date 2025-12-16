--!strict
--[[
	Faultline Fear: Creature Service

	Spawns and manages hostile night creatures.
	Creatures spawn at dusk, hunt players, despawn at dawn.

	Creature Types:
	- Shadow Stalker: Fast quadruped, pack hunter
	- Fissure Dweller: Emerges from fault line, slow but strong
	- Night Bird: Aerial threat, swooping attacks

	Features:
	- AI state machine (Idle, Hunt, Attack, Flee)
	- PathfindingService navigation
	- Integration with DayNightService
	- Damage on contact

	Exports: Initialize(), SpawnCreature(), DespawnAll()
	Depends: DayNightService, PathfindingService
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config
local AssetManifest = Shared.AssetManifest

local CreatureService = {}

-- Configuration
local CREATURE_CONFIG = {
	ShadowStalker = {
		health = 50,
		speed = 24,
		damage = 15,
		attackRange = 4,
		detectionRange = 60,
		packSize = 3,
		color = Color3.fromRGB(20, 20, 30),
		eyeColor = Color3.fromRGB(255, 80, 20),
		size = Vector3.new(3, 1.5, 5),
	},
	FissureDweller = {
		health = 100,
		speed = 12,
		damage = 25,
		attackRange = 6,
		detectionRange = 40,
		packSize = 1,
		color = Color3.fromRGB(60, 50, 45),
		eyeColor = Color3.fromRGB(200, 255, 80),
		size = Vector3.new(2, 6, 2),
	},
	NightBird = {
		health = 30,
		speed = 35,
		damage = 10,
		attackRange = 5,
		detectionRange = 80,
		packSize = 2,
		color = Color3.fromRGB(15, 15, 20),
		eyeColor = Color3.fromRGB(255, 200, 50),
		size = Vector3.new(4, 1, 2),
	},
}

-- Spawn points (calculated from zones)
local SPAWN_ZONES = {
	ShadowStalker = { "FOREST", "VALLEY" },
	FissureDweller = { "FAULT_LINE" },
	NightBird = { "MOUNTAIN", "FOREST" },
}

-- State
local activeCreatures: { [Model]: CreatureData } = {}
local creaturesFolder: Folder = nil :: any

-- Service references
local DayNightService: any = nil

-- AI States
type AIState = "Idle" | "Hunt" | "Attack" | "Flee" | "Dead"

type CreatureData = {
	model: Model,
	creatureType: string,
	config: typeof(CREATURE_CONFIG.ShadowStalker),
	state: AIState,
	health: number,
	target: Player?,
	lastAttackTime: number,
	pathfinding: Path?,
	spawnPosition: Vector3,
}

-- ==========================================
-- CREATURE MODEL CREATION
-- ==========================================

--[[
	Create a placeholder model when imported assets aren't available.
]]
local function createPlaceholderModel(creatureType: string, config: typeof(CREATURE_CONFIG.ShadowStalker)): Model
	local model = Instance.new("Model")
	model.Name = creatureType

	-- Body (placeholder box)
	local body = Instance.new("Part")
	body.Name = "HumanoidRootPart"
	body.Size = config.size
	body.Anchored = false
	body.CanCollide = true
	body.Color = config.color
	body.Material = Enum.Material.SmoothPlastic
	body.Parent = model

	-- Eyes (glowing)
	local eyeSize = config.size.Y * 0.15
	for _, offset in ipairs({ Vector3.new(config.size.X * 0.3, config.size.Y * 0.3, -config.size.Z * 0.4) }) do
		for side = -1, 1, 2 do
			local eye = Instance.new("Part")
			eye.Name = "Eye"
			eye.Shape = Enum.PartType.Ball
			eye.Size = Vector3.new(eyeSize, eyeSize, eyeSize)
			eye.CFrame = CFrame.new(offset + Vector3.new(side * config.size.X * 0.15, 0, 0))
			eye.Anchored = false
			eye.CanCollide = false
			eye.Color = config.eyeColor
			eye.Material = Enum.Material.Neon
			eye.Parent = model

			-- Weld to body
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = eye
			weld.Parent = eye

			-- Point light for glow
			local light = Instance.new("PointLight")
			light.Color = config.eyeColor
			light.Brightness = 2
			light.Range = 8
			light.Parent = eye
		end
	end

	model.PrimaryPart = body
	return model
end

--[[
	Prepare an imported model for use (add Humanoid, set properties).
]]
local function prepareImportedModel(model: Model, _creatureType: string, _config: typeof(CREATURE_CONFIG.ShadowStalker))
	-- Find or create HumanoidRootPart
	local rootPart = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if not rootPart then
		-- Use first MeshPart or Part as root
		for _, child in model:GetDescendants() do
			if child:IsA("MeshPart") or child:IsA("Part") then
				rootPart = child
				break
			end
		end
	end

	if rootPart then
		rootPart.Name = "HumanoidRootPart"
		rootPart.Anchored = false
		rootPart.CanCollide = true
		model.PrimaryPart = rootPart
	end

	-- Ensure all parts are unanchored
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= rootPart then
			part.Anchored = false
			-- Weld to root if not already connected
			if not part:FindFirstChildOfClass("WeldConstraint") then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = rootPart
				weld.Part1 = part
				weld.Parent = part
			end
		end
	end
end

--[[
	Create a creature model, using imported assets if available.
]]
local function createCreatureModel(creatureType: string, position: Vector3): Model
	local config = CREATURE_CONFIG[creatureType]
	if not config then
		error("[CreatureService] Unknown creature type: " .. creatureType)
	end

	local model: Model

	-- Try to get imported model from AssetManifest
	local importedModel = AssetManifest:CloneAsset(creatureType)
	if importedModel then
		model = importedModel
		prepareImportedModel(model, creatureType, config)
		print(string.format("[CreatureService] Using imported model for %s", creatureType))
	else
		-- Fall back to placeholder
		model = createPlaceholderModel(creatureType, config)
		print(string.format("[CreatureService] Using placeholder model for %s (asset not imported)", creatureType))
	end

	model.Name = creatureType

	-- Position the model
	if model.PrimaryPart then
		model:PivotTo(CFrame.new(position))
	end

	-- Add Humanoid (for pathfinding and health)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.Parent = model
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.MaxHealth = config.health
	humanoid.Health = config.health
	humanoid.WalkSpeed = config.speed

	-- Tags
	CollectionService:AddTag(model, "Creature")
	CollectionService:AddTag(model, creatureType)

	-- Attributes
	model:SetAttribute("CreatureType", creatureType)
	model:SetAttribute("Damage", config.damage)

	return model
end

-- ==========================================
-- AI BEHAVIOR
-- ==========================================

local function findNearestPlayer(position: Vector3, maxRange: number): Player?
	local nearestPlayer: Player? = nil
	local nearestDistance = maxRange

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local rootPart = character:FindFirstChild("HumanoidRootPart")

			if humanoid and humanoid.Health > 0 and rootPart then
				local distance = (rootPart.Position - position).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearestPlayer = player
				end
			end
		end
	end

	return nearestPlayer
end

local function moveToPosition(creatureData: CreatureData, targetPosition: Vector3)
	local model = creatureData.model
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local rootPart = model.PrimaryPart

	if not humanoid or not rootPart then
		return
	end

	-- Simple direct movement (can be upgraded to PathfindingService)
	humanoid:MoveTo(targetPosition)
end

local function attackPlayer(creatureData: CreatureData, player: Player)
	local now = tick()
	if now - creatureData.lastAttackTime < 1.5 then
		return
	end -- Attack cooldown

	creatureData.lastAttackTime = now

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	-- Deal damage
	humanoid:TakeDamage(creatureData.config.damage)

	print(
		string.format(
			"[CreatureService] %s attacked %s for %d damage",
			creatureData.creatureType,
			player.Name,
			creatureData.config.damage
		)
	)
end

local function updateCreatureAI(creatureData: CreatureData)
	local model = creatureData.model
	local rootPart = model.PrimaryPart
	local humanoid = model:FindFirstChildOfClass("Humanoid")

	if not rootPart or not humanoid then
		return
	end
	if humanoid.Health <= 0 then
		creatureData.state = "Dead"
		return
	end

	local position = rootPart.Position
	local config = creatureData.config

	-- State machine
	if creatureData.state == "Idle" then
		-- Look for players
		local target = findNearestPlayer(position, config.detectionRange)
		if target then
			creatureData.target = target
			creatureData.state = "Hunt"
		end
	elseif creatureData.state == "Hunt" then
		local target = creatureData.target
		if not target or not target.Character then
			creatureData.state = "Idle"
			creatureData.target = nil
			return
		end

		local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
		if not targetRoot then
			creatureData.state = "Idle"
			return
		end

		local distance = (targetRoot.Position - position).Magnitude

		-- Lost target?
		if distance > config.detectionRange * 1.5 then
			creatureData.state = "Idle"
			creatureData.target = nil
			return
		end

		-- In attack range?
		if distance <= config.attackRange then
			creatureData.state = "Attack"
		else
			-- Chase
			moveToPosition(creatureData, targetRoot.Position)
		end
	elseif creatureData.state == "Attack" then
		local target = creatureData.target
		if not target or not target.Character then
			creatureData.state = "Idle"
			creatureData.target = nil
			return
		end

		local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
		if not targetRoot then
			creatureData.state = "Idle"
			return
		end

		local distance = (targetRoot.Position - position).Magnitude

		if distance <= config.attackRange then
			attackPlayer(creatureData, target)
		else
			creatureData.state = "Hunt"
		end
	elseif creatureData.state == "Flee" then
		-- Move away from players toward spawn
		moveToPosition(creatureData, creatureData.spawnPosition)

		local distanceToSpawn = (position - creatureData.spawnPosition).Magnitude
		if distanceToSpawn < 10 then
			-- Reached spawn, despawn
			CreatureService:DespawnCreature(model)
		end
	end
	-- Note: "Dead" state is handled by Humanoid.Died connection
end

-- ==========================================
-- SPAWNING
-- ==========================================

local function getRandomSpawnPosition(zones: { string }): Vector3?
	local zoneName = zones[math.random(1, #zones)]
	local zoneConfig = Config.ZONES[zoneName]

	if not zoneConfig then
		return nil
	end

	local x = math.random(-Config.WORLD_SIZE / 4, Config.WORLD_SIZE / 4)
	local z = math.random(zoneConfig.zMin, zoneConfig.zMax)

	-- Get terrain height
	local heightmap = Shared.Heightmap
	local y = 50 -- Default
	if heightmap and heightmap.GetHeight then
		y = heightmap:GetHeight(x, z) + 3
	end

	return Vector3.new(x, y, z)
end

function CreatureService:SpawnCreature(creatureType: string, position: Vector3?): Model?
	local config = CREATURE_CONFIG[creatureType]
	if not config then
		warn("[CreatureService] Unknown creature type:", creatureType)
		return nil
	end

	local spawnPos = position or getRandomSpawnPosition(SPAWN_ZONES[creatureType] or { "FOREST" })
	if not spawnPos then
		return nil
	end

	local model = createCreatureModel(creatureType, spawnPos)
	model.Parent = creaturesFolder

	local creatureData: CreatureData = {
		model = model,
		creatureType = creatureType,
		config = config,
		state = "Idle",
		health = config.health,
		target = nil,
		lastAttackTime = 0,
		pathfinding = nil,
		spawnPosition = spawnPos,
	}

	activeCreatures[model] = creatureData

	-- Handle death
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			creatureData.state = "Dead"
			task.delay(3, function()
				self:DespawnCreature(model)
			end)
		end)
	end

	-- Handle touch damage
	local rootPart = model.PrimaryPart
	if rootPart then
		rootPart.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player and creatureData.state ~= "Dead" and creatureData.state ~= "Flee" then
				attackPlayer(creatureData, player)
			end
		end)
	end

	print(string.format("[CreatureService] Spawned %s at %s", creatureType, tostring(spawnPos)))
	return model
end

function CreatureService:DespawnCreature(model: Model)
	local data = activeCreatures[model]
	if data then
		activeCreatures[model] = nil
	end

	if model and model.Parent then
		model:Destroy()
	end
end

function CreatureService:DespawnAll()
	for model, _ in pairs(activeCreatures) do
		self:DespawnCreature(model)
	end
	print("[CreatureService] All creatures despawned")
end

-- ==========================================
-- NIGHT CYCLE INTEGRATION
-- ==========================================

local function spawnNightCreatures()
	print("[CreatureService] Night has fallen - spawning creatures")

	-- Spawn packs of each type
	for creatureType, config in pairs(CREATURE_CONFIG) do
		local packCount = math.random(2, 4) -- Number of packs

		for _ = 1, packCount do
			local packSize = config.packSize
			local basePosition = getRandomSpawnPosition(SPAWN_ZONES[creatureType] or { "FOREST" })

			if basePosition then
				for _ = 1, packSize do
					-- Offset pack members slightly
					local offset = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
					CreatureService:SpawnCreature(creatureType, basePosition + offset)
				end
			end
		end
	end
end

local function onDawnBreaks()
	print("[CreatureService] Dawn is breaking - creatures fleeing")

	-- Set all creatures to flee
	for _, data in pairs(activeCreatures) do
		if data.state ~= "Dead" then
			data.state = "Flee"
		end
	end

	-- Despawn remaining after delay
	task.delay(30, function()
		CreatureService:DespawnAll()
	end)
end

-- ==========================================
-- UPDATE LOOP
-- ==========================================

local function updateLoop()
	for _, creatureData in pairs(activeCreatures) do
		if creatureData.state ~= "Dead" then
			updateCreatureAI(creatureData)
		end
	end
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function CreatureService:SetDayNightService(service: any)
	DayNightService = service
end

function CreatureService:Initialize()
	-- Create folder
	creaturesFolder = Instance.new("Folder")
	creaturesFolder.Name = "Creatures"
	creaturesFolder.Parent = Workspace

	-- Start AI update loop
	RunService.Heartbeat:Connect(function()
		updateLoop()
	end)

	-- Monitor day/night changes
	task.spawn(function()
		local lastPeriod = ""

		while true do
			task.wait(1)

			if DayNightService then
				local period = DayNightService:GetCurrentPeriod()

				if period ~= lastPeriod then
					if period == "Night" and lastPeriod ~= "Night" then
						spawnNightCreatures()
					elseif period == "Dawn" and lastPeriod == "Night" then
						onDawnBreaks()
					end

					lastPeriod = period
				end
			end
		end
	end)

	print("[CreatureService] Initialized")
	print("[CreatureService] Creature types:", table.concat({ "ShadowStalker", "FissureDweller", "NightBird" }, ", "))
end

-- ==========================================
-- DEBUG
-- ==========================================

function CreatureService:DebugSpawnAll()
	for creatureType, _ in pairs(CREATURE_CONFIG) do
		self:SpawnCreature(creatureType)
	end
end

function CreatureService:GetActiveCount(): number
	local count = 0
	for _, _ in pairs(activeCreatures) do
		count += 1
	end
	return count
end

return CreatureService
