--!strict
--[[
	Faultline Fear: Asset Manifest

	Documents all Blender-created assets and provides loading helpers.

	WORKFLOW:
	1. Run: python tools/generate-all-assets.py (creates FBX files)
	2. In Roblox Studio: Asset Manager → Bulk Import → select all FBX
	3. In Asset Manager: Meshes → Select all → Right-click → Insert
	4. Assets appear in Workspace.Meshes as Category_AssetName
	5. Code uses AssetManifest:CloneAsset("AssetName") to spawn

	Assets are NOT synced via Rojo (binary files).
	This manifest ensures code and assets stay in sync.
]]

local AssetManifest = {}

-- ==========================================
-- ASSET DEFINITIONS
-- All assets that should exist in the game
-- ==========================================

export type AssetEntry = {
	name: string,
	category: string,
	blenderScript: string?,
	description: string,
	required: boolean,
	cloudAssetId: number?, -- Roblox cloud asset ID for InsertService fallback
}

local ASSETS: { [string]: AssetEntry } = {
	-- Creatures (from tools/blender/create_creatures.py)
	ShadowStalker = {
		name = "ShadowStalker",
		category = "Creatures",
		blenderScript = "tools/blender/create_creatures.py",
		description = "Fast quadruped night hunter",
		required = true,
	},
	FissureDweller = {
		name = "FissureDweller",
		category = "Creatures",
		blenderScript = "tools/blender/create_creatures.py",
		description = "Worm-like creature from fault line",
		required = true,
	},
	NightBird = {
		name = "NightBird",
		category = "Creatures",
		blenderScript = "tools/blender/create_creatures.py",
		description = "Aerial threat with glowing eyes",
		required = true,
	},

	-- Animals (from tools/blender/create_animals.py)
	Deer = {
		name = "Deer",
		category = "Animals",
		blenderScript = "tools/blender/create_animals.py",
		description = "Passive day animal, flees from player",
		required = false,
	},
	Bird = {
		name = "Bird",
		category = "Animals",
		blenderScript = "tools/blender/create_animals.py",
		description = "Small bird, perches and flies away",
		required = false,
	},
	Rabbit = {
		name = "Rabbit",
		category = "Animals",
		blenderScript = "tools/blender/create_animals.py",
		description = "Small passive animal, fast escape",
		required = false,
	},
	Fish = {
		name = "Fish",
		category = "Animals",
		blenderScript = "tools/blender/create_animals.py",
		description = "Ocean fish, swims in schools",
		required = false,
	},
	Wolf = {
		name = "Wolf",
		category = "Animals",
		blenderScript = "tools/blender/create_animals.py",
		description = "Night predator, pack hunter",
		required = false,
	},
	Coyote = {
		name = "Coyote",
		category = "Animals",
		blenderScript = "tools/blender/create_animals.py",
		description = "Solo night hunter, fast",
		required = false,
	},
	MountainLion = {
		name = "MountainLion",
		category = "Animals",
		blenderScript = "tools/blender/create_animals.py",
		description = "Rare powerful predator, stalks silently",
		required = false,
	},

	-- Structures (from tools/blender/create_structures.py)
	-- Cloud asset IDs uploaded via Open Cloud API (2024-12-19)
	FerrisWheel = {
		name = "FerrisWheel",
		category = "Structures",
		blenderScript = "tools/blender/create_structures.py",
		description = "Beach landmark, rotating beacon",
		required = false,
		cloudAssetId = 128227709441371,
	},
	RadioTower = {
		name = "RadioTower",
		category = "Structures",
		blenderScript = "tools/blender/create_structures.py",
		description = "Mountain summit rescue beacon",
		required = false,
		cloudAssetId = 119758365110065,
	},
	AbandonedHouse = {
		name = "AbandonedHouse",
		category = "Structures",
		blenderScript = "tools/blender/create_structures.py",
		description = "Modular town building",
		required = false,
		cloudAssetId = 90248483610888,
	},
	Bridge = {
		name = "Bridge",
		category = "Structures",
		blenderScript = "tools/blender/create_structures.py",
		description = "Fault line crossing",
		required = false,
		cloudAssetId = 105968577364311,
	},
	WaterTower = {
		name = "WaterTower",
		category = "Structures",
		blenderScript = "tools/blender/create_structures.py",
		description = "Town landmark, elevated tank",
		required = false,
		cloudAssetId = 74085624282098,
	},
	Lighthouse = {
		name = "Lighthouse",
		category = "Structures",
		blenderScript = "tools/blender/create_structures.py",
		description = "Coastal beacon with light",
		required = false,
		cloudAssetId = 97584625740584,
	},

	-- NPCs (from tools/blender/create_npcs.py - TODO)
	Survivor = {
		name = "Survivor",
		category = "NPCs",
		blenderScript = "tools/blender/create_npcs.py",
		description = "Rescuable survivor NPC",
		required = false,
	},
	PetCompanion = {
		name = "PetCompanion",
		category = "NPCs",
		blenderScript = "tools/blender/create_npcs.py",
		description = "Player's animal companion",
		required = false,
	},

	-- Terrain Assets (from tools/blender/create_terrain_assets.py)
	Boulder_Small = {
		name = "Boulder_Small",
		category = "Terrain",
		blenderScript = "tools/blender/create_terrain_assets.py",
		description = "Small boulder rock",
		required = false,
	},
	Boulder_Medium = {
		name = "Boulder_Medium",
		category = "Terrain",
		blenderScript = "tools/blender/create_terrain_assets.py",
		description = "Medium boulder rock",
		required = false,
	},
	Boulder_Large = {
		name = "Boulder_Large",
		category = "Terrain",
		blenderScript = "tools/blender/create_terrain_assets.py",
		description = "Large boulder rock",
		required = false,
	},
	Boulder_Huge = {
		name = "Boulder_Huge",
		category = "Terrain",
		blenderScript = "tools/blender/create_terrain_assets.py",
		description = "Huge boulder rock",
		required = false,
	},
	RockCluster_1 = {
		name = "RockCluster_1",
		category = "Terrain",
		blenderScript = "tools/blender/create_terrain_assets.py",
		description = "Cluster of small rocks",
		required = false,
	},
	RockCluster_2 = {
		name = "RockCluster_2",
		category = "Terrain",
		blenderScript = "tools/blender/create_terrain_assets.py",
		description = "Cluster of small rocks (variant)",
		required = false,
	},
	FallenRocks = {
		name = "FallenRocks",
		category = "Terrain",
		blenderScript = "tools/blender/create_terrain_assets.py",
		description = "Pile of fallen debris",
		required = false,
	},
	FaultEdge_Left = {
		name = "FaultEdge_Left",
		category = "Terrain",
		blenderScript = "tools/blender/create_terrain_assets.py",
		description = "Left edge of fault line crack",
		required = false,
	},
	FaultEdge_Right = {
		name = "FaultEdge_Right",
		category = "Terrain",
		blenderScript = "tools/blender/create_terrain_assets.py",
		description = "Right edge of fault line crack",
		required = false,
	},
	SteamVent = {
		name = "SteamVent",
		category = "Terrain",
		blenderScript = "tools/blender/create_terrain_assets.py",
		description = "Steam vent from fault line",
		required = false,
	},
	Cliff_Coastal = {
		name = "Cliff_Coastal",
		category = "Terrain",
		blenderScript = "tools/blender/create_terrain_assets.py",
		description = "Coastal cliff face",
		required = false,
	},
	Cliff_Mountain = {
		name = "Cliff_Mountain",
		category = "Terrain",
		blenderScript = "tools/blender/create_terrain_assets.py",
		description = "Mountain cliff face",
		required = false,
	},

	-- Cave Assets (from tools/blender/create_caves.py)
	CaveEntrance_Small = {
		name = "CaveEntrance_Small",
		category = "Caves",
		blenderScript = "tools/blender/create_caves.py",
		description = "Small cave entrance arch",
		required = false,
	},
	CaveEntrance_Medium = {
		name = "CaveEntrance_Medium",
		category = "Caves",
		blenderScript = "tools/blender/create_caves.py",
		description = "Medium cave entrance arch",
		required = false,
	},
	CaveEntrance_Large = {
		name = "CaveEntrance_Large",
		category = "Caves",
		blenderScript = "tools/blender/create_caves.py",
		description = "Large cave entrance arch",
		required = false,
	},
	CaveInteriorSegment = {
		name = "CaveInteriorSegment",
		category = "Caves",
		blenderScript = "tools/blender/create_caves.py",
		description = "Cave tunnel segment",
		required = false,
	},
	CaveChamber = {
		name = "CaveChamber",
		category = "Caves",
		blenderScript = "tools/blender/create_caves.py",
		description = "Large cave chamber room",
		required = false,
	},
	RockPillar = {
		name = "RockPillar",
		category = "Caves",
		blenderScript = "tools/blender/create_caves.py",
		description = "Floor-to-ceiling rock pillar",
		required = false,
	},
	Stalactite = {
		name = "Stalactite",
		category = "Caves",
		blenderScript = "tools/blender/create_caves.py",
		description = "Hanging cave formation",
		required = false,
	},
	Stalagmite = {
		name = "Stalagmite",
		category = "Caves",
		blenderScript = "tools/blender/create_caves.py",
		description = "Floor cave formation",
		required = false,
	},

	-- Liminal Space Assets (from tools/blender/create_liminal_spaces.py)
	AbandonedMall = {
		name = "AbandonedMall",
		category = "Liminal",
		blenderScript = "tools/blender/create_liminal_spaces.py",
		description = "Empty mall with fluorescent lights",
		required = false,
	},
	HotelLobby = {
		name = "HotelLobby",
		category = "Liminal",
		blenderScript = "tools/blender/create_liminal_spaces.py",
		description = "Grand lobby with stopped clocks",
		required = false,
	},
	AbandonedSchool = {
		name = "AbandonedSchool",
		category = "Liminal",
		blenderScript = "tools/blender/create_liminal_spaces.py",
		description = "Classroom with neat desks",
		required = false,
	},
	Hospital = {
		name = "Hospital",
		category = "Liminal",
		blenderScript = "tools/blender/create_liminal_spaces.py",
		description = "Corridor with gurneys",
		required = false,
	},
	HighwayUnderpass = {
		name = "HighwayUnderpass",
		category = "Liminal",
		blenderScript = "tools/blender/create_liminal_spaces.py",
		description = "Underpass with sodium lights",
		required = false,
	},

	-- Sign Assets (from tools/blender/create_signs.py)
	DirectionalSign = {
		name = "DirectionalSign",
		category = "Signs",
		blenderScript = "tools/blender/create_signs.py",
		description = "Highway-style directional sign",
		required = false,
	},
	WarningSign = {
		name = "WarningSign",
		category = "Signs",
		blenderScript = "tools/blender/create_signs.py",
		description = "Diamond-shaped warning sign",
		required = false,
	},
	StoryPlaque = {
		name = "StoryPlaque",
		category = "Signs",
		blenderScript = "tools/blender/create_signs.py",
		description = "Wooden plaque for lore text",
		required = false,
	},
	ObjectiveMarker = {
		name = "ObjectiveMarker",
		category = "Signs",
		blenderScript = "tools/blender/create_signs.py",
		description = "Tall objective checkpoint marker",
		required = false,
	},
	RoadSign = {
		name = "RoadSign",
		category = "Signs",
		blenderScript = "tools/blender/create_signs.py",
		description = "Standard road sign",
		required = false,
	},
}

-- ==========================================
-- ASSET LOADING
-- ==========================================

local ServerStorage = game:GetService("ServerStorage")
local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")

local AssetColors = require(script.Parent.AssetColors)

local missingAssetWarnings: { [string]: boolean } = {}
local assetCache: { [string]: Instance } = {}
local cloudAssetCache: { [number]: Instance } = {} -- Cache for cloud-loaded assets
local templatesFolder: Folder? = nil
local templatesFolderChecked = false

--[[
	Get the AssetTemplates folder from ServerStorage.
	This is where imported FBX assets should be stored (NOT Workspace).
]]
local function getTemplatesFolder(): Folder?
	if templatesFolderChecked then
		return templatesFolder
	end
	templatesFolderChecked = true

	-- Only server can access ServerStorage
	if not RunService:IsServer() then
		return nil
	end

	templatesFolder = ServerStorage:FindFirstChild("AssetTemplates") :: Folder?

	if not templatesFolder then
		warn("[AssetManifest] ServerStorage.AssetTemplates not found!")
		warn("[AssetManifest] After importing FBX, move MeshParts to ServerStorage.AssetTemplates")
	else
		print(
			string.format(
				"[AssetManifest] Found %d templates in ServerStorage.AssetTemplates",
				#templatesFolder:GetChildren()
			)
		)
	end

	return templatesFolder
end

--[[
	Load an asset from Roblox cloud using InsertService.
	Caches the result for future clones.
	@param assetId - Roblox cloud asset ID
	@param fullName - Full name for the model (Category_AssetName)
	@param assetName - Asset name for color lookup (e.g., "Lighthouse")
]]
local function loadFromCloud(assetId: number, fullName: string, assetName: string): Instance?
	-- Check cache first
	if cloudAssetCache[assetId] then
		return cloudAssetCache[assetId]
	end

	-- Only server can use InsertService
	if not RunService:IsServer() then
		return nil
	end

	local success, result = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)

	if not success or not result then
		warn(string.format("[AssetManifest] Failed to load cloud asset %d: %s", assetId, tostring(result)))
		return nil
	end

	-- LoadAsset returns a Model containing the asset
	local children = result:GetChildren()
	if #children == 0 then
		warn(string.format("[AssetManifest] Cloud asset %d returned empty container", assetId))
		result:Destroy()
		return nil
	end

	-- Get the first child (the actual model)
	local model = children[1]
	model.Name = fullName
	model.Parent = nil -- Detach from container

	-- CRITICAL: Apply colors! Roblox FBX import doesn't preserve Blender materials
	if model:IsA("Model") then
		AssetColors:ApplyColors(model, assetName)
		print(string.format("[AssetManifest] Applied colors to %s", assetName))
	end

	-- Cache it in ServerStorage for future use
	local folder = getTemplatesFolder()
	if folder then
		local cacheClone = model:Clone()
		cacheClone.Parent = folder
		print(string.format("[AssetManifest] Loaded cloud asset %s (ID: %d) and cached", fullName, assetId))
	end

	-- Store in memory cache
	cloudAssetCache[assetId] = model
	result:Destroy() -- Clean up container

	return model
end

--[[
	Check if a template is "empty" (no BasePart descendants).
	This handles cases where .rbxm files exist but have no actual geometry.
]]
local function isTemplateEmpty(template: Instance): boolean
	for _, child in template:GetDescendants() do
		if child:IsA("BasePart") then
			return false
		end
	end
	return true
end

--[[
	Find a template by its full name (Category_AssetName) in the templates folder.
]]
local function findTemplate(fullName: string): Instance?
	-- Check cache first
	if assetCache[fullName] then
		return assetCache[fullName]
	end

	local folder = getTemplatesFolder()
	if not folder then
		return nil
	end

	-- Search direct children
	local template = folder:FindFirstChild(fullName)
	if template and not isTemplateEmpty(template) then
		assetCache[fullName] = template
		return template
	end

	-- Search one level deep (in case of subfolders)
	for _, child in folder:GetChildren() do
		if child:IsA("Folder") then
			local found = child:FindFirstChild(fullName)
			if found and not isTemplateEmpty(found) then
				assetCache[fullName] = found
				return found
			end
		end
	end

	return nil
end

--[[
	Wrap a MeshPart in a Model with PrimaryPart set.
	Services expect Models with PrimaryPart, but FBX imports create MeshParts.
]]
local function wrapInModel(meshPart: MeshPart): Model
	local model = Instance.new("Model")
	model.Name = meshPart.Name

	-- Clone the MeshPart into the Model
	local clonedPart = meshPart:Clone()
	clonedPart.Parent = model

	-- Set PrimaryPart so services can use Model:PivotTo(), etc.
	model.PrimaryPart = clonedPart

	return model
end

--[[
	Get an asset template by name.
	Looks in ServerStorage.AssetTemplates for Category_AssetName format.
	Falls back to cloud loading via InsertService if local template is missing/empty.
	Returns the template (do NOT parent to Workspace - use CloneAsset instead).
]]
function AssetManifest:GetAsset(assetName: string): Instance?
	local entry = ASSETS[assetName]
	if not entry then
		warn("[AssetManifest] Unknown asset:", assetName)
		return nil
	end

	-- Asset imports use Category_AssetName format
	local fullName = entry.category .. "_" .. entry.name

	-- Try local template first
	local template = findTemplate(fullName)

	-- If no local template (or empty), try cloud loading
	if not template and entry.cloudAssetId then
		template = loadFromCloud(entry.cloudAssetId, fullName, entry.name)
		if template then
			-- Cache the cloud-loaded asset for future lookups
			assetCache[fullName] = template
		end
	end

	if not template then
		-- Only warn once per asset to avoid log spam
		if not missingAssetWarnings[assetName] then
			missingAssetWarnings[assetName] = true
			if entry.cloudAssetId then
				warn(
					string.format(
						"[AssetManifest] Asset '%s' not found locally or in cloud (ID: %d)",
						assetName,
						entry.cloudAssetId
					)
				)
			else
				warn(
					string.format(
						"[AssetManifest] Asset '%s' not found. Expected: ServerStorage.AssetTemplates.%s",
						assetName,
						fullName
					)
				)
			end
		end
		return nil
	end

	return template
end

--[[
	Clone an asset for spawning.
	Returns a Model with PrimaryPart set (wraps MeshParts automatically).
	This is the main function services should use.
]]
function AssetManifest:CloneAsset(assetName: string): Model?
	local template = self:GetAsset(assetName)
	if not template then
		return nil
	end

	-- If template is already a Model, just clone it
	if template:IsA("Model") then
		return template:Clone()
	end

	-- If template is a MeshPart, wrap it in a Model
	if template:IsA("MeshPart") then
		return wrapInModel(template)
	end

	-- For other BaseParts, also wrap in Model
	if template:IsA("BasePart") then
		local model = Instance.new("Model")
		model.Name = template.Name
		local clonedPart = template:Clone()
		clonedPart.Parent = model
		model.PrimaryPart = clonedPart
		return model
	end

	-- Fallback: just clone whatever it is
	warn(string.format("[AssetManifest] Unexpected template type for '%s': %s", assetName, template.ClassName))
	return template:Clone() :: Model
end

--[[
	Check if an asset exists in ServerStorage.AssetTemplates.
]]
function AssetManifest:HasAsset(assetName: string): boolean
	return self:GetAsset(assetName) ~= nil
end

--[[
	Get all templates in a category from ServerStorage.AssetTemplates.
]]
function AssetManifest:GetAssetsInCategory(category: string): { Instance }
	local folder = getTemplatesFolder()
	if not folder then
		return {}
	end

	local results = {}
	local prefix = category .. "_"

	for _, child in folder:GetChildren() do
		if string.sub(child.Name, 1, #prefix) == prefix then
			table.insert(results, child)
		end
	end

	return results
end

--[[
	Get the manifest entry for an asset.
]]
function AssetManifest:GetEntry(assetName: string): AssetEntry?
	return ASSETS[assetName]
end

--[[
	Get all manifest entries.
]]
function AssetManifest:GetAllEntries(): { [string]: AssetEntry }
	return ASSETS
end

-- ==========================================
-- VALIDATION
-- ==========================================

--[[
	Check which required assets are missing.
	Returns a list of missing asset names.
]]
function AssetManifest:GetMissingAssets(): { string }
	local missing = {}

	for name, entry in pairs(ASSETS) do
		if entry.required and not self:HasAsset(name) then
			table.insert(missing, name)
		end
	end

	return missing
end

--[[
	Print asset status report.
]]
function AssetManifest:PrintStatus()
	print("=== ASSET MANIFEST STATUS ===")
	print("Looking in: ServerStorage.AssetTemplates for Category_AssetName")

	local categories: { [string]: { present: number, missing: number } } = {}

	for name, entry in pairs(ASSETS) do
		if not categories[entry.category] then
			categories[entry.category] = { present = 0, missing = 0 }
		end

		if self:HasAsset(name) then
			categories[entry.category].present += 1
		else
			categories[entry.category].missing += 1
		end
	end

	for category, counts in pairs(categories) do
		local status = counts.missing == 0 and "OK" or "MISSING " .. counts.missing
		print(string.format("  %s: %d/%d [%s]", category, counts.present, counts.present + counts.missing, status))
	end

	local missing = self:GetMissingAssets()
	if #missing > 0 then
		print("")
		print("REQUIRED ASSETS MISSING:")
		for _, name in ipairs(missing) do
			local entry = ASSETS[name]
			print(string.format("  - %s (run: %s)", name, entry.blenderScript or "unknown"))
		end
	end

	print("=============================")
end

return AssetManifest
