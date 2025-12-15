--!strict
-- Discovery & Reward System for Mertin-Flemmer
-- Rewards players for finding special locations!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

-- Wait for inventory remote
local UpdateInventoryRemote = ReplicatedStorage:WaitForChild("UpdateInventory") :: RemoteEvent

-- Create discovery remote
local DiscoveryRemote = Instance.new("RemoteEvent")
DiscoveryRemote.Name = "Discovery"
DiscoveryRemote.Parent = ReplicatedStorage

-- Discovery locations with rewards
-- Each location can only be discovered once per player
local DISCOVERY_LOCATIONS = {
	-- ENVIRONMENTAL SPECTACLES (the animated effects!)
	{
		name = "Frozen Peaks",
		description = "A mountaintop where eternal snow falls from the heavens",
		position = Vector3.new(2000, 150, 0),
		radius = 300,
		rewards = { food = 5, batteries = 3, wood = 8 },
		category = "spectacle",
	},
	{
		name = "Volcanic Forge",
		description = "Sparks fly from the ancient volcanic vents",
		position = Vector3.new(-2300, 30, 1300),
		radius = 150,
		rewards = { food = 4, batteries = 5, wood = 3 },
		category = "spectacle",
	},
	{
		name = "Sacred Grove",
		description = "Stars stream heavenward in this mystical place",
		position = Vector3.new(0, 100, -800),
		radius = 150,
		rewards = { food = 8, batteries = 2, wood = 5 },
		category = "spectacle",
	},
	{
		name = "Crystal Hollow",
		description = "Rainbow lasers dance through prismatic crystals",
		position = Vector3.new(600, 50, 1500),
		radius = 100,
		rewards = { food = 6, batteries = 4, wood = 4 },
		category = "spectacle",
	},
	{
		name = "The Observatory",
		description = "A telescope beams light into the infinite cosmos",
		position = Vector3.new(350, 200, 350),
		radius = 100,
		rewards = { food = 3, batteries = 8, wood = 2 },
		category = "spectacle",
	},
	{
		name = "Mystical Portal",
		description = "A kaleidoscope of swirling colors defies reality",
		position = Vector3.new(-800, 20, -500),
		radius = 80,
		rewards = { food = 5, batteries = 5, wood = 5 },
		category = "spectacle",
	},

	-- RADIO TOWERS (lighted areas with music!)
	{
		name = "Desert Oasis Tower",
		description = "A beacon of light and music in the scorched sands",
		position = Vector3.new(1000, 0, 1000),
		radius = 80,
		rewards = { food = 3, batteries = 4, wood = 2 },
		category = "tower",
	},
	{
		name = "Volcanic Outlook Tower",
		description = "Broadcasting from the edge of the ashen peaks",
		position = Vector3.new(-1000, 0, 1000),
		radius = 80,
		rewards = { food = 2, batteries = 5, wood = 3 },
		category = "tower",
	},
	{
		name = "Frozen Lake Tower",
		description = "A warm signal in the frozen wastes",
		position = Vector3.new(1500, 0, -500),
		radius = 80,
		rewards = { food = 4, batteries = 3, wood = 4 },
		category = "tower",
	},
	{
		name = "Swamp Hollow Tower",
		description = "Light piercing through the murky depths",
		position = Vector3.new(-1500, 0, -1000),
		radius = 80,
		rewards = { food = 3, batteries = 3, wood = 5 },
		category = "tower",
	},

	-- WATERFALLS
	{
		name = "Whispering Falls",
		description = "The mist carries ancient secrets",
		position = Vector3.new(800, 0, 600),
		radius = 60,
		rewards = { food = 4, batteries = 1, wood = 3 },
		category = "waterfall",
	},
	{
		name = "Thunder Cascade",
		description = "The roar echoes through the valley",
		position = Vector3.new(-600, 0, 800),
		radius = 60,
		rewards = { food = 3, batteries = 2, wood = 4 },
		category = "waterfall",
	},
	{
		name = "Frozen Tears",
		description = "Ice crystals glitter in the eternal cold",
		position = Vector3.new(1800, 0, -400),
		radius = 60,
		rewards = { food = 5, batteries = 2, wood = 2 },
		category = "waterfall",
	},

	-- LANDMARKS
	{
		name = "Ice Fortress",
		description = "An ancient citadel frozen in time",
		position = Vector3.new(2200, 25, 200),
		radius = 100,
		rewards = { food = 6, batteries = 4, wood = 6 },
		category = "landmark",
	},
	{
		name = "Desert Temple",
		description = "Secrets of a forgotten civilization",
		position = Vector3.new(1800, 20, 2200),
		radius = 80,
		rewards = { food = 5, batteries = 6, wood = 3 },
		category = "landmark",
	},
	{
		name = "Obsidian Tower",
		description = "Dark spire rising from volcanic ash",
		position = Vector3.new(-2300, 60, 1300),
		radius = 60,
		rewards = { food = 4, batteries = 5, wood = 4 },
		category = "landmark",
	},
	{
		name = "Floor 7 1/2",
		description = "The legendary hidden floor of Mertin-Flemmer",
		position = Vector3.new(150, 0, -100),
		radius = 50,
		rewards = { food = 10, batteries = 10, wood = 10 },
		category = "landmark",
	},

	-- HERMIT CAVES
	{
		name = "The Hermit's Hollow",
		description = "Home of Old Mathias, keeper of forgotten lore",
		position = Vector3.new(400, 0, -400),
		radius = 40,
		rewards = { food = 3, batteries = 2, wood = 3 },
		category = "cave",
	},
	{
		name = "Whispering Grotto",
		description = "The Blind Seer awaits those who seek truth",
		position = Vector3.new(-800, 0, 300),
		radius = 40,
		rewards = { food = 2, batteries = 3, wood = 2 },
		category = "cave",
	},
	{
		name = "Crystal Witch's Lair",
		description = "Magical energies pulse through the cavern",
		position = Vector3.new(600, 0, 1500),
		radius = 40,
		rewards = { food = 4, batteries = 4, wood = 2 },
		category = "cave",
	},
}

-- Category display info
local CATEGORY_INFO = {
	spectacle = { title = "SPECTACULAR DISCOVERY!", color = Color3.fromRGB(255, 200, 100) },
	tower = { title = "RADIO TOWER FOUND!", color = Color3.fromRGB(100, 200, 255) },
	waterfall = { title = "WATERFALL DISCOVERED!", color = Color3.fromRGB(150, 220, 255) },
	landmark = { title = "LANDMARK REACHED!", color = Color3.fromRGB(255, 150, 100) },
	cave = { title = "CAVE EXPLORED!", color = Color3.fromRGB(200, 150, 255) },
}

-- Track player discoveries (resets on rejoin for now)
local playerDiscoveries: { [Player]: { [string]: boolean } } = {}

-- Track player inventories (shared with Resources system)
local playerInventoryRefs: { [Player]: { food: number, batteries: number, wood: number }? } = {}

-- Initialize player
local function initPlayer(player: Player)
	playerDiscoveries[player] = {}

	-- Try to get inventory reference from Resources system
	-- We'll update it when we give rewards
	playerInventoryRefs[player] = nil
end

-- Clean up player
local function cleanupPlayer(player: Player)
	playerDiscoveries[player] = nil
	playerInventoryRefs[player] = nil
end

-- Give discovery rewards
local function giveRewards(player: Player, location: typeof(DISCOVERY_LOCATIONS[1]))
	-- Fire to Resources system to add items
	-- The Resources system handles the actual inventory
	local CollectResourceRemote = ReplicatedStorage:FindFirstChild("CollectResource") :: RemoteEvent?

	if CollectResourceRemote then
		-- Send reward info - Resources system will handle adding to inventory
		for itemType, amount in location.rewards do
			for i = 1, amount do
				-- Simulate collection for each item
				if itemType == "food" then
					CollectResourceRemote:FireClient(player, "FOOD", "Discovery Reward")
				elseif itemType == "batteries" then
					CollectResourceRemote:FireClient(player, "BATTERY", "Discovery Reward")
				elseif itemType == "wood" then
					CollectResourceRemote:FireClient(player, "WOOD", "Discovery Reward")
				end
			end
		end
	end

	-- Also directly update via the Trading remote if available (for inventory sync)
	local TradingRemote = ReplicatedStorage:FindFirstChild("Trading") :: RemoteEvent?
	if TradingRemote then
		TradingRemote:FireClient(player, "DISCOVERY_REWARD", {
			food = location.rewards.food or 0,
			batteries = location.rewards.batteries or 0,
			wood = location.rewards.wood or 0,
		})
	end
end

-- Check if player discovered a new location
local function checkDiscoveries(player: Player)
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	local playerPos = rootPart.Position
	local discoveries = playerDiscoveries[player]
	if not discoveries then return end

	for _, location in DISCOVERY_LOCATIONS do
		-- Skip already discovered
		if discoveries[location.name] then continue end

		-- Check distance (horizontal only for better detection)
		local locationPos = location.position
		local horizontalDist = ((playerPos.X - locationPos.X)^2 + (playerPos.Z - locationPos.Z)^2)^0.5
		local verticalDist = math.abs(playerPos.Y - locationPos.Y)

		-- More lenient vertical check for elevated locations
		if horizontalDist < location.radius and verticalDist < 200 then
			-- DISCOVERED!
			discoveries[location.name] = true

			local categoryInfo = CATEGORY_INFO[location.category] or CATEGORY_INFO.landmark

			-- Notify client
			DiscoveryRemote:FireClient(player, "DISCOVERED", {
				name = location.name,
				description = location.description,
				rewards = location.rewards,
				category = location.category,
				title = categoryInfo.title,
				color = categoryInfo.color,
			})

			-- Give rewards
			giveRewards(player, location)

			print("[Discovery]", player.Name, "discovered", location.name, "- Rewards:",
				location.rewards.food, "food,",
				location.rewards.batteries, "batteries,",
				location.rewards.wood, "wood")
		end
	end
end

-- Player connections
Players.PlayerAdded:Connect(initPlayer)
Players.PlayerRemoving:Connect(cleanupPlayer)

for _, player in Players:GetPlayers() do
	initPlayer(player)
end

-- Check discoveries every second (performance friendly)
local lastCheck = 0
RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastCheck < 1 then return end
	lastCheck = now

	for _, player in Players:GetPlayers() do
		checkDiscoveries(player)
	end
end)

print("[Discovery] Discovery reward system initialized with", #DISCOVERY_LOCATIONS, "locations!")
