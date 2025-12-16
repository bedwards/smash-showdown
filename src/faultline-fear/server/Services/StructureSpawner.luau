--!strict
--[[
	Faultline Fear: Structure Spawner

	Places landmark structures in the world.
	Uses AssetManifest for imported models, falls back to placeholders.
	Uses Heightmap for terrain-aware placement.

	Structures:
	- Ferris Wheel (Beach) - Rotating beacon
	- Radio Tower (Mountain) - Rescue beacon
	- Water Tower (Valley) - Town landmark
	- Lighthouse (Coastal) - Coastal beacon
	- Abandoned Houses (Valley/Coastal) - Town buildings
	- Bridge (Fault Line) - Crossing point

	Exports: Initialize(), GetStructure()
	Depends: Config, Heightmap, AssetManifest
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config
local Heightmap = Shared.Heightmap
local AssetManifest = Shared.AssetManifest

local StructureSpawner = {}

-- Folder for structures
local structuresFolder: Folder = nil :: any

-- Structure definitions with placement info
type StructureDef = {
	name: string,
	assetName: string,
	zone: string,
	position: Vector3?, -- Specific position, or calculated from zone
	rotation: number, -- Y rotation in degrees
	flattenRadius: number, -- Radius to flatten terrain (0 = no flattening)
	scale: number, -- Scale multiplier
	beacon: boolean, -- Is this a navigation beacon?
}

local STRUCTURE_DEFS: { StructureDef } = {
	-- BEACH ZONE - Ferris Wheel
	{
		name = "FerrisWheel_Main",
		assetName = "FerrisWheel",
		zone = "BEACH",
		position = Vector3.new(200, 0, -1000), -- Specific beach location
		rotation = 0,
		flattenRadius = 30,
		scale = 1,
		beacon = true,
	},

	-- COASTAL ZONE - Lighthouse
	{
		name = "Lighthouse_Main",
		assetName = "Lighthouse",
		zone = "COASTAL",
		position = Vector3.new(-400, 0, -600), -- Coastal cliff
		rotation = 45,
		flattenRadius = 15,
		scale = 1,
		beacon = true,
	},

	-- VALLEY ZONE - Water Tower
	{
		name = "WaterTower_Main",
		assetName = "WaterTower",
		zone = "VALLEY",
		position = Vector3.new(0, 0, 100), -- Town center
		rotation = 0,
		flattenRadius = 20,
		scale = 1,
		beacon = true,
	},

	-- VALLEY ZONE - Abandoned Houses
	{
		name = "House_1",
		assetName = "AbandonedHouse",
		zone = "VALLEY",
		position = Vector3.new(-100, 0, 50),
		rotation = 15,
		flattenRadius = 15,
		scale = 1,
		beacon = false,
	},
	{
		name = "House_2",
		assetName = "AbandonedHouse",
		zone = "VALLEY",
		position = Vector3.new(80, 0, 150),
		rotation = -30,
		flattenRadius = 15,
		scale = 1,
		beacon = false,
	},
	{
		name = "House_3",
		assetName = "AbandonedHouse",
		zone = "COASTAL",
		position = Vector3.new(-150, 0, -400),
		rotation = 90,
		flattenRadius = 15,
		scale = 1,
		beacon = false,
	},
	{
		name = "House_4",
		assetName = "AbandonedHouse",
		zone = "COASTAL",
		position = Vector3.new(200, 0, -350),
		rotation = 180,
		flattenRadius = 15,
		scale = 1.1,
		beacon = false,
	},

	-- FAULT LINE ZONE - Bridge
	{
		name = "Bridge_Main",
		assetName = "Bridge",
		zone = "FAULT_LINE",
		position = Vector3.new(0, 0, 600), -- Main crossing
		rotation = 0,
		flattenRadius = 0, -- Don't flatten for bridge
		scale = 1,
		beacon = false,
	},
	{
		name = "Bridge_East",
		assetName = "Bridge",
		zone = "FAULT_LINE",
		position = Vector3.new(500, 0, 650),
		rotation = 15,
		flattenRadius = 0,
		scale = 0.8, -- Smaller secondary bridge
		beacon = false,
	},

	-- MOUNTAIN ZONE - Radio Tower
	{
		name = "RadioTower_Main",
		assetName = "RadioTower",
		zone = "MOUNTAIN",
		position = Vector3.new(0, 0, 1700), -- Near summit
		rotation = 0,
		flattenRadius = 25,
		scale = 1,
		beacon = true,
	},
}

-- ==========================================
-- PLACEHOLDER CREATION
-- ==========================================

local function createPlaceholderStructure(def: StructureDef): Model
	local model = Instance.new("Model")
	model.Name = def.name .. "_Placeholder"

	-- Create a simple colored box
	local part = Instance.new("Part")
	part.Name = "Main"
	part.Anchored = true
	part.CanCollide = true

	-- Size based on structure type
	local sizes: { [string]: Vector3 } = {
		FerrisWheel = Vector3.new(40, 45, 10),
		RadioTower = Vector3.new(15, 60, 15),
		WaterTower = Vector3.new(15, 35, 15),
		Lighthouse = Vector3.new(10, 30, 10),
		AbandonedHouse = Vector3.new(25, 20, 20),
		Bridge = Vector3.new(80, 5, 15),
	}

	local colors: { [string]: Color3 } = {
		FerrisWheel = Color3.fromRGB(200, 50, 50),
		RadioTower = Color3.fromRGB(200, 200, 200),
		WaterTower = Color3.fromRGB(100, 150, 200),
		Lighthouse = Color3.fromRGB(255, 255, 240),
		AbandonedHouse = Color3.fromRGB(150, 130, 110),
		Bridge = Color3.fromRGB(120, 120, 130),
	}

	part.Size = sizes[def.assetName] or Vector3.new(20, 20, 20)
	part.Color = colors[def.assetName] or Color3.fromRGB(150, 150, 150)
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = model

	model.PrimaryPart = part

	-- Add beacon light for beacon structures
	if def.beacon then
		local light = Instance.new("PointLight")
		light.Brightness = 3
		light.Range = 100
		light.Color = Color3.fromRGB(255, 200, 100)
		light.Parent = part

		-- Beacon effect (would need attachments, skip for placeholder)
	end

	return model
end

-- ==========================================
-- STRUCTURE SPAWNING
-- ==========================================

local function spawnStructure(def: StructureDef): Model?
	-- Try to get imported model
	local model = AssetManifest:CloneAsset(def.assetName)

	if model then
		print(string.format("[StructureSpawner] Using imported model for %s", def.name))
	else
		-- Create placeholder
		model = createPlaceholderStructure(def)
		print(string.format("[StructureSpawner] Using placeholder for %s (asset not imported)", def.name))
	end

	-- Calculate position
	local x: number, z: number
	if def.position then
		x, z = def.position.X, def.position.Z
	else
		-- Calculate from zone
		local zoneConfig = Config.ZONES[def.zone]
		if zoneConfig then
			x = math.random(-Config.WORLD_SIZE / 4, Config.WORLD_SIZE / 4)
			z = (zoneConfig.zMin + zoneConfig.zMax) / 2
		else
			x, z = 0, 0
		end
	end

	-- Flatten terrain if needed
	local y: number
	if def.flattenRadius > 0 then
		y = Heightmap:FlattenArea(x, z, def.flattenRadius)
	else
		y = Heightmap:GetHeight(x, z)
	end

	-- Apply scale
	if def.scale ~= 1 and model.PrimaryPart then
		-- Scale all parts
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Size = part.Size * def.scale
			end
		end
	end

	-- Position and rotate
	local cframe = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(def.rotation), 0)

	if model.PrimaryPart then
		-- Offset by half height so bottom is at ground level
		local halfHeight = model.PrimaryPart.Size.Y / 2
		cframe = cframe + Vector3.new(0, halfHeight, 0)
		model:PivotTo(cframe)
	end

	-- Set name and tags
	model.Name = def.name
	CollectionService:AddTag(model, "Structure")
	CollectionService:AddTag(model, def.assetName)
	if def.beacon then
		CollectionService:AddTag(model, "Beacon")
	end

	-- Set attributes
	model:SetAttribute("StructureType", def.assetName)
	model:SetAttribute("Zone", def.zone)
	model:SetAttribute("IsBeacon", def.beacon)

	-- Parent to folder
	model.Parent = structuresFolder

	return model
end

-- ==========================================
-- PUBLIC API
-- ==========================================

function StructureSpawner:GetStructure(name: string): Model?
	return structuresFolder:FindFirstChild(name) :: Model?
end

function StructureSpawner:GetStructuresByType(assetName: string): { Model }
	local results = {}
	for _, model in structuresFolder:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("StructureType") == assetName then
			table.insert(results, model)
		end
	end
	return results
end

function StructureSpawner:GetBeacons(): { Model }
	local results = {}
	for _, model in structuresFolder:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("IsBeacon") then
			table.insert(results, model)
		end
	end
	return results
end

function StructureSpawner:Initialize()
	-- Create folder
	structuresFolder = Instance.new("Folder")
	structuresFolder.Name = "Structures"
	structuresFolder.Parent = Workspace

	-- Spawn all structures
	local spawned = 0
	for _, def in ipairs(STRUCTURE_DEFS) do
		local model = spawnStructure(def)
		if model then
			spawned += 1
		end
	end

	print(string.format("[StructureSpawner] Initialized with %d structures", spawned))

	-- Print beacon info
	local beacons = self:GetBeacons()
	if #beacons > 0 then
		print("[StructureSpawner] Beacons:")
		for _, beacon in ipairs(beacons) do
			local pos = beacon:GetPivot().Position
			print(string.format("  - %s at (%.0f, %.0f, %.0f)", beacon.Name, pos.X, pos.Y, pos.Z))
		end
	end
end

-- ==========================================
-- DEBUG
-- ==========================================

function StructureSpawner:DebugHighlightBeacons()
	for _, beacon in self:GetBeacons() do
		local highlight = Instance.new("Highlight")
		highlight.FillColor = Color3.fromRGB(255, 200, 0)
		highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		highlight.FillTransparency = 0.5
		highlight.Parent = beacon
	end
	print("[StructureSpawner] Beacons highlighted")
end

return StructureSpawner
