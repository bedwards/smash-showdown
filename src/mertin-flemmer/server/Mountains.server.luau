--!strict
-- MOUNTAINS for Mertin-Flemmer
-- Real terrain mountains with peaks, valleys, caves, and snow caps

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Terrain = Workspace:WaitForChild("Terrain") :: Terrain

-- ==========================================
-- MOUNTAIN CONFIGURATION
-- ==========================================

local MOUNTAINS = {
	-- THE FROZEN PEAKS - Northern mountain range (where Signal Part #2 is)
	{
		name = "Frozen Peaks",
		basePosition = Vector3.new(300, 0, -400),
		peaks = {
			{ offset = Vector3.new(0, 0, 0), height = 350, radius = 120 },
			{ offset = Vector3.new(-150, 0, 50), height = 280, radius = 100 },
			{ offset = Vector3.new(100, 0, 80), height = 220, radius = 80 },
			{ offset = Vector3.new(-80, 0, -100), height = 300, radius = 90 },
			{ offset = Vector3.new(180, 0, -50), height = 250, radius = 85 },
		},
		snowLineHeight = 200,
		hasCaves = true,
		material = Enum.Material.Rock,
		snowMaterial = Enum.Material.Snow,
	},

	-- SHADOW MOUNTAINS - Western dark mountains
	{
		name = "Shadow Mountains",
		basePosition = Vector3.new(-500, 0, 100),
		peaks = {
			{ offset = Vector3.new(0, 0, 0), height = 280, radius = 100 },
			{ offset = Vector3.new(-120, 0, -80), height = 320, radius = 110 },
			{ offset = Vector3.new(80, 0, 100), height = 200, radius = 70 },
			{ offset = Vector3.new(-50, 0, 150), height = 240, radius = 85 },
		},
		snowLineHeight = 250,
		hasCaves = true,
		material = Enum.Material.Basalt,
		snowMaterial = Enum.Material.Snow,
	},

	-- EMBER RIDGE - Eastern volcanic mountains
	{
		name = "Ember Ridge",
		basePosition = Vector3.new(600, 0, 200),
		peaks = {
			{ offset = Vector3.new(0, 0, 0), height = 260, radius = 90 },
			{ offset = Vector3.new(-100, 0, 60), height = 300, radius = 100 }, -- Volcano!
			{ offset = Vector3.new(70, 0, -80), height = 180, radius = 70 },
		},
		snowLineHeight = 400, -- No snow on volcanic mountains
		hasCaves = true,
		material = Enum.Material.CrackedLava,
		snowMaterial = Enum.Material.Rock,
	},

	-- THE GIANTS - Massive southern peaks
	{
		name = "The Giants",
		basePosition = Vector3.new(0, 0, 500),
		peaks = {
			{ offset = Vector3.new(0, 0, 0), height = 400, radius = 150 }, -- Tallest peak!
			{ offset = Vector3.new(-200, 0, 50), height = 350, radius = 120 },
			{ offset = Vector3.new(180, 0, -30), height = 320, radius = 110 },
			{ offset = Vector3.new(-100, 0, 150), height = 280, radius = 90 },
			{ offset = Vector3.new(100, 0, 200), height = 300, radius = 100 },
			{ offset = Vector3.new(0, 0, -150), height = 250, radius = 80 },
		},
		snowLineHeight = 180,
		hasCaves = true,
		material = Enum.Material.Rock,
		snowMaterial = Enum.Material.Glacier,
	},

	-- BROKEN HILLS - Smaller hills near spawn for early exploration
	{
		name = "Broken Hills",
		basePosition = Vector3.new(-150, 0, -200),
		peaks = {
			{ offset = Vector3.new(0, 0, 0), height = 80, radius = 50 },
			{ offset = Vector3.new(-60, 0, 40), height = 60, radius = 40 },
			{ offset = Vector3.new(50, 0, -30), height = 70, radius = 45 },
			{ offset = Vector3.new(-30, 0, -70), height = 50, radius = 35 },
		},
		snowLineHeight = 500, -- No snow
		hasCaves = false,
		material = Enum.Material.Ground,
		snowMaterial = Enum.Material.Ground,
	},
}

-- ==========================================
-- TERRAIN GENERATION FUNCTIONS
-- ==========================================

-- Fill a sphere of terrain
local function fillSphere(center: Vector3, radius: number, material: Enum.Material)
	local resolution = 4
	local region = Region3.new(
		center - Vector3.new(radius, radius, radius),
		center + Vector3.new(radius, radius, radius)
	):ExpandToGrid(resolution)

	Terrain:FillBall(center, radius, material)
end

-- Create a mountain peak with natural shape
local function createPeak(basePos: Vector3, height: number, radius: number, material: Enum.Material, snowMaterial: Enum.Material, snowLine: number)
	print("[Mountains] Creating peak at", basePos, "height:", height)

	-- Build mountain from bottom to top with decreasing radius
	local layers = math.ceil(height / 8)

	for i = 0, layers do
		local progress = i / layers
		local y = progress * height
		local currentRadius = radius * (1 - progress * 0.85) -- Taper toward top

		-- Add some variation for natural look
		local variation = math.sin(i * 0.5) * (radius * 0.1)
		currentRadius = currentRadius + variation

		if currentRadius > 2 then
			local layerPos = basePos + Vector3.new(0, y, 0)

			-- Choose material based on height
			local layerMaterial = material
			if y > snowLine then
				layerMaterial = snowMaterial
			end

			-- Fill this layer
			Terrain:FillBall(layerPos, currentRadius, layerMaterial)

			-- Add some offset balls for natural bumpy look
			if i % 3 == 0 and currentRadius > 10 then
				for _ = 1, 3 do
					local offsetAngle = math.random() * math.pi * 2
					local offsetDist = currentRadius * 0.3
					local offsetPos = layerPos + Vector3.new(
						math.cos(offsetAngle) * offsetDist,
						math.random(-5, 5),
						math.sin(offsetAngle) * offsetDist
					)
					Terrain:FillBall(offsetPos, currentRadius * 0.4, layerMaterial)
				end
			end
		end
	end

	-- Add rocky outcrops near the top
	for _ = 1, 5 do
		local angle = math.random() * math.pi * 2
		local dist = radius * 0.2
		local rockHeight = height * (0.7 + math.random() * 0.25)
		local rockPos = basePos + Vector3.new(
			math.cos(angle) * dist,
			rockHeight,
			math.sin(angle) * dist
		)
		Terrain:FillBall(rockPos, 8 + math.random() * 8, snowMaterial)
	end
end

-- Create a cave entrance in a mountain
local function createCave(mountainBase: Vector3, height: number, radius: number)
	-- Cave entrance at base of mountain
	local entranceHeight = 10 + math.random() * 20
	local entranceAngle = math.random() * math.pi * 2

	local entrancePos = mountainBase + Vector3.new(
		math.cos(entranceAngle) * (radius * 0.8),
		entranceHeight,
		math.sin(entranceAngle) * (radius * 0.8)
	)

	-- Carve entrance
	local entranceRadius = 8 + math.random() * 5
	Terrain:FillBall(entrancePos, entranceRadius, Enum.Material.Air)

	-- Carve tunnel going into mountain
	local tunnelLength = 40 + math.random() * 30
	local tunnelDir = (mountainBase - entrancePos).Unit

	for i = 1, math.ceil(tunnelLength / 5) do
		local tunnelPos = entrancePos + tunnelDir * (i * 5)
		-- Tunnel goes slightly up/down
		tunnelPos = tunnelPos + Vector3.new(0, math.sin(i * 0.3) * 3, 0)
		local tunnelRadius = entranceRadius * (1 - i / (tunnelLength / 3))
		if tunnelRadius > 3 then
			Terrain:FillBall(tunnelPos, tunnelRadius, Enum.Material.Air)
		end
	end

	-- Create cave chamber at end
	local chamberPos = entrancePos + tunnelDir * tunnelLength
	Terrain:FillBall(chamberPos, 15 + math.random() * 10, Enum.Material.Air)

	-- Add glowing crystals in cave (parts, not terrain)
	local crystal = Instance.new("Part")
	crystal.Name = "CaveCrystal"
	crystal.Size = Vector3.new(2, 6, 2)
	crystal.Position = chamberPos + Vector3.new(math.random(-5, 5), -5, math.random(-5, 5))
	crystal.Color = Color3.fromRGB(100, 200, 255)
	crystal.Material = Enum.Material.Neon
	crystal.Anchored = true
	crystal.Parent = workspace

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(100, 200, 255)
	light.Brightness = 2
	light.Range = 30
	light.Parent = crystal

	return entrancePos
end

-- Create ridge connecting two peaks
local function createRidge(peak1: Vector3, peak2: Vector3, height1: number, height2: number, material: Enum.Material)
	local direction = (peak2 - peak1)
	local distance = direction.Magnitude
	local segments = math.ceil(distance / 15)

	for i = 0, segments do
		local progress = i / segments
		local pos = peak1 + direction * progress

		-- Ridge height interpolates between peaks, with sag in middle
		local sagAmount = math.sin(progress * math.pi) * 0.3
		local ridgeHeight = height1 * (1 - progress) + height2 * progress
		ridgeHeight = ridgeHeight * (1 - sagAmount)

		local ridgePos = pos + Vector3.new(0, ridgeHeight * 0.7, 0)
		local ridgeRadius = 15 + math.sin(i * 0.8) * 5

		Terrain:FillBall(ridgePos, ridgeRadius, material)
	end
end

-- Create a valley between mountains
local function createValley(center: Vector3, length: number, width: number, depth: number)
	-- Carve out a valley
	local segments = math.ceil(length / 10)

	for i = 0, segments do
		local progress = i / segments
		local valleyPos = center + Vector3.new(
			(progress - 0.5) * length,
			-depth * math.sin(progress * math.pi),
			math.sin(progress * math.pi * 2) * width * 0.2
		)

		-- U-shaped valley
		Terrain:FillBall(valleyPos, width / 2, Enum.Material.Air)
	end

	-- Fill bottom with grass/ground
	for i = 0, segments do
		local progress = i / segments
		local floorPos = center + Vector3.new(
			(progress - 0.5) * length,
			-depth + 5,
			math.sin(progress * math.pi * 2) * width * 0.2
		)
		Terrain:FillBall(floorPos, width / 3, Enum.Material.Grass)
	end
end

-- ==========================================
-- MOUNTAIN RANGE BUILDER
-- ==========================================

local function buildMountainRange(rangeData: typeof(MOUNTAINS[1]))
	print("[Mountains] Building mountain range:", rangeData.name)

	local peakPositions: { Vector3 } = {}
	local peakHeights: { number } = {}

	-- Create each peak
	for i, peakData in rangeData.peaks do
		local peakPos = rangeData.basePosition + peakData.offset

		createPeak(
			peakPos,
			peakData.height,
			peakData.radius,
			rangeData.material,
			rangeData.snowMaterial,
			rangeData.snowLineHeight
		)

		table.insert(peakPositions, peakPos)
		table.insert(peakHeights, peakData.height)

		-- Small delay to prevent lag
		if i % 2 == 0 then
			task.wait(0.1)
		end
	end

	-- Create ridges connecting nearby peaks
	for i = 1, #peakPositions - 1 do
		local dist = (peakPositions[i] - peakPositions[i + 1]).Magnitude
		if dist < 250 then -- Only connect close peaks
			createRidge(
				peakPositions[i],
				peakPositions[i + 1],
				peakHeights[i],
				peakHeights[i + 1],
				rangeData.material
			)
		end
	end

	-- Create caves
	if rangeData.hasCaves then
		for i, peakData in rangeData.peaks do
			if peakData.height > 150 and math.random() < 0.6 then
				local peakPos = rangeData.basePosition + peakData.offset
				local caveEntrance = createCave(peakPos, peakData.height, peakData.radius)

				-- Mark cave entrance with sign
				local sign = Instance.new("Part")
				sign.Name = "CaveSign"
				sign.Size = Vector3.new(3, 2, 0.3)
				sign.Position = caveEntrance + Vector3.new(0, 5, 0)
				sign.Color = Color3.fromRGB(80, 55, 35)
				sign.Material = Enum.Material.Wood
				sign.Anchored = true
				sign.Parent = workspace

				-- Sign text on BOTH sides
				for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
					local gui = Instance.new("SurfaceGui")
					gui.Face = face
					gui.Parent = sign

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, 0, 1, 0)
					label.BackgroundTransparency = 1
					label.Text = "CAVE\nDANGER!"
					label.TextColor3 = Color3.fromRGB(255, 100, 100)
					label.Font = Enum.Font.GothamBold
					label.TextSize = 24
					label.Parent = gui
				end
			end
		end
	end

	-- Create name marker at highest peak
	local highestPeak = peakPositions[1]
	local highestHeight = peakHeights[1]
	for i, h in peakHeights do
		if h > highestHeight then
			highestHeight = h
			highestPeak = peakPositions[i]
		end
	end

	local nameMarker = Instance.new("Part")
	nameMarker.Name = "MountainMarker_" .. rangeData.name
	nameMarker.Size = Vector3.new(1, 1, 1)
	nameMarker.Position = highestPeak + Vector3.new(0, highestHeight + 20, 0)
	nameMarker.Transparency = 1
	nameMarker.Anchored = true
	nameMarker.CanCollide = false
	nameMarker.Parent = workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.Adornee = nameMarker
	billboard.Parent = nameMarker

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = rangeData.name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 32
	nameLabel.Parent = billboard

	print("[Mountains] Completed", rangeData.name, "with", #rangeData.peaks, "peaks")
end

-- ==========================================
-- CLIFFS AND ROCK FORMATIONS
-- ==========================================

local function createCliff(position: Vector3, height: number, width: number)
	-- Vertical cliff face
	for y = 0, height, 8 do
		local layerWidth = width * (1 - y / height * 0.2)
		Terrain:FillBlock(
			CFrame.new(position + Vector3.new(0, y, 0)),
			Vector3.new(layerWidth, 10, 15),
			Enum.Material.Rock
		)

		-- Add rocky protrusions
		if math.random() < 0.3 then
			local protrusion = position + Vector3.new(
				math.random(-5, 5),
				y,
				8 + math.random() * 5
			)
			Terrain:FillBall(protrusion, 6 + math.random() * 4, Enum.Material.Rock)
		end
	end
end

local function createRockFormation(position: Vector3)
	-- Cluster of large boulders
	local numRocks = 3 + math.random(4)

	for _ = 1, numRocks do
		local rockPos = position + Vector3.new(
			math.random(-20, 20),
			0,
			math.random(-20, 20)
		)
		local rockSize = 8 + math.random() * 12

		Terrain:FillBall(rockPos + Vector3.new(0, rockSize / 2, 0), rockSize, Enum.Material.Rock)
	end
end

-- ==========================================
-- INITIALIZE MOUNTAINS
-- ==========================================

local function buildAllMountains()
	print("[Mountains] ========================================")
	print("[Mountains] BUILDING MOUNTAIN RANGES")
	print("[Mountains] This will take a moment...")
	print("[Mountains] ========================================")

	-- Clear some space first
	task.wait(1)

	for i, rangeData in MOUNTAINS do
		buildMountainRange(rangeData)
		task.wait(0.5) -- Prevent lag
	end

	-- Add scattered rock formations
	-- NOTE: Avoid placing rocks near Mertin-Flemmer building (150, 0, -100)!
	print("[Mountains] Adding rock formations...")
	local rockLocations = {
		Vector3.new(150, 0, -300), -- Moved AWAY from building (was -150, too close to elevator!)
		Vector3.new(-250, 0, 300),
		Vector3.new(400, 0, -100),
		Vector3.new(-100, 0, -350),
		Vector3.new(250, 0, 350),
	}

	for _, pos in rockLocations do
		createRockFormation(pos)
	end

	-- Add some cliffs
	print("[Mountains] Adding cliffs...")
	createCliff(Vector3.new(-300, 0, -250), 80, 60)
	createCliff(Vector3.new(450, 0, 50), 100, 80)

	-- Create a dramatic valley
	print("[Mountains] Carving valley...")
	createValley(Vector3.new(200, 50, -200), 150, 40, 30)

	print("[Mountains] ========================================")
	print("[Mountains] MOUNTAIN BUILDING COMPLETE!")
	print("[Mountains] - 5 mountain ranges")
	print("[Mountains] - Multiple peaks with snow caps")
	print("[Mountains] - Caves with crystal chambers")
	print("[Mountains] - Ridges connecting peaks")
	print("[Mountains] - Rock formations and cliffs")
	print("[Mountains] ========================================")
end

-- Start building after world loads
task.spawn(function()
	task.wait(2) -- Wait for other systems
	buildAllMountains()
end)

print("[Mountains] Mountain system initialized - building will start shortly...")
