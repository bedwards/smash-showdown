--!strict
-- Elder Scrolls-style NPCs for Mertin-Flemmer
-- Unique characters with personalities, quests, and varied behaviors

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

-- Create remotes for NPC interaction
local NPCDialogueRemote = Instance.new("RemoteEvent")
NPCDialogueRemote.Name = "NPCDialogue"
NPCDialogueRemote.Parent = ReplicatedStorage

local QuestUpdateRemote = Instance.new("RemoteEvent")
QuestUpdateRemote.Name = "QuestUpdate"
QuestUpdateRemote.Parent = ReplicatedStorage

-- ============================================
-- NPC CLASSES - Elder Scrolls Level Variety
-- ============================================
local NPC_CLASSES = {
	WANDERER = {
		name = "Wanderer",
		health = 50,
		speed = 14,
		friendly = true,
		colors = {
			body = Color3.fromRGB(100, 90, 80),
			accent = Color3.fromRGB(60, 50, 40),
		},
		items = { "Food", "Torch", "Map Fragment" },
	},
	MERCHANT = {
		name = "Merchant",
		health = 40,
		speed = 12,
		friendly = true,
		colors = {
			body = Color3.fromRGB(150, 100, 50),
			accent = Color3.fromRGB(200, 180, 100),
		},
		items = { "Battery", "Food", "Wood", "Rare Supplies" },
	},
	WARRIOR = {
		name = "Warrior",
		health = 100,
		speed = 16,
		friendly = true,
		colors = {
			body = Color3.fromRGB(120, 120, 130),
			accent = Color3.fromRGB(80, 80, 90),
		},
		items = { "Weapon", "Armor Scrap", "Battle Horn" },
	},
	MYSTIC = {
		name = "Mystic",
		health = 60,
		speed = 10,
		friendly = true,
		colors = {
			body = Color3.fromRGB(80, 60, 120),
			accent = Color3.fromRGB(150, 100, 200),
		},
		items = { "Crystal Shard", "Prophecy Scroll", "Enchanted Light" },
	},
	HEALER = {
		name = "Healer",
		health = 45,
		speed = 12,
		friendly = true,
		colors = {
			body = Color3.fromRGB(240, 240, 230),
			accent = Color3.fromRGB(200, 50, 50),
		},
		items = { "Healing Salve", "Bandages", "Antidote" },
	},
	SCHOLAR = {
		name = "Scholar",
		health = 35,
		speed = 10,
		friendly = true,
		colors = {
			body = Color3.fromRGB(60, 50, 40),
			accent = Color3.fromRGB(200, 180, 140),
		},
		items = { "Ancient Tome", "Research Notes", "Signal Part Clue" },
	},
	THIEF = {
		name = "Thief",
		health = 55,
		speed = 20,
		friendly = false, -- Steals from you!
		colors = {
			body = Color3.fromRGB(30, 30, 35),
			accent = Color3.fromRGB(50, 50, 55),
		},
		items = { "Lockpick", "Stolen Goods" },
	},
	CULTIST = {
		name = "Cultist",
		health = 70,
		speed = 14,
		friendly = false, -- Hostile!
		colors = {
			body = Color3.fromRGB(40, 20, 30),
			accent = Color3.fromRGB(150, 50, 50),
		},
		items = { "Dark Artifact", "Cursed Relic" },
	},
	HERMIT = {
		name = "Hermit",
		health = 40,
		speed = 8,
		friendly = true,
		colors = {
			body = Color3.fromRGB(80, 70, 60),
			accent = Color3.fromRGB(100, 90, 80),
		},
		items = { "Survival Tips", "Hidden Cache Location", "Ancient Secret" },
	},
	RANGER = {
		name = "Ranger",
		health = 80,
		speed = 18,
		friendly = true,
		colors = {
			body = Color3.fromRGB(60, 80, 50),
			accent = Color3.fromRGB(100, 120, 80),
		},
		items = { "Tracking Map", "Beast Lure", "Campfire Kit" },
	},
}

-- ============================================
-- UNIQUE NPC NAMES AND PERSONALITIES
-- ============================================
local NPC_NAMES = {
	WANDERER = { "Joric the Lost", "Elena Dustwalker", "Old Finn", "Mira Shadowstep", "Torvald Grim" },
	MERCHANT = { "Belethor", "Ysolda Coinpurse", "Khajiit Trader", "Mallus Goldhand", "Adrianne" },
	WARRIOR = { "Uthgerd the Unbroken", "Farkas Steelheart", "Aela Huntress", "Vilkas Grimclaw", "Mjoll the Lioness" },
	MYSTIC = { "Farengar Secret-Fire", "Wylandriah", "Sybille Stentor", "Drevis Neloren", "Phinis Gestor" },
	HEALER = { "Danica Pure-Spring", "Bothela Wise", "Elgrim", "Arcadia", "Zaria of Falkreath" },
	SCHOLAR = { "Urag gro-Shub", "Calcelmo", "Tolfdir the Ancient", "Enthir", "Sergius Turrianus" },
	THIEF = { "Brynjolf", "Sapphire", "Delvin Mallory", "Vex", "Mercer Frey" },
	CULTIST = { "Miraak's Follower", "Harkon's Servant", "Namira's Chosen", "Boethiah's Voice", "Dark Witness" },
	HERMIT = { "Anise", "Froki Whetted-Blade", "The Old Orc", "Peryite's Hermit", "Septimus Signus" },
	RANGER = { "Faendal", "Angi", "Aerin Tracker", "Sven Woodsman", "Golldir Scout" },
}

local NPC_DIALOGUE = {
	WANDERER = {
		greeting = { "Lost? So am I...", "The nights grow darker.", "Have you seen the others?", "Stay close to the fire, friend." },
		gift = { "Here, take this. You need it more than I do.", "Found this on my travels.", "May this help you survive." },
		quest = { "I'm looking for my brother. He went toward the frozen wastes...", "There's something strange in the volcanic region..." },
	},
	MERCHANT = {
		greeting = { "Looking to trade?", "I have wares, if you have coin... er, supplies.", "Business is hard when monsters roam.", "Everything must go! Especially me!" },
		gift = { "A sample of my finest goods.", "Consider it a future investment.", "First one's free, friend." },
		quest = { "My supply cart was raided. Help me recover it?", "I need an escort to the desert oasis..." },
	},
	WARRIOR = {
		greeting = { "The weak don't survive here.", "I've killed a hundred creatures.", "Stand behind me if you wish to live.", "Glory awaits those who fight!" },
		gift = { "Take this. Earned it in battle.", "A warrior's gift.", "You'll need this for what's coming." },
		quest = { "There's a creature den that needs clearing...", "Join me in hunting the great beast!" },
	},
	MYSTIC = {
		greeting = { "The stars foretold your coming...", "I sense great destiny in you.", "The veil between worlds thins...", "Curious energies surround you." },
		gift = { "This crystal holds ancient power.", "A gift from beyond the veil.", "May the arcane protect you." },
		quest = { "I need components for a ritual...", "The crystal caverns hold secrets I must uncover..." },
	},
	HEALER = {
		greeting = { "You look wounded. Let me help.", "Mara's blessing upon you.", "Rest here, traveler.", "I tend to all who need aid." },
		gift = { "This salve will heal your wounds.", "Take these supplies.", "Health is the greatest treasure." },
		quest = { "I need rare herbs from the swamp...", "Someone in the desert needs urgent care..." },
	},
	SCHOLAR = {
		greeting = { "Fascinating! A survivor!", "I'm studying the phenomenon...", "Do you know what caused all this?", "The answer lies in ancient texts..." },
		gift = { "My research notes might help you.", "Knowledge is power.", "This tome contains valuable information." },
		quest = { "I need a rubbing from the ancient temple...", "Help me collect samples from each biome..." },
	},
	THIEF = {
		greeting = { "Nice supplies you got there...", "Don't worry, I'm friendly. Mostly.", "Shadows keep their secrets.", "Looking a bit too comfortable, aren't we?" },
		steal = { "Thanks for the donation!", "You won't miss this.", "Quick hands make light work." },
		quest = { "There's a vault in the ice fortress...", "Help me with a heist and we split the take..." },
	},
	CULTIST = {
		greeting = { "The darkness calls to you...", "Join us, or perish.", "Your soul will fuel the awakening!", "The old ones stir..." },
		threat = { "You cannot escape what comes!", "Your light means nothing!", "DARKNESS ETERNAL!" },
	},
	HERMIT = {
		greeting = { "Few find my dwelling.", "I've watched these lands for decades.", "The secrets of survival I know well.", "Company... unexpected." },
		gift = { "This cache location will serve you well.", "Ancient knowledge, freely given.", "Survival wisdom, hard-earned." },
		quest = { "Find the three standing stones...", "There is wisdom in each biome..." },
	},
	RANGER = {
		greeting = { "The forest speaks to those who listen.", "I track all who enter these woods.", "Nature provides for the worthy.", "You move loudly. I'll teach you." },
		gift = { "This map shows safe passages.", "Nature's bounty.", "A ranger's gift to a fellow survivor." },
		quest = { "The beast migration is disrupted...", "Help me establish ranger outposts..." },
	},
}

-- ============================================
-- QUEST DEFINITIONS
-- ============================================
local QUESTS = {
	{ id = "find_brother", giver = "WANDERER", title = "The Lost Brother", objective = "Search the Frozen Wastes for Joric's brother", reward = "Map Fragment" },
	{ id = "recover_cart", giver = "MERCHANT", title = "Merchant's Misfortune", objective = "Recover the supply cart near the Western Gate", reward = "Rare Supplies" },
	{ id = "clear_den", giver = "WARRIOR", title = "Monster Hunt", objective = "Clear the creature den in the volcanic region", reward = "Battle Horn" },
	{ id = "crystal_ritual", giver = "MYSTIC", title = "The Ritual Components", objective = "Gather 3 crystal shards from the Shimmering Caverns", reward = "Enchanted Light" },
	{ id = "rare_herbs", giver = "HEALER", title = "Healing Herbs", objective = "Find medicinal herbs in the Murky Depths", reward = "Healing Salve" },
	{ id = "temple_rubbing", giver = "SCHOLAR", title = "Ancient Knowledge", objective = "Get a rubbing from the Ancient Temple in the desert", reward = "Signal Part Clue" },
	{ id = "standing_stones", giver = "HERMIT", title = "Wisdom of the Stones", objective = "Visit all 3 standing stones", reward = "Ancient Secret" },
	{ id = "ranger_outpost", giver = "RANGER", title = "Establishing Safety", objective = "Place 3 campfire kits in the outer regions", reward = "Tracking Map" },
}

-- State
local npcs: { Model } = {}
local npcStates: { [Model]: {
	class: string,
	name: string,
	friendly: boolean,
	interactCooldown: number,
	wanderTarget: Vector3?,
	followTarget: Player?,
	gaveGift: { [Player]: boolean },
	gaveQuest: { [Player]: boolean },
	behavior: string, -- "wander", "approach", "follow", "flee", "attack"
	behaviorTimer: number,
} } = {}

-- Player quest tracking
local playerQuests: { [Player]: { [string]: string } } = {} -- questId -> "active" | "complete"

-- Create NPC with unique appearance
local function createNPC(class: typeof(NPC_CLASSES.WANDERER), position: Vector3, specificName: string?): Model
	local npc = Instance.new("Model")
	local className = ""
	for k, v in NPC_CLASSES do
		if v == class then className = k break end
	end

	local names = NPC_NAMES[className] or { "Unknown" }
	local npcName = specificName or names[math.random(#names)]
	npc.Name = npcName

	-- BODY PARTS with class-specific styling
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2.5, 1)
	torso.Color = class.colors.body
	torso.Material = Enum.Material.Fabric
	torso.Parent = npc

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.3, 1.3, 1.3)
	head.Color = Color3.fromRGB(255, 220, 180)
	head.Material = Enum.Material.SmoothPlastic
	head.Parent = npc

	-- Face based on friendliness
	local face = Instance.new("Decal")
	face.Face = Enum.NormalId.Front
	face.Texture = class.friendly and "rbxassetid://7075769910" or "rbxassetid://152153524" -- Friendly or angry
	face.Parent = head

	-- Class-specific accessories
	if className == "WARRIOR" then
		-- Helmet
		local helmet = Instance.new("Part")
		helmet.Name = "Helmet"
		helmet.Size = Vector3.new(1.5, 0.8, 1.5)
		helmet.Color = class.colors.accent
		helmet.Material = Enum.Material.Metal
		helmet.Parent = npc

		-- Shoulder armor
		local shoulder = Instance.new("Part")
		shoulder.Name = "ShoulderArmor"
		shoulder.Size = Vector3.new(0.8, 0.5, 0.8)
		shoulder.Color = class.colors.accent
		shoulder.Material = Enum.Material.Metal
		shoulder.Parent = npc
	elseif className == "MYSTIC" then
		-- Hood
		local hood = Instance.new("Part")
		hood.Name = "Hood"
		hood.Size = Vector3.new(1.6, 1.2, 1.4)
		hood.Color = class.colors.body
		hood.Material = Enum.Material.Fabric
		hood.Transparency = 0.2
		hood.Parent = npc

		-- Glowing staff
		local staff = Instance.new("Part")
		staff.Name = "Staff"
		staff.Size = Vector3.new(0.3, 5, 0.3)
		staff.Color = class.colors.accent
		staff.Material = Enum.Material.Neon
		staff.Parent = npc
	elseif className == "MERCHANT" then
		-- Backpack
		local backpack = Instance.new("Part")
		backpack.Name = "Backpack"
		backpack.Size = Vector3.new(1.5, 2, 1)
		backpack.Color = class.colors.accent
		backpack.Material = Enum.Material.Fabric
		backpack.Parent = npc
	elseif className == "HEALER" then
		-- White robes (larger torso)
		torso.Size = Vector3.new(2.5, 3, 1.5)

		-- Red cross symbol
		local cross = Instance.new("Part")
		cross.Name = "Cross"
		cross.Size = Vector3.new(0.8, 1.2, 0.1)
		cross.Color = class.colors.accent
		cross.Material = Enum.Material.Neon
		cross.Parent = npc
	elseif className == "THIEF" or className == "CULTIST" then
		-- Dark hood
		local darkHood = Instance.new("Part")
		darkHood.Name = "DarkHood"
		darkHood.Size = Vector3.new(1.5, 1.4, 1.3)
		darkHood.Color = class.colors.body
		darkHood.Material = Enum.Material.Fabric
		darkHood.Parent = npc
	elseif className == "RANGER" then
		-- Cloak
		local cloak = Instance.new("Part")
		cloak.Name = "Cloak"
		cloak.Size = Vector3.new(2.2, 2.8, 0.3)
		cloak.Color = class.colors.body
		cloak.Material = Enum.Material.Fabric
		cloak.Transparency = 0.3
		cloak.Parent = npc

		-- Bow
		local bow = Instance.new("Part")
		bow.Name = "Bow"
		bow.Size = Vector3.new(0.2, 3, 0.5)
		bow.Color = Color3.fromRGB(100, 70, 50)
		bow.Material = Enum.Material.Wood
		bow.Parent = npc
	end

	-- Arms and legs
	local leftArm = Instance.new("Part")
	leftArm.Name = "Left Arm"
	leftArm.Size = Vector3.new(1, 2, 1)
	leftArm.Color = class.colors.body
	leftArm.Material = Enum.Material.Fabric
	leftArm.Parent = npc

	local rightArm = Instance.new("Part")
	rightArm.Name = "Right Arm"
	rightArm.Size = Vector3.new(1, 2, 1)
	rightArm.Color = class.colors.body
	rightArm.Material = Enum.Material.Fabric
	rightArm.Parent = npc

	local leftLeg = Instance.new("Part")
	leftLeg.Name = "Left Leg"
	leftLeg.Size = Vector3.new(1, 2, 1)
	leftLeg.Color = class.colors.accent
	leftLeg.Material = Enum.Material.Fabric
	leftLeg.Parent = npc

	local rightLeg = Instance.new("Part")
	rightLeg.Name = "Right Leg"
	rightLeg.Size = Vector3.new(1, 2, 1)
	rightLeg.Color = class.colors.accent
	rightLeg.Material = Enum.Material.Fabric
	rightLeg.Parent = npc

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.Parent = npc

	-- Humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = class.health
	humanoid.Health = class.health
	humanoid.WalkSpeed = class.speed
	humanoid.Parent = npc

	-- Weld parts
	local function weld(part0: BasePart, part1: BasePart, c0: CFrame)
		local motor = Instance.new("Motor6D")
		motor.Part0 = part0
		motor.Part1 = part1
		motor.C0 = c0
		motor.Parent = part0
	end

	npc.PrimaryPart = rootPart
	rootPart.Position = position + Vector3.new(0, 3, 0)
	torso.Position = position + Vector3.new(0, 3, 0)
	head.Position = position + Vector3.new(0, 4.6, 0)
	leftArm.Position = position + Vector3.new(-1.5, 3, 0)
	rightArm.Position = position + Vector3.new(1.5, 3, 0)
	leftLeg.Position = position + Vector3.new(-0.5, 1, 0)
	rightLeg.Position = position + Vector3.new(0.5, 1, 0)

	weld(rootPart, torso, CFrame.new())
	weld(torso, head, CFrame.new(0, 1.9, 0))
	weld(torso, leftArm, CFrame.new(-1.5, 0.2, 0))
	weld(torso, rightArm, CFrame.new(1.5, 0.2, 0))
	weld(torso, leftLeg, CFrame.new(-0.5, -2.2, 0))
	weld(torso, rightLeg, CFrame.new(0.5, -2.2, 0))

	-- Name tag with class
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 150, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.Adornee = head
	billboard.Parent = npc

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = npcName
	nameLabel.TextColor3 = class.friendly and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.Parent = billboard

	local classLabel = Instance.new("TextLabel")
	classLabel.Size = UDim2.new(1, 0, 0.3, 0)
	classLabel.Position = UDim2.new(0, 0, 0.5, 0)
	classLabel.BackgroundTransparency = 1
	classLabel.Text = "<" .. class.name .. ">"
	classLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	classLabel.Font = Enum.Font.Gotham
	classLabel.TextSize = 10
	classLabel.Parent = billboard

	-- Dialogue bubble
	local dialogueLabel = Instance.new("TextLabel")
	dialogueLabel.Name = "Dialogue"
	dialogueLabel.Size = UDim2.new(1, 0, 0.3, 0)
	dialogueLabel.Position = UDim2.new(0, 0, 0.8, 0)
	dialogueLabel.BackgroundTransparency = 1
	dialogueLabel.Text = ""
	dialogueLabel.TextColor3 = Color3.new(1, 1, 1)
	dialogueLabel.TextStrokeTransparency = 0.5
	dialogueLabel.Font = Enum.Font.Gotham
	dialogueLabel.TextSize = 10
	dialogueLabel.TextWrapped = true
	dialogueLabel.Parent = billboard

	npc.Parent = workspace
	return npc
end

-- Show dialogue
local function showDialogue(npc: Model, text: string)
	local billboard = npc:FindFirstChildOfClass("BillboardGui")
	if billboard then
		local dialogueLabel = billboard:FindFirstChild("Dialogue") :: TextLabel?
		if dialogueLabel then
			dialogueLabel.Text = '"' .. text .. '"'
			task.delay(5, function()
				if dialogueLabel then
					dialogueLabel.Text = ""
				end
			end)
		end
	end
end

-- Find closest player
local function findClosestPlayer(position: Vector3): (Player?, number)
	local closest: Player? = nil
	local closestDist = math.huge

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then continue end

		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not rootPart then continue end

		local dist = (rootPart.Position - position).Magnitude
		if dist < closestDist then
			closestDist = dist
			closest = player
		end
	end

	return closest, closestDist
end

-- NPC interaction
local function interactWithPlayer(npc: Model, player: Player, state: typeof(npcStates[npc]))
	local className = state.class
	local classData = NPC_CLASSES[className]
	local dialogue = NPC_DIALOGUE[className]

	if not classData or not dialogue then return end

	if classData.friendly then
		-- Friendly interaction
		if not state.gaveGift[player] and math.random() < 0.7 then
			-- Give gift
			state.gaveGift[player] = true
			local giftDialogue = dialogue.gift and dialogue.gift[math.random(#dialogue.gift)] or "Here, take this."
			showDialogue(npc, giftDialogue)

			local item = classData.items[math.random(#classData.items)]
			NPCDialogueRemote:FireClient(player, "GIFT", state.name, item)
			print("[NPC]", state.name, "gave", item, "to", player.Name)
		elseif not state.gaveQuest[player] and dialogue.quest and math.random() < 0.5 then
			-- Offer quest
			state.gaveQuest[player] = true
			local questDialogue = dialogue.quest[math.random(#dialogue.quest)]
			showDialogue(npc, questDialogue)

			-- Find matching quest
			for _, quest in QUESTS do
				if quest.giver == className then
					playerQuests[player] = playerQuests[player] or {}
					if not playerQuests[player][quest.id] then
						playerQuests[player][quest.id] = "active"
						QuestUpdateRemote:FireClient(player, "NEW_QUEST", quest)
						print("[NPC]", state.name, "gave quest to", player.Name, ":", quest.title)
						break
					end
				end
			end
		else
			-- Just greet
			local greeting = dialogue.greeting[math.random(#dialogue.greeting)]
			showDialogue(npc, greeting)
		end
	else
		-- Hostile/unfriendly
		if className == "THIEF" then
			local stealDialogue = dialogue.steal and dialogue.steal[math.random(#dialogue.steal)] or "Mine now!"
			showDialogue(npc, stealDialogue)
			NPCDialogueRemote:FireClient(player, "STOLEN", state.name, "Food")
		elseif className == "CULTIST" then
			local threatDialogue = dialogue.threat and dialogue.threat[math.random(#dialogue.threat)] or "DARKNESS!"
			showDialogue(npc, threatDialogue)
			-- Cultist attacks
			state.behavior = "attack"
		end
	end
end

-- Update NPC behavior
local function updateNPC(npc: Model, dt: number)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local rootPart = npc:FindFirstChild("HumanoidRootPart") :: BasePart?

	if not humanoid or not rootPart then return end
	if humanoid.Health <= 0 then return end

	local state = npcStates[npc]
	if not state then return end

	local position = rootPart.Position
	local classData = NPC_CLASSES[state.class]

	-- Update behavior timer
	state.behaviorTimer -= dt

	-- Find closest player
	local player, distance = findClosestPlayer(position)

	-- Check for interaction cooldown
	state.interactCooldown = math.max(0, state.interactCooldown - dt)

	-- Behavior state machine
	if state.behavior == "wander" then
		-- Wander around
		if not state.wanderTarget or (position - state.wanderTarget).Magnitude < 5 or state.behaviorTimer <= 0 then
			state.wanderTarget = position + Vector3.new(
				(math.random() - 0.5) * 100,
				0,
				(math.random() - 0.5) * 100
			)
			state.behaviorTimer = 10 + math.random() * 10
		end
		humanoid:MoveTo(state.wanderTarget)

		-- Maybe approach a nearby player
		if player and distance < 50 and classData.friendly and math.random() < 0.01 then
			state.behavior = "approach"
			state.followTarget = player
			state.behaviorTimer = 15
		end

		-- Hostile NPCs aggro
		if player and distance < 30 and not classData.friendly then
			state.behavior = "approach"
			state.followTarget = player
			state.behaviorTimer = 20
		end

	elseif state.behavior == "approach" then
		-- Move toward player
		if state.followTarget and state.followTarget.Character then
			local targetRoot = state.followTarget.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if targetRoot then
				humanoid:MoveTo(targetRoot.Position)

				local dist = (targetRoot.Position - position).Magnitude
				if dist < 8 and state.interactCooldown <= 0 then
					-- Interact!
					interactWithPlayer(npc, state.followTarget, state)
					state.interactCooldown = 30 -- Don't interact again for 30 seconds
					state.behavior = "flee"
					state.behaviorTimer = 10
				end
			end
		end

		if state.behaviorTimer <= 0 then
			state.behavior = "wander"
		end

	elseif state.behavior == "flee" then
		-- Run away after interaction
		if player and player.Character then
			local playerRoot = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if playerRoot then
				local awayDir = (position - playerRoot.Position).Unit
				humanoid:MoveTo(position + awayDir * 50)
			end
		end

		if state.behaviorTimer <= 0 then
			state.behavior = "wander"
		end

	elseif state.behavior == "attack" then
		-- Hostile attack behavior
		if state.followTarget and state.followTarget.Character then
			local targetRoot = state.followTarget.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local targetHumanoid = state.followTarget.Character:FindFirstChildOfClass("Humanoid")
			if targetRoot and targetHumanoid then
				humanoid:MoveTo(targetRoot.Position)

				local dist = (targetRoot.Position - position).Magnitude
				if dist < 6 then
					targetHumanoid:TakeDamage(5)
				end
			end
		end

		if state.behaviorTimer <= 0 then
			state.behavior = "wander"
		end
	end
end

-- Spawn NPCs across the world
local function spawnNPCs()
	task.wait(5) -- Wait for world to generate

	print("[NPC] Spawning Elder Scrolls-style NPCs across all biomes...")

	-- Spawn locations with class preferences
	local spawnConfigs = {
		-- Central/Forest area
		{ pos = Vector3.new(100, 0, 100), class = "WANDERER" },
		{ pos = Vector3.new(-150, 0, 50), class = "MERCHANT" },
		{ pos = Vector3.new(80, 0, -120), class = "HEALER" },
		{ pos = Vector3.new(-80, 0, -80), class = "SCHOLAR" },

		-- Frozen Wastes
		{ pos = Vector3.new(1900, 0, 100), class = "RANGER" },
		{ pos = Vector3.new(2100, 0, -200), class = "WARRIOR" },
		{ pos = Vector3.new(2300, 0, 300), class = "HERMIT" },

		-- Desert
		{ pos = Vector3.new(1400, 0, 1900), class = "MERCHANT" },
		{ pos = Vector3.new(1700, 0, 2100), class = "SCHOLAR" },
		{ pos = Vector3.new(1600, 0, 2300), class = "WANDERER" },

		-- Volcanic
		{ pos = Vector3.new(-1900, 0, 1400), class = "CULTIST" },
		{ pos = Vector3.new(-2100, 0, 1600), class = "MYSTIC" },
		{ pos = Vector3.new(-2300, 0, 1200), class = "WARRIOR" },

		-- Swamp
		{ pos = Vector3.new(-1400, 0, -1400), class = "HERMIT" },
		{ pos = Vector3.new(-1600, 0, -1600), class = "HEALER" },
		{ pos = Vector3.new(-1200, 0, -1800), class = "THIEF" },

		-- Crystal Caverns
		{ pos = Vector3.new(100, 0, -2400), class = "MYSTIC" },
		{ pos = Vector3.new(-100, 0, -2600), class = "SCHOLAR" },
		{ pos = Vector3.new(200, 0, -2800), class = "CULTIST" },

		-- Random wanderers
		{ pos = Vector3.new(500, 0, 500), class = "WANDERER" },
		{ pos = Vector3.new(-600, 0, 400), class = "RANGER" },
		{ pos = Vector3.new(700, 0, -300), class = "WARRIOR" },
		{ pos = Vector3.new(-400, 0, -700), class = "THIEF" },
	}

	for _, config in spawnConfigs do
		local class = NPC_CLASSES[config.class]
		if class then
			local npc = createNPC(class, config.pos)
			table.insert(npcs, npc)

			npcStates[npc] = {
				class = config.class,
				name = npc.Name,
				friendly = class.friendly,
				interactCooldown = 0,
				wanderTarget = nil,
				followTarget = nil,
				gaveGift = {},
				gaveQuest = {},
				behavior = "wander",
				behaviorTimer = math.random() * 10,
			}

			print("[NPC] Spawned", npc.Name, "(" .. class.name .. ")")
		end
	end

	print("[NPC] Spawned", #npcs, "unique NPCs across the world!")
end

-- Initialize player quest tracking
Players.PlayerAdded:Connect(function(player)
	playerQuests[player] = {}
end)

Players.PlayerRemoving:Connect(function(player)
	playerQuests[player] = nil
end)

-- Game loop
RunService.Heartbeat:Connect(function(dt)
	for _, npc in npcs do
		if npc and npc.Parent then
			updateNPC(npc, dt)
		end
	end
end)

-- Initialize
spawnNPCs()
print("[NPC] Elder Scrolls-style NPC system initialized!")
print("[NPC] - 10 unique NPC classes")
print("[NPC] - Friendly NPCs give gifts and quests")
print("[NPC] - Thieves steal from you")
print("[NPC] - Cultists attack!")
print("[NPC] - Each NPC has unique dialogue and personality")
