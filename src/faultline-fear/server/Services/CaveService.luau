--!strict
--[[
	Faultline Fear: Cave Service

	Manages cave entrances and interior spaces in the Mountain zone.
	Caves provide shelter from night creatures and contain secrets.

	Features:
	- Cave entrance placement in Mountain zone
	- Interior darkness (flashlight required)
	- Safe zones from night creatures
	- Hidden collectible spawns
	- Ambient effects

	Exports: Initialize(), GetCaves(), IsPlayerInCave()
	Depends: Config, Heightmap, AssetManifest
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local _Config = Shared.Config
local Heightmap = Shared.Heightmap
local AssetManifest = Shared.AssetManifest
local AssetColors = Shared.AssetColors

local CaveService = {}

-- State
local caves: { Model } = {}
local cavesFolder: Folder = nil :: any
local playerInCave: { [Player]: boolean } = {}

-- Cave definitions
type CaveDef = {
	name: string,
	position: Vector3,
	rotation: number,
	size: string, -- small, medium, large
	hasSecrets: boolean,
	description: string,
}

local CAVE_DEFINITIONS: { CaveDef } = {
	{
		name = "MountainCave_Main",
		position = Vector3.new(100, 0, 1500),
		rotation = 180,
		size = "large",
		hasSecrets = true,
		description = "Large cave with multiple chambers - main shelter",
	},
	{
		name = "MountainCave_Hidden",
		position = Vector3.new(-200, 0, 1650),
		rotation = 135,
		size = "medium",
		hasSecrets = true,
		description = "Hidden cave with emergency supplies",
	},
	{
		name = "MountainCave_Small",
		position = Vector3.new(50, 0, 1400),
		rotation = 200,
		size = "small",
		hasSecrets = false,
		description = "Small shelter cave near the path",
	},
}

-- Interior zone size based on cave size
local INTERIOR_SIZES = {
	small = Vector3.new(10, 8, 15),
	medium = Vector3.new(20, 12, 25),
	large = Vector3.new(35, 15, 40),
}

-- ==========================================
-- PLACEHOLDER CREATION
-- ==========================================

local function createPlaceholderCave(def: CaveDef): Model
	local model = Instance.new("Model")
	model.Name = def.name .. "_Placeholder"

	local size = INTERIOR_SIZES[def.size] or INTERIOR_SIZES.medium

	-- Entrance arch
	local entrance = Instance.new("Part")
	entrance.Name = "Entrance"
	entrance.Size = Vector3.new(size.X * 0.6, size.Y * 0.8, 3)
	entrance.Anchored = true
	entrance.CanCollide = true
	entrance.Color = Color3.fromRGB(80, 75, 70)
	entrance.Material = Enum.Material.Rock
	entrance.Parent = model

	-- Interior floor (invisible trigger)
	local interior = Instance.new("Part")
	interior.Name = "InteriorZone"
	interior.Size = size
	interior.Position = Vector3.new(0, size.Y / 2, size.Z / 2)
	interior.Anchored = true
	interior.CanCollide = false
	interior.Transparency = 1
	interior.Parent = model

	-- Dark lighting inside
	local darkness = Instance.new("Part")
	darkness.Name = "DarknessZone"
	darkness.Size = size * 0.9
	darkness.Position = interior.Position
	darkness.Anchored = true
	darkness.CanCollide = false
	darkness.Transparency = 0.95
	darkness.Color = Color3.fromRGB(10, 10, 15)
	darkness.Material = Enum.Material.SmoothPlastic
	darkness.Parent = model

	model.PrimaryPart = entrance
	return model
end

-- ==========================================
-- CAVE SPAWNING
-- ==========================================

local function spawnCave(def: CaveDef): Model
	-- Try imported model
	local assetName = "CaveEntrance_" .. def.size:sub(1, 1):upper() .. def.size:sub(2)
	local model = AssetManifest:CloneAsset(assetName)

	if model then
		-- Apply colors to imported model (Roblox doesn't import FBX colors)
		AssetColors:ApplyColors(model, assetName)
	else
		model = createPlaceholderCave(def)
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
	model:SetAttribute("CaveSize", def.size)
	model:SetAttribute("HasSecrets", def.hasSecrets)
	model:SetAttribute("Description", def.description)

	-- Tags
	CollectionService:AddTag(model, "Cave")
	CollectionService:AddTag(model, "SafeZone") -- Creatures won't enter

	-- Add interior zone for player detection
	local interiorZone = model:FindFirstChild("InteriorZone")
	if not interiorZone then
		local size = INTERIOR_SIZES[def.size] or INTERIOR_SIZES.medium
		interiorZone = Instance.new("Part")
		interiorZone.Name = "InteriorZone"
		interiorZone.Size = size
		interiorZone.Anchored = true
		interiorZone.CanCollide = false
		interiorZone.Transparency = 1

		-- Position behind entrance
		local offset = CFrame.new(0, size.Y / 2, size.Z / 2)
		interiorZone.CFrame = cframe * offset
		interiorZone.Parent = model
	end

	-- Setup touch detection
	if interiorZone:IsA("BasePart") then
		interiorZone.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				playerInCave[player] = true
			end
		end)

		interiorZone.TouchEnded:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				playerInCave[player] = false
			end
		end)
	end

	model.Parent = cavesFolder
	table.insert(caves, model)

	return model
end

-- ==========================================
-- SECRET SPAWNING
-- ==========================================

local function spawnCaveSecrets(cave: Model)
	if not cave:GetAttribute("HasSecrets") then
		return
	end

	local interiorZone = cave:FindFirstChild("InteriorZone")
	if not interiorZone or not interiorZone:IsA("BasePart") then
		return
	end

	-- Create supply cache
	local cache = Instance.new("Part")
	cache.Name = "SupplyCache"
	cache.Size = Vector3.new(2, 1.5, 1)
	cache.Anchored = true
	cache.CanCollide = true
	cache.Color = Color3.fromRGB(100, 80, 60)
	cache.Material = Enum.Material.WoodPlanks

	-- Position inside cave
	local zonePos = interiorZone.Position
	cache.Position = Vector3.new(
		zonePos.X + (math.random() - 0.5) * interiorZone.Size.X * 0.5,
		zonePos.Y - interiorZone.Size.Y / 2 + 0.75,
		zonePos.Z + math.random() * interiorZone.Size.Z * 0.3
	)

	-- Add collectible tag
	CollectionService:AddTag(cache, "SupplyCache")
	CollectionService:AddTag(cache, "Interactable")

	-- Add proximity prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Search"
	prompt.ObjectText = "Supply Cache"
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 6
	prompt.Parent = cache

	prompt.Triggered:Connect(function(player)
		-- Give supplies
		print(string.format("[CaveService] %s found supplies in %s", player.Name, cave.Name))
		cache:Destroy()
	end)

	cache.Parent = cave

	print(string.format("[CaveService] Spawned secrets in %s", cave.Name))
end

-- ==========================================
-- PUBLIC API
-- ==========================================

function CaveService:GetCaves(): { Model }
	return caves
end

function CaveService:GetCaveByName(name: string): Model?
	for _, cave in ipairs(caves) do
		if cave.Name == name then
			return cave
		end
	end
	return nil
end

function CaveService:IsPlayerInCave(player: Player): boolean
	return playerInCave[player] or false
end

function CaveService:GetPlayersInCaves(): { Player }
	local result = {}
	for player, inCave in pairs(playerInCave) do
		if inCave and player.Parent then
			table.insert(result, player)
		end
	end
	return result
end

function CaveService:Initialize()
	-- Create folder
	cavesFolder = Instance.new("Folder")
	cavesFolder.Name = "Caves"
	cavesFolder.Parent = Workspace

	-- Spawn all caves
	print("[CaveService] Spawning caves in Mountain zone...")

	for _, def in ipairs(CAVE_DEFINITIONS) do
		local cave = spawnCave(def)
		spawnCaveSecrets(cave)
		print(string.format("  - %s (%s) at (%.0f, %.0f)", def.name, def.size, def.position.X, def.position.Z))
	end

	-- Clean up on player leave
	Players.PlayerRemoving:Connect(function(player)
		playerInCave[player] = nil
	end)

	print(string.format("[CaveService] Initialized with %d caves", #caves))
end

return CaveService
