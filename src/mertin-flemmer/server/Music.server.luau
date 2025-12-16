--!strict
-- Music System - GTA-style radio stations and walkman
-- Radio towers broadcast different stations
-- Players can pick up a walkman to tune in anywhere

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Get shared config
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

-- Create remote events
local musicEvents = Instance.new("Folder")
musicEvents.Name = "MusicEvents"
musicEvents.Parent = ReplicatedStorage

local tuneStationEvent = Instance.new("RemoteEvent")
tuneStationEvent.Name = "TuneStation"
tuneStationEvent.Parent = musicEvents

local pickupWalkmanEvent = Instance.new("RemoteEvent")
pickupWalkmanEvent.Name = "PickupWalkman"
pickupWalkmanEvent.Parent = musicEvents

local walkmanStatusEvent = Instance.new("RemoteEvent")
walkmanStatusEvent.Name = "WalkmanStatus"
walkmanStatusEvent.Parent = musicEvents

local radioProximityEvent = Instance.new("RemoteEvent")
radioProximityEvent.Name = "RadioProximity"
radioProximityEvent.Parent = musicEvents

-- Music container
local musicFolder = Instance.new("Folder")
musicFolder.Name = "MusicSystem"
musicFolder.Parent = Workspace

-- ==========================================
-- RADIO STATIONS
-- Each station has a genre, mood, and location
-- ==========================================

type RadioStation = {
	name: string,
	genre: string,
	description: string,
	frequency: string, -- e.g., "97.5 FM"
	mood: string,
	color: Color3,
	position: Vector3,
	range: number, -- Broadcast range in studs
	-- Roblox audio IDs (using placeholder IDs - replace with real ones)
	tracks: { string },
	announcer: string, -- DJ personality
	towerHeight: number,
}

local RADIO_STATIONS: { RadioStation } = {
	-- ===== CENTRAL / SPAWN AREA =====
	{
		name = "Survivor Radio",
		genre = "Acoustic Folk",
		description = "Songs of hope in dark times",
		frequency = "88.1 FM",
		mood = "Hopeful",
		color = Color3.fromRGB(200, 180, 100),
		position = Vector3.new(200, 0, 100), -- Near spawn
		range = 1000, -- LARGER RANGE!
		tracks = {
			"rbxassetid://1837849285", -- Folk
			"rbxassetid://1837849285",
			"rbxassetid://1837849285",
		},
		announcer = "Old Martha",
		towerHeight = 60,
	},
	{
		name = "Camel Country",
		genre = "Desert Blues",
		description = "Toe-tappin' tunes for the trail",
		frequency = "103.5 FM",
		mood = "Upbeat",
		color = Color3.fromRGB(200, 150, 80),
		position = Vector3.new(-100, 0, 300), -- Southern area near spawn
		range = 900,
		tracks = {
			"rbxassetid://1836367922", -- Blues
			"rbxassetid://1836367922",
			"rbxassetid://1836367922",
		},
		announcer = "Dusty Dan",
		towerHeight = 55,
	},

	-- ===== FROZEN WASTES (Snow Biome - East) =====
	{
		name = "Frost Wave",
		genre = "Synth Chill",
		description = "Cold beats for cold nights",
		frequency = "94.5 FM",
		mood = "Serene",
		color = Color3.fromRGB(150, 200, 255),
		position = Vector3.new(1800, 0, 100), -- Deep in snow biome
		range = 1200,
		tracks = {
			"rbxassetid://1839841276", -- Atmospheric
			"rbxassetid://1839841276",
			"rbxassetid://1839841276",
		},
		announcer = "Ice Queen Vera",
		towerHeight = 100,
	},
	{
		name = "Arctic Dawn",
		genre = "Ambient",
		description = "The sound of frozen silence",
		frequency = "89.3 FM",
		mood = "Peaceful",
		color = Color3.fromRGB(200, 230, 255),
		position = Vector3.new(2500, 0, -300), -- Far frozen wastes
		range = 1000,
		tracks = {
			"rbxassetid://9043887091", -- Ambient
			"rbxassetid://9043887091",
		},
		announcer = "The Frost Whisperer",
		towerHeight = 120,
	},

	-- ===== SCORCHED SANDS (Desert Biome - East/South) =====
	{
		name = "Sandstorm Radio",
		genre = "Arabic Electronic",
		description = "Desert rhythms for weary travelers",
		frequency = "101.1 FM",
		mood = "Exotic",
		color = Color3.fromRGB(255, 200, 100),
		position = Vector3.new(1500, 0, 1800), -- Desert biome
		range = 1100,
		tracks = {
			"rbxassetid://1836367922", -- World music
			"rbxassetid://1836367922",
		},
		announcer = "Sultan of Sound",
		towerHeight = 80,
	},
	{
		name = "Mirage FM",
		genre = "Psychedelic",
		description = "Is this real? Does it matter?",
		frequency = "105.7 FM",
		mood = "Trippy",
		color = Color3.fromRGB(255, 150, 200),
		position = Vector3.new(2200, 0, 2000), -- Deep desert
		range = 900,
		tracks = {
			"rbxassetid://1837973836", -- Psychedelic
			"rbxassetid://1837973836",
		},
		announcer = "The Dreamer",
		towerHeight = 70,
	},

	-- ===== ASHEN PEAKS (Volcanic Biome - West/South) =====
	{
		name = "Doom FM",
		genre = "Dark Ambient",
		description = "The sound of approaching inevitability",
		frequency = "66.6 FM",
		mood = "Ominous",
		color = Color3.fromRGB(255, 80, 0),
		position = Vector3.new(-2000, 0, 1500), -- Volcanic biome
		range = 1200,
		tracks = {
			"rbxassetid://9043887091", -- Dark ambient
			"rbxassetid://9043887091",
			"rbxassetid://9043887091",
		},
		announcer = "The Harbinger",
		towerHeight = 100,
	},
	{
		name = "Inferno Beats",
		genre = "Industrial Metal",
		description = "FORGED IN FIRE!",
		frequency = "98.9 FM",
		mood = "Intense",
		color = Color3.fromRGB(255, 50, 0),
		position = Vector3.new(-2500, 0, 1000), -- Deep volcanic
		range = 1000,
		tracks = {
			"rbxassetid://9043887091", -- Heavy
			"rbxassetid://9043887091",
		},
		announcer = "Forge Master Rex",
		towerHeight = 90,
	},

	-- ===== MURKY DEPTHS (Swamp Biome - West/North) =====
	{
		name = "Bayou Blues",
		genre = "Swamp Blues",
		description = "Music from the murky depths",
		frequency = "92.3 FM",
		mood = "Eerie",
		color = Color3.fromRGB(100, 150, 80),
		position = Vector3.new(-1500, 0, -1200), -- Swamp biome
		range = 1000,
		tracks = {
			"rbxassetid://1836367922", -- Blues
			"rbxassetid://1836367922",
		},
		announcer = "Swamp Thing Sam",
		towerHeight = 60,
	},
	{
		name = "Fog Frequency",
		genre = "Gothic Ambient",
		description = "Lost in the mist...",
		frequency = "77.7 FM",
		mood = "Mysterious",
		color = Color3.fromRGB(80, 100, 80),
		position = Vector3.new(-1800, 0, -800), -- Deep swamp
		range = 800,
		tracks = {
			"rbxassetid://9043887091", -- Gothic
			"rbxassetid://9043887091",
		},
		announcer = "The Fog",
		towerHeight = 50,
	},

	-- ===== SHIMMERING CAVERNS (Crystal Biome - South) =====
	{
		name = "Crystal Clear",
		genre = "New Age",
		description = "Healing frequencies from the crystals",
		frequency = "111.1 FM",
		mood = "Magical",
		color = Color3.fromRGB(200, 100, 255),
		position = Vector3.new(0, 0, -2000), -- Crystal biome
		range = 1100,
		tracks = {
			"rbxassetid://1837973836", -- New age
			"rbxassetid://1837973836",
		},
		announcer = "Crystal Sage Lumina",
		towerHeight = 110,
	},

	-- ===== MOUNTAIN AREAS =====
	{
		name = "The Wasteland",
		genre = "Post-Rock",
		description = "Music for the end of everything",
		frequency = "91.7 FM",
		mood = "Melancholic",
		color = Color3.fromRGB(100, 100, 120),
		position = Vector3.new(400, 0, -200), -- Shadow Mountains area
		range = 1000,
		tracks = {
			"rbxassetid://1839841276", -- Atmospheric
			"rbxassetid://1839841276",
			"rbxassetid://1839841276",
		},
		announcer = "Silent Sam",
		towerHeight = 70,
	},
	{
		name = "Mountain Echo",
		genre = "Orchestral",
		description = "Classical pieces for contemplation",
		frequency = "107.9 FM",
		mood = "Grand",
		color = Color3.fromRGB(150, 150, 200),
		position = Vector3.new(350, 0, 350), -- Near The Giants
		range = 1000,
		tracks = {
			"rbxassetid://1837973836", -- Orchestral
			"rbxassetid://1837973836",
			"rbxassetid://1837973836",
		},
		announcer = "Professor Harmon",
		towerHeight = 90,
	},
	{
		name = "Peak Performance",
		genre = "Epic Cinematic",
		description = "For those who climb highest",
		frequency = "99.9 FM",
		mood = "Triumphant",
		color = Color3.fromRGB(255, 215, 0),
		position = Vector3.new(300, 0, -500), -- Near mountain peaks
		range = 1200,
		tracks = {
			"rbxassetid://1837973836", -- Epic
			"rbxassetid://1837973836",
		},
		announcer = "Summit Steve",
		towerHeight = 150,
	},

	-- ===== MYSTERIOUS / SPECIAL =====
	{
		name = "Static",
		genre = "Experimental Noise",
		description = "???",
		frequency = "?.? FM",
		mood = "Unsettling",
		color = Color3.fromRGB(50, 50, 50),
		position = Vector3.new(0, 0, -500), -- Mysterious location
		range = 600,
		tracks = {
			"rbxassetid://9043887091", -- Noise/static
			"rbxassetid://9043887091",
		},
		announcer = "???",
		towerHeight = 100,
	},
	{
		name = "Skyscraper FM",
		genre = "Elevator Jazz",
		description = "Smooth sounds from Floor 7½",
		frequency = "75.0 FM",
		mood = "Jazzy",
		color = Color3.fromRGB(255, 200, 150),
		position = Vector3.new(150, 0, -100), -- At the Mertin-Flemmer building
		range = 500,
		tracks = {
			"rbxassetid://1837973836", -- Jazz
			"rbxassetid://1837973836",
		},
		announcer = "Mertin & Flemmer",
		towerHeight = 40, -- Short - it's ON the skyscraper
	},
}

-- ==========================================
-- WALKMAN SPAWNS
-- Portable radios scattered around the world
-- ==========================================

type WalkmanSpawn = {
	position: Vector3,
	description: string,
}

local WALKMAN_SPAWNS: { WalkmanSpawn } = {
	{ position = Vector3.new(50, 5, 50), description = "Near spawn" },
	{ position = Vector3.new(-150, 5, 100), description = "Abandoned camp" },
	{ position = Vector3.new(200, 5, -100), description = "Old trading post" },
	{ position = Vector3.new(-50, 5, 250), description = "Riverside" },
	{ position = Vector3.new(300, 5, 200), description = "Mountain base" },
	{ position = Vector3.new(-200, 5, -200), description = "Forest clearing" },
	{ position = Vector3.new(100, 5, -300), description = "Cave entrance" },
	{ position = Vector3.new(-300, 5, 150), description = "Ruined shelter" },
}

-- Player walkman state
local playerWalkmans: { [Player]: {
	hasWalkman: boolean,
	currentStation: number?, -- Index into RADIO_STATIONS, nil = off
	volume: number,
} } = {}

-- ==========================================
-- CREATE RADIO TOWER (TALL RED & WHITE WITH ELECTRIC WAVES!)
-- ==========================================

local function createRadioTower(station: RadioStation, index: number)
	local tower = Instance.new("Model")
	tower.Name = station.name .. "_Tower"

	-- Get terrain height at tower position
	local terrainHeight = Shared.getTerrainHeight(station.position.X, station.position.Z)
	local basePos = Vector3.new(station.position.X, terrainHeight, station.position.Z)

	-- MASSIVE tower height (150-250 studs tall!)
	local TOWER_HEIGHT = 150 + station.towerHeight

	-- Concrete foundation
	local foundation = Instance.new("Part")
	foundation.Name = "Foundation"
	foundation.Size = Vector3.new(20, 6, 20)
	foundation.Position = basePos + Vector3.new(0, 3, 0)
	foundation.Anchored = true
	foundation.Material = Enum.Material.Concrete
	foundation.Color = Color3.fromRGB(100, 100, 100)
	foundation.Parent = tower

	-- RED AND WHITE STRIPED TOWER SECTIONS (optimized - fewer parts)
	local NUM_SECTIONS = 6  -- Reduced for performance
	local sectionHeight = TOWER_HEIGHT / NUM_SECTIONS
	local RED = Color3.fromRGB(200, 30, 30)
	local WHITE = Color3.fromRGB(240, 240, 240)

	for i = 1, NUM_SECTIONS do
		-- Main tower section (tapers toward top)
		local taper = 1 - (i / NUM_SECTIONS) * 0.5
		local section = Instance.new("Part")
		section.Name = "Section" .. i
		section.Size = Vector3.new(5 * taper, sectionHeight, 5 * taper)
		section.Position = basePos + Vector3.new(0, 6 + (i - 0.5) * sectionHeight, 0)
		section.Anchored = true
		section.Material = Enum.Material.Metal
		section.CastShadow = false  -- Performance
		-- Alternate red and white
		section.Color = (i % 2 == 0) and RED or WHITE
		section.Parent = tower
	end

	-- Antenna mast at very top
	local antenna = Instance.new("Part")
	antenna.Name = "Antenna"
	antenna.Size = Vector3.new(1, 30, 1)
	antenna.Position = basePos + Vector3.new(0, 6 + TOWER_HEIGHT + 15, 0)
	antenna.Anchored = true
	antenna.Material = Enum.Material.Metal
	antenna.Color = WHITE
	antenna.Parent = tower

	-- TOP WARNING LIGHT (just one for performance)
	local topLight = Instance.new("Part")
	topLight.Name = "WarningLight"
	topLight.Shape = Enum.PartType.Ball
	topLight.Size = Vector3.new(5, 5, 5)
	topLight.Position = basePos + Vector3.new(0, 6 + TOWER_HEIGHT + 30, 0)
	topLight.Anchored = true
	topLight.Material = Enum.Material.Neon
	topLight.Color = RED
	topLight.CastShadow = false
	topLight.Parent = tower

	local pointLight = Instance.new("PointLight")
	pointLight.Color = RED
	pointLight.Range = 60
	pointLight.Brightness = 3
	pointLight.Parent = topLight

	-- Blink animation
	task.spawn(function()
		while topLight and topLight.Parent do
			pointLight.Brightness = 3
			topLight.Transparency = 0
			task.wait(1)
			pointLight.Brightness = 0.3
			topLight.Transparency = 0.6
			task.wait(1.5)
		end
	end)

	-- ELECTRIC WAVE EMITTER at top!
	local emitterPart = Instance.new("Part")
	emitterPart.Name = "WaveEmitter"
	emitterPart.Shape = Enum.PartType.Ball
	emitterPart.Size = Vector3.new(8, 8, 8)
	emitterPart.Position = basePos + Vector3.new(0, 6 + TOWER_HEIGHT + 35, 0)
	emitterPart.Anchored = true
	emitterPart.Transparency = 0.5
	emitterPart.Material = Enum.Material.Neon
	emitterPart.Color = station.color
	emitterPart.Parent = tower

	-- Electric wave particles (optimized - low rate)
	local waveEmitter = Instance.new("ParticleEmitter")
	waveEmitter.Name = "ElectricWaves"
	waveEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, station.color),
		ColorSequenceKeypoint.new(1, station.color),
	})
	waveEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	waveEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3),
		NumberSequenceKeypoint.new(1, 60),
	})
	waveEmitter.Texture = "rbxassetid://243098098" -- Ring/circle texture
	waveEmitter.Lifetime = NumberRange.new(2, 2.5)
	waveEmitter.Rate = 1  -- Reduced for performance
	waveEmitter.Speed = NumberRange.new(0, 0)
	waveEmitter.RotSpeed = NumberRange.new(10, 20)
	waveEmitter.Rotation = NumberRange.new(0, 360)
	waveEmitter.Parent = emitterPart

	-- Sparkle/electricity particles (reduced)
	local sparkEmitter = Instance.new("ParticleEmitter")
	sparkEmitter.Name = "Sparks"
	sparkEmitter.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
	sparkEmitter.Transparency = NumberSequence.new(0, 1)
	sparkEmitter.Size = NumberSequence.new(0.4, 0)
	sparkEmitter.Lifetime = NumberRange.new(0.3, 0.6)
	sparkEmitter.Rate = 5  -- Reduced for performance
	sparkEmitter.Speed = NumberRange.new(5, 15)
	sparkEmitter.SpreadAngle = Vector2.new(180, 180)
	sparkEmitter.LightEmission = 1
	sparkEmitter.Parent = emitterPart

	-- Station sign with post (text faces OUTWARD from tower)
	local signPost = Instance.new("Part")
	signPost.Name = "SignPost"
	signPost.Size = Vector3.new(1, 12, 1)
	signPost.Position = basePos + Vector3.new(12, 12, 0)
	signPost.Anchored = true
	signPost.Material = Enum.Material.Metal
	signPost.Color = Color3.fromRGB(80, 80, 80)
	signPost.CastShadow = false
	signPost.Parent = tower

	-- Sign board attached to FRONT of post (facing away from tower)
	local signPart = Instance.new("Part")
	signPart.Name = "SignBoard"
	signPart.Size = Vector3.new(14, 7, 0.5)
	signPart.CFrame = CFrame.new(basePos + Vector3.new(14, 14, 0)) -- In front of post
	signPart.Anchored = true
	signPart.Material = Enum.Material.SmoothPlastic
	signPart.Color = Color3.fromRGB(30, 30, 30)
	signPart.CastShadow = false
	signPart.Parent = tower

	-- GUI on BOTH sides
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "StationSign"
		gui.Face = face
		gui.Parent = signPart

		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundTransparency = 1
		frame.Parent = gui

		local frequency = Instance.new("TextLabel")
		frequency.Name = "Frequency"
		frequency.Size = UDim2.fromScale(1, 0.4)
		frequency.Position = UDim2.fromScale(0, 0)
		frequency.BackgroundTransparency = 1
		frequency.Text = station.frequency
		frequency.TextColor3 = station.color
		frequency.TextScaled = true
		frequency.Font = Enum.Font.SourceSansBold
		frequency.Parent = frame

		local stationNameLabel = Instance.new("TextLabel")
		stationNameLabel.Name = "StationName"
		stationNameLabel.Size = UDim2.fromScale(1, 0.35)
		stationNameLabel.Position = UDim2.fromScale(0, 0.4)
		stationNameLabel.BackgroundTransparency = 1
		stationNameLabel.Text = station.name
		stationNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		stationNameLabel.TextScaled = true
		stationNameLabel.Font = Enum.Font.SourceSansBold
		stationNameLabel.Parent = frame

		local genreLabel = Instance.new("TextLabel")
		genreLabel.Name = "Genre"
		genreLabel.Size = UDim2.fromScale(1, 0.25)
		genreLabel.Position = UDim2.fromScale(0, 0.75)
		genreLabel.BackgroundTransparency = 1
		genreLabel.Text = station.genre
		genreLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		genreLabel.TextScaled = true
		genreLabel.Font = Enum.Font.SourceSans
		genreLabel.Parent = frame
	end

	-- Store station index for reference
	tower:SetAttribute("StationIndex", index)
	tower:SetAttribute("StationName", station.name)
	tower:SetAttribute("Frequency", station.frequency)

	tower.Parent = musicFolder

	print("[Music] Built radio tower:", station.name, "- Height:", TOWER_HEIGHT + 35, "studs")
	return tower
end

-- ==========================================
-- CREATE WALKMAN PICKUP
-- ==========================================

local function createWalkman(spawnInfo: WalkmanSpawn)
	local walkman = Instance.new("Model")
	walkman.Name = "Walkman"

	-- Get terrain height at spawn position
	local terrainHeight = Shared.getTerrainHeight(spawnInfo.position.X, spawnInfo.position.Z)
	local basePos = Vector3.new(spawnInfo.position.X, terrainHeight + 0.5, spawnInfo.position.Z)

	-- Main body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(1.5, 0.4, 2.5)
	body.Position = basePos
	body.Anchored = true
	body.Material = Enum.Material.SmoothPlastic
	body.Color = Color3.fromRGB(50, 50, 60)
	body.CanCollide = false
	body.Parent = walkman
	walkman.PrimaryPart = body

	-- Screen/display
	local screen = Instance.new("Part")
	screen.Name = "Screen"
	screen.Size = Vector3.new(1.2, 0.1, 1.5)
	screen.Position = basePos + Vector3.new(0, 0.25, 0)
	screen.Anchored = true
	screen.Material = Enum.Material.Neon
	screen.Color = Color3.fromRGB(100, 200, 100)
	screen.CanCollide = false
	screen.Parent = walkman

	-- Weld screen to body
	local screenWeld = Instance.new("WeldConstraint")
	screenWeld.Part0 = body
	screenWeld.Part1 = screen
	screenWeld.Parent = screen

	-- Display text
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Display"
	gui.Face = Enum.NormalId.Top
	gui.Parent = screen

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "WALKMAN"
	label.TextColor3 = Color3.fromRGB(0, 50, 0)
	label.TextScaled = true
	label.Font = Enum.Font.Code
	label.Parent = gui

	-- Buttons
	for i = 1, 3 do
		local button = Instance.new("Part")
		button.Name = "Button" .. i
		button.Shape = Enum.PartType.Cylinder
		button.Size = Vector3.new(0.1, 0.3, 0.3)
		button.CFrame = CFrame.new(basePos + Vector3.new(-0.5 + (i * 0.4), 0.25, 1))
			* CFrame.Angles(0, 0, math.rad(90))
		button.Anchored = true
		button.Material = Enum.Material.SmoothPlastic
		button.Color = Color3.fromRGB(80, 80, 90)
		button.CanCollide = false
		button.Parent = walkman

		local buttonWeld = Instance.new("WeldConstraint")
		buttonWeld.Part0 = body
		buttonWeld.Part1 = button
		buttonWeld.Parent = button
	end

	-- Headphone jack
	local jack = Instance.new("Part")
	jack.Name = "Jack"
	jack.Shape = Enum.PartType.Cylinder
	jack.Size = Vector3.new(0.3, 0.15, 0.15)
	jack.CFrame = CFrame.new(basePos + Vector3.new(0.8, 0.1, 0))
		* CFrame.Angles(0, 0, math.rad(90))
	jack.Anchored = true
	jack.Material = Enum.Material.Metal
	jack.Color = Color3.fromRGB(180, 180, 180)
	jack.CanCollide = false
	jack.Parent = walkman

	-- Pickup prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickupPrompt"
	prompt.ActionText = "Pick Up"
	prompt.ObjectText = "Walkman"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.Parent = body

	-- Glow effect to make it visible
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(100, 200, 100)
	highlight.FillTransparency = 0.8
	highlight.OutlineColor = Color3.fromRGB(100, 200, 100)
	highlight.OutlineTransparency = 0.5
	highlight.Parent = walkman

	-- Handle pickup
	prompt.Triggered:Connect(function(player: Player)
		if not playerWalkmans[player] then return end
		if playerWalkmans[player].hasWalkman then return end

		-- Give walkman to player
		playerWalkmans[player].hasWalkman = true
		playerWalkmans[player].currentStation = nil -- Off initially

		-- Remove the walkman from world
		walkman:Destroy()

		-- Notify client
		pickupWalkmanEvent:FireClient(player, true)

		-- Announce
		print(player.Name .. " picked up a walkman!")
	end)

	walkman.Parent = musicFolder
	return walkman
end

-- ==========================================
-- PLAYER SETUP
-- ==========================================

local function setupPlayer(player: Player)
	playerWalkmans[player] = {
		hasWalkman = false,
		currentStation = nil,
		volume = 0.8,
	}

	-- Send station list to client
	local stationData = {}
	for i, station in ipairs(RADIO_STATIONS) do
		table.insert(stationData, {
			index = i,
			name = station.name,
			frequency = station.frequency,
			genre = station.genre,
			description = station.description,
			mood = station.mood,
			color = { station.color.R, station.color.G, station.color.B },
			tracks = station.tracks,
			announcer = station.announcer,
		})
	end

	-- Wait for character then send data
	task.spawn(function()
		player.CharacterAdded:Wait()
		task.wait(1)
		walkmanStatusEvent:FireClient(player, {
			hasWalkman = false,
			stations = stationData,
		})
	end)
end

local function cleanupPlayer(player: Player)
	playerWalkmans[player] = nil
end

-- ==========================================
-- REMOTE EVENT HANDLERS
-- ==========================================

-- Player tunes to a station
tuneStationEvent.OnServerEvent:Connect(function(player: Player, stationIndex: number?)
	if not playerWalkmans[player] then return end
	if not playerWalkmans[player].hasWalkman then return end

	-- Validate station index
	if stationIndex ~= nil then
		if stationIndex < 1 or stationIndex > #RADIO_STATIONS then
			return
		end
	end

	playerWalkmans[player].currentStation = stationIndex

	-- Confirm to client
	if stationIndex then
		local station = RADIO_STATIONS[stationIndex]
		tuneStationEvent:FireClient(player, {
			index = stationIndex,
			name = station.name,
			frequency = station.frequency,
			tracks = station.tracks,
		})
	else
		tuneStationEvent:FireClient(player, nil)
	end
end)

-- ==========================================
-- DEFAULT AMBIENT MUSIC
-- Always plays when not near any radio station
-- ==========================================

local DEFAULT_AMBIENT = {
	name = "Wilderness Ambient",
	genre = "Nature Sounds",
	description = "The sounds of the wild...",
	frequency = "---.- FM",
	mood = "Atmospheric",
	tracks = {
		"rbxassetid://9043887091", -- Ambient nature
		"rbxassetid://1839841276", -- Atmospheric
	},
}

-- ==========================================
-- PROXIMITY DETECTION
-- Updates clients about nearby radio towers
-- MUSIC NEVER STOPS - defaults to ambient when no stations nearby
-- ==========================================

local function updateProximity()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then continue end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then continue end

		local playerPos = rootPart.Position
		local nearbyStations = {}

		for i, station in ipairs(RADIO_STATIONS) do
			local distance = (playerPos - station.position).Magnitude
			if distance <= station.range then
				local strength = 1 - (distance / station.range)
				table.insert(nearbyStations, {
					index = i,
					name = station.name,
					frequency = station.frequency,
					strength = strength,
					distance = distance,
				})
			end
		end

		-- Sort by strength (strongest first)
		table.sort(nearbyStations, function(a, b)
			return a.strength > b.strength
		end)

		-- MUSIC NEVER STOPS! If no stations nearby, add default ambient
		if #nearbyStations == 0 then
			table.insert(nearbyStations, {
				index = 0, -- Special index for default ambient
				name = DEFAULT_AMBIENT.name,
				frequency = DEFAULT_AMBIENT.frequency,
				strength = 0.5, -- Medium strength
				distance = 0,
				isDefault = true,
				tracks = DEFAULT_AMBIENT.tracks,
			})
		end

		radioProximityEvent:FireClient(player, nearbyStations)
	end
end

-- ==========================================
-- RADIO SPEAKER FOR OBJECTS (buildings, camels, etc)
-- Uses spatial audio for performance
-- ==========================================

local function attachRadioSpeaker(part: BasePart, range: number?, volume: number?): Sound?
	if not part then return nil end

	-- Find nearest station based on part position
	local nearestStation: RadioStation? = nil
	local nearestDist = math.huge

	for _, station in ipairs(RADIO_STATIONS) do
		local dist = (part.Position - station.position).Magnitude
		if dist < nearestDist then
			nearestDist = dist
			nearestStation = station
		end
	end

	if not nearestStation then return nil end

	-- Create spatial audio speaker
	local sound = Instance.new("Sound")
	sound.Name = "RadioSpeaker"
	sound.SoundId = nearestStation.tracks[math.random(1, #nearestStation.tracks)]
	sound.Volume = volume or 0.4
	sound.Looped = true
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMinDistance = 10
	sound.RollOffMaxDistance = range or 100
	sound.Parent = part
	sound:Play()

	return sound
end

local function attachRadiosToBuildings()
	-- Wait for buildings to spawn
	task.wait(8)

	local buildingsWithRadios = 0
	local maxBuildingRadios = 15 -- Limit for performance

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if buildingsWithRadios >= maxBuildingRadios then break end

		-- Find abandoned buildings by their name pattern
		if obj:IsA("Model") and (string.find(obj.Name, "Building") or string.find(obj.Name, "Office")) then
			local primaryPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
			if primaryPart then
				attachRadioSpeaker(primaryPart, 80, 0.3)
				buildingsWithRadios += 1
			end
		end
	end

	print("[Music] Attached radios to", buildingsWithRadios, "buildings")
end

local function attachRadioToCamels()
	-- Wait for camels to spawn
	task.wait(10)

	local camelsWithRadios = 0

	for _, obj in ipairs(Workspace:GetDescendants()) do
		-- Companions are named "Companion_Pickles", "Companion_Gerald", etc.
		if obj:IsA("Model") and string.find(obj.Name, "Companion_") then
			local body = obj:FindFirstChild("Body") :: BasePart?
			if body then
				local sound = attachRadioSpeaker(body, 40, 0.25)
				if sound then
					-- Special camel music - always plays "Camel Country" station
					for _, station in ipairs(RADIO_STATIONS) do
						if station.name == "Camel Country" then
							sound.SoundId = station.tracks[math.random(1, #station.tracks)]
							break
						end
					end
					camelsWithRadios += 1
				end
			end
		end
	end

	print("[Music] Attached radios to", camelsWithRadios, "camel companions")
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

local function initialize()
	print("[Music] Initializing radio stations...")

	-- Create radio towers
	for i, station in ipairs(RADIO_STATIONS) do
		createRadioTower(station, i)
		print("[Music] Created tower: " .. station.name .. " (" .. station.frequency .. ")")
	end

	-- Create walkman pickups
	for _, spawn in ipairs(WALKMAN_SPAWNS) do
		createWalkman(spawn)
	end
	print("[Music] Spawned " .. #WALKMAN_SPAWNS .. " walkmans")

	-- Setup existing players
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	-- Listen for new players
	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(cleanupPlayer)

	-- Start proximity update loop (performance: updates every 2 seconds)
	task.spawn(function()
		while true do
			updateProximity()
			task.wait(2) -- Update every 2 seconds for performance
		end
	end)

	-- Attach radios to buildings and camels (in background for performance)
	task.spawn(attachRadiosToBuildings)
	task.spawn(attachRadioToCamels)

	print("[Music] Radio system online! " .. #RADIO_STATIONS .. " stations broadcasting")
	print("[Music] MUSIC NEVER STOPS - default ambient plays when no stations nearby")
	print("[Music] Radios will be attached to buildings and camels shortly...")
end

initialize()
