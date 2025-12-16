--!strict
--[[
	Faultline Fear: Sign Service

	Creates and manages signs throughout the world for player guidance.
	All signs are DOUBLE-SIDED (text visible from both sides).

	Sign Types:
	- Directional: Point to key locations with distance
	- Warning: Hazard alerts, safety instructions
	- Story: Lore text, survivor messages
	- Objective: Quest reminders, goal markers

	Exports: Initialize(), CreateSign(), GetSigns()
	Depends: Config, Heightmap
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local _Config = Shared.Config
local Heightmap = Shared.Heightmap

local SignService = {}

-- State
local signs: { Model } = {}
local signsFolder: Folder = nil :: any

-- Sign type configurations
type SignConfig = {
	backgroundColor: Color3,
	textColor: Color3,
	borderColor: Color3,
	font: Enum.Font,
	postColor: Color3,
	signSize: Vector3,
	postHeight: number,
}

local SIGN_CONFIGS: { [string]: SignConfig } = {
	directional = {
		backgroundColor = Color3.fromRGB(0, 100, 50),
		textColor = Color3.fromRGB(255, 255, 255),
		borderColor = Color3.fromRGB(255, 255, 255),
		font = Enum.Font.Highway,
		postColor = Color3.fromRGB(80, 80, 80),
		signSize = Vector3.new(8, 3, 0.3),
		postHeight = 6,
	},
	warning = {
		backgroundColor = Color3.fromRGB(255, 200, 0),
		textColor = Color3.fromRGB(0, 0, 0),
		borderColor = Color3.fromRGB(0, 0, 0),
		font = Enum.Font.GothamBold,
		postColor = Color3.fromRGB(60, 60, 60),
		signSize = Vector3.new(6, 6, 0.3),
		postHeight = 5,
	},
	story = {
		backgroundColor = Color3.fromRGB(60, 40, 30),
		textColor = Color3.fromRGB(240, 230, 200),
		borderColor = Color3.fromRGB(120, 80, 40),
		font = Enum.Font.Antique,
		postColor = Color3.fromRGB(100, 70, 40),
		signSize = Vector3.new(7, 5, 0.4),
		postHeight = 4,
	},
	objective = {
		backgroundColor = Color3.fromRGB(0, 80, 150),
		textColor = Color3.fromRGB(255, 255, 255),
		borderColor = Color3.fromRGB(255, 200, 0),
		font = Enum.Font.GothamBold,
		postColor = Color3.fromRGB(50, 50, 60),
		signSize = Vector3.new(6, 4, 0.3),
		postHeight = 7,
	},
}

-- Sign definitions
type SignDef = {
	position: Vector3,
	rotation: number,
	signType: string,
	text: string,
	subText: string?, -- Secondary line (e.g., distance)
}

local SIGN_DEFINITIONS: { SignDef } = {
	-- Directional signs
	{
		position = Vector3.new(0, 0, 200),
		rotation = 0,
		signType = "directional",
		text = "BEACH",
		subText = "← 200 studs",
	},
	{
		position = Vector3.new(0, 0, 200),
		rotation = 180,
		signType = "directional",
		text = "TOWN",
		subText = "→ 400 studs",
	},
	{
		position = Vector3.new(100, 0, 600),
		rotation = 45,
		signType = "directional",
		text = "RADIO TOWER",
		subText = "↗ Mountain Summit",
	},
	{
		position = Vector3.new(-50, 0, 800),
		rotation = -45,
		signType = "directional",
		text = "SAFE CAVE",
		subText = "← Follow Path",
	},
	{
		position = Vector3.new(50, 0, 400),
		rotation = 0,
		signType = "directional",
		text = "VALLEY",
		subText = "↑ 300 studs",
	},

	-- Warning signs
	{
		position = Vector3.new(-100, 0, 450),
		rotation = 90,
		signType = "warning",
		text = "⚠️ FAULT LINE",
		subText = "UNSTABLE GROUND",
	},
	{
		position = Vector3.new(100, 0, 450),
		rotation = -90,
		signType = "warning",
		text = "⚠️ DANGER",
		subText = "AFTERSHOCKS POSSIBLE",
	},
	{
		position = Vector3.new(0, 0, 1200),
		rotation = 0,
		signType = "warning",
		text = "⚠️ PREDATORS",
		subText = "DO NOT TRAVEL AT NIGHT",
	},
	{
		position = Vector3.new(-150, 0, 700),
		rotation = 45,
		signType = "warning",
		text = "⚠️ EMERGENCY",
		subText = "EVACUATE TO HIGH GROUND",
	},

	-- Story signs
	{
		position = Vector3.new(150, 0, 100),
		rotation = 0,
		signType = "story",
		text = "Coastal Memorial",
		subText = "In memory of those lost",
	},
	{
		position = Vector3.new(-80, 0, 650),
		rotation = 20,
		signType = "story",
		text = '"We waited here."',
		subText = "- Survivor, Day 3",
	},
	{
		position = Vector3.new(200, 0, 850),
		rotation = -30,
		signType = "story",
		text = "Town Founded 1923",
		subText = "Population: 2,847",
	},
	{
		position = Vector3.new(-200, 0, 1100),
		rotation = 15,
		signType = "story",
		text = '"Stay together."',
		subText = "- Unknown",
	},

	-- Objective signs
	{
		position = Vector3.new(50, 0, 50),
		rotation = 180,
		signType = "objective",
		text = "OBJECTIVE",
		subText = "Find Shelter",
	},
	{
		position = Vector3.new(0, 0, 500),
		rotation = 0,
		signType = "objective",
		text = "CHECKPOINT",
		subText = "Valley Entrance",
	},
	{
		position = Vector3.new(100, 0, 1400),
		rotation = 0,
		signType = "objective",
		text = "GOAL AHEAD",
		subText = "Radio Tower - Call for Help",
	},
}

-- ==========================================
-- SIGN CREATION
-- ==========================================

local function createSurfaceGui(face: Enum.NormalId, config: SignConfig, text: string, subText: string?): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui_" .. face.Name
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.Brightness = 1

	-- Background frame
	local frame = Instance.new("Frame")
	frame.Name = "Background"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = config.backgroundColor
	frame.BorderSizePixel = 0
	frame.Parent = gui

	-- Border
	local stroke = Instance.new("UIStroke")
	stroke.Color = config.borderColor
	stroke.Thickness = 4
	stroke.Parent = frame

	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = frame

	-- Main text
	local mainLabel = Instance.new("TextLabel")
	mainLabel.Name = "MainText"
	mainLabel.Size = UDim2.new(0.9, 0, subText and 0.55 or 0.8, 0)
	mainLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
	mainLabel.BackgroundTransparency = 1
	mainLabel.Text = text
	mainLabel.TextColor3 = config.textColor
	mainLabel.Font = config.font
	mainLabel.TextScaled = true
	mainLabel.TextXAlignment = Enum.TextXAlignment.Center
	mainLabel.TextYAlignment = Enum.TextYAlignment.Center
	mainLabel.Parent = frame

	-- Sub text (if provided)
	if subText then
		local subLabel = Instance.new("TextLabel")
		subLabel.Name = "SubText"
		subLabel.Size = UDim2.new(0.9, 0, 0.35, 0)
		subLabel.Position = UDim2.new(0.05, 0, 0.6, 0)
		subLabel.BackgroundTransparency = 1
		subLabel.Text = subText
		subLabel.TextColor3 = config.textColor
		subLabel.Font = config.font
		subLabel.TextScaled = true
		subLabel.TextXAlignment = Enum.TextXAlignment.Center
		subLabel.TextYAlignment = Enum.TextYAlignment.Top
		subLabel.Parent = frame
	end

	return gui
end

local function createSign(def: SignDef): Model
	local config = SIGN_CONFIGS[def.signType] or SIGN_CONFIGS.directional

	local model = Instance.new("Model")
	model.Name = "Sign_" .. def.signType

	-- Sign board
	local signBoard = Instance.new("Part")
	signBoard.Name = "SignBoard"
	signBoard.Size = config.signSize
	signBoard.Anchored = true
	signBoard.CanCollide = true
	signBoard.Material = Enum.Material.SmoothPlastic
	signBoard.Color = config.backgroundColor
	signBoard.Parent = model

	-- DOUBLE-SIDED: Add SurfaceGui to BOTH Front AND Back
	local frontGui = createSurfaceGui(Enum.NormalId.Front, config, def.text, def.subText)
	frontGui.Parent = signBoard

	local backGui = createSurfaceGui(Enum.NormalId.Back, config, def.text, def.subText)
	backGui.Parent = signBoard

	-- Post
	local post = Instance.new("Part")
	post.Name = "Post"
	post.Size = Vector3.new(0.5, config.postHeight, 0.5)
	post.Anchored = true
	post.CanCollide = true
	post.Material = Enum.Material.Metal
	post.Color = config.postColor
	post.Parent = model

	-- Position sign board on top of post
	signBoard.Position = Vector3.new(0, config.postHeight + config.signSize.Y / 2, 0)
	post.Position = Vector3.new(0, config.postHeight / 2, 0)

	model.PrimaryPart = post
	return model
end

-- ==========================================
-- SIGN SPAWNING
-- ==========================================

local function spawnSign(def: SignDef): Model
	local model = createSign(def)

	-- Get terrain height
	local y = Heightmap:GetHeight(def.position.X, def.position.Z)

	-- Position and rotate
	local cframe = CFrame.new(def.position.X, y, def.position.Z) * CFrame.Angles(0, math.rad(def.rotation), 0)

	if model.PrimaryPart then
		model:PivotTo(cframe)
	end

	-- Set attributes
	model:SetAttribute("SignType", def.signType)
	model:SetAttribute("Text", def.text)
	if def.subText then
		model:SetAttribute("SubText", def.subText)
	end

	-- Tags
	CollectionService:AddTag(model, "Sign")
	CollectionService:AddTag(model, "Sign_" .. def.signType)

	model.Parent = signsFolder
	table.insert(signs, model)

	return model
end

-- ==========================================
-- PUBLIC API
-- ==========================================

function SignService:GetSigns(): { Model }
	return signs
end

function SignService:GetSignsByType(signType: string): { Model }
	local result = {}
	for _, sign in ipairs(signs) do
		if sign:GetAttribute("SignType") == signType then
			table.insert(result, sign)
		end
	end
	return result
end

function SignService:CreateCustomSign(
	position: Vector3,
	rotation: number,
	signType: string,
	text: string,
	subText: string?
): Model
	local def: SignDef = {
		position = position,
		rotation = rotation,
		signType = signType,
		text = text,
		subText = subText,
	}
	return spawnSign(def)
end

function SignService:Initialize()
	-- Create folder
	signsFolder = Instance.new("Folder")
	signsFolder.Name = "Signs"
	signsFolder.Parent = Workspace

	-- Spawn all signs
	print("[SignService] Creating signs throughout the world...")

	local byType: { [string]: number } = {}
	for _, def in ipairs(SIGN_DEFINITIONS) do
		spawnSign(def)
		byType[def.signType] = (byType[def.signType] or 0) + 1
	end

	-- Print summary
	for signType, count in pairs(byType) do
		print(string.format("  - %s: %d signs", signType, count))
	end

	print(string.format("[SignService] Initialized with %d double-sided signs", #signs))
end

return SignService
