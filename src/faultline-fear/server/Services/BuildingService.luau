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

-- ==========================================
-- PUBLIC API
-- ==========================================

function BuildingService:CreateBuilding(def: BuildingDef): Model?
	-- Get terrain height
	local x, z = def.position.X, def.position.Z
	local y = Heightmap:GetHeight(x, z)

	-- Flatten area for building
	if Heightmap.FlattenArea then
		y = Heightmap:FlattenArea(x, z, 25)
	end

	-- Create building based on type
	local building: Model?
	if def.buildingType == "RanchHouse" then
		building = createRanchHouse(def)
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
