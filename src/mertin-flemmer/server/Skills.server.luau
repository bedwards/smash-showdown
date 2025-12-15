--!strict
-- Skills System for Mertin-Flemmer
-- Elder Scrolls-style skill-by-doing progression
-- Skills improve through use and grant passive bonuses

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config

-- Create remotes
local SkillsRemote = Instance.new("RemoteEvent")
SkillsRemote.Name = "Skills"
SkillsRemote.Parent = ReplicatedStorage

-- ==========================================
-- SKILL DEFINITIONS
-- ==========================================

type SkillDefinition = {
	id: string,
	name: string,
	description: string,
	category: string, -- "survival", "combat", "crafting", "exploration"
	maxLevel: number,
	bonusPerLevel: number, -- Percentage bonus per level
	bonusType: string, -- What the bonus affects
}

local SKILLS: { [string]: SkillDefinition } = {
	-- SURVIVAL SKILLS
	endurance = {
		id = "endurance",
		name = "Endurance",
		description = "Reduces hunger drain. High endurance lets you explore farther without food.",
		category = "survival",
		maxLevel = 100,
		bonusPerLevel = 0.5, -- 0.5% less hunger drain per level (50% reduction at max)
		bonusType = "hunger_reduction",
	},
	vitality = {
		id = "vitality",
		name = "Vitality",
		description = "Increases maximum health and health regeneration.",
		category = "survival",
		maxLevel = 100,
		bonusPerLevel = 1, -- 1% more HP per level
		bonusType = "health_bonus",
	},
	stamina_mastery = {
		id = "stamina_mastery",
		name = "Stamina Mastery",
		description = "Faster stamina regeneration and slower drain when sprinting.",
		category = "survival",
		maxLevel = 100,
		bonusPerLevel = 0.5,
		bonusType = "stamina_efficiency",
	},
	foraging = {
		id = "foraging",
		name = "Foraging",
		description = "Find more food when gathering. Chance to find rare ingredients.",
		category = "survival",
		maxLevel = 100,
		bonusPerLevel = 1, -- 1% bonus yield per level
		bonusType = "gather_bonus",
	},

	-- COMBAT SKILLS
	melee = {
		id = "melee",
		name = "Melee Combat",
		description = "Increased damage with melee weapons.",
		category = "combat",
		maxLevel = 100,
		bonusPerLevel = 0.5,
		bonusType = "melee_damage",
	},
	defense = {
		id = "defense",
		name = "Defense",
		description = "Reduces damage taken from all sources.",
		category = "combat",
		maxLevel = 100,
		bonusPerLevel = 0.3, -- 0.3% damage reduction per level (30% max)
		bonusType = "damage_reduction",
	},
	evasion = {
		id = "evasion",
		name = "Evasion",
		description = "Faster movement when fleeing from creatures.",
		category = "combat",
		maxLevel = 100,
		bonusPerLevel = 0.2, -- 0.2% speed bonus per level
		bonusType = "flee_speed",
	},

	-- CRAFTING SKILLS
	alchemy = {
		id = "alchemy",
		name = "Alchemy",
		description = "Create potions and elixirs. Higher levels unlock better recipes.",
		category = "crafting",
		maxLevel = 100,
		bonusPerLevel = 1,
		bonusType = "potion_effectiveness",
	},
	smithing = {
		id = "smithing",
		name = "Smithing",
		description = "Craft and improve weapons and armor.",
		category = "crafting",
		maxLevel = 100,
		bonusPerLevel = 1,
		bonusType = "equipment_quality",
	},

	-- EXPLORATION SKILLS
	athletics = {
		id = "athletics",
		name = "Athletics",
		description = "Move faster and jump higher.",
		category = "exploration",
		maxLevel = 100,
		bonusPerLevel = 0.1, -- 0.1% speed per level (10% max)
		bonusType = "movement_speed",
	},
	night_eye = {
		id = "night_eye",
		name = "Night Eye",
		description = "See better in darkness. Reduced fear gain at night.",
		category = "exploration",
		maxLevel = 100,
		bonusPerLevel = 0.5,
		bonusType = "night_vision",
	},
	pathfinding = {
		id = "pathfinding",
		name = "Pathfinding",
		description = "Discover locations faster. Better sense of direction.",
		category = "exploration",
		maxLevel = 100,
		bonusPerLevel = 1,
		bonusType = "discovery_range",
	},
}

-- ==========================================
-- PLAYER SKILLS STATE
-- ==========================================

type PlayerSkills = {
	skills: { [string]: { level: number, experience: number } },
	totalLevel: number,
}

local playerSkills: { [Player]: PlayerSkills } = {}

local function initPlayerSkills(player: Player)
	local skills = {}
	for skillId, _ in SKILLS do
		skills[skillId] = { level = 1, experience = 0 }
	end

	playerSkills[player] = {
		skills = skills,
		totalLevel = #SKILLS, -- Sum of all skill levels (starts at number of skills since each is level 1)
	}

	sendSkillsUpdate(player)
end

local function cleanupPlayerSkills(player: Player)
	playerSkills[player] = nil
end

function sendSkillsUpdate(player: Player)
	local pSkills = playerSkills[player]
	if not pSkills then return end

	local skillsData = {}
	for skillId, skillState in pSkills.skills do
		local def = SKILLS[skillId]
		if def then
			local expNeeded = getExpForLevel(skillState.level + 1)
			skillsData[skillId] = {
				name = def.name,
				description = def.description,
				category = def.category,
				level = skillState.level,
				experience = skillState.experience,
				experienceNeeded = expNeeded,
				maxLevel = def.maxLevel,
				bonus = skillState.level * def.bonusPerLevel,
				bonusType = def.bonusType,
			}
		end
	end

	SkillsRemote:FireClient(player, "UPDATE", {
		skills = skillsData,
		totalLevel = pSkills.totalLevel,
	})
end

-- ==========================================
-- SKILL PROGRESSION
-- ==========================================

-- Experience needed for each level (exponential curve)
function getExpForLevel(level: number): number
	return math.floor(100 * (level ^ 1.5))
end

-- Grant experience to a skill
local function grantSkillExp(player: Player, skillId: string, amount: number)
	local pSkills = playerSkills[player]
	if not pSkills then return end

	local skillState = pSkills.skills[skillId]
	local def = SKILLS[skillId]
	if not skillState or not def then return end

	-- Already max level?
	if skillState.level >= def.maxLevel then return end

	-- Add experience
	skillState.experience += amount

	-- Check for level up
	local expNeeded = getExpForLevel(skillState.level + 1)
	local leveledUp = false

	while skillState.experience >= expNeeded and skillState.level < def.maxLevel do
		skillState.experience -= expNeeded
		skillState.level += 1
		pSkills.totalLevel += 1
		leveledUp = true
		expNeeded = getExpForLevel(skillState.level + 1)
	end

	if leveledUp then
		SkillsRemote:FireClient(player, "LEVEL_UP", {
			skillId = skillId,
			skillName = def.name,
			newLevel = skillState.level,
			bonus = skillState.level * def.bonusPerLevel,
		})
		print("[Skills]", player.Name, "leveled up", def.name, "to level", skillState.level)
	end

	sendSkillsUpdate(player)
end

-- Get skill bonus for a player
local function getSkillBonus(player: Player, bonusType: string): number
	local pSkills = playerSkills[player]
	if not pSkills then return 0 end

	local totalBonus = 0
	for skillId, skillState in pSkills.skills do
		local def = SKILLS[skillId]
		if def and def.bonusType == bonusType then
			totalBonus += skillState.level * def.bonusPerLevel
		end
	end

	return totalBonus
end

-- ==========================================
-- SKILL TRIGGERS (learn by doing)
-- ==========================================

-- Track activities to grant skill XP
local playerActivity: { [Player]: {
	distanceTraveled: number,
	lastPosition: Vector3?,
	timeInDarkness: number,
	damageTaken: number,
	damageDealt: number,
	itemsGathered: number,
	itemsCrafted: number,
} } = {}

local function initActivity(player: Player)
	playerActivity[player] = {
		distanceTraveled = 0,
		lastPosition = nil,
		timeInDarkness = 0,
		damageTaken = 0,
		damageDealt = 0,
		itemsGathered = 0,
		itemsCrafted = 0,
	}
end

-- Track movement for Athletics
local function trackMovement(player: Player, dt: number)
	local activity = playerActivity[player]
	if not activity then return end

	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	local currentPos = rootPart.Position

	if activity.lastPosition then
		local distance = (currentPos - activity.lastPosition).Magnitude
		if distance > 0.5 and distance < 50 then -- Ignore teleports
			activity.distanceTraveled += distance

			-- Grant Athletics XP every 100 studs
			if activity.distanceTraveled >= 100 then
				grantSkillExp(player, "athletics", 5)
				activity.distanceTraveled -= 100
			end
		end
	end

	activity.lastPosition = currentPos

	-- Check if sprinting for Stamina Mastery
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.WalkSpeed > Config.WALK_SPEED then
		grantSkillExp(player, "stamina_mastery", 0.1 * dt)
	end
end

-- Called when player takes damage
local function onDamageTaken(player: Player, amount: number)
	local activity = playerActivity[player]
	if not activity then return end

	activity.damageTaken += amount

	-- Grant Defense XP when taking damage
	grantSkillExp(player, "defense", amount * 0.5)

	-- Grant Vitality XP
	grantSkillExp(player, "vitality", amount * 0.3)
end

-- Called when player deals damage
local function onDamageDealt(player: Player, amount: number)
	grantSkillExp(player, "melee", amount * 0.5)
end

-- Called when player gathers resources
local function onGather(player: Player, resourceType: string)
	grantSkillExp(player, "foraging", 10)

	-- Endurance XP for surviving and foraging
	grantSkillExp(player, "endurance", 3)
end

-- Called when player crafts
local function onCraft(player: Player, category: string)
	if category == "potion" then
		grantSkillExp(player, "alchemy", 15)
	elseif category == "weapon" or category == "armor" then
		grantSkillExp(player, "smithing", 15)
	end
end

-- Track time spent in darkness
local function trackDarkness(player: Player, isInDarkness: boolean, dt: number)
	if isInDarkness then
		grantSkillExp(player, "night_eye", dt * 2)
	end
end

-- Called when discovering a location
local function onDiscovery(player: Player)
	grantSkillExp(player, "pathfinding", 25)
end

-- Called when fleeing from creatures
local function onFlee(player: Player)
	grantSkillExp(player, "evasion", 5)
end

-- ==========================================
-- HUNGER MODIFICATION
-- ==========================================

-- Apply skill bonuses to hunger drain
local function getModifiedHungerDrain(player: Player, baseDrain: number): number
	local hungerReduction = getSkillBonus(player, "hunger_reduction")
	local modifier = 1 - (hungerReduction / 100) -- Convert % to multiplier
	return baseDrain * math.max(0.5, modifier) -- Minimum 50% drain rate at max skill
end

-- ==========================================
-- REMOTE HANDLERS
-- ==========================================

SkillsRemote.OnServerEvent:Connect(function(player: Player, action: string, data: any)
	if action == "GET_SKILLS" then
		sendSkillsUpdate(player)
	elseif action == "ACTIVITY" then
		-- Handle activity reports from client
		if data.type == "GATHER" then
			onGather(player, data.resourceType)
		elseif data.type == "CRAFT" then
			onCraft(player, data.category)
		elseif data.type == "FLEE" then
			onFlee(player)
		elseif data.type == "DISCOVER" then
			onDiscovery(player)
		end
	end
end)

-- Expose functions for other systems
_G.SkillSystem = {
	getSkillBonus = getSkillBonus,
	getModifiedHungerDrain = getModifiedHungerDrain,
	grantSkillExp = grantSkillExp,
	onDamageTaken = onDamageTaken,
	onDamageDealt = onDamageDealt,
	onGather = onGather,
	onCraft = onCraft,
}

-- ==========================================
-- UPDATE LOOP
-- ==========================================

RunService.Heartbeat:Connect(function(dt)
	for player, _ in playerSkills do
		trackMovement(player, dt)
	end
end)

-- ==========================================
-- PLAYER SETUP
-- ==========================================

Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	initPlayerSkills(player)
	initActivity(player)
end)

Players.PlayerRemoving:Connect(function(player)
	cleanupPlayerSkills(player)
	playerActivity[player] = nil
end)

-- Initialize existing players
for _, player in Players:GetPlayers() do
	task.spawn(function()
		task.wait(2)
		initPlayerSkills(player)
		initActivity(player)
	end)
end

print("[Skills] Skill system initialized!")
print("[Skills] Skills improve through use (learn by doing)")
print("[Skills] Endurance skill reduces hunger drain for exploration")
