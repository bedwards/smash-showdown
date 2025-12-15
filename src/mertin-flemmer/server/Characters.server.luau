--!strict
-- Diverse Characters for Mertin-Flemmer
-- Humans (all ages), Animals, and Mythical Creatures

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

-- Create remotes
local CharacterInteractRemote = Instance.new("RemoteEvent")
CharacterInteractRemote.Name = "CharacterInteract"
CharacterInteractRemote.Parent = ReplicatedStorage

-- ==========================================
-- CHARACTER TEMPLATES
-- ==========================================

type CharacterTemplate = {
	category: string, -- "human", "animal", "mythical"
	subtype: string,
	name: string,
	height: number, -- Scale multiplier
	bodyType: string, -- "thin", "normal", "stocky", "child", "quadruped"
	colors: {
		skin: Color3,
		clothing: Color3,
		accent: Color3,
		hair: Color3?,
	},
	friendly: boolean,
	speed: number,
	dialogue: { string }?,
	sounds: { string }?, -- Sound descriptions
	special: string?, -- Special behaviors
}

-- HUMAN TEMPLATES
local HUMANS: { CharacterTemplate } = {
	-- ELDERLY
	{
		category = "human",
		subtype = "elder_man",
		name = "Old Fisherman",
		height = 0.9,
		bodyType = "thin",
		colors = {
			skin = Color3.fromRGB(220, 190, 160),
			clothing = Color3.fromRGB(80, 90, 100),
			accent = Color3.fromRGB(60, 70, 80),
			hair = Color3.fromRGB(200, 200, 200), -- Gray hair
		},
		friendly = true,
		speed = 8,
		dialogue = { "In my day, the nights weren't so dark...", "Seen many things in these waters.", "The fish don't bite like they used to." },
	},
	{
		category = "human",
		subtype = "elder_woman",
		name = "Wise Grandmother",
		height = 0.85,
		bodyType = "stocky",
		colors = {
			skin = Color3.fromRGB(200, 170, 140),
			clothing = Color3.fromRGB(120, 80, 100),
			accent = Color3.fromRGB(180, 140, 160),
			hair = Color3.fromRGB(220, 220, 220),
		},
		friendly = true,
		speed = 6,
		dialogue = { "Come closer, child. Let me tell you a story.", "I remember when this was all farmland.", "Take this - you'll need it." },
		special = "gives_food",
	},
	{
		category = "human",
		subtype = "elder_sage",
		name = "Ancient Sage",
		height = 0.95,
		bodyType = "thin",
		colors = {
			skin = Color3.fromRGB(180, 150, 130),
			clothing = Color3.fromRGB(60, 50, 80),
			accent = Color3.fromRGB(200, 180, 100),
			hair = Color3.fromRGB(240, 240, 250),
		},
		friendly = true,
		speed = 5,
		dialogue = { "The prophecy speaks of one such as you...", "Ancient knowledge courses through these lands.", "Seek the three stones, young one." },
		special = "gives_quest",
	},
	-- ADULTS
	{
		category = "human",
		subtype = "farmer",
		name = "Farmer",
		height = 1.1,
		bodyType = "stocky",
		colors = {
			skin = Color3.fromRGB(210, 170, 130),
			clothing = Color3.fromRGB(100, 80, 60),
			accent = Color3.fromRGB(150, 120, 80),
			hair = Color3.fromRGB(80, 60, 40),
		},
		friendly = true,
		speed = 12,
		dialogue = { "The crops won't tend themselves!", "Strange creatures been eating my livestock.", "Could use some help around here." },
	},
	{
		category = "human",
		subtype = "blacksmith",
		name = "Blacksmith",
		height = 1.2,
		bodyType = "stocky",
		colors = {
			skin = Color3.fromRGB(180, 140, 100),
			clothing = Color3.fromRGB(40, 40, 50),
			accent = Color3.fromRGB(150, 100, 50),
			hair = Color3.fromRGB(30, 25, 20),
		},
		friendly = true,
		speed = 10,
		dialogue = { "Need something forged?", "Steel and fire, that's what I know.", "This blade's seen better days." },
		special = "repairs_equipment",
	},
	{
		category = "human",
		subtype = "hunter",
		name = "Hunter",
		height = 1.05,
		bodyType = "thin",
		colors = {
			skin = Color3.fromRGB(190, 160, 130),
			clothing = Color3.fromRGB(60, 80, 50),
			accent = Color3.fromRGB(80, 60, 40),
			hair = Color3.fromRGB(100, 70, 40),
		},
		friendly = true,
		speed = 16,
		dialogue = { "Tracks lead north. Big creature.", "Stay downwind or they'll smell you.", "The forest provides, if you know where to look." },
	},
	{
		category = "human",
		subtype = "mother",
		name = "Worried Mother",
		height = 1.0,
		bodyType = "normal",
		colors = {
			skin = Color3.fromRGB(230, 200, 180),
			clothing = Color3.fromRGB(140, 100, 100),
			accent = Color3.fromRGB(180, 140, 140),
			hair = Color3.fromRGB(120, 80, 50),
		},
		friendly = true,
		speed = 11,
		dialogue = { "Have you seen my children? They wandered off!", "It's not safe out here!", "Please, help me find them!" },
		special = "gives_quest",
	},
	-- CHILDREN
	{
		category = "human",
		subtype = "child_boy",
		name = "Curious Boy",
		height = 0.6,
		bodyType = "child",
		colors = {
			skin = Color3.fromRGB(240, 210, 180),
			clothing = Color3.fromRGB(100, 120, 150),
			accent = Color3.fromRGB(80, 100, 130),
			hair = Color3.fromRGB(100, 80, 50),
		},
		friendly = true,
		speed = 14,
		dialogue = { "Wow! Are you an adventurer?!", "I'm not scared of monsters!", "Can I come with you? Pleeeease?" },
	},
	{
		category = "human",
		subtype = "child_girl",
		name = "Playful Girl",
		height = 0.55,
		bodyType = "child",
		colors = {
			skin = Color3.fromRGB(235, 205, 175),
			clothing = Color3.fromRGB(180, 100, 120),
			accent = Color3.fromRGB(200, 150, 170),
			hair = Color3.fromRGB(60, 40, 20),
		},
		friendly = true,
		speed = 15,
		dialogue = { "Wanna play hide and seek?", "My doll is lost somewhere...", "The fairies come out at night!" },
		special = "gives_quest",
	},
	{
		category = "human",
		subtype = "teenager",
		name = "Rebellious Teen",
		height = 0.85,
		bodyType = "thin",
		colors = {
			skin = Color3.fromRGB(230, 200, 170),
			clothing = Color3.fromRGB(30, 30, 40),
			accent = Color3.fromRGB(150, 50, 50),
			hair = Color3.fromRGB(20, 20, 25),
		},
		friendly = true,
		speed = 18,
		dialogue = { "Whatever.", "My parents don't understand.", "There's a secret spot I could show you... if you're cool." },
	},
}

-- ANIMAL TEMPLATES
local ANIMALS: { CharacterTemplate } = {
	-- DOGS
	{
		category = "animal",
		subtype = "dog_loyal",
		name = "Loyal Dog",
		height = 0.4,
		bodyType = "quadruped",
		colors = {
			skin = Color3.fromRGB(150, 100, 60),
			clothing = Color3.fromRGB(150, 100, 60),
			accent = Color3.fromRGB(200, 150, 100),
		},
		friendly = true,
		speed = 20,
		sounds = { "Woof!", "Bark bark!", "*happy panting*" },
		special = "follows_player",
	},
	{
		category = "animal",
		subtype = "dog_stray",
		name = "Stray Dog",
		height = 0.35,
		bodyType = "quadruped",
		colors = {
			skin = Color3.fromRGB(80, 70, 60),
			clothing = Color3.fromRGB(80, 70, 60),
			accent = Color3.fromRGB(60, 50, 40),
		},
		friendly = true,
		speed = 18,
		sounds = { "*whimper*", "Arf?", "*cautious sniff*" },
		special = "can_tame",
	},
	-- CATS
	{
		category = "animal",
		subtype = "cat_tabby",
		name = "Tabby Cat",
		height = 0.25,
		bodyType = "quadruped",
		colors = {
			skin = Color3.fromRGB(200, 150, 100),
			clothing = Color3.fromRGB(200, 150, 100),
			accent = Color3.fromRGB(100, 70, 40),
		},
		friendly = true,
		speed = 16,
		sounds = { "Meow~", "*purr*", "Mrow?" },
		special = "random_affection",
	},
	{
		category = "animal",
		subtype = "cat_black",
		name = "Black Cat",
		height = 0.25,
		bodyType = "quadruped",
		colors = {
			skin = Color3.fromRGB(20, 20, 25),
			clothing = Color3.fromRGB(20, 20, 25),
			accent = Color3.fromRGB(255, 200, 50), -- Yellow eyes
		},
		friendly = true,
		speed = 18,
		sounds = { "Mrrrow...", "*silent stare*", "Hiss!" },
		special = "night_guide",
	},
	-- WILDLIFE
	{
		category = "animal",
		subtype = "deer",
		name = "Gentle Deer",
		height = 0.8,
		bodyType = "quadruped",
		colors = {
			skin = Color3.fromRGB(180, 140, 100),
			clothing = Color3.fromRGB(180, 140, 100),
			accent = Color3.fromRGB(250, 250, 250), -- White spots
		},
		friendly = true,
		speed = 22,
		sounds = { "*soft bleat*", "*ears twitch*", "*stamps hoof*" },
		special = "flees_player",
	},
	{
		category = "animal",
		subtype = "rabbit",
		name = "Wild Rabbit",
		height = 0.15,
		bodyType = "quadruped",
		colors = {
			skin = Color3.fromRGB(160, 140, 120),
			clothing = Color3.fromRGB(160, 140, 120),
			accent = Color3.fromRGB(250, 240, 230),
		},
		friendly = true,
		speed = 25,
		sounds = { "*nose twitch*", "*hop hop*" },
		special = "very_skittish",
	},
	{
		category = "animal",
		subtype = "horse",
		name = "Wild Horse",
		height = 1.3,
		bodyType = "quadruped",
		colors = {
			skin = Color3.fromRGB(100, 70, 50),
			clothing = Color3.fromRGB(100, 70, 50),
			accent = Color3.fromRGB(30, 20, 15), -- Mane
		},
		friendly = true,
		speed = 30,
		sounds = { "*neigh*", "*snort*", "*stamps ground*" },
		special = "can_ride",
	},
	{
		category = "animal",
		subtype = "crow",
		name = "Mysterious Crow",
		height = 0.2,
		bodyType = "quadruped",
		colors = {
			skin = Color3.fromRGB(20, 20, 30),
			clothing = Color3.fromRGB(20, 20, 30),
			accent = Color3.fromRGB(50, 50, 70),
		},
		friendly = true,
		speed = 12,
		sounds = { "Caw! Caw!", "*intelligent stare*", "Caw..." },
		special = "flying",
	},
}

-- MYTHICAL TEMPLATES
local MYTHICAL: { CharacterTemplate } = {
	{
		category = "mythical",
		subtype = "fairy",
		name = "Forest Fairy",
		height = 0.15,
		bodyType = "thin",
		colors = {
			skin = Color3.fromRGB(255, 220, 200),
			clothing = Color3.fromRGB(100, 200, 100),
			accent = Color3.fromRGB(255, 255, 200), -- Glow
		},
		friendly = true,
		speed = 20,
		dialogue = { "*tinkle tinkle*", "Follow the light~", "Secrets hide in moonbeams!" },
		special = "glowing",
	},
	{
		category = "mythical",
		subtype = "wisp",
		name = "Will-o'-Wisp",
		height = 0.3,
		bodyType = "thin",
		colors = {
			skin = Color3.fromRGB(100, 200, 255),
			clothing = Color3.fromRGB(100, 200, 255),
			accent = Color3.fromRGB(150, 220, 255),
		},
		friendly = true,
		speed = 15,
		sounds = { "*ethereal hum*", "*flickers*" },
		special = "glowing_guide",
	},
	{
		category = "mythical",
		subtype = "goblin",
		name = "Mischievous Goblin",
		height = 0.5,
		bodyType = "stocky",
		colors = {
			skin = Color3.fromRGB(100, 150, 100),
			clothing = Color3.fromRGB(80, 60, 40),
			accent = Color3.fromRGB(200, 150, 50),
		},
		friendly = false,
		speed = 18,
		dialogue = { "Hehehe! Shiny things!", "Give me your stuff!", "Goblin tricks! Goblin treats!" },
		special = "steals",
	},
	{
		category = "mythical",
		subtype = "spirit_ancestor",
		name = "Ancestor Spirit",
		height = 1.1,
		bodyType = "thin",
		colors = {
			skin = Color3.fromRGB(200, 220, 255),
			clothing = Color3.fromRGB(180, 200, 240),
			accent = Color3.fromRGB(255, 255, 255),
		},
		friendly = true,
		speed = 8,
		dialogue = { "Remember the old ways...", "Your ancestors watch over you.", "Seek the sacred grove." },
		special = "transparent",
	},
	{
		category = "mythical",
		subtype = "forest_spirit",
		name = "Forest Guardian",
		height = 2.0,
		bodyType = "stocky",
		colors = {
			skin = Color3.fromRGB(80, 120, 60),
			clothing = Color3.fromRGB(60, 100, 40),
			accent = Color3.fromRGB(200, 180, 100),
		},
		friendly = true,
		speed = 6,
		dialogue = { "The trees speak...", "Protect nature, and she protects you.", "The forest remembers." },
		special = "huge",
	},
	{
		category = "mythical",
		subtype = "pixie",
		name = "Playful Pixie",
		height = 0.1,
		bodyType = "thin",
		colors = {
			skin = Color3.fromRGB(255, 200, 220),
			clothing = Color3.fromRGB(200, 100, 200),
			accent = Color3.fromRGB(255, 150, 255),
		},
		friendly = true,
		speed = 25,
		dialogue = { "Teehee!", "Catch me if you can!", "Sparkle sparkle~" },
		special = "glowing_fast",
	},
	{
		category = "mythical",
		subtype = "unicorn",
		name = "Moonlit Unicorn",
		height = 1.4,
		bodyType = "quadruped",
		colors = {
			skin = Color3.fromRGB(250, 250, 255),
			clothing = Color3.fromRGB(250, 250, 255),
			accent = Color3.fromRGB(255, 215, 180), -- Golden horn
		},
		friendly = true,
		speed = 28,
		sounds = { "*magical neigh*", "*sparkles*" },
		special = "rare_healer",
	},
	{
		category = "mythical",
		subtype = "troll",
		name = "Bridge Troll",
		height = 1.8,
		bodyType = "stocky",
		colors = {
			skin = Color3.fromRGB(100, 90, 80),
			clothing = Color3.fromRGB(60, 50, 40),
			accent = Color3.fromRGB(50, 100, 50),
		},
		friendly = false,
		speed = 10,
		dialogue = { "PAY THE TOLL!", "No pass without tribute!", "TROLL HUNGRY!" },
		special = "blocks_path",
	},
}

-- ==========================================
-- CHARACTER CREATION
-- ==========================================

local allCharacters: { Model } = {}
local characterStates: { [Model]: {
	template: CharacterTemplate,
	behavior: string,
	target: Vector3?,
	followPlayer: Player?,
	lastInteract: number,
	homePosition: Vector3,
} } = {}

-- Create humanoid character
local function createHumanCharacter(template: CharacterTemplate, position: Vector3): Model
	local char = Instance.new("Model")
	char.Name = template.name

	local scale = template.height
	local isChild = template.bodyType == "child"
	local isStocky = template.bodyType == "stocky"
	local isThin = template.bodyType == "thin"

	-- Body proportions based on type
	local torsoWidth = isStocky and 2.4 or (isThin and 1.6 or 2)
	local torsoHeight = isChild and 1.5 or (isStocky and 2.2 or 2.5)
	local headSize = isChild and 1.5 or 1.3 -- Kids have bigger heads proportionally

	-- TORSO
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(torsoWidth, torsoHeight, 1) * scale
	torso.Color = template.colors.clothing
	torso.Material = Enum.Material.Fabric
	torso.Anchored = false
	torso.Parent = char

	-- HEAD
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(headSize, headSize, headSize) * scale
	head.Color = template.colors.skin
	head.Material = Enum.Material.SmoothPlastic
	head.Parent = char

	-- Face decal
	local face = Instance.new("Decal")
	face.Face = Enum.NormalId.Front
	face.Texture = isChild and "rbxassetid://7075771214" or "rbxassetid://7075769910"
	face.Parent = head

	-- HAIR (if specified)
	if template.colors.hair then
		local hair = Instance.new("Part")
		hair.Name = "Hair"
		local hairHeight = isChild and 0.4 or 0.5
		hair.Size = Vector3.new(headSize * 1.1, hairHeight, headSize * 1.1) * scale
		hair.Color = template.colors.hair
		hair.Material = Enum.Material.SmoothPlastic
		hair.Parent = char
	end

	-- LIMBS
	local limbWidth = isChild and 0.6 or (isStocky and 1.1 or 0.9)
	local armLength = isChild and 1.2 or 2
	local legLength = isChild and 1.0 or 2

	local leftArm = Instance.new("Part")
	leftArm.Name = "Left Arm"
	leftArm.Size = Vector3.new(limbWidth, armLength, limbWidth) * scale
	leftArm.Color = template.colors.clothing
	leftArm.Material = Enum.Material.Fabric
	leftArm.Parent = char

	local rightArm = Instance.new("Part")
	rightArm.Name = "Right Arm"
	rightArm.Size = Vector3.new(limbWidth, armLength, limbWidth) * scale
	rightArm.Color = template.colors.clothing
	rightArm.Material = Enum.Material.Fabric
	rightArm.Parent = char

	local leftLeg = Instance.new("Part")
	leftLeg.Name = "Left Leg"
	leftLeg.Size = Vector3.new(limbWidth, legLength, limbWidth) * scale
	leftLeg.Color = template.colors.accent
	leftLeg.Material = Enum.Material.Fabric
	leftLeg.Parent = char

	local rightLeg = Instance.new("Part")
	rightLeg.Name = "Right Leg"
	rightLeg.Size = Vector3.new(limbWidth, legLength, limbWidth) * scale
	rightLeg.Color = template.colors.accent
	rightLeg.Material = Enum.Material.Fabric
	rightLeg.Parent = char

	-- ROOT PART
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1) * scale
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.Parent = char

	-- HUMANOID
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.WalkSpeed = template.speed
	humanoid.Parent = char

	-- Position parts
	local baseY = position.Y + (torsoHeight * scale / 2) + (legLength * scale)
	rootPart.Position = Vector3.new(position.X, baseY, position.Z)
	torso.Position = rootPart.Position
	head.Position = torso.Position + Vector3.new(0, (torsoHeight * scale / 2) + (headSize * scale / 2), 0)
	leftArm.Position = torso.Position + Vector3.new(-(torsoWidth * scale / 2) - (limbWidth * scale / 2), 0, 0)
	rightArm.Position = torso.Position + Vector3.new((torsoWidth * scale / 2) + (limbWidth * scale / 2), 0, 0)
	leftLeg.Position = torso.Position + Vector3.new(-(limbWidth * scale / 2), -(torsoHeight * scale / 2) - (legLength * scale / 2), 0)
	rightLeg.Position = torso.Position + Vector3.new((limbWidth * scale / 2), -(torsoHeight * scale / 2) - (legLength * scale / 2), 0)

	-- Weld parts
	local function weld(part0: BasePart, part1: BasePart, offset: Vector3)
		local motor = Instance.new("Motor6D")
		motor.Part0 = part0
		motor.Part1 = part1
		motor.C0 = CFrame.new(offset)
		motor.Parent = part0
	end

	char.PrimaryPart = rootPart
	weld(rootPart, torso, CFrame.new())
	weld(torso, head, CFrame.new(0, (torsoHeight * scale / 2) + (headSize * scale / 2), 0))
	weld(torso, leftArm, CFrame.new(-(torsoWidth * scale / 2) - (limbWidth * scale / 2), 0, 0))
	weld(torso, rightArm, CFrame.new((torsoWidth * scale / 2) + (limbWidth * scale / 2), 0, 0))
	weld(torso, leftLeg, CFrame.new(-(limbWidth * scale / 2), -(torsoHeight * scale / 2) - (legLength * scale / 2), 0))
	weld(torso, rightLeg, CFrame.new((limbWidth * scale / 2), -(torsoHeight * scale / 2) - (legLength * scale / 2), 0))

	-- NAME TAG
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 150, 0, 40)
	billboard.StudsOffset = Vector3.new(0, (headSize * scale) + 1, 0)
	billboard.Adornee = head
	billboard.Parent = char

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = template.name
	nameLabel.TextColor3 = template.friendly and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.Parent = billboard

	local subtypeLabel = Instance.new("TextLabel")
	subtypeLabel.Size = UDim2.new(1, 0, 0.4, 0)
	subtypeLabel.Position = UDim2.new(0, 0, 0.6, 0)
	subtypeLabel.BackgroundTransparency = 1
	subtypeLabel.Text = "<" .. template.category .. ">"
	subtypeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	subtypeLabel.Font = Enum.Font.Gotham
	subtypeLabel.TextSize = 10
	subtypeLabel.Parent = billboard

	-- Special effects
	if template.special == "glowing" or template.special == "glowing_guide" or template.special == "glowing_fast" then
		local glow = Instance.new("PointLight")
		glow.Color = template.colors.accent
		glow.Brightness = 2
		glow.Range = 15
		glow.Parent = torso
	end

	if template.special == "transparent" then
		for _, part in char:GetChildren() do
			if part:IsA("BasePart") then
				part.Transparency = 0.5
			end
		end
	end

	char.Parent = workspace
	return char
end

-- Create quadruped (animal) character
local function createAnimalCharacter(template: CharacterTemplate, position: Vector3): Model
	local char = Instance.new("Model")
	char.Name = template.name

	local scale = template.height
	local isLarge = scale > 0.8

	-- BODY
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(1.5, 1, 2.5) * scale
	body.Color = template.colors.skin
	body.Material = Enum.Material.SmoothPlastic
	body.Parent = char

	-- HEAD
	local head = Instance.new("Part")
	head.Name = "Head"
	local headSize = isLarge and 0.8 or 0.6
	head.Size = Vector3.new(headSize, headSize, headSize) * scale
	head.Color = template.colors.skin
	head.Material = Enum.Material.SmoothPlastic
	head.Parent = char

	-- LEGS (4)
	local legSize = isLarge and 0.3 or 0.2
	local legHeight = isLarge and 1 or 0.6

	for i, offset in { Vector3.new(-0.5, 0, -0.8), Vector3.new(0.5, 0, -0.8), Vector3.new(-0.5, 0, 0.8), Vector3.new(0.5, 0, 0.8) } do
		local leg = Instance.new("Part")
		leg.Name = "Leg" .. i
		leg.Size = Vector3.new(legSize, legHeight, legSize) * scale
		leg.Color = template.colors.skin
		leg.Material = Enum.Material.SmoothPlastic
		leg.Parent = char
	end

	-- TAIL
	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.15, 0.15, 0.8) * scale
	tail.Color = template.colors.accent or template.colors.skin
	tail.Material = Enum.Material.SmoothPlastic
	tail.Parent = char

	-- ROOT PART
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(1.5, 1, 2.5) * scale
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.Parent = char

	-- HUMANOID
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 50
	humanoid.Health = 50
	humanoid.WalkSpeed = template.speed
	humanoid.HipHeight = legHeight * scale * 0.8
	humanoid.Parent = char

	-- Position
	local baseY = position.Y + (legHeight * scale) + (scale * 0.5)
	rootPart.Position = Vector3.new(position.X, baseY, position.Z)
	body.Position = rootPart.Position
	head.Position = body.Position + Vector3.new(0, scale * 0.3, -scale * 1.2)
	tail.Position = body.Position + Vector3.new(0, scale * 0.3, scale * 1.4)

	char.PrimaryPart = rootPart

	-- NAME TAG
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 1.5 * scale, 0)
	billboard.Adornee = body
	billboard.Parent = char

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = template.name
	nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextSize = 10
	nameLabel.Parent = billboard

	-- Special effects
	if template.special == "rare_healer" then
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(255, 255, 200)
		glow.Brightness = 1.5
		glow.Range = 20
		glow.Parent = body

		-- Sparkles
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 200))
		sparkles.Size = NumberSequence.new(0.2, 0)
		sparkles.Lifetime = NumberRange.new(1, 2)
		sparkles.Rate = 10
		sparkles.Speed = NumberRange.new(1, 3)
		sparkles.Parent = body
	end

	char.Parent = workspace
	return char
end

-- Create character based on template
local function createCharacter(template: CharacterTemplate, position: Vector3): Model
	if template.bodyType == "quadruped" then
		return createAnimalCharacter(template, position)
	else
		return createHumanCharacter(template, position)
	end
end

-- ==========================================
-- CHARACTER SPAWNING
-- ==========================================

local function spawnCharacters()
	task.wait(6) -- Wait for world

	print("[Characters] Spawning diverse characters...")

	-- Get all templates
	local allTemplates = {}
	for _, t in HUMANS do table.insert(allTemplates, t) end
	for _, t in ANIMALS do table.insert(allTemplates, t) end
	for _, t in MYTHICAL do table.insert(allTemplates, t) end

	-- Spawn locations with character type preferences
	local spawnPoints = {
		-- Near spawn (friendly humans and pets)
		{ pos = Vector3.new(30, 0, -20), types = { "elder_woman", "child_boy", "dog_loyal" } },
		{ pos = Vector3.new(-25, 0, -40), types = { "farmer", "cat_tabby" } },
		{ pos = Vector3.new(50, 0, 10), types = { "elder_man", "child_girl" } },

		-- Forest (animals and forest creatures)
		{ pos = Vector3.new(150, 0, 100), types = { "deer", "rabbit", "fairy" } },
		{ pos = Vector3.new(-100, 0, 150), types = { "hunter", "dog_stray", "crow" } },
		{ pos = Vector3.new(200, 0, -50), types = { "forest_spirit", "pixie" } },

		-- Paths and roads
		{ pos = Vector3.new(300, 0, 0), types = { "wanderer", "horse" } },
		{ pos = Vector3.new(-200, 0, 100), types = { "merchant", "dog_loyal" } },
		{ pos = Vector3.new(0, 0, 300), types = { "teenager", "cat_black" } },

		-- Wilderness
		{ pos = Vector3.new(500, 0, 200), types = { "wisp", "goblin" } },
		{ pos = Vector3.new(-400, 0, -200), types = { "troll", "crow" } },
		{ pos = Vector3.new(300, 0, -400), types = { "spirit_ancestor", "unicorn" } },

		-- Villages/settlements
		{ pos = Vector3.new(-80, 0, -150), types = { "blacksmith", "mother", "child_boy" } },
		{ pos = Vector3.new(120, 0, -200), types = { "healer", "elder_sage", "cat_tabby" } },
	}

	for _, spawnPoint in spawnPoints do
		for _, subtype in spawnPoint.types do
			-- Find matching template
			local template: CharacterTemplate? = nil
			for _, t in allTemplates do
				if t.subtype == subtype then
					template = t
					break
				end
			end

			if template then
				local offset = Vector3.new((math.random() - 0.5) * 20, 0, (math.random() - 0.5) * 20)
				local char = createCharacter(template, spawnPoint.pos + offset)

				table.insert(allCharacters, char)
				characterStates[char] = {
					template = template,
					behavior = "wander",
					target = nil,
					followPlayer = nil,
					lastInteract = 0,
					homePosition = spawnPoint.pos,
				}

				print("[Characters] Spawned", template.name, "at", spawnPoint.pos)
			end
		end
	end

	print("[Characters] Spawned", #allCharacters, "diverse characters!")
end

-- ==========================================
-- CHARACTER BEHAVIOR
-- ==========================================

local function updateCharacter(char: Model, dt: number)
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local rootPart = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end

	local state = characterStates[char]
	if not state then return end

	local template = state.template
	local pos = rootPart.Position

	-- Find closest player
	local closestPlayer: Player? = nil
	local closestDist = math.huge
	for _, player in Players:GetPlayers() do
		local pChar = player.Character
		if pChar then
			local pRoot = pChar:FindFirstChild("HumanoidRootPart") :: BasePart?
			if pRoot then
				local dist = (pRoot.Position - pos).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestPlayer = player
				end
			end
		end
	end

	-- Behavior based on special trait
	if template.special == "follows_player" and closestPlayer and closestDist < 50 then
		-- Dogs follow nearby players
		local pRoot = closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if pRoot and closestDist > 5 then
			humanoid:MoveTo(pRoot.Position)
		end
	elseif template.special == "flees_player" or template.special == "very_skittish" then
		-- Deer/rabbits flee
		local fleeRange = template.special == "very_skittish" and 30 or 20
		if closestPlayer and closestDist < fleeRange then
			local pRoot = closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if pRoot then
				local awayDir = (pos - pRoot.Position).Unit
				humanoid:MoveTo(pos + awayDir * 30)
			end
		else
			-- Wander peacefully
			if not state.target or (pos - state.target).Magnitude < 5 then
				state.target = state.homePosition + Vector3.new(
					(math.random() - 0.5) * 50,
					0,
					(math.random() - 0.5) * 50
				)
			end
			humanoid:MoveTo(state.target)
		end
	elseif template.special == "blocks_path" then
		-- Trolls stay in place
		humanoid:MoveTo(state.homePosition)
	else
		-- Default wander behavior
		if not state.target or (pos - state.target).Magnitude < 5 or math.random() < 0.01 then
			state.target = state.homePosition + Vector3.new(
				(math.random() - 0.5) * 80,
				0,
				(math.random() - 0.5) * 80
			)
		end
		humanoid:MoveTo(state.target)
	end
end

-- ==========================================
-- GAME LOOP
-- ==========================================

RunService.Heartbeat:Connect(function(dt)
	for _, char in allCharacters do
		if char and char.Parent then
			updateCharacter(char, dt)
		end
	end
end)

-- Initialize
task.spawn(spawnCharacters)

print("[Characters] Diverse character system initialized!")
print("[Characters] - Humans: Adults, Elderly, Children")
print("[Characters] - Animals: Dogs, Cats, Deer, Horses, Rabbits")
print("[Characters] - Mythical: Fairies, Wisps, Spirits, Goblins, Unicorns")
