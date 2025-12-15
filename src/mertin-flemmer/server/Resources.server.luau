--!strict
-- Resource spawning and collection for Mertin-Flemmer
-- Food, batteries, wood scattered across the world

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config

-- Resource configuration - plenty of loot scattered around!
local RESOURCE_CONFIG = {
	FOOD = {
		count = 35,  -- Lots of food to find
		respawnTime = 120,
		collectRadius = 4,
		hungerRestore = 30,
		models = {
			{ name = "Apple", color = Color3.fromRGB(200, 50, 50), size = Vector3.new(1, 1, 1) },
			{ name = "Bread", color = Color3.fromRGB(200, 170, 100), size = Vector3.new(1.5, 0.8, 1) },
			{ name = "Canned Food", color = Color3.fromRGB(100, 120, 140), size = Vector3.new(0.8, 1.2, 0.8) },
			{ name = "Berries", color = Color3.fromRGB(100, 50, 150), size = Vector3.new(0.6, 0.6, 0.6) },
		},
	},
	BATTERY = {
		count = 20,  -- Batteries for flashlights
		respawnTime = 180,
		collectRadius = 3,
		batteryRestore = 60, -- seconds of flashlight
		models = {
			{ name = "Battery", color = Color3.fromRGB(50, 50, 60), size = Vector3.new(0.5, 1.5, 0.5) },
			{ name = "Battery Pack", color = Color3.fromRGB(200, 180, 50), size = Vector3.new(1, 0.5, 0.5) },
		},
	},
	WOOD = {
		count = 40,  -- Wood for campfires
		respawnTime = 90,
		collectRadius = 5,
		campfireFuel = 60, -- seconds added to campfire
		models = {
			{ name = "Stick", color = Color3.fromRGB(100, 70, 40), size = Vector3.new(0.3, 2, 0.3) },
			{ name = "Log", color = Color3.fromRGB(80, 55, 35), size = Vector3.new(0.8, 2.5, 0.8) },
			{ name = "Branches", color = Color3.fromRGB(90, 65, 40), size = Vector3.new(1.5, 0.5, 1) },
		},
	},
}

-- Create remotes
local CollectResourceRemote = Instance.new("RemoteEvent")
CollectResourceRemote.Name = "CollectResource"
CollectResourceRemote.Parent = ReplicatedStorage

local UpdateInventoryRemote = Instance.new("RemoteEvent")
UpdateInventoryRemote.Name = "UpdateInventory"
UpdateInventoryRemote.Parent = ReplicatedStorage

-- State
local resources: { [BasePart]: {
	type: string,
	modelData: typeof(RESOURCE_CONFIG.FOOD.models[1]),
	spawnPosition: Vector3,
	collected: boolean,
	collectTime: number?,
} } = {}

local playerInventories: { [Player]: {
	food: number,
	batteries: number,
	wood: number,
} } = {}

-- World bounds - must match terrain size!
local WORLD_SIZE = 3000  -- Slightly smaller than terrain (3500) to keep resources within playable area

-- Create a resource pickup
local function createResource(resourceType: string, position: Vector3): BasePart?
	local config = RESOURCE_CONFIG[resourceType]
	if not config then return nil end

	local modelData = config.models[math.random(#config.models)]

	-- Get terrain height at this position
	local terrainHeight = Shared.getTerrainHeight(position.X, position.Z)

	local resource = Instance.new("Part")
	resource.Name = "Resource_" .. resourceType .. "_" .. modelData.name
	resource.Size = modelData.size
	resource.Color = modelData.color
	resource.Material = Enum.Material.SmoothPlastic
	resource.Position = Vector3.new(position.X, terrainHeight + modelData.size.Y / 2 + 0.3, position.Z)
	resource.Anchored = true
	resource.CanCollide = false

	-- Add glow effect for visibility
	local highlight = Instance.new("Highlight")
	highlight.FillColor = modelData.color
	highlight.FillTransparency = 0.8
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.OutlineTransparency = 0.5
	highlight.Parent = resource

	-- Add floating animation
	local baseY = terrainHeight + modelData.size.Y / 2 + 0.3
	local floatOffset = math.random() * math.pi * 2

	-- Hover and rotate effect
	local connection: RBXScriptConnection?
	connection = RunService.Heartbeat:Connect(function(dt)
		if not resource or not resource.Parent then
			if connection then connection:Disconnect() end
			return
		end

		local t = tick() + floatOffset
		resource.Position = Vector3.new(
			resource.Position.X,
			baseY + math.sin(t * 2) * 0.3,
			resource.Position.Z
		)
		resource.Orientation = Vector3.new(0, (t * 30) % 360, 0)
	end)

	-- Billboard GUI for name
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 80, 0, 20)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.Adornee = resource
	billboard.Parent = resource

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = modelData.name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.Parent = billboard

	resource.Parent = workspace

	-- Store resource data
	resources[resource] = {
		type = resourceType,
		modelData = modelData,
		spawnPosition = position,
		collected = false,
		collectTime = nil,
	}

	return resource
end

-- Spawn resources across the world
local function spawnResources()
	-- Wait for world to generate
	task.wait(4)

	print("[Resources] Spawning resources across the world...")

	-- SPAWN AREA FOOD (lots of food near the spawn house for new players)
	local SPAWN_FOOD_COUNT = 20
	local SPAWN_CENTER = Vector3.new(0, 0, -30) -- Near spawn house
	local SPAWN_FOOD_RADIUS = 60

	print("[Resources] Spawning", SPAWN_FOOD_COUNT, "food items near spawn area...")
	for i = 1, SPAWN_FOOD_COUNT do
		local angle = math.random() * math.pi * 2
		local distance = math.random() * SPAWN_FOOD_RADIUS
		local pos = SPAWN_CENTER + Vector3.new(
			math.cos(angle) * distance,
			0,
			math.sin(angle) * distance
		)
		createResource("FOOD", pos)
	end

	-- Spawn regular food across world
	for i = 1, RESOURCE_CONFIG.FOOD.count do
		local pos = Vector3.new(
			math.random(-WORLD_SIZE, WORLD_SIZE),
			0,
			math.random(-WORLD_SIZE, WORLD_SIZE)
		)
		createResource("FOOD", pos)
	end

	-- Spawn batteries (rarer, often near buildings)
	for i = 1, RESOURCE_CONFIG.BATTERY.count do
		local pos: Vector3
		if math.random() < 0.6 then
			-- Near buildings
			local angle = math.random() * math.pi * 2
			local buildingDist = 150 + math.random() * 400
			pos = Vector3.new(
				math.cos(angle) * buildingDist + (math.random() - 0.5) * 30,
				0,
				math.sin(angle) * buildingDist + (math.random() - 0.5) * 30
			)
		else
			-- Random
			pos = Vector3.new(
				math.random(-WORLD_SIZE, WORLD_SIZE),
				0,
				math.random(-WORLD_SIZE, WORLD_SIZE)
			)
		end
		createResource("BATTERY", pos)
	end

	-- Spawn wood (often near trees)
	for i = 1, RESOURCE_CONFIG.WOOD.count do
		local pos = Vector3.new(
			math.random(-WORLD_SIZE, WORLD_SIZE),
			0,
			math.random(-WORLD_SIZE, WORLD_SIZE)
		)
		createResource("WOOD", pos)
	end

	print("[Resources] Spawned resources: Food x", RESOURCE_CONFIG.FOOD.count,
		"| Batteries x", RESOURCE_CONFIG.BATTERY.count,
		"| Wood x", RESOURCE_CONFIG.WOOD.count)
end

-- Initialize player inventory
local function initPlayerInventory(player: Player)
	playerInventories[player] = {
		food = 5, -- Start with 5 food to survive initial exploration
		batteries = 1, -- One battery to start
		wood = 3, -- Some wood for campfire
	}
	-- Send initial inventory to client
	UpdateInventoryRemote:FireClient(player, playerInventories[player])
	print("[Resources] Initialized", player.Name, "with starting supplies")
end

-- Cleanup player inventory
local function cleanupPlayerInventory(player: Player)
	playerInventories[player] = nil
end

-- Check for resource collection
local function checkResourceCollection()
	for resource, data in resources do
		if data.collected then continue end
		if not resource or not resource.Parent then continue end

		local resourcePos = resource.Position

		for _, player in Players:GetPlayers() do
			local character = player.Character
			if not character then continue end

			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not rootPart then continue end

			local config = RESOURCE_CONFIG[data.type]
			local distance = (rootPart.Position - resourcePos).Magnitude

			if distance < config.collectRadius then
				-- Collect the resource!
				data.collected = true
				data.collectTime = tick()

				-- Update player inventory
				local inventory = playerInventories[player]
				if inventory then
					if data.type == "FOOD" then
						inventory.food += 1
					elseif data.type == "BATTERY" then
						inventory.batteries += 1
					elseif data.type == "WOOD" then
						inventory.wood += 1
					end

					-- Notify client
					UpdateInventoryRemote:FireClient(player, inventory)
					CollectResourceRemote:FireClient(player, data.type, data.modelData.name)
				end

				-- Hide resource
				resource.Transparency = 1
				local highlight = resource:FindFirstChildOfClass("Highlight")
				if highlight then highlight.Enabled = false end
				local billboard = resource:FindFirstChildOfClass("BillboardGui")
				if billboard then billboard.Enabled = false end

				print("[Resources]", player.Name, "collected", data.modelData.name)

				-- Schedule respawn
				task.delay(config.respawnTime, function()
					if resource and resource.Parent then
						data.collected = false
						data.collectTime = nil
						resource.Transparency = 0
						if highlight then highlight.Enabled = true end
						if billboard then billboard.Enabled = true end
					end
				end)

				break -- Only one player can collect
			end
		end
	end
end

-- Handle use resource requests from client
CollectResourceRemote.OnServerEvent:Connect(function(player: Player, action: string, resourceType: string)
	local inventory = playerInventories[player]
	if not inventory then return end

	if action == "USE" then
		if resourceType == "FOOD" and inventory.food > 0 then
			inventory.food -= 1
			-- Restore hunger (handled by hunger system)
			-- For now, just update inventory
			UpdateInventoryRemote:FireClient(player, inventory)
			print("[Resources]", player.Name, "ate food")
		elseif resourceType == "BATTERY" and inventory.batteries > 0 then
			inventory.batteries -= 1
			-- Restore flashlight battery (client handles this)
			UpdateInventoryRemote:FireClient(player, inventory)
			print("[Resources]", player.Name, "used battery")
		elseif resourceType == "WOOD" and inventory.wood > 0 then
			-- Wood is used at campfires
			inventory.wood -= 1
			UpdateInventoryRemote:FireClient(player, inventory)
			print("[Resources]", player.Name, "used wood")
		end
	end
end)

-- Player setup
Players.PlayerAdded:Connect(initPlayerInventory)
Players.PlayerRemoving:Connect(cleanupPlayerInventory)

for _, player in Players:GetPlayers() do
	initPlayerInventory(player)
end

-- Game loop
RunService.Heartbeat:Connect(function()
	checkResourceCollection()
end)

-- Initialize
spawnResources()
print("[Resources] Resource system initialized!")
