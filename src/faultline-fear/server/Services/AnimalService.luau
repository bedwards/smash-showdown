--!strict
--[[
	Faultline Fear: Animal Service

	Creates and manages wildlife in the world.
	Day animals are passive, night predators are hostile.

	Day Animals (passive, flee from player):
	- Deer: Forest/Valley, grazes and flees
	- Birds: Various zones, perch and fly
	- Rabbits: Beach/Coastal, hop and flee
	- Fish: Ocean, swim in schools

	Night Predators (hostile):
	- Wolves: Pack behavior, howl warning
	- Coyotes: Solo hunters, fast
	- Mountain Lions: Rare, stalking, high damage

	Exports: Initialize(), SpawnDayAnimals(), SpawnNightPredators()
	Depends: Config, Heightmap, DayNightService, AssetManifest
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config
local Heightmap = Shared.Heightmap
local AssetManifest = Shared.AssetManifest
local AssetColors = Shared.AssetColors

local AnimalService = {}

-- External service references
local DayNightService: any = nil

-- State
local animals: { Model } = {}
local animalsFolder: Folder = nil :: any
local lastTimeCheck: string = "DAWN" -- Track period changes

-- Animal type configurations
type AnimalConfig = {
	speed: number,
	fleeSpeed: number,
	detectRange: number,
	hostile: boolean,
	damage: number,
	health: number,
	zones: { string },
	dayOnly: boolean,
	nightOnly: boolean,
	packSize: number?, -- For wolves
}

local ANIMAL_CONFIGS: { [string]: AnimalConfig } = {
	-- Day animals (passive)
	Deer = {
		speed = 8,
		fleeSpeed = 18,
		detectRange = 30,
		hostile = false,
		damage = 0,
		health = 50,
		zones = { "FOREST", "VALLEY" },
		dayOnly = true,
		nightOnly = false,
	},
	Bird = {
		speed = 15,
		fleeSpeed = 25,
		detectRange = 20,
		hostile = false,
		damage = 0,
		health = 10,
		zones = { "FOREST", "COASTAL", "BEACH" },
		dayOnly = true,
		nightOnly = false,
	},
	Rabbit = {
		speed = 12,
		fleeSpeed = 22,
		detectRange = 15,
		hostile = false,
		damage = 0,
		health = 15,
		zones = { "BEACH", "COASTAL" },
		dayOnly = true,
		nightOnly = false,
	},
	Fish = {
		speed = 6,
		fleeSpeed = 10,
		detectRange = 8,
		hostile = false,
		damage = 0,
		health = 5,
		zones = { "BEACH" }, -- Near water
		dayOnly = false, -- Fish are always present
		nightOnly = false,
	},

	-- Night predators (hostile)
	Wolf = {
		speed = 14,
		fleeSpeed = 14,
		detectRange = 50,
		hostile = true,
		damage = 15,
		health = 80,
		zones = { "FOREST", "MOUNTAIN" },
		dayOnly = false,
		nightOnly = true,
		packSize = 3,
	},
	Coyote = {
		speed = 16,
		fleeSpeed = 16,
		detectRange = 40,
		hostile = true,
		damage = 10,
		health = 50,
		zones = { "VALLEY", "FOREST" },
		dayOnly = false,
		nightOnly = true,
	},
	MountainLion = {
		speed = 18,
		fleeSpeed = 18,
		detectRange = 60,
		hostile = true,
		damage = 30,
		health = 120,
		zones = { "MOUNTAIN" },
		dayOnly = false,
		nightOnly = false, -- Can appear any time (rare)
	},
}

-- AI States
type AIState = "Idle" | "Wander" | "Flee" | "Hunt" | "Attack" | "Return"

type AnimalState = {
	state: AIState,
	targetPosition: Vector3?,
	targetPlayer: Player?,
	stateTime: number,
	lastUpdate: number,
}

local animalStates: { [Model]: AnimalState } = {}

-- ==========================================
-- MODEL CREATION
-- ==========================================

local function createPlaceholderAnimal(animalType: string, config: AnimalConfig): Model
	local model = Instance.new("Model")
	model.Name = animalType

	local part = Instance.new("Part")
	part.Name = "HumanoidRootPart"
	part.Anchored = true
	part.CanCollide = false

	-- Size and color based on animal type
	if animalType == "Deer" then
		part.Size = Vector3.new(1.5, 2, 3)
		part.Color = Color3.fromRGB(140, 100, 70)
	elseif animalType == "Bird" then
		part.Size = Vector3.new(0.4, 0.3, 0.5)
		part.Color = Color3.fromRGB(100, 120, 150)
	elseif animalType == "Rabbit" then
		part.Size = Vector3.new(0.5, 0.4, 0.6)
		part.Color = Color3.fromRGB(180, 160, 140)
	elseif animalType == "Fish" then
		part.Size = Vector3.new(0.3, 0.2, 0.6)
		part.Color = Color3.fromRGB(100, 150, 200)
	elseif animalType == "Wolf" then
		part.Size = Vector3.new(1.2, 1.5, 2.5)
		part.Color = Color3.fromRGB(80, 80, 90)
	elseif animalType == "Coyote" then
		part.Size = Vector3.new(1, 1.2, 2)
		part.Color = Color3.fromRGB(150, 120, 90)
	elseif animalType == "MountainLion" then
		part.Size = Vector3.new(1.5, 1.8, 3)
		part.Color = Color3.fromRGB(180, 140, 100)
	else
		part.Size = Vector3.new(1, 1, 1)
		part.Color = Color3.fromRGB(150, 150, 150)
	end

	part.Material = Enum.Material.SmoothPlastic
	part.Parent = model
	model.PrimaryPart = part

	-- Add humanoid for name display
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = animalType
	humanoid.HealthDisplayDistance = 0
	humanoid.NameDisplayDistance = config.hostile and 30 or 20
	humanoid.MaxHealth = config.health
	humanoid.Health = config.health
	humanoid.Parent = model

	return model
end

local function createAnimalModel(animalType: string): Model
	local config = ANIMAL_CONFIGS[animalType]
	if not config then
		warn("[AnimalService] Unknown animal type:", animalType)
		config = ANIMAL_CONFIGS.Deer -- Default
	end

	-- Try imported model first
	local model = AssetManifest:CloneAsset(animalType)

	if model then
		-- Apply colors to imported model (Roblox doesn't import FBX colors)
		AssetColors:ApplyColors(model, animalType)
	else
		model = createPlaceholderAnimal(animalType, config)
	end

	-- Tags
	CollectionService:AddTag(model, "Animal")
	CollectionService:AddTag(model, animalType)
	if config.hostile then
		CollectionService:AddTag(model, "Predator")
	else
		CollectionService:AddTag(model, "Prey")
	end

	-- Attributes
	model:SetAttribute("AnimalType", animalType)
	model:SetAttribute("Hostile", config.hostile)
	model:SetAttribute("Speed", config.speed)
	model:SetAttribute("FleeSpeed", config.fleeSpeed)
	model:SetAttribute("DetectRange", config.detectRange)
	model:SetAttribute("Damage", config.damage)

	return model
end

-- ==========================================
-- SPAWNING
-- ==========================================

local function getRandomPositionInZone(zoneName: string): Vector3?
	local zone = Config.ZONES[zoneName]
	if not zone then
		return nil
	end

	local worldHalfSize = Config.WORLD_SIZE / 2
	local x = math.random(-worldHalfSize * 0.9, worldHalfSize * 0.9)
	local z = zone.zMin + math.random() * (zone.zMax - zone.zMin)

	local y = Heightmap:GetHeight(x, z)

	return Vector3.new(x, y + 1, z)
end

local function spawnAnimal(animalType: string): Model?
	local config = ANIMAL_CONFIGS[animalType]
	if not config then
		return nil
	end

	-- Pick random zone
	local zone = config.zones[math.random(1, #config.zones)]
	local position = getRandomPositionInZone(zone)
	if not position then
		return nil
	end

	local model = createAnimalModel(animalType)
	model:PivotTo(CFrame.new(position))
	model.Parent = animalsFolder

	-- Initialize AI state
	animalStates[model] = {
		state = "Idle",
		targetPosition = nil,
		targetPlayer = nil,
		stateTime = tick(),
		lastUpdate = tick(),
	}

	table.insert(animals, model)
	return model
end

local function despawnAnimal(model: Model)
	-- Remove from tracking
	animalStates[model] = nil
	local index = table.find(animals, model)
	if index then
		table.remove(animals, index)
	end

	-- Destroy model
	model:Destroy()
end

function AnimalService:SpawnDayAnimals()
	print("[AnimalService] Spawning day animals...")

	local animalConfig = Config.ANIMALS

	-- Deer
	for _ = 1, animalConfig.DEER_COUNT do
		spawnAnimal("Deer")
	end

	-- Birds
	for _ = 1, animalConfig.BIRD_COUNT do
		spawnAnimal("Bird")
	end

	-- Rabbits
	for _ = 1, animalConfig.RABBIT_COUNT do
		spawnAnimal("Rabbit")
	end

	-- Fish (always present)
	for _ = 1, animalConfig.FISH_COUNT do
		spawnAnimal("Fish")
	end

	print(
		string.format(
			"[AnimalService] Spawned day animals: %d deer, %d birds, %d rabbits, %d fish",
			animalConfig.DEER_COUNT,
			animalConfig.BIRD_COUNT,
			animalConfig.RABBIT_COUNT,
			animalConfig.FISH_COUNT
		)
	)
end

function AnimalService:SpawnNightPredators()
	print("[AnimalService] Spawning night predators...")

	local animalConfig = Config.ANIMALS

	-- Wolf packs
	for _ = 1, animalConfig.WOLF_PACK_COUNT do
		-- Spawn pack together
		local zone = ANIMAL_CONFIGS.Wolf.zones[math.random(1, #ANIMAL_CONFIGS.Wolf.zones)]
		local packCenter = getRandomPositionInZone(zone)
		if packCenter then
			for _ = 1, animalConfig.WOLF_PACK_SIZE do
				local offset = Vector3.new((math.random() - 0.5) * 10, 0, (math.random() - 0.5) * 10)
				local model = createAnimalModel("Wolf")
				local y = Heightmap:GetHeight(packCenter.X + offset.X, packCenter.Z + offset.Z)
				model:PivotTo(CFrame.new(packCenter.X + offset.X, y + 1, packCenter.Z + offset.Z))
				model.Parent = animalsFolder

				model:SetAttribute("PackId", _)

				animalStates[model] = {
					state = "Idle",
					targetPosition = nil,
					targetPlayer = nil,
					stateTime = tick(),
					lastUpdate = tick(),
				}

				table.insert(animals, model)
			end
		end
	end

	-- Coyotes
	for _ = 1, animalConfig.COYOTE_COUNT do
		spawnAnimal("Coyote")
	end

	print(
		string.format(
			"[AnimalService] Spawned night predators: %d wolf packs (%d wolves), %d coyotes",
			animalConfig.WOLF_PACK_COUNT,
			animalConfig.WOLF_PACK_COUNT * animalConfig.WOLF_PACK_SIZE,
			animalConfig.COYOTE_COUNT
		)
	)
end

function AnimalService:SpawnMountainLions()
	-- Mountain lions can appear any time but are rare
	local animalConfig = Config.ANIMALS

	for _ = 1, animalConfig.MOUNTAIN_LION_COUNT do
		spawnAnimal("MountainLion")
	end

	print(string.format("[AnimalService] Spawned %d mountain lions", animalConfig.MOUNTAIN_LION_COUNT))
end

function AnimalService:DespawnDayAnimals()
	print("[AnimalService] Despawning day animals...")

	local toDespawn = {}
	for _, model in ipairs(animals) do
		local animalType = model:GetAttribute("AnimalType")
		local config = ANIMAL_CONFIGS[animalType]
		if config and config.dayOnly then
			table.insert(toDespawn, model)
		end
	end

	for _, model in ipairs(toDespawn) do
		despawnAnimal(model)
	end

	print(string.format("[AnimalService] Despawned %d day animals", #toDespawn))
end

function AnimalService:DespawnNightPredators()
	print("[AnimalService] Despawning night predators...")

	local toDespawn = {}
	for _, model in ipairs(animals) do
		local animalType = model:GetAttribute("AnimalType")
		local config = ANIMAL_CONFIGS[animalType]
		if config and config.nightOnly then
			table.insert(toDespawn, model)
		end
	end

	for _, model in ipairs(toDespawn) do
		despawnAnimal(model)
	end

	print(string.format("[AnimalService] Despawned %d night predators", #toDespawn))
end

-- ==========================================
-- AI BEHAVIOR
-- ==========================================

local function getNearestPlayer(position: Vector3, maxRange: number): Player?
	local nearestPlayer: Player? = nil
	local nearestDist = maxRange

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then
			continue
		end

		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then
			continue
		end

		local dist = (root.Position - position).Magnitude
		if dist < nearestDist then
			nearestDist = dist
			nearestPlayer = player
		end
	end

	return nearestPlayer
end

local function updateAnimalAI(model: Model, dt: number)
	local state = animalStates[model]
	if not state then
		return
	end
	if not model.PrimaryPart then
		return
	end

	local animalType = model:GetAttribute("AnimalType")
	local config = ANIMAL_CONFIGS[animalType]
	if not config then
		return
	end

	local position = model.PrimaryPart.Position
	local now = tick()
	local stateDuration = now - state.stateTime

	-- Find nearest player
	local nearestPlayer = getNearestPlayer(position, config.detectRange)

	-- State machine
	if config.hostile then
		-- Predator AI
		if state.state == "Idle" then
			if nearestPlayer then
				state.state = "Hunt"
				state.targetPlayer = nearestPlayer
				state.stateTime = now
			elseif stateDuration > 3 then
				-- Start wandering
				state.state = "Wander"
				state.targetPosition = position + Vector3.new((math.random() - 0.5) * 30, 0, (math.random() - 0.5) * 30)
				state.stateTime = now
			end
		elseif state.state == "Wander" then
			if nearestPlayer then
				state.state = "Hunt"
				state.targetPlayer = nearestPlayer
				state.stateTime = now
			elseif state.targetPosition then
				local dist = (position - state.targetPosition).Magnitude
				if dist < 2 or stateDuration > 5 then
					state.state = "Idle"
					state.stateTime = now
				else
					-- Move toward target
					local direction = (state.targetPosition - position).Unit
					local newPos = position + direction * config.speed * dt
					local y = Heightmap:GetHeight(newPos.X, newPos.Z)
					model:PivotTo(CFrame.new(newPos.X, y + 1, newPos.Z))
				end
			end
		elseif state.state == "Hunt" then
			if not nearestPlayer or not nearestPlayer.Character then
				state.state = "Idle"
				state.stateTime = now
			else
				local target = nearestPlayer.Character:FindFirstChild("HumanoidRootPart")
				if target then
					local dist = (target.Position - position).Magnitude
					if dist > config.detectRange * 1.5 then
						-- Lost target
						state.state = "Idle"
						state.stateTime = now
					elseif dist < 3 then
						-- Attack!
						state.state = "Attack"
						state.stateTime = now
					else
						-- Chase
						local direction = (target.Position - position).Unit
						local newPos = position + direction * config.speed * dt
						local y = Heightmap:GetHeight(newPos.X, newPos.Z)
						local lookAt = CFrame.lookAt(
							Vector3.new(newPos.X, y + 1, newPos.Z),
							Vector3.new(target.Position.X, y + 1, target.Position.Z)
						)
						model:PivotTo(lookAt)
					end
				end
			end
		elseif state.state == "Attack" then
			-- Deal damage (simplified)
			if nearestPlayer and nearestPlayer.Character then
				local humanoid = nearestPlayer.Character:FindFirstChildOfClass("Humanoid")
				if humanoid and stateDuration > 1 then
					humanoid:TakeDamage(config.damage)
					state.state = "Hunt"
					state.stateTime = now
				end
			else
				state.state = "Idle"
				state.stateTime = now
			end
		end
	else
		-- Prey AI
		if state.state == "Idle" then
			if nearestPlayer then
				state.state = "Flee"
				state.targetPlayer = nearestPlayer
				state.stateTime = now
			elseif stateDuration > 2 + math.random() * 3 then
				state.state = "Wander"
				state.targetPosition = position + Vector3.new((math.random() - 0.5) * 20, 0, (math.random() - 0.5) * 20)
				state.stateTime = now
			end
		elseif state.state == "Wander" then
			if nearestPlayer then
				state.state = "Flee"
				state.targetPlayer = nearestPlayer
				state.stateTime = now
			elseif state.targetPosition then
				local dist = (position - state.targetPosition).Magnitude
				if dist < 2 or stateDuration > 4 then
					state.state = "Idle"
					state.stateTime = now
				else
					local direction = (state.targetPosition - position).Unit
					local newPos = position + direction * config.speed * dt
					local y = Heightmap:GetHeight(newPos.X, newPos.Z)
					model:PivotTo(CFrame.new(newPos.X, y + 1, newPos.Z))
				end
			end
		elseif state.state == "Flee" then
			if not nearestPlayer or not nearestPlayer.Character then
				state.state = "Idle"
				state.stateTime = now
			else
				local target = nearestPlayer.Character:FindFirstChild("HumanoidRootPart")
				if target then
					local dist = (target.Position - position).Magnitude
					if dist > config.detectRange * 2 then
						-- Safe
						state.state = "Idle"
						state.stateTime = now
					else
						-- Run away
						local awayDirection = (position - target.Position).Unit
						local newPos = position + awayDirection * config.fleeSpeed * dt
						local y = Heightmap:GetHeight(newPos.X, newPos.Z)
						model:PivotTo(CFrame.new(newPos.X, y + 1, newPos.Z))
					end
				end
			end
		end
	end
end

local function updateAllAnimals()
	local dt = 0.016 -- Approximate frame time
	for _, model in ipairs(animals) do
		if model.Parent then
			updateAnimalAI(model, dt)
		end
	end
end

-- ==========================================
-- TIME PERIOD HANDLING
-- ==========================================

local function onTimePeriodChange()
	if not DayNightService then
		return
	end

	local period = DayNightService:GetCurrentPeriod()

	if period ~= lastTimeCheck then
		print(string.format("[AnimalService] Time period changed: %s -> %s", lastTimeCheck, period))

		if period == "DUSK" then
			-- Evening - despawn day animals
			AnimalService:DespawnDayAnimals()
		elseif period == "NIGHT" then
			-- Night - spawn predators
			AnimalService:SpawnNightPredators()
		elseif period == "DAWN" then
			-- Dawn - despawn predators
			AnimalService:DespawnNightPredators()
		elseif period == "DAY" then
			-- Day - spawn day animals
			AnimalService:SpawnDayAnimals()
		end

		lastTimeCheck = period
	end
end

-- ==========================================
-- PUBLIC API
-- ==========================================

function AnimalService:GetAnimals(): { Model }
	return animals
end

function AnimalService:GetAnimalsByType(animalType: string): { Model }
	local result = {}
	for _, model in ipairs(animals) do
		if model:GetAttribute("AnimalType") == animalType then
			table.insert(result, model)
		end
	end
	return result
end

function AnimalService:SetDayNightService(service: any)
	DayNightService = service
end

function AnimalService:Initialize()
	-- Create folder
	animalsFolder = Instance.new("Folder")
	animalsFolder.Name = "Animals"
	animalsFolder.Parent = Workspace

	-- Update loop
	RunService.Heartbeat:Connect(updateAllAnimals)

	-- Check time period regularly
	task.spawn(function()
		while true do
			onTimePeriodChange()
			task.wait(1) -- Check every second
		end
	end)

	-- Initial spawn based on current time
	if DayNightService then
		local period = DayNightService:GetCurrentPeriod()
		lastTimeCheck = period

		if period == "DAY" or period == "DAWN" then
			self:SpawnDayAnimals()
		elseif period == "NIGHT" or period == "DUSK" then
			self:SpawnNightPredators()
		end
	else
		-- Default to day
		self:SpawnDayAnimals()
	end

	-- Mountain lions spawn regardless of time (rare)
	self:SpawnMountainLions()

	print("[AnimalService] Initialized")
end

return AnimalService
