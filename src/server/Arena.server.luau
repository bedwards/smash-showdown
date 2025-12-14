--!strict
-- Arena generation for Smash Showdown
-- Creates the battle arena at runtime

local Workspace = game:GetService("Workspace")

local function createPart(name: string, size: Vector3, position: Vector3, color: Color3, anchored: boolean): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Anchored = anchored
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = Workspace
	return part
end

local function buildArena()
	print("[Arena] Building arena...")

	-- Arena folder
	local arena = Instance.new("Folder")
	arena.Name = "Arena"
	arena.Parent = Workspace

	-- Main floor (rectangular court like Racket Rivals)
	local floor = createPart(
		"Floor",
		Vector3.new(80, 2, 50),
		Vector3.new(0, -1, 0),
		Color3.fromRGB(40, 40, 50),
		true
	)
	floor.Parent = arena

	-- Center line
	local centerLine = createPart(
		"CenterLine",
		Vector3.new(0.5, 2.1, 50),
		Vector3.new(0, -0.9, 0),
		Color3.fromRGB(255, 200, 50),
		true
	)
	centerLine.Parent = arena

	-- Side walls (bouncy walls like Racket Rivals)
	local wallHeight = 15
	local wallThickness = 2

	local leftWall = createPart(
		"LeftWall",
		Vector3.new(80, wallHeight, wallThickness),
		Vector3.new(0, wallHeight/2 - 1, -26),
		Color3.fromRGB(60, 60, 80),
		true
	)
	leftWall.Parent = arena

	local rightWall = createPart(
		"RightWall",
		Vector3.new(80, wallHeight, wallThickness),
		Vector3.new(0, wallHeight/2 - 1, 26),
		Color3.fromRGB(60, 60, 80),
		true
	)
	rightWall.Parent = arena

	-- Back walls (goal zones)
	local backWallLeft = createPart(
		"BackWallLeft",
		Vector3.new(wallThickness, wallHeight, 50),
		Vector3.new(-41, wallHeight/2 - 1, 0),
		Color3.fromRGB(200, 50, 50),
		true
	)
	backWallLeft.Parent = arena

	local backWallRight = createPart(
		"BackWallRight",
		Vector3.new(wallThickness, wallHeight, 50),
		Vector3.new(41, wallHeight/2 - 1, 0),
		Color3.fromRGB(50, 100, 200),
		true
	)
	backWallRight.Parent = arena

	-- Spawn points
	local spawn1 = Instance.new("SpawnLocation")
	spawn1.Name = "Spawn1"
	spawn1.Size = Vector3.new(6, 1, 6)
	spawn1.Position = Vector3.new(-25, 0.5, 0)
	spawn1.Color = Color3.fromRGB(200, 50, 50)
	spawn1.Anchored = true
	spawn1.CanCollide = false
	spawn1.Transparency = 0.5
	spawn1.Parent = arena

	local spawn2 = Instance.new("SpawnLocation")
	spawn2.Name = "Spawn2"
	spawn2.Size = Vector3.new(6, 1, 6)
	spawn2.Position = Vector3.new(25, 0.5, 0)
	spawn2.Color = Color3.fromRGB(50, 100, 200)
	spawn2.Anchored = true
	spawn2.CanCollide = false
	spawn2.Transparency = 0.5
	spawn2.Parent = arena

	-- Lighting
	local Lighting = game:GetService("Lighting")
	Lighting.Ambient = Color3.fromRGB(100, 100, 120)
	Lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 120)
	Lighting.Brightness = 2
	Lighting.ClockTime = 14

	print("[Arena] Arena built!")
end

-- Remove default spawn and baseplate
for _, obj in Workspace:GetChildren() do
	if obj:IsA("SpawnLocation") or obj.Name == "Baseplate" then
		obj:Destroy()
	end
end

buildArena()
