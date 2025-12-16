--!strict
--[[
	Faultline Fear: Story Zone Manager

	Creates and manages story trigger zones in the world.
	Places invisible trigger parts at key narrative locations.

	Zones are positioned based on Config.ZONES terrain boundaries.

	Exports: Initialize(), GetZone()
	Depends: Config, CollectionService
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config

local StoryZoneManager = {}

-- Zone folder
local zoneFolder: Folder = nil :: any

-- Zone definitions: where each story zone is placed
-- Coordinates are calculated from Config.ZONES
local ZONE_DEFINITIONS = {
	-- ACT 1: Coastal Town (in COASTAL zone)
	CoastalTown = {
		position = function()
			local coastal = Config.ZONES.COASTAL
			local centerZ = (coastal.zMin + coastal.zMax) / 2
			return Vector3.new(0, 20, centerZ)
		end,
		size = Vector3.new(300, 100, 200),
		description = "The destroyed coastal town - first major destination",
	},

	-- ACT 2: Fault Line North (north side of FAULT_LINE zone)
	FaultLineNorth = {
		position = function()
			local fault = Config.ZONES.FAULT_LINE
			return Vector3.new(0, 20, fault.zMax)
		end,
		size = Vector3.new(400, 100, 100),
		description = "North side of the fault line - crossing point",
	},

	-- ACT 3: Survivor Camp (in VALLEY zone)
	SurvivorCamp = {
		position = function()
			local valley = Config.ZONES.VALLEY
			local centerZ = (valley.zMin + valley.zMax) / 2
			return Vector3.new(-300, 20, centerZ)
		end,
		size = Vector3.new(150, 80, 150),
		description = "Makeshift survivor camp in the valley",
	},

	-- ACT 3: Mountain Base (at start of MOUNTAIN zone)
	MountainBase = {
		position = function()
			local mountain = Config.ZONES.MOUNTAIN
			return Vector3.new(0, 50, mountain.zMin)
		end,
		size = Vector3.new(300, 150, 100),
		description = "Base of the mountain - start of the climb",
	},

	-- ACT 4: Radio Tower (high in MOUNTAIN zone)
	RadioTower = {
		position = function()
			local mountain = Config.ZONES.MOUNTAIN
			local centerZ = (mountain.zMin + mountain.zMax) / 2
			return Vector3.new(0, 300, centerZ + 200)
		end,
		size = Vector3.new(100, 200, 100),
		description = "The radio tower at the mountain summit",
	},

	-- ACT 5: Helicopter Zone (near RadioTower, flat landing area)
	HelicopterZone = {
		position = function()
			local mountain = Config.ZONES.MOUNTAIN
			local centerZ = (mountain.zMin + mountain.zMax) / 2
			return Vector3.new(100, 300, centerZ + 250)
		end,
		size = Vector3.new(60, 50, 60),
		description = "Helicopter landing pad - extraction point",
	},

	-- Spawn Zone (in BEACH zone - where players start)
	SpawnZone = {
		position = function()
			local beach = Config.ZONES.BEACH
			local centerZ = (beach.zMin + beach.zMax) / 2
			return Vector3.new(0, 10, centerZ)
		end,
		size = Vector3.new(200, 50, 200),
		description = "Player spawn area on the beach",
	},
}

-- ==========================================
-- ZONE CREATION
-- ==========================================

local function createZonePart(zoneId: string, definition: any): BasePart
	local part = Instance.new("Part")
	part.Name = "StoryZone_" .. zoneId
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1 -- Invisible
	part.CanQuery = false -- Don't affect raycasts
	part.CanTouch = true -- But do trigger touch events

	-- Calculate position from definition
	local position = definition.position()
	part.Position = position
	part.Size = definition.size

	-- Set zone attributes
	part:SetAttribute("ZoneId", zoneId)
	part:SetAttribute("Description", definition.description)

	-- Add CollectionService tag for StoryBeatProcessor
	CollectionService:AddTag(part, "StoryZone")

	return part
end

-- ==========================================
-- PUBLIC API
-- ==========================================

function StoryZoneManager:GetZone(zoneId: string): BasePart?
	if zoneFolder then
		return zoneFolder:FindFirstChild("StoryZone_" .. zoneId) :: BasePart
	end
	return nil
end

function StoryZoneManager:GetAllZones(): { BasePart }
	local zones = {}
	if zoneFolder then
		for _, child in zoneFolder:GetChildren() do
			if child:IsA("BasePart") then
				table.insert(zones, child)
			end
		end
	end
	return zones
end

function StoryZoneManager:Initialize()
	-- Create folder for organization
	zoneFolder = Instance.new("Folder")
	zoneFolder.Name = "StoryZones"
	zoneFolder.Parent = Workspace

	-- Create all story zones
	for zoneId, definition in pairs(ZONE_DEFINITIONS) do
		local zonePart = createZonePart(zoneId, definition)
		zonePart.Parent = zoneFolder
		print(string.format("[StoryZoneManager] Created zone: %s at %s", zoneId, tostring(zonePart.Position)))
	end

	print(string.format("[StoryZoneManager] Initialized with %d zones", #self:GetAllZones()))
end

-- ==========================================
-- DEBUG
-- ==========================================

function StoryZoneManager:DebugShowZones(visible: boolean)
	for _, zone in self:GetAllZones() do
		zone.Transparency = if visible then 0.7 else 1
		if visible then
			zone.BrickColor = BrickColor.new("Bright green")
		end
	end
	print(string.format("[StoryZoneManager] Debug visibility: %s", tostring(visible)))
end

return StoryZoneManager
