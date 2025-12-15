--!strict
-- World generation for Mertin-Flemmer
-- Creates the mysterious forest/building environment

local Workspace = game:GetService("Workspace")

-- Configuration
local WORLD_SIZE = 200
local TREE_COUNT = 80
local BUILDING_COUNT = 5

-- Create ground
local function createGround()
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Size = Vector3.new(WORLD_SIZE * 2, 2, WORLD_SIZE * 2)
	ground.Position = Vector3.new(0, -1, 0)
	ground.Color = Color3.fromRGB(30, 45, 25)
	ground.Material = Enum.Material.Grass
	ground.Anchored = true
	ground.Parent = Workspace

	-- Add some terrain variation
	for i = 1, 20 do
		local hill = Instance.new("Part")
		hill.Name = "Hill_" .. i
		hill.Shape = Enum.PartType.Ball
		hill.Size = Vector3.new(30, 15, 30) * (0.5 + math.random())
		hill.Position = Vector3.new(
			math.random(-WORLD_SIZE, WORLD_SIZE),
			-5,
			math.random(-WORLD_SIZE, WORLD_SIZE)
		)
		hill.Color = Color3.fromRGB(35, 50, 30)
		hill.Material = Enum.Material.Grass
		hill.Anchored = true
		hill.Parent = Workspace
	end

	return ground
end

-- Create a tree
local function createTree(position: Vector3)
	local tree = Instance.new("Model")
	tree.Name = "Tree"

	-- Trunk
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(2, 15 + math.random() * 10, 2)
	trunk.Position = position + Vector3.new(0, trunk.Size.Y / 2, 0)
	trunk.Color = Color3.fromRGB(60, 40, 30)
	trunk.Material = Enum.Material.Wood
	trunk.Anchored = true
	trunk.Parent = tree

	-- Leaves (multiple spheres for fuller look)
	for j = 1, 3 do
		local leaves = Instance.new("Part")
		leaves.Name = "Leaves_" .. j
		leaves.Shape = Enum.PartType.Ball
		local size = 8 + math.random() * 6
		leaves.Size = Vector3.new(size, size * 0.8, size)
		leaves.Position = trunk.Position + Vector3.new(
			(math.random() - 0.5) * 4,
			trunk.Size.Y / 2 + math.random() * 3,
			(math.random() - 0.5) * 4
		)
		leaves.Color = Color3.fromRGB(20 + math.random(20), 50 + math.random(30), 20 + math.random(20))
		leaves.Material = Enum.Material.Grass
		leaves.Anchored = true
		leaves.CanCollide = false
		leaves.Parent = tree
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

	-- Spawn point inside
	local spawnPoint = Instance.new("SpawnLocation")
	spawnPoint.Size = Vector3.new(4, 1, 4)
	spawnPoint.Position = position + Vector3.new(0, 1, 0)
	spawnPoint.Transparency = 1
	spawnPoint.Anchored = true
	spawnPoint.CanCollide = false
	spawnPoint.Parent = building

	building.Parent = Workspace
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

-- Generate the world
local function generateWorld()
	print("[World] Generating mysterious forest...")

	-- Clear existing
	for _, obj in Workspace:GetChildren() do
		if obj.Name ~= "Camera" and obj.Name ~= "Terrain" then
			obj:Destroy()
		end
	end

	-- Create ground
	createGround()

	-- Create trees
	for i = 1, TREE_COUNT do
		local pos = Vector3.new(
			math.random(-WORLD_SIZE, WORLD_SIZE),
			0,
			math.random(-WORLD_SIZE, WORLD_SIZE)
		)
		-- Avoid center spawn area
		if pos.Magnitude > 30 then
			createTree(pos)
		end
	end

	-- Create buildings
	for i = 1, BUILDING_COUNT do
		local angle = (i / BUILDING_COUNT) * math.pi * 2
		local distance = 60 + math.random() * 80
		local pos = Vector3.new(
			math.cos(angle) * distance,
			0,
			math.sin(angle) * distance
		)
		createBuilding(pos)
	end

	-- Create central campfire (safe zone)
	createCampfire(Vector3.new(0, 0, 0))

	-- Create additional campfires
	for i = 1, 3 do
		local angle = (i / 3) * math.pi * 2
		local distance = 80 + math.random() * 40
		createCampfire(Vector3.new(
			math.cos(angle) * distance,
			0,
			math.sin(angle) * distance
		))
	end

	print("[World] Forest generated!", TREE_COUNT, "trees,", BUILDING_COUNT, "buildings")
end

generateWorld()
