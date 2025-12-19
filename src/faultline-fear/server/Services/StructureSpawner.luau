--!strict
--[[
	Faultline Fear: Structure Spawner

	Places landmark structures in the world using encapsulated StructureEntity.
	Uses AssetManifest for imported models, StructureEntity handles cloud/placeholders.
	All spawning logic (config, rotation, sensitivity, colors) in shared StructureEntity.

	Structures:
	- Ferris Wheel (Beach) - Rotating beacon
	- Radio Tower (Mountain) - Rescue beacon
	- Water Tower (Valley/Forest) - Town landmarks
	- Lighthouse (Coastal) - Coastal beacon
	- Abandoned Houses (Valley/Coastal) - Town buildings
	- Bridge (Fault Line) - Crossing point

	Exports: Initialize(), GetStructure()
	Depends: Config, AssetManifest, TerrainCore.StructureEntity
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config
local AssetManifest = Shared.AssetManifest
local AssetColors = Shared.AssetColors
local StructureEntity = Shared.TerrainCore.StructureEntity

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
	anchored: boolean?, -- If false, structure is physics-enabled (default true)
	dropHeight: number?, -- If unanchored, initial drop height above ground
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
	-- NOTE: Spawn is at (0, ~30, 100). Structures must be well clear of spawn.
	{
		name = "WaterTower_Main",
		assetName = "WaterTower",
		zone = "VALLEY",
		position = Vector3.new(250, 0, 300), -- Visible ahead-right from spawn
		rotation = 0,
		flattenRadius = 20,
		scale = 1,
		beacon = true,
	},

	-- VALLEY ZONE - Abandoned Houses
	-- Spread out in front of player, well away from spawn at (0, 100)
	{
		name = "House_1",
		assetName = "AbandonedHouse",
		zone = "VALLEY",
		position = Vector3.new(-220, 0, 280), -- Left-front from spawn
		rotation = 15,
		flattenRadius = 15,
		scale = 1,
		beacon = false,
	},
	{
		name = "House_2",
		assetName = "AbandonedHouse",
		zone = "VALLEY",
		position = Vector3.new(150, 0, 380), -- Ahead-right, past water tower
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

	-- FOREST ZONE - Water Towers (one per town, 4 total)
	-- Foothills at higher elevations - testing earthquake physics
	{
		name = "WaterTower_Town1_Anchored",
		assetName = "WaterTower",
		zone = "FOREST",
		position = Vector3.new(-500, 0, 900), -- West foothills
		rotation = 0,
		flattenRadius = 20,
		scale = 1,
		beacon = false,
		anchored = true, -- Solid reference - won't move
	},
	{
		name = "WaterTower_Town2_OnGround",
		assetName = "WaterTower",
		zone = "FOREST",
		position = Vector3.new(500, 0, 1000), -- East foothills
		rotation = 45,
		flattenRadius = 20,
		scale = 1,
		beacon = false,
		anchored = false, -- Unanchored, placed on ground
		dropHeight = 0,
	},
	{
		name = "WaterTower_Town3_LowDrop",
		assetName = "WaterTower",
		zone = "FOREST",
		position = Vector3.new(-400, 0, 1200), -- Northwest foothills
		rotation = 90,
		flattenRadius = 20,
		scale = 1,
		beacon = false,
		anchored = false,
		dropHeight = 3, -- Low drop, gentle landing
	},
	{
		name = "WaterTower_Town4_HighDrop",
		assetName = "WaterTower",
		zone = "FOREST",
		position = Vector3.new(400, 0, 1300), -- Northeast foothills
		rotation = -45,
		flattenRadius = 20,
		scale = 1,
		beacon = false,
		anchored = false,
		dropHeight = 20, -- High drop, dramatic fall
	},
}

-- ==========================================
-- COLLISION AUDIT (Fix for Issue #86)
-- ==========================================

--[[
	Audit a model for invisible colliders and fix them.
	A part is considered an "invisible collider" if:
	- It has CanCollide = true
	- AND (Transparency >= 0.9 OR it's a MeshPart with no visible mesh)

	This prevents invisible walls blocking player movement.
]]
local function auditAndFixInvisibleColliders(model: Model): number
	local fixed = 0

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.CanCollide then
			local shouldDisableCollision = false
			local reason = ""

			-- Check for high transparency
			if part.Transparency >= 0.9 then
				shouldDisableCollision = true
				reason = "Transparency >= 0.9"
			end

			-- Check for MeshParts with no mesh loaded
			if part:IsA("MeshPart") then
				-- If MeshId is empty or mesh failed to load, it's invisible
				if part.MeshId == "" then
					shouldDisableCollision = true
					reason = "MeshPart with no MeshId"
				end
			end

			if shouldDisableCollision then
				part.CanCollide = false
				fixed += 1
				warn(string.format(
					"[StructureSpawner] Disabled collision on invisible part '%s' in '%s' (%s)",
					part.Name, model.Name, reason
				))
			end
		end
	end

	return fixed
end

-- ==========================================
-- STRUCTURE SPAWNING (Uses encapsulated StructureEntity)
-- ==========================================

local function spawnStructure(def: StructureDef): Model?
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

	-- Try to get imported model from AssetManifest
	local preloadedModel = AssetManifest:CloneAsset(def.assetName)
	if preloadedModel then
		-- Apply colors (Roblox doesn't import FBX colors)
		AssetColors:ApplyColors(preloadedModel, def.assetName)
		print(string.format("[StructureSpawner] Using imported model for %s", def.name))
	else
		print(string.format("[StructureSpawner] Will load from cloud/placeholder for %s", def.name))
	end

	-- Create entity and spawn using encapsulated logic
	local entity = StructureEntity.new(def.assetName)
	local model = entity:spawn(x, z, {
		anchored = def.anchored,
		dropHeight = def.dropHeight or 0,
		rotation = def.rotation,
		flattenRadius = def.flattenRadius,
		scale = def.scale,
		parent = structuresFolder,
		name = def.name,
		model = preloadedModel,
		zone = def.zone,
		beacon = def.beacon,
	})

	if not model then
		return nil
	end

	-- Audit for invisible colliders (Fix for Issue #86)
	local fixedCount = auditAndFixInvisibleColliders(model)
	if fixedCount > 0 then
		print(string.format("[StructureSpawner] Fixed %d invisible colliders in %s", fixedCount, def.name))
	end

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
