--!strict
-- UI for Mertin-Flemmer
-- Stamina bar, hunger bar, inventory, time of day, warnings

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config

-- Wait for remotes
local TimeUpdateRemote = ReplicatedStorage:WaitForChild("TimeUpdate") :: RemoteEvent
local UpdateInventoryRemote = ReplicatedStorage:WaitForChild("UpdateInventory") :: RemoteEvent
local CollectResourceRemote = ReplicatedStorage:WaitForChild("CollectResource") :: RemoteEvent
local ObjectiveUpdateRemote = ReplicatedStorage:WaitForChild("ObjectiveUpdate") :: RemoteEvent
local MissionUpdateRemote = ReplicatedStorage:WaitForChild("MissionUpdate") :: RemoteEvent
local MissionCompleteRemote = ReplicatedStorage:WaitForChild("MissionComplete") :: RemoteEvent
local TradingRemote = ReplicatedStorage:WaitForChild("Trading") :: RemoteEvent
local OpenShopRemote = ReplicatedStorage:WaitForChild("OpenShop") :: RemoteEvent

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MertinFlemmerUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Stamina bar
local staminaContainer = Instance.new("Frame")
staminaContainer.Name = "StaminaBar"
staminaContainer.Size = UDim2.new(0, 200, 0, 10)
staminaContainer.Position = UDim2.new(0.5, -100, 1, -50)
staminaContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
staminaContainer.BorderSizePixel = 0
staminaContainer.Parent = screenGui

local staminaCorner = Instance.new("UICorner")
staminaCorner.CornerRadius = UDim.new(0, 4)
staminaCorner.Parent = staminaContainer

local staminaFill = Instance.new("Frame")
staminaFill.Name = "Fill"
staminaFill.Size = UDim2.new(1, -4, 1, -4)
staminaFill.Position = UDim2.new(0, 2, 0, 2)
staminaFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
staminaFill.BorderSizePixel = 0
staminaFill.Parent = staminaContainer

local staminaFillCorner = Instance.new("UICorner")
staminaFillCorner.CornerRadius = UDim.new(0, 2)
staminaFillCorner.Parent = staminaFill

-- Time display
local timeDisplay = Instance.new("TextLabel")
timeDisplay.Name = "TimeDisplay"
timeDisplay.Size = UDim2.new(0, 150, 0, 40)
timeDisplay.Position = UDim2.new(0.5, -75, 0, 10)
timeDisplay.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
timeDisplay.BackgroundTransparency = 0.3
timeDisplay.Text = "Day 1"
timeDisplay.TextColor3 = Color3.new(1, 1, 1)
timeDisplay.Font = Enum.Font.GothamBold
timeDisplay.TextSize = 18
timeDisplay.Parent = screenGui

local timeCorner = Instance.new("UICorner")
timeCorner.CornerRadius = UDim.new(0, 8)
timeCorner.Parent = timeDisplay

-- Night warning
local nightWarning = Instance.new("TextLabel")
nightWarning.Name = "NightWarning"
nightWarning.Size = UDim2.new(1, 0, 0, 60)
nightWarning.Position = UDim2.new(0, 0, 0.3, 0)
nightWarning.BackgroundTransparency = 1
nightWarning.Text = "NIGHT IS FALLING"
nightWarning.TextColor3 = Color3.fromRGB(255, 50, 50)
nightWarning.TextStrokeTransparency = 0
nightWarning.TextStrokeColor3 = Color3.new(0, 0, 0)
nightWarning.Font = Enum.Font.GothamBlack
nightWarning.TextSize = 48
nightWarning.TextTransparency = 1
nightWarning.Parent = screenGui

-- Controls hint
local controlsHint = Instance.new("TextLabel")
controlsHint.Size = UDim2.new(0, 400, 0, 20)
controlsHint.Position = UDim2.new(0.5, -200, 1, -25)
controlsHint.BackgroundTransparency = 1
controlsHint.Text = "WASD: Move | Shift: Sprint | F: Flashlight | 1: Eat | 2: Battery | 3: Wood"
controlsHint.TextColor3 = Color3.fromRGB(180, 180, 180)
controlsHint.Font = Enum.Font.Gotham
controlsHint.TextSize = 12
controlsHint.Parent = screenGui

-- Hunger bar (below stamina)
local hungerContainer = Instance.new("Frame")
hungerContainer.Name = "HungerBar"
hungerContainer.Size = UDim2.new(0, 200, 0, 10)
hungerContainer.Position = UDim2.new(0.5, -100, 1, -70)
hungerContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
hungerContainer.BorderSizePixel = 0
hungerContainer.Parent = screenGui

local hungerCorner = Instance.new("UICorner")
hungerCorner.CornerRadius = UDim.new(0, 4)
hungerCorner.Parent = hungerContainer

local hungerFill = Instance.new("Frame")
hungerFill.Name = "Fill"
hungerFill.Size = UDim2.new(1, -4, 1, -4)
hungerFill.Position = UDim2.new(0, 2, 0, 2)
hungerFill.BackgroundColor3 = Color3.fromRGB(255, 180, 100)
hungerFill.BorderSizePixel = 0
hungerFill.Parent = hungerContainer

local hungerFillCorner = Instance.new("UICorner")
hungerFillCorner.CornerRadius = UDim.new(0, 2)
hungerFillCorner.Parent = hungerFill

local hungerLabel = Instance.new("TextLabel")
hungerLabel.Size = UDim2.new(0, 60, 0, 10)
hungerLabel.Position = UDim2.new(0.5, -130, 1, -70)
hungerLabel.BackgroundTransparency = 1
hungerLabel.Text = "HUNGER"
hungerLabel.TextColor3 = Color3.fromRGB(255, 180, 100)
hungerLabel.Font = Enum.Font.GothamBold
hungerLabel.TextSize = 10
hungerLabel.Parent = screenGui

-- Inventory display (bottom left)
local inventoryFrame = Instance.new("Frame")
inventoryFrame.Name = "Inventory"
inventoryFrame.Size = UDim2.new(0, 150, 0, 100)
inventoryFrame.Position = UDim2.new(0, 10, 1, -120)
inventoryFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
inventoryFrame.BackgroundTransparency = 0.3
inventoryFrame.BorderSizePixel = 0
inventoryFrame.Parent = screenGui

local inventoryCorner = Instance.new("UICorner")
inventoryCorner.CornerRadius = UDim.new(0, 8)
inventoryCorner.Parent = inventoryFrame

local inventoryTitle = Instance.new("TextLabel")
inventoryTitle.Size = UDim2.new(1, 0, 0, 25)
inventoryTitle.BackgroundTransparency = 1
inventoryTitle.Text = "INVENTORY"
inventoryTitle.TextColor3 = Color3.new(1, 1, 1)
inventoryTitle.Font = Enum.Font.GothamBold
inventoryTitle.TextSize = 12
inventoryTitle.Parent = inventoryFrame

local foodLabel = Instance.new("TextLabel")
foodLabel.Name = "Food"
foodLabel.Size = UDim2.new(1, -10, 0, 20)
foodLabel.Position = UDim2.new(0, 5, 0, 28)
foodLabel.BackgroundTransparency = 1
foodLabel.Text = "[1] Food: 0"
foodLabel.TextColor3 = Color3.fromRGB(200, 100, 100)
foodLabel.TextXAlignment = Enum.TextXAlignment.Left
foodLabel.Font = Enum.Font.Gotham
foodLabel.TextSize = 14
foodLabel.Parent = inventoryFrame

local batteryLabel = Instance.new("TextLabel")
batteryLabel.Name = "Battery"
batteryLabel.Size = UDim2.new(1, -10, 0, 20)
batteryLabel.Position = UDim2.new(0, 5, 0, 50)
batteryLabel.BackgroundTransparency = 1
batteryLabel.Text = "[2] Batteries: 0"
batteryLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
batteryLabel.TextXAlignment = Enum.TextXAlignment.Left
batteryLabel.Font = Enum.Font.Gotham
batteryLabel.TextSize = 14
batteryLabel.Parent = inventoryFrame

local woodLabel = Instance.new("TextLabel")
woodLabel.Name = "Wood"
woodLabel.Size = UDim2.new(1, -10, 0, 20)
woodLabel.Position = UDim2.new(0, 5, 0, 72)
woodLabel.BackgroundTransparency = 1
woodLabel.Text = "[3] Wood: 0"
woodLabel.TextColor3 = Color3.fromRGB(150, 100, 60)
woodLabel.TextXAlignment = Enum.TextXAlignment.Left
woodLabel.Font = Enum.Font.Gotham
woodLabel.TextSize = 14
woodLabel.Parent = inventoryFrame

-- Collection notification
local collectNotification = Instance.new("TextLabel")
collectNotification.Name = "CollectNotification"
collectNotification.Size = UDim2.new(0, 300, 0, 40)
collectNotification.Position = UDim2.new(0.5, -150, 0.7, 0)
collectNotification.BackgroundTransparency = 1
collectNotification.Text = ""
collectNotification.TextColor3 = Color3.fromRGB(100, 255, 100)
collectNotification.TextStrokeTransparency = 0.3
collectNotification.Font = Enum.Font.GothamBold
collectNotification.TextSize = 18
collectNotification.TextTransparency = 1
collectNotification.Parent = screenGui

-- Missions panel (top right) - shows active quests
local missionsFrame = Instance.new("Frame")
missionsFrame.Name = "MissionsPanel"
missionsFrame.Size = UDim2.new(0, 280, 0, 300)
missionsFrame.Position = UDim2.new(1, -290, 0, 10)
missionsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
missionsFrame.BackgroundTransparency = 0.2
missionsFrame.BorderSizePixel = 0
missionsFrame.Parent = screenGui

local missionsCorner = Instance.new("UICorner")
missionsCorner.CornerRadius = UDim.new(0, 10)
missionsCorner.Parent = missionsFrame

-- Header with title and level
local missionsHeader = Instance.new("Frame")
missionsHeader.Size = UDim2.new(1, 0, 0, 35)
missionsHeader.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
missionsHeader.BackgroundTransparency = 0.3
missionsHeader.BorderSizePixel = 0
missionsHeader.Parent = missionsFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = missionsHeader

local missionsTitle = Instance.new("TextLabel")
missionsTitle.Size = UDim2.new(0.6, 0, 1, 0)
missionsTitle.Position = UDim2.new(0, 10, 0, 0)
missionsTitle.BackgroundTransparency = 1
missionsTitle.Text = "ACTIVE QUESTS"
missionsTitle.TextColor3 = Color3.fromRGB(255, 215, 100)
missionsTitle.TextXAlignment = Enum.TextXAlignment.Left
missionsTitle.Font = Enum.Font.GothamBold
missionsTitle.TextSize = 14
missionsTitle.Parent = missionsHeader

local levelLabel = Instance.new("TextLabel")
levelLabel.Name = "Level"
levelLabel.Size = UDim2.new(0.4, -10, 1, 0)
levelLabel.Position = UDim2.new(0.6, 0, 0, 0)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "Lv.1 | 0 XP"
levelLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
levelLabel.TextXAlignment = Enum.TextXAlignment.Right
levelLabel.Font = Enum.Font.GothamBold
levelLabel.TextSize = 12
levelLabel.Parent = missionsHeader

-- Scrolling frame for missions
local missionsScroll = Instance.new("ScrollingFrame")
missionsScroll.Name = "MissionsScroll"
missionsScroll.Size = UDim2.new(1, -10, 1, -45)
missionsScroll.Position = UDim2.new(0, 5, 0, 40)
missionsScroll.BackgroundTransparency = 1
missionsScroll.BorderSizePixel = 0
missionsScroll.ScrollBarThickness = 4
missionsScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
missionsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
missionsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
missionsScroll.Parent = missionsFrame

local missionsLayout = Instance.new("UIListLayout")
missionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
missionsLayout.Padding = UDim.new(0, 8)
missionsLayout.Parent = missionsScroll

-- Category colors
local CATEGORY_COLORS = {
	main = Color3.fromRGB(255, 200, 80),    -- Gold for main quests
	side = Color3.fromRGB(100, 180, 255),   -- Blue for side quests
	daily = Color3.fromRGB(150, 255, 150),  -- Green for daily
	exploration = Color3.fromRGB(200, 150, 255), -- Purple for exploration
}

-- Create a mission entry
local function createMissionEntry(missionId: string, missionData: any): Frame
	local categoryColor = CATEGORY_COLORS[missionData.category] or Color3.fromRGB(200, 200, 200)

	local entry = Instance.new("Frame")
	entry.Name = missionId
	entry.Size = UDim2.new(1, -10, 0, 0)
	entry.AutomaticSize = Enum.AutomaticSize.Y
	entry.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	entry.BackgroundTransparency = 0.4
	entry.BorderSizePixel = 0

	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 6)
	entryCorner.Parent = entry

	-- Category indicator bar
	local categoryBar = Instance.new("Frame")
	categoryBar.Size = UDim2.new(0, 3, 1, 0)
	categoryBar.BackgroundColor3 = categoryColor
	categoryBar.BorderSizePixel = 0
	categoryBar.Parent = entry

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 3)
	barCorner.Parent = categoryBar

	-- Mission title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -15, 0, 20)
	title.Position = UDim2.new(0, 10, 0, 4)
	title.BackgroundTransparency = 1
	title.Text = missionData.title
	title.TextColor3 = categoryColor
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 12
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = entry

	-- Objectives container
	local objectivesContainer = Instance.new("Frame")
	objectivesContainer.Name = "Objectives"
	objectivesContainer.Size = UDim2.new(1, -15, 0, 0)
	objectivesContainer.Position = UDim2.new(0, 10, 0, 24)
	objectivesContainer.AutomaticSize = Enum.AutomaticSize.Y
	objectivesContainer.BackgroundTransparency = 1
	objectivesContainer.Parent = entry

	local objLayout = Instance.new("UIListLayout")
	objLayout.SortOrder = Enum.SortOrder.LayoutOrder
	objLayout.Padding = UDim.new(0, 2)
	objLayout.Parent = objectivesContainer

	-- Create objective entries
	for i, obj in missionData.objectives do
		local objFrame = Instance.new("Frame")
		objFrame.Name = "Obj" .. i
		objFrame.Size = UDim2.new(1, 0, 0, 18)
		objFrame.BackgroundTransparency = 1
		objFrame.LayoutOrder = i
		objFrame.Parent = objectivesContainer

		-- Checkbox/indicator
		local checkbox = Instance.new("TextLabel")
		checkbox.Size = UDim2.new(0, 14, 0, 14)
		checkbox.Position = UDim2.new(0, 0, 0, 2)
		checkbox.BackgroundTransparency = 1
		checkbox.Text = obj.complete and "✓" or "○"
		checkbox.TextColor3 = obj.complete and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(150, 150, 150)
		checkbox.Font = Enum.Font.GothamBold
		checkbox.TextSize = 12
		checkbox.Parent = objFrame

		-- Objective text with progress
		local progressText = ""
		if obj.required > 1 then
			progressText = " (" .. obj.current .. "/" .. obj.required .. ")"
		end

		local objLabel = Instance.new("TextLabel")
		objLabel.Size = UDim2.new(1, -18, 1, 0)
		objLabel.Position = UDim2.new(0, 18, 0, 0)
		objLabel.BackgroundTransparency = 1
		objLabel.Text = obj.description .. progressText
		objLabel.TextColor3 = obj.complete and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(180, 180, 180)
		objLabel.TextXAlignment = Enum.TextXAlignment.Left
		objLabel.Font = Enum.Font.Gotham
		objLabel.TextSize = 11
		objLabel.TextTruncate = Enum.TextTruncate.AtEnd
		objLabel.Parent = objFrame

		-- Progress bar for multi-step objectives
		if obj.required > 1 and not obj.complete then
			local progressBg = Instance.new("Frame")
			progressBg.Size = UDim2.new(1, -18, 0, 3)
			progressBg.Position = UDim2.new(0, 18, 1, -4)
			progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			progressBg.BorderSizePixel = 0
			progressBg.Parent = objFrame

			local progressFill = Instance.new("Frame")
			progressFill.Size = UDim2.new(math.min(1, obj.current / obj.required), 0, 1, 0)
			progressFill.BackgroundColor3 = categoryColor
			progressFill.BorderSizePixel = 0
			progressFill.Parent = progressBg

			objFrame.Size = UDim2.new(1, 0, 0, 22) -- Slightly taller for progress bar
		end
	end

	-- Padding at bottom
	local padding = Instance.new("UIPadding")
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = entry

	return entry
end

-- Update missions UI
local function updateMissionsUI(missionData: any)
	-- Clear existing entries
	for _, child in missionsScroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Update level display
	if missionData.level and missionData.experience then
		levelLabel.Text = "Lv." .. missionData.level .. " | " .. missionData.experience .. " XP"
	end

	-- Sort missions by category (main first, then side, then daily)
	local sortOrder = { main = 1, side = 2, daily = 3, exploration = 4 }
	local sortedMissions = {}

	for id, mission in missionData.missions do
		table.insert(sortedMissions, { id = id, data = mission, order = sortOrder[mission.category] or 5 })
	end

	table.sort(sortedMissions, function(a, b)
		return a.order < b.order
	end)

	-- Create entries
	for i, mission in sortedMissions do
		local entry = createMissionEntry(mission.id, mission.data)
		entry.LayoutOrder = i
		entry.Parent = missionsScroll
	end
end

-- Legacy objectives panel (rescue signal - compact)
local objectivesFrame = Instance.new("Frame")
objectivesFrame.Name = "RescueObjectives"
objectivesFrame.Size = UDim2.new(0, 280, 0, 60)
objectivesFrame.Position = UDim2.new(1, -290, 0, 320)
objectivesFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 25)
objectivesFrame.BackgroundTransparency = 0.2
objectivesFrame.BorderSizePixel = 0
objectivesFrame.Parent = screenGui

local objectivesCorner = Instance.new("UICorner")
objectivesCorner.CornerRadius = UDim.new(0, 8)
objectivesCorner.Parent = objectivesFrame

local rescueTitle = Instance.new("TextLabel")
rescueTitle.Size = UDim2.new(1, 0, 0, 18)
rescueTitle.BackgroundTransparency = 1
rescueTitle.Text = "🚨 RESCUE BEACON"
rescueTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
rescueTitle.Font = Enum.Font.GothamBold
rescueTitle.TextSize = 11
rescueTitle.Parent = objectivesFrame

local signalPartsLabel = Instance.new("TextLabel")
signalPartsLabel.Name = "SignalParts"
signalPartsLabel.Size = UDim2.new(0.5, -5, 0, 16)
signalPartsLabel.Position = UDim2.new(0, 8, 0, 20)
signalPartsLabel.BackgroundTransparency = 1
signalPartsLabel.Text = "Parts: 0/3"
signalPartsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
signalPartsLabel.TextXAlignment = Enum.TextXAlignment.Left
signalPartsLabel.Font = Enum.Font.Gotham
signalPartsLabel.TextSize = 11
signalPartsLabel.Parent = objectivesFrame

local nightsLabel = Instance.new("TextLabel")
nightsLabel.Name = "Nights"
nightsLabel.Size = UDim2.new(0.5, -5, 0, 16)
nightsLabel.Position = UDim2.new(0.5, 0, 0, 20)
nightsLabel.BackgroundTransparency = 1
nightsLabel.Text = "Nights: 0/5"
nightsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
nightsLabel.TextXAlignment = Enum.TextXAlignment.Left
nightsLabel.Font = Enum.Font.Gotham
nightsLabel.TextSize = 11
nightsLabel.Parent = objectivesFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.new(1, -16, 0, 16)
statusLabel.Position = UDim2.new(0, 8, 0, 38)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Find signal parts!"
statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 11
statusLabel.Parent = objectivesFrame

-- Major announcement (game win, rescue, etc)
local majorAnnouncement = Instance.new("TextLabel")
majorAnnouncement.Name = "MajorAnnouncement"
majorAnnouncement.Size = UDim2.new(1, 0, 0, 100)
majorAnnouncement.Position = UDim2.new(0, 0, 0.4, 0)
majorAnnouncement.BackgroundTransparency = 1
majorAnnouncement.Text = ""
majorAnnouncement.TextColor3 = Color3.fromRGB(50, 255, 100)
majorAnnouncement.TextStrokeTransparency = 0
majorAnnouncement.TextStrokeColor3 = Color3.new(0, 0, 0)
majorAnnouncement.Font = Enum.Font.GothamBlack
majorAnnouncement.TextSize = 36
majorAnnouncement.TextTransparency = 1
majorAnnouncement.Parent = screenGui

-- Gold display (bottom left, above inventory)
local goldFrame = Instance.new("Frame")
goldFrame.Name = "GoldDisplay"
goldFrame.Size = UDim2.new(0, 100, 0, 30)
goldFrame.Position = UDim2.new(0, 10, 1, -155)
goldFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 15)
goldFrame.BackgroundTransparency = 0.3
goldFrame.BorderSizePixel = 0
goldFrame.Parent = screenGui

local goldCorner = Instance.new("UICorner")
goldCorner.CornerRadius = UDim.new(0, 6)
goldCorner.Parent = goldFrame

local goldIcon = Instance.new("TextLabel")
goldIcon.Size = UDim2.new(0, 25, 1, 0)
goldIcon.BackgroundTransparency = 1
goldIcon.Text = "G"
goldIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
goldIcon.Font = Enum.Font.GothamBlack
goldIcon.TextSize = 18
goldIcon.Parent = goldFrame

local goldAmount = Instance.new("TextLabel")
goldAmount.Name = "Amount"
goldAmount.Size = UDim2.new(1, -30, 1, 0)
goldAmount.Position = UDim2.new(0, 28, 0, 0)
goldAmount.BackgroundTransparency = 1
goldAmount.Text = "100"
goldAmount.TextColor3 = Color3.fromRGB(255, 215, 0)
goldAmount.TextXAlignment = Enum.TextXAlignment.Left
goldAmount.Font = Enum.Font.GothamBold
goldAmount.TextSize = 16
goldAmount.Parent = goldFrame

-- ==========================================
-- SHOP UI
-- ==========================================

local shopVisible = false
local currentMerchantType = ""
local currentShopItems = {}
local playerGold = 100
local playerInventory = {}

-- Shop container (centered, hidden by default)
local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopUI"
shopFrame.Size = UDim2.new(0, 500, 0, 400)
shopFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
shopFrame.BackgroundColor3 = Color3.fromRGB(25, 20, 30)
shopFrame.BackgroundTransparency = 0.1
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.Parent = screenGui

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 12)
shopCorner.Parent = shopFrame

-- Shop header
local shopHeader = Instance.new("Frame")
shopHeader.Size = UDim2.new(1, 0, 0, 50)
shopHeader.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
shopHeader.BackgroundTransparency = 0.3
shopHeader.BorderSizePixel = 0
shopHeader.Parent = shopFrame

local shopHeaderCorner = Instance.new("UICorner")
shopHeaderCorner.CornerRadius = UDim.new(0, 12)
shopHeaderCorner.Parent = shopHeader

local shopTitle = Instance.new("TextLabel")
shopTitle.Name = "Title"
shopTitle.Size = UDim2.new(0.7, 0, 1, 0)
shopTitle.Position = UDim2.new(0, 15, 0, 0)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "MERCHANT"
shopTitle.TextColor3 = Color3.fromRGB(255, 215, 100)
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.Font = Enum.Font.GothamBold
shopTitle.TextSize = 20
shopTitle.Parent = shopHeader

local shopGold = Instance.new("TextLabel")
shopGold.Name = "Gold"
shopGold.Size = UDim2.new(0.25, 0, 1, 0)
shopGold.Position = UDim2.new(0.7, 0, 0, 0)
shopGold.BackgroundTransparency = 1
shopGold.Text = "G 100"
shopGold.TextColor3 = Color3.fromRGB(255, 215, 0)
shopGold.TextXAlignment = Enum.TextXAlignment.Right
shopGold.Font = Enum.Font.GothamBold
shopGold.TextSize = 18
shopGold.Parent = shopHeader

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -45, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.Parent = shopHeader

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Greeting text
local greetingLabel = Instance.new("TextLabel")
greetingLabel.Name = "Greeting"
greetingLabel.Size = UDim2.new(1, -20, 0, 30)
greetingLabel.Position = UDim2.new(0, 10, 0, 55)
greetingLabel.BackgroundTransparency = 1
greetingLabel.Text = "Welcome, traveler!"
greetingLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
greetingLabel.Font = Enum.Font.GothamMedium
greetingLabel.TextSize = 14
greetingLabel.TextXAlignment = Enum.TextXAlignment.Left
greetingLabel.Parent = shopFrame

-- Tab buttons
local buyTab = Instance.new("TextButton")
buyTab.Name = "BuyTab"
buyTab.Size = UDim2.new(0.5, -5, 0, 35)
buyTab.Position = UDim2.new(0, 10, 0, 90)
buyTab.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
buyTab.Text = "BUY"
buyTab.TextColor3 = Color3.new(1, 1, 1)
buyTab.Font = Enum.Font.GothamBold
buyTab.TextSize = 14
buyTab.Parent = shopFrame

local buyTabCorner = Instance.new("UICorner")
buyTabCorner.CornerRadius = UDim.new(0, 6)
buyTabCorner.Parent = buyTab

local sellTab = Instance.new("TextButton")
sellTab.Name = "SellTab"
sellTab.Size = UDim2.new(0.5, -15, 0, 35)
sellTab.Position = UDim2.new(0.5, 5, 0, 90)
sellTab.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
sellTab.Text = "SELL"
sellTab.TextColor3 = Color3.fromRGB(180, 180, 180)
sellTab.Font = Enum.Font.GothamBold
sellTab.TextSize = 14
sellTab.Parent = shopFrame

local sellTabCorner = Instance.new("UICorner")
sellTabCorner.CornerRadius = UDim.new(0, 6)
sellTabCorner.Parent = sellTab

-- Items scroll frame
local itemsScroll = Instance.new("ScrollingFrame")
itemsScroll.Name = "ItemsScroll"
itemsScroll.Size = UDim2.new(1, -20, 1, -145)
itemsScroll.Position = UDim2.new(0, 10, 0, 135)
itemsScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
itemsScroll.BackgroundTransparency = 0.5
itemsScroll.BorderSizePixel = 0
itemsScroll.ScrollBarThickness = 6
itemsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
itemsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
itemsScroll.Parent = shopFrame

local itemsScrollCorner = Instance.new("UICorner")
itemsScrollCorner.CornerRadius = UDim.new(0, 6)
itemsScrollCorner.Parent = itemsScroll

local itemsLayout = Instance.new("UIListLayout")
itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
itemsLayout.Padding = UDim.new(0, 5)
itemsLayout.Parent = itemsScroll

local itemsPadding = Instance.new("UIPadding")
itemsPadding.PaddingTop = UDim.new(0, 5)
itemsPadding.PaddingLeft = UDim.new(0, 5)
itemsPadding.PaddingRight = UDim.new(0, 5)
itemsPadding.Parent = itemsScroll

-- Shop state
local currentTab = "buy"

-- Create item entry for shop
local function createShopItem(itemId: string, itemData: any, isBuying: boolean): Frame
	local entry = Instance.new("Frame")
	entry.Name = itemId
	entry.Size = UDim2.new(1, -10, 0, 60)
	entry.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	entry.BackgroundTransparency = 0.3
	entry.BorderSizePixel = 0

	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 6)
	entryCorner.Parent = entry

	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 0, 25)
	nameLabel.Position = UDim2.new(0, 10, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = itemData.name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.Parent = entry

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.65, 0, 0, 20)
	descLabel.Position = UDim2.new(0, 10, 0, 28)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = itemData.description
	descLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 11
	descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	descLabel.Parent = entry

	-- Price
	local price = isBuying and itemData.buyPrice or itemData.sellPrice
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0, 80, 0, 25)
	priceLabel.Position = UDim2.new(0.55, 0, 0, 18)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "G " .. price
	priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextSize = 16
	priceLabel.Parent = entry

	-- Quantity (for selling, show owned)
	if not isBuying and itemData.quantity then
		local qtyLabel = Instance.new("TextLabel")
		qtyLabel.Size = UDim2.new(0, 60, 0, 20)
		qtyLabel.Position = UDim2.new(0.55, 0, 0, 38)
		qtyLabel.BackgroundTransparency = 1
		qtyLabel.Text = "Own: " .. itemData.quantity
		qtyLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
		qtyLabel.Font = Enum.Font.Gotham
		qtyLabel.TextSize = 11
		qtyLabel.Parent = entry
	end

	-- Buy/Sell button
	local actionButton = Instance.new("TextButton")
	actionButton.Size = UDim2.new(0, 70, 0, 35)
	actionButton.Position = UDim2.new(1, -80, 0.5, -17)
	actionButton.BackgroundColor3 = isBuying and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(120, 80, 60)
	actionButton.Text = isBuying and "BUY" or "SELL"
	actionButton.TextColor3 = Color3.new(1, 1, 1)
	actionButton.Font = Enum.Font.GothamBold
	actionButton.TextSize = 14
	actionButton.Parent = entry

	local actionCorner = Instance.new("UICorner")
	actionCorner.CornerRadius = UDim.new(0, 6)
	actionCorner.Parent = actionButton

	-- Action handler
	actionButton.MouseButton1Click:Connect(function()
		TradingRemote:FireServer(isBuying and "BUY" or "SELL", {
			merchantType = currentMerchantType,
			itemId = itemId,
			quantity = 1,
		})
	end)

	return entry
end

-- Populate shop items
local function populateShop()
	-- Clear existing
	for _, child in itemsScroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	if currentTab == "buy" then
		-- Show merchant's items
		local i = 0
		for itemId, itemData in currentShopItems do
			local entry = createShopItem(itemId, itemData, true)
			entry.LayoutOrder = i
			entry.Parent = itemsScroll
			i += 1
		end
	else
		-- Show player's items for selling
		for itemId, itemData in playerInventory do
			if itemData.quantity > 0 then
				local entry = createShopItem(itemId, itemData, false)
				entry.Parent = itemsScroll
			end
		end
	end
end

-- Toggle shop visibility
local function toggleShop(show: boolean)
	shopVisible = show
	shopFrame.Visible = show
end

-- Tab switching
buyTab.MouseButton1Click:Connect(function()
	currentTab = "buy"
	buyTab.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
	buyTab.TextColor3 = Color3.new(1, 1, 1)
	sellTab.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	sellTab.TextColor3 = Color3.fromRGB(180, 180, 180)
	populateShop()
end)

sellTab.MouseButton1Click:Connect(function()
	currentTab = "sell"
	sellTab.BackgroundColor3 = Color3.fromRGB(120, 80, 60)
	sellTab.TextColor3 = Color3.new(1, 1, 1)
	buyTab.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	buyTab.TextColor3 = Color3.fromRGB(180, 180, 180)
	populateShop()
end)

closeButton.MouseButton1Click:Connect(function()
	toggleShop(false)
end)

-- Merchant proximity hint
local merchantHint = Instance.new("TextLabel")
merchantHint.Name = "MerchantHint"
merchantHint.Size = UDim2.new(0, 250, 0, 40)
merchantHint.Position = UDim2.new(0.5, -125, 0.8, 0)
merchantHint.BackgroundColor3 = Color3.fromRGB(30, 25, 40)
merchantHint.BackgroundTransparency = 0.3
merchantHint.Text = "Press E to trade"
merchantHint.TextColor3 = Color3.fromRGB(255, 215, 100)
merchantHint.Font = Enum.Font.GothamBold
merchantHint.TextSize = 16
merchantHint.Visible = false
merchantHint.Parent = screenGui

local hintCorner = Instance.new("UICorner")
hintCorner.CornerRadius = UDim.new(0, 8)
hintCorner.Parent = merchantHint

-- Track stats locally
local currentStamina = Config.MAX_STAMINA
local currentHunger = Config.MAX_HUNGER
local inventory = { food = 0, batteries = 0, wood = 0 }

-- Show collection notification
local function showCollectNotification(resourceType: string, itemName: string)
	collectNotification.Text = "+ " .. itemName
	collectNotification.TextTransparency = 0

	local tween = TweenService:Create(collectNotification, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {
		TextTransparency = 1,
	})
	task.delay(0.5, function()
		tween:Play()
	end)
end

-- Handle inventory updates from server
UpdateInventoryRemote.OnClientEvent:Connect(function(newInventory: { food: number, batteries: number, wood: number })
	inventory = newInventory
	foodLabel.Text = "[1] Food: " .. inventory.food
	batteryLabel.Text = "[2] Batteries: " .. inventory.batteries
	woodLabel.Text = "[3] Wood: " .. inventory.wood
end)

-- Handle collection notification
CollectResourceRemote.OnClientEvent:Connect(function(resourceType: string, itemName: string)
	showCollectNotification(resourceType, itemName)
end)

-- Input handling for using items
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.One then
		-- Eat food
		if inventory.food > 0 then
			currentHunger = math.min(Config.MAX_HUNGER, currentHunger + 30)
			CollectResourceRemote:FireServer("USE", "FOOD")
		end
	elseif input.KeyCode == Enum.KeyCode.Two then
		-- Use battery (extends flashlight)
		if inventory.batteries > 0 then
			CollectResourceRemote:FireServer("USE", "BATTERY")
		end
	elseif input.KeyCode == Enum.KeyCode.Three then
		-- Use wood (at campfire)
		if inventory.wood > 0 then
			CollectResourceRemote:FireServer("USE", "WOOD")
		end
	end
end)

-- Show major announcement
local function showAnnouncement(text: string, color: Color3)
	majorAnnouncement.Text = text
	majorAnnouncement.TextColor3 = color
	majorAnnouncement.TextTransparency = 0

	local tween = TweenService:Create(majorAnnouncement, TweenInfo.new(3, Enum.EasingStyle.Sine), {
		TextTransparency = 1,
	})
	task.delay(2, function()
		tween:Play()
	end)
end

-- Update rescue objectives UI (compact format)
local function updateObjectivesUI(gameState: { nightsSurvived: number, signalPartsCollected: number, rescueSignaled: boolean, gameWon: boolean })
	signalPartsLabel.Text = "Parts: " .. gameState.signalPartsCollected .. "/3"
	nightsLabel.Text = "Nights: " .. gameState.nightsSurvived .. "/5"

	-- Update colors based on completion
	signalPartsLabel.TextColor3 = gameState.signalPartsCollected >= 3 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(200, 200, 200)
	nightsLabel.TextColor3 = gameState.nightsSurvived >= 5 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(200, 200, 200)

	-- Update status
	if gameState.gameWon then
		statusLabel.Text = "RESCUED!"
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	elseif gameState.rescueSignaled then
		statusLabel.Text = "Survive! Help coming!"
		statusLabel.TextColor3 = Color3.fromRGB(50, 200, 255)
	elseif gameState.signalPartsCollected >= 3 and gameState.nightsSurvived >= 5 then
		statusLabel.Text = "Go to beacon!"
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	elseif gameState.signalPartsCollected >= 3 then
		statusLabel.Text = "Survive more nights!"
		statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	else
		statusLabel.Text = "Find signal parts!"
		statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	end
end

-- Handle objective updates
ObjectiveUpdateRemote.OnClientEvent:Connect(function(eventType: string, gameState: any)
	updateObjectivesUI(gameState)

	if eventType == "PART_COLLECTED" then
		showAnnouncement("SIGNAL PART COLLECTED!\n" .. gameState.signalPartsCollected .. "/3", Color3.fromRGB(50, 200, 255))
	elseif eventType == "NIGHT_SURVIVED" then
		showAnnouncement("NIGHT SURVIVED!\n" .. gameState.nightsSurvived .. " nights", Color3.fromRGB(255, 200, 100))
	elseif eventType == "RESCUE_SIGNALED" then
		showAnnouncement("RESCUE SIGNALED!\nSurvive 60 more seconds!", Color3.fromRGB(50, 255, 100))
	elseif eventType == "GAME_WON" then
		showAnnouncement("RESCUE ARRIVED!\nYOU SURVIVED!", Color3.fromRGB(100, 255, 100))
	end
end)

-- Handle time updates
TimeUpdateRemote.OnClientEvent:Connect(function(data: { state: string, dayCount: number, isNight: boolean })
	timeDisplay.Text = "Day " .. data.dayCount .. " - " .. data.state

	if data.isNight then
		timeDisplay.TextColor3 = Color3.fromRGB(255, 100, 100)

		-- Show warning
		nightWarning.TextTransparency = 0
		local tween = TweenService:Create(nightWarning, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			TextTransparency = 1,
		})
		task.delay(1, function()
			tween:Play()
		end)
	else
		timeDisplay.TextColor3 = Color3.new(1, 1, 1)
	end
end)

-- Hunger drain timer
local lastHungerDrain = tick()

-- Update stamina and hunger display
RunService.Heartbeat:Connect(function()
	local dt = 0.016 -- approximate frame time
	local now = tick()

	-- Get stamina from character (simplified - in real game would use attributes)
	local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Estimate stamina based on walk speed
		local isSprinting = humanoid.WalkSpeed > Config.WALK_SPEED
		if isSprinting then
			currentStamina = math.max(0, currentStamina - Config.STAMINA_DRAIN * dt)
		else
			currentStamina = math.min(Config.MAX_STAMINA, currentStamina + Config.STAMINA_REGEN * dt)
		end

		local staminaPercent = currentStamina / Config.MAX_STAMINA
		staminaFill.Size = UDim2.new(staminaPercent, -4, 1, -4)

		-- Hunger drain (every minute loses 1 hunger point, but we check every second)
		if now - lastHungerDrain > 1 then
			lastHungerDrain = now
			currentHunger = math.max(0, currentHunger - Config.HUNGER_DRAIN / 60)

			-- Starving damage
			if currentHunger <= 0 then
				humanoid:TakeDamage(Config.HUNGER_DAMAGE * 0.1) -- Small tick damage
			end
		end

		-- Update hunger bar
		local hungerPercent = currentHunger / Config.MAX_HUNGER
		hungerFill.Size = UDim2.new(hungerPercent, -4, 1, -4)

		-- Change hunger bar color based on level
		if hungerPercent < 0.2 then
			hungerFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Critical
		elseif hungerPercent < 0.5 then
			hungerFill.BackgroundColor3 = Color3.fromRGB(255, 150, 50) -- Warning
		else
			hungerFill.BackgroundColor3 = Color3.fromRGB(255, 180, 100) -- Normal
		end
	end
end)

-- ==========================================
-- TRADING SYSTEM EVENT HANDLERS
-- ==========================================

local nearMerchant = false
local pendingShopData: any = nil

-- Handle trading events
TradingRemote.OnClientEvent:Connect(function(eventType: string, data: any)
	if eventType == "INVENTORY_UPDATE" then
		playerGold = data.gold
		playerInventory = data.inventory or {}
		goldAmount.Text = tostring(playerGold)
		shopGold.Text = "G " .. playerGold

		-- Refresh shop if open
		if shopVisible then
			populateShop()
		end
	elseif eventType == "TRADE_RESULT" then
		if data.success then
			showCollectNotification("trade", data.message)
		else
			showAnnouncement(data.message, Color3.fromRGB(255, 100, 100))
		end
	elseif eventType == "GOLD_EARNED" then
		showCollectNotification("gold", "+" .. data.amount .. " Gold")
	end
end)

-- Handle shop proximity
OpenShopRemote.OnClientEvent:Connect(function(eventType: string, data: any)
	if eventType == "NEAR_MERCHANT" then
		nearMerchant = true
		pendingShopData = data
		merchantHint.Text = "Press E to trade with " .. data.merchantName
		merchantHint.Visible = true
	end
end)

-- E key to open shop
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.E then
		if nearMerchant and pendingShopData and not shopVisible then
			-- Open shop
			currentMerchantType = pendingShopData.merchantType
			currentShopItems = pendingShopData.items or {}
			shopTitle.Text = pendingShopData.merchantName
			greetingLabel.Text = pendingShopData.greeting
			shopGold.Text = "G " .. playerGold
			currentTab = "buy"
			buyTab.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
			buyTab.TextColor3 = Color3.new(1, 1, 1)
			sellTab.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			sellTab.TextColor3 = Color3.fromRGB(180, 180, 180)
			populateShop()
			toggleShop(true)
			merchantHint.Visible = false
		elseif shopVisible then
			toggleShop(false)
		end
	end
end)

-- Clear merchant hint when moving away
RunService.Heartbeat:Connect(function()
	-- Reset nearMerchant flag each frame, server will set it again if still near
	if not shopVisible then
		nearMerchant = false
		merchantHint.Visible = false
	end
end)

-- ==========================================
-- MISSION SYSTEM EVENT HANDLERS
-- ==========================================

-- Handle mission updates from server
MissionUpdateRemote.OnClientEvent:Connect(function(eventType: string, data: any)
	if eventType == "UPDATE" then
		updateMissionsUI(data)
	elseif eventType == "NEW_MISSION" then
		-- Show notification for new mission
		showAnnouncement("NEW QUEST!\n" .. data, Color3.fromRGB(255, 215, 100))
	end
end)

-- Handle mission completion events
MissionCompleteRemote.OnClientEvent:Connect(function(eventType: string, data: any)
	if eventType == "COMPLETE" then
		-- Show completion notification
		local text = "QUEST COMPLETE!\n" .. data.title .. "\n+" .. data.experience .. " XP"
		showAnnouncement(text, Color3.fromRGB(100, 255, 100))

		-- Show item rewards if any
		if data.items and #data.items > 0 then
			task.delay(2.5, function()
				local itemText = "REWARDS:\n" .. table.concat(data.items, ", ")
				showAnnouncement(itemText, Color3.fromRGB(255, 200, 100))
			end)
		end
	elseif eventType == "LEVEL_UP" then
		-- Epic level up notification
		showAnnouncement("LEVEL UP!\nYou are now level " .. data, Color3.fromRGB(255, 215, 100))
	end
end)

print("[UI] Mertin-Flemmer UI ready! Survive the night, find food, stay in the light.")
