--!strict
-- Alchemy & Crafting System for Mertin-Flemmer
-- Combine ingredients to create potions, weapons, and gear

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

-- Wait for trading system
local TradingRemote = ReplicatedStorage:WaitForChild("Trading") :: RemoteEvent

-- Create remotes
local AlchemyRemote = Instance.new("RemoteEvent")
AlchemyRemote.Name = "Alchemy"
AlchemyRemote.Parent = ReplicatedStorage

-- ==========================================
-- RECIPE DEFINITIONS
-- ==========================================

type Recipe = {
	id: string,
	name: string,
	description: string,
	category: string, -- "potion", "weapon", "armor", "tool", "enchantment"
	ingredients: { [string]: number }, -- itemId -> quantity needed
	result: string, -- itemId produced
	resultQuantity: number,
	craftTime: number, -- seconds
	skillRequired: number, -- alchemy skill level needed
	experienceGain: number, -- skill XP gained
}

local RECIPES: { [string]: Recipe } = {
	-- POTIONS
	healing_potion = {
		id = "healing_potion",
		name = "Healing Tonic",
		description = "Restores 50 health points.",
		category = "potion",
		ingredients = { herb = 2, mushroom = 1 },
		result = "health_potion",
		resultQuantity = 1,
		craftTime = 3,
		skillRequired = 0,
		experienceGain = 10,
	},
	greater_healing = {
		id = "greater_healing",
		name = "Greater Healing Potion",
		description = "Restores 100 health points.",
		category = "potion",
		ingredients = { herb = 4, mushroom = 2, crystal_shard = 1 },
		result = "greater_health_potion",
		resultQuantity = 1,
		craftTime = 5,
		skillRequired = 20,
		experienceGain = 25,
	},
	stamina_elixir = {
		id = "stamina_elixir",
		name = "Vigor Elixir",
		description = "Instantly restores stamina.",
		category = "potion",
		ingredients = { herb = 1, food = 1 },
		result = "stamina_potion",
		resultQuantity = 1,
		craftTime = 2,
		skillRequired = 0,
		experienceGain = 8,
	},
	night_vision = {
		id = "night_vision",
		name = "Night Eye Potion",
		description = "See clearly in darkness for 5 minutes.",
		category = "potion",
		ingredients = { mushroom = 3, crystal_shard = 1 },
		result = "night_vision_potion",
		resultQuantity = 1,
		craftTime = 4,
		skillRequired = 15,
		experienceGain = 20,
	},
	creature_ward = {
		id = "creature_ward",
		name = "Creature Ward",
		description = "Repels creatures for 2 minutes.",
		category = "potion",
		ingredients = { wolf_pelt = 1, herb = 2, blood_moon_crystal = 1 },
		result = "creature_ward_potion",
		resultQuantity = 1,
		craftTime = 8,
		skillRequired = 30,
		experienceGain = 40,
	},

	-- TOOLS & EQUIPMENT
	torch_craft = {
		id = "torch_craft",
		name = "Torch",
		description = "A simple light source.",
		category = "tool",
		ingredients = { wood = 3 },
		result = "torch",
		resultQuantity = 2,
		craftTime = 2,
		skillRequired = 0,
		experienceGain = 5,
	},
	lantern_craft = {
		id = "lantern_craft",
		name = "Oil Lantern",
		description = "Long-lasting portable light.",
		category = "tool",
		ingredients = { wood = 5, crystal_shard = 2 },
		result = "lantern",
		resultQuantity = 1,
		craftTime = 6,
		skillRequired = 10,
		experienceGain = 20,
	},

	-- WEAPONS
	wooden_club = {
		id = "wooden_club",
		name = "Wooden Club",
		description = "A basic melee weapon.",
		category = "weapon",
		ingredients = { wood = 8 },
		result = "wooden_club",
		resultQuantity = 1,
		craftTime = 4,
		skillRequired = 0,
		experienceGain = 15,
	},
	crystal_blade = {
		id = "crystal_blade",
		name = "Crystal Blade",
		description = "A shimmering blade infused with crystal energy.",
		category = "weapon",
		ingredients = { wood = 5, crystal_shard = 5, blood_moon_crystal = 1 },
		result = "crystal_blade",
		resultQuantity = 1,
		craftTime = 10,
		skillRequired = 35,
		experienceGain = 60,
	},

	-- ARMOR
	wolf_cloak = {
		id = "wolf_cloak",
		name = "Wolf Fur Cloak",
		description = "Provides warmth and minor protection.",
		category = "armor",
		ingredients = { wolf_pelt = 3 },
		result = "wolf_cloak",
		resultQuantity = 1,
		craftTime = 5,
		skillRequired = 5,
		experienceGain = 20,
	},
	crystal_amulet = {
		id = "crystal_amulet",
		name = "Crystal Amulet",
		description = "Enhances magical abilities.",
		category = "armor",
		ingredients = { crystal_shard = 4, blood_moon_crystal = 1 },
		result = "crystal_amulet",
		resultQuantity = 1,
		craftTime = 8,
		skillRequired = 25,
		experienceGain = 45,
	},

	-- SPECIAL
	stalker_charm = {
		id = "stalker_charm",
		name = "Stalker's Charm",
		description = "Protection from the Deer Monster.",
		category = "enchantment",
		ingredients = { stalker_tooth = 1, blood_moon_crystal = 2, crystal_shard = 3 },
		result = "stalker_charm",
		resultQuantity = 1,
		craftTime = 15,
		skillRequired = 50,
		experienceGain = 100,
	},
}

-- ==========================================
-- PLAYER ALCHEMY STATE
-- ==========================================

type PlayerAlchemy = {
	skill: number, -- Alchemy skill level (0-100)
	experience: number, -- XP toward next level
	knownRecipes: { [string]: boolean },
	currentlyCrafting: string?, -- Recipe ID if crafting
	craftProgress: number, -- 0-1
	craftStartTime: number,
}

local playerAlchemy: { [Player]: PlayerAlchemy } = {}

local function initPlayerAlchemy(player: Player)
	playerAlchemy[player] = {
		skill = 0,
		experience = 0,
		knownRecipes = {
			-- Start with basic recipes
			healing_potion = true,
			stamina_elixir = true,
			torch_craft = true,
			wooden_club = true,
		},
		currentlyCrafting = nil,
		craftProgress = 0,
		craftStartTime = 0,
	}

	sendAlchemyUpdate(player)
end

local function cleanupPlayerAlchemy(player: Player)
	playerAlchemy[player] = nil
end

function sendAlchemyUpdate(player: Player)
	local alchemy = playerAlchemy[player]
	if not alchemy then return end

	-- Build recipe data
	local recipesData = {}
	for recipeId, known in alchemy.knownRecipes do
		if known then
			local recipe = RECIPES[recipeId]
			if recipe then
				-- Check if player can craft (has ingredients)
				local canCraft = recipe.skillRequired <= alchemy.skill

				recipesData[recipeId] = {
					name = recipe.name,
					description = recipe.description,
					category = recipe.category,
					ingredients = recipe.ingredients,
					resultQuantity = recipe.resultQuantity,
					craftTime = recipe.craftTime,
					skillRequired = recipe.skillRequired,
					canCraft = canCraft,
				}
			end
		end
	end

	-- Locked recipes (show what they need)
	local lockedRecipes = {}
	for recipeId, recipe in RECIPES do
		if not alchemy.knownRecipes[recipeId] then
			lockedRecipes[recipeId] = {
				name = recipe.name,
				category = recipe.category,
				skillRequired = recipe.skillRequired,
			}
		end
	end

	AlchemyRemote:FireClient(player, "UPDATE", {
		skill = alchemy.skill,
		experience = alchemy.experience,
		experienceToNextLevel = (alchemy.skill + 1) * 100,
		recipes = recipesData,
		lockedRecipes = lockedRecipes,
		currentlyCrafting = alchemy.currentlyCrafting,
		craftProgress = alchemy.craftProgress,
	})
end

-- ==========================================
-- CRAFTING FUNCTIONS
-- ==========================================

-- Get player inventory from trading system
local function getPlayerInventory(player: Player): { [string]: number }?
	-- This would integrate with Trading.server.luau
	-- For now, we'll use a simple request system
	return nil
end

local function startCrafting(player: Player, recipeId: string): (boolean, string)
	local alchemy = playerAlchemy[player]
	if not alchemy then return false, "No alchemy data" end

	-- Already crafting?
	if alchemy.currentlyCrafting then
		return false, "Already crafting something"
	end

	-- Know the recipe?
	if not alchemy.knownRecipes[recipeId] then
		return false, "Recipe not learned"
	end

	local recipe = RECIPES[recipeId]
	if not recipe then return false, "Unknown recipe" end

	-- Check skill level
	if alchemy.skill < recipe.skillRequired then
		return false, "Alchemy skill too low (need " .. recipe.skillRequired .. ")"
	end

	-- Check ingredients via Trading system
	TradingRemote:FireServer(player, "CHECK_INGREDIENTS", recipe.ingredients)

	-- Start crafting
	alchemy.currentlyCrafting = recipeId
	alchemy.craftProgress = 0
	alchemy.craftStartTime = tick()

	sendAlchemyUpdate(player)

	print("[Alchemy]", player.Name, "started crafting:", recipe.name)
	return true, "Crafting started!"
end

local function cancelCrafting(player: Player)
	local alchemy = playerAlchemy[player]
	if not alchemy then return end

	if alchemy.currentlyCrafting then
		local recipe = RECIPES[alchemy.currentlyCrafting]
		print("[Alchemy]", player.Name, "cancelled crafting:", recipe and recipe.name or "unknown")
	end

	alchemy.currentlyCrafting = nil
	alchemy.craftProgress = 0
	alchemy.craftStartTime = 0

	sendAlchemyUpdate(player)
end

local function completeCrafting(player: Player)
	local alchemy = playerAlchemy[player]
	if not alchemy or not alchemy.currentlyCrafting then return end

	local recipe = RECIPES[alchemy.currentlyCrafting]
	if not recipe then
		cancelCrafting(player)
		return
	end

	-- Consume ingredients (via Trading system)
	for itemId, quantity in recipe.ingredients do
		TradingRemote:FireClient(player, "CONSUME_ITEM", { itemId = itemId, quantity = quantity })
	end

	-- Give result item
	TradingRemote:FireClient(player, "GIVE_ITEM", {
		itemId = recipe.result,
		quantity = recipe.resultQuantity,
	})

	-- Grant experience
	alchemy.experience += recipe.experienceGain

	-- Check for level up
	local expNeeded = (alchemy.skill + 1) * 100
	while alchemy.experience >= expNeeded and alchemy.skill < 100 do
		alchemy.experience -= expNeeded
		alchemy.skill += 1
		expNeeded = (alchemy.skill + 1) * 100

		-- Unlock new recipes at certain levels
		unlockRecipesAtLevel(player, alchemy.skill)

		AlchemyRemote:FireClient(player, "LEVEL_UP", alchemy.skill)
	end

	-- Notify completion
	AlchemyRemote:FireClient(player, "CRAFT_COMPLETE", {
		recipeName = recipe.name,
		resultQuantity = recipe.resultQuantity,
		experienceGain = recipe.experienceGain,
	})

	print("[Alchemy]", player.Name, "completed crafting:", recipe.name)

	alchemy.currentlyCrafting = nil
	alchemy.craftProgress = 0
	alchemy.craftStartTime = 0

	sendAlchemyUpdate(player)
end

function unlockRecipesAtLevel(player: Player, level: number)
	local alchemy = playerAlchemy[player]
	if not alchemy then return end

	-- Unlock recipes based on level thresholds
	for recipeId, recipe in RECIPES do
		if recipe.skillRequired <= level and not alchemy.knownRecipes[recipeId] then
			alchemy.knownRecipes[recipeId] = true
			AlchemyRemote:FireClient(player, "RECIPE_UNLOCKED", recipe.name)
		end
	end
end

-- ==========================================
-- ALCHEMY STATION PROXIMITY
-- ==========================================

local alchemyStations: { BasePart } = {}

local function findAlchemyStations()
	for _, obj in workspace:GetDescendants() do
		if obj:IsA("Model") and string.find(obj.Name, "AlchemyStation") then
			local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
			if primary then
				table.insert(alchemyStations, primary)
			end
		elseif obj:IsA("BasePart") and string.find(obj.Name, "Cauldron") then
			table.insert(alchemyStations, obj)
		end
	end

	print("[Alchemy] Found", #alchemyStations, "alchemy stations")
end

local function checkStationProximity()
	for player, alchemy in playerAlchemy do
		local character = player.Character
		if not character then continue end

		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not rootPart then continue end

		local playerPos = rootPart.Position
		local nearStation = false

		for _, station in alchemyStations do
			if not station or not station.Parent then continue end

			local distance = (playerPos - station.Position).Magnitude
			if distance < 10 then
				nearStation = true
				break
			end
		end

		if nearStation then
			AlchemyRemote:FireClient(player, "NEAR_STATION", true)
		end
	end
end

-- ==========================================
-- UPDATE LOOP
-- ==========================================

local proximityTimer = 0
local craftTimer = 0

RunService.Heartbeat:Connect(function(dt)
	-- Check station proximity
	proximityTimer += dt
	if proximityTimer >= 1 then
		proximityTimer = 0
		checkStationProximity()
	end

	-- Update crafting progress
	craftTimer += dt
	if craftTimer >= 0.1 then
		craftTimer = 0

		for player, alchemy in playerAlchemy do
			if alchemy.currentlyCrafting then
				local recipe = RECIPES[alchemy.currentlyCrafting]
				if recipe then
					local elapsed = tick() - alchemy.craftStartTime
					alchemy.craftProgress = math.min(1, elapsed / recipe.craftTime)

					-- Check completion
					if alchemy.craftProgress >= 1 then
						completeCrafting(player)
					else
						-- Send progress update
						AlchemyRemote:FireClient(player, "CRAFT_PROGRESS", alchemy.craftProgress)
					end
				end
			end
		end
	end
end)

-- ==========================================
-- REMOTE HANDLERS
-- ==========================================

AlchemyRemote.OnServerEvent:Connect(function(player: Player, action: string, data: any)
	if action == "CRAFT" then
		local success, message = startCrafting(player, data.recipeId)
		AlchemyRemote:FireClient(player, "CRAFT_RESULT", { success = success, message = message })
	elseif action == "CANCEL" then
		cancelCrafting(player)
	elseif action == "GET_RECIPES" then
		sendAlchemyUpdate(player)
	end
end)

-- ==========================================
-- PLAYER SETUP
-- ==========================================

Players.PlayerAdded:Connect(function(player)
	task.wait(4)
	initPlayerAlchemy(player)
end)

Players.PlayerRemoving:Connect(cleanupPlayerAlchemy)

-- Initialize existing players
for _, player in Players:GetPlayers() do
	task.spawn(function()
		task.wait(4)
		initPlayerAlchemy(player)
	end)
end

-- Find alchemy stations after world loads
task.spawn(function()
	task.wait(6)
	findAlchemyStations()
end)

print("[Alchemy] Crafting system initialized!")
print("[Alchemy] Find alchemy stations to craft potions and gear")
print("[Alchemy] Unlock more recipes by leveling alchemy skill")
