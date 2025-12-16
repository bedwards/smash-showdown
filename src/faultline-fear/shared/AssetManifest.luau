--!strict
--[[
	Faultline Fear: Asset Manifest

	Documents all Blender-created assets and provides loading helpers.

	WORKFLOW:
	1. Run Blender script: blender --background --python tools/blender/create_X.py
	2. Import FBX into Roblox Studio via Asset Manager
	3. Place in ReplicatedStorage.Assets.<Category>.<AssetName>
	4. Code uses AssetManifest:GetAsset() to load

	Assets are NOT synced via Rojo (binary files).
	This manifest ensures code and assets stay in sync.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

	-- Structures (from tools/blender/create_structures.py - TODO)
	FerrisWheel = {
		name = "FerrisWheel",
		category = "Structures",
		blenderScript = "tools/blender/create_structures.py",
		description = "Beach landmark, rotating beacon",
		required = false,
	},
	RadioTower = {
		name = "RadioTower",
		category = "Structures",
		blenderScript = "tools/blender/create_structures.py",
		description = "Mountain summit rescue beacon",
		required = false,
	},
	AbandonedHouse = {
		name = "AbandonedHouse",
		category = "Structures",
		blenderScript = "tools/blender/create_structures.py",
		description = "Modular town building",
		required = false,
	},
	Bridge = {
		name = "Bridge",
		category = "Structures",
		blenderScript = "tools/blender/create_structures.py",
		description = "Fault line crossing",
		required = false,
	},
	WaterTower = {
		name = "WaterTower",
		category = "Structures",
		blenderScript = "tools/blender/create_structures.py",
		description = "Town landmark, elevated tank",
		required = false,
	},
	Lighthouse = {
		name = "Lighthouse",
		category = "Structures",
		blenderScript = "tools/blender/create_structures.py",
		description = "Coastal beacon with light",
		required = false,
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
}

-- ==========================================
-- ASSET LOADING
-- ==========================================

local assetsFolder: Folder? = nil

local function getAssetsFolder(): Folder?
	if assetsFolder then
		return assetsFolder
	end

	assetsFolder = ReplicatedStorage:FindFirstChild("Assets") :: Folder?
	return assetsFolder
end

--[[
	Get an asset Model by name.
	Returns nil if not found (asset not imported yet).
]]
function AssetManifest:GetAsset(assetName: string): Model?
	local entry = ASSETS[assetName]
	if not entry then
		warn("[AssetManifest] Unknown asset:", assetName)
		return nil
	end

	local folder = getAssetsFolder()
	if not folder then
		warn("[AssetManifest] Assets folder not found in ReplicatedStorage")
		return nil
	end

	local categoryFolder = folder:FindFirstChild(entry.category)
	if not categoryFolder then
		warn("[AssetManifest] Category folder not found:", entry.category)
		return nil
	end

	local asset = categoryFolder:FindFirstChild(entry.name)
	if not asset then
		warn(string.format(
			"[AssetManifest] Asset '%s' not found. Run: %s",
			entry.name,
			entry.blenderScript or "unknown script"
		))
		return nil
	end

	return asset :: Model
end

--[[
	Clone an asset for spawning.
	Returns a clone of the asset, or nil if not found.
]]
function AssetManifest:CloneAsset(assetName: string): Model?
	local asset = self:GetAsset(assetName)
	if asset then
		return asset:Clone()
	end
	return nil
end

--[[
	Check if an asset exists.
]]
function AssetManifest:HasAsset(assetName: string): boolean
	return self:GetAsset(assetName) ~= nil
end

--[[
	Get all assets in a category.
]]
function AssetManifest:GetAssetsInCategory(category: string): { Model }
	local results = {}
	local folder = getAssetsFolder()
	if not folder then
		return results
	end

	local categoryFolder = folder:FindFirstChild(category)
	if not categoryFolder then
		return results
	end

	for _, child in categoryFolder:GetChildren() do
		if child:IsA("Model") then
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
		print(string.format("  %s: %d/%d [%s]",
			category,
			counts.present,
			counts.present + counts.missing,
			status
		))
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
