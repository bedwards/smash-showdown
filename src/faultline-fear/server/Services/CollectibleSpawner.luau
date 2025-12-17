--!strict
--[[
	Faultline Fear: Collectible Spawner

	Creates and manages collectible items in the world:
	- 6 Generator Parts (for radio tower)
	- Food items (for hunger)

	Items are placed at strategic locations based on terrain zones.
	Uses CollectionService tags for StoryBeatProcessor integration.

	Exports: Initialize(), SpawnGeneratorParts(), SpawnFood()
	Depends: Config, CollectionService, Heightmap
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config
local Heightmap = Shared.Heightmap

local CollectibleSpawner = {}

-- Folders
local collectiblesFolder: Folder = nil :: any

-- Generator part definitions with locations
-- Parts are spread across the world for exploration
local GENERATOR_PARTS = {
	{
		name = "Spark Plug",
		description = "A spark plug for the generator ignition",
		zone = "COASTAL",
		offset = Vector3.new(150, 0, 0),
		color = BrickColor.new("Bright yellow"),
	},
	{
		name = "Carburetor",
		description = "Mixes fuel and air for combustion",
		zone = "VALLEY",
		offset = Vector3.new(-100, 0, 100),
		color = BrickColor.new("Medium stone grey"),
	},
	{
		name = "Pull Cord",
		description = "Starter cord with handle",
		zone = "FAULT_LINE",
		offset = Vector3.new(200, 0, -50),
		color = BrickColor.new("Bright red"),
	},
	{
		name = "Fuel Line",
		description = "Rubber tubing for fuel delivery",
		zone = "FOREST",
		offset = Vector3.new(-150, 0, 200),
		color = BrickColor.new("Black"),
	},
	{
		name = "Air Filter",
		description = "Filters debris from air intake",
		zone = "FOREST",
		offset = Vector3.new(100, 0, -100),
		color = BrickColor.new("Cork"),
	},
	{
		name = "Ignition Coil",
		description = "Generates spark voltage",
		zone = "MOUNTAIN",
		offset = Vector3.new(0, 0, -200),
		color = BrickColor.new("Dark orange"),
	},
}

-- Food spawn locations (simplified - spread across zones)
local FOOD_SPAWN_ZONES = {
	{ zone = "BEACH", count = 3 },
	{ zone = "COASTAL", count = 4 },
	{ zone = "VALLEY", count = 5 },
	{ zone = "FOREST", count = 4 },
}

-- Food spawns near landmarks (reward for reaching them)
-- Multiple spawn points around each landmark
local LANDMARK_FOOD_SPAWNS = {
	-- Ferris Wheel (Beach) - boardwalk snacks
	{
		name = "FerrisWheel",
		center = Vector3.new(200, 0, -1000),
		spawns = {
			{ offset = Vector3.new(15, 0, 0), foodType = "Popcorn", hungerRestore = 15 },
			{ offset = Vector3.new(-15, 0, 5), foodType = "Cotton Candy", hungerRestore = 10 },
			{ offset = Vector3.new(0, 0, 20), foodType = "Hot Dog", hungerRestore = 25 },
			{ offset = Vector3.new(10, 0, -15), foodType = "Soda", hungerRestore = 10 },
		},
	},
	-- Lighthouse (Coastal) - keeper's supplies
	{
		name = "Lighthouse",
		center = Vector3.new(-400, 0, -600),
		spawns = {
			{ offset = Vector3.new(8, 0, 0), foodType = "Canned Beans", hungerRestore = 30 },
			{ offset = Vector3.new(-5, 0, 8), foodType = "Crackers", hungerRestore = 15 },
			{ offset = Vector3.new(0, 0, -10), foodType = "Dried Fish", hungerRestore = 25 },
		},
	},
	-- Water Tower (Valley) - emergency cache
	{
		name = "WaterTower",
		center = Vector3.new(0, 0, 100),
		spawns = {
			{ offset = Vector3.new(12, 0, 0), foodType = "MRE", hungerRestore = 40 },
			{ offset = Vector3.new(-10, 0, 5), foodType = "Water Bottle", hungerRestore = 20 },
			{ offset = Vector3.new(5, 0, -12), foodType = "Energy Bar", hungerRestore = 20 },
		},
	},
	-- Radio Tower (Mountain) - rescue supply drop
	{
		name = "RadioTower",
		center = Vector3.new(0, 0, 1700),
		spawns = {
			{ offset = Vector3.new(10, 0, 0), foodType = "MRE", hungerRestore = 40 },
			{ offset = Vector3.new(-8, 0, 8), foodType = "MRE", hungerRestore = 40 },
			{ offset = Vector3.new(0, 0, -10), foodType = "Energy Bar", hungerRestore = 20 },
			{ offset = Vector3.new(-5, 0, -8), foodType = "Water Bottle", hungerRestore = 20 },
			{ offset = Vector3.new(8, 0, 10), foodType = "First Aid Ration", hungerRestore = 35 },
		},
	},
	-- Bridge (Fault Line) - abandoned supplies
	{
		name = "Bridge",
		center = Vector3.new(0, 0, 600),
		spawns = {
			{ offset = Vector3.new(20, 0, 0), foodType = "Canned Food", hungerRestore = 25 },
			{ offset = Vector3.new(-25, 0, 5), foodType = "Granola Bar", hungerRestore = 15 },
		},
	},
	-- Houses in Valley - pantry items
	{
		name = "House_Valley_1",
		center = Vector3.new(-100, 0, 50),
		spawns = {
			{ offset = Vector3.new(5, 0, 0), foodType = "Canned Soup", hungerRestore = 30 },
			{ offset = Vector3.new(-3, 0, 5), foodType = "Cereal", hungerRestore = 20 },
		},
	},
	{
		name = "House_Valley_2",
		center = Vector3.new(80, 0, 150),
		spawns = {
			{ offset = Vector3.new(0, 0, 8), foodType = "Pasta", hungerRestore = 25 },
			{ offset = Vector3.new(6, 0, -3), foodType = "Canned Vegetables", hungerRestore = 20 },
		},
	},
	-- Houses in Coastal - pantry items
	{
		name = "House_Coastal_1",
		center = Vector3.new(-150, 0, -400),
		spawns = {
			{ offset = Vector3.new(4, 0, 0), foodType = "Canned Tuna", hungerRestore = 25 },
			{ offset = Vector3.new(-5, 0, 4), foodType = "Crackers", hungerRestore = 15 },
		},
	},
}

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================

local function getZoneCenter(zoneName: string): Vector3?
	local zoneConfig = Config.ZONES[zoneName]
	if not zoneConfig then
		warn("[CollectibleSpawner] Unknown zone:", zoneName)
		return nil
	end

	local centerZ = (zoneConfig.zMin + zoneConfig.zMax) / 2
	local centerX = 0

	return Vector3.new(centerX, 0, centerZ)
end

local function getTerrainHeight(x: number, z: number): number
	if Heightmap and Heightmap.GetHeight then
		return Heightmap:GetHeight(x, z)
	end
	return 20 -- Default height if heightmap not ready
end

local function createProximityPrompt(parent: Instance, actionText: string, objectText: string): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.MaxActivationDistance = 8
	prompt.HoldDuration = 0.3
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

-- ==========================================
-- GENERATOR PARTS
-- ==========================================

local function createGeneratorPart(partDef: typeof(GENERATOR_PARTS[1])): Model
	-- Create container model
	local model = Instance.new("Model")
	model.Name = "GeneratorPart_" .. partDef.name:gsub(" ", "")

	-- Create the part (placeholder mesh)
	local part = Instance.new("Part")
	part.Name = "Part"
	part.Size = Vector3.new(1.5, 1, 1.5)
	part.Anchored = true
	part.CanCollide = false
	part.BrickColor = partDef.color
	part.Material = Enum.Material.Metal
	part.Parent = model

	-- Add glow effect
	local light = Instance.new("PointLight")
	light.Brightness = 0.5
	light.Range = 8
	light.Color = partDef.color.Color
	light.Parent = part

	-- Add subtle bobbing animation
	local attachment = Instance.new("Attachment")
	attachment.Parent = part

	-- Set primary part
	model.PrimaryPart = part

	-- Add attributes
	model:SetAttribute("PartName", partDef.name)
	model:SetAttribute("Description", partDef.description)
	model:SetAttribute("ObjectTag", "GeneratorPart")

	-- Add CollectionService tag
	CollectionService:AddTag(model, "GeneratorPart")
	CollectionService:AddTag(model, "StoryCollectible")

	-- Add ProximityPrompt
	createProximityPrompt(part, "Collect", partDef.name)

	return model
end

function CollectibleSpawner:SpawnGeneratorParts()
	local partsFolder = Instance.new("Folder")
	partsFolder.Name = "GeneratorParts"
	partsFolder.Parent = collectiblesFolder

	for _, partDef in ipairs(GENERATOR_PARTS) do
		local zoneCenter = getZoneCenter(partDef.zone)
		if not zoneCenter then
			continue
		end

		-- Calculate position
		local x = zoneCenter.X + partDef.offset.X
		local z = zoneCenter.Z + partDef.offset.Z
		local y = getTerrainHeight(x, z) + 2 -- Float above ground

		local position = Vector3.new(x, y, z)

		-- Create and place part
		local model = createGeneratorPart(partDef)
		model:PivotTo(CFrame.new(position))
		model.Parent = partsFolder

		print(
			string.format(
				"[CollectibleSpawner] Spawned '%s' at %s (zone: %s)",
				partDef.name,
				tostring(position),
				partDef.zone
			)
		)
	end

	print(string.format("[CollectibleSpawner] Spawned %d generator parts", #GENERATOR_PARTS))
end

-- ==========================================
-- FOOD ITEMS
-- ==========================================

local function createFoodItem(foodType: string, position: Vector3, hungerRestore: number?): Model
	local model = Instance.new("Model")
	model.Name = "Food_" .. foodType:gsub(" ", "")

	-- Create the part (placeholder)
	local part = Instance.new("Part")
	part.Name = "Part"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(1, 1, 1)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	part.Position = position

	-- Color based on food type
	if string.find(foodType, "MRE") or string.find(foodType, "Canned") then
		part.BrickColor = BrickColor.new("Medium stone grey")
	elseif string.find(foodType, "Water") or string.find(foodType, "Soda") then
		part.BrickColor = BrickColor.new("Bright blue")
	elseif string.find(foodType, "Bar") or string.find(foodType, "Granola") then
		part.BrickColor = BrickColor.new("Cork")
	elseif string.find(foodType, "Hot Dog") or string.find(foodType, "Fish") then
		part.BrickColor = BrickColor.new("Bright red")
	elseif string.find(foodType, "Popcorn") or string.find(foodType, "Cotton") then
		part.BrickColor = BrickColor.new("White")
	else
		part.BrickColor = BrickColor.new("Bright green")
	end

	part.Parent = model
	model.PrimaryPart = part

	-- Add attributes
	model:SetAttribute("FoodType", foodType)
	model:SetAttribute("HungerRestore", hungerRestore or 25)
	model:SetAttribute("ObjectTag", "Food")

	-- Add tags
	CollectionService:AddTag(model, "Food")
	CollectionService:AddTag(model, "StoryCollectible")

	-- Add ProximityPrompt
	createProximityPrompt(part, "Eat", foodType)

	return model
end

function CollectibleSpawner:SpawnFood()
	local foodFolder = Instance.new("Folder")
	foodFolder.Name = "FoodItems"
	foodFolder.Parent = collectiblesFolder

	local foodTypes = { "Apple", "Berries", "Mushroom", "Fish", "Canned Food" }
	local totalSpawned = 0

	for _, spawnConfig in ipairs(FOOD_SPAWN_ZONES) do
		local zoneCenter = getZoneCenter(spawnConfig.zone)
		if not zoneCenter then
			continue
		end

		local zoneConfig = Config.ZONES[spawnConfig.zone]
		local zoneWidth = Config.WORLD_SIZE / 2

		for _ = 1, spawnConfig.count do
			-- Random position within zone
			local x = math.random(-zoneWidth / 2, zoneWidth / 2)
			local z = math.random(zoneConfig.zMin, zoneConfig.zMax)
			local y = getTerrainHeight(x, z) + 0.5

			local position = Vector3.new(x, y, z)
			local foodType = foodTypes[math.random(1, #foodTypes)]

			local model = createFoodItem(foodType, position)
			model.Parent = foodFolder

			totalSpawned += 1
		end
	end

	print(string.format("[CollectibleSpawner] Spawned %d food items in zones", totalSpawned))
end

function CollectibleSpawner:SpawnLandmarkFood()
	local foodFolder = collectiblesFolder:FindFirstChild("FoodItems")
	if not foodFolder then
		foodFolder = Instance.new("Folder")
		foodFolder.Name = "FoodItems"
		foodFolder.Parent = collectiblesFolder
	end

	local totalSpawned = 0

	for _, landmarkDef in ipairs(LANDMARK_FOOD_SPAWNS) do
		for _, spawnDef in ipairs(landmarkDef.spawns) do
			-- Calculate position
			local x = landmarkDef.center.X + spawnDef.offset.X
			local z = landmarkDef.center.Z + spawnDef.offset.Z
			local y = getTerrainHeight(x, z) + 0.5

			local position = Vector3.new(x, y, z)

			-- Create food item with custom hunger restore
			local model = createFoodItem(spawnDef.foodType, position, spawnDef.hungerRestore)
			model:SetAttribute("Landmark", landmarkDef.name)
			model.Parent = foodFolder

			totalSpawned += 1
		end

		print(
			string.format("[CollectibleSpawner] Spawned %d food items near %s", #landmarkDef.spawns, landmarkDef.name)
		)
	end

	print(string.format("[CollectibleSpawner] Spawned %d total landmark food items", totalSpawned))
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function CollectibleSpawner:Initialize()
	-- Create main folder
	collectiblesFolder = Instance.new("Folder")
	collectiblesFolder.Name = "Collectibles"
	collectiblesFolder.Parent = Workspace

	-- Spawn all collectibles
	self:SpawnGeneratorParts()
	self:SpawnFood()
	self:SpawnLandmarkFood()

	print("[CollectibleSpawner] Initialized")
end

-- ==========================================
-- DEBUG
-- ==========================================

function CollectibleSpawner:DebugHighlightAll()
	for _, model in collectiblesFolder:GetDescendants() do
		if model:IsA("Model") and model.PrimaryPart then
			local highlight = Instance.new("Highlight")
			highlight.FillTransparency = 0.5
			highlight.OutlineTransparency = 0
			highlight.Parent = model
		end
	end
	print("[CollectibleSpawner] Debug highlights added")
end

return CollectibleSpawner
