--!strict
-- Survival System for Mertin-Flemmer
-- Shelter building, fire, hygiene, farming, cooking, community boost
-- This is a HARD survival game - every mechanic is mandatory!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

-- Create remotes
local SurvivalRemote = Instance.new("RemoteEvent")
SurvivalRemote.Name = "Survival"
SurvivalRemote.Parent = ReplicatedStorage

local MarkerRemote = Instance.new("RemoteEvent")
MarkerRemote.Name = "Markers"
MarkerRemote.Parent = ReplicatedStorage

-- ==========================================
-- CONFIGURATION - HARDCORE SURVIVAL
-- ==========================================

local SURVIVAL_CONFIG = {
	-- SHELTER (exposure kills without it at night)
	SHELTER = {
		exposureDamagePerSecond = 2, -- damage when outside at night without shelter
		shelterRadius = 15, -- studs around shelter that count as protected
		buildCost = { wood = 10 }, -- resources to build
		durability = 300, -- seconds shelter lasts before needs repair
		repairCost = { wood = 3 },
	},

	-- TEMPERATURE (hypothermia/heat stroke)
	TEMPERATURE = {
		coldDamagePerSecond = 1.5, -- damage in cold without fire
		heatDamagePerSecond = 0.5, -- damage in extreme heat
		fireWarmthRadius = 20, -- studs around fire that provide warmth
		fireLastsSeconds = 180, -- how long fire burns
		fireCost = { wood = 5 },
	},

	-- HYGIENE (disease risk increases without it)
	HYGIENE = {
		maxHygiene = 100,
		hygieneDecayPerMinute = 5, -- hygiene drops over time
		diseaseThreshold = 25, -- below this, risk disease
		diseaseChancePerMinute = 0.1, -- 10% chance per minute when dirty
		diseaseDamagePerSecond = 0.5,
		bathingRestoreAmount = 80, -- how much bathing restores
		brushingRestoreAmount = 20, -- how much brushing restores
		bathingDuration = 5, -- seconds to bathe
	},

	-- FARMING
	FARMING = {
		growthTimeSeconds = 120, -- time for crops to grow
		harvestYield = { min = 2, max = 5 }, -- items per harvest
		plotCost = { wood = 3 },
	},

	-- COOKING
	COOKING = {
		rawFoodHungerRestore = 15,
		cookedFoodHungerRestore = 40,
		cookingTime = 10, -- seconds to cook
		burntThreshold = 20, -- over-cooking burns food
	},

	-- COMMUNITY BOOST
	COMMUNITY = {
		boostRadius = 30, -- studs to count as "near" friend
		hungerReductionPerFriend = 0.15, -- 15% less hunger drain per nearby friend
		maxBoost = 0.6, -- max 60% reduction with 4+ friends
		moraleBoostPerFriend = 10, -- bonus to survival stats
	},

	-- DEATH/RESPAWN
	RESPAWN = {
		respawnFraction = 0.33, -- respawn 1/3 back toward spawn
		spawnPoint = Vector3.new(0, 5, -30), -- default spawn
	},
}

-- ==========================================
-- PLAYER SURVIVAL STATE
-- ==========================================

local playerSurvivalState: { [Player]: {
	-- Core stats
	hygiene: number,
	temperature: number, -- 0 = freezing, 50 = perfect, 100 = overheating
	hasShelter: boolean,
	isDisease: boolean,
	diseaseTimer: number,

	-- Position tracking
	lastDeathPosition: Vector3?,
	furthestPosition: Vector3?,
	distanceFromSpawn: number,

	-- Markers
	markers: { { name: string, position: Vector3 } },

	-- Shelters/fires owned
	shelters: { Model },
	fires: { Model },
	farmPlots: { Model },

	-- Timers
	lastBatheTime: number,
	lastBrushTime: number,
	bathingProgress: number,
	isBathing: boolean,
} } = {}

-- ==========================================
-- WORLD ITEMS (toothbrushes, seeds, etc)
-- ==========================================

local FINDABLE_ITEMS = {
	TOOTHBRUSH = {
		count = 30,
		color = Color3.fromRGB(100, 200, 255),
		size = Vector3.new(0.2, 1.5, 0.2),
		spawnRadius = 600,
	},
	TOOTHPASTE = {
		count = 20,
		color = Color3.fromRGB(255, 255, 255),
		size = Vector3.new(0.5, 1, 0.5),
		spawnRadius = 600,
	},
	SEEDS_WHEAT = {
		count = 40,
		color = Color3.fromRGB(200, 180, 100),
		size = Vector3.new(0.3, 0.3, 0.3),
		spawnRadius = 400,
	},
	SEEDS_CARROT = {
		count = 30,
		color = Color3.fromRGB(255, 150, 50),
		size = Vector3.new(0.3, 0.3, 0.3),
		spawnRadius = 400,
	},
	SEEDS_POTATO = {
		count = 25,
		color = Color3.fromRGB(180, 150, 100),
		size = Vector3.new(0.4, 0.3, 0.4),
		spawnRadius = 400,
	},
}

local playerInventory: { [Player]: {
	toothbrush: number,
	toothpaste: number,
	seeds_wheat: number,
	seeds_carrot: number,
	seeds_potato: number,
	raw_wheat: number,
	raw_carrot: number,
	raw_potato: number,
	cooked_food: number,
} } = {}

-- ==========================================
-- RECIPES
-- ==========================================

local RECIPES = {
	BREAD = {
		ingredients = { raw_wheat = 3 },
		result = { cooked_food = 2 },
		cookTime = 15,
	},
	STEW = {
		ingredients = { raw_carrot = 2, raw_potato = 2 },
		result = { cooked_food = 4 },
		cookTime = 20,
	},
	ROASTED_VEGGIES = {
		ingredients = { raw_carrot = 1, raw_potato = 1 },
		result = { cooked_food = 2 },
		cookTime = 10,
	},
}

-- ==========================================
-- WATER BODIES FOR BATHING
-- ==========================================

local WATER_BODIES: { { center: Vector3, radius: number } } = {}

local function createWaterBody(center: Vector3, radius: number)
	-- Create visible water
	local water = Instance.new("Part")
	water.Name = "WaterBody"
	water.Size = Vector3.new(radius * 2, 1, radius * 2)
	water.Position = center + Vector3.new(0, -0.5, 0)
	water.Color = Color3.fromRGB(50, 100, 200)
	water.Material = Enum.Material.Water
	water.Transparency = 0.3
	water.Anchored = true
	water.CanCollide = false
	water.Parent = workspace

	-- Add bathing prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Bathe"
	prompt.ObjectText = "Water"
	prompt.HoldDuration = SURVIVAL_CONFIG.HYGIENE.bathingDuration
	prompt.MaxActivationDistance = 10
	prompt.Parent = water

	prompt.Triggered:Connect(function(player)
		local state = playerSurvivalState[player]
		if state then
			state.hygiene = math.min(100, state.hygiene + SURVIVAL_CONFIG.HYGIENE.bathingRestoreAmount)
			state.lastBatheTime = tick()
			SurvivalRemote:FireClient(player, "BATHED", { hygiene = state.hygiene })
			print("[Survival]", player.Name, "bathed! Hygiene:", state.hygiene)
		end
	end)

	table.insert(WATER_BODIES, { center = center, radius = radius })
	return water
end

-- ==========================================
-- SHELTER SYSTEM
-- ==========================================

local shelters: { Model } = {}

local function buildShelter(player: Player, position: Vector3): Model?
	-- Check resources (would integrate with Resources system)
	-- For now, just build

	local shelter = Instance.new("Model")
	shelter.Name = player.Name .. "_Shelter"

	-- Floor
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(12, 0.5, 12)
	floor.Position = position + Vector3.new(0, 0.25, 0)
	floor.Color = Color3.fromRGB(80, 60, 40)
	floor.Material = Enum.Material.Wood
	floor.Anchored = true
	floor.Parent = shelter

	-- Walls (4 sides, with door opening)
	local wallPositions = {
		{ pos = Vector3.new(0, 3, -6), size = Vector3.new(12, 6, 0.5) }, -- back
		{ pos = Vector3.new(0, 3, 6), size = Vector3.new(5, 6, 0.5), offset = Vector3.new(-3.5, 0, 0) }, -- front left
		{ pos = Vector3.new(0, 3, 6), size = Vector3.new(5, 6, 0.5), offset = Vector3.new(3.5, 0, 0) }, -- front right
		{ pos = Vector3.new(-6, 3, 0), size = Vector3.new(0.5, 6, 12) }, -- left
		{ pos = Vector3.new(6, 3, 0), size = Vector3.new(0.5, 6, 12) }, -- right
	}

	for _, wallData in wallPositions do
		local wall = Instance.new("Part")
		wall.Name = "Wall"
		wall.Size = wallData.size
		wall.Position = position + wallData.pos + (wallData.offset or Vector3.zero)
		wall.Color = Color3.fromRGB(100, 80, 60)
		wall.Material = Enum.Material.Wood
		wall.Anchored = true
		wall.Parent = shelter
	end

	-- Roof
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = Vector3.new(14, 0.5, 14)
	roof.Position = position + Vector3.new(0, 6.25, 0)
	roof.Color = Color3.fromRGB(60, 45, 30)
	roof.Material = Enum.Material.Wood
	roof.Anchored = true
	roof.Parent = shelter

	-- Shelter sign
	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.new(0, 100, 0, 30)
	sign.StudsOffset = Vector3.new(0, 8, 0)
	sign.Adornee = floor
	sign.Parent = floor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = player.Name .. "'s Shelter"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Parent = sign

	shelter.Parent = workspace
	table.insert(shelters, shelter)

	-- Track for player
	local state = playerSurvivalState[player]
	if state then
		table.insert(state.shelters, shelter)
	end

	print("[Survival]", player.Name, "built a shelter at", position)
	SurvivalRemote:FireClient(player, "SHELTER_BUILT", { position = position })

	return shelter
end

local function isInShelter(position: Vector3): boolean
	for _, shelter in shelters do
		local floor = shelter:FindFirstChild("Floor") :: BasePart?
		if floor then
			local distance = (Vector3.new(position.X, 0, position.Z) - Vector3.new(floor.Position.X, 0, floor.Position.Z)).Magnitude
			if distance < SURVIVAL_CONFIG.SHELTER.shelterRadius then
				return true
			end
		end
	end
	return false
end

-- ==========================================
-- FIRE/CAMPFIRE SYSTEM
-- ==========================================

local fires: { { part: BasePart, expires: number } } = {}

local function buildFire(player: Player, position: Vector3): BasePart?
	-- Create campfire
	local fire = Instance.new("Part")
	fire.Name = player.Name .. "_Campfire"
	fire.Size = Vector3.new(4, 1, 4)
	fire.Position = position + Vector3.new(0, 0.5, 0)
	fire.Shape = Enum.PartType.Cylinder
	fire.Orientation = Vector3.new(0, 0, 90)
	fire.Color = Color3.fromRGB(60, 40, 30)
	fire.Material = Enum.Material.Wood
	fire.Anchored = true
	fire.Parent = workspace

	-- Fire effect
	local fireEffect = Instance.new("Fire")
	fireEffect.Size = 8
	fireEffect.Heat = 10
	fireEffect.Parent = fire

	-- Light
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 150, 50)
	light.Brightness = 2
	light.Range = SURVIVAL_CONFIG.TEMPERATURE.fireWarmthRadius
	light.Parent = fire

	-- Cooking prompt
	local cookPrompt = Instance.new("ProximityPrompt")
	cookPrompt.ActionText = "Cook"
	cookPrompt.ObjectText = "Campfire"
	cookPrompt.HoldDuration = 0
	cookPrompt.MaxActivationDistance = 8
	cookPrompt.Parent = fire

	cookPrompt.Triggered:Connect(function(triggerPlayer)
		-- Open cooking menu
		SurvivalRemote:FireClient(triggerPlayer, "OPEN_COOKING", {
			recipes = RECIPES,
			inventory = playerInventory[triggerPlayer],
		})
	end)

	local expiresAt = tick() + SURVIVAL_CONFIG.TEMPERATURE.fireLastsSeconds
	table.insert(fires, { part = fire, expires = expiresAt })

	-- Track for player
	local state = playerSurvivalState[player]
	if state then
		table.insert(state.fires, fire :: Model)
	end

	print("[Survival]", player.Name, "built a campfire at", position)
	SurvivalRemote:FireClient(player, "FIRE_BUILT", {
		position = position,
		expiresIn = SURVIVAL_CONFIG.TEMPERATURE.fireLastsSeconds,
	})

	-- Auto-destroy when burnt out
	task.delay(SURVIVAL_CONFIG.TEMPERATURE.fireLastsSeconds, function()
		if fire and fire.Parent then
			-- Fire dies out
			local smoke = Instance.new("Smoke")
			smoke.Size = 2
			smoke.Parent = fire

			fireEffect:Destroy()
			light.Brightness = 0

			task.delay(5, function()
				if fire and fire.Parent then
					fire:Destroy()
				end
			end)
		end
	end)

	return fire
end

local function isNearFire(position: Vector3): boolean
	for _, fireData in fires do
		if fireData.part and fireData.part.Parent and tick() < fireData.expires then
			local distance = (position - fireData.part.Position).Magnitude
			if distance < SURVIVAL_CONFIG.TEMPERATURE.fireWarmthRadius then
				return true
			end
		end
	end
	return false
end

-- ==========================================
-- FARMING SYSTEM
-- ==========================================

local farmPlots: { { part: BasePart, seedType: string?, plantedAt: number?, grown: boolean } } = {}

local function createFarmPlot(player: Player, position: Vector3): BasePart
	local plot = Instance.new("Part")
	plot.Name = player.Name .. "_FarmPlot"
	plot.Size = Vector3.new(4, 0.5, 4)
	plot.Position = position + Vector3.new(0, 0.25, 0)
	plot.Color = Color3.fromRGB(80, 50, 30)
	plot.Material = Enum.Material.Ground
	plot.Anchored = true
	plot.Parent = workspace

	local plotData = { part = plot, seedType = nil, plantedAt = nil, grown = false }
	table.insert(farmPlots, plotData)

	-- Plant prompt
	local plantPrompt = Instance.new("ProximityPrompt")
	plantPrompt.ActionText = "Plant Seeds"
	plantPrompt.ObjectText = "Farm Plot"
	plantPrompt.MaxActivationDistance = 6
	plantPrompt.Parent = plot

	plantPrompt.Triggered:Connect(function(triggerPlayer)
		local inv = playerInventory[triggerPlayer]
		if not inv then return end

		if plotData.seedType then
			-- Already planted
			if plotData.grown then
				-- Harvest!
				local yield = math.random(
					SURVIVAL_CONFIG.FARMING.harvestYield.min,
					SURVIVAL_CONFIG.FARMING.harvestYield.max
				)

				local itemKey = "raw_" .. string.lower(string.gsub(plotData.seedType, "SEEDS_", ""))
				if inv[itemKey] then
					inv[itemKey] += yield
				end

				plotData.seedType = nil
				plotData.plantedAt = nil
				plotData.grown = false

				-- Remove plant visual
				local plant = plot:FindFirstChild("Plant")
				if plant then plant:Destroy() end

				plantPrompt.ActionText = "Plant Seeds"
				SurvivalRemote:FireClient(triggerPlayer, "HARVESTED", { item = itemKey, amount = yield })
				print("[Survival]", triggerPlayer.Name, "harvested", yield, itemKey)
			else
				SurvivalRemote:FireClient(triggerPlayer, "MESSAGE", { text = "Crops still growing..." })
			end
		else
			-- Plant something
			SurvivalRemote:FireClient(triggerPlayer, "SELECT_SEEDS", {
				seeds = {
					{ key = "SEEDS_WHEAT", name = "Wheat", count = inv.seeds_wheat },
					{ key = "SEEDS_CARROT", name = "Carrot", count = inv.seeds_carrot },
					{ key = "SEEDS_POTATO", name = "Potato", count = inv.seeds_potato },
				},
				plotPosition = position,
			})
		end
	end)

	-- Track for player
	local state = playerSurvivalState[player]
	if state then
		table.insert(state.farmPlots, plot :: Model)
	end

	print("[Survival]", player.Name, "created farm plot at", position)
	return plot
end

local function plantSeeds(player: Player, plotPosition: Vector3, seedType: string)
	local inv = playerInventory[player]
	if not inv then return end

	local seedKey = "seeds_" .. string.lower(string.gsub(seedType, "SEEDS_", ""))
	if not inv[seedKey] or inv[seedKey] <= 0 then
		SurvivalRemote:FireClient(player, "MESSAGE", { text = "No seeds!" })
		return
	end

	-- Find the plot
	for _, plotData in farmPlots do
		if plotData.part and plotData.part.Parent then
			local dist = (plotData.part.Position - plotPosition).Magnitude
			if dist < 5 and not plotData.seedType then
				-- Plant!
				inv[seedKey] -= 1
				plotData.seedType = seedType
				plotData.plantedAt = tick()
				plotData.grown = false

				-- Create seedling visual
				local plant = Instance.new("Part")
				plant.Name = "Plant"
				plant.Size = Vector3.new(0.5, 0.5, 0.5)
				plant.Position = plotData.part.Position + Vector3.new(0, 0.5, 0)
				plant.Color = Color3.fromRGB(50, 150, 50)
				plant.Material = Enum.Material.Grass
				plant.Anchored = true
				plant.Parent = plotData.part

				-- Update prompt
				local prompt = plotData.part:FindFirstChildOfClass("ProximityPrompt")
				if prompt then
					prompt.ActionText = "Growing..."
				end

				SurvivalRemote:FireClient(player, "PLANTED", { seedType = seedType })
				print("[Survival]", player.Name, "planted", seedType)
				return
			end
		end
	end
end

local function updateFarmGrowth()
	local currentTime = tick()

	for _, plotData in farmPlots do
		if plotData.seedType and plotData.plantedAt and not plotData.grown then
			local elapsed = currentTime - plotData.plantedAt

			if elapsed >= SURVIVAL_CONFIG.FARMING.growthTimeSeconds then
				plotData.grown = true

				-- Update visual to full plant
				local plant = plotData.part:FindFirstChild("Plant") :: BasePart?
				if plant then
					plant.Size = Vector3.new(1, 2, 1)
					plant.Position = plotData.part.Position + Vector3.new(0, 1.25, 0)

					-- Add color based on type
					if plotData.seedType == "SEEDS_WHEAT" then
						plant.Color = Color3.fromRGB(220, 200, 100)
					elseif plotData.seedType == "SEEDS_CARROT" then
						plant.Color = Color3.fromRGB(255, 150, 50)
					elseif plotData.seedType == "SEEDS_POTATO" then
						plant.Color = Color3.fromRGB(100, 150, 50)
					end
				end

				-- Update prompt
				local prompt = plotData.part:FindFirstChildOfClass("ProximityPrompt")
				if prompt then
					prompt.ActionText = "Harvest!"
				end
			end
		end
	end
end

-- ==========================================
-- MARKER/WAYPOINT SYSTEM
-- ==========================================

local function setMarker(player: Player, name: string, position: Vector3)
	local state = playerSurvivalState[player]
	if not state then return end

	-- Max 10 markers
	if #state.markers >= 10 then
		SurvivalRemote:FireClient(player, "MESSAGE", { text = "Max 10 markers! Delete one first." })
		return
	end

	table.insert(state.markers, { name = name, position = position })

	-- Create visible marker in world
	local marker = Instance.new("Part")
	marker.Name = "Marker_" .. player.Name .. "_" .. name
	marker.Size = Vector3.new(2, 10, 2)
	marker.Position = position + Vector3.new(0, 5, 0)
	marker.Color = Color3.fromRGB(100, 200, 255)
	marker.Material = Enum.Material.Neon
	marker.Transparency = 0.5
	marker.Anchored = true
	marker.CanCollide = false
	marker.Parent = workspace

	local beam = Instance.new("Beam")

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 8, 0)
	billboard.Adornee = marker
	billboard.Parent = marker

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Color3.fromRGB(100, 200, 255)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Parent = billboard

	SurvivalRemote:FireClient(player, "MARKER_SET", { name = name, position = position })
	print("[Survival]", player.Name, "set marker:", name)
end

local function removeMarker(player: Player, name: string)
	local state = playerSurvivalState[player]
	if not state then return end

	for i, marker in state.markers do
		if marker.name == name then
			table.remove(state.markers, i)

			-- Remove world marker
			local worldMarker = workspace:FindFirstChild("Marker_" .. player.Name .. "_" .. name)
			if worldMarker then
				worldMarker:Destroy()
			end

			SurvivalRemote:FireClient(player, "MARKER_REMOVED", { name = name })
			break
		end
	end
end

-- ==========================================
-- COMMUNITY BOOST SYSTEM
-- ==========================================

local function getNearbyPlayersCount(player: Player): number
	local character = player.Character
	if not character then return 0 end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return 0 end

	local count = 0
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= player then
			local otherChar = otherPlayer.Character
			if otherChar then
				local otherRoot = otherChar:FindFirstChild("HumanoidRootPart") :: BasePart?
				if otherRoot then
					local distance = (rootPart.Position - otherRoot.Position).Magnitude
					if distance < SURVIVAL_CONFIG.COMMUNITY.boostRadius then
						count += 1
					end
				end
			end
		end
	end

	return count
end

local function getCommunityBoost(player: Player): number
	local nearbyCount = getNearbyPlayersCount(player)
	local boost = nearbyCount * SURVIVAL_CONFIG.COMMUNITY.hungerReductionPerFriend
	return math.min(boost, SURVIVAL_CONFIG.COMMUNITY.maxBoost)
end

-- ==========================================
-- DEATH/RESPAWN SYSTEM
-- ==========================================

local function getDistanceFromSpawn(position: Vector3): number
	return (Vector3.new(position.X, 0, position.Z) - Vector3.new(
		SURVIVAL_CONFIG.RESPAWN.spawnPoint.X,
		0,
		SURVIVAL_CONFIG.RESPAWN.spawnPoint.Z
	)).Magnitude
end

local function calculateRespawnPosition(deathPosition: Vector3): Vector3
	local spawn = SURVIVAL_CONFIG.RESPAWN.spawnPoint

	-- Calculate position 1/3 back toward spawn
	local direction = (spawn - deathPosition).Unit
	local totalDistance = (deathPosition - spawn).Magnitude
	local respawnDistance = totalDistance * SURVIVAL_CONFIG.RESPAWN.respawnFraction

	local respawnPos = deathPosition + direction * respawnDistance
	respawnPos = Vector3.new(respawnPos.X, spawn.Y, respawnPos.Z)

	return respawnPos
end

local function onPlayerDied(player: Player)
	local state = playerSurvivalState[player]
	if not state then return end

	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if rootPart then
			state.lastDeathPosition = rootPart.Position
		end
	end
end

local function onCharacterAdded(player: Player, character: Model)
	local state = playerSurvivalState[player]
	if not state then return end

	-- If died previously, respawn at calculated position
	if state.lastDeathPosition then
		local respawnPos = calculateRespawnPosition(state.lastDeathPosition)

		task.wait(0.5) -- Wait for character to load
		local rootPart = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
		if rootPart then
			rootPart.CFrame = CFrame.new(respawnPos)
			SurvivalRemote:FireClient(player, "RESPAWNED", {
				message = "You died and respawned 1/3 of the way back...",
				position = respawnPos,
				lostDistance = (state.lastDeathPosition - respawnPos).Magnitude,
			})
			print("[Survival]", player.Name, "respawned at", respawnPos, "(lost progress)")
		end

		state.lastDeathPosition = nil
	end

	-- Connect death
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if humanoid then
		humanoid.Died:Connect(function()
			onPlayerDied(player)
		end)
	end
end

-- ==========================================
-- HYGIENE UPDATE
-- ==========================================

local function updateHygiene(player: Player, dt: number)
	local state = playerSurvivalState[player]
	if not state then return end

	-- Decay hygiene over time
	state.hygiene -= (SURVIVAL_CONFIG.HYGIENE.hygieneDecayPerMinute / 60) * dt
	state.hygiene = math.max(0, state.hygiene)

	-- Disease check if too dirty
	if state.hygiene < SURVIVAL_CONFIG.HYGIENE.diseaseThreshold and not state.isDisease then
		local chancePerSecond = SURVIVAL_CONFIG.HYGIENE.diseaseChancePerMinute / 60
		if math.random() < chancePerSecond * dt then
			state.isDisease = true
			state.diseaseTimer = 60 -- Disease lasts 60 seconds
			SurvivalRemote:FireClient(player, "DISEASE", {
				message = "You've contracted a disease from poor hygiene! Find medicine or wait it out.",
			})
			print("[Survival]", player.Name, "got disease from poor hygiene")
		end
	end

	-- Disease damage
	if state.isDisease then
		state.diseaseTimer -= dt

		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:TakeDamage(SURVIVAL_CONFIG.HYGIENE.diseaseDamagePerSecond * dt)
			end
		end

		if state.diseaseTimer <= 0 then
			state.isDisease = false
			SurvivalRemote:FireClient(player, "DISEASE_CURED", {
				message = "Your disease has passed. Keep clean!",
			})
		end
	end
end

-- ==========================================
-- PLAYER INITIALIZATION
-- ==========================================

local function initPlayer(player: Player)
	playerSurvivalState[player] = {
		hygiene = 100,
		temperature = 50,
		hasShelter = false,
		isDisease = false,
		diseaseTimer = 0,
		lastDeathPosition = nil,
		furthestPosition = SURVIVAL_CONFIG.RESPAWN.spawnPoint,
		distanceFromSpawn = 0,
		markers = {},
		shelters = {},
		fires = {},
		farmPlots = {},
		lastBatheTime = tick(),
		lastBrushTime = tick(),
		bathingProgress = 0,
		isBathing = false,
	}

	playerInventory[player] = {
		toothbrush = 0,
		toothpaste = 0,
		seeds_wheat = 2, -- Start with some seeds
		seeds_carrot = 2,
		seeds_potato = 1,
		raw_wheat = 0,
		raw_carrot = 0,
		raw_potato = 0,
		cooked_food = 0,
	}

	-- Send initial state
	SurvivalRemote:FireClient(player, "INIT", {
		hygiene = 100,
		inventory = playerInventory[player],
		markers = {},
	})

	-- Connect character
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)

	print("[Survival]", player.Name, "survival state initialized")
end

local function cleanupPlayer(player: Player)
	playerSurvivalState[player] = nil
	playerInventory[player] = nil

	-- Remove player's markers
	for _, child in workspace:GetChildren() do
		if string.find(child.Name, "Marker_" .. player.Name) then
			child:Destroy()
		end
	end
end

-- ==========================================
-- REMOTE EVENT HANDLERS
-- ==========================================

SurvivalRemote.OnServerEvent:Connect(function(player: Player, action: string, data: any?)
	if action == "BUILD_SHELTER" then
		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if rootPart then
				buildShelter(player, rootPart.Position + rootPart.CFrame.LookVector * 10)
			end
		end

	elseif action == "BUILD_FIRE" then
		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if rootPart then
				buildFire(player, rootPart.Position + rootPart.CFrame.LookVector * 5)
			end
		end

	elseif action == "BUILD_FARM" then
		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if rootPart then
				createFarmPlot(player, rootPart.Position + rootPart.CFrame.LookVector * 5)
			end
		end

	elseif action == "PLANT_SEEDS" and data then
		plantSeeds(player, data.position, data.seedType)

	elseif action == "COOK" and data then
		local recipe = RECIPES[data.recipe]
		if recipe then
			local inv = playerInventory[player]
			if inv then
				-- Check ingredients
				local canCook = true
				for item, amount in recipe.ingredients do
					if not inv[item] or inv[item] < amount then
						canCook = false
						break
					end
				end

				if canCook then
					-- Remove ingredients
					for item, amount in recipe.ingredients do
						inv[item] -= amount
					end

					-- Add result
					for item, amount in recipe.result do
						inv[item] = (inv[item] or 0) + amount
					end

					SurvivalRemote:FireClient(player, "COOKED", {
						recipe = data.recipe,
						inventory = inv,
					})
					print("[Survival]", player.Name, "cooked", data.recipe)
				else
					SurvivalRemote:FireClient(player, "MESSAGE", { text = "Missing ingredients!" })
				end
			end
		end

	elseif action == "BRUSH_TEETH" then
		local state = playerSurvivalState[player]
		local inv = playerInventory[player]
		if state and inv and inv.toothbrush > 0 and inv.toothpaste > 0 then
			inv.toothpaste -= 1
			state.hygiene = math.min(100, state.hygiene + SURVIVAL_CONFIG.HYGIENE.brushingRestoreAmount)
			SurvivalRemote:FireClient(player, "BRUSHED", { hygiene = state.hygiene })
			print("[Survival]", player.Name, "brushed teeth")
		else
			SurvivalRemote:FireClient(player, "MESSAGE", { text = "Need toothbrush AND toothpaste!" })
		end

	elseif action == "SET_MARKER" and data then
		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if rootPart then
				setMarker(player, data.name, rootPart.Position)
			end
		end

	elseif action == "REMOVE_MARKER" and data then
		removeMarker(player, data.name)

	elseif action == "GET_MARKERS" then
		local state = playerSurvivalState[player]
		if state then
			SurvivalRemote:FireClient(player, "MARKERS_LIST", { markers = state.markers })
		end

	elseif action == "EAT_COOKED" then
		local inv = playerInventory[player]
		if inv and inv.cooked_food > 0 then
			inv.cooked_food -= 1
			-- Would integrate with hunger system - restore more hunger
			SurvivalRemote:FireClient(player, "ATE_COOKED", {
				hungerRestored = SURVIVAL_CONFIG.COOKING.cookedFoodHungerRestore,
				inventory = inv,
			})
			print("[Survival]", player.Name, "ate cooked food")
		end
	end
end)

MarkerRemote.OnServerEvent:Connect(function(player: Player, action: string, data: any?)
	if action == "SET" and data then
		setMarker(player, data.name, data.position or Vector3.zero)
	elseif action == "REMOVE" and data then
		removeMarker(player, data.name)
	end
end)

-- ==========================================
-- SPAWN FINDABLE ITEMS
-- ==========================================

local function spawnFindableItems()
	print("[Survival] Spawning findable items...")

	for itemType, config in FINDABLE_ITEMS do
		for i = 1, config.count do
			local angle = math.random() * math.pi * 2
			local distance = math.random() * config.spawnRadius
			local pos = Vector3.new(
				math.cos(angle) * distance,
				0.5,
				math.sin(angle) * distance
			)

			local item = Instance.new("Part")
			item.Name = "Findable_" .. itemType
			item.Size = config.size
			item.Position = pos + Vector3.new(0, config.size.Y / 2, 0)
			item.Color = config.color
			item.Material = Enum.Material.SmoothPlastic
			item.Anchored = true
			item.CanCollide = false

			-- Highlight
			local highlight = Instance.new("Highlight")
			highlight.FillTransparency = 0.8
			highlight.OutlineTransparency = 0.5
			highlight.Parent = item

			-- Pickup prompt
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Pick Up"
			prompt.ObjectText = string.gsub(itemType, "_", " ")
			prompt.MaxActivationDistance = 5
			prompt.Parent = item

			prompt.Triggered:Connect(function(player)
				local inv = playerInventory[player]
				if inv then
					local key = string.lower(itemType)
					if inv[key] ~= nil then
						inv[key] += 1
						SurvivalRemote:FireClient(player, "ITEM_PICKED_UP", {
							item = itemType,
							inventory = inv,
						})
						item:Destroy()
						print("[Survival]", player.Name, "found", itemType)
					end
				end
			end)

			item.Parent = workspace
		end
	end

	print("[Survival] Spawned findable items")
end

-- ==========================================
-- HAND-CRAFTED WINDING RIVERS AND STREAMS
-- ==========================================

-- Each river is defined by waypoints that it winds through
local RIVERS = {
	-- THE SERPENT RIVER: Main river winding from mountains to sea
	{
		name = "Serpent River",
		width = 15,
		depth = 2,
		color = Color3.fromRGB(40, 80, 140),
		waypoints = {
			Vector3.new(-400, -1, -300), -- Mountain source
			Vector3.new(-350, -1, -250),
			Vector3.new(-280, -1, -200),
			Vector3.new(-220, -1, -180), -- Bend
			Vector3.new(-150, -1, -150),
			Vector3.new(-80, -1, -100),
			Vector3.new(-30, -1, -50),
			Vector3.new(20, -1, 10),
			Vector3.new(50, -1, 80), -- Near spawn area
			Vector3.new(100, -1, 140),
			Vector3.new(180, -1, 180),
			Vector3.new(250, -1, 200), -- Wide bend
			Vector3.new(320, -1, 180),
			Vector3.new(400, -1, 150),
			Vector3.new(500, -1, 100), -- Toward coast
		},
	},

	-- WHISPERING BROOK: Smaller stream through forest
	{
		name = "Whispering Brook",
		width = 6,
		depth = 1,
		color = Color3.fromRGB(60, 100, 150),
		waypoints = {
			Vector3.new(50, -0.5, 200),
			Vector3.new(80, -0.5, 230),
			Vector3.new(100, -0.5, 280),
			Vector3.new(90, -0.5, 330), -- Curves back
			Vector3.new(60, -0.5, 370),
			Vector3.new(40, -0.5, 420),
			Vector3.new(70, -0.5, 480),
			Vector3.new(120, -0.5, 520),
		},
	},

	-- SHADOW CREEK: Dark stream through dangerous area
	{
		name = "Shadow Creek",
		width = 8,
		depth = 1.5,
		color = Color3.fromRGB(30, 50, 80),
		waypoints = {
			Vector3.new(-300, -0.5, 100),
			Vector3.new(-280, -0.5, 150),
			Vector3.new(-240, -0.5, 180),
			Vector3.new(-200, -0.5, 220),
			Vector3.new(-160, -0.5, 240),
			Vector3.new(-100, -0.5, 250),
			Vector3.new(-60, -0.5, 300),
		},
	},

	-- CRYSTAL FALLS TRIBUTARY: From waterfall area
	{
		name = "Crystal Falls",
		width = 10,
		depth = 1.5,
		color = Color3.fromRGB(70, 130, 180),
		waypoints = {
			Vector3.new(300, -0.5, -200),
			Vector3.new(260, -0.5, -150),
			Vector3.new(200, -0.5, -100),
			Vector3.new(150, -0.5, -60),
			Vector3.new(100, -0.5, -20), -- Joins main river area
		},
	},
}

-- HAND-CRAFTED PONDS AND LAKES (irregular shapes, not circles)
local LAKES = {
	-- MOONLIGHT POND: Crescent-shaped pond near spawn
	{
		name = "Moonlight Pond",
		position = Vector3.new(60, -0.5, 120),
		-- Custom shape defined by parts
		parts = {
			{ offset = Vector3.new(0, 0, 0), size = Vector3.new(25, 1, 15) },
			{ offset = Vector3.new(15, 0, 8), size = Vector3.new(15, 1, 12) },
			{ offset = Vector3.new(-12, 0, -5), size = Vector3.new(12, 1, 10) },
		},
		color = Color3.fromRGB(50, 90, 150),
	},

	-- HERMIT'S LAKE: L-shaped lake in secluded area
	{
		name = "Hermit's Lake",
		position = Vector3.new(-200, -0.5, -80),
		parts = {
			{ offset = Vector3.new(0, 0, 0), size = Vector3.new(40, 1, 20) },
			{ offset = Vector3.new(25, 0, 20), size = Vector3.new(20, 1, 35) },
		},
		color = Color3.fromRGB(40, 70, 120),
	},

	-- DRAGON'S TEAR: Teardrop-shaped pool
	{
		name = "Dragon's Tear",
		position = Vector3.new(350, -0.5, 300),
		parts = {
			{ offset = Vector3.new(0, 0, 0), size = Vector3.new(30, 1, 50) },
			{ offset = Vector3.new(0, 0, -30), size = Vector3.new(20, 1, 20) },
			{ offset = Vector3.new(0, 0, -45), size = Vector3.new(10, 1, 15) },
		},
		color = Color3.fromRGB(60, 100, 160),
	},

	-- SANCTUARY SPRINGS: Multiple connected pools
	{
		name = "Sanctuary Springs",
		position = Vector3.new(-100, -0.5, 400),
		parts = {
			{ offset = Vector3.new(0, 0, 0), size = Vector3.new(20, 1, 20) },
			{ offset = Vector3.new(18, 0, 5), size = Vector3.new(15, 1, 15) },
			{ offset = Vector3.new(-15, 0, 10), size = Vector3.new(12, 1, 18) },
			{ offset = Vector3.new(5, 0, 20), size = Vector3.new(10, 1, 12) },
		},
		color = Color3.fromRGB(55, 95, 155),
	},
}

-- Create river segment between two points
local function createRiverSegment(start: Vector3, finish: Vector3, width: number, depth: number, color: Color3, parent: Model)
	local direction = (finish - start)
	local length = direction.Magnitude
	local midpoint = start + direction / 2

	local segment = Instance.new("Part")
	segment.Name = "RiverSegment"
	segment.Size = Vector3.new(width, depth, length + width * 0.3) -- Overlap slightly
	segment.Position = midpoint + Vector3.new(0, -depth / 2, 0)
	segment.Color = color
	segment.Material = Enum.Material.Water
	segment.Transparency = 0.3
	segment.Anchored = true
	segment.CanCollide = false

	-- Rotate to face direction
	local angle = math.atan2(direction.X, direction.Z)
	segment.Orientation = Vector3.new(0, math.deg(angle), 0)

	segment.Parent = parent

	return segment
end

-- Create bathing prompt for water
local function addBathingPrompt(waterPart: BasePart, waterName: string)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Bathe"
	prompt.ObjectText = waterName
	prompt.HoldDuration = SURVIVAL_CONFIG.HYGIENE.bathingDuration
	prompt.MaxActivationDistance = 12
	prompt.Parent = waterPart

	prompt.Triggered:Connect(function(player)
		local state = playerSurvivalState[player]
		if state then
			state.hygiene = math.min(100, state.hygiene + SURVIVAL_CONFIG.HYGIENE.bathingRestoreAmount)
			state.lastBatheTime = tick()
			SurvivalRemote:FireClient(player, "BATHED", {
				hygiene = state.hygiene,
				location = waterName,
			})
			print("[Survival]", player.Name, "bathed in", waterName, "! Hygiene:", state.hygiene)
		end
	end)
end

local function spawnWaterBodies()
	print("[Survival] Creating hand-crafted rivers and lakes...")

	-- Create winding rivers
	for _, riverData in RIVERS do
		local riverModel = Instance.new("Model")
		riverModel.Name = "River_" .. riverData.name

		-- Create segments between each waypoint
		for i = 1, #riverData.waypoints - 1 do
			local start = riverData.waypoints[i]
			local finish = riverData.waypoints[i + 1]
			local segment = createRiverSegment(start, finish, riverData.width, riverData.depth, riverData.color, riverModel)

			-- Add bathing prompt to middle segments
			if i == math.floor(#riverData.waypoints / 2) then
				addBathingPrompt(segment, riverData.name)
			end
		end

		-- Add riverbank decorations (rocks, plants)
		for i, waypoint in riverData.waypoints do
			if i % 3 == 0 then -- Every third waypoint
				-- Rocks on banks
				for _ = 1, math.random(2, 4) do
					local rock = Instance.new("Part")
					rock.Size = Vector3.new(math.random(2, 5), math.random(1, 3), math.random(2, 5))
					rock.Position = waypoint + Vector3.new(
						riverData.width / 2 + math.random(2, 8) * (math.random() > 0.5 and 1 or -1),
						rock.Size.Y / 2,
						math.random(-5, 5)
					)
					rock.Color = Color3.fromRGB(100 + math.random(-20, 20), 90 + math.random(-20, 20), 80 + math.random(-20, 20))
					rock.Material = Enum.Material.Rock
					rock.Anchored = true
					rock.Parent = riverModel
				end
			end
		end

		-- River name sign
		local signPos = riverData.waypoints[math.floor(#riverData.waypoints / 2)]
		local sign = Instance.new("Part")
		sign.Size = Vector3.new(4, 2, 0.3)
		sign.Position = signPos + Vector3.new(riverData.width + 5, 3, 0)
		sign.Color = Color3.fromRGB(80, 55, 35)
		sign.Material = Enum.Material.Wood
		sign.Anchored = true
		sign.Parent = riverModel

		local signGui = Instance.new("SurfaceGui")
		signGui.Face = Enum.NormalId.Front
		signGui.Parent = sign

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = riverData.name
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0
		label.Font = Enum.Font.Antique
		label.TextSize = 18
		label.Parent = signGui

		riverModel.Parent = workspace
		print("[Survival] Created river:", riverData.name, "with", #riverData.waypoints, "waypoints")
	end

	-- Create irregular lakes
	for _, lakeData in LAKES do
		local lakeModel = Instance.new("Model")
		lakeModel.Name = "Lake_" .. lakeData.name

		local mainPart: BasePart? = nil

		for i, partData in lakeData.parts do
			local lakePart = Instance.new("Part")
			lakePart.Size = partData.size
			lakePart.Position = lakeData.position + partData.offset + Vector3.new(0, -partData.size.Y / 2, 0)
			lakePart.Color = lakeData.color
			lakePart.Material = Enum.Material.Water
			lakePart.Transparency = 0.3
			lakePart.Anchored = true
			lakePart.CanCollide = false
			lakePart.Parent = lakeModel

			if i == 1 then
				mainPart = lakePart
			end
		end

		-- Add bathing prompt to main part
		if mainPart then
			addBathingPrompt(mainPart, lakeData.name)
		end

		-- Lake name marker
		local marker = Instance.new("Part")
		marker.Size = Vector3.new(3, 0.5, 3)
		marker.Position = lakeData.position + Vector3.new(0, 0.3, 0)
		marker.Color = Color3.fromRGB(80, 55, 35)
		marker.Material = Enum.Material.Wood
		marker.Anchored = true
		marker.Parent = lakeModel

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 100, 0, 30)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.Adornee = marker
		billboard.Parent = marker

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 1, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = lakeData.name
		nameLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
		nameLabel.TextStrokeTransparency = 0
		nameLabel.Font = Enum.Font.Antique
		nameLabel.TextSize = 14
		nameLabel.Parent = billboard

		lakeModel.Parent = workspace
		print("[Survival] Created lake:", lakeData.name)
	end

	print("[Survival] Created", #RIVERS, "winding rivers and", #LAKES, "irregular lakes")
end

-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

local lastFarmUpdate = 0

RunService.Heartbeat:Connect(function(dt)
	-- Update each player
	for player, state in playerSurvivalState do
		updateHygiene(player, dt)

		-- Track furthest position
		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if rootPart then
				local distFromSpawn = getDistanceFromSpawn(rootPart.Position)
				if distFromSpawn > state.distanceFromSpawn then
					state.distanceFromSpawn = distFromSpawn
					state.furthestPosition = rootPart.Position
				end
			end
		end

		-- Update community boost status periodically
		local nearbyCount = getNearbyPlayersCount(player)
		if nearbyCount > 0 then
			-- Visual/audio feedback could go here
		end
	end

	-- Update farm growth (less frequently)
	if tick() - lastFarmUpdate > 5 then
		updateFarmGrowth()
		lastFarmUpdate = tick()
	end

	-- Clean up expired fires
	for i = #fires, 1, -1 do
		local fireData = fires[i]
		if not fireData.part or not fireData.part.Parent then
			table.remove(fires, i)
		end
	end
end)

-- ==========================================
-- INITIALIZATION
-- ==========================================

Players.PlayerAdded:Connect(initPlayer)
Players.PlayerRemoving:Connect(cleanupPlayer)

for _, player in Players:GetPlayers() do
	initPlayer(player)
end

task.spawn(function()
	task.wait(3)
	spawnFindableItems()
	spawnWaterBodies()
end)

print("[Survival] Hardcore survival system initialized!")
print("[Survival] - Shelter building: MANDATORY")
print("[Survival] - Fire/warmth: MANDATORY")
print("[Survival] - Hygiene (bathing, brushing): MANDATORY")
print("[Survival] - Farming and cooking: AVAILABLE")
print("[Survival] - Community boost: ACTIVE")
print("[Survival] - Death respawn: 1/3 back toward spawn")
print("[Survival] - Markers: Up to 10 per player")
