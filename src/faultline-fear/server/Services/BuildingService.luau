--!strict
--[[
	Faultline Fear: Building Service

	Manages procedurally-generated buildings with enterable interiors.
	Buildings are built from Roblox Parts for full control over
	interiors, collision, and interactivity.

	Features:
	- California-style architecture (ranch houses, stores, etc.)
	- Enterable interiors with working doors
	- Searchable containers with food stashes
	- Earthquake damage variants (INTACT, MODERATE, SEVERE)
	- Performance-optimized (150-200 parts per building)

	Exports: Initialize(), CreateBuilding(), GetBuildings()
	Depends: Config, Heightmap, HungerService
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Heightmap = Shared.Heightmap

local BuildingService = {}

-- ==========================================
-- TYPES
-- ==========================================

export type DamageLevel = "INTACT" | "MODERATE" | "SEVERE"

export type BuildingDef = {
	name: string,
	buildingType: string, -- "RanchHouse", "Store", etc.
	position: Vector3,
	rotation: number, -- Y rotation in degrees
	damageLevel: DamageLevel,
}

export type ContainerDef = {
	name: string,
	containerType: string, -- "KITCHEN_CABINET", "REFRIGERATOR", etc.
	foodType: string, -- "CannedFood", "Perishable", etc.
	foodAmount: number,
}

-- ==========================================
-- CONSTANTS
-- ==========================================

-- Available damage levels (for reference/documentation)
-- local DAMAGE_LEVELS: { DamageLevel } = { "INTACT", "MODERATE", "SEVERE" }

-- California color palette (warm stucco, terracotta, etc.)
local COLORS = {
	-- Walls
	STUCCO_CREAM = Color3.fromRGB(245, 235, 220),
	STUCCO_TAN = Color3.fromRGB(220, 200, 170),
	STUCCO_BEIGE = Color3.fromRGB(230, 210, 180),
	STUCCO_PINK = Color3.fromRGB(235, 200, 185),

	-- Roof
	TERRACOTTA = Color3.fromRGB(180, 95, 60),
	TERRACOTTA_DARK = Color3.fromRGB(140, 70, 45),
	ASPHALT_GRAY = Color3.fromRGB(80, 80, 85),

	-- Trim
	WOOD_BROWN = Color3.fromRGB(110, 75, 50),
	WOOD_DARK = Color3.fromRGB(70, 50, 35),
	WHITE_TRIM = Color3.fromRGB(250, 250, 250),

	-- Interior
	FLOOR_WOOD = Color3.fromRGB(160, 120, 80),
	FLOOR_TILE = Color3.fromRGB(200, 195, 185),
	CABINET_WOOD = Color3.fromRGB(130, 90, 60),
	APPLIANCE_WHITE = Color3.fromRGB(240, 240, 240),

	-- Damage
	CRACK_DARK = Color3.fromRGB(40, 35, 30),
	DEBRIS_GRAY = Color3.fromRGB(100, 95, 88),

	-- Convenience Store
	STORE_CONCRETE = Color3.fromRGB(200, 195, 190),
	STORE_METAL = Color3.fromRGB(160, 165, 170),
	STORE_GLASS = Color3.fromRGB(180, 220, 255),
	STORE_SHELF = Color3.fromRGB(80, 80, 85),
	GAS_PUMP_RED = Color3.fromRGB(180, 40, 40),
	GAS_PUMP_WHITE = Color3.fromRGB(245, 245, 245),
	NEON_BLUE = Color3.fromRGB(100, 180, 255),
	NEON_RED = Color3.fromRGB(255, 80, 80),
	LINOLEUM_FLOOR = Color3.fromRGB(180, 175, 165),
	COUNTER_TOP = Color3.fromRGB(50, 50, 55),

	-- Motel
	MOTEL_STUCCO = Color3.fromRGB(230, 220, 200),
	MOTEL_TRIM = Color3.fromRGB(50, 100, 110),
	MOTEL_DOOR = Color3.fromRGB(150, 80, 50),
	MOTEL_ROOF = Color3.fromRGB(100, 90, 80),
	POOL_BLUE = Color3.fromRGB(80, 160, 200),
	POOL_EMPTY = Color3.fromRGB(150, 145, 135),
	VENDING_RED = Color3.fromRGB(180, 50, 50),
	VENDING_BLUE = Color3.fromRGB(50, 80, 180),
	NEON_PINK = Color3.fromRGB(255, 100, 150),
	NEON_GREEN = Color3.fromRGB(100, 255, 150),
	CARPET_BROWN = Color3.fromRGB(100, 70, 50),
	BEDSHEET_WHITE = Color3.fromRGB(240, 235, 230),
	TV_BLACK = Color3.fromRGB(30, 30, 35),
	RAILING_METAL = Color3.fromRGB(140, 140, 145),
}

-- Building placements (where to spawn buildings)
local BUILDING_PLACEMENTS: { BuildingDef } = {
	-- Valley zone - residential area
	{
		name = "RanchHouse_Valley_1",
		buildingType = "RanchHouse",
		position = Vector3.new(-150, 0, 100),
		rotation = 15,
		damageLevel = "INTACT",
	},
	{
		name = "RanchHouse_Valley_2",
		buildingType = "RanchHouse",
		position = Vector3.new(120, 0, 200),
		rotation = -20,
		damageLevel = "MODERATE",
	},
	{
		name = "RanchHouse_Valley_3",
		buildingType = "RanchHouse",
		position = Vector3.new(-80, 0, 350),
		rotation = 180,
		damageLevel = "SEVERE",
	},

	-- Coastal zone
	{
		name = "RanchHouse_Coastal_1",
		buildingType = "RanchHouse",
		position = Vector3.new(200, 0, -400),
		rotation = 45,
		damageLevel = "INTACT",
	},
	{
		name = "RanchHouse_Coastal_2",
		buildingType = "RanchHouse",
		position = Vector3.new(-250, 0, -550),
		rotation = -30,
		damageLevel = "MODERATE",
	},
	{
		name = "RanchHouse_Coastal_3",
		buildingType = "RanchHouse",
		position = Vector3.new(50, 0, -700),
		rotation = 90,
		damageLevel = "SEVERE",
	},

	-- Convenience Stores
	{
		name = "ConvenienceStore_Valley_1",
		buildingType = "ConvenienceStore",
		position = Vector3.new(300, 0, 50),
		rotation = 0,
		damageLevel = "INTACT",
	},
	{
		name = "ConvenienceStore_Coastal_1",
		buildingType = "ConvenienceStore",
		position = Vector3.new(-350, 0, -450),
		rotation = -15,
		damageLevel = "MODERATE",
	},
	{
		name = "GasStation_Valley_1",
		buildingType = "ConvenienceStore",
		position = Vector3.new(-300, 0, 280),
		rotation = 45,
		damageLevel = "SEVERE",
	},

	-- Motels
	{
		name = "Motel_Coastal_1",
		buildingType = "Motel",
		position = Vector3.new(400, 0, -600),
		rotation = -10,
		damageLevel = "INTACT",
	},
	{
		name = "Motel_Valley_1",
		buildingType = "Motel",
		position = Vector3.new(-450, 0, 150),
		rotation = 90,
		damageLevel = "MODERATE",
	},
}

-- ==========================================
-- STATE
-- ==========================================

local buildingsFolder: Folder = nil :: any
local buildings: { [string]: Model } = {}

-- ==========================================
-- BUILDING GENERATORS
-- ==========================================

-- Create a simple door with ProximityPrompt
local function createDoor(parent: Model, position: Vector3, size: Vector3, name: string): Part
	local door = Instance.new("Part")
	door.Name = name
	door.Anchored = true
	door.CanCollide = true
	door.Size = size
	door.Position = position
	door.Color = COLORS.WOOD_BROWN
	door.Material = Enum.Material.Wood
	door.Parent = parent

	-- Add proximity prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open"
	prompt.ObjectText = "Door"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = door

	-- Door state
	door:SetAttribute("IsOpen", false)
	door:SetAttribute("OriginalCFrame", door.CFrame:ToWorldSpace(CFrame.new()))

	-- Store original position for toggling
	local originalCFrame = door.CFrame

	prompt.Triggered:Connect(function(_player)
		local isOpen = door:GetAttribute("IsOpen")
		if isOpen then
			-- Close door
			door.CFrame = originalCFrame
			door.CanCollide = true
			prompt.ActionText = "Open"
		else
			-- Open door (swing 90 degrees)
			local pivot = originalCFrame * CFrame.new(-size.X / 2, 0, 0)
			door.CFrame = pivot * CFrame.Angles(0, math.rad(-90), 0) * CFrame.new(size.X / 2, 0, 0)
			door.CanCollide = false
			prompt.ActionText = "Close"
		end
		door:SetAttribute("IsOpen", not isOpen)
	end)

	CollectionService:AddTag(door, "Door")
	return door
end

-- Create a searchable container
local function createContainer(
	parent: Model,
	position: Vector3,
	size: Vector3,
	name: string,
	containerType: string,
	color: Color3
): Part
	local container = Instance.new("Part")
	container.Name = name
	container.Anchored = true
	container.CanCollide = true
	container.Size = size
	container.Position = position
	container.Color = color
	container.Material = Enum.Material.SmoothPlastic
	container.Parent = parent

	-- Add proximity prompt for searching
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Search"
	prompt.ObjectText = containerType
	prompt.HoldDuration = 1.5 -- Takes time to search
	prompt.MaxActivationDistance = 6
	prompt.RequiresLineOfSight = true
	prompt.Parent = container

	-- Container state
	container:SetAttribute("ContainerType", containerType)
	container:SetAttribute("Searched", false)
	container:SetAttribute("FoodAmount", math.random(1, 3))

	prompt.Triggered:Connect(function(player)
		if container:GetAttribute("Searched") then
			-- Already searched
			return
		end

		local foodAmount = container:GetAttribute("FoodAmount")
		container:SetAttribute("Searched", true)
		prompt.Enabled = false

		-- Fire hunger remote to give food
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		if remotes then
			local hungerRemote = remotes:FindFirstChild("HungerUpdate")
			if hungerRemote and hungerRemote:IsA("RemoteEvent") then
				-- Calculate food value based on container type
				local foodValue = foodAmount * 10
				if containerType == "Refrigerator" then
					foodValue = foodAmount * 15
				elseif containerType == "Pantry" then
					foodValue = foodAmount * 12
				end

				hungerRemote:FireClient(player, "add", foodValue)
			end
		end

		-- Visual feedback - change color slightly
		container.Color = Color3.fromRGB(
			math.floor(color.R * 255 * 0.7),
			math.floor(color.G * 255 * 0.7),
			math.floor(color.B * 255 * 0.7)
		)
	end)

	CollectionService:AddTag(container, "SearchableContainer")
	CollectionService:AddTag(container, containerType)
	return container
end

-- Create a wall with optional window
local function createWall(
	parent: Model,
	position: Vector3,
	size: Vector3,
	color: Color3,
	hasWindow: boolean,
	windowBroken: boolean
): Part
	local wall = Instance.new("Part")
	wall.Name = "Wall"
	wall.Anchored = true
	wall.CanCollide = true
	wall.Size = size
	wall.Position = position
	wall.Color = color
	wall.Material = Enum.Material.Concrete
	wall.Parent = parent

	if hasWindow then
		-- Create window frame
		local windowSize = Vector3.new(size.X * 0.4, size.Y * 0.4, size.Z + 0.2)
		local windowPos = position + Vector3.new(0, size.Y * 0.1, 0)

		local window = Instance.new("Part")
		window.Name = "Window"
		window.Anchored = true
		window.CanCollide = false
		window.Size = windowSize
		window.Position = windowPos
		window.Transparency = windowBroken and 1 or 0.5
		window.Color = windowBroken and COLORS.CRACK_DARK or Color3.fromRGB(180, 220, 255)
		window.Material = Enum.Material.Glass
		window.Parent = parent

		if windowBroken then
			CollectionService:AddTag(window, "BrokenWindow")
		end
	end

	return wall
end

-- Create California ranch house
local function createRanchHouse(def: BuildingDef): Model
	local house = Instance.new("Model")
	house.Name = def.name

	-- Base dimensions
	local width = 36 -- studs
	local depth = 26
	local wallHeight = 12
	local wallThickness = 0.8
	local roofOverhang = 2

	-- Determine damage effects
	local isBrokenWindows = def.damageLevel == "MODERATE" or def.damageLevel == "SEVERE"
	local hasCracks = def.damageLevel ~= "INTACT"
	local hasDebris = def.damageLevel == "SEVERE"
	local roofTilt = def.damageLevel == "SEVERE" and 5 or 0

	-- Choose wall color (slight variation)
	local wallColors = { COLORS.STUCCO_CREAM, COLORS.STUCCO_TAN, COLORS.STUCCO_BEIGE }
	local wallColor = wallColors[math.random(1, #wallColors)]

	-- FOUNDATION / FLOOR
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Size = Vector3.new(width, 0.5, depth)
	floor.Position = Vector3.new(0, 0.25, 0)
	floor.Color = COLORS.FLOOR_WOOD
	floor.Material = Enum.Material.Wood
	floor.Parent = house

	-- EXTERIOR WALLS
	-- Front wall (with door and windows)
	local frontWall = createWall(
		house,
		Vector3.new(0, wallHeight / 2, -depth / 2),
		Vector3.new(width, wallHeight, wallThickness),
		wallColor,
		true,
		isBrokenWindows
	)
	frontWall.Name = "FrontWall"

	-- Back wall
	local backWall = createWall(
		house,
		Vector3.new(0, wallHeight / 2, depth / 2),
		Vector3.new(width, wallHeight, wallThickness),
		wallColor,
		true,
		isBrokenWindows
	)
	backWall.Name = "BackWall"

	-- Left wall
	local leftWall = createWall(
		house,
		Vector3.new(-width / 2, wallHeight / 2, 0),
		Vector3.new(wallThickness, wallHeight, depth),
		wallColor,
		true,
		isBrokenWindows
	)
	leftWall.Name = "LeftWall"

	-- Right wall
	local rightWall = createWall(
		house,
		Vector3.new(width / 2, wallHeight / 2, 0),
		Vector3.new(wallThickness, wallHeight, depth),
		wallColor,
		true,
		isBrokenWindows
	)
	rightWall.Name = "RightWall"

	-- FRONT DOOR (entry point)
	local doorWidth = 4
	local doorHeight = 8
	local doorPos = Vector3.new(5, doorHeight / 2, -depth / 2 - wallThickness / 2)
	createDoor(house, doorPos, Vector3.new(doorWidth, doorHeight, wallThickness), "FrontDoor")

	-- ROOF (flat with slight slope, terracotta style)
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Anchored = true
	roof.Size = Vector3.new(width + roofOverhang * 2, 1, depth + roofOverhang * 2)
	roof.Color = COLORS.TERRACOTTA
	roof.Material = Enum.Material.Brick
	roof.Parent = house

	-- Apply roof tilt for damage
	local roofCFrame = CFrame.new(0, wallHeight + 0.5, 0) * CFrame.Angles(math.rad(roofTilt), 0, 0)
	roof.CFrame = roofCFrame

	-- INTERIOR WALLS (divide into rooms)
	-- Living room / Kitchen divider
	local interiorWall1 = Instance.new("Part")
	interiorWall1.Name = "InteriorWall1"
	interiorWall1.Anchored = true
	interiorWall1.Size = Vector3.new(wallThickness, wallHeight * 0.9, depth * 0.6)
	interiorWall1.Position = Vector3.new(-width / 4, wallHeight * 0.45, depth * 0.1)
	interiorWall1.Color = COLORS.STUCCO_CREAM
	interiorWall1.Material = Enum.Material.SmoothPlastic
	interiorWall1.Parent = house

	-- KITCHEN AREA (back left)
	-- Kitchen cabinet (container adds itself to house)
	createContainer(
		house,
		Vector3.new(-width / 3, 3, depth / 3),
		Vector3.new(6, 6, 2),
		"KitchenCabinet",
		"Cabinet",
		COLORS.CABINET_WOOD
	)

	-- Refrigerator
	createContainer(
		house,
		Vector3.new(-width / 3 + 8, 4, depth / 3),
		Vector3.new(3, 8, 3),
		"Refrigerator",
		"Refrigerator",
		COLORS.APPLIANCE_WHITE
	)

	-- Pantry
	createContainer(
		house,
		Vector3.new(-width / 3 - 4, 4, depth / 3 - 4),
		Vector3.new(2, 8, 2),
		"Pantry",
		"Pantry",
		COLORS.WOOD_BROWN
	)

	-- LIVING ROOM FURNITURE (front right)
	-- Couch
	local couch = Instance.new("Part")
	couch.Name = "Couch"
	couch.Anchored = true
	couch.Size = Vector3.new(8, 3, 3)
	couch.Position = Vector3.new(width / 4, 1.5, -depth / 4)
	couch.Color = Color3.fromRGB(80, 60, 50)
	couch.Material = Enum.Material.Fabric
	couch.Parent = house

	-- Coffee table
	local table = Instance.new("Part")
	table.Name = "CoffeeTable"
	table.Anchored = true
	table.Size = Vector3.new(4, 1.5, 2)
	table.Position = Vector3.new(width / 4, 0.75, -depth / 4 + 4)
	table.Color = COLORS.WOOD_BROWN
	table.Material = Enum.Material.Wood
	table.Parent = house

	-- BEDROOM (back right)
	-- Bed
	local bed = Instance.new("Part")
	bed.Name = "Bed"
	bed.Anchored = true
	bed.Size = Vector3.new(6, 2, 8)
	bed.Position = Vector3.new(width / 4, 1, depth / 4)
	bed.Color = Color3.fromRGB(200, 180, 160)
	bed.Material = Enum.Material.Fabric
	bed.Parent = house

	-- DAMAGE EFFECTS
	if hasCracks then
		-- Add crack decals or dark lines on walls
		local crack = Instance.new("Part")
		crack.Name = "WallCrack"
		crack.Anchored = true
		crack.CanCollide = false
		crack.Size = Vector3.new(0.2, wallHeight * 0.6, wallThickness + 0.1)
		crack.Position = frontWall.Position + Vector3.new(width / 3, 0, 0)
		crack.Color = COLORS.CRACK_DARK
		crack.Material = Enum.Material.Slate
		crack.Transparency = 0.3
		crack.Parent = house
		CollectionService:AddTag(crack, "DamageEffect")
	end

	if hasDebris then
		-- Scatter debris
		local random = Random.new()
		for i = 1, 8 do
			local debris = Instance.new("Part")
			debris.Name = "Debris_" .. i
			debris.Anchored = true
			debris.Size = Vector3.new(random:NextNumber(0.5, 2), random:NextNumber(0.3, 1), random:NextNumber(0.5, 2))
			debris.Position = Vector3.new(
				random:NextNumber(-width / 3, width / 3),
				debris.Size.Y / 2,
				random:NextNumber(-depth / 3, depth / 3)
			)
			debris.Color = COLORS.DEBRIS_GRAY
			debris.Material = Enum.Material.Rock
			debris.Rotation =
				Vector3.new(random:NextNumber(-20, 20), random:NextNumber(0, 360), random:NextNumber(-20, 20))
			debris.Parent = house
			CollectionService:AddTag(debris, "Debris")
		end
	end

	-- Set primary part for positioning
	house.PrimaryPart = floor

	-- Tags and attributes
	CollectionService:AddTag(house, "Building")
	CollectionService:AddTag(house, "RanchHouse")
	CollectionService:AddTag(house, "Enterable")
	house:SetAttribute("BuildingType", "RanchHouse")
	house:SetAttribute("DamageLevel", def.damageLevel)

	return house
end

-- Create a gas pump
local function createGasPump(parent: Model, position: Vector3, rotation: number): Model
	local pump = Instance.new("Model")
	pump.Name = "GasPump"

	-- Main body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.Size = Vector3.new(2.5, 6, 1.5)
	body.Position = position + Vector3.new(0, 3, 0)
	body.Color = COLORS.GAS_PUMP_WHITE
	body.Material = Enum.Material.SmoothPlastic
	body.Parent = pump

	-- Red top stripe
	local stripe = Instance.new("Part")
	stripe.Name = "TopStripe"
	stripe.Anchored = true
	stripe.Size = Vector3.new(2.6, 1, 1.6)
	stripe.Position = position + Vector3.new(0, 5.5, 0)
	stripe.Color = COLORS.GAS_PUMP_RED
	stripe.Material = Enum.Material.SmoothPlastic
	stripe.Parent = pump

	-- Nozzle holder
	local nozzle = Instance.new("Part")
	nozzle.Name = "NozzleHolder"
	nozzle.Anchored = true
	nozzle.Size = Vector3.new(0.8, 1.5, 0.3)
	nozzle.Position = position + Vector3.new(0, 3.5, -0.9)
	nozzle.Color = COLORS.STORE_METAL
	nozzle.Material = Enum.Material.Metal
	nozzle.Parent = pump

	-- Display screen
	local display = Instance.new("Part")
	display.Name = "Display"
	display.Anchored = true
	display.Size = Vector3.new(1.8, 1, 0.1)
	display.Position = position + Vector3.new(0, 4.5, -0.8)
	display.Color = Color3.fromRGB(20, 40, 20)
	display.Material = Enum.Material.Neon
	display.Parent = pump

	pump.PrimaryPart = body

	-- Rotate pump
	pump:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.rad(rotation), 0) + Vector3.new(0, 0, 0))

	pump.Parent = parent
	CollectionService:AddTag(pump, "GasPump")
	return pump
end

-- Create a store shelf
local function createShelf(parent: Model, position: Vector3, size: Vector3, name: string, hasFood: boolean): Part
	local shelf = Instance.new("Part")
	shelf.Name = name
	shelf.Anchored = true
	shelf.CanCollide = true
	shelf.Size = size
	shelf.Position = position
	shelf.Color = COLORS.STORE_SHELF
	shelf.Material = Enum.Material.Metal
	shelf.Parent = parent

	-- Add shelving lines (visual detail)
	local numShelves = math.floor(size.Y / 2)
	for i = 1, numShelves do
		local shelfLine = Instance.new("Part")
		shelfLine.Name = "ShelfLine_" .. i
		shelfLine.Anchored = true
		shelfLine.CanCollide = false
		shelfLine.Size = Vector3.new(size.X + 0.1, 0.1, size.Z + 0.1)
		shelfLine.Position = position + Vector3.new(0, -size.Y / 2 + i * (size.Y / (numShelves + 1)), 0)
		shelfLine.Color = COLORS.STORE_METAL
		shelfLine.Material = Enum.Material.Metal
		shelfLine.Parent = parent
	end

	if hasFood then
		-- Make this a searchable container
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Search"
		prompt.ObjectText = "Store Shelf"
		prompt.HoldDuration = 1.5
		prompt.MaxActivationDistance = 6
		prompt.RequiresLineOfSight = true
		prompt.Parent = shelf

		shelf:SetAttribute("ContainerType", "StoreShelf")
		shelf:SetAttribute("Searched", false)
		shelf:SetAttribute("FoodAmount", math.random(2, 5))

		prompt.Triggered:Connect(function(player)
			if shelf:GetAttribute("Searched") then
				return
			end

			local foodAmount = shelf:GetAttribute("FoodAmount")
			shelf:SetAttribute("Searched", true)
			prompt.Enabled = false

			local remotes = ReplicatedStorage:FindFirstChild("Remotes")
			if remotes then
				local hungerRemote = remotes:FindFirstChild("HungerUpdate")
				if hungerRemote and hungerRemote:IsA("RemoteEvent") then
					local foodValue = foodAmount * 8
					hungerRemote:FireClient(player, "add", foodValue)
				end
			end

			shelf.Color = Color3.fromRGB(60, 60, 65)
		end)

		CollectionService:AddTag(shelf, "SearchableContainer")
		CollectionService:AddTag(shelf, "StoreShelf")
	end

	return shelf
end

-- Create California convenience store / gas station
local function createConvenienceStore(def: BuildingDef): Model
	local store = Instance.new("Model")
	store.Name = def.name

	-- Base dimensions (larger than ranch house)
	local width = 50
	local depth = 40
	local wallHeight = 14
	local wallThickness = 0.8

	-- Determine damage effects
	local isBrokenWindows = def.damageLevel == "MODERATE" or def.damageLevel == "SEVERE"
	local hasCracks = def.damageLevel ~= "INTACT"
	local hasDebris = def.damageLevel == "SEVERE"
	local roofSag = def.damageLevel == "SEVERE" and 2 or 0

	-- FOUNDATION / FLOOR
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Size = Vector3.new(width, 0.5, depth)
	floor.Position = Vector3.new(0, 0.25, 0)
	floor.Color = COLORS.LINOLEUM_FLOOR
	floor.Material = Enum.Material.SmoothPlastic
	floor.Parent = store

	-- EXTERIOR WALLS
	-- Front wall (large glass storefront)
	local frontWallLeft = Instance.new("Part")
	frontWallLeft.Name = "FrontWallLeft"
	frontWallLeft.Anchored = true
	frontWallLeft.Size = Vector3.new(width * 0.15, wallHeight, wallThickness)
	frontWallLeft.Position = Vector3.new(-width / 2 + width * 0.075, wallHeight / 2, -depth / 2)
	frontWallLeft.Color = COLORS.STORE_CONCRETE
	frontWallLeft.Material = Enum.Material.Concrete
	frontWallLeft.Parent = store

	local frontWallRight = Instance.new("Part")
	frontWallRight.Name = "FrontWallRight"
	frontWallRight.Anchored = true
	frontWallRight.Size = Vector3.new(width * 0.15, wallHeight, wallThickness)
	frontWallRight.Position = Vector3.new(width / 2 - width * 0.075, wallHeight / 2, -depth / 2)
	frontWallRight.Color = COLORS.STORE_CONCRETE
	frontWallRight.Material = Enum.Material.Concrete
	frontWallRight.Parent = store

	-- Large glass windows (storefront)
	local glassWidth = width * 0.7
	local glassWindow = Instance.new("Part")
	glassWindow.Name = "StorefrontGlass"
	glassWindow.Anchored = true
	glassWindow.CanCollide = true
	glassWindow.Size = Vector3.new(glassWidth, wallHeight * 0.8, wallThickness * 0.5)
	glassWindow.Position = Vector3.new(0, wallHeight * 0.45, -depth / 2)
	glassWindow.Transparency = isBrokenWindows and 0.9 or 0.3
	glassWindow.Color = isBrokenWindows and COLORS.CRACK_DARK or COLORS.STORE_GLASS
	glassWindow.Material = Enum.Material.Glass
	glassWindow.Parent = store

	if isBrokenWindows then
		CollectionService:AddTag(glassWindow, "BrokenWindow")
	end

	-- Back wall
	local backWall = Instance.new("Part")
	backWall.Name = "BackWall"
	backWall.Anchored = true
	backWall.Size = Vector3.new(width, wallHeight, wallThickness)
	backWall.Position = Vector3.new(0, wallHeight / 2, depth / 2)
	backWall.Color = COLORS.STORE_CONCRETE
	backWall.Material = Enum.Material.Concrete
	backWall.Parent = store

	-- Side walls
	local leftWall = Instance.new("Part")
	leftWall.Name = "LeftWall"
	leftWall.Anchored = true
	leftWall.Size = Vector3.new(wallThickness, wallHeight, depth)
	leftWall.Position = Vector3.new(-width / 2, wallHeight / 2, 0)
	leftWall.Color = COLORS.STORE_CONCRETE
	leftWall.Material = Enum.Material.Concrete
	leftWall.Parent = store

	local rightWall = Instance.new("Part")
	rightWall.Name = "RightWall"
	rightWall.Anchored = true
	rightWall.Size = Vector3.new(wallThickness, wallHeight, depth)
	rightWall.Position = Vector3.new(width / 2, wallHeight / 2, 0)
	rightWall.Color = COLORS.STORE_CONCRETE
	rightWall.Material = Enum.Material.Concrete
	rightWall.Parent = store

	-- ROOF (flat commercial)
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Anchored = true
	roof.Size = Vector3.new(width + 2, 1, depth + 2)
	roof.Position = Vector3.new(0, wallHeight + 0.5 - roofSag / 2, 0)
	roof.Color = COLORS.ASPHALT_GRAY
	roof.Material = Enum.Material.Asphalt
	roof.Parent = store

	if roofSag > 0 then
		roof.CFrame = roof.CFrame * CFrame.Angles(math.rad(roofSag), 0, math.rad(roofSag / 2))
	end

	-- FRONT DOOR (automatic glass door style)
	local doorWidth = 6
	local doorHeight = 10
	local doorPos = Vector3.new(0, doorHeight / 2, -depth / 2 - wallThickness / 2)
	createDoor(store, doorPos, Vector3.new(doorWidth, doorHeight, wallThickness), "FrontDoor")

	-- STORE SIGN (on front)
	local sign = Instance.new("Part")
	sign.Name = "StoreSign"
	sign.Anchored = true
	sign.Size = Vector3.new(20, 3, 0.5)
	sign.Position = Vector3.new(0, wallHeight - 1, -depth / 2 - 0.5)
	sign.Color = COLORS.NEON_BLUE
	sign.Material = Enum.Material.Neon
	sign.Parent = store

	-- Sign light (neon effect)
	local signLight = Instance.new("PointLight")
	signLight.Brightness = 2
	signLight.Range = 20
	signLight.Color = COLORS.NEON_BLUE
	signLight.Parent = sign

	-- ==========================================
	-- INTERIOR - STORE AISLES
	-- ==========================================

	-- Aisle 1 (left side - snacks/chips)
	createShelf(store, Vector3.new(-width / 4, 3, -depth / 6), Vector3.new(1.5, 6, 12), "Aisle1_Left", true)
	createShelf(store, Vector3.new(-width / 4 + 4, 3, -depth / 6), Vector3.new(1.5, 6, 12), "Aisle1_Right", true)

	-- Aisle 2 (center - canned goods)
	createShelf(store, Vector3.new(0, 3, -depth / 6), Vector3.new(1.5, 6, 12), "Aisle2_Left", true)
	createShelf(store, Vector3.new(4, 3, -depth / 6), Vector3.new(1.5, 6, 12), "Aisle2_Right", true)

	-- Aisle 3 (right side - beverages)
	createShelf(store, Vector3.new(width / 4, 3, -depth / 6), Vector3.new(1.5, 6, 12), "Aisle3_Left", true)

	-- ==========================================
	-- REFRIGERATED CASES (back wall)
	-- ==========================================

	local fridgeWidth = 8
	for i = 0, 2 do
		local fridgeX = -width / 3 + i * (fridgeWidth + 2)
		local fridge = createContainer(
			store,
			Vector3.new(fridgeX, 4, depth / 2 - 2),
			Vector3.new(fridgeWidth, 8, 2),
			"RefrigeratedCase_" .. (i + 1),
			"Refrigerator",
			Color3.fromRGB(220, 240, 255)
		)
		fridge.Material = Enum.Material.Glass
		fridge.Transparency = 0.4

		-- Cold light
		local coldLight = Instance.new("PointLight")
		coldLight.Brightness = 1
		coldLight.Range = 8
		coldLight.Color = Color3.fromRGB(200, 220, 255)
		coldLight.Parent = fridge
	end

	-- ==========================================
	-- CHECKOUT COUNTER
	-- ==========================================

	local counter = Instance.new("Part")
	counter.Name = "CheckoutCounter"
	counter.Anchored = true
	counter.Size = Vector3.new(12, 4, 3)
	counter.Position = Vector3.new(width / 3, 2, -depth / 3)
	counter.Color = COLORS.COUNTER_TOP
	counter.Material = Enum.Material.Granite
	counter.Parent = store

	-- Cash register
	local register = Instance.new("Part")
	register.Name = "CashRegister"
	register.Anchored = true
	register.Size = Vector3.new(2, 1.5, 1.5)
	register.Position = Vector3.new(width / 3, 4.75, -depth / 3)
	register.Color = COLORS.STORE_METAL
	register.Material = Enum.Material.Metal
	register.Parent = store

	-- Behind counter snacks (searchable)
	createContainer(
		store,
		Vector3.new(width / 3 + 3, 4, -depth / 3 + 3),
		Vector3.new(4, 5, 1.5),
		"BehindCounterSnacks",
		"Cabinet",
		COLORS.STORE_SHELF
	)

	-- ==========================================
	-- BACK ROOM / STORAGE
	-- ==========================================

	-- Back room wall
	local backRoomWall = Instance.new("Part")
	backRoomWall.Name = "BackRoomWall"
	backRoomWall.Anchored = true
	backRoomWall.Size = Vector3.new(width * 0.4, wallHeight * 0.9, wallThickness)
	backRoomWall.Position = Vector3.new(width / 4, wallHeight * 0.45, depth / 4)
	backRoomWall.Color = COLORS.STORE_CONCRETE
	backRoomWall.Material = Enum.Material.Concrete
	backRoomWall.Parent = store

	-- Storage room door
	createDoor(store, Vector3.new(width / 4 - 8, 4, depth / 4), Vector3.new(4, 8, wallThickness), "StorageRoomDoor")

	-- Storage boxes (searchable)
	createContainer(
		store,
		Vector3.new(width / 3, 2, depth / 3),
		Vector3.new(4, 4, 4),
		"StorageBox_1",
		"Pantry",
		Color3.fromRGB(139, 90, 43)
	)

	createContainer(
		store,
		Vector3.new(width / 3 + 6, 2, depth / 3),
		Vector3.new(4, 4, 4),
		"StorageBox_2",
		"Pantry",
		Color3.fromRGB(139, 90, 43)
	)

	-- ==========================================
	-- GAS PUMPS (outside, in front)
	-- ==========================================

	-- Gas pump island
	local pumpIsland = Instance.new("Part")
	pumpIsland.Name = "PumpIsland"
	pumpIsland.Anchored = true
	pumpIsland.Size = Vector3.new(20, 0.5, 8)
	pumpIsland.Position = Vector3.new(0, 0.25, -depth / 2 - 15)
	pumpIsland.Color = COLORS.STORE_CONCRETE
	pumpIsland.Material = Enum.Material.Concrete
	pumpIsland.Parent = store

	-- Gas pumps
	createGasPump(store, Vector3.new(-6, 0.5, -depth / 2 - 15), 0)
	createGasPump(store, Vector3.new(0, 0.5, -depth / 2 - 15), 0)
	createGasPump(store, Vector3.new(6, 0.5, -depth / 2 - 15), 0)

	-- Pump canopy
	local canopy = Instance.new("Part")
	canopy.Name = "PumpCanopy"
	canopy.Anchored = true
	canopy.Size = Vector3.new(24, 1, 12)
	canopy.Position = Vector3.new(0, 12, -depth / 2 - 15)
	canopy.Color = COLORS.GAS_PUMP_WHITE
	canopy.Material = Enum.Material.SmoothPlastic
	canopy.Parent = store

	-- Canopy support pillars
	for _, xPos in ipairs({ -10, 10 }) do
		local pillar = Instance.new("Part")
		pillar.Name = "CanopyPillar"
		pillar.Anchored = true
		pillar.Size = Vector3.new(1, 11.5, 1)
		pillar.Position = Vector3.new(xPos, 6, -depth / 2 - 15)
		pillar.Color = COLORS.STORE_METAL
		pillar.Material = Enum.Material.Metal
		pillar.Parent = store
	end

	-- Canopy lights
	for _, xPos in ipairs({ -6, 0, 6 }) do
		local canopyLight = Instance.new("Part")
		canopyLight.Name = "CanopyLight"
		canopyLight.Anchored = true
		canopyLight.Size = Vector3.new(4, 0.3, 4)
		canopyLight.Position = Vector3.new(xPos, 11.4, -depth / 2 - 15)
		canopyLight.Color = Color3.fromRGB(255, 250, 240)
		canopyLight.Material = Enum.Material.Neon
		canopyLight.Parent = store

		local light = Instance.new("PointLight")
		light.Brightness = 3
		light.Range = 25
		light.Color = Color3.fromRGB(255, 250, 240)
		light.Parent = canopyLight
	end

	-- ==========================================
	-- FLICKERING LIGHT EFFECT
	-- ==========================================

	-- Interior ceiling lights with flicker
	local flickerLights: { PointLight } = {}
	for i = 0, 2 do
		for j = 0, 1 do
			local ceilingLight = Instance.new("Part")
			ceilingLight.Name = "CeilingLight_" .. i .. "_" .. j
			ceilingLight.Anchored = true
			ceilingLight.Size = Vector3.new(4, 0.3, 2)
			ceilingLight.Position =
				Vector3.new(-width / 4 + i * (width / 4), wallHeight - 0.5, -depth / 4 + j * (depth / 3))
			ceilingLight.Color = Color3.fromRGB(255, 255, 245)
			ceilingLight.Material = Enum.Material.Neon
			ceilingLight.Parent = store

			local light = Instance.new("PointLight")
			light.Brightness = 2
			light.Range = 20
			light.Color = Color3.fromRGB(255, 255, 245)
			light.Parent = ceilingLight

			table.insert(flickerLights, light)
		end
	end

	-- Flicker effect coroutine (for damaged buildings)
	if hasCracks then
		task.spawn(function()
			local random = Random.new()
			while store.Parent do
				for _, light in ipairs(flickerLights) do
					if random:NextNumber() < 0.1 then
						-- Flicker
						local originalBrightness = light.Brightness
						light.Brightness = 0
						task.wait(random:NextNumber(0.05, 0.15))
						light.Brightness = originalBrightness
						if random:NextNumber() < 0.3 then
							-- Double flicker
							task.wait(random:NextNumber(0.02, 0.08))
							light.Brightness = 0
							task.wait(random:NextNumber(0.05, 0.1))
							light.Brightness = originalBrightness
						end
					end
				end
				task.wait(random:NextNumber(0.5, 2))
			end
		end)
	end

	-- ==========================================
	-- DAMAGE EFFECTS
	-- ==========================================

	if hasCracks then
		-- Wall cracks
		for _, wall in ipairs({ backWall, leftWall, rightWall }) do
			local crack = Instance.new("Part")
			crack.Name = "WallCrack"
			crack.Anchored = true
			crack.CanCollide = false
			crack.Size = Vector3.new(0.2, wallHeight * 0.5, wallThickness + 0.1)
			crack.CFrame = wall.CFrame * CFrame.new(wall.Size.X / 4, 0, 0)
			crack.Color = COLORS.CRACK_DARK
			crack.Material = Enum.Material.Slate
			crack.Transparency = 0.3
			crack.Parent = store
			CollectionService:AddTag(crack, "DamageEffect")
		end
	end

	if hasDebris then
		-- Scatter debris
		local random = Random.new()
		for i = 1, 12 do
			local debris = Instance.new("Part")
			debris.Name = "Debris_" .. i
			debris.Anchored = true
			debris.Size =
				Vector3.new(random:NextNumber(0.5, 2.5), random:NextNumber(0.3, 1.2), random:NextNumber(0.5, 2.5))
			debris.Position = Vector3.new(
				random:NextNumber(-width / 3, width / 3),
				debris.Size.Y / 2,
				random:NextNumber(-depth / 3, depth / 3)
			)
			debris.Color = COLORS.DEBRIS_GRAY
			debris.Material = Enum.Material.Rock
			debris.Rotation =
				Vector3.new(random:NextNumber(-25, 25), random:NextNumber(0, 360), random:NextNumber(-25, 25))
			debris.Parent = store
			CollectionService:AddTag(debris, "Debris")
		end

		-- Fallen shelf
		local fallenShelf = Instance.new("Part")
		fallenShelf.Name = "FallenShelf"
		fallenShelf.Anchored = true
		fallenShelf.Size = Vector3.new(1.5, 6, 10)
		fallenShelf.Position = Vector3.new(-width / 5, 3, 0)
		fallenShelf.Rotation = Vector3.new(0, 15, 75)
		fallenShelf.Color = COLORS.STORE_SHELF
		fallenShelf.Material = Enum.Material.Metal
		fallenShelf.Parent = store
		CollectionService:AddTag(fallenShelf, "Debris")
	end

	-- Set primary part
	store.PrimaryPart = floor

	-- Tags and attributes
	CollectionService:AddTag(store, "Building")
	CollectionService:AddTag(store, "ConvenienceStore")
	CollectionService:AddTag(store, "Enterable")
	store:SetAttribute("BuildingType", "ConvenienceStore")
	store:SetAttribute("DamageLevel", def.damageLevel)

	return store
end

-- Create a vending machine
local function createVendingMachine(parent: Model, position: Vector3, rotation: number, machineType: string): Part
	local machine = Instance.new("Part")
	machine.Name = "VendingMachine_" .. machineType
	machine.Anchored = true
	machine.Size = Vector3.new(3, 6, 2.5)
	machine.Position = position + Vector3.new(0, 3, 0)
	machine.Color = machineType == "Snacks" and COLORS.VENDING_RED or COLORS.VENDING_BLUE
	machine.Material = Enum.Material.SmoothPlastic
	machine.CFrame = CFrame.new(position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, math.rad(rotation), 0)
	machine.Parent = parent

	-- Glass front
	local glass = Instance.new("Part")
	glass.Name = "Glass"
	glass.Anchored = true
	glass.CanCollide = false
	glass.Size = Vector3.new(2.5, 4, 0.1)
	glass.CFrame = machine.CFrame * CFrame.new(0, 0.5, -1.3)
	glass.Color = COLORS.STORE_GLASS
	glass.Material = Enum.Material.Glass
	glass.Transparency = 0.3
	glass.Parent = parent

	-- Make searchable
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Search"
	prompt.ObjectText = machineType .. " Machine"
	prompt.HoldDuration = 1.5
	prompt.MaxActivationDistance = 6
	prompt.RequiresLineOfSight = true
	prompt.Parent = machine

	machine:SetAttribute("ContainerType", "VendingMachine")
	machine:SetAttribute("Searched", false)
	machine:SetAttribute("FoodAmount", math.random(2, 4))

	prompt.Triggered:Connect(function(player)
		if machine:GetAttribute("Searched") then
			return
		end

		local foodAmount = machine:GetAttribute("FoodAmount")
		machine:SetAttribute("Searched", true)
		prompt.Enabled = false

		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		if remotes then
			local hungerRemote = remotes:FindFirstChild("HungerUpdate")
			if hungerRemote and hungerRemote:IsA("RemoteEvent") then
				local foodValue = foodAmount * 10
				hungerRemote:FireClient(player, "add", foodValue)
			end
		end
	end)

	CollectionService:AddTag(machine, "SearchableContainer")
	CollectionService:AddTag(machine, "VendingMachine")
	return machine
end

-- Create a motel room interior
local function createMotelRoom(
	parent: Model,
	roomPos: Vector3,
	roomWidth: number,
	roomDepth: number,
	_roomHeight: number,
	roomNumber: number,
	isCollapsed: boolean,
	isRansacked: boolean
): ()
	if isCollapsed then
		-- Just debris for collapsed rooms
		local random = Random.new(roomNumber)
		for i = 1, 5 do
			local debris = Instance.new("Part")
			debris.Name = "RoomDebris_" .. roomNumber .. "_" .. i
			debris.Anchored = true
			debris.Size = Vector3.new(random:NextNumber(1, 3), random:NextNumber(0.5, 2), random:NextNumber(1, 3))
			debris.Position = roomPos
				+ Vector3.new(
					random:NextNumber(-roomWidth / 3, roomWidth / 3),
					debris.Size.Y / 2,
					random:NextNumber(-roomDepth / 3, roomDepth / 3)
				)
			debris.Color = COLORS.DEBRIS_GRAY
			debris.Material = Enum.Material.Rock
			debris.Rotation =
				Vector3.new(random:NextNumber(-30, 30), random:NextNumber(0, 360), random:NextNumber(-30, 30))
			debris.Parent = parent
			CollectionService:AddTag(debris, "Debris")
		end
		return
	end

	-- Room floor (carpet)
	local carpet = Instance.new("Part")
	carpet.Name = "RoomCarpet_" .. roomNumber
	carpet.Anchored = true
	carpet.CanCollide = true
	carpet.Size = Vector3.new(roomWidth - 0.2, 0.1, roomDepth - 0.2)
	carpet.Position = roomPos + Vector3.new(0, 0.05, 0)
	carpet.Color = COLORS.CARPET_BROWN
	carpet.Material = Enum.Material.Fabric
	carpet.Parent = parent

	-- Bed
	local bed = Instance.new("Part")
	bed.Name = "Bed_" .. roomNumber
	bed.Anchored = true
	bed.Size = Vector3.new(5, 2, 7)
	local bedOffset = isRansacked and Vector3.new(0.5, 1, 0) or Vector3.new(0, 1, 0)
	bed.Position = roomPos + Vector3.new(-roomWidth / 4, 0, roomDepth / 4) + bedOffset
	bed.Color = COLORS.BEDSHEET_WHITE
	bed.Material = Enum.Material.Fabric
	if isRansacked then
		bed.Rotation = Vector3.new(0, 15, 5)
	end
	bed.Parent = parent

	-- Nightstand
	local nightstand = Instance.new("Part")
	nightstand.Name = "Nightstand_" .. roomNumber
	nightstand.Anchored = true
	nightstand.Size = Vector3.new(1.5, 2, 1.5)
	nightstand.Position = roomPos + Vector3.new(-roomWidth / 4 + 3.5, 1, roomDepth / 4 - 3)
	nightstand.Color = COLORS.WOOD_BROWN
	nightstand.Material = Enum.Material.Wood
	nightstand.Parent = parent

	-- TV
	local tv = Instance.new("Part")
	tv.Name = "TV_" .. roomNumber
	tv.Anchored = true
	tv.Size = Vector3.new(3, 2, 0.3)
	local tvOffset = isRansacked and Vector3.new(0, 0, 0) or Vector3.new(0, 3, -roomDepth / 3)
	tv.Position = roomPos + Vector3.new(roomWidth / 4, 0, 0) + tvOffset
	tv.Color = COLORS.TV_BLACK
	tv.Material = Enum.Material.SmoothPlastic
	if isRansacked then
		tv.Position = roomPos + Vector3.new(roomWidth / 5, 0.15, -roomDepth / 4)
		tv.Rotation = Vector3.new(90, 25, 0)
	end
	tv.Parent = parent

	-- TV Stand
	local tvStand = Instance.new("Part")
	tvStand.Name = "TVStand_" .. roomNumber
	tvStand.Anchored = true
	tvStand.Size = Vector3.new(4, 2, 1.5)
	tvStand.Position = roomPos + Vector3.new(roomWidth / 4, 1, -roomDepth / 3)
	tvStand.Color = COLORS.WOOD_DARK
	tvStand.Material = Enum.Material.Wood
	tvStand.Parent = parent

	-- Bathroom area (minibar searchable)
	local minibar = createContainer(
		parent,
		roomPos + Vector3.new(roomWidth / 3, 1.5, roomDepth / 3 - 1),
		Vector3.new(2, 3, 1.5),
		"Minibar_" .. roomNumber,
		"Cabinet",
		COLORS.WOOD_BROWN
	)
	minibar:SetAttribute("FoodAmount", math.random(1, 3))
end

-- Create California roadside motel
local function createMotel(def: BuildingDef): Model
	local motel = Instance.new("Model")
	motel.Name = def.name

	-- Dimensions
	local roomWidth = 12
	local roomDepth = 14
	local roomHeight = 10
	local numMainRooms = 6
	local numSideRooms = 2
	local mainWingLength = numMainRooms * roomWidth
	local sideWingLength = numSideRooms * roomWidth
	local walkwayWidth = 4
	local wallThickness = 0.8

	-- Determine damage effects
	local isBrokenWindows = def.damageLevel == "MODERATE" or def.damageLevel == "SEVERE"
	local hasCracks = def.damageLevel ~= "INTACT"
	local hasDebris = def.damageLevel == "SEVERE"
	local numCollapsedRooms = def.damageLevel == "SEVERE" and 2 or (def.damageLevel == "MODERATE" and 1 or 0)

	-- Randomly determine which rooms are collapsed/ransacked
	local random = Random.new(def.position.X + def.position.Z)
	local collapsedRooms: { [number]: boolean } = {}
	local ransackedRooms: { [number]: boolean } = {}
	local totalRooms = numMainRooms + numSideRooms

	for _ = 1, numCollapsedRooms do
		local room = random:NextInteger(1, totalRooms)
		collapsedRooms[room] = true
	end
	for i = 1, totalRooms do
		if not collapsedRooms[i] and random:NextNumber() < 0.4 then
			ransackedRooms[i] = true
		end
	end

	-- ==========================================
	-- MAIN FOUNDATION
	-- ==========================================

	local mainFoundation = Instance.new("Part")
	mainFoundation.Name = "MainFoundation"
	mainFoundation.Anchored = true
	mainFoundation.Size = Vector3.new(mainWingLength, 0.5, roomDepth + walkwayWidth)
	mainFoundation.Position = Vector3.new(0, 0.25, 0)
	mainFoundation.Color = COLORS.STORE_CONCRETE
	mainFoundation.Material = Enum.Material.Concrete
	mainFoundation.Parent = motel

	-- Side wing foundation (L-shape)
	local sideFoundation = Instance.new("Part")
	sideFoundation.Name = "SideFoundation"
	sideFoundation.Anchored = true
	sideFoundation.Size = Vector3.new(roomWidth + walkwayWidth, 0.5, sideWingLength + roomDepth)
	sideFoundation.Position = Vector3.new(-mainWingLength / 2 + roomWidth / 2, 0.25, roomDepth / 2 + sideWingLength / 2)
	sideFoundation.Color = COLORS.STORE_CONCRETE
	sideFoundation.Material = Enum.Material.Concrete
	sideFoundation.Parent = motel

	-- ==========================================
	-- MAIN WING ROOMS
	-- ==========================================

	for i = 1, numMainRooms do
		local roomX = -mainWingLength / 2 + (i - 0.5) * roomWidth
		local roomZ = walkwayWidth / 2

		-- Room back wall
		local backWall = Instance.new("Part")
		backWall.Name = "BackWall_" .. i
		backWall.Anchored = true
		backWall.Size = Vector3.new(roomWidth, roomHeight, wallThickness)
		backWall.Position = Vector3.new(roomX, roomHeight / 2, roomDepth / 2)
		backWall.Color = COLORS.MOTEL_STUCCO
		backWall.Material = Enum.Material.Concrete
		backWall.Parent = motel

		-- Room side walls (only between rooms)
		if i < numMainRooms then
			local dividerWall = Instance.new("Part")
			dividerWall.Name = "DividerWall_" .. i
			dividerWall.Anchored = true
			dividerWall.Size = Vector3.new(wallThickness, roomHeight, roomDepth)
			dividerWall.Position = Vector3.new(roomX + roomWidth / 2, roomHeight / 2, roomZ + roomDepth / 4)
			dividerWall.Color = COLORS.MOTEL_STUCCO
			dividerWall.Material = Enum.Material.Concrete
			dividerWall.Parent = motel
		end

		-- Room door
		local doorPos = Vector3.new(roomX, 4, -walkwayWidth / 2 + 0.5)
		local door = createDoor(motel, doorPos, Vector3.new(3.5, 8, wallThickness), "RoomDoor_" .. i)
		door.Color = COLORS.MOTEL_DOOR

		-- Room number sign
		local roomSign = Instance.new("Part")
		roomSign.Name = "RoomSign_" .. i
		roomSign.Anchored = true
		roomSign.Size = Vector3.new(1.5, 0.8, 0.1)
		roomSign.Position = Vector3.new(roomX + 2, 7, -walkwayWidth / 2 + 0.3)
		roomSign.Color = COLORS.WHITE_TRIM
		roomSign.Material = Enum.Material.SmoothPlastic
		roomSign.Parent = motel

		-- Room window
		local window = Instance.new("Part")
		window.Name = "RoomWindow_" .. i
		window.Anchored = true
		window.CanCollide = false
		window.Size = Vector3.new(4, 3, 0.2)
		window.Position = Vector3.new(roomX - 2.5, 5, -walkwayWidth / 2 + 0.5)
		window.Transparency = isBrokenWindows and 0.9 or 0.3
		window.Color = isBrokenWindows and COLORS.CRACK_DARK or COLORS.STORE_GLASS
		window.Material = Enum.Material.Glass
		window.Parent = motel

		if isBrokenWindows then
			CollectionService:AddTag(window, "BrokenWindow")
		end

		-- Create room interior
		local roomPos = Vector3.new(roomX, 0.5, roomZ + roomDepth / 4)
		createMotelRoom(
			motel,
			roomPos,
			roomWidth - 1,
			roomDepth - 1,
			roomHeight,
			i,
			collapsedRooms[i] or false,
			ransackedRooms[i] or false
		)
	end

	-- ==========================================
	-- SIDE WING ROOMS (L-shape extension)
	-- ==========================================

	for i = 1, numSideRooms do
		local roomIndex = numMainRooms + i
		local roomX = -mainWingLength / 2 + walkwayWidth / 2
		local roomZ = roomDepth + (i - 0.5) * roomWidth

		-- Room back wall (faces away from parking)
		local backWall = Instance.new("Part")
		backWall.Name = "SideBackWall_" .. i
		backWall.Anchored = true
		backWall.Size = Vector3.new(wallThickness, roomHeight, roomWidth)
		backWall.Position = Vector3.new(-mainWingLength / 2 + roomDepth / 2 + walkwayWidth, roomHeight / 2, roomZ)
		backWall.Color = COLORS.MOTEL_STUCCO
		backWall.Material = Enum.Material.Concrete
		backWall.Parent = motel

		-- Side wing door
		local doorPos = Vector3.new(-mainWingLength / 2 - walkwayWidth / 2 + 0.5, 4, roomZ)
		local door = createDoor(motel, doorPos, Vector3.new(wallThickness, 8, 3.5), "SideRoomDoor_" .. i)
		door.Color = COLORS.MOTEL_DOOR
		door.CFrame = CFrame.new(doorPos) * CFrame.Angles(0, math.rad(90), 0)

		-- Create room interior
		local roomPos = Vector3.new(roomX + roomDepth / 4, 0.5, roomZ)
		createMotelRoom(
			motel,
			roomPos,
			roomDepth - 1,
			roomWidth - 1,
			roomHeight,
			roomIndex,
			collapsedRooms[roomIndex] or false,
			ransackedRooms[roomIndex] or false
		)
	end

	-- ==========================================
	-- ROOF
	-- ==========================================

	local mainRoof = Instance.new("Part")
	mainRoof.Name = "MainRoof"
	mainRoof.Anchored = true
	mainRoof.Size = Vector3.new(mainWingLength + 2, 1, roomDepth + walkwayWidth + 2)
	mainRoof.Position = Vector3.new(0, roomHeight + 0.5, 0)
	mainRoof.Color = COLORS.MOTEL_ROOF
	mainRoof.Material = Enum.Material.Asphalt
	mainRoof.Parent = motel

	local sideRoof = Instance.new("Part")
	sideRoof.Name = "SideRoof"
	sideRoof.Anchored = true
	sideRoof.Size = Vector3.new(roomWidth + walkwayWidth + 2, 1, sideWingLength + 2)
	sideRoof.Position =
		Vector3.new(-mainWingLength / 2 + roomWidth / 2, roomHeight + 0.5, roomDepth / 2 + sideWingLength / 2)
	sideRoof.Color = COLORS.MOTEL_ROOF
	sideRoof.Material = Enum.Material.Asphalt
	sideRoof.Parent = motel

	-- ==========================================
	-- WALKWAY AND RAILINGS
	-- ==========================================

	-- Walkway overhang
	local overhang = Instance.new("Part")
	overhang.Name = "WalkwayOverhang"
	overhang.Anchored = true
	overhang.Size = Vector3.new(mainWingLength, 0.3, walkwayWidth + 1)
	overhang.Position = Vector3.new(0, roomHeight - 1, -walkwayWidth / 2 - 0.5)
	overhang.Color = COLORS.MOTEL_ROOF
	overhang.Material = Enum.Material.Asphalt
	overhang.Parent = motel

	-- Railing posts
	local numPosts = 8
	for i = 0, numPosts do
		local postX = -mainWingLength / 2 + 2 + i * ((mainWingLength - 4) / numPosts)
		local post = Instance.new("Part")
		post.Name = "RailingPost_" .. i
		post.Anchored = true
		post.Size = Vector3.new(0.3, 3.5, 0.3)
		post.Position = Vector3.new(postX, 1.75, -walkwayWidth - 0.5)
		post.Color = COLORS.RAILING_METAL
		post.Material = Enum.Material.Metal
		post.Parent = motel
	end

	-- Railing bar
	local railingBar = Instance.new("Part")
	railingBar.Name = "RailingBar"
	railingBar.Anchored = true
	railingBar.Size = Vector3.new(mainWingLength - 2, 0.2, 0.2)
	railingBar.Position = Vector3.new(0, 3.2, -walkwayWidth - 0.5)
	railingBar.Color = COLORS.RAILING_METAL
	railingBar.Material = Enum.Material.Metal
	railingBar.Parent = motel

	-- ==========================================
	-- NEON VACANCY SIGN
	-- ==========================================

	local signPole = Instance.new("Part")
	signPole.Name = "SignPole"
	signPole.Anchored = true
	signPole.Size = Vector3.new(1, 20, 1)
	signPole.Position = Vector3.new(mainWingLength / 2 + 10, 10, -5)
	signPole.Color = COLORS.RAILING_METAL
	signPole.Material = Enum.Material.Metal
	signPole.Parent = motel

	local signBoard = Instance.new("Part")
	signBoard.Name = "VacancySign"
	signBoard.Anchored = true
	signBoard.Size = Vector3.new(12, 6, 1)
	signBoard.Position = Vector3.new(mainWingLength / 2 + 10, 17, -5)
	signBoard.Color = Color3.fromRGB(40, 40, 45)
	signBoard.Material = Enum.Material.SmoothPlastic
	signBoard.Parent = motel

	-- Neon "VACANCY" text (simplified as glowing part)
	local neonText = Instance.new("Part")
	neonText.Name = "NeonVacancy"
	neonText.Anchored = true
	neonText.Size = Vector3.new(10, 2, 0.2)
	neonText.Position = Vector3.new(mainWingLength / 2 + 10, 17, -5.6)
	neonText.Color = COLORS.NEON_PINK
	neonText.Material = Enum.Material.Neon
	neonText.Parent = motel

	local neonLight = Instance.new("PointLight")
	neonLight.Brightness = 3
	neonLight.Range = 30
	neonLight.Color = COLORS.NEON_PINK
	neonLight.Parent = neonText

	-- Flickering effect for neon sign
	task.spawn(function()
		local flickerRandom = Random.new()
		while motel.Parent do
			if flickerRandom:NextNumber() < 0.15 then
				local originalBrightness = neonLight.Brightness
				neonLight.Brightness = 0
				neonText.Material = Enum.Material.SmoothPlastic
				task.wait(flickerRandom:NextNumber(0.05, 0.2))
				neonLight.Brightness = originalBrightness
				neonText.Material = Enum.Material.Neon
				if flickerRandom:NextNumber() < 0.4 then
					task.wait(flickerRandom:NextNumber(0.03, 0.1))
					neonLight.Brightness = 0
					neonText.Material = Enum.Material.SmoothPlastic
					task.wait(flickerRandom:NextNumber(0.05, 0.15))
					neonLight.Brightness = originalBrightness
					neonText.Material = Enum.Material.Neon
				end
			end
			task.wait(flickerRandom:NextNumber(0.3, 1.5))
		end
	end)

	-- ==========================================
	-- POOL AREA
	-- ==========================================

	local poolLength = 20
	local poolWidth = 10
	local poolDepth = 4
	local poolX = mainWingLength / 4
	local poolZ = -walkwayWidth - 15

	-- Pool walls (drained)
	local poolFloor = Instance.new("Part")
	poolFloor.Name = "PoolFloor"
	poolFloor.Anchored = true
	poolFloor.Size = Vector3.new(poolLength, 0.5, poolWidth)
	poolFloor.Position = Vector3.new(poolX, -poolDepth + 0.25, poolZ)
	poolFloor.Color = hasDebris and COLORS.POOL_EMPTY or COLORS.POOL_BLUE
	poolFloor.Material = Enum.Material.Concrete
	poolFloor.Parent = motel

	-- Pool sides
	for _, side in ipairs({
		{ Vector3.new(poolLength, poolDepth, 0.5), Vector3.new(poolX, -poolDepth / 2, poolZ - poolWidth / 2) },
		{ Vector3.new(poolLength, poolDepth, 0.5), Vector3.new(poolX, -poolDepth / 2, poolZ + poolWidth / 2) },
		{ Vector3.new(0.5, poolDepth, poolWidth), Vector3.new(poolX - poolLength / 2, -poolDepth / 2, poolZ) },
		{ Vector3.new(0.5, poolDepth, poolWidth), Vector3.new(poolX + poolLength / 2, -poolDepth / 2, poolZ) },
	}) do
		local poolWall = Instance.new("Part")
		poolWall.Name = "PoolWall"
		poolWall.Anchored = true
		poolWall.Size = side[1]
		poolWall.Position = side[2]
		poolWall.Color = COLORS.POOL_BLUE
		poolWall.Material = Enum.Material.Concrete
		poolWall.Parent = motel
	end

	-- Pool edge/deck
	local poolDeck = Instance.new("Part")
	poolDeck.Name = "PoolDeck"
	poolDeck.Anchored = true
	poolDeck.Size = Vector3.new(poolLength + 6, 0.3, poolWidth + 6)
	poolDeck.Position = Vector3.new(poolX, 0.15, poolZ)
	poolDeck.Color = COLORS.STORE_CONCRETE
	poolDeck.Material = Enum.Material.Concrete
	poolDeck.Parent = motel

	-- Pool debris (if damaged)
	if hasDebris then
		local debrisRandom = Random.new()
		for i = 1, 4 do
			local debris = Instance.new("Part")
			debris.Name = "PoolDebris_" .. i
			debris.Anchored = true
			debris.Size = Vector3.new(
				debrisRandom:NextNumber(1, 3),
				debrisRandom:NextNumber(0.5, 1.5),
				debrisRandom:NextNumber(1, 3)
			)
			debris.Position = Vector3.new(
				poolX + debrisRandom:NextNumber(-8, 8),
				-poolDepth + 1 + debris.Size.Y / 2,
				poolZ + debrisRandom:NextNumber(-3, 3)
			)
			debris.Color = COLORS.DEBRIS_GRAY
			debris.Material = Enum.Material.Rock
			debris.Parent = motel
			CollectionService:AddTag(debris, "Debris")
		end
	end

	-- ==========================================
	-- VENDING MACHINES
	-- ==========================================

	createVendingMachine(motel, Vector3.new(-mainWingLength / 2 + 2, 0.5, -walkwayWidth - 1), 180, "Snacks")
	createVendingMachine(motel, Vector3.new(-mainWingLength / 2 + 6, 0.5, -walkwayWidth - 1), 180, "Drinks")

	-- Ice machine (non-searchable, atmospheric)
	local iceMachine = Instance.new("Part")
	iceMachine.Name = "IceMachine"
	iceMachine.Anchored = true
	iceMachine.Size = Vector3.new(3, 4, 2.5)
	iceMachine.Position = Vector3.new(-mainWingLength / 2 + 10, 2, -walkwayWidth - 1)
	iceMachine.Color = COLORS.APPLIANCE_WHITE
	iceMachine.Material = Enum.Material.SmoothPlastic
	iceMachine.Parent = motel

	-- ==========================================
	-- DAMAGE EFFECTS
	-- ==========================================

	if hasCracks then
		-- Add cracks to main walls
		local crackPositions = {
			Vector3.new(mainWingLength / 4, roomHeight / 2, roomDepth / 2 + 0.5),
			Vector3.new(-mainWingLength / 3, roomHeight / 3, roomDepth / 2 + 0.5),
		}
		for i, pos in ipairs(crackPositions) do
			local crack = Instance.new("Part")
			crack.Name = "WallCrack_" .. i
			crack.Anchored = true
			crack.CanCollide = false
			crack.Size = Vector3.new(0.2, roomHeight * 0.4, 0.3)
			crack.Position = pos
			crack.Color = COLORS.CRACK_DARK
			crack.Material = Enum.Material.Slate
			crack.Transparency = 0.3
			crack.Rotation = Vector3.new(0, 0, random:NextNumber(-15, 15))
			crack.Parent = motel
			CollectionService:AddTag(crack, "DamageEffect")
		end
	end

	if hasDebris then
		-- Exterior debris
		for i = 1, 8 do
			local debris = Instance.new("Part")
			debris.Name = "ExteriorDebris_" .. i
			debris.Anchored = true
			debris.Size = Vector3.new(random:NextNumber(0.5, 2), random:NextNumber(0.3, 1), random:NextNumber(0.5, 2))
			debris.Position = Vector3.new(
				random:NextNumber(-mainWingLength / 2, mainWingLength / 2),
				debris.Size.Y / 2,
				random:NextNumber(-walkwayWidth - 8, -walkwayWidth - 2)
			)
			debris.Color = COLORS.DEBRIS_GRAY
			debris.Material = Enum.Material.Rock
			debris.Rotation =
				Vector3.new(random:NextNumber(-20, 20), random:NextNumber(0, 360), random:NextNumber(-20, 20))
			debris.Parent = motel
			CollectionService:AddTag(debris, "Debris")
		end
	end

	-- Set primary part
	motel.PrimaryPart = mainFoundation

	-- Tags and attributes
	CollectionService:AddTag(motel, "Building")
	CollectionService:AddTag(motel, "Motel")
	CollectionService:AddTag(motel, "Enterable")
	motel:SetAttribute("BuildingType", "Motel")
	motel:SetAttribute("DamageLevel", def.damageLevel)
	motel:SetAttribute("NumRooms", totalRooms)

	return motel
end

-- ==========================================
-- PUBLIC API
-- ==========================================

function BuildingService:CreateBuilding(def: BuildingDef): Model?
	-- Get terrain height
	local x, z = def.position.X, def.position.Z
	local y = Heightmap:GetHeight(x, z)

	-- Flatten area for building (larger radius for bigger buildings)
	local flattenRadius = 25
	if def.buildingType == "Motel" then
		flattenRadius = 50 -- Motels are larger
	elseif def.buildingType == "ConvenienceStore" then
		flattenRadius = 35 -- Convenience stores with gas pumps
	end

	if Heightmap.FlattenArea then
		y = Heightmap:FlattenArea(x, z, flattenRadius)
	end

	-- Create building based on type
	local building: Model?
	if def.buildingType == "RanchHouse" then
		building = createRanchHouse(def)
	elseif def.buildingType == "ConvenienceStore" then
		building = createConvenienceStore(def)
	elseif def.buildingType == "Motel" then
		building = createMotel(def)
	else
		warn("[BuildingService] Unknown building type: " .. def.buildingType)
		return nil
	end

	if building and building.PrimaryPart then
		-- Position building
		local cframe = CFrame.new(x, y + 0.5, z) * CFrame.Angles(0, math.rad(def.rotation), 0)
		building:PivotTo(cframe)

		-- Parent to folder
		building.Parent = buildingsFolder
		buildings[def.name] = building

		print(
			string.format(
				"[BuildingService] Created %s at (%.0f, %.0f, %.0f) - %s damage",
				def.name,
				x,
				y,
				z,
				def.damageLevel
			)
		)
	end

	return building
end

function BuildingService:GetBuildings(): { Model }
	local result = {}
	for _, building in pairs(buildings) do
		table.insert(result, building)
	end
	return result
end

function BuildingService:GetBuildingsByType(buildingType: string): { Model }
	local result = {}
	for _, building in pairs(buildings) do
		if building:GetAttribute("BuildingType") == buildingType then
			table.insert(result, building)
		end
	end
	return result
end

function BuildingService:GetBuilding(name: string): Model?
	return buildings[name]
end

function BuildingService:Initialize()
	print("[BuildingService] Initializing...")

	-- Create buildings folder
	buildingsFolder = Instance.new("Folder")
	buildingsFolder.Name = "Buildings"
	buildingsFolder.Parent = Workspace

	-- Spawn all buildings
	local spawned = 0
	for _, def in ipairs(BUILDING_PLACEMENTS) do
		local building = self:CreateBuilding(def)
		if building then
			spawned += 1
		end
	end

	print(string.format("[BuildingService] Initialized with %d buildings", spawned))

	-- Print building summary
	local byType: { [string]: number } = {}
	local byDamage: { [string]: number } = {}
	for _, building in pairs(buildings) do
		local bType = building:GetAttribute("BuildingType") or "Unknown"
		local damage = building:GetAttribute("DamageLevel") or "Unknown"
		byType[bType] = (byType[bType] or 0) + 1
		byDamage[damage] = (byDamage[damage] or 0) + 1
	end

	print("[BuildingService] Building types:")
	for bType, count in pairs(byType) do
		print(string.format("  - %s: %d", bType, count))
	end

	print("[BuildingService] Damage levels:")
	for damage, count in pairs(byDamage) do
		print(string.format("  - %s: %d", damage, count))
	end
end

return BuildingService
