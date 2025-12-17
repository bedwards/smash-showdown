--!strict
--[[
	Faultline Fear: Terrain Asset Spawner

	Spawns terrain features (rocks, cliffs, fault line edges) in the world.
	Uses AssetManifest for models with placeholder fallbacks.
	Uses Heightmap for terrain-aware placement.

	Features:
	- Boulders scattered throughout zones
	- Fault line edge pieces along the crack
	- Steam vents in fault line zone
	- Cliff faces at zone boundaries
	- Rock clusters for environmental detail

	Exports: Initialize(), GetTerrainAssets()
	Depends: Config, Heightmap, AssetManifest
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config
local Heightmap = Shared.Heightmap
local AssetManifest = Shared.AssetManifest
local AssetColors = Shared.AssetColors

local TerrainAssetSpawner = {}

-- Folder for terrain assets
local terrainFolder: Folder = nil :: any

-- ==========================================
-- PLACEMENT DEFINITIONS
-- ==========================================

type AssetPlacement = {
	assetName: string,
	position: Vector3,
	rotation: number,
	scale: number,
}

-- Boulder placements - scatter across zones
local function generateBoulderPlacements(): { AssetPlacement }
	local placements: { AssetPlacement } = {}
	local random = Random.new(Config.TERRAIN_SEED + 100)

	-- Boulder types by zone
	local zoneConfigs = {
		{ zone = "BEACH", count = 15, types = { "Boulder_Small", "Boulder_Medium" } },
		{ zone = "COASTAL", count = 20, types = { "Boulder_Small", "Boulder_Medium", "Boulder_Large" } },
		{ zone = "VALLEY", count = 25, types = { "Boulder_Small", "Boulder_Medium", "RockCluster_1" } },
		{ zone = "FOREST", count = 30, types = { "Boulder_Medium", "Boulder_Large", "RockCluster_2" } },
		{ zone = "FAULT_LINE", count = 20, types = { "Boulder_Large", "FallenRocks", "Boulder_Huge" } },
		{
			zone = "MOUNTAIN",
			count = 35,
			types = { "Boulder_Large", "Boulder_Huge", "RockCluster_1", "RockCluster_2" },
		},
	}

	local worldHalfSize = Config.WORLD_SIZE / 2

	for _, zoneConfig in ipairs(zoneConfigs) do
		local zone = Config.ZONES[zoneConfig.zone]
		if not zone then
			continue
		end

		for _ = 1, zoneConfig.count do
			local x = random:NextNumber(-worldHalfSize, worldHalfSize)
			local z = random:NextNumber(zone.zMin, zone.zMax)
			local assetType = zoneConfig.types[random:NextInteger(1, #zoneConfig.types)]

			table.insert(placements, {
				assetName = assetType,
				position = Vector3.new(x, 0, z),
				rotation = random:NextNumber(0, 360),
				scale = 0.8 + random:NextNumber() * 0.4,
			})
		end
	end

	return placements
end

-- Fault line edge placements
local function generateFaultLinePlacements(): { AssetPlacement }
	local placements: { AssetPlacement } = {}
	local random = Random.new(Config.TERRAIN_SEED + 200)

	local faultZone = Config.ZONES.FAULT_LINE
	if not faultZone then
		return placements
	end

	local worldHalfSize = Config.WORLD_SIZE / 2
	local faultCenterZ = (faultZone.zMin + faultZone.zMax) / 2

	-- Place fault edges along the crack
	local numEdges = 20
	for i = 1, numEdges do
		local x = -worldHalfSize + (i / numEdges) * Config.WORLD_SIZE

		-- Left edge (north side of fault)
		table.insert(placements, {
			assetName = "FaultEdge_Left",
			position = Vector3.new(x, 0, faultCenterZ + 10 + random:NextNumber(-5, 5)),
			rotation = random:NextNumber(-10, 10),
			scale = 0.9 + random:NextNumber() * 0.2,
		})

		-- Right edge (south side of fault)
		table.insert(placements, {
			assetName = "FaultEdge_Right",
			position = Vector3.new(x, 0, faultCenterZ - 10 + random:NextNumber(-5, 5)),
			rotation = random:NextNumber(-10, 10),
			scale = 0.9 + random:NextNumber() * 0.2,
		})
	end

	return placements
end

-- Steam vent placements
local function generateSteamVentPlacements(): { AssetPlacement }
	local placements: { AssetPlacement } = {}
	local random = Random.new(Config.TERRAIN_SEED + 300)

	local faultZone = Config.ZONES.FAULT_LINE
	if not faultZone then
		return placements
	end

	local worldHalfSize = Config.WORLD_SIZE / 2
	local numVents = 12

	for _ = 1, numVents do
		local x = random:NextNumber(-worldHalfSize * 0.8, worldHalfSize * 0.8)
		local z = random:NextNumber(faultZone.zMin, faultZone.zMax)

		table.insert(placements, {
			assetName = "SteamVent",
			position = Vector3.new(x, 0, z),
			rotation = random:NextNumber(0, 360),
			scale = 0.7 + random:NextNumber() * 0.6,
		})
	end

	return placements
end

-- Cliff placements at zone boundaries
local function generateCliffPlacements(): { AssetPlacement }
	local placements: { AssetPlacement } = {}
	local random = Random.new(Config.TERRAIN_SEED + 400)

	local worldHalfSize = Config.WORLD_SIZE / 2

	-- Coastal cliffs along beach boundary
	local beachZone = Config.ZONES.BEACH
	if beachZone then
		local numCliffs = 8
		for i = 1, numCliffs do
			local x = -worldHalfSize * 0.9 + (i / numCliffs) * worldHalfSize * 1.8
			table.insert(placements, {
				assetName = "Cliff_Coastal",
				position = Vector3.new(x, 0, beachZone.zMax - 20),
				rotation = random:NextNumber(-15, 15),
				scale = 0.8 + random:NextNumber() * 0.4,
			})
		end
	end

	-- Mountain cliffs near summit
	local mountainZone = Config.ZONES.MOUNTAIN
	if mountainZone then
		local numCliffs = 10
		for i = 1, numCliffs do
			local angle = (i / numCliffs) * math.pi -- Semicircle
			local radius = worldHalfSize * 0.6
			local x = math.cos(angle) * radius
			local z = mountainZone.zMax - 100 + math.sin(angle) * 50

			table.insert(placements, {
				assetName = "Cliff_Mountain",
				position = Vector3.new(x, 0, z),
				rotation = math.deg(angle) + 90 + random:NextNumber(-10, 10),
				scale = 0.9 + random:NextNumber() * 0.3,
			})
		end
	end

	return placements
end

-- ==========================================
-- PLACEHOLDER CREATION
-- ==========================================

local function createPlaceholderAsset(assetName: string): Model
	local model = Instance.new("Model")
	model.Name = assetName .. "_Placeholder"

	local part = Instance.new("Part")
	part.Name = "Main"
	part.Anchored = true
	part.CanCollide = true

	-- Size and color based on asset type
	if string.find(assetName, "Boulder") then
		if string.find(assetName, "Huge") then
			part.Size = Vector3.new(10, 6, 8)
		elseif string.find(assetName, "Large") then
			part.Size = Vector3.new(5, 3, 4)
		elseif string.find(assetName, "Medium") then
			part.Size = Vector3.new(2.4, 2, 1.6)
		else
			part.Size = Vector3.new(1, 0.8, 0.7)
		end
		part.Color = Color3.fromRGB(100, 95, 88)
		part.Shape = Enum.PartType.Ball
	elseif string.find(assetName, "RockCluster") then
		part.Size = Vector3.new(4, 1, 4)
		part.Color = Color3.fromRGB(90, 85, 77)
	elseif string.find(assetName, "FaultEdge") then
		part.Size = Vector3.new(8, 6, 1)
		part.Color = Color3.fromRGB(95, 88, 80)
	elseif string.find(assetName, "SteamVent") then
		part.Size = Vector3.new(2, 1, 2)
		part.Color = Color3.fromRGB(80, 70, 60)
		part.Shape = Enum.PartType.Cylinder
	elseif string.find(assetName, "Cliff") then
		part.Size = Vector3.new(20, 16, 4)
		if string.find(assetName, "Coastal") then
			part.Color = Color3.fromRGB(150, 140, 115)
		else
			part.Color = Color3.fromRGB(100, 95, 88)
		end
	elseif string.find(assetName, "FallenRocks") then
		part.Size = Vector3.new(6, 1.5, 6)
		part.Color = Color3.fromRGB(100, 92, 83)
	else
		part.Size = Vector3.new(2, 2, 2)
		part.Color = Color3.fromRGB(100, 100, 100)
	end

	part.Material = Enum.Material.Rock
	part.Parent = model
	model.PrimaryPart = part

	return model
end

-- ==========================================
-- SPAWNING
-- ==========================================

local function spawnAsset(placement: AssetPlacement): Model?
	-- Try to get imported model
	local model = AssetManifest:CloneAsset(placement.assetName)

	if model then
		-- Apply colors to imported model (Roblox doesn't import FBX colors)
		AssetColors:ApplyColors(model, placement.assetName)
	else
		-- Create placeholder
		model = createPlaceholderAsset(placement.assetName)
	end

	-- Get terrain height
	local y = Heightmap:GetHeight(placement.position.X, placement.position.Z)

	-- Position and rotate
	local cframe = CFrame.new(placement.position.X, y, placement.position.Z)
		* CFrame.Angles(0, math.rad(placement.rotation), 0)

	-- Adjust for model height
	if model.PrimaryPart then
		local halfHeight = model.PrimaryPart.Size.Y / 2 * placement.scale
		cframe = cframe + Vector3.new(0, halfHeight, 0)

		-- Apply scale
		if placement.scale ~= 1 then
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") then
					part.Size = part.Size * placement.scale
				end
			end
		end

		model:PivotTo(cframe)
	end

	-- Tags
	model.Name = placement.assetName
	CollectionService:AddTag(model, "TerrainAsset")
	CollectionService:AddTag(model, placement.assetName)

	-- Attributes
	model:SetAttribute("AssetType", placement.assetName)

	model.Parent = terrainFolder

	return model
end

-- ==========================================
-- PUBLIC API
-- ==========================================

function TerrainAssetSpawner:GetTerrainAssets(): { Model }
	local assets = {}
	for _, child in terrainFolder:GetChildren() do
		if child:IsA("Model") then
			table.insert(assets, child)
		end
	end
	return assets
end

function TerrainAssetSpawner:GetAssetsByType(assetType: string): { Model }
	local assets = {}
	for _, child in terrainFolder:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("AssetType") == assetType then
			table.insert(assets, child)
		end
	end
	return assets
end

function TerrainAssetSpawner:Initialize()
	-- Create folder
	terrainFolder = Instance.new("Folder")
	terrainFolder.Name = "TerrainAssets"
	terrainFolder.Parent = Workspace

	-- Generate all placements
	local allPlacements: { AssetPlacement } = {}

	print("[TerrainAssetSpawner] Generating terrain asset placements...")

	local boulderPlacements = generateBoulderPlacements()
	for _, p in ipairs(boulderPlacements) do
		table.insert(allPlacements, p)
	end
	print(string.format("  - %d boulder placements", #boulderPlacements))

	local faultLinePlacements = generateFaultLinePlacements()
	for _, p in ipairs(faultLinePlacements) do
		table.insert(allPlacements, p)
	end
	print(string.format("  - %d fault line edge placements", #faultLinePlacements))

	local steamVentPlacements = generateSteamVentPlacements()
	for _, p in ipairs(steamVentPlacements) do
		table.insert(allPlacements, p)
	end
	print(string.format("  - %d steam vent placements", #steamVentPlacements))

	local cliffPlacements = generateCliffPlacements()
	for _, p in ipairs(cliffPlacements) do
		table.insert(allPlacements, p)
	end
	print(string.format("  - %d cliff placements", #cliffPlacements))

	-- Spawn all assets
	local spawned = 0
	for _, placement in ipairs(allPlacements) do
		local model = spawnAsset(placement)
		if model then
			spawned += 1
		end
	end

	print(string.format("[TerrainAssetSpawner] Initialized with %d terrain assets", spawned))
end

return TerrainAssetSpawner
