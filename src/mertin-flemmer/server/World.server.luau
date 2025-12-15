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
local function createGround()
	print("[World] Creating epic terrain...")

	-- Main ground for each biome region
	local biomeGrounds = {}

	-- Create one massive ground base (thick to prevent fall-through)
	local ground = Instance.new("Part")
	ground.Name = "Ground_Main"
	ground.Size = Vector3.new(WORLD_SIZE * 2.5, 20, WORLD_SIZE * 2.5)
	ground.Position = Vector3.new(0, -10, 0) -- Top surface at y=0
	ground.Color = BIOMES.FOREST.groundColor
	ground.Material = BIOMES.FOREST.material
	ground.Anchored = true
	ground.CanCollide = true
	ground.Parent = Workspace
	biomeGrounds["MAIN"] = ground

	print("[World] Main ground created - size:", ground.Size, "at", ground.Position)

	-- Mountains in different biomes
	local mountainPositions = {
		-- Frozen mountains (north)
		{ pos = Vector3.new(2000, 0, 0), height = 400, biome = BIOMES.SNOW },
		{ pos = Vector3.new(2500, 0, 500), height = 300, biome = BIOMES.SNOW },
		{ pos = Vector3.new(1800, 0, -400), height = 350, biome = BIOMES.SNOW },
		-- Volcanic mountains (west)
		{ pos = Vector3.new(-2000, 0, 1500), height = 500, biome = BIOMES.VOLCANIC },
		{ pos = Vector3.new(-2500, 0, 1000), height = 400, biome = BIOMES.VOLCANIC },
		-- Desert mesas (east)
		{ pos = Vector3.new(1500, 0, 2000), height = 150, biome = BIOMES.DESERT },
		{ pos = Vector3.new(2000, 0, 2500), height = 100, biome = BIOMES.DESERT },
	}

	for i, mtn in mountainPositions do
		local mountain = Instance.new("Part")
		mountain.Name = "Mountain_" .. i
		mountain.Size = Vector3.new(mtn.height * 2, mtn.height, mtn.height * 2)
		mountain.Position = mtn.pos + Vector3.new(0, mtn.height / 2 - 10, 0)
		mountain.Color = mtn.biome.groundColor
		mountain.Material = mtn.biome.material
		mountain.Anchored = true
		mountain.Parent = Workspace

		-- Snow cap for tall mountains
		if mtn.height > 300 then
			local snowCap = Instance.new("Part")
			snowCap.Name = "SnowCap_" .. i
			snowCap.Size = Vector3.new(mtn.height * 0.8, mtn.height * 0.3, mtn.height * 0.8)
			snowCap.Position = mtn.pos + Vector3.new(0, mtn.height * 0.7, 0)
			snowCap.Color = Color3.fromRGB(255, 255, 255)
			snowCap.Material = Enum.Material.Snow
			snowCap.Anchored = true
			snowCap.Parent = Workspace
		end
	end

	-- Hills and terrain variation - EPIC rolling landscape
	local hillFolder = Instance.new("Folder")
	hillFolder.Name = "Hills"

	for i = 1, 200 do  -- Plenty of rolling hills!
		local x = (math.random() - 0.5) * WORLD_SIZE * 1.8  -- Stay within terrain bounds
		local z = (math.random() - 0.5) * WORLD_SIZE * 1.8
		local biome = getBiome(x, z)

		local hill = Instance.new("Part")
		hill.Name = "Hill_" .. i
		hill.Shape = Enum.PartType.Ball
		local size = 20 + math.random() * 80
		hill.Size = Vector3.new(size, size * 0.5, size)
		hill.Position = Vector3.new(x, -size * 0.2, z)
		hill.Color = biome.groundColor
		hill.Material = biome.material
		hill.Anchored = true
		hill.CastShadow = false  -- Performance boost
		hill.Parent = hillFolder

		-- Yield every 50 hills to prevent lag
		if i % 50 == 0 then task.wait() end
	end

	hillFolder.Parent = Workspace

	-- Rivers (long blue parts)
	local rivers = {
		{ start = Vector3.new(0, 0, 0), endPos = Vector3.new(1500, 0, 1500) },
		{ start = Vector3.new(-500, 0, 200), endPos = Vector3.new(-2000, 0, -1000) },
		{ start = Vector3.new(200, 0, -300), endPos = Vector3.new(2000, 0, -2000) },
	}

	for i, river in rivers do
		local direction = (river.endPos - river.start)
		local length = direction.Magnitude
		local midpoint = river.start + direction / 2

		local riverPart = Instance.new("Part")
		riverPart.Name = "River_" .. i
		riverPart.Size = Vector3.new(30, 3, length)
		riverPart.CFrame = CFrame.lookAt(midpoint, river.endPos) * CFrame.new(0, -1, 0)
		riverPart.Color = Color3.fromRGB(40, 80, 120)
		riverPart.Material = Enum.Material.Water
		riverPart.Transparency = 0.3
		riverPart.Anchored = true
		riverPart.CanCollide = false
		riverPart.Parent = Workspace
	end

	-- Lava rivers in volcanic biome
	local lavaRiver = Instance.new("Part")
	lavaRiver.Name = "LavaRiver"
	lavaRiver.Size = Vector3.new(40, 5, 800)
	lavaRiver.Position = Vector3.new(-2200, 1, 1200)
	lavaRiver.Color = Color3.fromRGB(255, 100, 0)
	lavaRiver.Material = Enum.Material.Neon
	lavaRiver.Anchored = true
	lavaRiver.Parent = Workspace

	local lavaLight = Instance.new("PointLight")
	lavaLight.Color = Color3.fromRGB(255, 150, 50)
	lavaLight.Brightness = 3
	lavaLight.Range = 60
	lavaLight.Parent = lavaRiver

	print("[World] Terrain created with mountains, rivers, and varied biomes")
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
-- 20 stories tall, but only floor 7.5 is accessible with very low ceilings
local function createOfficeBuilding75(position: Vector3)
	local Players = game:GetService("Players")
	local building = Instance.new("Model")
	building.Name = "MertinFlemmerBuilding"

	local buildingWidth = 80
	local buildingDepth = 50
	local floorHeight = 14 -- Normal floor height
	local totalFloors = 20 -- 20 story building
	local floor75Height = 4 -- VERY low ceiling - you MUST crouch! (Being John Malkovich)
	local lobbyHeight = 20 -- Grand lobby

	-- Calculate positions
	local floor7Top = 7 * floorHeight
	local floor75Bottom = floor7Top
	local floor75Top = floor75Bottom + floor75Height
	local totalHeight = totalFloors * floorHeight

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

	local lobbyGui = Instance.new("SurfaceGui")
	lobbyGui.Face = Enum.NormalId.Front
	lobbyGui.Parent = lobbySign

	local lobbyText = Instance.new("TextLabel")
	lobbyText.Size = UDim2.new(1, 0, 1, 0)
	lobbyText.BackgroundTransparency = 1
	lobbyText.Text = "MERTIN & FLEMMER LLP"
	lobbyText.TextColor3 = Color3.fromRGB(220, 200, 160)
	lobbyText.Font = Enum.Font.Antique
	lobbyText.TextScaled = true
	lobbyText.Parent = lobbyGui

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

	-- Elevator button panel
	local buttonPanel = Instance.new("Part")
	buttonPanel.Name = "ElevatorButton"
	buttonPanel.Size = Vector3.new(1.5, 3, 0.5)
	buttonPanel.Position = position + Vector3.new(-20, 5, -buildingDepth / 2 + 5)
	buttonPanel.Color = Color3.fromRGB(60, 60, 65)
	buttonPanel.Material = Enum.Material.Metal
	buttonPanel.Anchored = true
	buttonPanel.Parent = building

	local buttonGui = Instance.new("SurfaceGui")
	buttonGui.Face = Enum.NormalId.Front
	buttonGui.Parent = buttonPanel

	local buttonText = Instance.new("TextLabel")
	buttonText.Size = UDim2.new(1, 0, 1, 0)
	buttonText.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	buttonText.Text = "7½\n[TOUCH]"
	buttonText.TextColor3 = Color3.fromRGB(255, 200, 100)
	buttonText.Font = Enum.Font.Code
	buttonText.TextScaled = true
	buttonText.Parent = buttonGui

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

	-- Exit elevator on floor 7.5 (returns to lobby)
	local exitDoor = Instance.new("Part")
	exitDoor.Name = "ExitElevator"
	exitDoor.Size = Vector3.new(4, floor75Height - 1.5, 1)
	exitDoor.Position = position + Vector3.new(-interiorWidth / 2 + 3, floor75Bottom + floor75Height / 2, 0)
	exitDoor.Color = Color3.fromRGB(180, 175, 165)
	exitDoor.Material = Enum.Material.Metal
	exitDoor.Anchored = true
	exitDoor.Parent = building

	local exitGui = Instance.new("SurfaceGui")
	exitGui.Face = Enum.NormalId.Back
	exitGui.Parent = exitDoor

	local exitText = Instance.new("TextLabel")
	exitText.Size = UDim2.new(1, 0, 1, 0)
	exitText.BackgroundTransparency = 1
	exitText.Text = "EXIT\n[TOUCH]"
	exitText.TextColor3 = Color3.fromRGB(255, 100, 100)
	exitText.Font = Enum.Font.GothamBold
	exitText.TextScaled = true
	exitText.Parent = exitGui

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

	local sign75Gui = Instance.new("SurfaceGui")
	sign75Gui.Face = Enum.NormalId.Front
	sign75Gui.Parent = floor75Sign

	local sign75Text = Instance.new("TextLabel")
	sign75Text.Size = UDim2.new(1, 0, 1, 0)
	sign75Text.BackgroundTransparency = 1
	sign75Text.Text = "FLOOR 7½"
	sign75Text.TextColor3 = Color3.fromRGB(80, 60, 40)
	sign75Text.Font = Enum.Font.Antique
	sign75Text.TextScaled = true
	sign75Text.Parent = sign75Gui

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

	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = sign

	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = name
	signText.TextColor3 = Color3.fromRGB(200, 180, 140)
	signText.Font = Enum.Font.Antique
	signText.TextScaled = true
	signText.Parent = signGui

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

	local nameGui = Instance.new("SurfaceGui")
	nameGui.Face = Enum.NormalId.Front
	nameGui.Parent = nameSign

	local nameText = Instance.new("TextLabel")
	nameText.Size = UDim2.new(1, 0, 1, 0)
	nameText.BackgroundTransparency = 1
	nameText.Text = name
	nameText.TextColor3 = Color3.fromRGB(180, 160, 120)
	nameText.Font = Enum.Font.Fantasy
	nameText.TextScaled = true
	nameText.Parent = nameGui

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

	-- Get terrain height and position house WELL ABOVE terrain
	local terrainHeight = Shared.getTerrainHeight(position.X, position.Z)
	local baseY = math.max(terrainHeight, 0) + 5  -- 5 studs above terrain to be safe
	position = Vector3.new(position.X, baseY, position.Z)

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

	-- Spawn location INSIDE the house
	local spawnPoint = Instance.new("SpawnLocation")
	spawnPoint.Name = "MainSpawn"
	spawnPoint.Size = Vector3.new(6, 1, 6)
	spawnPoint.Position = position + Vector3.new(0, 1.5, 0)
	spawnPoint.Color = Color3.fromRGB(100, 150, 100)
	spawnPoint.Material = Enum.Material.SmoothPlastic
	spawnPoint.Transparency = 0.5
	spawnPoint.Anchored = true
	spawnPoint.CanCollide = false
	spawnPoint.Neutral = true
	spawnPoint.Parent = house

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

	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = sign

	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = "SURVIVOR'S CABIN"
	signText.TextColor3 = Color3.fromRGB(200, 180, 140)
	signText.Font = Enum.Font.Antique
	signText.TextScaled = true
	signText.Parent = signGui

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
	createOfficeBuilding75(Vector3.new(150, 0, -100))

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

	-- Special locations for each biome
	-- Frozen Wastes - ice fortress ruins
	local iceFort = Instance.new("Part")
	iceFort.Name = "IceFortress"
	iceFort.Size = Vector3.new(100, 50, 100)
	iceFort.Position = Vector3.new(2200, 25, 200)
	iceFort.Color = Color3.fromRGB(200, 220, 255)
	iceFort.Material = Enum.Material.Ice
	iceFort.Transparency = 0.3
	iceFort.Anchored = true
	iceFort.Parent = Workspace

	-- Desert - ancient temple
	local temple = Instance.new("Part")
	temple.Name = "AncientTemple"
	temple.Size = Vector3.new(80, 40, 80)
	temple.Position = Vector3.new(1800, 20, 2200)
	temple.Color = Color3.fromRGB(220, 200, 160)
	temple.Material = Enum.Material.Sandstone
	temple.Anchored = true
	temple.Parent = Workspace

	-- Volcanic - obsidian tower
	local obsidianTower = Instance.new("Part")
	obsidianTower.Name = "ObsidianTower"
	obsidianTower.Size = Vector3.new(30, 120, 30)
	obsidianTower.Position = Vector3.new(-2300, 60, 1300)
	obsidianTower.Color = Color3.fromRGB(20, 20, 25)
	obsidianTower.Material = Enum.Material.Rock
	obsidianTower.Anchored = true
	obsidianTower.Parent = Workspace

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

		local signGui = Instance.new("SurfaceGui")
		signGui.Face = Enum.NormalId.Front
		signGui.Parent = sign

		local signText = Instance.new("TextLabel")
		signText.Size = UDim2.new(1, 0, 1, 0)
		signText.BackgroundTransparency = 1
		signText.Text = merchant.name
		signText.TextColor3 = Color3.fromRGB(255, 220, 150)
		signText.Font = Enum.Font.Fantasy
		signText.TextScaled = true
		signText.Parent = signGui

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

	local alchemySignGui = Instance.new("SurfaceGui")
	alchemySignGui.Face = Enum.NormalId.Front
	alchemySignGui.Parent = alchemySign

	local alchemySignText = Instance.new("TextLabel")
	alchemySignText.Size = UDim2.new(1, 0, 1, 0)
	alchemySignText.BackgroundTransparency = 1
	alchemySignText.Text = "ALCHEMY"
	alchemySignText.TextColor3 = Color3.fromRGB(100, 255, 150)
	alchemySignText.Font = Enum.Font.Fantasy
	alchemySignText.TextScaled = true
	alchemySignText.Parent = alchemySignGui

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

generateWorld()
