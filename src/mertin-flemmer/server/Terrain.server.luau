--!strict
-- Terrain, Paths, and Environmental Storytelling for Mertin-Flemmer
-- Winding paths, elevation changes, story signs, explorer remains, pirate ship

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

-- ==========================================
-- TERRAIN CONFIGURATION
-- ==========================================

local SPAWN_CENTER = Vector3.new(0, 0, -30)

-- Path definitions - each leads to a different destination
local PATHS = {
	{
		name = "The Northern Trail",
		description = "A winding path through the Whispering Woods.\nDanger Level: Low\nRumors of fairies and lost children.",
		color = Color3.fromRGB(100, 150, 100), -- Green
		direction = "north",
		waypoints = {
			Vector3.new(0, 0, 50),
			Vector3.new(20, 3, 120),
			Vector3.new(10, 5, 200),
			Vector3.new(40, 8, 280),
			Vector3.new(30, 6, 380),
			Vector3.new(50, 4, 500),
		},
		destination = "Whispering Woods",
		journalHints = {
			"Day 3: The forest seems alive. I hear whispers at night.",
			"Day 7: Found strange mushroom circles. The locals call them fairy rings.",
		},
	},
	{
		name = "The Eastern Road",
		description = "A treacherous climb to the Frozen Peaks.\nDanger Level: High\nBeware the cold and what lurks within.",
		color = Color3.fromRGB(150, 200, 255), -- Icy blue
		direction = "east",
		waypoints = {
			Vector3.new(50, 0, -30),
			Vector3.new(130, 8, -20),
			Vector3.new(220, 15, -40),
			Vector3.new(320, 25, -30),
			Vector3.new(420, 35, -50),
			Vector3.new(550, 45, -40),
		},
		destination = "Frozen Peaks",
		journalHints = {
			"Day 5: The temperature drops with each step upward.",
			"Day 12: My companion didn't wake up this morning. The cold took him.",
		},
	},
	{
		name = "The Western Passage",
		description = "A coastal route to Smuggler's Cove.\nDanger Level: Medium\nPirates have been spotted in these waters.",
		color = Color3.fromRGB(200, 180, 120), -- Sandy
		direction = "west",
		waypoints = {
			Vector3.new(-50, 0, -20),
			Vector3.new(-120, -2, 0),
			Vector3.new(-200, -3, 30),
			Vector3.new(-300, -2, 20),
			Vector3.new(-420, 0, 50),
			Vector3.new(-550, 2, 80),
		},
		destination = "Smuggler's Cove",
		journalHints = {
			"Day 2: The sound of waves is calming, but I've seen ships on the horizon.",
			"Day 8: Pirates! They took everything. I barely escaped with my life.",
		},
	},
}

-- ==========================================
-- PATH CREATION
-- ==========================================

local function createPath(pathData: typeof(PATHS[1]))
	local pathModel = Instance.new("Model")
	pathModel.Name = "Path_" .. pathData.name:gsub(" ", "_")

	local waypoints = pathData.waypoints
	local pathWidth = 6

	-- Create path segments between waypoints
	for i = 1, #waypoints - 1 do
		local start = waypoints[i]
		local finish = waypoints[i + 1]
		local direction = (finish - start)
		local length = direction.Magnitude
		local midpoint = start + direction / 2

		-- Main path segment
		local segment = Instance.new("Part")
		segment.Name = "PathSegment_" .. i
		segment.Size = Vector3.new(pathWidth, 0.3, length)
		segment.Position = midpoint + Vector3.new(0, 0.15, 0)
		segment.CFrame = CFrame.lookAt(midpoint, finish) * CFrame.new(0, 0.15, 0)
		segment.Color = Color3.fromRGB(140, 120, 90) -- Dirt path
		segment.Material = Enum.Material.Ground
		segment.Anchored = true
		segment.Parent = pathModel

		-- Path borders (stones)
		for side = -1, 1, 2 do
			local borderOffset = pathWidth / 2 * side
			for j = 0, math.floor(length / 4) do
				if math.random() > 0.4 then
					local stone = Instance.new("Part")
					stone.Name = "Stone"
					stone.Size = Vector3.new(0.5 + math.random() * 0.5, 0.3 + math.random() * 0.3, 0.5 + math.random() * 0.5)

					local t = j / math.floor(length / 4)
					local stonePos = start + direction * t
					stone.Position = stonePos + Vector3.new(borderOffset + (math.random() - 0.5) * 0.5, stone.Size.Y / 2, 0)
					stone.Color = Color3.fromRGB(100 + math.random(30), 100 + math.random(30), 100 + math.random(30))
					stone.Material = Enum.Material.Rock
					stone.Anchored = true
					stone.Parent = pathModel
				end
			end
		end

		-- Add elevation terrain (hills beside path)
		if i % 2 == 0 then
			local hillSide = math.random() > 0.5 and 1 or -1
			local hill = Instance.new("Part")
			hill.Name = "Hill"
			hill.Size = Vector3.new(30 + math.random() * 20, 10 + math.random() * 15, 30 + math.random() * 20)
			hill.Position = midpoint + Vector3.new(hillSide * 30, hill.Size.Y / 2 - 5, (math.random() - 0.5) * 20)
			hill.Color = Color3.fromRGB(80, 120, 60)
			hill.Material = Enum.Material.Grass
			hill.Shape = Enum.PartType.Ball
			hill.Anchored = true
			hill.Parent = pathModel
		end
	end

	-- Add waypoint markers (small lanterns or torches)
	for i, waypoint in waypoints do
		if i > 1 and i < #waypoints then
			local marker = Instance.new("Part")
			marker.Name = "Waypoint_" .. i
			marker.Size = Vector3.new(0.5, 3, 0.5)
			marker.Position = waypoint + Vector3.new(pathWidth / 2 + 1, 1.5, 0)
			marker.Color = Color3.fromRGB(80, 60, 40)
			marker.Material = Enum.Material.Wood
			marker.Anchored = true
			marker.Parent = pathModel

			-- Lantern top
			local lantern = Instance.new("Part")
			lantern.Size = Vector3.new(0.8, 0.8, 0.8)
			lantern.Position = marker.Position + Vector3.new(0, 2, 0)
			lantern.Color = Color3.fromRGB(255, 200, 100)
			lantern.Material = Enum.Material.Neon
			lantern.Transparency = 0.3
			lantern.Anchored = true
			lantern.Parent = pathModel

			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 200, 100)
			light.Brightness = 0.8
			light.Range = 20
			light.Parent = lantern
		end
	end

	pathModel.Parent = workspace
	return pathModel
end

-- ==========================================
-- SPAWN AREA SIGNS
-- ==========================================

local function createSpawnSigns()
	local signModel = Instance.new("Model")
	signModel.Name = "SpawnSigns"

	-- Central signpost (moved further from spawn house door)
	local post = Instance.new("Part")
	post.Name = "CentralPost"
	post.Size = Vector3.new(1.5, 12, 1.5)  -- Taller, thicker post
	post.Position = SPAWN_CENTER + Vector3.new(0, 6, 50)  -- Much further from house
	post.Color = Color3.fromRGB(80, 60, 40)
	post.Material = Enum.Material.Wood
	post.Anchored = true
	post.Parent = signModel

	-- Decorative top
	local postTop = Instance.new("Part")
	postTop.Size = Vector3.new(1.5, 0.5, 1.5)
	postTop.Position = post.Position + Vector3.new(0, 4.25, 0)
	postTop.Color = Color3.fromRGB(60, 45, 30)
	postTop.Material = Enum.Material.Wood
	postTop.Anchored = true
	postTop.Parent = signModel

	-- Create directional signs for each path
	for i, pathData in PATHS do
		local signBoard = Instance.new("Part")
		signBoard.Name = "Sign_" .. pathData.direction
		signBoard.Size = Vector3.new(10, 4, 0.4)  -- Much bigger signs

		-- Position signs at different heights pointing in direction
		local height = 5 - (i - 1) * 2
		local rotation = 0

		if pathData.direction == "north" then
			rotation = 0
		elseif pathData.direction == "east" then
			rotation = -90
		elseif pathData.direction == "west" then
			rotation = 90
		elseif pathData.direction == "south" then
			rotation = 180
		end

		signBoard.CFrame = CFrame.new(post.Position + Vector3.new(0, height, 0)) * CFrame.Angles(0, math.rad(rotation), math.rad(5))
		signBoard.Position = signBoard.Position + signBoard.CFrame.LookVector * 3
		signBoard.Color = Color3.fromRGB(100, 80, 50)
		signBoard.Material = Enum.Material.Wood
		signBoard.Anchored = true
		signBoard.Parent = signModel

		-- Sign text (front)
		local signGui = Instance.new("SurfaceGui")
		signGui.Face = Enum.NormalId.Front
		signGui.Parent = signBoard

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = pathData.name
		titleLabel.TextColor3 = Color3.new(1, 1, 1)
		titleLabel.Font = Enum.Font.Antique
		titleLabel.TextScaled = true  -- Auto-scale to fill space
		titleLabel.Parent = signGui

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -10, 0.6, 0)
		descLabel.Position = UDim2.new(0, 5, 0.4, 0)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = pathData.description
		descLabel.TextColor3 = Color3.fromRGB(220, 220, 200)
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextScaled = true  -- Auto-scale to fill space
		descLabel.TextWrapped = true
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Parent = signGui

		-- Arrow pointing direction
		local arrow = Instance.new("Part")
		arrow.Name = "Arrow"
		arrow.Size = Vector3.new(1.5, 0.3, 0.8)
		arrow.CFrame = signBoard.CFrame * CFrame.new(3.5, 0, 0)
		arrow.Color = pathData.color
		arrow.Material = Enum.Material.SmoothPlastic
		arrow.Anchored = true
		arrow.Parent = signModel
	end

	-- Welcome sign (moved further from door so it doesn't block)
	local welcomeSign = Instance.new("Part")
	welcomeSign.Name = "WelcomeSign"
	welcomeSign.Size = Vector3.new(8, 4, 0.5)
	welcomeSign.Position = SPAWN_CENTER + Vector3.new(0, 3, 40)  -- Much further out
	welcomeSign.Color = Color3.fromRGB(80, 60, 40)
	welcomeSign.Material = Enum.Material.Wood
	welcomeSign.Anchored = true
	welcomeSign.Parent = signModel

	local welcomeGui = Instance.new("SurfaceGui")
	welcomeGui.Face = Enum.NormalId.Back
	welcomeGui.Parent = welcomeSign

	local welcomeText = Instance.new("TextLabel")
	welcomeText.Size = UDim2.new(1, 0, 1, 0)
	welcomeText.BackgroundColor3 = Color3.fromRGB(40, 30, 20)
	welcomeText.BackgroundTransparency = 0.3
	welcomeText.Text = "WELCOME, SURVIVOR\n\nChoose your path wisely.\nCollect Signal Parts to call for rescue.\nSave the lost pets.\nSurvive the night.\n\n- The Watchers"
	welcomeText.TextColor3 = Color3.new(1, 1, 1)
	welcomeText.Font = Enum.Font.Antique
	welcomeText.TextSize = 20
	welcomeText.TextWrapped = true
	welcomeText.Parent = welcomeGui

	signModel.Parent = workspace
	return signModel
end

-- ==========================================
-- EXPLORER REMAINS & JOURNALS
-- ==========================================

local JOURNAL_ENTRIES = {
	{
		title = "Torn Journal Page",
		content = "Day 1: We arrived at the settlement with high hopes. The locals warned us about the creatures that come at night. We didn't listen.",
		location = Vector3.new(80, 0, 50),
	},
	{
		title = "Bloodstained Note",
		content = "To whoever finds this: DO NOT travel alone. DO NOT leave the light. The Deer Monster... it doesn't make a sound until it's too late.",
		location = Vector3.new(-120, 0, 100),
	},
	{
		title = "Final Entry",
		content = "Day 23: I'm the last one. The signal parts are scattered across the land - I found one in the frozen peaks, one in the pirate cove. The third... I never found it. If you're reading this, I'm sorry I couldn't do more.",
		location = Vector3.new(200, 0, -100),
	},
	{
		title = "Child's Drawing",
		content = "[A crude drawing shows a house, two adults, a child, and a dog. At the bottom is written:] FLUFFY IS LOST. PLEASE FIND HIM. HE WENT TOWARD THE BIG SHIP.",
		location = Vector3.new(-80, 0, -80),
	},
	{
		title = "Pirate's Map Fragment",
		content = "X marks the spot, they say, but the real treasure ain't gold - it's that glowing signal piece we found in the cave. Captain's keeping it locked up tight on the ship.",
		location = Vector3.new(-400, 0, 100),
	},
	{
		title = "Hermit's Warning",
		content = "The pets have been disappearing. Someone - or something - is taking them. I've seen cages near the pirate ship. Those scoundrels are selling them to dark traders from across the sea.",
		location = Vector3.new(150, 0, -250),
	},
}

local function createExplorerRemains(position: Vector3, journalData: typeof(JOURNAL_ENTRIES[1])?)
	local remains = Instance.new("Model")
	remains.Name = "ExplorerRemains"

	-- Skeleton
	local skull = Instance.new("Part")
	skull.Name = "Skull"
	skull.Size = Vector3.new(0.8, 0.8, 0.8)
	skull.Position = position + Vector3.new(0, 0.4, 0)
	skull.Color = Color3.fromRGB(240, 230, 210)
	skull.Material = Enum.Material.SmoothPlastic
	skull.Anchored = true
	skull.Parent = remains

	-- Ribcage
	local ribs = Instance.new("Part")
	ribs.Name = "Ribcage"
	ribs.Size = Vector3.new(1.2, 0.8, 1.5)
	ribs.Position = position + Vector3.new(0.5, 0.4, 1)
	ribs.Color = Color3.fromRGB(235, 225, 205)
	ribs.Material = Enum.Material.SmoothPlastic
	ribs.Anchored = true
	ribs.Parent = remains

	-- Arm bones
	local arm = Instance.new("Part")
	arm.Name = "ArmBone"
	arm.Size = Vector3.new(0.2, 0.2, 1.5)
	arm.Position = position + Vector3.new(1.2, 0.2, 0.5)
	arm.Color = Color3.fromRGB(235, 225, 205)
	arm.Material = Enum.Material.SmoothPlastic
	arm.Anchored = true
	arm.Parent = remains

	-- Scattered belongings
	local backpack = Instance.new("Part")
	backpack.Name = "OldBackpack"
	backpack.Size = Vector3.new(1, 1.2, 0.6)
	backpack.Position = position + Vector3.new(-0.8, 0.6, 0.5)
	backpack.Color = Color3.fromRGB(80, 70, 50)
	backpack.Material = Enum.Material.Fabric
	backpack.Anchored = true
	backpack.Parent = remains

	-- Rusted lantern
	local lantern = Instance.new("Part")
	lantern.Name = "RustedLantern"
	lantern.Size = Vector3.new(0.4, 0.6, 0.4)
	lantern.Position = position + Vector3.new(0.3, 0.3, -0.5)
	lantern.Color = Color3.fromRGB(100, 80, 60)
	lantern.Material = Enum.Material.CorrodedMetal
	lantern.Anchored = true
	lantern.Parent = remains

	-- Journal if provided
	if journalData then
		local journal = Instance.new("Part")
		journal.Name = "Journal"
		journal.Size = Vector3.new(0.6, 0.1, 0.8)
		journal.Position = position + Vector3.new(-0.5, 0.15, -0.3)
		journal.Color = Color3.fromRGB(120, 80, 50)
		journal.Material = Enum.Material.Fabric
		journal.Anchored = true
		journal.Parent = remains

		-- Proximity prompt to read
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Read Journal"
		prompt.ObjectText = journalData.title
		prompt.MaxActivationDistance = 6
		prompt.HoldDuration = 0.3
		prompt.Parent = journal

		-- Journal reading event
		prompt.Triggered:Connect(function(player)
			local JournalRemote = ReplicatedStorage:FindFirstChild("Journal") :: RemoteEvent?
			if not JournalRemote then
				JournalRemote = Instance.new("RemoteEvent")
				JournalRemote.Name = "Journal"
				JournalRemote.Parent = ReplicatedStorage
			end

			JournalRemote:FireClient(player, "READ", {
				title = journalData.title,
				content = journalData.content,
			})
		end)

		-- Billboard showing it's interactable
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 100, 0, 30)
		billboard.StudsOffset = Vector3.new(0, 1.5, 0)
		billboard.Adornee = journal
		billboard.Parent = journal

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = journalData.title
		label.TextColor3 = Color3.fromRGB(200, 180, 140)
		label.TextStrokeTransparency = 0.3
		label.Font = Enum.Font.Antique
		label.TextSize = 20
		label.Parent = billboard
	end

	remains.Parent = workspace
	return remains
end

-- ==========================================
-- PIRATE SHIP & COVE
-- ==========================================

local function createPirateShip(position: Vector3)
	local ship = Instance.new("Model")
	ship.Name = "PirateShip"

	-- Hull
	local hull = Instance.new("Part")
	hull.Name = "Hull"
	hull.Size = Vector3.new(20, 10, 60)
	hull.Position = position + Vector3.new(0, 5, 0)
	hull.Color = Color3.fromRGB(80, 50, 30)
	hull.Material = Enum.Material.Wood
	hull.Anchored = true
	hull.Parent = ship

	-- Deck
	local deck = Instance.new("Part")
	deck.Name = "Deck"
	deck.Size = Vector3.new(18, 1, 55)
	deck.Position = position + Vector3.new(0, 10.5, 0)
	deck.Color = Color3.fromRGB(100, 70, 40)
	deck.Material = Enum.Material.Wood
	deck.Anchored = true
	deck.Parent = ship

	-- Captain's cabin
	local cabin = Instance.new("Part")
	cabin.Name = "Cabin"
	cabin.Size = Vector3.new(14, 8, 15)
	cabin.Position = position + Vector3.new(0, 15, 18)
	cabin.Color = Color3.fromRGB(70, 45, 25)
	cabin.Material = Enum.Material.Wood
	cabin.Anchored = true
	cabin.Parent = ship

	-- Mast
	local mast = Instance.new("Part")
	mast.Name = "Mast"
	mast.Size = Vector3.new(2, 40, 2)
	mast.Position = position + Vector3.new(0, 30, -5)
	mast.Color = Color3.fromRGB(90, 60, 35)
	mast.Material = Enum.Material.Wood
	mast.Anchored = true
	mast.Parent = ship

	-- Crow's nest
	local crowsNest = Instance.new("Part")
	crowsNest.Name = "CrowsNest"
	crowsNest.Size = Vector3.new(5, 2, 5)
	crowsNest.Position = position + Vector3.new(0, 48, -5)
	crowsNest.Color = Color3.fromRGB(80, 55, 30)
	crowsNest.Material = Enum.Material.Wood
	crowsNest.Anchored = true
	crowsNest.Parent = ship

	-- Sails
	local sail = Instance.new("Part")
	sail.Name = "Sail"
	sail.Size = Vector3.new(0.3, 25, 18)
	sail.Position = position + Vector3.new(0, 35, -5)
	sail.Color = Color3.fromRGB(200, 180, 150)
	sail.Material = Enum.Material.Fabric
	sail.Anchored = true
	sail.Parent = ship

	-- Jolly Roger (skull flag)
	local flag = Instance.new("Part")
	flag.Name = "JollyRoger"
	flag.Size = Vector3.new(0.1, 5, 8)
	flag.Position = position + Vector3.new(0, 52, -5)
	flag.Color = Color3.fromRGB(20, 20, 20)
	flag.Material = Enum.Material.Fabric
	flag.Anchored = true
	flag.Parent = ship

	local flagGui = Instance.new("SurfaceGui")
	flagGui.Face = Enum.NormalId.Front
	flagGui.Parent = flag

	local skullLabel = Instance.new("TextLabel")
	skullLabel.Size = UDim2.new(1, 0, 1, 0)
	skullLabel.BackgroundTransparency = 1
	skullLabel.Text = "💀"
	skullLabel.TextColor3 = Color3.new(1, 1, 1)
	skullLabel.TextSize = 50
	skullLabel.Parent = flagGui

	-- Cannon
	for i, xOffset in { -8, 8 } do
		local cannon = Instance.new("Part")
		cannon.Name = "Cannon_" .. i
		cannon.Size = Vector3.new(2, 2, 6)
		cannon.Position = position + Vector3.new(xOffset, 11.5, -10)
		cannon.Color = Color3.fromRGB(40, 40, 50)
		cannon.Material = Enum.Material.Metal
		cannon.Anchored = true
		cannon.Parent = ship
	end

	-- Pet cages on deck
	local cagePositions = {
		Vector3.new(-6, 11.5, 5),
		Vector3.new(6, 11.5, 5),
		Vector3.new(0, 11.5, 10),
	}

	for i, cagePos in cagePositions do
		local cage = Instance.new("Model")
		cage.Name = "PetCage_" .. i

		-- Cage frame
		local frame = Instance.new("Part")
		frame.Name = "Frame"
		frame.Size = Vector3.new(3, 3, 3)
		frame.Position = position + cagePos + Vector3.new(0, 1.5, 0)
		frame.Color = Color3.fromRGB(60, 60, 70)
		frame.Material = Enum.Material.Metal
		frame.Transparency = 0.5
		frame.Anchored = true
		frame.Parent = cage

		-- Captured pet inside
		local pet = Instance.new("Part")
		pet.Name = "CapturedPet"
		pet.Size = Vector3.new(1, 0.8, 1.5)
		pet.Position = frame.Position
		pet.Color = i == 1 and Color3.fromRGB(150, 100, 60) or (i == 2 and Color3.fromRGB(30, 30, 35) or Color3.fromRGB(200, 150, 100))
		pet.Material = Enum.Material.SmoothPlastic
		pet.Anchored = true
		pet.Parent = cage

		-- Pet name tag
		local petBillboard = Instance.new("BillboardGui")
		petBillboard.Size = UDim2.new(0, 80, 0, 30)
		petBillboard.StudsOffset = Vector3.new(0, 2, 0)
		petBillboard.Adornee = pet
		petBillboard.Parent = cage

		local petNames = { "Fluffy the Dog", "Shadow the Cat", "Whiskers the Cat" }
		local petLabel = Instance.new("TextLabel")
		petLabel.Size = UDim2.new(1, 0, 1, 0)
		petLabel.BackgroundTransparency = 1
		petLabel.Text = petNames[i] .. "\n[RESCUE ME!]"
		petLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
		petLabel.TextStrokeTransparency = 0.3
		petLabel.Font = Enum.Font.GothamBold
		petLabel.TextSize = 18
		petLabel.Parent = petBillboard

		-- Rescue prompt
		local rescuePrompt = Instance.new("ProximityPrompt")
		rescuePrompt.ActionText = "Rescue Pet"
		rescuePrompt.ObjectText = petNames[i]
		rescuePrompt.MaxActivationDistance = 5
		rescuePrompt.HoldDuration = 2
		rescuePrompt.Parent = frame

		cage.Parent = ship
	end

	-- Ship sign
	local shipSign = Instance.new("Part")
	shipSign.Name = "ShipNameSign"
	shipSign.Size = Vector3.new(10, 2, 0.3)
	shipSign.Position = position + Vector3.new(0, 9, -29)
	shipSign.Color = Color3.fromRGB(60, 40, 25)
	shipSign.Material = Enum.Material.Wood
	shipSign.Anchored = true
	shipSign.Parent = ship

	local nameGui = Instance.new("SurfaceGui")
	nameGui.Face = Enum.NormalId.Front
	nameGui.Parent = shipSign

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "THE BLACK MIST"
	nameLabel.TextColor3 = Color3.fromRGB(200, 180, 140)
	nameLabel.Font = Enum.Font.Antique
	nameLabel.TextSize = 32
	nameLabel.Parent = nameGui

	-- Water around ship
	local water = Instance.new("Part")
	water.Name = "CoveWater"
	water.Size = Vector3.new(100, 2, 100)
	water.Position = position + Vector3.new(0, -1, 0)
	water.Color = Color3.fromRGB(40, 80, 120)
	water.Material = Enum.Material.Glass
	water.Transparency = 0.4
	water.Anchored = true
	water.CanCollide = false
	water.Parent = ship

	ship.Parent = workspace
	return ship
end

-- ==========================================
-- TERRAIN INITIALIZATION
-- ==========================================

local function initializeTerrain()
	task.wait(3) -- Wait for base world

	print("[Terrain] Creating winding paths...")

	-- Create paths
	for _, pathData in PATHS do
		createPath(pathData)
	end

	print("[Terrain] Creating spawn area signs...")
	createSpawnSigns()

	print("[Terrain] Placing explorer remains and journals...")
	for _, journalData in JOURNAL_ENTRIES do
		createExplorerRemains(journalData.location, journalData)
	end

	-- Additional skeleton spawns without journals
	local extraSkeletonPositions = {
		Vector3.new(300, 0, 150),
		Vector3.new(-250, 0, -200),
		Vector3.new(400, 30, -100),
		Vector3.new(-350, 0, 250),
	}
	for _, pos in extraSkeletonPositions do
		createExplorerRemains(pos, nil)
	end

	print("[Terrain] Creating pirate ship at Smuggler's Cove...")
	createPirateShip(Vector3.new(-600, 0, 100))

	print("[Terrain] Terrain, paths, and story elements created!")
end

-- Initialize
task.spawn(initializeTerrain)

print("[Terrain] Environmental storytelling system initialized!")
