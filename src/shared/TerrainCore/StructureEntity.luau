--!strict
--[[
	TerrainCore: Structure Entity

	Encapsulated entity for spawning and managing structures.
	Single source of truth for structure configuration and spawning logic.
	Used by both Fault-Lite and Faultline Fear (DRY/SOLID/APIE).

	Usage:
		local StructureEntity = require(TerrainCore.StructureEntity)
		local entity = StructureEntity.new("WaterTower")
		local model = entity:spawn(x, z, {
			anchored = true,
			dropHeight = 0,
			rotation = 45,
		})
]]

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Import sibling modules
local TerrainConfig = require(script.Parent.TerrainConfig)
local Heightmap = require(script.Parent.Heightmap)

-- Cloud asset IDs (single source of truth)
local CLOUD_ASSETS = {
	FerrisWheel = 128227709441371,
	RadioTower = 119758365110065,
	WaterTower = 74085624282098,
	Lighthouse = 97584625740584,
	AbandonedHouse = 90248483610888,
	Bridge = 105968577364311,
}

-- Try to get AssetColors from Faultline Fear shared
local AssetColors: any = nil
local function getAssetColors()
	if AssetColors then return AssetColors end

	local success, result = pcall(function()
		local ffShared = ReplicatedStorage:FindFirstChild("FaultlineFearShared")
			or ReplicatedStorage:FindFirstChild("Shared")
		if ffShared then
			local colorsModule = ffShared:FindFirstChild("AssetColors")
			if colorsModule then
				return require(colorsModule)
			end
		end
		return nil
	end)

	if success and result then
		AssetColors = result
	end
	return AssetColors
end

export type SpawnOptions = {
	anchored: boolean?,      -- Default true
	dropHeight: number?,     -- Height above ground for drop (default 0)
	rotation: number?,       -- Y rotation in degrees (default 0)
	flattenRadius: number?,  -- Flatten terrain radius (default 0)
	scale: number?,          -- Scale multiplier (default 1)
	parent: Instance?,       -- Parent folder (required)
	name: string?,           -- Custom name (default assetName)
	model: Model?,           -- Pre-loaded model (optional, skips cloud loading)
	zone: string?,           -- Zone name for attributes
	beacon: boolean?,        -- Is this a navigation beacon?
	tags: { string }?,       -- Additional CollectionService tags
}

export type StructureEntity = {
	assetName: string,
	config: typeof(TerrainConfig.STRUCTURES.DEFAULT),
	cloudAssetId: number?,

	spawn: (self: StructureEntity, x: number, z: number, options: SpawnOptions) -> Model?,
	getConfig: (self: StructureEntity) -> typeof(TerrainConfig.STRUCTURES.DEFAULT),
}

local StructureEntity = {}
StructureEntity.__index = StructureEntity

--[[
	Create a new structure entity for the given asset type.
	@param assetName The name of the asset (e.g., "WaterTower", "FerrisWheel")
]]
function StructureEntity.new(assetName: string): StructureEntity
	local self = setmetatable({}, StructureEntity)

	self.assetName = assetName
	self.config = TerrainConfig.GetStructureConfig(assetName)
	self.cloudAssetId = CLOUD_ASSETS[assetName]

	return self :: any
end

--[[
	Get the structure configuration.
]]
function StructureEntity:getConfig()
	return self.config
end

--[[
	Spawn the structure at the given world coordinates.
	@param x World X coordinate
	@param z World Z coordinate
	@param options Spawn options (anchored, dropHeight, rotation, etc.)
	@return The spawned model, or nil on failure
]]
function StructureEntity:spawn(x: number, z: number, options: SpawnOptions): Model?
	local assetName = self.assetName
	local config = self.config

	-- Validate parent
	if not options.parent then
		warn("[StructureEntity] No parent specified for " .. assetName)
		return nil
	end

	-- Default options
	local isAnchored = options.anchored ~= false
	local baseDropHeight = options.dropHeight or 0
	local rotation = options.rotation or 0
	local flattenRadius = options.flattenRadius or 0
	local scale = options.scale or 1
	local modelName = options.name or assetName

	-- Apply drop multiplier from config
	local actualDropHeight = baseDropHeight * config.dropMultiplier

	print(string.format("[StructureEntity] Spawning %s (anchored=%s, drop=%.1f)",
		assetName, tostring(isAnchored), actualDropHeight))

	-- Use pre-loaded model if provided, otherwise try cloud
	local model: Model? = options.model
	if model then
		print(string.format("[StructureEntity] Using pre-loaded model for %s", assetName))
	elseif self.cloudAssetId then
		local success, result = pcall(function()
			return InsertService:LoadAsset(self.cloudAssetId)
		end)

		if success and result then
			-- Extract model from container
			for _, child in result:GetChildren() do
				if child:IsA("Model") or child:IsA("MeshPart") then
					model = child :: Model
					break
				end
			end

			if model then
				-- CRITICAL: Unparent from container BEFORE destroying container
				model.Parent = nil

				-- Wrap MeshPart in Model if needed
				if not model:IsA("Model") then
					local wrapper = Instance.new("Model")
					wrapper.Name = assetName
					model.Parent = wrapper
					wrapper.PrimaryPart = model :: BasePart
					model = wrapper
				end
			end

			result:Destroy()
		else
			warn("[StructureEntity] Failed to load cloud asset: " .. tostring(result))
		end
	end

	-- Create placeholder if no model available
	if not model then
		model = Instance.new("Model")
		model.Name = assetName .. "_Placeholder"

		local part = Instance.new("Part")
		part.Name = "Main"
		part.Size = Vector3.new(20, 20, 20)
		part.Color = Color3.fromRGB(200, 100, 100)
		part.Anchored = isAnchored
		part.Parent = model

		model.PrimaryPart = part
	end

	-- Ensure PrimaryPart is set
	if not model.PrimaryPart then
		local largest: BasePart? = nil
		local maxVol = 0
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") then
				local vol = p.Size.X * p.Size.Y * p.Size.Z
				if vol > maxVol then
					maxVol = vol
					largest = p
				end
			end
		end
		if largest then
			model.PrimaryPart = largest
		end
	end

	-- Set anchoring on all parts
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = isAnchored
		end
	end

	-- Apply scale
	if scale ~= 1 then
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Size = part.Size * scale
			end
		end
	end

	-- Apply colors
	local colors = getAssetColors()
	if colors then
		colors:ApplyColors(model, assetName)
	end

	-- Calculate terrain height
	local terrainY: number
	if flattenRadius > 0 then
		terrainY = Heightmap:FlattenArea(x, z, flattenRadius)
	else
		terrainY = Heightmap:GetHeight(x, z)
	end

	-- Calculate model bottom offset
	local minY = math.huge
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local partBottom = part.Position.Y - part.Size.Y / 2
			minY = math.min(minY, partBottom)
		end
	end

	-- Calculate final Y position
	local finalY = terrainY
	if minY < math.huge then
		finalY = terrainY - minY
	elseif model.PrimaryPart then
		finalY = terrainY + model.PrimaryPart.Size.Y / 2
	end

	-- Apply per-structure Y offset
	finalY = finalY + config.yOffset

	-- Apply drop height for unanchored structures
	if not isAnchored then
		finalY = finalY + actualDropHeight
	end

	-- Build rotation CFrame (user rotation + structure correction)
	local rotX = config.rotationX or 0
	local rotY = config.rotationY or 0
	local rotZ = config.rotationZ or 0

	local cframe = CFrame.new(x, finalY, z)
		* CFrame.Angles(0, math.rad(rotation), 0)
		* CFrame.Angles(math.rad(rotX), math.rad(rotY), math.rad(rotZ))

	model:PivotTo(cframe)

	-- Set name and attributes
	local suffix = isAnchored and "_Anchored" or ("_Drop" .. string.format("%.0f", actualDropHeight))
	model.Name = modelName .. suffix

	model:SetAttribute("AssetName", assetName)
	model:SetAttribute("StructureType", assetName)
	model:SetAttribute("Sensitivity", config.sensitivity)
	model:SetAttribute("IsAnchored", isAnchored)
	if options.zone then
		model:SetAttribute("Zone", options.zone)
	end
	if options.beacon then
		model:SetAttribute("IsBeacon", true)
	end

	-- Add CollectionService tags
	CollectionService:AddTag(model, "Structure")
	CollectionService:AddTag(model, assetName)
	if options.beacon then
		CollectionService:AddTag(model, "Beacon")
	end
	if options.tags then
		for _, tag in ipairs(options.tags) do
			CollectionService:AddTag(model, tag)
		end
	end

	-- Parent to folder
	model.Parent = options.parent

	print(string.format("[StructureEntity] Spawned %s at (%.0f, %.0f, %.0f)",
		model.Name, x, finalY, z))

	return model
end

--[[
	Get all available structure asset names.
]]
function StructureEntity.getAvailableAssets(): { string }
	local names = {}
	for name in pairs(CLOUD_ASSETS) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

--[[
	Check if an asset name is valid.
]]
function StructureEntity.isValidAsset(assetName: string): boolean
	return CLOUD_ASSETS[assetName] ~= nil
end

return StructureEntity
