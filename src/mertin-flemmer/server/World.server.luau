--!strict
-- World generation for Mertin-Flemmer
-- Creates the mysterious forest/building environment

local Workspace = game:GetService("Workspace")

-- Configuration
local WORLD_SIZE = 3500 -- Matches AlpineTerrain size - BIG EPIC WORLD
local RunService = game:GetService("RunService")

-- BIOME DEFINITIONS
local BIOMES = {
	FOREST = {
		name = "The Whispering Woods",
		groundColor = Color3.fromRGB(30, 45, 25),
		material = Enum.Material.Grass,
		treeColor = Color3.fromRGB(25, 60, 25),
		fogColor = Color3.fromRGB(100, 120, 100),
	},
	SNOW = {
		name = "The Frozen Wastes",
		groundColor = Color3.fromRGB(240, 245, 255),
		material = Enum.Material.Snow,
		treeColor = Color3.fromRGB(200, 210, 220),
		fogColor = Color3.fromRGB(200, 210, 230),
	},
	DESERT = {
		name = "The Scorched Sands",
		groundColor = Color3.fromRGB(210, 180, 140),
		material = Enum.Material.Sand,
		treeColor = Color3.fromRGB(80, 60, 40),
		fogColor = Color3.fromRGB(220, 200, 160),
	},
	VOLCANIC = {
		name = "The Ashen Peaks",
		groundColor = Color3.fromRGB(40, 35, 35),
		material = Enum.Material.Rock,
		treeColor = Color3.fromRGB(30, 25, 25),
		fogColor = Color3.fromRGB(80, 60, 50),
	},
	SWAMP = {
		name = "The Murky Depths",
		groundColor = Color3.fromRGB(45, 50, 35),
		material = Enum.Material.Mud,
		treeColor = Color3.fromRGB(40, 55, 30),
		fogColor = Color3.fromRGB(80, 100, 70),
	},
	CRYSTAL = {
		name = "The Shimmering Caverns",
		groundColor = Color3.fromRGB(60, 50, 80),
		material = Enum.Material.Slate,
		treeColor = Color3.fromRGB(150, 100, 200),
		fogColor = Color3.fromRGB(100, 80, 140),
	},
}

-- Biome regions (each biome is a wedge from center)
local function getBiome(x: number, z: number): typeof(BIOMES.FOREST)
	local distance = math.sqrt(x * x + z * z)
	local angle = math.atan2(z, x)

	-- Inner area is always forest
	if distance < 500 then
		return BIOMES.FOREST
	end

	-- Outer areas are different biomes based on direction
	if angle >= -math.pi / 3 and angle < math.pi / 3 then
		return BIOMES.SNOW
	elseif angle >= math.pi / 3 and angle < 2 * math.pi / 3 then
		return BIOMES.DESERT
	elseif angle >= 2 * math.pi / 3 or angle < -2 * math.pi / 3 then
		return BIOMES.VOLCANIC
	elseif angle >= -2 * math.pi / 3 and angle < -math.pi / 3 then
		return BIOMES.SWAMP
	else
		return BIOMES.CRYSTAL
	end
end

-- Create varied terrain with mountains, valleys, rivers
-- ==========================================
-- GROUND: Minimal safety floor only
-- AlpineTerrain.server.luau creates the actual voxel terrain
-- This is just a kill-floor to catch players who fall through
-- ==========================================
local function createGround()
	print("[World] Creating safety floor (AlpineTerrain handles actual terrain)...")

	-- Safety floor WAY below terrain - catches players who fall through
	local safetyFloor = Instance.new("Part")
	safetyFloor.Name = "SafetyFloor"
	safetyFloor.Size = Vector3.new(WORLD_SIZE * 3, 10, WORLD_SIZE * 3)
	safetyFloor.Position = Vector3.new(0, -100, 0)  -- 100 studs below ground
	safetyFloor.Color = Color3.fromRGB(50, 50, 50)
	safetyFloor.Material = Enum.Material.SmoothPlastic
	safetyFloor.Anchored = true
	safetyFloor.CanCollide = true
	safetyFloor.Transparency = 1  -- Invisible
	safetyFloor.Parent = Workspace

	print("[World] Safety floor created at Y=-100")
end

-- ==========================================
-- TERRAIN HEIGHT: Raycast to find actual voxel terrain surface
-- This is the ONLY way to get accurate terrain height after generation
-- ==========================================
local function getActualTerrainHeight(x: number, z: number): number
	local rayOrigin = Vector3.new(x, 500, z)
	local rayDirection = Vector3.new(0, -600, 0)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { Workspace.Terrain }

	local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return result.Position.Y
	end

	-- Fallback to calculated height if raycast fails (terrain not generated yet)
	print("[World] WARNING: Raycast failed at", x, z, "- using calculated height")
	return Shared.getTerrainHeight(x, z)
end

-- Create a tree (biome-aware)
local function createTree(position: Vector3)
	local biome = getBiome(position.X, position.Z)
	local tree = Instance.new("Model")
	tree.Name = "Tree"

	local trunkHeight = 15 + math.random() * 10

	-- Different tree types per biome
	if biome == BIOMES.SNOW then
		-- Pine tree
		trunkHeight = 20 + math.random() * 15
		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		trunk.Size = Vector3.new(1.5, trunkHeight, 1.5)
		trunk.Position = position + Vector3.new(0, trunkHeight / 2, 0)
		trunk.Color = Color3.fromRGB(80, 60, 50)
		trunk.Material = Enum.Material.Wood
		trunk.Anchored = true
		trunk.Parent = tree

		-- Layered cone foliage
		for layer = 1, 4 do
			local cone = Instance.new("Part")
			cone.Name = "PineLayer_" .. layer
			local layerSize = 12 - layer * 2
			cone.Size = Vector3.new(layerSize, 6, layerSize)
			cone.Position = trunk.Position + Vector3.new(0, trunkHeight / 3 + layer * 4, 0)
			cone.Color = Color3.fromRGB(30, 60, 40)
			cone.Material = Enum.Material.Grass
			cone.Anchored = true
			cone.Parent = tree

			-- Snow on branches
			local snow = Instance.new("Part")
			snow.Name = "Snow_" .. layer
			snow.Size = Vector3.new(layerSize * 0.8, 1, layerSize * 0.8)
			snow.Position = cone.Position + Vector3.new(0, 3, 0)
			snow.Color = Color3.fromRGB(255, 255, 255)
			snow.Material = Enum.Material.Snow
			snow.Anchored = true
			snow.CanCollide = false
			snow.Parent = tree
		end
	elseif biome == BIOMES.DESERT then
		-- Cactus
		local trunk = Instance.new("Part")
		trunk.Name = "Cactus"
		trunk.Size = Vector3.new(3, 12 + math.random() * 8, 3)
		trunk.Position = position + Vector3.new(0, trunk.Size.Y / 2, 0)
		trunk.Color = Color3.fromRGB(80, 120, 60)
		trunk.Material = Enum.Material.SmoothPlastic
		trunk.Anchored = true
		trunk.Parent = tree

		-- Arms
		for arm = 1, 2 do
			local armPart = Instance.new("Part")
			armPart.Name = "Arm_" .. arm
			armPart.Size = Vector3.new(2, 6, 2)
			armPart.Position = trunk.Position + Vector3.new((arm == 1 and 2 or -2), 2, 0)
			armPart.Color = Color3.fromRGB(80, 120, 60)
			armPart.Material = Enum.Material.SmoothPlastic
			armPart.Anchored = true
			armPart.Parent = tree
		end
	elseif biome == BIOMES.VOLCANIC then
		-- Dead/charred tree
		local trunk = Instance.new("Part")
		trunk.Name = "DeadTrunk"
		trunk.Size = Vector3.new(2, 10 + math.random() * 5, 2)
		trunk.Position = position + Vector3.new(0, trunk.Size.Y / 2, 0)
		trunk.Color = Color3.fromRGB(30, 25, 25)
		trunk.Material = Enum.Material.Slate
		trunk.Anchored = true
		trunk.Parent = tree

		-- Dead branches
		for branch = 1, 3 do
			local branchPart = Instance.new("Part")
			branchPart.Name = "Branch_" .. branch
			branchPart.Size = Vector3.new(0.5, 4, 0.5)
			local angle = (branch / 3) * math.pi * 2
			branchPart.CFrame = CFrame.new(trunk.Position + Vector3.new(math.cos(angle) * 1.5, trunk.Size.Y / 3, math.sin(angle) * 1.5))
				* CFrame.Angles(math.rad(45), angle, 0)
			branchPart.Color = Color3.fromRGB(25, 20, 20)
			branchPart.Material = Enum.Material.Slate
			branchPart.Anchored = true
			branchPart.Parent = tree
		end
	elseif biome == BIOMES.SWAMP then
		-- Willow-like tree with hanging moss
		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		trunk.Size = Vector3.new(3, 18, 3)
		trunk.Position = position + Vector3.new(0, 9, 0)
		trunk.Color = Color3.fromRGB(50, 45, 35)
		trunk.Material = Enum.Material.Wood
		trunk.Anchored = true
		trunk.Parent = tree

		-- Drooping foliage
		for droop = 1, 6 do
			local droopPart = Instance.new("Part")
			droopPart.Name = "Moss_" .. droop
			droopPart.Size = Vector3.new(1, 10, 1)
			local angle = (droop / 6) * math.pi * 2
			droopPart.Position = trunk.Position + Vector3.new(math.cos(angle) * 4, 5, math.sin(angle) * 4)
			droopPart.Color = Color3.fromRGB(60, 80, 50)
			droopPart.Material = Enum.Material.Grass
			droopPart.Anchored = true
			droopPart.CanCollide = false
			droopPart.Parent = tree
		end
	elseif biome == BIOMES.CRYSTAL then
		-- Crystal formations
		local crystal = Instance.new("Part")
		crystal.Name = "Crystal"
		crystal.Size = Vector3.new(3, 15 + math.random() * 10, 3)
		crystal.Position = position + Vector3.new(0, crystal.Size.Y / 2, 0)
		crystal.Color = Color3.fromRGB(150 + math.random(50), 100 + math.random(50), 200)
		crystal.Material = Enum.Material.Glass
		crystal.Transparency = 0.3
		crystal.Anchored = true
		crystal.Parent = tree

		local glow = Instance.new("PointLight")
		glow.Color = crystal.Color
		glow.Brightness = 0.5
		glow.Range = 15
		glow.Parent = crystal
	else
		-- Default forest tree
		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		trunk.Size = Vector3.new(2, trunkHeight, 2)
		trunk.Position = position + Vector3.new(0, trunkHeight / 2, 0)
		trunk.Color = Color3.fromRGB(60, 40, 30)
		trunk.Material = Enum.Material.Wood
		trunk.Anchored = true
		trunk.Parent = tree

		for j = 1, 3 do
			local leaves = Instance.new("Part")
			leaves.Name = "Leaves_" .. j
			leaves.Shape = Enum.PartType.Ball
			local size = 8 + math.random() * 6
			leaves.Size = Vector3.new(size, size * 0.8, size)
			leaves.Position = trunk.Position + Vector3.new(
				(math.random() - 0.5) * 4,
				trunkHeight / 2 + math.random() * 3,
				(math.random() - 0.5) * 4
			)
			leaves.Color = Color3.fromRGB(20 + math.random(20), 50 + math.random(30), 20 + math.random(20))
			leaves.Material = Enum.Material.Grass
			leaves.Anchored = true
			leaves.CanCollide = false
			leaves.Parent = tree
		end
	end

	tree.Parent = Workspace
	return tree
end

-- Create abandoned building
local function createBuilding(position: Vector3)
	local building = Instance.new("Model")
	building.Name = "AbandonedBuilding"

	local width = 20 + math.random() * 15
	local depth = 15 + math.random() * 10
	local height = 10 + math.random() * 8

	-- Floor
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(width, 1, depth)
	floor.Position = position + Vector3.new(0, 0.5, 0)
	floor.Color = Color3.fromRGB(80, 80, 70)
	floor.Material = Enum.Material.Concrete
	floor.Anchored = true
	floor.Parent = building

	-- Walls (with gaps for doors/windows)
	local wallConfigs = {
		{ size = Vector3.new(width, height, 1), offset = Vector3.new(0, height/2, depth/2) },
		{ size = Vector3.new(width, height, 1), offset = Vector3.new(0, height/2, -depth/2) },
		{ size = Vector3.new(1, height, depth), offset = Vector3.new(width/2, height/2, 0) },
		{ size = Vector3.new(1, height, depth * 0.4), offset = Vector3.new(-width/2, height/2, depth * 0.3) },
		{ size = Vector3.new(1, height, depth * 0.4), offset = Vector3.new(-width/2, height/2, -depth * 0.3) },
	}

	for i, config in wallConfigs do
		local wall = Instance.new("Part")
		wall.Name = "Wall_" .. i
		wall.Size = config.size
		wall.Position = position + config.offset
		wall.Color = Color3.fromRGB(70, 65, 60)
		wall.Material = Enum.Material.Concrete
		wall.Anchored = true
		wall.Parent = building
	end

	-- Roof (partially destroyed)
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = Vector3.new(width * 0.7, 1, depth)
	roof.Position = position + Vector3.new(width * 0.15, height + 0.5, 0)
	roof.Color = Color3.fromRGB(50, 45, 40)
	roof.Material = Enum.Material.Slate
	roof.Anchored = true
	roof.Parent = building

	-- No SpawnLocation here - players spawn at main cabin only

	building.Parent = Workspace
	return building
end

-- Create the 7.5 floor office building (Being John Malkovich style)
-- MASSIVE 60 story skyscraper - visible from EVERYWHERE!
local function createOfficeBuilding75(position: Vector3)
	local Players = game:GetService("Players")
	local building = Instance.new("Model")
	building.Name = "MertinFlemmerBuilding"

	local buildingWidth = 100 -- WIDER
	local buildingDepth = 60 -- DEEPER
	local floorHeight = 14 -- Normal floor height
	local totalFloors = 60 -- MASSIVE 60 story skyscraper!
	local floor75Height = 8 -- Low ceiling but walkable (Being John Malkovich style)
	local lobbyHeight = 25 -- Even grander lobby

	-- Calculate positions
	local floor7Top = 7 * floorHeight
	local floor75Bottom = floor7Top
	local floor75Top = floor75Bottom + floor75Height
	local totalHeight = totalFloors * floorHeight

	-- ★★★ CLEAR TERRAIN AROUND BUILDING ★★★
	-- This ensures no rocks block the entrance or elevator button!
	local Terrain = Workspace.Terrain
	local clearRadius = buildingWidth / 2 + 30 -- Clear area around building
	local clearHeight = 50 -- Clear up to lobby height

	-- Clear the area around the building entrance and elevator
	for dx = -clearRadius, clearRadius, 10 do
		for dz = -clearRadius, clearRadius, 10 do
			local clearPos = position + Vector3.new(dx, clearHeight / 2, dz)
			-- Use FillBlock with Air to clear terrain
			Terrain:FillBlock(
				CFrame.new(clearPos),
				Vector3.new(12, clearHeight, 12),
				Enum.Material.Air
			)
		end
	end
	print("[World] Cleared terrain around Mertin-Flemmer building for accessibility")

	-- EXTERIOR WALLS (not solid - just walls)
	local wallThickness = 2

	-- Front wall (with entrance cutout)
	local frontWallLeft = Instance.new("Part")
	frontWallLeft.Name = "FrontWallLeft"
	frontWallLeft.Size = Vector3.new((buildingWidth - 12) / 2, totalHeight, wallThickness)
	frontWallLeft.Position = position + Vector3.new(-buildingWidth / 4 - 3, totalHeight / 2, buildingDepth / 2)
	frontWallLeft.Color = Color3.fromRGB(140, 135, 125)
	frontWallLeft.Material = Enum.Material.Concrete
	frontWallLeft.Anchored = true
	frontWallLeft.Parent = building

	local frontWallRight = frontWallLeft:Clone()
	frontWallRight.Name = "FrontWallRight"
	frontWallRight.Position = position + Vector3.new(buildingWidth / 4 + 3, totalHeight / 2, buildingDepth / 2)
	frontWallRight.Parent = building

	-- Front wall above entrance
	local frontWallTop = Instance.new("Part")
	frontWallTop.Name = "FrontWallTop"
	frontWallTop.Size = Vector3.new(12, totalHeight - lobbyHeight, wallThickness)
	frontWallTop.Position = position + Vector3.new(0, lobbyHeight + (totalHeight - lobbyHeight) / 2, buildingDepth / 2)
	frontWallTop.Color = Color3.fromRGB(140, 135, 125)
	frontWallTop.Material = Enum.Material.Concrete
	frontWallTop.Anchored = true
	frontWallTop.Parent = building

	-- Back wall
	local backWall = Instance.new("Part")
	backWall.Name = "BackWall"
	backWall.Size = Vector3.new(buildingWidth, totalHeight, wallThickness)
	backWall.Position = position + Vector3.new(0, totalHeight / 2, -buildingDepth / 2)
	backWall.Color = Color3.fromRGB(140, 135, 125)
	backWall.Material = Enum.Material.Concrete
	backWall.Anchored = true
	backWall.Parent = building

	-- Side walls
	local leftWall = Instance.new("Part")
	leftWall.Name = "LeftWall"
	leftWall.Size = Vector3.new(wallThickness, totalHeight, buildingDepth)
	leftWall.Position = position + Vector3.new(-buildingWidth / 2, totalHeight / 2, 0)
	leftWall.Color = Color3.fromRGB(140, 135, 125)
	leftWall.Material = Enum.Material.Concrete
	leftWall.Anchored = true
	leftWall.Parent = building

	local rightWall = leftWall:Clone()
	rightWall.Name = "RightWall"
	rightWall.Position = position + Vector3.new(buildingWidth / 2, totalHeight / 2, 0)
	rightWall.Parent = building

	-- Roof
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = Vector3.new(buildingWidth, 2, buildingDepth)
	roof.Position = position + Vector3.new(0, totalHeight + 1, 0)
	roof.Color = Color3.fromRGB(80, 80, 85)
	roof.Material = Enum.Material.Concrete
	roof.Anchored = true
	roof.Parent = building

	-- Windows on exterior
	for floor = 1, totalFloors do
		for w = 1, 8 do
			local windowSize = Vector3.new(6, 10, 0.3)
			local windowX = (w - 4.5) * 9

			-- Front windows
			local window = Instance.new("Part")
			window.Name = "Window_F_" .. floor .. "_" .. w
			window.Size = windowSize
			local windowY = (floor - 0.5) * floorHeight
			window.Position = position + Vector3.new(windowX, windowY, buildingDepth / 2 + 1)
			window.Color = Color3.fromRGB(30, 50, 70)
			window.Material = Enum.Material.Glass
			window.Transparency = 0.4
			window.Anchored = true
			window.CanCollide = false
			window.Parent = building

			-- Back windows
			local windowBack = window:Clone()
			windowBack.Name = "Window_B_" .. floor .. "_" .. w
			windowBack.Position = position + Vector3.new(windowX, windowY, -buildingDepth / 2 - 1)
			windowBack.Parent = building
		end
	end

	-- GRAND LOBBY (accessible!)
	local lobbyFloor = Instance.new("Part")
	lobbyFloor.Name = "LobbyFloor"
	lobbyFloor.Size = Vector3.new(buildingWidth - 4, 1, buildingDepth - 4)
	lobbyFloor.Position = position + Vector3.new(0, 0.5, 0)
	lobbyFloor.Color = Color3.fromRGB(180, 170, 150)
	lobbyFloor.Material = Enum.Material.Marble
	lobbyFloor.Anchored = true
	lobbyFloor.Parent = building

	-- ENTRANCE RAMP - gentle slope from outside to lobby floor
	local entranceRamp = Instance.new("Part")
	entranceRamp.Name = "EntranceRamp"
	entranceRamp.Size = Vector3.new(14, 1, 10)
	entranceRamp.CFrame = CFrame.new(position + Vector3.new(0, 0.25, buildingDepth / 2 + 5))
		* CFrame.Angles(math.rad(-5), 0, 0) -- Slight slope
	entranceRamp.Color = Color3.fromRGB(160, 150, 140)
	entranceRamp.Material = Enum.Material.Marble
	entranceRamp.Anchored = true
	entranceRamp.Parent = building

	-- Entrance plaza outside the door
	local entrancePlaza = Instance.new("Part")
	entrancePlaza.Name = "EntrancePlaza"
	entrancePlaza.Size = Vector3.new(30, 1, 20)
	entrancePlaza.Position = position + Vector3.new(0, 0.1, buildingDepth / 2 + 15)
	entrancePlaza.Color = Color3.fromRGB(140, 135, 130)
	entrancePlaza.Material = Enum.Material.Concrete
	entrancePlaza.Anchored = true
	entrancePlaza.Parent = building

	-- Entrance lights
	local entranceLight1 = Instance.new("Part")
	entranceLight1.Name = "EntranceLight1"
	entranceLight1.Size = Vector3.new(2, 2, 2)
	entranceLight1.Position = position + Vector3.new(-8, lobbyHeight - 2, buildingDepth / 2 + 1)
	entranceLight1.Color = Color3.fromRGB(255, 220, 150)
	entranceLight1.Material = Enum.Material.Neon
	entranceLight1.Anchored = true
	entranceLight1.Parent = building

	local light1 = Instance.new("PointLight")
	light1.Color = Color3.fromRGB(255, 240, 200)
	light1.Brightness = 2
	light1.Range = 30
	light1.Parent = entranceLight1

	local entranceLight2 = entranceLight1:Clone()
	entranceLight2.Name = "EntranceLight2"
	entranceLight2.Position = position + Vector3.new(8, lobbyHeight - 2, buildingDepth / 2 + 1)
	entranceLight2.Parent = building

	local lobbyCeiling = Instance.new("Part")
	lobbyCeiling.Name = "LobbyCeiling"
	lobbyCeiling.Size = Vector3.new(buildingWidth - 4, 1, buildingDepth - 4)
	lobbyCeiling.Position = position + Vector3.new(0, lobbyHeight - 0.5, 0)
	lobbyCeiling.Color = Color3.fromRGB(220, 215, 200)
	lobbyCeiling.Material = Enum.Material.SmoothPlastic
	lobbyCeiling.Anchored = true
	lobbyCeiling.Parent = building

	-- Lobby chandelier
	local chandelier = Instance.new("Part")
	chandelier.Name = "Chandelier"
	chandelier.Size = Vector3.new(8, 6, 8)
	chandelier.Position = position + Vector3.new(0, lobbyHeight - 4, 5)
	chandelier.Color = Color3.fromRGB(255, 220, 150)
	chandelier.Material = Enum.Material.Glass
	chandelier.Transparency = 0.3
	chandelier.Anchored = true
	chandelier.CanCollide = false
	chandelier.Parent = building

	local chandelierLight = Instance.new("PointLight")
	chandelierLight.Color = Color3.fromRGB(255, 240, 200)
	chandelierLight.Brightness = 2
	chandelierLight.Range = 40
	chandelierLight.Parent = chandelier

	-- MERTIN & FLEMMER LLP sign
	local lobbySign = Instance.new("Part")
	lobbySign.Name = "LobbySign"
	lobbySign.Size = Vector3.new(30, 5, 1)
	lobbySign.Position = position + Vector3.new(0, 14, -buildingDepth / 2 + 3)
	lobbySign.Color = Color3.fromRGB(50, 40, 30)
	lobbySign.Material = Enum.Material.Wood
	lobbySign.Anchored = true
	lobbySign.Parent = building

	-- Sign text on BOTH sides
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local lobbyGui = Instance.new("SurfaceGui")
		lobbyGui.Face = face
		lobbyGui.Parent = lobbySign

		local lobbyText = Instance.new("TextLabel")
		lobbyText.Size = UDim2.new(1, 0, 1, 0)
		lobbyText.BackgroundTransparency = 1
		lobbyText.Text = "MERTIN & FLEMMER LLP"
		lobbyText.TextColor3 = Color3.fromRGB(220, 200, 160)
		lobbyText.Font = Enum.Font.Antique
		lobbyText.TextScaled = true
		lobbyText.Parent = lobbyGui
	end

	-- Reception desk
	local reception = Instance.new("Part")
	reception.Name = "ReceptionDesk"
	reception.Size = Vector3.new(12, 4, 4)
	reception.Position = position + Vector3.new(0, 2, -10)
	reception.Color = Color3.fromRGB(80, 60, 40)
	reception.Material = Enum.Material.Wood
	reception.Anchored = true
	reception.Parent = building

	-- ELEVATOR AREA
	local elevatorWidth = 8
	local elevatorDepth = 8

	-- Elevator doors in lobby (teleporter!)
	local elevatorDoor = Instance.new("Part")
	elevatorDoor.Name = "ElevatorDoor"
	elevatorDoor.Size = Vector3.new(6, 10, 1)
	elevatorDoor.Position = position + Vector3.new(-25, 5, -buildingDepth / 2 + 5)
	elevatorDoor.Color = Color3.fromRGB(180, 175, 165)
	elevatorDoor.Material = Enum.Material.Metal
	elevatorDoor.Anchored = true
	elevatorDoor.Parent = building

	-- Elevator frame
	local elevatorFrame = Instance.new("Part")
	elevatorFrame.Name = "ElevatorFrame"
	elevatorFrame.Size = Vector3.new(8, 12, 2)
	elevatorFrame.Position = position + Vector3.new(-25, 6, -buildingDepth / 2 + 4)
	elevatorFrame.Color = Color3.fromRGB(100, 95, 85)
	elevatorFrame.Material = Enum.Material.Metal
	elevatorFrame.Anchored = true
	elevatorFrame.Parent = building

	-- Elevator button panel - text on ALL sides
	local buttonPanel = Instance.new("Part")
	buttonPanel.Name = "ElevatorButton"
	buttonPanel.Size = Vector3.new(1.5, 3, 0.5)
	buttonPanel.Position = position + Vector3.new(-20, 5, -buildingDepth / 2 + 5)
	buttonPanel.Color = Color3.fromRGB(60, 60, 65)
	buttonPanel.Material = Enum.Material.Metal
	buttonPanel.Anchored = true
	buttonPanel.Parent = building

	-- Text on ALL faces of the button panel
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		local buttonGui = Instance.new("SurfaceGui")
		buttonGui.Face = face
		buttonGui.Parent = buttonPanel

		local buttonText = Instance.new("TextLabel")
		buttonText.Size = UDim2.new(1, 0, 1, 0)
		buttonText.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
		buttonText.Text = "7½\n[TOUCH]"
		buttonText.TextColor3 = Color3.fromRGB(255, 200, 100)
		buttonText.Font = Enum.Font.Code
		buttonText.TextScaled = true
		buttonText.Parent = buttonGui
	end

	-- FLOOR 7.5 (the weird floor with low ceilings!)
	local floor75Floor = Instance.new("Part")
	floor75Floor.Name = "Floor75_Floor"
	floor75Floor.Size = Vector3.new(buildingWidth - 4, 1, buildingDepth - 4)
	floor75Floor.Position = position + Vector3.new(0, floor75Bottom + 0.5, 0)
	floor75Floor.Color = Color3.fromRGB(120, 100, 70)
	floor75Floor.Material = Enum.Material.Wood
	floor75Floor.Anchored = true
	floor75Floor.Parent = building

	local floor75Ceiling = Instance.new("Part")
	floor75Ceiling.Name = "Floor75_Ceiling"
	floor75Ceiling.Size = Vector3.new(buildingWidth - 4, 1, buildingDepth - 4)
	floor75Ceiling.Position = position + Vector3.new(0, floor75Top - 0.5, 0)
	floor75Ceiling.Color = Color3.fromRGB(240, 235, 220)
	floor75Ceiling.Material = Enum.Material.SmoothPlastic
	floor75Ceiling.Anchored = true
	floor75Ceiling.Parent = building

	-- Floor 7.5 interior walls
	local interiorWidth = buildingWidth - 8
	local interiorDepth = buildingDepth - 8

	-- Cubicle walls (creating maze-like office)
	for row = -2, 2 do
		for col = -2, 2 do
			if math.abs(row) + math.abs(col) > 0 then -- Skip center
				local cubicle = Instance.new("Part")
				cubicle.Name = "CubicleWall"
				cubicle.Size = Vector3.new(0.3, floor75Height - 2, 8)
				cubicle.Position = position + Vector3.new(col * 12, floor75Bottom + floor75Height / 2, row * 8)
				cubicle.Color = Color3.fromRGB(180, 175, 165)
				cubicle.Material = Enum.Material.Fabric
				cubicle.Anchored = true
				cubicle.Parent = building
			end
		end
	end

	-- Squished desks throughout floor 7.5
	for i = 1, 20 do
		local desk = Instance.new("Part")
		desk.Name = "Desk75_" .. i
		desk.Size = Vector3.new(3, 1.8, 2) -- Short!
		desk.Position = position + Vector3.new(
			(math.random() - 0.5) * interiorWidth * 0.8,
			floor75Bottom + 1.4,
			(math.random() - 0.5) * interiorDepth * 0.8
		)
		desk.Color = Color3.fromRGB(100, 80, 50)
		desk.Material = Enum.Material.Wood
		desk.Anchored = true
		desk.Parent = building

		-- Tiny chair
		local chair = Instance.new("Part")
		chair.Name = "Chair75_" .. i
		chair.Size = Vector3.new(1.5, 1.2, 1.5)
		chair.Position = desk.Position + Vector3.new(0, -0.3, 2)
		chair.Color = Color3.fromRGB(60, 60, 65)
		chair.Material = Enum.Material.Fabric
		chair.Anchored = true
		chair.Parent = building
	end

	-- Flickering fluorescent lights
	for lx = -2, 2 do
		for lz = -2, 2 do
			local light = Instance.new("Part")
			light.Name = "FluorescentLight"
			light.Size = Vector3.new(6, 0.3, 1.5)
			light.Position = position + Vector3.new(lx * 12, floor75Top - 0.65, lz * 8)
			light.Color = Color3.fromRGB(255, 255, 245)
			light.Material = Enum.Material.Neon
			light.Anchored = true
			light.CanCollide = false
			light.Parent = building

			local pointLight = Instance.new("PointLight")
			pointLight.Color = Color3.fromRGB(255, 250, 230)
			pointLight.Brightness = 0.6
			pointLight.Range = 12
			pointLight.Parent = light
		end
	end

	-- Exit elevator on floor 7.5 (returns to lobby) - VERY VISIBLE!
	local exitDoor = Instance.new("Part")
	exitDoor.Name = "ExitElevator"
	exitDoor.Size = Vector3.new(6, floor75Height - 1, 2)
	exitDoor.Position = position + Vector3.new(-interiorWidth / 2 + 5, floor75Bottom + floor75Height / 2, 0)
	exitDoor.Color = Color3.fromRGB(255, 50, 50) -- BRIGHT RED!
	exitDoor.Material = Enum.Material.Neon
	exitDoor.Anchored = true
	exitDoor.Parent = building

	-- Exit text on BOTH sides of the door
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local exitGui = Instance.new("SurfaceGui")
		exitGui.Face = face
		exitGui.Parent = exitDoor

		local exitText = Instance.new("TextLabel")
		exitText.Size = UDim2.new(1, 0, 1, 0)
		exitText.BackgroundTransparency = 1
		exitText.Text = "EXIT\n[TOUCH ME]"
		exitText.TextColor3 = Color3.fromRGB(255, 255, 255)
		exitText.Font = Enum.Font.GothamBold
		exitText.TextScaled = true
		exitText.Parent = exitGui
	end

	-- GLOWING EXIT SIGN above the door
	local exitSignPart = Instance.new("Part")
	exitSignPart.Name = "ExitSign"
	exitSignPart.Size = Vector3.new(8, 2, 0.5)
	exitSignPart.Position = position + Vector3.new(-interiorWidth / 2 + 5, floor75Top - 1.5, 0)
	exitSignPart.Color = Color3.fromRGB(255, 0, 0)
	exitSignPart.Material = Enum.Material.Neon
	exitSignPart.Anchored = true
	exitSignPart.Parent = building

	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local signGui = Instance.new("SurfaceGui")
		signGui.Face = face
		signGui.Parent = exitSignPart

		local signText = Instance.new("TextLabel")
		signText.Size = UDim2.new(1, 0, 1, 0)
		signText.BackgroundTransparency = 1
		signText.Text = "◄ EXIT ►"
		signText.TextColor3 = Color3.fromRGB(255, 255, 255)
		signText.Font = Enum.Font.GothamBold
		signText.TextScaled = true
		signText.Parent = signGui
	end

	-- Bright light pointing at the exit
	local exitLight = Instance.new("PointLight")
	exitLight.Color = Color3.fromRGB(255, 100, 100)
	exitLight.Brightness = 5
	exitLight.Range = 30
	exitLight.Parent = exitDoor

	-- Flashing lights around exit
	local flashLight1 = Instance.new("Part")
	flashLight1.Name = "FlashLight1"
	flashLight1.Size = Vector3.new(1, 1, 1)
	flashLight1.Position = position + Vector3.new(-interiorWidth / 2 + 1, floor75Top - 2, -2)
	flashLight1.Color = Color3.fromRGB(255, 255, 0)
	flashLight1.Material = Enum.Material.Neon
	flashLight1.Anchored = true
	flashLight1.Parent = building

	local flashLight2 = flashLight1:Clone()
	flashLight2.Name = "FlashLight2"
	flashLight2.Position = position + Vector3.new(-interiorWidth / 2 + 1, floor75Top - 2, 2)
	flashLight2.Parent = building

	-- Arrow pointing to exit on the floor
	local exitArrow = Instance.new("Part")
	exitArrow.Name = "ExitArrow"
	exitArrow.Size = Vector3.new(10, 0.1, 4)
	exitArrow.Position = position + Vector3.new(-interiorWidth / 2 + 15, floor75Bottom + 0.6, 0)
	exitArrow.Color = Color3.fromRGB(255, 100, 100)
	exitArrow.Material = Enum.Material.Neon
	exitArrow.Anchored = true
	exitArrow.Parent = building

	local arrowGui = Instance.new("SurfaceGui")
	arrowGui.Face = Enum.NormalId.Top
	arrowGui.Parent = exitArrow

	local arrowText = Instance.new("TextLabel")
	arrowText.Size = UDim2.new(1, 0, 1, 0)
	arrowText.BackgroundTransparency = 1
	arrowText.Text = "◄◄◄ EXIT ◄◄◄"
	arrowText.TextColor3 = Color3.fromRGB(255, 255, 255)
	arrowText.Font = Enum.Font.GothamBold
	arrowText.TextScaled = true
	arrowText.Rotation = 180
	arrowText.Parent = arrowGui

	-- ========================================
	-- FLOOR 7½ COLLECTIBLE LOOT! (FLOATING!)
	-- These are ACTUAL collectible items!
	-- ========================================
	print("[World] Adding FLOATING COLLECTIBLE LOOT to Floor 7½...")

	local FLOAT_HEIGHT = 3 -- Height above floor to float
	local lootFloatY = floor75Bottom + FLOAT_HEIGHT

	-- Helper function to create floating collectible loot
	local function createFloor75Loot(pos: Vector3, name: string, labelText: string, color: Color3, resourceType: string)
		local loot = Instance.new("Part")
		loot.Name = name
		loot.Size = Vector3.new(1.5, 1.5, 1.5)
		loot.Shape = Enum.PartType.Ball
		loot.Position = pos
		loot.Color = color
		loot.Material = Enum.Material.Neon
		loot.Anchored = true
		loot.CanCollide = false
		loot.Parent = workspace -- Parent to workspace for collection!

		-- Highlight
		local highlight = Instance.new("Highlight")
		highlight.FillColor = color
		highlight.FillTransparency = 0.5
		highlight.OutlineColor = Color3.new(1, 1, 1)
		highlight.Parent = loot

		-- Billboard
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 120, 0, 40)
		billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		billboard.Parent = loot

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = labelText
		label.TextColor3 = color
		label.TextStrokeTransparency = 0
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Parent = billboard

		-- Point light
		local light = Instance.new("PointLight")
		light.Color = color
		light.Brightness = 3
		light.Range = 20
		light.Parent = loot

		-- Store resource type as attribute for collection
		loot:SetAttribute("ResourceType", resourceType)
		loot:SetAttribute("LootName", labelText)

		-- Floating animation
		local baseY = pos.Y
		local animOffset = math.random() * math.pi * 2
		local conn: RBXScriptConnection?
		conn = RunService.Heartbeat:Connect(function()
			if not loot or not loot.Parent then
				if conn then conn:Disconnect() end
				return
			end
			local t = tick() + animOffset
			loot.Position = Vector3.new(pos.X, baseY + math.sin(t * 2) * 0.3, pos.Z)
			loot.Orientation = Vector3.new(0, (t * 40) % 360, 0)
		end)

		return loot
	end

	-- FOOD (collectible - gives hunger)
	createFloor75Loot(
		position + Vector3.new(-15, lootFloatY, -10),
		"Floor75_Food1",
		"★ FOOD ★",
		Color3.fromRGB(100, 255, 100),
		"food"
	)
	createFloor75Loot(
		position + Vector3.new(15, lootFloatY, 10),
		"Floor75_Food2",
		"★ FOOD ★",
		Color3.fromRGB(100, 255, 100),
		"food"
	)

	-- BATTERIES (collectible)
	createFloor75Loot(
		position + Vector3.new(20, lootFloatY, -15),
		"Floor75_Batteries1",
		"★ BATTERIES ★",
		Color3.fromRGB(50, 200, 255),
		"batteries"
	)
	createFloor75Loot(
		position + Vector3.new(-20, lootFloatY, 15),
		"Floor75_Batteries2",
		"★ BATTERIES ★",
		Color3.fromRGB(50, 200, 255),
		"batteries"
	)

	-- FLASHLIGHT (collectible)
	createFloor75Loot(
		position + Vector3.new(0, lootFloatY, -20),
		"Floor75_Flashlight",
		"★ FLASHLIGHT ★",
		Color3.fromRGB(255, 255, 100),
		"flashlight"
	)

	-- ★★★ WALKMAN RADIO - SPECIAL ITEM! ★★★
	local walkman = Instance.new("Part")
	walkman.Name = "Floor75_Walkman"
	walkman.Size = Vector3.new(2, 2, 2)
	walkman.Shape = Enum.PartType.Ball
	walkman.Position = position + Vector3.new(0, lootFloatY + 1, 0) -- Center, slightly higher
	walkman.Color = Color3.fromRGB(255, 100, 200)
	walkman.Material = Enum.Material.Neon
	walkman.Anchored = true
	walkman.CanCollide = false
	walkman.Parent = workspace

	local walkmanHighlight = Instance.new("Highlight")
	walkmanHighlight.FillColor = Color3.fromRGB(255, 100, 200)
	walkmanHighlight.FillTransparency = 0.3
	walkmanHighlight.OutlineColor = Color3.new(1, 1, 1)
	walkmanHighlight.Parent = walkman

	local walkmanBillboard = Instance.new("BillboardGui")
	walkmanBillboard.Size = UDim2.new(0, 180, 0, 60)
	walkmanBillboard.StudsOffset = Vector3.new(0, 3, 0)
	walkmanBillboard.Parent = walkman

	local walkmanLabel = Instance.new("TextLabel")
	walkmanLabel.Size = UDim2.new(1, 0, 1, 0)
	walkmanLabel.BackgroundTransparency = 1
	walkmanLabel.Text = "★★ WALKMAN ★★\nPress 6/7/8 for radio!"
	walkmanLabel.TextColor3 = Color3.fromRGB(255, 100, 200)
	walkmanLabel.TextStrokeTransparency = 0
	walkmanLabel.Font = Enum.Font.GothamBold
	walkmanLabel.TextScaled = true
	walkmanLabel.Parent = walkmanBillboard

	local walkmanLight = Instance.new("PointLight")
	walkmanLight.Color = Color3.fromRGB(255, 100, 200)
	walkmanLight.Brightness = 5
	walkmanLight.Range = 30
	walkmanLight.Parent = walkman

	-- Walkman particles
	local walkmanParticles = Instance.new("ParticleEmitter")
	walkmanParticles.Color = ColorSequence.new(Color3.fromRGB(255, 100, 200))
	walkmanParticles.Transparency = NumberSequence.new(0, 0.5, 1)
	walkmanParticles.Size = NumberSequence.new(0.5, 1, 0)
	walkmanParticles.Lifetime = NumberRange.new(1, 2)
	walkmanParticles.Rate = 15
	walkmanParticles.Speed = NumberRange.new(3, 8)
	walkmanParticles.SpreadAngle = Vector2.new(180, 180)
	walkmanParticles.LightEmission = 1
	walkmanParticles.Parent = walkman

	walkman:SetAttribute("ResourceType", "walkman")
	walkman:SetAttribute("LootName", "WALKMAN RADIO")

	-- Walkman floating animation
	local walkmanBaseY = walkman.Position.Y
	local walkmanOffset = math.random() * math.pi * 2
	local walkmanConn: RBXScriptConnection?
	walkmanConn = RunService.Heartbeat:Connect(function()
		if not walkman or not walkman.Parent then
			if walkmanConn then walkmanConn:Disconnect() end
			return
		end
		local t = tick() + walkmanOffset
		walkman.Position = Vector3.new(walkman.Position.X, walkmanBaseY + math.sin(t * 2) * 0.4, walkman.Position.Z)
		walkman.Orientation = Vector3.new(0, (t * 60) % 360, 0)
	end)

	-- SIGNAL PART HINT SIGN (non-collectible, just a sign)
	local hintSign = Instance.new("Part")
	hintSign.Name = "SignalPartHint"
	hintSign.Size = Vector3.new(8, 4, 0.5)
	hintSign.Position = position + Vector3.new(0, floor75Bottom + 5, 20)
	hintSign.Color = Color3.fromRGB(50, 200, 255)
	hintSign.Material = Enum.Material.Neon
	hintSign.Anchored = true
	hintSign.Parent = building

	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local hintGui = Instance.new("SurfaceGui")
		hintGui.Face = face
		hintGui.Parent = hintSign

		local hintText = Instance.new("TextLabel")
		hintText.Size = UDim2.new(1, 0, 1, 0)
		hintText.BackgroundTransparency = 1
		hintText.Text = "SIGNAL PART #1\nFLOATING NEARBY!"
		hintText.TextColor3 = Color3.new(1, 1, 1)
		hintText.Font = Enum.Font.GothamBold
		hintText.TextScaled = true
		hintText.Parent = hintGui
	end

	print("[World] Floor 7½ loot: 2 Food, 2 Batteries, 1 Flashlight, 1 WALKMAN!")

	-- TELEPORTER LOGIC (touch elevator button to go to 7.5)
	local floor75SpawnPos = position + Vector3.new(0, floor75Bottom + 2, 0)
	local lobbySpawnPos = position + Vector3.new(-20, 2, -buildingDepth / 2 + 10)

	buttonPanel.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if humanoid and rootPart then
			rootPart.CFrame = CFrame.new(floor75SpawnPos)
			print("[Building] Welcome to Floor 7½...")
		end
	end)

	exitDoor.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if humanoid and rootPart then
			rootPart.CFrame = CFrame.new(lobbySpawnPos)
			print("[Building] Returning to lobby...")
		end
	end)

	-- Floor 7.5 sign (visible from outside at that level)
	local floor75Sign = Instance.new("Part")
	floor75Sign.Name = "Floor75ExtSign"
	floor75Sign.Size = Vector3.new(20, 3, 1)
	floor75Sign.Position = position + Vector3.new(0, floor75Bottom + floor75Height / 2, buildingDepth / 2 + 2)
	floor75Sign.Color = Color3.fromRGB(200, 180, 140)
	floor75Sign.Material = Enum.Material.Wood
	floor75Sign.Anchored = true
	floor75Sign.Parent = building

	-- Sign text on BOTH sides
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local sign75Gui = Instance.new("SurfaceGui")
		sign75Gui.Face = face
		sign75Gui.Parent = floor75Sign

		local sign75Text = Instance.new("TextLabel")
		sign75Text.Size = UDim2.new(1, 0, 1, 0)
		sign75Text.BackgroundTransparency = 1
		sign75Text.Text = "FLOOR 7½"
		sign75Text.TextColor3 = Color3.fromRGB(80, 60, 40)
		sign75Text.Font = Enum.Font.Antique
		sign75Text.TextScaled = true
		sign75Text.Parent = sign75Gui
	end

	building.Parent = Workspace
	print("[World] The 20-story Mertin-Flemmer building rises... Floor 7½ awaits.")
	return building
end

-- Create safe campfire location
local function createCampfire(position: Vector3)
	local campfire = Instance.new("Model")
	campfire.Name = "Campfire"

	-- Fire pit base
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(1, 6, 6)
	base.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	base.Color = Color3.fromRGB(40, 35, 30)
	base.Material = Enum.Material.Slate
	base.Anchored = true
	base.Parent = campfire

	-- Logs
	for i = 1, 4 do
		local log = Instance.new("Part")
		log.Name = "Log_" .. i
		log.Size = Vector3.new(0.5, 3, 0.5)
		local angle = (i / 4) * math.pi * 2
		log.CFrame = CFrame.new(position + Vector3.new(math.cos(angle) * 1.5, 0.5, math.sin(angle) * 1.5))
			* CFrame.Angles(math.rad(60), angle, 0)
		log.Color = Color3.fromRGB(60, 40, 25)
		log.Material = Enum.Material.Wood
		log.Anchored = true
		log.Parent = campfire
	end

	-- Fire (glowing part)
	local fire = Instance.new("Part")
	fire.Name = "Fire"
	fire.Shape = Enum.PartType.Ball
	fire.Size = Vector3.new(2, 3, 2)
	fire.Position = position + Vector3.new(0, 1.5, 0)
	fire.Color = Color3.fromRGB(255, 150, 50)
	fire.Material = Enum.Material.Neon
	fire.Anchored = true
	fire.CanCollide = false
	fire.Parent = campfire

	-- Point light
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 180, 100)
	light.Brightness = 2
	light.Range = 30
	light.Parent = fire

	campfire.Parent = Workspace
	return campfire
end

-- Create a fast travel portal
-- Track portal cooldowns per player to prevent teleport loops
local portalCooldowns: { [Player]: number } = {}
local PORTAL_COOLDOWN = 3  -- 3 seconds between portal uses

local function createPortal(position: Vector3, destination: Vector3, portalName: string, color: Color3)
	local portal = Instance.new("Model")
	portal.Name = "Portal_" .. portalName

	-- Get terrain height at destination for proper landing
	local destTerrainHeight = Shared.getTerrainHeight(destination.X, destination.Z)

	-- Portal ring
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Size = Vector3.new(10, 15, 2)
	ring.Position = position + Vector3.new(0, 7.5, 0)
	ring.Color = color
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.3
	ring.Anchored = true
	ring.CanCollide = false
	ring.Parent = portal

	-- Portal center (teleporter)
	local center = Instance.new("Part")
	center.Name = "Teleporter"
	center.Size = Vector3.new(6, 12, 1)
	center.Position = position + Vector3.new(0, 6, 0)
	center.Color = color
	center.Material = Enum.Material.ForceField
	center.Transparency = 0.5
	center.Anchored = true
	center.CanCollide = false
	center.Parent = portal

	-- Glow
	local glow = Instance.new("PointLight")
	glow.Color = color
	glow.Brightness = 2
	glow.Range = 30
	glow.Parent = center

	-- Name sign
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 150, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 12, 0)
	billboard.Adornee = ring
	billboard.Parent = portal

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	label.BackgroundTransparency = 0.3
	label.Text = portalName
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	-- Teleport on touch (WITH COOLDOWN to prevent loops!)
	center.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not humanoid or not rootPart then return end

		-- Get the player
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		-- Check cooldown
		local lastUse = portalCooldowns[player] or 0
		if tick() - lastUse < PORTAL_COOLDOWN then
			return  -- Still on cooldown
		end

		-- Set cooldown
		portalCooldowns[player] = tick()

		-- Teleport AWAY from the return portal (offset 20 studs to the side)
		-- This prevents landing directly on the return portal
		local landingPos = Vector3.new(destination.X + 20, destTerrainHeight + 5, destination.Z)
		rootPart.CFrame = CFrame.new(landingPos)

		print("[Portal]", player.Name, "traveling to", portalName)
	end)

	portal.Parent = Workspace
	return portal
end

-- Create a beach area
local function createBeach(position: Vector3, size: number)
	local beach = Instance.new("Model")
	beach.Name = "Beach"

	-- Sandy beach
	local sand = Instance.new("Part")
	sand.Name = "Sand"
	sand.Size = Vector3.new(size, 3, size * 0.6)
	sand.Position = position + Vector3.new(0, -1, 0)
	sand.Color = Color3.fromRGB(240, 220, 180)
	sand.Material = Enum.Material.Sand
	sand.Anchored = true
	sand.Parent = beach

	-- Ocean water
	local water = Instance.new("Part")
	water.Name = "Ocean"
	water.Size = Vector3.new(size * 1.5, 8, size)
	water.Position = position + Vector3.new(0, -4, size * 0.7)
	water.Color = Color3.fromRGB(30, 100, 150)
	water.Material = Enum.Material.Water
	water.Transparency = 0.4
	water.Anchored = true
	water.CanCollide = false
	water.Parent = beach

	-- Palm trees on beach
	for i = 1, 5 do
		local palm = Instance.new("Model")
		palm.Name = "PalmTree"

		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		trunk.Size = Vector3.new(1.5, 15, 1.5)
		local palmX = position.X + (math.random() - 0.5) * size * 0.8
		local palmZ = position.Z + (math.random() - 0.5) * size * 0.3
		trunk.Position = Vector3.new(palmX, 7.5, palmZ)
		trunk.Color = Color3.fromRGB(120, 90, 60)
		trunk.Material = Enum.Material.Wood
		trunk.Anchored = true
		trunk.Parent = palm

		-- Palm fronds
		for f = 1, 6 do
			local frond = Instance.new("Part")
			frond.Name = "Frond_" .. f
			frond.Size = Vector3.new(1, 0.3, 8)
			local angle = (f / 6) * math.pi * 2
			frond.CFrame = CFrame.new(trunk.Position + Vector3.new(0, 6, 0))
				* CFrame.Angles(0, angle, math.rad(-30))
				* CFrame.new(0, 0, -4)
			frond.Color = Color3.fromRGB(50, 140, 50)
			frond.Material = Enum.Material.Grass
			frond.Anchored = true
			frond.CanCollide = false
			frond.Parent = palm
		end

		palm.Parent = beach
	end

	-- Seashells scattered
	for i = 1, 10 do
		local shell = Instance.new("Part")
		shell.Name = "Shell_" .. i
		shell.Size = Vector3.new(0.5, 0.2, 0.5)
		shell.Position = position + Vector3.new(
			(math.random() - 0.5) * size * 0.8,
			0.5,
			(math.random() - 0.5) * size * 0.4
		)
		shell.Color = Color3.fromRGB(255, 240, 220)
		shell.Material = Enum.Material.SmoothPlastic
		shell.Anchored = true
		shell.Parent = beach
	end

	beach.Parent = Workspace
	return beach
end

-- Create a waterfall
local function createWaterfall(position: Vector3, height: number, name: string)
	local waterfall = Instance.new("Model")
	waterfall.Name = "Waterfall_" .. name

	-- Cliff face
	local cliff = Instance.new("Part")
	cliff.Name = "Cliff"
	cliff.Size = Vector3.new(30, height, 15)
	cliff.Position = position + Vector3.new(0, height / 2, 0)
	cliff.Color = Color3.fromRGB(80, 75, 70)
	cliff.Material = Enum.Material.Rock
	cliff.Anchored = true
	cliff.Parent = waterfall

	-- Water stream falling
	local stream = Instance.new("Part")
	stream.Name = "WaterStream"
	stream.Size = Vector3.new(8, height, 3)
	stream.Position = position + Vector3.new(0, height / 2, 8)
	stream.Color = Color3.fromRGB(100, 180, 220)
	stream.Material = Enum.Material.Glass
	stream.Transparency = 0.4
	stream.Anchored = true
	stream.CanCollide = false
	stream.Parent = waterfall

	-- Mist particles
	local mistEmitter = Instance.new("ParticleEmitter")
	mistEmitter.Color = ColorSequence.new(Color3.fromRGB(200, 220, 255))
	mistEmitter.Transparency = NumberSequence.new(0.5, 1)
	mistEmitter.Size = NumberSequence.new(5, 10)
	mistEmitter.Lifetime = NumberRange.new(2, 4)
	mistEmitter.Rate = 20
	mistEmitter.Speed = NumberRange.new(3, 8)
	mistEmitter.SpreadAngle = Vector2.new(60, 60)
	mistEmitter.Parent = stream

	-- Pool at bottom
	local pool = Instance.new("Part")
	pool.Name = "Pool"
	pool.Shape = Enum.PartType.Cylinder
	pool.Size = Vector3.new(5, 40, 40)
	pool.CFrame = CFrame.new(position + Vector3.new(0, 2.5, 20)) * CFrame.Angles(0, 0, math.rad(90))
	pool.Color = Color3.fromRGB(50, 130, 180)
	pool.Material = Enum.Material.Water
	pool.Transparency = 0.3
	pool.Anchored = true
	pool.CanCollide = false
	pool.Parent = waterfall

	-- Ambient sound visualization (glowing orbs)
	for i = 1, 5 do
		local orb = Instance.new("Part")
		orb.Name = "MistOrb_" .. i
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(2, 2, 2)
		orb.Position = position + Vector3.new(
			(math.random() - 0.5) * 20,
			math.random() * height * 0.3,
			10 + math.random() * 15
		)
		orb.Color = Color3.fromRGB(180, 220, 255)
		orb.Material = Enum.Material.Neon
		orb.Transparency = 0.7
		orb.Anchored = true
		orb.CanCollide = false
		orb.Parent = waterfall
	end

	-- Sign
	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(6, 3, 0.5)
	sign.Position = position + Vector3.new(-20, 3, 25)
	sign.Color = Color3.fromRGB(80, 60, 40)
	sign.Material = Enum.Material.Wood
	sign.Anchored = true
	sign.Parent = waterfall

	-- Sign text on BOTH sides
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local signGui = Instance.new("SurfaceGui")
		signGui.Face = face
		signGui.Parent = sign

		local signText = Instance.new("TextLabel")
		signText.Size = UDim2.new(1, 0, 1, 0)
		signText.BackgroundTransparency = 1
		signText.Text = name
		signText.TextColor3 = Color3.fromRGB(200, 180, 140)
		signText.Font = Enum.Font.Antique
		signText.TextScaled = true
		signText.Parent = signGui
	end

	waterfall.Parent = Workspace
	return waterfall
end

-- Create a cave (for hermits to live in)
local function createCave(position: Vector3, name: string, hermitName: string?): Model
	local cave = Instance.new("Model")
	cave.Name = "Cave_" .. name

	-- Cave entrance (hollow cylinder)
	local entrance = Instance.new("Part")
	entrance.Name = "Entrance"
	entrance.Size = Vector3.new(15, 12, 20)
	entrance.Position = position + Vector3.new(0, 6, 0)
	entrance.Color = Color3.fromRGB(50, 45, 40)
	entrance.Material = Enum.Material.Rock
	entrance.Anchored = true
	entrance.Parent = cave

	-- Hollow out the inside (archway)
	local archway = Instance.new("Part")
	archway.Name = "Archway"
	archway.Size = Vector3.new(8, 10, 25)
	archway.Position = position + Vector3.new(0, 5, 2)
	archway.Color = Color3.fromRGB(30, 28, 25)
	archway.Material = Enum.Material.Slate
	archway.Transparency = 0
	archway.Anchored = true
	archway.CanCollide = false -- Walk through
	archway.Parent = cave

	-- Cave interior floor
	local floor = Instance.new("Part")
	floor.Name = "CaveFloor"
	floor.Size = Vector3.new(20, 2, 30)
	floor.Position = position + Vector3.new(0, -1, -10)
	floor.Color = Color3.fromRGB(40, 38, 35)
	floor.Material = Enum.Material.Slate
	floor.Anchored = true
	floor.Parent = cave

	-- Cave back wall
	local backWall = Instance.new("Part")
	backWall.Name = "BackWall"
	backWall.Size = Vector3.new(20, 15, 3)
	backWall.Position = position + Vector3.new(0, 7, -25)
	backWall.Color = Color3.fromRGB(35, 33, 30)
	backWall.Material = Enum.Material.Rock
	backWall.Anchored = true
	backWall.Parent = cave

	-- Cave ceiling
	local ceiling = Instance.new("Part")
	ceiling.Name = "Ceiling"
	ceiling.Size = Vector3.new(20, 3, 30)
	ceiling.Position = position + Vector3.new(0, 13, -10)
	ceiling.Color = Color3.fromRGB(45, 42, 38)
	ceiling.Material = Enum.Material.Rock
	ceiling.Anchored = true
	ceiling.Parent = cave

	-- Side walls
	local leftWall = Instance.new("Part")
	leftWall.Name = "LeftWall"
	leftWall.Size = Vector3.new(3, 15, 30)
	leftWall.Position = position + Vector3.new(-11, 7, -10)
	leftWall.Color = Color3.fromRGB(45, 42, 38)
	leftWall.Material = Enum.Material.Rock
	leftWall.Anchored = true
	leftWall.Parent = cave

	local rightWall = leftWall:Clone()
	rightWall.Name = "RightWall"
	rightWall.Position = position + Vector3.new(11, 7, -10)
	rightWall.Parent = cave

	-- Campfire inside cave
	local firePit = Instance.new("Part")
	firePit.Name = "FirePit"
	firePit.Shape = Enum.PartType.Cylinder
	firePit.Size = Vector3.new(1, 4, 4)
	firePit.CFrame = CFrame.new(position + Vector3.new(0, 0.5, -15)) * CFrame.Angles(0, 0, math.rad(90))
	firePit.Color = Color3.fromRGB(40, 35, 30)
	firePit.Material = Enum.Material.Slate
	firePit.Anchored = true
	firePit.Parent = cave

	local fire = Instance.new("Part")
	fire.Name = "Fire"
	fire.Shape = Enum.PartType.Ball
	fire.Size = Vector3.new(2, 2, 2)
	fire.Position = position + Vector3.new(0, 2, -15)
	fire.Color = Color3.fromRGB(255, 150, 50)
	fire.Material = Enum.Material.Neon
	fire.Anchored = true
	fire.CanCollide = false
	fire.Parent = cave

	local fireLight = Instance.new("PointLight")
	fireLight.Color = Color3.fromRGB(255, 180, 100)
	fireLight.Brightness = 2
	fireLight.Range = 30
	fireLight.Parent = fire

	-- Glowing crystals on cave walls
	for i = 1, 8 do
		local crystal = Instance.new("Part")
		crystal.Name = "Crystal_" .. i
		crystal.Size = Vector3.new(0.5, 1 + math.random(), 0.5)
		crystal.Position = position + Vector3.new(
			(math.random() > 0.5 and 9 or -9),
			2 + math.random() * 8,
			-5 - math.random() * 15
		)
		crystal.Color = Color3.fromRGB(100 + math.random(100), 150 + math.random(100), 255)
		crystal.Material = Enum.Material.Neon
		crystal.Transparency = 0.3
		crystal.Anchored = true
		crystal.Parent = cave

		local crystalLight = Instance.new("PointLight")
		crystalLight.Color = crystal.Color
		crystalLight.Brightness = 0.5
		crystalLight.Range = 8
		crystalLight.Parent = crystal
	end

	-- Hermit's belongings
	local bedroll = Instance.new("Part")
	bedroll.Name = "Bedroll"
	bedroll.Size = Vector3.new(3, 0.5, 6)
	bedroll.Position = position + Vector3.new(-5, 0.5, -20)
	bedroll.Color = Color3.fromRGB(100, 80, 60)
	bedroll.Material = Enum.Material.Fabric
	bedroll.Anchored = true
	bedroll.Parent = cave

	-- Storage crates
	for i = 1, 3 do
		local crate = Instance.new("Part")
		crate.Name = "Crate_" .. i
		crate.Size = Vector3.new(2, 2, 2)
		crate.Position = position + Vector3.new(5 + i, 1, -18 - i)
		crate.Color = Color3.fromRGB(80, 60, 40)
		crate.Material = Enum.Material.Wood
		crate.Anchored = true
		crate.Parent = cave
	end

	-- Cave name sign
	local nameSign = Instance.new("Part")
	nameSign.Name = "CaveSign"
	nameSign.Size = Vector3.new(8, 3, 0.5)
	nameSign.Position = position + Vector3.new(0, 14, 10)
	nameSign.Color = Color3.fromRGB(60, 50, 40)
	nameSign.Material = Enum.Material.Wood
	nameSign.Anchored = true
	nameSign.Parent = cave

	-- Sign text on BOTH sides
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local nameGui = Instance.new("SurfaceGui")
		nameGui.Face = face
		nameGui.Parent = nameSign

		local nameText = Instance.new("TextLabel")
		nameText.Size = UDim2.new(1, 0, 1, 0)
		nameText.BackgroundTransparency = 1
		nameText.Text = name
		nameText.TextColor3 = Color3.fromRGB(180, 160, 120)
		nameText.Font = Enum.Font.Fantasy
		nameText.TextScaled = true
		nameText.Parent = nameGui
	end

	-- Store hermit info as attribute
	if hermitName then
		cave:SetAttribute("HermitName", hermitName)
	end

	cave.Parent = Workspace
	return cave
end

-- Create a waystone (save point / mini fast travel)
local function createWaystone(position: Vector3, name: string)
	local waystone = Instance.new("Model")
	waystone.Name = "Waystone_" .. name

	local stone = Instance.new("Part")
	stone.Name = "Stone"
	stone.Size = Vector3.new(3, 8, 2)
	stone.Position = position + Vector3.new(0, 4, 0)
	stone.Color = Color3.fromRGB(100, 100, 120)
	stone.Material = Enum.Material.Rock
	stone.Anchored = true
	stone.Parent = waystone

	-- Glowing runes
	local runes = Instance.new("Part")
	runes.Name = "Runes"
	runes.Size = Vector3.new(2.5, 6, 0.5)
	runes.Position = position + Vector3.new(0, 4, 1.1)
	runes.Color = Color3.fromRGB(100, 200, 255)
	runes.Material = Enum.Material.Neon
	runes.Transparency = 0.5
	runes.Anchored = true
	runes.CanCollide = false
	runes.Parent = waystone

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(100, 200, 255)
	light.Brightness = 1
	light.Range = 20
	light.Parent = runes

	-- Label
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 120, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.Adornee = stone
	billboard.Parent = waystone

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Color3.fromRGB(100, 200, 255)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.Fantasy
	label.TextSize = 14
	label.Parent = billboard

	waystone.Parent = Workspace
	return waystone
end

-- Create the player spawn house (safe starting location)
local function createSpawnHouse(position: Vector3)
	local house = Instance.new("Model")
	house.Name = "SpawnHouse"

	local width = 20
	local depth = 15
	local height = 12

	-- Get ACTUAL terrain height using raycast (terrain must be generated first!)
	local terrainHeight = getActualTerrainHeight(position.X, position.Z)
	position = Vector3.new(position.X, terrainHeight, position.Z)
	print("[World] Spawn house terrain height (raycast):", terrainHeight)

	-- Foundation (solid base so you don't fall through)
	local foundation = Instance.new("Part")
	foundation.Name = "Foundation"
	foundation.Size = Vector3.new(width + 10, 5, depth + 10)
	foundation.Position = position + Vector3.new(0, -2.5, 0)
	foundation.Color = Color3.fromRGB(80, 70, 60)
	foundation.Material = Enum.Material.Rock
	foundation.Anchored = true
	foundation.Parent = house

	-- Floor (doesn't extend to doorway to avoid blocking)
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(width, 1, depth - 2)  -- Shorter to not reach door
	floor.Position = position + Vector3.new(0, 0.5, -1)  -- Moved back slightly
	floor.Color = Color3.fromRGB(120, 90, 60)
	floor.Material = Enum.Material.Wood
	floor.Anchored = true
	floor.Parent = house

	-- Doorstep (thin, at ground level, in doorway)
	local doorstep = Instance.new("Part")
	doorstep.Name = "Doorstep"
	doorstep.Size = Vector3.new(6, 0.2, 2)  -- Thin step
	doorstep.Position = position + Vector3.new(0, 0.1, depth / 2 - 0.5)  -- At door, very low
	doorstep.Color = Color3.fromRGB(100, 80, 60)
	doorstep.Material = Enum.Material.Wood
	doorstep.Anchored = true
	doorstep.CanCollide = false  -- Don't block walking
	doorstep.Parent = house

	-- Walls
	local wallColor = Color3.fromRGB(100, 85, 70)

	-- Back wall
	local backWall = Instance.new("Part")
	backWall.Name = "BackWall"
	backWall.Size = Vector3.new(width, height, 1)
	backWall.Position = position + Vector3.new(0, height / 2 + 1, -depth / 2)
	backWall.Color = wallColor
	backWall.Material = Enum.Material.Wood
	backWall.Anchored = true
	backWall.Parent = house

	-- Left wall
	local leftWall = Instance.new("Part")
	leftWall.Name = "LeftWall"
	leftWall.Size = Vector3.new(1, height, depth)
	leftWall.Position = position + Vector3.new(-width / 2, height / 2 + 1, 0)
	leftWall.Color = wallColor
	leftWall.Material = Enum.Material.Wood
	leftWall.Anchored = true
	leftWall.Parent = house

	-- Right wall
	local rightWall = Instance.new("Part")
	rightWall.Name = "RightWall"
	rightWall.Size = Vector3.new(1, height, depth)
	rightWall.Position = position + Vector3.new(width / 2, height / 2 + 1, 0)
	rightWall.Color = wallColor
	rightWall.Material = Enum.Material.Wood
	rightWall.Anchored = true
	rightWall.Parent = house

	-- Front wall with doorway (door is 6 wide x 8 tall)
	-- Left side of front wall
	local frontWallLeft = Instance.new("Part")
	frontWallLeft.Name = "FrontWallLeft"
	frontWallLeft.Size = Vector3.new((width - 6) / 2, height, 1)
	frontWallLeft.Position = position + Vector3.new(-width / 4 - 1.5, height / 2 + 1, depth / 2)
	frontWallLeft.Color = wallColor
	frontWallLeft.Material = Enum.Material.Wood
	frontWallLeft.Anchored = true
	frontWallLeft.Parent = house

	-- Right side of front wall
	local frontWallRight = Instance.new("Part")
	frontWallRight.Name = "FrontWallRight"
	frontWallRight.Size = Vector3.new((width - 6) / 2, height, 1)
	frontWallRight.Position = position + Vector3.new(width / 4 + 1.5, height / 2 + 1, depth / 2)
	frontWallRight.Color = wallColor
	frontWallRight.Material = Enum.Material.Wood
	frontWallRight.Anchored = true
	frontWallRight.Parent = house

	-- Top of doorway (above the door opening) - NO BOTTOM PIECE
	local frontWallTop = Instance.new("Part")
	frontWallTop.Name = "FrontWallTop"
	frontWallTop.Size = Vector3.new(6, 3, 1)  -- Just the part above door
	frontWallTop.Position = position + Vector3.new(0, height - 0.5, depth / 2)  -- At top of wall
	frontWallTop.Color = wallColor
	frontWallTop.Material = Enum.Material.Wood
	frontWallTop.Anchored = true
	frontWallTop.Parent = house

	-- Roof
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = Vector3.new(width + 4, 2, depth + 4)
	roof.Position = position + Vector3.new(0, height + 2, 0)
	roof.Color = Color3.fromRGB(60, 50, 40)
	roof.Material = Enum.Material.Slate
	roof.Anchored = true
	roof.Parent = house

	-- Spawn location INSIDE the house (must be direct child of Workspace, not in a model)
	local spawnPoint = Instance.new("SpawnLocation")
	spawnPoint.Name = "MainSpawn"
	spawnPoint.Size = Vector3.new(6, 1, 6)
	spawnPoint.Position = position + Vector3.new(0, 1.5, -2)  -- Inside house, slightly toward back
	spawnPoint.Color = Color3.fromRGB(100, 150, 100)
	spawnPoint.Material = Enum.Material.SmoothPlastic
	spawnPoint.Transparency = 1  -- Completely invisible
	spawnPoint.Anchored = true
	spawnPoint.CanCollide = false
	spawnPoint.Neutral = true
	spawnPoint.Parent = Workspace  -- Must be direct child of Workspace!

	-- Bed
	local bed = Instance.new("Part")
	bed.Name = "Bed"
	bed.Size = Vector3.new(4, 2, 6)
	bed.Position = position + Vector3.new(-6, 2, -4)
	bed.Color = Color3.fromRGB(150, 100, 80)
	bed.Material = Enum.Material.Fabric
	bed.Anchored = true
	bed.Parent = house

	-- Lantern
	local lantern = Instance.new("Part")
	lantern.Name = "Lantern"
	lantern.Size = Vector3.new(1, 2, 1)
	lantern.Position = position + Vector3.new(6, 5, -4)
	lantern.Color = Color3.fromRGB(255, 200, 100)
	lantern.Material = Enum.Material.Neon
	lantern.Anchored = true
	lantern.Parent = house

	local lanternLight = Instance.new("PointLight")
	lanternLight.Color = Color3.fromRGB(255, 220, 150)
	lanternLight.Brightness = 2
	lanternLight.Range = 25
	lanternLight.Parent = lantern

	-- Welcome sign
	local sign = Instance.new("Part")
	sign.Name = "WelcomeSign"
	sign.Size = Vector3.new(8, 3, 0.5)
	sign.Position = position + Vector3.new(0, 8, -depth / 2 + 2)
	sign.Color = Color3.fromRGB(80, 60, 40)
	sign.Material = Enum.Material.Wood
	sign.Anchored = true
	sign.Parent = house

	-- Sign text on BOTH sides
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local signGui = Instance.new("SurfaceGui")
		signGui.Face = face
		signGui.Parent = sign

		local signText = Instance.new("TextLabel")
		signText.Size = UDim2.new(1, 0, 1, 0)
		signText.BackgroundTransparency = 1
		signText.Text = "SURVIVOR'S CABIN"
		signText.TextColor3 = Color3.fromRGB(200, 180, 140)
		signText.Font = Enum.Font.Antique
		signText.TextScaled = true
		signText.Parent = signGui
	end

	-- Porch/walkway outside door (positioned to not block doorway)
	local porch = Instance.new("Part")
	porch.Name = "Porch"
	porch.Size = Vector3.new(10, 0.5, 6)  -- Thinner so it doesn't block
	porch.Position = position + Vector3.new(0, 0.25, depth / 2 + 4)  -- Further out, lower
	porch.Color = Color3.fromRGB(100, 80, 60)
	porch.Material = Enum.Material.Wood
	porch.Anchored = true
	porch.Parent = house

	house.Parent = Workspace
	print("[World] Spawn house created - players will start here safely")
	return house
end

-- Generate the world
local function generateWorld()
	print("[World] Generating epic world with varied biomes...")

	-- Clear existing (except players and their characters)
	for _, obj in Workspace:GetChildren() do
		if obj.Name ~= "Camera" and obj.Name ~= "Terrain" and not obj:IsA("Model") then
			obj:Destroy()
		elseif obj:IsA("Model") and not game:GetService("Players"):GetPlayerFromCharacter(obj) then
			obj:Destroy()
		end
	end

	-- Create terrain FIRST so players don't fall
	createGround()

	-- Create spawn house at center IMMEDIATELY
	createSpawnHouse(Vector3.new(0, 0, -30))

	-- Create the Mertin-Flemmer Building (7.5 floor) near center
	local buildingX, buildingZ = 150, -100
	local buildingTerrainY = getActualTerrainHeight(buildingX, buildingZ)
	print("[World] Office building terrain height (raycast):", buildingTerrainY)
	createOfficeBuilding75(Vector3.new(buildingX, buildingTerrainY, buildingZ))

	-- FAST TRAVEL PORTAL NETWORK
	local portalLocations = {
		-- Portals spread out more from spawn to reduce clutter
		{ pos = Vector3.new(0, 0, 100), dest = Vector3.new(2000, 0, 0), name = "Frozen Wastes", color = Color3.fromRGB(150, 200, 255) },
		{ pos = Vector3.new(100, 0, 50), dest = Vector3.new(1500, 0, 2000), name = "Scorched Sands", color = Color3.fromRGB(255, 200, 100) },
		{ pos = Vector3.new(-100, 0, 50), dest = Vector3.new(-2000, 0, 1500), name = "Ashen Peaks", color = Color3.fromRGB(255, 100, 50) },
		{ pos = Vector3.new(0, 0, -100), dest = Vector3.new(-1500, 0, -1500), name = "Murky Depths", color = Color3.fromRGB(100, 150, 100) },
		{ pos = Vector3.new(-80, 0, 80), dest = Vector3.new(0, 0, -2500), name = "Shimmering Caverns", color = Color3.fromRGB(200, 150, 255) },
	}

	print("[World] Creating fast travel portal network...")
	for _, p in portalLocations do
		createPortal(p.pos, p.dest, p.name, p.color)
		-- Return portal at destination
		createPortal(p.dest, p.pos, "Return to Spawn", Color3.fromRGB(100, 255, 100))
	end

	-- WAYSTONES across the world
	local waystoneLocations = {
		{ pos = Vector3.new(500, 0, 0), name = "Northern Watch" },
		{ pos = Vector3.new(-500, 0, 0), name = "Western Gate" },
		{ pos = Vector3.new(0, 0, 500), name = "Southern Crossing" },
		{ pos = Vector3.new(0, 0, -500), name = "Eastern Post" },
		{ pos = Vector3.new(1000, 0, 1000), name = "Desert Oasis" },
		{ pos = Vector3.new(-1000, 0, 1000), name = "Volcanic Outlook" },
		{ pos = Vector3.new(1500, 0, -500), name = "Frozen Lake" },
		{ pos = Vector3.new(-1500, 0, -1000), name = "Swamp Hollow" },
	}

	for _, w in waystoneLocations do
		createWaystone(w.pos, w.name)
	end

	-- TREES - lots of them, spread across all biomes
	print("[World] Planting forests across all biomes...")
	for i = 1, 2000 do
		local x = (math.random() - 0.5) * WORLD_SIZE * 1.8  -- Stay within terrain bounds
		local z = (math.random() - 0.5) * WORLD_SIZE * 1.8
		local pos = Vector3.new(x, 0, z)

		-- Avoid spawn area and building
		local distFromCenter = pos.Magnitude
		local distFromBuilding = (pos - Vector3.new(150, 0, -100)).Magnitude
		if distFromCenter > 80 and distFromBuilding > 60 then
			createTree(pos)
		end
	end

	-- ABANDONED BUILDINGS across all biomes
	print("[World] Placing abandoned structures...")
	for i = 1, 60 do
		local angle = math.random() * math.pi * 2
		local distance = 200 + math.random() * 3000
		local pos = Vector3.new(
			math.cos(angle) * distance,
			0,
			math.sin(angle) * distance
		)
		createBuilding(pos)
	end

	-- CAMPFIRES - many scattered across the world
	print("[World] Lighting campfires...")
	-- Central safe zone
	createCampfire(Vector3.new(0, 0, 0))

	-- Campfires in each biome and throughout
	for i = 1, 50 do
		local angle = math.random() * math.pi * 2
		local distance = 100 + math.random() * 3500
		createCampfire(Vector3.new(
			math.cos(angle) * distance,
			0,
			math.sin(angle) * distance
		))
	end

	-- ========================================
	-- MASSIVE LANDMARKS - Visible from EVERYWHERE!
	-- ========================================
	print("[World] Creating MASSIVE landmark beacons...")

	-- Frozen Wastes - MASSIVE ice fortress with glowing spires
	local iceFort = Instance.new("Part")
	iceFort.Name = "IceFortress"
	iceFort.Size = Vector3.new(150, 200, 150) -- MUCH BIGGER!
	iceFort.Position = Vector3.new(2200, 100, 200)
	iceFort.Color = Color3.fromRGB(200, 220, 255)
	iceFort.Material = Enum.Material.Ice
	iceFort.Transparency = 0.3
	iceFort.Anchored = true
	iceFort.Parent = Workspace

	-- Ice fortress beacon spire
	local iceSpire = Instance.new("Part")
	iceSpire.Name = "IceSpire"
	iceSpire.Size = Vector3.new(20, 300, 20)
	iceSpire.Position = Vector3.new(2200, 350, 200)
	iceSpire.Color = Color3.fromRGB(180, 220, 255)
	iceSpire.Material = Enum.Material.Neon
	iceSpire.Transparency = 0.4
	iceSpire.Anchored = true
	iceSpire.Parent = Workspace

	local iceBeacon = Instance.new("PointLight")
	iceBeacon.Color = Color3.fromRGB(150, 200, 255)
	iceBeacon.Brightness = 5
	iceBeacon.Range = 500
	iceBeacon.Parent = iceSpire

	-- Ice particles
	local iceMist = Instance.new("ParticleEmitter")
	iceMist.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
	iceMist.Transparency = NumberSequence.new(0.5, 1)
	iceMist.Size = NumberSequence.new(5, 20, 0)
	iceMist.Lifetime = NumberRange.new(3, 5)
	iceMist.Rate = 20
	iceMist.Speed = NumberRange.new(10, 30)
	iceMist.SpreadAngle = Vector2.new(15, 15)
	iceMist.EmissionDirection = Enum.NormalId.Top
	iceMist.LightEmission = 1
	iceMist.Parent = iceSpire

	-- Desert - MASSIVE ancient temple with golden beacon
	local temple = Instance.new("Part")
	temple.Name = "AncientTemple"
	temple.Size = Vector3.new(150, 150, 150) -- MUCH BIGGER!
	temple.Position = Vector3.new(1800, 75, 2200)
	temple.Color = Color3.fromRGB(220, 200, 160)
	temple.Material = Enum.Material.Sandstone
	temple.Anchored = true
	temple.Parent = Workspace

	-- Golden pyramid on top
	local pyramid = Instance.new("Part")
	pyramid.Name = "GoldenPyramid"
	pyramid.Size = Vector3.new(60, 100, 60)
	pyramid.Position = Vector3.new(1800, 200, 2200)
	pyramid.Color = Color3.fromRGB(255, 215, 0)
	pyramid.Material = Enum.Material.Neon
	pyramid.Transparency = 0.3
	pyramid.Anchored = true
	pyramid.Parent = Workspace

	local goldenBeacon = Instance.new("PointLight")
	goldenBeacon.Color = Color3.fromRGB(255, 200, 100)
	goldenBeacon.Brightness = 6
	goldenBeacon.Range = 600
	goldenBeacon.Parent = pyramid

	-- Volcanic - MASSIVE obsidian tower with fire beacon
	local obsidianTower = Instance.new("Part")
	obsidianTower.Name = "ObsidianTower"
	obsidianTower.Size = Vector3.new(50, 400, 50) -- MUCH TALLER!
	obsidianTower.Position = Vector3.new(-2300, 200, 1300)
	obsidianTower.Color = Color3.fromRGB(20, 20, 25)
	obsidianTower.Material = Enum.Material.Rock
	obsidianTower.Anchored = true
	obsidianTower.Parent = Workspace

	-- Lava beacon at top
	local lavaBeacon = Instance.new("Part")
	lavaBeacon.Name = "LavaBeacon"
	lavaBeacon.Size = Vector3.new(30, 30, 30)
	lavaBeacon.Position = Vector3.new(-2300, 415, 1300)
	lavaBeacon.Color = Color3.fromRGB(255, 100, 0)
	lavaBeacon.Material = Enum.Material.Neon
	lavaBeacon.Anchored = true
	lavaBeacon.Parent = Workspace

	local fireLight = Instance.new("PointLight")
	fireLight.Color = Color3.fromRGB(255, 100, 20)
	fireLight.Brightness = 8
	fireLight.Range = 700
	fireLight.Parent = lavaBeacon

	-- Fire particles
	local fireEmitter = Instance.new("ParticleEmitter")
	fireEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 0)),
	})
	fireEmitter.Transparency = NumberSequence.new(0, 0.5, 1)
	fireEmitter.Size = NumberSequence.new(10, 30, 0)
	fireEmitter.Lifetime = NumberRange.new(2, 4)
	fireEmitter.Rate = 40
	fireEmitter.Speed = NumberRange.new(30, 80)
	fireEmitter.SpreadAngle = Vector2.new(20, 20)
	fireEmitter.EmissionDirection = Enum.NormalId.Top
	fireEmitter.LightEmission = 1
	fireEmitter.Parent = lavaBeacon

	-- ========================================
	-- GIANT CRYSTAL SPIRES - Visible from anywhere!
	-- ========================================
	print("[World] Creating giant crystal spires...")
	local crystalSpireLocations = {
		{ pos = Vector3.new(800, 0, -1500), color = Color3.fromRGB(255, 100, 200), height = 250 }, -- Pink
		{ pos = Vector3.new(-1200, 0, 800), color = Color3.fromRGB(100, 255, 200), height = 280 }, -- Cyan
		{ pos = Vector3.new(1500, 0, 1000), color = Color3.fromRGB(200, 100, 255), height = 220 }, -- Purple
		{ pos = Vector3.new(-800, 0, -1800), color = Color3.fromRGB(255, 255, 100), height = 260 }, -- Yellow
		{ pos = Vector3.new(2500, 0, -1500), color = Color3.fromRGB(100, 200, 255), height = 300 }, -- Blue
		{ pos = Vector3.new(-2000, 0, -800), color = Color3.fromRGB(255, 150, 100), height = 240 }, -- Orange
	}

	for i, spire in crystalSpireLocations do
		local crystal = Instance.new("Part")
		crystal.Name = "GiantCrystal_" .. i
		crystal.Size = Vector3.new(30, spire.height, 30)
		crystal.Position = spire.pos + Vector3.new(0, spire.height / 2, 0)
		crystal.Color = spire.color
		crystal.Material = Enum.Material.Neon
		crystal.Transparency = 0.3
		crystal.Anchored = true
		crystal.Parent = Workspace

		local crystalLight = Instance.new("PointLight")
		crystalLight.Color = spire.color
		crystalLight.Brightness = 4
		crystalLight.Range = 400
		crystalLight.Parent = crystal

		-- Crystal glow particles
		local crystalGlow = Instance.new("ParticleEmitter")
		crystalGlow.Color = ColorSequence.new(spire.color)
		crystalGlow.Transparency = NumberSequence.new(0.3, 1)
		crystalGlow.Size = NumberSequence.new(3, 8, 0)
		crystalGlow.Lifetime = NumberRange.new(2, 4)
		crystalGlow.Rate = 15
		crystalGlow.Speed = NumberRange.new(5, 20)
		crystalGlow.SpreadAngle = Vector2.new(30, 30)
		crystalGlow.EmissionDirection = Enum.NormalId.Top
		crystalGlow.LightEmission = 1
		crystalGlow.Parent = crystal
	end

	-- ========================================
	-- SKYSCRAPER ROOFTOP BEACON - Visible from EVERYWHERE!
	-- ========================================
	print("[World] Adding beacon to skyscraper rooftop...")
	-- The skyscraper is at (150, Y, -100) and is 60 floors * 14 = 840 studs tall
	local skyscraperBeacon = Instance.new("Part")
	skyscraperBeacon.Name = "SkyscraperBeacon"
	skyscraperBeacon.Size = Vector3.new(15, 200, 15)
	skyscraperBeacon.Position = Vector3.new(150, 950, -100) -- On top of 60-story building
	skyscraperBeacon.Color = Color3.fromRGB(255, 50, 50)
	skyscraperBeacon.Material = Enum.Material.Neon
	skyscraperBeacon.Transparency = 0.2
	skyscraperBeacon.Anchored = true
	skyscraperBeacon.Parent = Workspace

	local skyscraperLight = Instance.new("PointLight")
	skyscraperLight.Color = Color3.fromRGB(255, 100, 100)
	skyscraperLight.Brightness = 10
	skyscraperLight.Range = 1000 -- Visible from FAR away!
	skyscraperLight.Parent = skyscraperBeacon

	-- Pulsing red particles (like an aircraft warning beacon)
	local beaconPulse = Instance.new("ParticleEmitter")
	beaconPulse.Color = ColorSequence.new(Color3.fromRGB(255, 50, 50))
	beaconPulse.Transparency = NumberSequence.new(0, 0.5, 1)
	beaconPulse.Size = NumberSequence.new(5, 15, 0)
	beaconPulse.Lifetime = NumberRange.new(1, 2)
	beaconPulse.Rate = 25
	beaconPulse.Speed = NumberRange.new(20, 50)
	beaconPulse.SpreadAngle = Vector2.new(180, 180)
	beaconPulse.LightEmission = 1
	beaconPulse.Parent = skyscraperBeacon

	-- ========================================
	-- FLOATING GLOWING RINGS - Mystical markers
	-- ========================================
	print("[World] Creating floating rings...")
	local ringLocations = {
		{ pos = Vector3.new(600, 80, 400), color = Color3.fromRGB(100, 255, 200) },
		{ pos = Vector3.new(-400, 60, 600), color = Color3.fromRGB(255, 200, 100) },
		{ pos = Vector3.new(900, 100, -300), color = Color3.fromRGB(200, 100, 255) },
		{ pos = Vector3.new(-700, 70, -500), color = Color3.fromRGB(255, 100, 150) },
	}

	for i, ring in ringLocations do
		local ringPart = Instance.new("Part")
		ringPart.Name = "FloatingRing_" .. i
		ringPart.Shape = Enum.PartType.Cylinder
		ringPart.Size = Vector3.new(5, 40, 40)
		ringPart.CFrame = CFrame.new(ring.pos) * CFrame.Angles(0, 0, math.rad(90))
		ringPart.Color = ring.color
		ringPart.Material = Enum.Material.Neon
		ringPart.Transparency = 0.4
		ringPart.CanCollide = false
		ringPart.Anchored = true
		ringPart.Parent = Workspace

		local ringLight = Instance.new("PointLight")
		ringLight.Color = ring.color
		ringLight.Brightness = 3
		ringLight.Range = 100
		ringLight.Parent = ringPart
	end

	-- ========================================
	-- BEACHES around world edges
	-- ========================================
	print("[World] Creating beautiful beaches...")
	local beachLocations = {
		{ pos = Vector3.new(4000, 0, 0), size = 200 },
		{ pos = Vector3.new(-4000, 0, 0), size = 180 },
		{ pos = Vector3.new(0, 0, 4000), size = 220 },
		{ pos = Vector3.new(0, 0, -4000), size = 200 },
		{ pos = Vector3.new(3000, 0, 3000), size = 150 },
		{ pos = Vector3.new(-3000, 0, 3000), size = 160 },
		{ pos = Vector3.new(3000, 0, -3000), size = 140 },
		{ pos = Vector3.new(-3000, 0, -3000), size = 170 },
	}
	for _, b in beachLocations do
		createBeach(b.pos, b.size)
	end

	-- ========================================
	-- WATERFALLS throughout the world
	-- ========================================
	print("[World] Creating majestic waterfalls...")
	local waterfallLocations = {
		{ pos = Vector3.new(800, 0, 600), height = 60, name = "Whispering Falls" },
		{ pos = Vector3.new(-600, 0, 800), height = 80, name = "Thunder Cascade" },
		{ pos = Vector3.new(1800, 0, -400), height = 100, name = "Frozen Tears" },
		{ pos = Vector3.new(-1200, 0, -800), height = 50, name = "Murky Veil" },
		{ pos = Vector3.new(2500, 0, 1500), height = 40, name = "Desert Mirage Falls" },
		{ pos = Vector3.new(-1800, 0, 1800), height = 70, name = "Obsidian Flow" },
	}
	for _, w in waterfallLocations do
		createWaterfall(w.pos, w.height, w.name)
	end

	-- ========================================
	-- CAVES with hermits
	-- ========================================
	print("[World] Carving mysterious caves...")
	local caveLocations = {
		{ pos = Vector3.new(400, 0, -400), name = "The Hermit's Hollow", hermit = "Old Mathias" },
		{ pos = Vector3.new(-800, 0, 300), name = "Whispering Grotto", hermit = "The Blind Seer" },
		{ pos = Vector3.new(1200, 0, 800), name = "Sunken Cavern", hermit = "Mad Gideon" },
		{ pos = Vector3.new(-1500, 0, -600), name = "Shadow's Rest", hermit = "The Silent One" },
		{ pos = Vector3.new(2000, 0, -800), name = "Frozen Sanctuary", hermit = "Frost Elder Yuki" },
		{ pos = Vector3.new(-2000, 0, 2000), name = "Ember Cave", hermit = "Forge Master Kael" },
		{ pos = Vector3.new(600, 0, 1500), name = "Crystal Hollow", hermit = "The Crystal Witch" },
		{ pos = Vector3.new(-400, 0, -1200), name = "Mushroom Grotto", hermit = "Spore Keeper Fungus" },
	}
	for _, c in caveLocations do
		createCave(c.pos, c.name, c.hermit)
	end

	-- ========================================
	-- MISSION BOARDS throughout the world
	-- ========================================
	print("[World] Placing mission boards...")
	local missionBoardLocations = {
		{ pos = Vector3.new(60, 0, 30), missions = { -- Moved away from spawn door
			"SURVIVE THE NIGHT - Find shelter before darkness falls. Campfires provide safety.",
			"GATHER RESOURCES - Collect food, wood, and batteries to survive.",
			"EXPLORE THE WORLD - Use portals to travel to distant biomes.",
		}},
		{ pos = Vector3.new(500, 0, 100), missions = {
			"WOLF HUNTER - The wolves grow bold. Thin their numbers for rewards.",
			"FIND THE HERMITS - Seek the wise ones who dwell in caves.",
			"WATERFALL MEDITATION - Stand in the mist of a waterfall.",
		}},
		{ pos = Vector3.new(-500, 0, -200), missions = {
			"THE 7½ FLOOR - Seek the Mertin-Flemmer building's secret floor.",
			"FACE THE STALKER - Encounter the Deer Monster and survive.",
			"BLOOD MOON - Survive a Blood Night for rare rewards.",
		}},
		{ pos = Vector3.new(1000, 0, 500), missions = {
			"BEACH TREASURES - Explore the coastline for pearls.",
			"CAVE CRYSTALS - Harvest glowing crystals from the caves.",
			"TRADE WITH MERCHANTS - Find wandering traders for supplies.",
		}},
	}

	for i, board in missionBoardLocations do
		local missionBoard = Instance.new("Model")
		missionBoard.Name = "MissionBoard_" .. i

		-- Board post
		local post = Instance.new("Part")
		post.Name = "Post"
		post.Size = Vector3.new(1, 8, 1)
		post.Position = board.pos + Vector3.new(0, 4, 0)
		post.Color = Color3.fromRGB(80, 60, 40)
		post.Material = Enum.Material.Wood
		post.Anchored = true
		post.Parent = missionBoard

		-- Board surface
		local surface = Instance.new("Part")
		surface.Name = "Board"
		surface.Size = Vector3.new(8, 6, 0.5)
		surface.Position = board.pos + Vector3.new(0, 8, 0.5)
		surface.Color = Color3.fromRGB(100, 80, 50)
		surface.Material = Enum.Material.Wood
		surface.Anchored = true
		surface.Parent = missionBoard

		-- Header
		local headerGui = Instance.new("SurfaceGui")
		headerGui.Face = Enum.NormalId.Front
		headerGui.Parent = surface

		local headerFrame = Instance.new("Frame")
		headerFrame.Size = UDim2.new(1, 0, 0.2, 0)
		headerFrame.BackgroundColor3 = Color3.fromRGB(60, 40, 25)
		headerFrame.BorderSizePixel = 0
		headerFrame.Parent = headerGui

		local headerText = Instance.new("TextLabel")
		headerText.Size = UDim2.new(1, 0, 1, 0)
		headerText.BackgroundTransparency = 1
		headerText.Text = "QUESTS & MISSIONS"
		headerText.TextColor3 = Color3.fromRGB(255, 220, 150)
		headerText.Font = Enum.Font.GothamBold
		headerText.TextScaled = true
		headerText.Parent = headerFrame

		-- Mission list
		local listFrame = Instance.new("Frame")
		listFrame.Size = UDim2.new(1, 0, 0.8, 0)
		listFrame.Position = UDim2.new(0, 0, 0.2, 0)
		listFrame.BackgroundTransparency = 1
		listFrame.Parent = headerGui

		for j, mission in board.missions do
			local missionLabel = Instance.new("TextLabel")
			missionLabel.Size = UDim2.new(0.95, 0, 0.28, 0)
			missionLabel.Position = UDim2.new(0.025, 0, (j - 1) * 0.32 + 0.02, 0)
			missionLabel.BackgroundColor3 = Color3.fromRGB(240, 230, 200)
			missionLabel.Text = "• " .. mission
			missionLabel.TextColor3 = Color3.fromRGB(40, 30, 20)
			missionLabel.Font = Enum.Font.Gotham
			missionLabel.TextScaled = true
			missionLabel.TextXAlignment = Enum.TextXAlignment.Left
			missionLabel.TextWrapped = true
			missionLabel.Parent = listFrame

			local missionCorner = Instance.new("UICorner")
			missionCorner.CornerRadius = UDim.new(0, 4)
			missionCorner.Parent = missionLabel

			local padding = Instance.new("UIPadding")
			padding.PaddingLeft = UDim.new(0, 5)
			padding.Parent = missionLabel
		end

		-- Lantern for visibility
		local lantern = Instance.new("Part")
		lantern.Name = "Lantern"
		lantern.Size = Vector3.new(1, 1.5, 1)
		lantern.Position = board.pos + Vector3.new(4.5, 8, 0)
		lantern.Color = Color3.fromRGB(255, 200, 100)
		lantern.Material = Enum.Material.Neon
		lantern.Anchored = true
		lantern.Parent = missionBoard

		local lanternLight = Instance.new("PointLight")
		lanternLight.Color = Color3.fromRGB(255, 220, 150)
		lanternLight.Brightness = 1.5
		lanternLight.Range = 20
		lanternLight.Parent = lantern

		missionBoard.Parent = Workspace
	end

	-- ========================================
	-- MERCHANT STALLS for trading
	-- ========================================
	print("[World] Setting up merchant stalls...")
	local merchantLocations = {
		{ pos = Vector3.new(80, 0, 40), name = "Trader's Corner" },
		{ pos = Vector3.new(-150, 0, 100), name = "The Wandering Merchant" },
		{ pos = Vector3.new(300, 0, -200), name = "Rare Goods" },
	}

	for i, merchant in merchantLocations do
		local stall = Instance.new("Model")
		stall.Name = "MerchantStall_" .. i

		-- Counter
		local counter = Instance.new("Part")
		counter.Name = "Counter"
		counter.Size = Vector3.new(8, 4, 3)
		counter.Position = merchant.pos + Vector3.new(0, 2, 0)
		counter.Color = Color3.fromRGB(100, 70, 45)
		counter.Material = Enum.Material.Wood
		counter.Anchored = true
		counter.Parent = stall

		-- Awning
		local awning = Instance.new("Part")
		awning.Name = "Awning"
		awning.Size = Vector3.new(10, 0.5, 5)
		awning.Position = merchant.pos + Vector3.new(0, 7, 0)
		awning.Color = Color3.fromRGB(180, 50, 50)
		awning.Material = Enum.Material.Fabric
		awning.Anchored = true
		awning.Parent = stall

		-- Sign
		local sign = Instance.new("Part")
		sign.Name = "Sign"
		sign.Size = Vector3.new(6, 2, 0.3)
		sign.Position = merchant.pos + Vector3.new(0, 9, 0)
		sign.Color = Color3.fromRGB(80, 60, 40)
		sign.Material = Enum.Material.Wood
		sign.Anchored = true
		sign.Parent = stall

		-- Sign text on BOTH sides
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local signGui = Instance.new("SurfaceGui")
			signGui.Face = face
			signGui.Parent = sign

			local signText = Instance.new("TextLabel")
			signText.Size = UDim2.new(1, 0, 1, 0)
			signText.BackgroundTransparency = 1
			signText.Text = merchant.name
			signText.TextColor3 = Color3.fromRGB(255, 220, 150)
			signText.Font = Enum.Font.Fantasy
			signText.TextScaled = true
			signText.Parent = signGui
		end

		-- Goods on counter
		for g = 1, 5 do
			local good = Instance.new("Part")
			good.Name = "Good_" .. g
			good.Size = Vector3.new(0.8, 0.8, 0.8)
			good.Position = merchant.pos + Vector3.new(-3 + g * 1.2, 4.5, 0)
			good.Color = Color3.fromRGB(
				100 + math.random(100),
				100 + math.random(100),
				100 + math.random(100)
			)
			good.Material = Enum.Material.SmoothPlastic
			good.Anchored = true
			good.Parent = stall
		end

		-- Lanterns
		local leftLantern = Instance.new("Part")
		leftLantern.Name = "LeftLantern"
		leftLantern.Size = Vector3.new(0.8, 1.2, 0.8)
		leftLantern.Position = merchant.pos + Vector3.new(-4, 5, 0)
		leftLantern.Color = Color3.fromRGB(255, 200, 100)
		leftLantern.Material = Enum.Material.Neon
		leftLantern.Anchored = true
		leftLantern.Parent = stall

		local leftLight = Instance.new("PointLight")
		leftLight.Color = Color3.fromRGB(255, 220, 150)
		leftLight.Brightness = 1
		leftLight.Range = 15
		leftLight.Parent = leftLantern

		local rightLantern = leftLantern:Clone()
		rightLantern.Name = "RightLantern"
		rightLantern.Position = merchant.pos + Vector3.new(4, 5, 0)
		rightLantern.Parent = stall

		stall.Parent = Workspace
	end

	-- ========================================
	-- ALCHEMY TABLE near spawn
	-- ========================================
	print("[World] Creating alchemy station...")
	local alchemyTable = Instance.new("Model")
	alchemyTable.Name = "AlchemyStation"

	local table = Instance.new("Part")
	table.Name = "Table"
	table.Size = Vector3.new(6, 3, 4)
	table.Position = Vector3.new(-60, 1.5, 20) -- Moved away from spawn door
	table.Color = Color3.fromRGB(60, 45, 30)
	table.Material = Enum.Material.Wood
	table.Anchored = true
	table.Parent = alchemyTable

	-- Cauldron
	local cauldron = Instance.new("Part")
	cauldron.Name = "Cauldron"
	cauldron.Shape = Enum.PartType.Cylinder
	cauldron.Size = Vector3.new(2, 3, 3)
	cauldron.CFrame = CFrame.new(Vector3.new(-60, 4, 20)) * CFrame.Angles(0, 0, math.rad(90))
	cauldron.Color = Color3.fromRGB(40, 40, 45)
	cauldron.Material = Enum.Material.Metal
	cauldron.Anchored = true
	cauldron.Parent = alchemyTable

	-- Bubbling liquid
	local liquid = Instance.new("Part")
	liquid.Name = "Liquid"
	liquid.Shape = Enum.PartType.Cylinder
	liquid.Size = Vector3.new(0.5, 2.5, 2.5)
	liquid.CFrame = CFrame.new(Vector3.new(-60, 4.5, 20)) * CFrame.Angles(0, 0, math.rad(90))
	liquid.Color = Color3.fromRGB(100, 255, 150)
	liquid.Material = Enum.Material.Neon
	liquid.Transparency = 0.3
	liquid.Anchored = true
	liquid.CanCollide = false
	liquid.Parent = alchemyTable

	-- Bubble particles
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Color = ColorSequence.new(Color3.fromRGB(150, 255, 200))
	bubbles.Transparency = NumberSequence.new(0.5, 1)
	bubbles.Size = NumberSequence.new(0.2, 0)
	bubbles.Lifetime = NumberRange.new(0.5, 1)
	bubbles.Rate = 15
	bubbles.Speed = NumberRange.new(2, 4)
	bubbles.SpreadAngle = Vector2.new(20, 20)
	bubbles.Parent = liquid

	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(100, 255, 150)
	glow.Brightness = 1.5
	glow.Range = 15
	glow.Parent = liquid

	-- Ingredient bottles
	local bottleColors = {
		Color3.fromRGB(255, 100, 100),
		Color3.fromRGB(100, 100, 255),
		Color3.fromRGB(255, 255, 100),
		Color3.fromRGB(150, 100, 255),
	}

	for b, color in bottleColors do
		local bottle = Instance.new("Part")
		bottle.Name = "Bottle_" .. b
		bottle.Size = Vector3.new(0.6, 1.2, 0.6)
		bottle.Position = Vector3.new(-62 + b * 1.2, 3.6, 22)
		bottle.Color = color
		bottle.Material = Enum.Material.Glass
		bottle.Transparency = 0.3
		bottle.Anchored = true
		bottle.Parent = alchemyTable
	end

	-- Sign
	local alchemySign = Instance.new("Part")
	alchemySign.Name = "Sign"
	alchemySign.Size = Vector3.new(5, 2, 0.3)
	alchemySign.Position = Vector3.new(-60, 7, 18)
	alchemySign.Color = Color3.fromRGB(60, 45, 30)
	alchemySign.Material = Enum.Material.Wood
	alchemySign.Anchored = true
	alchemySign.Parent = alchemyTable

	-- Sign text on BOTH sides
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local alchemySignGui = Instance.new("SurfaceGui")
		alchemySignGui.Face = face
		alchemySignGui.Parent = alchemySign

		local alchemySignText = Instance.new("TextLabel")
		alchemySignText.Size = UDim2.new(1, 0, 1, 0)
		alchemySignText.BackgroundTransparency = 1
		alchemySignText.Text = "ALCHEMY"
		alchemySignText.TextColor3 = Color3.fromRGB(100, 255, 150)
		alchemySignText.Font = Enum.Font.Fantasy
		alchemySignText.TextScaled = true
		alchemySignText.Parent = alchemySignGui
	end

	alchemyTable.Parent = Workspace

	-- ========================================
	-- SPECIAL ENVIRONMENTAL EFFECTS
	-- Unique animations at specific locations!
	-- ========================================
	print("[World] Creating magical environmental effects...")

	-- 1. SNOW FALLING - Frozen Peaks area
	local snowZone = Instance.new("Part")
	snowZone.Name = "SnowZone"
	snowZone.Size = Vector3.new(600, 10, 600)
	snowZone.Position = Vector3.new(2000, 150, 0)  -- High in the frozen mountains
	snowZone.Transparency = 1
	snowZone.CanCollide = false
	snowZone.Anchored = true
	snowZone.Parent = Workspace

	local snowfall = Instance.new("ParticleEmitter")
	snowfall.Name = "Snowfall"
	snowfall.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	snowfall.Transparency = NumberSequence.new(0, 0.3, 1)
	snowfall.Size = NumberSequence.new(0.3, 0.5, 0.2)
	snowfall.Texture = "rbxassetid://241876428"  -- Soft particle
	snowfall.Lifetime = NumberRange.new(8, 12)
	snowfall.Rate = 50
	snowfall.Speed = NumberRange.new(5, 15)
	snowfall.SpreadAngle = Vector2.new(30, 30)
	snowfall.Rotation = NumberRange.new(0, 360)
	snowfall.RotSpeed = NumberRange.new(-30, 30)
	snowfall.EmissionDirection = Enum.NormalId.Bottom
	snowfall.Parent = snowZone

	-- 2. SPARKS FLYING - Volcanic Forge area
	local sparkZone = Instance.new("Part")
	sparkZone.Name = "SparkZone"
	sparkZone.Size = Vector3.new(80, 20, 80)
	sparkZone.Position = Vector3.new(-2300, 30, 1300)  -- Near obsidian tower
	sparkZone.Transparency = 1
	sparkZone.CanCollide = false
	sparkZone.Anchored = true
	sparkZone.Parent = Workspace

	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "VolcanicSparks"
	sparks.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 0)),
	})
	sparks.Transparency = NumberSequence.new(0, 0.5, 1)
	sparks.Size = NumberSequence.new(0.8, 0.3, 0)
	sparks.LightEmission = 1
	sparks.LightInfluence = 0
	sparks.Lifetime = NumberRange.new(2, 4)
	sparks.Rate = 30
	sparks.Speed = NumberRange.new(20, 50)
	sparks.SpreadAngle = Vector2.new(60, 60)
	sparks.Acceleration = Vector3.new(0, -20, 0)  -- Fall back down
	sparks.EmissionDirection = Enum.NormalId.Top
	sparks.Parent = sparkZone

	-- Ember glow
	local emberGlow = Instance.new("PointLight")
	emberGlow.Color = Color3.fromRGB(255, 100, 20)
	emberGlow.Brightness = 3
	emberGlow.Range = 100
	emberGlow.Parent = sparkZone

	-- 3. STARS STREAMING TO HEAVEN - Sacred Grove
	local starZone = Instance.new("Part")
	starZone.Name = "StarZone"
	starZone.Shape = Enum.PartType.Cylinder
	starZone.Size = Vector3.new(200, 100, 100)
	starZone.CFrame = CFrame.new(Vector3.new(0, 100, -800)) * CFrame.Angles(0, 0, math.rad(90))
	starZone.Transparency = 1
	starZone.CanCollide = false
	starZone.Anchored = true
	starZone.Parent = Workspace

	local risingStars = Instance.new("ParticleEmitter")
	risingStars.Name = "RisingStars"
	risingStars.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 200)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	risingStars.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.1, 0),
		NumberSequenceKeypoint.new(0.8, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	risingStars.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 1.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	risingStars.Texture = "rbxassetid://244221613"  -- Sparkle/star
	risingStars.LightEmission = 1
	risingStars.Lifetime = NumberRange.new(5, 8)
	risingStars.Rate = 15
	risingStars.Speed = NumberRange.new(30, 60)
	risingStars.SpreadAngle = Vector2.new(10, 10)
	risingStars.EmissionDirection = Enum.NormalId.Top
	risingStars.Parent = starZone

	-- Sacred stone at center
	local sacredStone = Instance.new("Part")
	sacredStone.Name = "SacredStone"
	sacredStone.Size = Vector3.new(15, 25, 15)
	sacredStone.Position = Vector3.new(0, 12, -800)
	sacredStone.Color = Color3.fromRGB(180, 180, 200)
	sacredStone.Material = Enum.Material.Marble
	sacredStone.Anchored = true
	sacredStone.Parent = Workspace

	-- 4. RAINBOW LASERS - Crystal Cavern entrance
	local rainbowZone = Instance.new("Part")
	rainbowZone.Name = "RainbowZone"
	rainbowZone.Size = Vector3.new(50, 100, 50)
	rainbowZone.Position = Vector3.new(600, 50, 1500)  -- Near Crystal Hollow
	rainbowZone.Transparency = 1
	rainbowZone.CanCollide = false
	rainbowZone.Anchored = true
	rainbowZone.Parent = Workspace

	-- Crystal that emits rainbows
	local rainbowCrystal = Instance.new("Part")
	rainbowCrystal.Name = "RainbowCrystal"
	rainbowCrystal.Size = Vector3.new(8, 20, 8)
	rainbowCrystal.Position = Vector3.new(600, 10, 1500)
	rainbowCrystal.Color = Color3.fromRGB(255, 255, 255)
	rainbowCrystal.Material = Enum.Material.Glass
	rainbowCrystal.Transparency = 0.3
	rainbowCrystal.Anchored = true
	rainbowCrystal.Parent = Workspace

	local rainbowBeams = Instance.new("ParticleEmitter")
	rainbowBeams.Name = "RainbowLasers"
	rainbowBeams.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 165, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(238, 130, 238)),
	})
	rainbowBeams.Transparency = NumberSequence.new(0.2, 0.5, 1)
	rainbowBeams.Size = NumberSequence.new(2, 8, 0)
	rainbowBeams.LightEmission = 1
	rainbowBeams.Lifetime = NumberRange.new(3, 5)
	rainbowBeams.Rate = 8
	rainbowBeams.Speed = NumberRange.new(40, 80)
	rainbowBeams.SpreadAngle = Vector2.new(30, 30)
	rainbowBeams.EmissionDirection = Enum.NormalId.Top
	rainbowBeams.Parent = rainbowCrystal

	-- 5. TELESCOPE EFFECT - Observatory on mountain peak
	local observatoryBase = Instance.new("Part")
	observatoryBase.Name = "Observatory"
	observatoryBase.Shape = Enum.PartType.Cylinder
	observatoryBase.Size = Vector3.new(10, 60, 60)
	observatoryBase.CFrame = CFrame.new(Vector3.new(350, 200, 350)) * CFrame.Angles(0, 0, math.rad(90))
	observatoryBase.Color = Color3.fromRGB(200, 200, 210)
	observatoryBase.Material = Enum.Material.Concrete
	observatoryBase.Anchored = true
	observatoryBase.Parent = Workspace

	-- Dome
	local dome = Instance.new("Part")
	dome.Name = "ObservatoryDome"
	dome.Shape = Enum.PartType.Ball
	dome.Size = Vector3.new(50, 50, 50)
	dome.Position = Vector3.new(350, 230, 350)
	dome.Color = Color3.fromRGB(150, 160, 180)
	dome.Material = Enum.Material.Metal
	dome.Anchored = true
	dome.Parent = Workspace

	-- Telescope beam shooting into sky!
	local telescopeBeam = Instance.new("Part")
	telescopeBeam.Name = "TelescopeBeam"
	telescopeBeam.Size = Vector3.new(5, 500, 5)
	telescopeBeam.Position = Vector3.new(350, 500, 350)
	telescopeBeam.Color = Color3.fromRGB(150, 180, 255)
	telescopeBeam.Material = Enum.Material.Neon
	telescopeBeam.Transparency = 0.7
	telescopeBeam.CanCollide = false
	telescopeBeam.Anchored = true
	telescopeBeam.Parent = Workspace

	-- Telescope particles going up the beam
	local telescopeParticles = Instance.new("ParticleEmitter")
	telescopeParticles.Name = "TelescopeRays"
	telescopeParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 150, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 220, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	telescopeParticles.Transparency = NumberSequence.new(0.5, 0.8, 1)
	telescopeParticles.Size = NumberSequence.new(1, 3, 0)
	telescopeParticles.LightEmission = 1
	telescopeParticles.Lifetime = NumberRange.new(4, 6)
	telescopeParticles.Rate = 20
	telescopeParticles.Speed = NumberRange.new(80, 120)
	telescopeParticles.SpreadAngle = Vector2.new(5, 5)
	telescopeParticles.EmissionDirection = Enum.NormalId.Top
	telescopeParticles.Parent = dome

	-- Twinkling stars around dome
	local domeStars = Instance.new("ParticleEmitter")
	domeStars.Name = "DomeStars"
	domeStars.Color = ColorSequence.new(Color3.fromRGB(255, 255, 200))
	domeStars.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0),
		NumberSequenceKeypoint.new(0.7, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	domeStars.Size = NumberSequence.new(0.5, 1, 0.5)
	domeStars.LightEmission = 1
	domeStars.Lifetime = NumberRange.new(1, 2)
	domeStars.Rate = 10
	domeStars.Speed = NumberRange.new(0, 2)
	domeStars.SpreadAngle = Vector2.new(180, 180)
	domeStars.Parent = dome

	-- 6. KALEIDOSCOPE - Mystical Portal ruins
	local kaleidoscopeBase = Instance.new("Part")
	kaleidoscopeBase.Name = "KaleidoscopeBase"
	kaleidoscopeBase.Shape = Enum.PartType.Cylinder
	kaleidoscopeBase.Size = Vector3.new(3, 40, 40)
	kaleidoscopeBase.CFrame = CFrame.new(Vector3.new(-800, 20, -500)) * CFrame.Angles(0, 0, math.rad(90))
	kaleidoscopeBase.Color = Color3.fromRGB(50, 30, 60)
	kaleidoscopeBase.Material = Enum.Material.Slate
	kaleidoscopeBase.Anchored = true
	kaleidoscopeBase.Parent = Workspace

	-- Central prism
	local prism = Instance.new("Part")
	prism.Name = "KaleidoscopePrism"
	prism.Size = Vector3.new(6, 12, 6)
	prism.Position = Vector3.new(-800, 30, -500)
	prism.Color = Color3.fromRGB(255, 255, 255)
	prism.Material = Enum.Material.Glass
	prism.Transparency = 0.4
	prism.Anchored = true
	prism.Parent = Workspace

	-- Rotating colored beams (kaleidoscope effect!)
	local kaleidoColors = {
		Color3.fromRGB(255, 50, 100),   -- Pink
		Color3.fromRGB(100, 255, 150),  -- Mint
		Color3.fromRGB(100, 150, 255),  -- Sky blue
		Color3.fromRGB(255, 200, 50),   -- Gold
		Color3.fromRGB(200, 100, 255),  -- Purple
		Color3.fromRGB(50, 255, 255),   -- Cyan
	}

	for i, color in ipairs(kaleidoColors) do
		local beam = Instance.new("Part")
		beam.Name = "KaleidoBeam" .. i
		beam.Size = Vector3.new(1, 80, 1)
		local angle = (i / #kaleidoColors) * math.pi * 2
		beam.CFrame = CFrame.new(Vector3.new(-800, 70, -500))
			* CFrame.Angles(math.rad(30), angle, 0)
			* CFrame.new(0, 40, 0)
		beam.Color = color
		beam.Material = Enum.Material.Neon
		beam.Transparency = 0.5
		beam.CanCollide = false
		beam.Anchored = true
		beam.CastShadow = false
		beam.Parent = Workspace

		-- Particles along each beam
		local beamParticles = Instance.new("ParticleEmitter")
		beamParticles.Name = "BeamGlow"
		beamParticles.Color = ColorSequence.new(color)
		beamParticles.Transparency = NumberSequence.new(0.3, 1)
		beamParticles.Size = NumberSequence.new(0.5, 2, 0)
		beamParticles.LightEmission = 1
		beamParticles.Lifetime = NumberRange.new(1, 2)
		beamParticles.Rate = 5
		beamParticles.Speed = NumberRange.new(10, 20)
		beamParticles.SpreadAngle = Vector2.new(10, 10)
		beamParticles.Parent = beam
	end

	-- Central swirling particles
	local kaleidoSwirl = Instance.new("ParticleEmitter")
	kaleidoSwirl.Name = "KaleidoscopeSwirl"
	kaleidoSwirl.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 100)),
		ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 50)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(100, 255, 150)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(100, 150, 255)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(200, 100, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 100)),
	})
	kaleidoSwirl.Transparency = NumberSequence.new(0, 0.5, 1)
	kaleidoSwirl.Size = NumberSequence.new(0.5, 3, 0)
	kaleidoSwirl.Texture = "rbxassetid://243098098"  -- Ring
	kaleidoSwirl.LightEmission = 1
	kaleidoSwirl.Lifetime = NumberRange.new(2, 3)
	kaleidoSwirl.Rate = 15
	kaleidoSwirl.Speed = NumberRange.new(5, 15)
	kaleidoSwirl.SpreadAngle = Vector2.new(180, 180)
	kaleidoSwirl.RotSpeed = NumberRange.new(100, 200)
	kaleidoSwirl.Rotation = NumberRange.new(0, 360)
	kaleidoSwirl.Parent = prism

	-- Floating geometric shapes
	local shapePositions = {
		Vector3.new(-795, 50, -495),
		Vector3.new(-805, 55, -505),
		Vector3.new(-800, 60, -490),
		Vector3.new(-790, 45, -510),
	}
	for j, pos in ipairs(shapePositions) do
		local floatingShape = Instance.new("Part")
		floatingShape.Name = "FloatingShape" .. j
		floatingShape.Size = Vector3.new(3, 3, 3)
		floatingShape.Position = pos
		floatingShape.Color = kaleidoColors[(j % #kaleidoColors) + 1]
		floatingShape.Material = Enum.Material.Neon
		floatingShape.Transparency = 0.3
		floatingShape.CanCollide = false
		floatingShape.Anchored = true
		floatingShape.CastShadow = false
		floatingShape.Parent = Workspace
	end

	print("[World] - Snow falling in Frozen Peaks")
	print("[World] - Volcanic sparks at Obsidian Tower")
	print("[World] - Stars rising at Sacred Grove")
	print("[World] - Rainbow lasers at Crystal Hollow")
	print("[World] - Telescope beam at Mountain Observatory")
	print("[World] - Kaleidoscope at Mystical Portal")

	-- ========================================
	-- ★★★ REWARD SHACKS WITH BIG SIGNS ★★★
	-- One at each chapter location + near radio towers!
	-- ========================================
	print("[World] Building REWARD SHACKS with BIG SIGNS and treats...")

	local function createRewardShack(position: Vector3, name: string, chapterNum: number?, biomeColor: Color3?, specialDesc: string?)
		local shack = Instance.new("Model")
		shack.Name = "RewardShack_" .. name

		local color = biomeColor or Color3.fromRGB(255, 200, 100)
		local terrainY = getActualTerrainHeight(position.X, position.Z)
		local basePos = Vector3.new(position.X, terrainY, position.Z)

		-- SHACK STRUCTURE (visible from distance!)
		local floor = Instance.new("Part")
		floor.Name = "Floor"
		floor.Size = Vector3.new(16, 1, 16)
		floor.Position = basePos + Vector3.new(0, 0.5, 0)
		floor.Color = Color3.fromRGB(100, 70, 45)
		floor.Material = Enum.Material.Wood
		floor.Anchored = true
		floor.Parent = shack

		-- Walls with gaps for entry
		local wallHeight = 10
		local wallColor = Color3.fromRGB(120, 90, 60)

		local backWall = Instance.new("Part")
		backWall.Name = "BackWall"
		backWall.Size = Vector3.new(16, wallHeight, 1)
		backWall.Position = basePos + Vector3.new(0, wallHeight/2 + 1, -7.5)
		backWall.Color = wallColor
		backWall.Material = Enum.Material.Wood
		backWall.Anchored = true
		backWall.Parent = shack

		local leftWall = Instance.new("Part")
		leftWall.Name = "LeftWall"
		leftWall.Size = Vector3.new(1, wallHeight, 16)
		leftWall.Position = basePos + Vector3.new(-7.5, wallHeight/2 + 1, 0)
		leftWall.Color = wallColor
		leftWall.Material = Enum.Material.Wood
		leftWall.Anchored = true
		leftWall.Parent = shack

		local rightWall = Instance.new("Part")
		rightWall.Name = "RightWall"
		rightWall.Size = Vector3.new(1, wallHeight, 16)
		rightWall.Position = basePos + Vector3.new(7.5, wallHeight/2 + 1, 0)
		rightWall.Color = wallColor
		rightWall.Material = Enum.Material.Wood
		rightWall.Anchored = true
		rightWall.Parent = shack

		-- Roof
		local roof = Instance.new("Part")
		roof.Name = "Roof"
		roof.Size = Vector3.new(20, 2, 20)
		roof.Position = basePos + Vector3.new(0, wallHeight + 2, 0)
		roof.Color = Color3.fromRGB(80, 55, 35)
		roof.Material = Enum.Material.Slate
		roof.Anchored = true
		roof.Parent = shack

		-- ★★★ MASSIVE GLOWING SIGN - Visible from FAR! ★★★
		local signPost = Instance.new("Part")
		signPost.Name = "SignPost"
		signPost.Size = Vector3.new(4, 30, 4)
		signPost.Position = basePos + Vector3.new(0, 25, 12)
		signPost.Color = color
		signPost.Material = Enum.Material.Neon
		signPost.Transparency = 0.2
		signPost.Anchored = true
		signPost.Parent = shack

		local bigSign = Instance.new("Part")
		bigSign.Name = "BigSign"
		bigSign.Size = Vector3.new(24, 12, 2)
		bigSign.Position = basePos + Vector3.new(0, 45, 12)
		bigSign.Color = color
		bigSign.Material = Enum.Material.Neon
		bigSign.Transparency = 0.1
		bigSign.Anchored = true
		bigSign.Parent = shack

		-- Text on BOTH sides of big sign
		local signText = chapterNum and ("★ CHAPTER " .. chapterNum .. " ★\n" .. string.upper(name)) or ("★ " .. string.upper(name) .. " ★\nREWARD SHACK")
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local signGui = Instance.new("SurfaceGui")
			signGui.Face = face
			signGui.Parent = bigSign

			local signLabel = Instance.new("TextLabel")
			signLabel.Size = UDim2.new(1, 0, 1, 0)
			signLabel.BackgroundTransparency = 1
			signLabel.Text = signText
			signLabel.TextColor3 = Color3.new(1, 1, 1)
			signLabel.Font = Enum.Font.GothamBold
			signLabel.TextScaled = true
			signLabel.TextStrokeTransparency = 0
			signLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
			signLabel.Parent = signGui
		end

		-- BEACON LIGHT - Visible from anywhere!
		local beacon = Instance.new("PointLight")
		beacon.Color = color
		beacon.Brightness = 10
		beacon.Range = 300
		beacon.Parent = bigSign

		-- Particle effect on sign
		local signParticles = Instance.new("ParticleEmitter")
		signParticles.Color = ColorSequence.new(color)
		signParticles.Transparency = NumberSequence.new(0, 0.5, 1)
		signParticles.Size = NumberSequence.new(2, 5, 0)
		signParticles.Lifetime = NumberRange.new(1, 2)
		signParticles.Rate = 15
		signParticles.Speed = NumberRange.new(10, 25)
		signParticles.SpreadAngle = Vector2.new(45, 45)
		signParticles.LightEmission = 1
		signParticles.Parent = bigSign

		-- INTERIOR LIGHTING (lots of warm light!)
		for i = 1, 4 do
			local lantern = Instance.new("Part")
			lantern.Name = "Lantern_" .. i
			lantern.Size = Vector3.new(1, 2, 1)
			local lx = (i % 2 == 0) and 5 or -5
			local lz = (i > 2) and 4 or -4
			lantern.Position = basePos + Vector3.new(lx, wallHeight - 1, lz)
			lantern.Color = Color3.fromRGB(255, 220, 100)
			lantern.Material = Enum.Material.Neon
			lantern.Anchored = true
			lantern.Parent = shack

			local lanternLight = Instance.new("PointLight")
			lanternLight.Color = Color3.fromRGB(255, 220, 150)
			lanternLight.Brightness = 3
			lanternLight.Range = 25
			lanternLight.Parent = lantern
		end

		-- CAMPFIRE inside
		local firepit = Instance.new("Part")
		firepit.Name = "Firepit"
		firepit.Shape = Enum.PartType.Cylinder
		firepit.Size = Vector3.new(1, 4, 4)
		firepit.CFrame = CFrame.new(basePos + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90))
		firepit.Color = Color3.fromRGB(50, 40, 35)
		firepit.Material = Enum.Material.Slate
		firepit.Anchored = true
		firepit.Parent = shack

		local fire = Instance.new("Part")
		fire.Name = "Fire"
		fire.Shape = Enum.PartType.Ball
		fire.Size = Vector3.new(2, 2, 2)
		fire.Position = basePos + Vector3.new(0, 2.5, 0)
		fire.Color = Color3.fromRGB(255, 150, 50)
		fire.Material = Enum.Material.Neon
		fire.Anchored = true
		fire.CanCollide = false
		fire.Parent = shack

		local fireLight = Instance.new("PointLight")
		fireLight.Color = Color3.fromRGB(255, 180, 100)
		fireLight.Brightness = 3
		fireLight.Range = 40
		fireLight.Parent = fire

		-- ★★★ LOOT ITEMS - Food, Flashlight, Batteries, Seeds ★★★
		-- FOOD CRATE
		local foodCrate = Instance.new("Part")
		foodCrate.Name = "FoodCrate"
		foodCrate.Size = Vector3.new(3, 2, 2)
		foodCrate.Position = basePos + Vector3.new(-4, 2, -4)
		foodCrate.Color = Color3.fromRGB(150, 100, 50)
		foodCrate.Material = Enum.Material.Wood
		foodCrate.Anchored = true
		foodCrate.Parent = shack

		local foodHighlight = Instance.new("Highlight")
		foodHighlight.FillColor = Color3.fromRGB(100, 255, 100)
		foodHighlight.FillTransparency = 0.7
		foodHighlight.Parent = foodCrate

		local foodBillboard = Instance.new("BillboardGui")
		foodBillboard.Size = UDim2.new(0, 80, 0, 25)
		foodBillboard.StudsOffset = Vector3.new(0, 2, 0)
		foodBillboard.Parent = foodCrate

		local foodLabel = Instance.new("TextLabel")
		foodLabel.Size = UDim2.new(1, 0, 1, 0)
		foodLabel.BackgroundTransparency = 1
		foodLabel.Text = "FOOD"
		foodLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		foodLabel.TextStrokeTransparency = 0
		foodLabel.Font = Enum.Font.GothamBold
		foodLabel.TextScaled = true
		foodLabel.Parent = foodBillboard

		-- FLASHLIGHT
		local flashlight = Instance.new("Part")
		flashlight.Name = "Flashlight"
		flashlight.Size = Vector3.new(0.5, 0.5, 2)
		flashlight.Position = basePos + Vector3.new(4, 2, -4)
		flashlight.Color = Color3.fromRGB(255, 255, 100)
		flashlight.Material = Enum.Material.Neon
		flashlight.Anchored = true
		flashlight.Parent = shack

		local flashHighlight = Instance.new("Highlight")
		flashHighlight.FillColor = Color3.fromRGB(255, 255, 100)
		flashHighlight.FillTransparency = 0.5
		flashHighlight.Parent = flashlight

		local flashBillboard = Instance.new("BillboardGui")
		flashBillboard.Size = UDim2.new(0, 100, 0, 25)
		flashBillboard.StudsOffset = Vector3.new(0, 1.5, 0)
		flashBillboard.Parent = flashlight

		local flashLabel = Instance.new("TextLabel")
		flashLabel.Size = UDim2.new(1, 0, 1, 0)
		flashLabel.BackgroundTransparency = 1
		flashLabel.Text = "FLASHLIGHT"
		flashLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
		flashLabel.TextStrokeTransparency = 0
		flashLabel.Font = Enum.Font.GothamBold
		flashLabel.TextScaled = true
		flashLabel.Parent = flashBillboard

		-- BATTERIES
		local batteries = Instance.new("Part")
		batteries.Name = "Batteries"
		batteries.Size = Vector3.new(1, 0.5, 0.5)
		batteries.Position = basePos + Vector3.new(4, 2, 3)
		batteries.Color = Color3.fromRGB(50, 200, 255)
		batteries.Material = Enum.Material.SmoothPlastic
		batteries.Anchored = true
		batteries.Parent = shack

		local battHighlight = Instance.new("Highlight")
		battHighlight.FillColor = Color3.fromRGB(50, 200, 255)
		battHighlight.FillTransparency = 0.6
		battHighlight.Parent = batteries

		local battBillboard = Instance.new("BillboardGui")
		battBillboard.Size = UDim2.new(0, 90, 0, 25)
		battBillboard.StudsOffset = Vector3.new(0, 1.5, 0)
		battBillboard.Parent = batteries

		local battLabel = Instance.new("TextLabel")
		battLabel.Size = UDim2.new(1, 0, 1, 0)
		battLabel.BackgroundTransparency = 1
		battLabel.Text = "BATTERIES"
		battLabel.TextColor3 = Color3.fromRGB(50, 200, 255)
		battLabel.TextStrokeTransparency = 0
		battLabel.Font = Enum.Font.GothamBold
		battLabel.TextScaled = true
		battLabel.Parent = battBillboard

		-- SEEDS
		local seeds = Instance.new("Part")
		seeds.Name = "Seeds"
		seeds.Size = Vector3.new(1, 1, 1)
		seeds.Position = basePos + Vector3.new(-4, 2, 3)
		seeds.Color = Color3.fromRGB(200, 180, 100)
		seeds.Material = Enum.Material.SmoothPlastic
		seeds.Anchored = true
		seeds.Parent = shack

		local seedHighlight = Instance.new("Highlight")
		seedHighlight.FillColor = Color3.fromRGB(200, 180, 100)
		seedHighlight.FillTransparency = 0.6
		seedHighlight.Parent = seeds

		local seedBillboard = Instance.new("BillboardGui")
		seedBillboard.Size = UDim2.new(0, 70, 0, 25)
		seedBillboard.StudsOffset = Vector3.new(0, 1.5, 0)
		seedBillboard.Parent = seeds

		local seedLabel = Instance.new("TextLabel")
		seedLabel.Size = UDim2.new(1, 0, 1, 0)
		seedLabel.BackgroundTransparency = 1
		seedLabel.Text = "SEEDS"
		seedLabel.TextColor3 = Color3.fromRGB(200, 180, 100)
		seedLabel.TextStrokeTransparency = 0
		seedLabel.Font = Enum.Font.GothamBold
		seedLabel.TextScaled = true
		seedLabel.Parent = seedBillboard

		-- Description sign inside
		if specialDesc then
			local descSign = Instance.new("Part")
			descSign.Name = "DescSign"
			descSign.Size = Vector3.new(10, 5, 0.3)
			descSign.Position = basePos + Vector3.new(0, 6, -7)
			descSign.Color = Color3.fromRGB(60, 50, 40)
			descSign.Material = Enum.Material.Wood
			descSign.Anchored = true
			descSign.Parent = shack

			local descGui = Instance.new("SurfaceGui")
			descGui.Face = Enum.NormalId.Front
			descGui.Parent = descSign

			local descLabel = Instance.new("TextLabel")
			descLabel.Size = UDim2.new(1, 0, 1, 0)
			descLabel.BackgroundTransparency = 1
			descLabel.Text = specialDesc
			descLabel.TextColor3 = Color3.new(1, 1, 1)
			descLabel.Font = Enum.Font.Gotham
			descLabel.TextScaled = true
			descLabel.TextWrapped = true
			descLabel.Parent = descGui
		end

		shack.Parent = Workspace
		print("[World] Created reward shack:", name, "at", basePos)
		return shack
	end

	-- CHAPTER REWARD SHACKS (one per chapter!)
	local chapterShacks = {
		-- Chapter 1: Floor 7½ has goodies INSIDE the building already
		-- Chapter 2: Survivor's Camp (near spawn)
		{ pos = Vector3.new(35, 0, 5), name = "Survivor's Camp", chapter = 2, color = Color3.fromRGB(100, 255, 100), desc = "Welcome survivor!\nGrab supplies and\nstay alive!" },
		-- Chapter 3: Forest Guardian
		{ pos = Vector3.new(80, 8, 320), name = "Forest Guardian", chapter = 3, color = Color3.fromRGB(50, 200, 100), desc = "The forest provides.\nTake what you need." },
		-- Chapter 4: Frozen Peaks
		{ pos = Vector3.new(420, 40, -30), name = "Mountain Summit", chapter = 4, color = Color3.fromRGB(150, 200, 255), desc = "Warm yourself here.\nThe cold is deadly." },
		-- Chapter 5: Pirate Cove
		{ pos = Vector3.new(-430, 0, 100), name = "Pet Sanctuary", chapter = 5, color = Color3.fromRGB(255, 150, 50), desc = "Elder Martha's cache.\nSave the pets!" },
		-- Chapter 6: Prophecy Stone
		{ pos = Vector3.new(25, 0, -120), name = "Prophecy Shrine", chapter = 6, color = Color3.fromRGB(200, 100, 255), desc = "The final truth.\nYou are ready." },
	}

	for _, shackData in chapterShacks do
		createRewardShack(shackData.pos, shackData.name, shackData.chapter, shackData.color, shackData.desc)
	end

	-- RADIO TOWER SHACKS (near every radio tower!)
	local radioTowerShacks = {
		{ pos = Vector3.new(220, 0, 120), name = "Radio Station Alpha" },
		{ pos = Vector3.new(-80, 0, 320), name = "Broadcast Hub" },
		{ pos = Vector3.new(1820, 0, 120), name = "Frozen Radio" },
		{ pos = Vector3.new(2520, 0, -280), name = "Arctic Signal" },
		{ pos = Vector3.new(1520, 0, 1820), name = "Desert Relay" },
		{ pos = Vector3.new(2220, 0, 2020), name = "Oasis Station" },
		{ pos = Vector3.new(-1980, 0, 1520), name = "Volcanic Radio" },
		{ pos = Vector3.new(-2480, 0, 1020), name = "Ember Broadcast" },
		{ pos = Vector3.new(-1480, 0, -1180), name = "Swamp Signal" },
		{ pos = Vector3.new(-1780, 0, -780), name = "Murky Tower" },
		{ pos = Vector3.new(20, 0, -1980), name = "Crystal Radio" },
		{ pos = Vector3.new(420, 0, -180), name = "Shadow Station" },
	}

	for _, shackData in radioTowerShacks do
		createRewardShack(shackData.pos, shackData.name, nil, Color3.fromRGB(255, 200, 100), "Radio supplies!\nListen for music.")
	end

	-- MOUNTAIN TOP SHACKS (at high elevations!)
	local mountainShacks = {
		{ pos = Vector3.new(350, 200, 370), name = "Peak Refuge" },  -- Near observatory
		{ pos = Vector3.new(2200, 150, 200), name = "Ice Peak Cabin" },  -- Ice fortress area
		{ pos = Vector3.new(-2300, 100, 1300), name = "Volcanic Overlook" },  -- Obsidian tower
		{ pos = Vector3.new(800, 80, -1500), name = "Crystal Heights" },  -- Near crystal spire
	}

	for _, shackData in mountainShacks do
		createRewardShack(shackData.pos, shackData.name, nil, Color3.fromRGB(200, 220, 255), "Mountain refuge!\nRest and resupply.")
	end

	print("[World] Created", #chapterShacks, "chapter shacks")
	print("[World] Created", #radioTowerShacks, "radio tower shacks")
	print("[World] Created", #mountainShacks, "mountain top shacks")

	print("[World] ========================================")
	print("[World] EPIC WORLD GENERATED!")
	print("[World] - 6 distinct biomes")
	print("[World] - 5 fast travel portals")
	print("[World] - 8 waystones")
	print("[World] - 2000 biome-specific trees/plants")
	print("[World] - 60 abandoned structures")
	print("[World] - 50+ campfires")
	print("[World] - The Mertin-Flemmer building awaits...")
	print("[World] ========================================")
end

-- ==========================================
-- TERRAIN SYNC: Reposition objects after terrain is generated
-- ==========================================

local function syncObjectsToTerrain()
	print("[World] Syncing objects to actual terrain surface...")

	-- Find and reposition the spawn house
	local spawnHouse = Workspace:FindFirstChild("SpawnHouse")
	if spawnHouse and spawnHouse:IsA("Model") then
		local primaryPart = spawnHouse.PrimaryPart or spawnHouse:FindFirstChildWhichIsA("BasePart")
		if primaryPart then
			local x, z = 0, -30
			local actualY = getActualTerrainHeight(x, z)
			local currentY = primaryPart.Position.Y
			local deltaY = actualY - currentY + 1  -- +1 to sit on top

			-- Move entire model
			for _, part in spawnHouse:GetDescendants() do
				if part:IsA("BasePart") then
					part.Position = part.Position + Vector3.new(0, deltaY, 0)
				end
			end
			print("[World] Spawn house repositioned to Y=" .. actualY)
		end
	end

	-- Find and reposition the office building
	local building = Workspace:FindFirstChild("MertinFlemmerBuilding")
	if building and building:IsA("Model") then
		local x, z = 150, -100
		local actualY = getActualTerrainHeight(x, z)

		for _, part in building:GetDescendants() do
			if part:IsA("BasePart") then
				-- Get part's current height relative to ground
				local relativeY = part.Position.Y
				-- Reposition based on actual terrain
				part.Position = Vector3.new(part.Position.X, relativeY + actualY, part.Position.Z)
			end
		end
		print("[World] Office building repositioned to terrain Y=" .. actualY)
	end

	print("[World] Terrain sync complete!")
end

-- Wait for AlpineTerrain to finish, then sync
local function waitForTerrainAndSync()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	-- Wait for TerrainReady event
	local terrainReady = ReplicatedStorage:FindFirstChild("TerrainReady")
	if terrainReady then
		print("[World] Waiting for AlpineTerrain to generate voxels...")
		terrainReady.Event:Wait()
		print("[World] Terrain ready! Syncing objects...")

		-- Give terrain a moment to fully settle
		task.wait(1)

		-- Sync objects to actual terrain
		syncObjectsToTerrain()
	else
		print("[World] WARNING: TerrainReady event not found, skipping sync")
	end
end

-- ==========================================
-- MAIN: Wait for terrain FIRST, then generate world
-- ==========================================

local function main()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	-- WAIT for AlpineTerrain to finish BEFORE generating anything
	print("[World] Waiting for AlpineTerrain to generate voxels...")
	local terrainReady = ReplicatedStorage:WaitForChild("TerrainReady", 30)
	if terrainReady then
		terrainReady.Event:Wait()
		print("[World] Terrain ready! Now generating world objects...")
		task.wait(1)  -- Let terrain fully settle
	else
		print("[World] WARNING: TerrainReady not found, proceeding anyway")
	end

	-- NOW generate world (terrain exists, raycast will work)
	generateWorld()

	-- Sync critical objects to actual terrain surface
	syncObjectsToTerrain()
end

main()
