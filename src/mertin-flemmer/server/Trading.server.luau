--!strict
-- Trading & Economy System for Mertin-Flemmer
-- Buy and sell items with merchants, currency system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

-- Create remotes
local TradingRemote = Instance.new("RemoteEvent")
TradingRemote.Name = "Trading"
TradingRemote.Parent = ReplicatedStorage

local OpenShopRemote = Instance.new("RemoteEvent")
OpenShopRemote.Name = "OpenShop"
OpenShopRemote.Parent = ReplicatedStorage

-- ==========================================
-- ITEM DEFINITIONS
-- ==========================================

type Item = {
	id: string,
	name: string,
	description: string,
	category: string,
	buyPrice: number,
	sellPrice: number,
	stackable: boolean,
	maxStack: number,
	effect: string?,
}

local ITEMS: { [string]: Item } = {
	-- Consumables
	food = {
		id = "food",
		name = "Dried Meat",
		description = "Restores hunger when eaten.",
		category = "consumable",
		buyPrice = 10,
		sellPrice = 3,
		stackable = true,
		maxStack = 20,
		effect = "restore_hunger_30",
	},
	battery = {
		id = "battery",
		name = "Battery Pack",
		description = "Recharges your flashlight.",
		category = "consumable",
		buyPrice = 25,
		sellPrice = 8,
		stackable = true,
		maxStack = 10,
		effect = "recharge_flashlight",
	},
	wood = {
		id = "wood",
		name = "Firewood",
		description = "Fuel for campfires.",
		category = "material",
		buyPrice = 5,
		sellPrice = 2,
		stackable = true,
		maxStack = 50,
	},
	health_potion = {
		id = "health_potion",
		name = "Healing Tonic",
		description = "Restores 50 health.",
		category = "consumable",
		buyPrice = 50,
		sellPrice = 15,
		stackable = true,
		maxStack = 5,
		effect = "restore_health_50",
	},
	stamina_potion = {
		id = "stamina_potion",
		name = "Vigor Elixir",
		description = "Instantly restores stamina.",
		category = "consumable",
		buyPrice = 35,
		sellPrice = 10,
		stackable = true,
		maxStack = 5,
		effect = "restore_stamina_full",
	},

	-- Equipment
	torch = {
		id = "torch",
		name = "Torch",
		description = "A handheld light source.",
		category = "equipment",
		buyPrice = 20,
		sellPrice = 5,
		stackable = false,
		maxStack = 1,
	},
	lantern = {
		id = "lantern",
		name = "Oil Lantern",
		description = "Long-lasting portable light.",
		category = "equipment",
		buyPrice = 100,
		sellPrice = 30,
		stackable = false,
		maxStack = 1,
	},
	compass = {
		id = "compass",
		name = "Compass",
		description = "Always points north.",
		category = "equipment",
		buyPrice = 75,
		sellPrice = 20,
		stackable = false,
		maxStack = 1,
	},

	-- Materials
	wolf_pelt = {
		id = "wolf_pelt",
		name = "Wolf Pelt",
		description = "Fur from a wolf. Used in crafting.",
		category = "material",
		buyPrice = 40,
		sellPrice = 25,
		stackable = true,
		maxStack = 10,
	},
	crystal_shard = {
		id = "crystal_shard",
		name = "Crystal Shard",
		description = "Glowing fragment from cave crystals.",
		category = "material",
		buyPrice = 60,
		sellPrice = 35,
		stackable = true,
		maxStack = 20,
	},
	herb = {
		id = "herb",
		name = "Healing Herb",
		description = "Used in alchemy.",
		category = "material",
		buyPrice = 15,
		sellPrice = 5,
		stackable = true,
		maxStack = 30,
	},
	mushroom = {
		id = "mushroom",
		name = "Glowing Mushroom",
		description = "Bioluminescent fungus. Alchemical ingredient.",
		category = "material",
		buyPrice = 20,
		sellPrice = 8,
		stackable = true,
		maxStack = 30,
	},

	-- Rare items
	stalker_tooth = {
		id = "stalker_tooth",
		name = "Stalker's Tooth",
		description = "Trophy from the Deer Monster. Extremely rare.",
		category = "rare",
		buyPrice = 500,
		sellPrice = 200,
		stackable = false,
		maxStack = 1,
	},
	blood_moon_crystal = {
		id = "blood_moon_crystal",
		name = "Blood Moon Crystal",
		description = "Formed during blood nights. Powerful.",
		category = "rare",
		buyPrice = 300,
		sellPrice = 150,
		stackable = true,
		maxStack = 5,
	},
}

-- ==========================================
-- MERCHANT DEFINITIONS
-- ==========================================

type MerchantShop = {
	name: string,
	greeting: string,
	farewell: string,
	inventory: { string }, -- Item IDs they sell
	buyMultiplier: number, -- Price multiplier for buying
	sellMultiplier: number, -- Price multiplier for selling to them
}

local MERCHANTS: { [string]: MerchantShop } = {
	general = {
		name = "General Goods",
		greeting = "Welcome, traveler! Take a look at my wares.",
		farewell = "Safe travels, friend.",
		inventory = { "food", "battery", "wood", "torch", "health_potion" },
		buyMultiplier = 1.0,
		sellMultiplier = 1.0,
	},
	wandering = {
		name = "Wandering Merchant",
		greeting = "Khajiit has wares if you have coin.",
		farewell = "May your road lead you to warm sands.",
		inventory = { "food", "battery", "lantern", "compass", "stamina_potion", "herb", "mushroom" },
		buyMultiplier = 1.2, -- Slightly higher prices
		sellMultiplier = 0.8,
	},
	alchemist = {
		name = "The Alchemist",
		greeting = "Potions, elixirs, and rare ingredients...",
		farewell = "Use them wisely.",
		inventory = { "health_potion", "stamina_potion", "herb", "mushroom", "crystal_shard" },
		buyMultiplier = 0.9, -- Better prices for alchemy
		sellMultiplier = 1.2, -- Pays more for ingredients
	},
	rare_collector = {
		name = "Collector of Curiosities",
		greeting = "Do you have anything... unusual?",
		farewell = "Bring me more curiosities!",
		inventory = { "stalker_tooth", "blood_moon_crystal", "crystal_shard" },
		buyMultiplier = 1.5, -- Expensive
		sellMultiplier = 1.5, -- But pays well for rare items
	},
}

-- ==========================================
-- PLAYER ECONOMY STATE
-- ==========================================

type PlayerEconomy = {
	gold: number,
	inventory: { [string]: number }, -- itemId -> quantity
}

local playerEconomy: { [Player]: PlayerEconomy } = {}

local function initPlayerEconomy(player: Player)
	playerEconomy[player] = {
		gold = 100, -- Starting gold
		inventory = {
			food = 3,
			battery = 2,
			wood = 5,
		},
	}

	-- Send initial state
	sendInventoryUpdate(player)
end

local function cleanupPlayerEconomy(player: Player)
	playerEconomy[player] = nil
end

function sendInventoryUpdate(player: Player)
	local economy = playerEconomy[player]
	if not economy then return end

	-- Build inventory data with item details
	local inventoryData = {}
	for itemId, quantity in economy.inventory do
		local item = ITEMS[itemId]
		if item and quantity > 0 then
			inventoryData[itemId] = {
				quantity = quantity,
				name = item.name,
				description = item.description,
				category = item.category,
				sellPrice = item.sellPrice,
			}
		end
	end

	TradingRemote:FireClient(player, "INVENTORY_UPDATE", {
		gold = economy.gold,
		inventory = inventoryData,
	})
end

-- ==========================================
-- TRADING FUNCTIONS
-- ==========================================

local function buyItem(player: Player, merchantType: string, itemId: string, quantity: number): (boolean, string)
	local economy = playerEconomy[player]
	if not economy then return false, "No economy data" end

	local merchant = MERCHANTS[merchantType]
	if not merchant then return false, "Unknown merchant" end

	local item = ITEMS[itemId]
	if not item then return false, "Unknown item" end

	-- Check if merchant sells this item
	local sellsItem = false
	for _, id in merchant.inventory do
		if id == itemId then
			sellsItem = true
			break
		end
	end
	if not sellsItem then return false, "Merchant doesn't sell this item" end

	-- Calculate price
	local price = math.ceil(item.buyPrice * merchant.buyMultiplier * quantity)

	-- Check gold
	if economy.gold < price then
		return false, "Not enough gold"
	end

	-- Check stack limit
	local currentQuantity = economy.inventory[itemId] or 0
	if currentQuantity + quantity > item.maxStack then
		return false, "Inventory full for this item"
	end

	-- Execute trade
	economy.gold -= price
	economy.inventory[itemId] = currentQuantity + quantity

	sendInventoryUpdate(player)

	print("[Trading]", player.Name, "bought", quantity, "x", item.name, "for", price, "gold")
	return true, "Purchase successful!"
end

local function sellItem(player: Player, merchantType: string, itemId: string, quantity: number): (boolean, string)
	local economy = playerEconomy[player]
	if not economy then return false, "No economy data" end

	local merchant = MERCHANTS[merchantType]
	if not merchant then return false, "Unknown merchant" end

	local item = ITEMS[itemId]
	if not item then return false, "Unknown item" end

	-- Check if player has enough
	local currentQuantity = economy.inventory[itemId] or 0
	if currentQuantity < quantity then
		return false, "Not enough items"
	end

	-- Calculate price
	local price = math.floor(item.sellPrice * merchant.sellMultiplier * quantity)

	-- Execute trade
	economy.gold += price
	economy.inventory[itemId] = currentQuantity - quantity
	if economy.inventory[itemId] <= 0 then
		economy.inventory[itemId] = nil
	end

	sendInventoryUpdate(player)

	print("[Trading]", player.Name, "sold", quantity, "x", item.name, "for", price, "gold")
	return true, "Sale complete! +" .. price .. " gold"
end

-- ==========================================
-- MERCHANT PROXIMITY DETECTION
-- ==========================================

local activeMerchants: { [Model]: string } = {} -- Model -> merchant type

-- Find all merchant stalls and NPCs
local function registerMerchants()
	-- Find merchant stalls
	for _, obj in workspace:GetDescendants() do
		if obj:IsA("Model") and string.find(obj.Name, "MerchantStall") then
			activeMerchants[obj] = "general"
		end
	end

	-- Find merchant NPCs from Survivor system
	for _, obj in workspace:GetDescendants() do
		if obj:IsA("Model") and obj:GetAttribute("NPCClass") == "MERCHANT" then
			-- Assign random merchant type based on name
			local name = obj.Name
			if string.find(name, "Khajiit") then
				activeMerchants[obj] = "wandering"
			elseif string.find(name, "Alchemist") or string.find(name, "Potion") then
				activeMerchants[obj] = "alchemist"
			elseif string.find(name, "Collector") or string.find(name, "Curiosit") then
				activeMerchants[obj] = "rare_collector"
			else
				activeMerchants[obj] = "general"
			end
		end
	end

	print("[Trading] Registered", #activeMerchants, "merchants")
end

-- Check player proximity to merchants
local function checkMerchantProximity()
	for player, economy in playerEconomy do
		local character = player.Character
		if not character then continue end

		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not rootPart then continue end

		local playerPos = rootPart.Position

		for merchantModel, merchantType in activeMerchants do
			if not merchantModel or not merchantModel.Parent then continue end

			local merchantPos: Vector3
			if merchantModel:IsA("Model") then
				local primary = merchantModel.PrimaryPart or merchantModel:FindFirstChildWhichIsA("BasePart")
				if primary then
					merchantPos = primary.Position
				else
					continue
				end
			end

			local distance = (playerPos - merchantPos).Magnitude

			-- Open shop when close enough
			if distance < 10 then
				local merchant = MERCHANTS[merchantType]
				if merchant then
					-- Build shop data
					local shopItems = {}
					for _, itemId in merchant.inventory do
						local item = ITEMS[itemId]
						if item then
							shopItems[itemId] = {
								name = item.name,
								description = item.description,
								category = item.category,
								buyPrice = math.ceil(item.buyPrice * merchant.buyMultiplier),
								sellPrice = math.floor(item.sellPrice * merchant.sellMultiplier),
							}
						end
					end

					OpenShopRemote:FireClient(player, "NEAR_MERCHANT", {
						merchantType = merchantType,
						merchantName = merchant.name,
						greeting = merchant.greeting,
						items = shopItems,
					})
				end
			end
		end
	end
end

-- ==========================================
-- REMOTE HANDLERS
-- ==========================================

TradingRemote.OnServerEvent:Connect(function(player: Player, action: string, data: any)
	if action == "BUY" then
		local success, message = buyItem(player, data.merchantType, data.itemId, data.quantity or 1)
		TradingRemote:FireClient(player, "TRADE_RESULT", { success = success, message = message })
	elseif action == "SELL" then
		local success, message = sellItem(player, data.merchantType, data.itemId, data.quantity or 1)
		TradingRemote:FireClient(player, "TRADE_RESULT", { success = success, message = message })
	elseif action == "GET_INVENTORY" then
		sendInventoryUpdate(player)
	end
end)

-- ==========================================
-- GOLD REWARDS
-- ==========================================

-- Listen for mission completions to award gold
local MissionCompleteRemote = ReplicatedStorage:WaitForChild("MissionComplete", 5)
if MissionCompleteRemote then
	-- Award gold when missions complete (integrate with mission system)
	-- For now, we'll award gold on various events
end

-- Award gold for killing creatures
local function awardGoldForKill(player: Player, creatureType: string)
	local economy = playerEconomy[player]
	if not economy then return end

	local goldRewards = {
		Wolf = 5,
		Bear = 15,
		Owl = 3,
		Ram = 8,
		Shadow = 10,
		Wendigo = 50,
		DeerMonster = 0, -- Can't kill it
	}

	local reward = 0
	for creatureName, amount in goldRewards do
		if string.find(creatureType, creatureName) then
			reward = amount
			break
		end
	end

	if reward > 0 then
		economy.gold += reward
		TradingRemote:FireClient(player, "GOLD_EARNED", { amount = reward, source = "creature" })
		sendInventoryUpdate(player)
	end
end

-- ==========================================
-- GAME LOOP
-- ==========================================

local proximityTimer = 0
RunService.Heartbeat:Connect(function(dt)
	proximityTimer += dt
	if proximityTimer >= 1 then -- Check every second
		proximityTimer = 0
		checkMerchantProximity()
	end
end)

-- ==========================================
-- PLAYER SETUP
-- ==========================================

Players.PlayerAdded:Connect(function(player)
	task.wait(3) -- Wait for other systems
	initPlayerEconomy(player)
end)

Players.PlayerRemoving:Connect(cleanupPlayerEconomy)

-- Initialize existing players
for _, player in Players:GetPlayers() do
	task.spawn(function()
		task.wait(3)
		initPlayerEconomy(player)
	end)
end

-- Register merchants after world loads
task.spawn(function()
	task.wait(5)
	registerMerchants()
end)

print("[Trading] Economy system initialized!")
print("[Trading] Players start with 100 gold")
print("[Trading] Find merchants to buy and sell items")
