--!strict
--[[
	Faultline Fear: Beacon Controller

	Client-side objective beacon system.
	Shows a light pillar/beam pointing toward current objectives.

	Features:
	- Animated beam effect pointing to target
	- Compass direction indicator on HUD
	- Distance display
	- Multiple beacon types (main quest, optional, collectibles)

	Exports: Initialize(), ShowBeacon(), HideBeacon(), UpdateObjective()
	Depends: ObjectiveUpdate remote, Workspace
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local BeaconController = {}

-- Configuration
local BEACON_HEIGHT = 1000
local COMPASS_SIZE = 100

-- State
local activeBeacons: { [string]: Model } = {}
local beaconFolder: Folder = nil :: any
local compassUI: Frame = nil :: any
local distanceLabel: TextLabel = nil :: any
local directionArrow: ImageLabel = nil :: any
local currentTarget: Vector3? = nil

-- Beacon color schemes
local BEACON_COLORS = {
	main = Color3.fromRGB(255, 200, 50), -- Gold for main objectives
	optional = Color3.fromRGB(100, 200, 255), -- Blue for optional
	collectible = Color3.fromRGB(100, 255, 100), -- Green for collectibles
}

-- ==========================================
-- BEACON CREATION
-- ==========================================

local function createBeamPart(color: Color3, position: Vector3): Part
	local part = Instance.new("Part")
	part.Name = "BeaconBeam"
	part.Size = Vector3.new(4, BEACON_HEIGHT, 4)
	part.Position = position + Vector3.new(0, BEACON_HEIGHT / 2, 0)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Transparency = 0.7
	part.Material = Enum.Material.Neon
	part.Color = color

	-- Add beam effect
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 30
	light.Color = color
	light.Parent = part

	return part
end

local function createBaseRing(color: Color3, position: Vector3): Part
	local part = Instance.new("Part")
	part.Name = "BeaconBase"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(1, 20, 20)
	part.Position = position
	part.Orientation = Vector3.new(0, 0, 90)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Transparency = 0.5
	part.Material = Enum.Material.Neon
	part.Color = color

	return part
end

local function createBeacon(id: string, position: Vector3, beaconType: string): Model
	local color = BEACON_COLORS[beaconType] or BEACON_COLORS.main

	local model = Instance.new("Model")
	model.Name = "Beacon_" .. id

	-- Create beam
	local beam = createBeamPart(color, position)
	beam.Parent = model

	-- Create base ring
	local baseRing = createBaseRing(color, position)
	baseRing.Parent = model

	model.PrimaryPart = baseRing

	-- Animate the base ring (pulse effect)
	task.spawn(function()
		while model.Parent do
			local tween =
				TweenService:Create(baseRing, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Size = Vector3.new(1, 25, 25),
					Transparency = 0.7,
				})
			tween:Play()
			tween.Completed:Wait()

			tween =
				TweenService:Create(baseRing, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Size = Vector3.new(1, 20, 20),
					Transparency = 0.5,
				})
			tween:Play()
			tween.Completed:Wait()
		end
	end)

	return model
end

-- ==========================================
-- COMPASS UI
-- ==========================================

local function createCompassUI()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Check if HUD already exists, attach to it
	local hudGui = playerGui:FindFirstChild("FaultlineFearHUD")
	local parent: Instance = if hudGui then hudGui else playerGui

	local screenGui: ScreenGui
	if hudGui then
		screenGui = hudGui :: ScreenGui
	else
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "FaultlineFearBeacon"
		screenGui.ResetOnSpawn = false
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.DisplayOrder = 5
		screenGui.Parent = playerGui
		parent = screenGui
	end

	-- Compass container (top center)
	compassUI = Instance.new("Frame")
	compassUI.Name = "ObjectiveCompass"
	compassUI.Size = UDim2.new(0, COMPASS_SIZE, 0, COMPASS_SIZE + 30)
	compassUI.Position = UDim2.new(0.5, -COMPASS_SIZE / 2, 0, 10)
	compassUI.BackgroundTransparency = 1
	compassUI.Visible = false
	compassUI.Parent = parent

	-- Direction arrow (rotates to point at objective)
	directionArrow = Instance.new("ImageLabel")
	directionArrow.Name = "DirectionArrow"
	directionArrow.Size = UDim2.new(0, 60, 0, 60)
	directionArrow.Position = UDim2.new(0.5, -30, 0, 10)
	directionArrow.BackgroundTransparency = 1
	directionArrow.Image = "rbxassetid://6031091004" -- Arrow icon
	directionArrow.ImageColor3 = BEACON_COLORS.main
	directionArrow.Parent = compassUI

	-- Distance label
	distanceLabel = Instance.new("TextLabel")
	distanceLabel.Name = "DistanceLabel"
	distanceLabel.Size = UDim2.new(1, 0, 0, 25)
	distanceLabel.Position = UDim2.new(0, 0, 1, -25)
	distanceLabel.BackgroundTransparency = 1
	distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	distanceLabel.TextStrokeTransparency = 0.5
	distanceLabel.TextSize = 16
	distanceLabel.Font = Enum.Font.GothamBold
	distanceLabel.Text = "0m"
	distanceLabel.Parent = compassUI

	print("[BeaconController] Compass UI created")
end

local function updateCompass()
	if not currentTarget then
		compassUI.Visible = false
		return
	end

	local player = Players.LocalPlayer
	local character = player.Character
	if not character then
		compassUI.Visible = false
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		compassUI.Visible = false
		return
	end

	compassUI.Visible = true

	local playerPos = humanoidRootPart.Position
	local targetPos = currentTarget

	-- Calculate distance
	local distance = (Vector3.new(targetPos.X, playerPos.Y, targetPos.Z) - Vector3.new(
		playerPos.X,
		playerPos.Y,
		playerPos.Z
	)).Magnitude
	distanceLabel.Text = string.format("%.0fm", distance)

	-- Calculate direction angle
	local direction = (targetPos - playerPos).Unit
	local _, playerRotation, _ = humanoidRootPart.CFrame:ToOrientation()

	local targetAngle = math.atan2(direction.X, direction.Z)
	local relativeAngle = targetAngle - playerRotation

	-- Rotate arrow to point at target
	directionArrow.Rotation = math.deg(relativeAngle)

	-- Change color based on distance
	if distance < 50 then
		directionArrow.ImageColor3 = Color3.fromRGB(100, 255, 100) -- Green when close
	elseif distance < 200 then
		directionArrow.ImageColor3 = Color3.fromRGB(255, 200, 50) -- Gold
	else
		directionArrow.ImageColor3 = Color3.fromRGB(255, 255, 255) -- White when far
	end
end

-- ==========================================
-- PUBLIC API
-- ==========================================

function BeaconController:ShowBeacon(id: string, position: Vector3, beaconType: string?)
	-- Remove existing beacon with same ID
	self:HideBeacon(id)

	local beacon = createBeacon(id, position, beaconType or "main")
	beacon.Parent = beaconFolder

	activeBeacons[id] = beacon

	-- Set as current target if it's a main beacon
	if beaconType == "main" or beaconType == nil then
		currentTarget = position
	end

	print(string.format("[BeaconController] Showing beacon '%s' at %s", id, tostring(position)))
end

function BeaconController:HideBeacon(id: string)
	local beacon = activeBeacons[id]
	if beacon then
		beacon:Destroy()
		activeBeacons[id] = nil

		-- Clear current target if this was it
		if currentTarget then
			currentTarget = nil
		end

		print(string.format("[BeaconController] Hidden beacon '%s'", id))
	end
end

function BeaconController:HideAllBeacons()
	for id, _ in pairs(activeBeacons) do
		self:HideBeacon(id)
	end
	currentTarget = nil
end

function BeaconController:SetCurrentTarget(position: Vector3?)
	currentTarget = position
	if not position then
		compassUI.Visible = false
	end
end

function BeaconController:UpdateFromObjective(objectiveData: any)
	-- Clear existing beacons
	self:HideAllBeacons()

	-- Determine beacon position based on current objective
	local workspace = game:GetService("Workspace")
	local storyZones = workspace:FindFirstChild("StoryZones")

	if not storyZones then
		return
	end

	-- Map objectives to zones
	local objectiveZoneMap: { [string]: string } = {
		reach_town = "CoastalTown",
		cross_fault = "FaultLineNorth",
		find_survivors_aftermath = "SurvivorCamp",
		adapt_new_terrain = "MountainBase",
		ascend_mountain = "RadioTower",
		board_helicopter = "HelicopterZone",
	}

	-- Find first incomplete main objective and show beacon
	if objectiveData.objectives then
		for _, objective in ipairs(objectiveData.objectives) do
			if not objective.isOptional then
				local current = objectiveData.completedObjectives[objective.id] or 0
				local required = objective.requiredCount or 1

				if current < required then
					-- Found incomplete objective
					local zoneName = objectiveZoneMap[objective.id]
					if zoneName then
						local zone = storyZones:FindFirstChild("StoryZone_" .. zoneName)
						if zone and zone:IsA("BasePart") then
							self:ShowBeacon("main_objective", zone.Position, "main")
							break
						end
					end
				end
			end
		end
	end
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function BeaconController:Initialize()
	-- Create folder for beacons
	beaconFolder = Instance.new("Folder")
	beaconFolder.Name = "ObjectiveBeacons"
	beaconFolder.Parent = game:GetService("Workspace")

	-- Create compass UI
	createCompassUI()

	-- Start compass update loop
	RunService.Heartbeat:Connect(function()
		updateCompass()
	end)

	-- Listen for objective updates
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if remotes then
		local objectiveUpdate = remotes:FindFirstChild("ObjectiveUpdate")
		if objectiveUpdate then
			(objectiveUpdate :: RemoteEvent).OnClientEvent:Connect(function(data)
				self:UpdateFromObjective(data)
			end)
		end
	end

	print("[BeaconController] Initialized")
end

return BeaconController
