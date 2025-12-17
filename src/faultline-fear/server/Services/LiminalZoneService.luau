--!strict
--[[
	Faultline Fear: Liminal Zone Service

	Manages eerie "liminal space" zones that create unsettling atmosphere:
	- Empty, abandoned spaces that feel "off"
	- Music mutes in these zones
	- Special ambient audio (HVAC hum, electrical buzz)
	- Distinct lighting (harsh fluorescent)
	- Earthquake damage adds to wrongness

	Liminal Zones:
	- Abandoned Mall: Fluorescent lights, empty stores, muzak
	- Hotel Lobby: Grand but empty, stopped clocks, luggage
	- School: Neat desks, homework on boards, bell system
	- Hospital: Gurneys, beeping equipment, flickering lights
	- Highway Underpass: Sodium lights, graffiti, echoes

	Exports: Initialize(), IsPlayerInLiminalZone(), GetLiminalZones()
	Depends: Config, Heightmap, AssetManifest
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local _Config = Shared.Config
local Heightmap = Shared.Heightmap
local AssetManifest = Shared.AssetManifest

local LiminalZoneService = {}

-- State
local liminalZones: { Model } = {}
local liminalFolder: Folder = nil :: any
local playerInLiminal: { [Player]: string? } = {} -- nil = not in liminal, string = zone name

-- Remote events
local LiminalEvent: RemoteEvent = nil :: any

-- Liminal zone definitions
type LiminalZoneDef = {
	name: string,
	position: Vector3,
	rotation: number,
	size: Vector3, -- Interior size
	zoneType: string, -- mall, hotel, school, hospital, underpass
	ambientSound: string, -- Sound category
	lightColor: Color3,
	lightFlicker: boolean,
	description: string,
}

local LIMINAL_DEFINITIONS: { LiminalZoneDef } = {
	-- Abandoned Mall - in Town area
	{
		name = "AbandonedMall",
		position = Vector3.new(-150, 0, 800),
		rotation = 0,
		size = Vector3.new(80, 12, 60),
		zoneType = "mall",
		ambientSound = "fluorescent_hum",
		lightColor = Color3.fromRGB(255, 250, 240), -- Harsh white
		lightFlicker = true,
		description = "Empty mall with lights still on",
	},
	-- Hotel Lobby - near Town
	{
		name = "HotelLobby",
		position = Vector3.new(200, 0, 750),
		rotation = 45,
		size = Vector3.new(40, 15, 50),
		zoneType = "hotel",
		ambientSound = "elevator_music",
		lightColor = Color3.fromRGB(255, 235, 200), -- Warm but empty
		lightFlicker = false,
		description = "Grand lobby, clocks stopped at quake time",
	},
	-- School - edge of Town
	{
		name = "AbandonedSchool",
		position = Vector3.new(-50, 0, 950),
		rotation = 15,
		size = Vector3.new(60, 10, 40),
		zoneType = "school",
		ambientSound = "hvac_drone",
		lightColor = Color3.fromRGB(255, 255, 255),
		lightFlicker = true,
		description = "Desks arranged neatly, homework on boards",
	},
	-- Hospital - between Town and Valley
	{
		name = "Hospital",
		position = Vector3.new(100, 0, 650),
		rotation = -30,
		size = Vector3.new(50, 14, 70),
		zoneType = "hospital",
		ambientSound = "beeping_equipment",
		lightColor = Color3.fromRGB(230, 255, 230), -- Sickly green tint
		lightFlicker = true,
		description = "Gurneys in hallways, beeping monitors",
	},
	-- Highway Underpass - near Fault Line
	{
		name = "HighwayUnderpass",
		position = Vector3.new(0, 0, 500),
		rotation = 90,
		size = Vector3.new(30, 8, 80),
		zoneType = "underpass",
		ambientSound = "distant_traffic",
		lightColor = Color3.fromRGB(255, 180, 100), -- Sodium orange
		lightFlicker = false,
		description = "Orange lights, graffiti, echo chamber",
	},
}

-- ==========================================
-- PLACEHOLDER CREATION
-- ==========================================

local function createPlaceholderZone(def: LiminalZoneDef): Model
	local model = Instance.new("Model")
	model.Name = def.name .. "_Placeholder"

	-- Floor
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(def.size.X, 0.5, def.size.Z)
	floor.Position = Vector3.new(0, 0.25, 0)
	floor.Anchored = true
	floor.CanCollide = true

	-- Different floor materials by zone type
	if def.zoneType == "mall" then
		floor.Material = Enum.Material.Marble
		floor.Color = Color3.fromRGB(200, 195, 190)
	elseif def.zoneType == "hotel" then
		floor.Material = Enum.Material.Fabric
		floor.Color = Color3.fromRGB(120, 80, 80)
	elseif def.zoneType == "school" then
		floor.Material = Enum.Material.SmoothPlastic
		floor.Color = Color3.fromRGB(180, 170, 160)
	elseif def.zoneType == "hospital" then
		floor.Material = Enum.Material.SmoothPlastic
		floor.Color = Color3.fromRGB(220, 220, 210)
	else
		floor.Material = Enum.Material.Concrete
		floor.Color = Color3.fromRGB(100, 100, 100)
	end

	floor.Parent = model

	-- Walls
	local wallHeight = def.size.Y
	local wallThickness = 1

	local walls = {
		{ Vector3.new(wallThickness, wallHeight, def.size.Z), Vector3.new(-def.size.X / 2, wallHeight / 2, 0) },
		{ Vector3.new(wallThickness, wallHeight, def.size.Z), Vector3.new(def.size.X / 2, wallHeight / 2, 0) },
		{ Vector3.new(def.size.X, wallHeight, wallThickness), Vector3.new(0, wallHeight / 2, -def.size.Z / 2) },
		{ Vector3.new(def.size.X, wallHeight, wallThickness), Vector3.new(0, wallHeight / 2, def.size.Z / 2) },
	}

	for i, wallData in ipairs(walls) do
		local wall = Instance.new("Part")
		wall.Name = "Wall" .. i
		wall.Size = wallData[1]
		wall.Position = wallData[2]
		wall.Anchored = true
		wall.CanCollide = true
		wall.Material = Enum.Material.Concrete
		wall.Color = Color3.fromRGB(200, 195, 190)
		wall.Parent = model
	end

	-- Ceiling
	local ceiling = Instance.new("Part")
	ceiling.Name = "Ceiling"
	ceiling.Size = Vector3.new(def.size.X, 0.5, def.size.Z)
	ceiling.Position = Vector3.new(0, wallHeight, 0)
	ceiling.Anchored = true
	ceiling.CanCollide = true
	ceiling.Material = Enum.Material.SmoothPlastic
	ceiling.Color = Color3.fromRGB(220, 220, 220)
	ceiling.Parent = model

	-- Fluorescent lights
	local numLights = math.floor(def.size.X / 15)
	for i = 1, numLights do
		local light = Instance.new("Part")
		light.Name = "FluorescentLight" .. i
		light.Size = Vector3.new(4, 0.2, 1)
		light.Position = Vector3.new(-def.size.X / 2 + (i / (numLights + 1)) * def.size.X, wallHeight - 0.3, 0)
		light.Anchored = true
		light.CanCollide = false
		light.Material = Enum.Material.Neon
		light.Color = def.lightColor
		light.Parent = model

		-- Add actual light source
		local pointLight = Instance.new("PointLight")
		pointLight.Name = "Light"
		pointLight.Color = def.lightColor
		pointLight.Brightness = 2
		pointLight.Range = 20
		pointLight.Parent = light

		-- Mark for flicker effect
		if def.lightFlicker then
			CollectionService:AddTag(light, "FlickerLight")
		end
	end

	-- Interior detection zone (invisible)
	local interiorZone = Instance.new("Part")
	interiorZone.Name = "InteriorZone"
	interiorZone.Size = def.size
	interiorZone.Position = Vector3.new(0, def.size.Y / 2, 0)
	interiorZone.Anchored = true
	interiorZone.CanCollide = false
	interiorZone.Transparency = 1
	interiorZone.Parent = model

	-- Entrance (gap in one wall)
	local entrance = Instance.new("Part")
	entrance.Name = "EntranceMarker"
	entrance.Size = Vector3.new(6, 8, 1)
	entrance.Position = Vector3.new(0, 4, def.size.Z / 2)
	entrance.Anchored = true
	entrance.CanCollide = false
	entrance.Transparency = 1
	entrance.Parent = model

	model.PrimaryPart = floor
	return model
end

-- ==========================================
-- ZONE-SPECIFIC DETAILS
-- ==========================================

local function addMallDetails(model: Model, def: LiminalZoneDef)
	-- Empty store displays
	local numStores = 4
	for i = 1, numStores do
		local display = Instance.new("Part")
		display.Name = "StoreDisplay" .. i
		display.Size = Vector3.new(8, 6, 2)
		display.Position = Vector3.new(-def.size.X / 2 + (i / (numStores + 1)) * def.size.X, 3, -def.size.Z / 2 + 3)
		display.Anchored = true
		display.Transparency = 0.7
		display.Material = Enum.Material.Glass
		display.Color = Color3.fromRGB(200, 220, 255)
		display.Parent = model
	end

	-- Benches
	for i = 1, 2 do
		local bench = Instance.new("Part")
		bench.Name = "Bench" .. i
		bench.Size = Vector3.new(4, 1.5, 1.5)
		bench.Position = Vector3.new((i - 1.5) * 15, 0.75, 0)
		bench.Anchored = true
		bench.Material = Enum.Material.Metal
		bench.Color = Color3.fromRGB(100, 100, 100)
		bench.Parent = model
	end
end

local function addHotelDetails(model: Model, _def: LiminalZoneDef)
	-- Front desk
	local desk = Instance.new("Part")
	desk.Name = "FrontDesk"
	desk.Size = Vector3.new(15, 3.5, 3)
	desk.Position = Vector3.new(0, 1.75, -15)
	desk.Anchored = true
	desk.Material = Enum.Material.Wood
	desk.Color = Color3.fromRGB(80, 50, 30)
	desk.Parent = model

	-- Chandelier (decorative)
	local chandelier = Instance.new("Part")
	chandelier.Name = "Chandelier"
	chandelier.Size = Vector3.new(5, 3, 5)
	chandelier.Position = Vector3.new(0, 12, 0)
	chandelier.Anchored = true
	chandelier.Shape = Enum.PartType.Ball
	chandelier.Material = Enum.Material.Glass
	chandelier.Color = Color3.fromRGB(255, 240, 200)
	chandelier.Parent = model

	local chandelierLight = Instance.new("PointLight")
	chandelierLight.Brightness = 1
	chandelierLight.Range = 30
	chandelierLight.Color = Color3.fromRGB(255, 235, 200)
	chandelierLight.Parent = chandelier

	-- Abandoned luggage
	for i = 1, 3 do
		local luggage = Instance.new("Part")
		luggage.Name = "Luggage" .. i
		luggage.Size = Vector3.new(1.5, 2, 1)
		luggage.Position = Vector3.new(-5 + i * 3 + math.random() * 2, 1, 10 + math.random() * 3)
		luggage.Rotation = Vector3.new(0, math.random() * 30, 0)
		luggage.Anchored = true
		luggage.Material = Enum.Material.Fabric
		luggage.Color = Color3.fromRGB(math.random(60, 120), math.random(40, 80), math.random(40, 80))
		luggage.Parent = model
	end
end

local function addSchoolDetails(model: Model, def: LiminalZoneDef)
	-- Desks in rows
	local rows = 4
	local cols = 5
	for r = 1, rows do
		for c = 1, cols do
			local desk = Instance.new("Part")
			desk.Name = "Desk_" .. r .. "_" .. c
			desk.Size = Vector3.new(2, 2.5, 1.5)
			desk.Position = Vector3.new(-def.size.X / 2 + 10 + (c - 1) * 6, 1.25, -def.size.Z / 2 + 8 + (r - 1) * 5)
			desk.Anchored = true
			desk.Material = Enum.Material.Wood
			desk.Color = Color3.fromRGB(180, 150, 100)
			desk.Parent = model
		end
	end

	-- Chalkboard
	local board = Instance.new("Part")
	board.Name = "Chalkboard"
	board.Size = Vector3.new(12, 4, 0.3)
	board.Position = Vector3.new(0, 5, -def.size.Z / 2 + 1)
	board.Anchored = true
	board.Material = Enum.Material.SmoothPlastic
	board.Color = Color3.fromRGB(30, 50, 30)
	board.Parent = model

	-- Clock (stopped)
	local clock = Instance.new("Part")
	clock.Name = "Clock"
	clock.Size = Vector3.new(1.5, 1.5, 0.2)
	clock.Position = Vector3.new(10, 7, -def.size.Z / 2 + 0.5)
	clock.Shape = Enum.PartType.Cylinder
	clock.Anchored = true
	clock.Material = Enum.Material.SmoothPlastic
	clock.Color = Color3.fromRGB(240, 230, 220)
	clock.Parent = model
end

local function addHospitalDetails(model: Model, def: LiminalZoneDef)
	-- Gurney
	local gurney = Instance.new("Part")
	gurney.Name = "Gurney"
	gurney.Size = Vector3.new(2.5, 2.5, 7)
	gurney.Position = Vector3.new(5, 1.25, 0)
	gurney.Rotation = Vector3.new(0, 15, 0)
	gurney.Anchored = true
	gurney.Material = Enum.Material.Metal
	gurney.Color = Color3.fromRGB(220, 220, 220)
	gurney.Parent = model

	-- Medical equipment
	local monitor = Instance.new("Part")
	monitor.Name = "Monitor"
	monitor.Size = Vector3.new(1, 1.5, 0.5)
	monitor.Position = Vector3.new(-def.size.X / 2 + 3, 4, 10)
	monitor.Anchored = true
	monitor.Material = Enum.Material.SmoothPlastic
	monitor.Color = Color3.fromRGB(50, 50, 50)
	monitor.Parent = model

	-- Screen glow
	local screenLight = Instance.new("PointLight")
	screenLight.Color = Color3.fromRGB(0, 255, 100)
	screenLight.Brightness = 0.5
	screenLight.Range = 5
	screenLight.Parent = monitor

	-- IV Stand
	local ivStand = Instance.new("Part")
	ivStand.Name = "IVStand"
	ivStand.Size = Vector3.new(0.2, 5, 0.2)
	ivStand.Position = Vector3.new(7, 2.5, 0)
	ivStand.Anchored = true
	ivStand.Material = Enum.Material.Metal
	ivStand.Color = Color3.fromRGB(180, 180, 180)
	ivStand.Parent = model
end

local function addUnderpassDetails(model: Model, def: LiminalZoneDef)
	-- Support pillars
	for i = 1, 3 do
		local pillar = Instance.new("Part")
		pillar.Name = "Pillar" .. i
		pillar.Size = Vector3.new(3, def.size.Y, 3)
		pillar.Position = Vector3.new(0, def.size.Y / 2, -def.size.Z / 2 + i * 20)
		pillar.Anchored = true
		pillar.Material = Enum.Material.Concrete
		pillar.Color = Color3.fromRGB(120, 120, 120)
		pillar.Parent = model
	end

	-- Graffiti panel (colored section on wall)
	local graffiti = Instance.new("Part")
	graffiti.Name = "Graffiti"
	graffiti.Size = Vector3.new(0.1, 4, 10)
	graffiti.Position = Vector3.new(-def.size.X / 2 + 0.5, 3, 0)
	graffiti.Anchored = true
	graffiti.Material = Enum.Material.SmoothPlastic
	graffiti.Color = Color3.fromRGB(math.random(100, 255), math.random(50, 200), math.random(50, 200))
	graffiti.Parent = model

	-- Abandoned camp (tent-like shape)
	local tent = Instance.new("Part")
	tent.Name = "AbandonedCamp"
	tent.Size = Vector3.new(4, 3, 4)
	tent.Position = Vector3.new(8, 1.5, 15)
	tent.Anchored = true
	tent.Material = Enum.Material.Fabric
	tent.Color = Color3.fromRGB(80, 100, 80)
	tent.Parent = model
end

-- ==========================================
-- ZONE SPAWNING
-- ==========================================

local function spawnLiminalZone(def: LiminalZoneDef): Model
	-- Try imported model
	local assetName = def.name
	local model = AssetManifest:CloneAsset(assetName)

	if not model then
		model = createPlaceholderZone(def)
	end

	-- Get terrain height
	local y = Heightmap:GetHeight(def.position.X, def.position.Z)

	-- Position and rotate
	local cframe = CFrame.new(def.position.X, y, def.position.Z) * CFrame.Angles(0, math.rad(def.rotation), 0)

	if model.PrimaryPart then
		model:PivotTo(cframe)
	end

	-- Set properties
	model.Name = def.name
	model:SetAttribute("ZoneType", def.zoneType)
	model:SetAttribute("AmbientSound", def.ambientSound)
	model:SetAttribute("LightColor", def.lightColor:ToHex())
	model:SetAttribute("LightFlicker", def.lightFlicker)
	model:SetAttribute("Description", def.description)

	-- Tags
	CollectionService:AddTag(model, "LiminalZone")

	-- Add zone-specific details to placeholder
	if string.find(model.Name, "_Placeholder") then
		if def.zoneType == "mall" then
			addMallDetails(model, def)
		elseif def.zoneType == "hotel" then
			addHotelDetails(model, def)
		elseif def.zoneType == "school" then
			addSchoolDetails(model, def)
		elseif def.zoneType == "hospital" then
			addHospitalDetails(model, def)
		elseif def.zoneType == "underpass" then
			addUnderpassDetails(model, def)
		end
	end

	-- Setup interior detection
	local interiorZone = model:FindFirstChild("InteriorZone")
	if interiorZone and interiorZone:IsA("BasePart") then
		interiorZone.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				local wasIn = playerInLiminal[player]
				playerInLiminal[player] = def.name

				if wasIn ~= def.name then
					-- Player entered this zone
					print(string.format("[LiminalZoneService] %s entered %s", player.Name, def.name))

					-- Notify client
					if LiminalEvent then
						LiminalEvent:FireClient(player, {
							type = "enter",
							zone = def.name,
							zoneType = def.zoneType,
							ambientSound = def.ambientSound,
						})
					end
				end
			end
		end)

		interiorZone.TouchEnded:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player and playerInLiminal[player] == def.name then
				playerInLiminal[player] = nil

				print(string.format("[LiminalZoneService] %s exited %s", player.Name, def.name))

				-- Notify client
				if LiminalEvent then
					LiminalEvent:FireClient(player, {
						type = "exit",
						zone = def.name,
					})
				end
			end
		end)
	end

	model.Parent = liminalFolder
	table.insert(liminalZones, model)

	return model
end

-- ==========================================
-- LIGHT FLICKER EFFECT
-- ==========================================

local flickerLights: { PointLight } = {}
local flickerTime: number = 0

local function updateLightFlicker(dt: number)
	flickerTime += dt

	for _, light in ipairs(flickerLights) do
		if light.Parent then
			-- Random flicker pattern
			local baseIntensity = 2
			local flicker = 1

			-- Occasional full flicker
			if math.random() < 0.01 then
				flicker = math.random() * 0.3
			else
				-- Use instance address from tostring as unique offset (GetHashCode doesn't exist in Luau)
				local addressMatch = tostring(light):match("%x+$")
				local lightId = addressMatch and tonumber(addressMatch, 16) or 0
				flicker = 0.8 + math.sin(flickerTime * 10 + lightId * 0.0001) * 0.2
			end

			light.Brightness = baseIntensity * flicker
		end
	end
end

-- ==========================================
-- PUBLIC API
-- ==========================================

function LiminalZoneService:GetLiminalZones(): { Model }
	return liminalZones
end

function LiminalZoneService:GetZoneByName(name: string): Model?
	for _, zone in ipairs(liminalZones) do
		if zone.Name == name then
			return zone
		end
	end
	return nil
end

function LiminalZoneService:IsPlayerInLiminalZone(player: Player): boolean
	return playerInLiminal[player] ~= nil
end

function LiminalZoneService:GetPlayerLiminalZone(player: Player): string?
	return playerInLiminal[player]
end

function LiminalZoneService:GetPlayersInLiminalZones(): { Player }
	local result = {}
	for player, zone in pairs(playerInLiminal) do
		if zone and player.Parent then
			table.insert(result, player)
		end
	end
	return result
end

function LiminalZoneService:Initialize()
	-- Create folder
	liminalFolder = Instance.new("Folder")
	liminalFolder.Name = "LiminalZones"
	liminalFolder.Parent = Workspace

	-- Create remote event
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local liminalEvent = remotes:FindFirstChild("LiminalEvent")
	if not liminalEvent then
		liminalEvent = Instance.new("RemoteEvent")
		liminalEvent.Name = "LiminalEvent"
		liminalEvent.Parent = remotes
	end
	LiminalEvent = liminalEvent :: RemoteEvent

	-- Spawn all liminal zones
	print("[LiminalZoneService] Creating liminal space zones...")

	for _, def in ipairs(LIMINAL_DEFINITIONS) do
		local zone = spawnLiminalZone(def)
		print(string.format("  - %s (%s) at (%.0f, %.0f)", def.name, def.zoneType, def.position.X, def.position.Z))

		-- Collect flicker lights
		for _, desc in zone:GetDescendants() do
			if desc:IsA("PointLight") then
				local parent = desc.Parent
				if parent and CollectionService:HasTag(parent, "FlickerLight") then
					table.insert(flickerLights, desc)
				end
			end
		end
	end

	-- Start flicker update loop
	RunService.Heartbeat:Connect(updateLightFlicker)

	-- Clean up on player leave
	Players.PlayerRemoving:Connect(function(player)
		playerInLiminal[player] = nil
	end)

	print(string.format("[LiminalZoneService] Initialized with %d liminal zones", #liminalZones))
end

return LiminalZoneService
