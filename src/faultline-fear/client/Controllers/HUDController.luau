--!strict
-- Faultline Fear: HUD Controller
-- Manages all HUD elements and updates
-- Responsive design: adapts to Small/Medium/Large screens
-- Toggle: Tab key (desktop), long-press 1s (touch), or button

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config
local InputService = Shared.InputService

local HUDController = {}

-- State
local isVisible: boolean = true
local isExpanded: boolean = false -- For expand button on small screens
local currentScreenSize: "Small" | "Medium" | "Large" = "Large"
local screenGui: ScreenGui = nil :: any
local elements: { [string]: GuiObject } = {}

-- Touch long-press tracking
local touchStartTime: number = 0
local touchStartPosition: Vector2? = nil
local LONG_PRESS_DURATION = 1.0 -- 1 second
local TOUCH_MOVE_THRESHOLD = 20 -- pixels - cancel long-press if moved

-- Current data (stored for future getter functions)
local _currentHunger = { current = 100, max = 100 }
local _currentTime = { clockTime = 8, period = "Day" :: string, isDangerous = false }
local _currentObjective = { text = "Explore the area", step = 1, total = 1 }
local currentProgress = { generatorParts = 0, survivors = 0 }

-- ==========================================
-- UI CREATION HELPERS
-- ==========================================

local function createBar(parent: Frame, name: string, color: Color3, yPosition: number): Frame
	local container = Instance.new("Frame")
	container.Name = name .. "Container"
	container.Size = UDim2.new(0, 200, 0, 20)
	container.Position = UDim2.new(0, 20, 0, yPosition)
	container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	container.BorderSizePixel = 0
	container.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = container

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = container

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 12
	label.Font = Enum.Font.GothamBold
	label.Text = name
	label.Parent = container

	return container
end

local function createTextLabel(
	parent: Frame,
	name: string,
	position: UDim2,
	size: UDim2,
	alignment: Enum.TextXAlignment
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 14
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = alignment
	label.TextStrokeTransparency = 0.5
	label.Parent = parent
	return label
end

-- ==========================================
-- HUD CREATION
-- ==========================================

function HUDController:CreateHUD()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Main ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FaultlineFearHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Main container
	local container = Instance.new("Frame")
	container.Name = "HUDContainer"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = screenGui
	elements.container = container

	-- ========== TOP LEFT: Status Bars ==========
	local statusBars = Instance.new("Frame")
	statusBars.Name = "StatusBars"
	statusBars.Size = UDim2.new(0, 240, 0, 100)
	statusBars.Position = UDim2.new(0, 0, 0, 0)
	statusBars.BackgroundTransparency = 1
	statusBars.Parent = container

	elements.hungerBar = createBar(statusBars, "Hunger", Color3.fromRGB(255, 165, 0), 20)
	elements.staminaBar = createBar(statusBars, "Stamina", Color3.fromRGB(0, 150, 255), 50)
	elements.healthBar = createBar(statusBars, "Health", Color3.fromRGB(255, 50, 50), 80)

	-- ========== TOP CENTER: Zone & Time ==========
	local topCenter = Instance.new("Frame")
	topCenter.Name = "TopCenter"
	topCenter.Size = UDim2.new(0, 300, 0, 60)
	topCenter.Position = UDim2.new(0.5, -150, 0, 10)
	topCenter.BackgroundTransparency = 1
	topCenter.Parent = container

	elements.zoneName = createTextLabel(
		topCenter,
		"ZoneName",
		UDim2.new(0, 0, 0, 0),
		UDim2.new(1, 0, 0, 24),
		Enum.TextXAlignment.Center
	)
	elements.zoneName.TextSize = 18
	elements.zoneName.Font = Enum.Font.GothamBold
	elements.zoneName.Text = "Valley"

	elements.timeDisplay = createTextLabel(
		topCenter,
		"TimeDisplay",
		UDim2.new(0, 0, 0, 28),
		UDim2.new(1, 0, 0, 20),
		Enum.TextXAlignment.Center
	)
	elements.timeDisplay.TextSize = 14
	elements.timeDisplay.Text = "8:00 AM - Day"

	-- Time icon (sun/moon)
	local timeIcon = Instance.new("TextLabel")
	timeIcon.Name = "TimeIcon"
	timeIcon.Size = UDim2.new(0, 24, 0, 24)
	timeIcon.Position = UDim2.new(0.5, -80, 0, 26)
	timeIcon.BackgroundTransparency = 1
	timeIcon.TextSize = 20
	timeIcon.Text = "☀️"
	timeIcon.Parent = topCenter
	elements.timeIcon = timeIcon

	-- ========== BOTTOM LEFT: Objective ==========
	local bottomLeft = Instance.new("Frame")
	bottomLeft.Name = "BottomLeft"
	bottomLeft.Size = UDim2.new(0, 350, 0, 80)
	bottomLeft.Position = UDim2.new(0, 20, 1, -100)
	bottomLeft.BackgroundTransparency = 1
	bottomLeft.Parent = container

	elements.objectiveTitle = createTextLabel(
		bottomLeft,
		"ObjectiveTitle",
		UDim2.new(0, 0, 0, 0),
		UDim2.new(1, 0, 0, 20),
		Enum.TextXAlignment.Left
	)
	elements.objectiveTitle.TextSize = 12
	elements.objectiveTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	elements.objectiveTitle.Text = "CURRENT OBJECTIVE"

	elements.objectiveText = createTextLabel(
		bottomLeft,
		"ObjectiveText",
		UDim2.new(0, 0, 0, 22),
		UDim2.new(1, 0, 0, 30),
		Enum.TextXAlignment.Left
	)
	elements.objectiveText.TextSize = 16
	elements.objectiveText.Font = Enum.Font.GothamBold
	elements.objectiveText.Text = "Explore the area"
	elements.objectiveText.TextWrapped = true

	elements.objectiveStep = createTextLabel(
		bottomLeft,
		"ObjectiveStep",
		UDim2.new(0, 0, 0, 54),
		UDim2.new(1, 0, 0, 16),
		Enum.TextXAlignment.Left
	)
	elements.objectiveStep.TextSize = 11
	elements.objectiveStep.TextColor3 = Color3.fromRGB(150, 150, 150)
	elements.objectiveStep.Text = "Step 1 of 1"

	-- ========== BOTTOM RIGHT: Progress ==========
	local bottomRight = Instance.new("Frame")
	bottomRight.Name = "BottomRight"
	bottomRight.Size = UDim2.new(0, 200, 0, 60)
	bottomRight.Position = UDim2.new(1, -220, 1, -80)
	bottomRight.BackgroundTransparency = 1
	bottomRight.Parent = container

	elements.generatorProgress = createTextLabel(
		bottomRight,
		"GeneratorProgress",
		UDim2.new(0, 0, 0, 0),
		UDim2.new(1, 0, 0, 24),
		Enum.TextXAlignment.Right
	)
	elements.generatorProgress.TextSize = 14
	elements.generatorProgress.Text = "⚙️ Generator Parts: 0/6"

	elements.survivorProgress = createTextLabel(
		bottomRight,
		"SurvivorProgress",
		UDim2.new(0, 0, 0, 26),
		UDim2.new(1, 0, 0, 24),
		Enum.TextXAlignment.Right
	)
	elements.survivorProgress.TextSize = 14
	elements.survivorProgress.Text = "👤 Survivors: 0/10"

	-- ========== CENTER: Warning Overlay ==========
	local warningOverlay = Instance.new("Frame")
	warningOverlay.Name = "WarningOverlay"
	warningOverlay.Size = UDim2.new(1, 0, 1, 0)
	warningOverlay.BackgroundTransparency = 1
	warningOverlay.Visible = false
	warningOverlay.Parent = container
	elements.warningOverlay = warningOverlay

	-- Warning edge glow
	local warningGlow = Instance.new("ImageLabel")
	warningGlow.Name = "WarningGlow"
	warningGlow.Size = UDim2.new(1, 0, 1, 0)
	warningGlow.BackgroundTransparency = 1
	warningGlow.ImageTransparency = 0.5
	warningGlow.ImageColor3 = Color3.fromRGB(255, 100, 0)
	warningGlow.Image = "rbxassetid://1309251850" -- Radial gradient
	warningGlow.Parent = warningOverlay
	elements.warningGlow = warningGlow

	local warningText = Instance.new("TextLabel")
	warningText.Name = "WarningText"
	warningText.Size = UDim2.new(1, 0, 0, 50)
	warningText.Position = UDim2.new(0, 0, 0.3, 0)
	warningText.BackgroundTransparency = 1
	warningText.TextColor3 = Color3.fromRGB(255, 200, 0)
	warningText.TextSize = 32
	warningText.Font = Enum.Font.GothamBold
	warningText.TextStrokeTransparency = 0
	warningText.TextStrokeColor3 = Color3.fromRGB(100, 50, 0)
	warningText.Text = "⚠️ EARTHQUAKE INCOMING ⚠️"
	warningText.Parent = warningOverlay
	elements.warningText = warningText

	-- ========== Interaction Prompt ==========
	local interactPrompt = Instance.new("TextLabel")
	interactPrompt.Name = "InteractPrompt"
	interactPrompt.Size = UDim2.new(0, 300, 0, 40)
	interactPrompt.Position = UDim2.new(0.5, -150, 0.6, 0)
	interactPrompt.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	interactPrompt.BackgroundTransparency = 0.5
	interactPrompt.TextColor3 = Color3.fromRGB(255, 255, 255)
	interactPrompt.TextSize = 16
	interactPrompt.Font = Enum.Font.GothamMedium
	interactPrompt.Text = "Press E to interact"
	interactPrompt.Visible = false
	interactPrompt.Parent = container

	local promptCorner = Instance.new("UICorner")
	promptCorner.CornerRadius = UDim.new(0, 8)
	promptCorner.Parent = interactPrompt

	elements.interactPrompt = interactPrompt

	-- ========== Toggle Button (all sizes, corner) ==========
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.Size = UDim2.new(0, 40, 0, 40)
	toggleButton.Position = UDim2.new(1, -50, 0, 10)
	toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	toggleButton.BackgroundTransparency = 0.3
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.TextSize = 20
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.Text = "👁️"
	toggleButton.Parent = screenGui -- Parent to screenGui, not container (always visible)

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 8)
	toggleCorner.Parent = toggleButton

	toggleButton.MouseButton1Click:Connect(function()
		self:Toggle()
	end)
	elements.toggleButton = toggleButton

	-- ========== Expand Button (small screens only) ==========
	local expandButton = Instance.new("TextButton")
	expandButton.Name = "ExpandButton"
	expandButton.Size = UDim2.new(0, 50, 0, 50)
	expandButton.Position = UDim2.new(1, -70, 1, -70)
	expandButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	expandButton.BackgroundTransparency = 0.2
	expandButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	expandButton.TextSize = 24
	expandButton.Font = Enum.Font.GothamBold
	expandButton.Text = "+"
	expandButton.Visible = false -- Only shown on small screens
	expandButton.Parent = screenGui

	local expandCorner = Instance.new("UICorner")
	expandCorner.CornerRadius = UDim.new(0, 12)
	expandCorner.Parent = expandButton

	expandButton.MouseButton1Click:Connect(function()
		self:ToggleExpand()
	end)
	elements.expandButton = expandButton

	-- ========== Expanded Panel (for small screens) ==========
	local expandedPanel = Instance.new("Frame")
	expandedPanel.Name = "ExpandedPanel"
	expandedPanel.Size = UDim2.new(0, 280, 0, 200)
	expandedPanel.Position = UDim2.new(1, -300, 1, -220)
	expandedPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	expandedPanel.BackgroundTransparency = 0.1
	expandedPanel.Visible = false
	expandedPanel.Parent = container

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = expandedPanel

	-- Expanded panel content
	local expandedSignal = createTextLabel(
		expandedPanel,
		"ExpandedSignal",
		UDim2.new(0, 20, 0, 20),
		UDim2.new(1, -40, 0, 24),
		Enum.TextXAlignment.Left
	)
	expandedSignal.Text = "⚙️ Generator Parts: 0/6"
	elements.expandedGenerator = expandedSignal

	local expandedSurvivors = createTextLabel(
		expandedPanel,
		"ExpandedSurvivors",
		UDim2.new(0, 20, 0, 50),
		UDim2.new(1, -40, 0, 24),
		Enum.TextXAlignment.Left
	)
	expandedSurvivors.Text = "👤 Survivors: 0/10"
	elements.expandedSurvivors = expandedSurvivors

	local expandedTime = createTextLabel(
		expandedPanel,
		"ExpandedTime",
		UDim2.new(0, 20, 0, 80),
		UDim2.new(1, -40, 0, 24),
		Enum.TextXAlignment.Left
	)
	expandedTime.Text = "🕐 8:00 AM - Day"
	elements.expandedTime = expandedTime

	local expandedZone = createTextLabel(
		expandedPanel,
		"ExpandedZone",
		UDim2.new(0, 20, 0, 110),
		UDim2.new(1, -40, 0, 24),
		Enum.TextXAlignment.Left
	)
	expandedZone.Text = "📍 Valley"
	elements.expandedZone = expandedZone

	local closeExpandedButton = Instance.new("TextButton")
	closeExpandedButton.Name = "CloseExpanded"
	closeExpandedButton.Size = UDim2.new(0, 30, 0, 30)
	closeExpandedButton.Position = UDim2.new(1, -40, 0, 10)
	closeExpandedButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	closeExpandedButton.BackgroundTransparency = 0.3
	closeExpandedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeExpandedButton.TextSize = 16
	closeExpandedButton.Font = Enum.Font.GothamBold
	closeExpandedButton.Text = "×"
	closeExpandedButton.Parent = expandedPanel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeExpandedButton

	closeExpandedButton.MouseButton1Click:Connect(function()
		self:ToggleExpand()
	end)

	elements.expandedPanel = expandedPanel

	print("[HUDController] HUD created")
end

-- ==========================================
-- UPDATE FUNCTIONS
-- ==========================================

function HUDController:UpdateBar(barElement: Frame, current: number, max: number)
	local fill = barElement:FindFirstChild("Fill") :: Frame
	if fill then
		local ratio = math.clamp(current / max, 0, 1)
		local tween = TweenService:Create(fill, TweenInfo.new(0.3), { Size = UDim2.new(ratio, 0, 1, 0) })
		tween:Play()
	end
end

function HUDController:UpdateHunger(hungerData: { current: number, max: number, isBlurred: boolean?, isSlow: boolean? })
	_currentHunger = hungerData
	self:UpdateBar(elements.hungerBar :: Frame, hungerData.current, hungerData.max)

	-- Change bar color based on status
	local fill = (elements.hungerBar :: Frame):FindFirstChild("Fill") :: Frame
	if fill then
		if hungerData.current < Config.HUNGER.BLUR_THRESHOLD then
			fill.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Critical - red
		elseif hungerData.current < Config.HUNGER.SLOW_THRESHOLD then
			fill.BackgroundColor3 = Color3.fromRGB(255, 200, 0) -- Warning - yellow
		else
			fill.BackgroundColor3 = Color3.fromRGB(255, 165, 0) -- Normal - orange
		end
	end
end

function HUDController:UpdateTime(timeData: { clockTime: number, period: string, isDangerous: boolean })
	_currentTime = timeData

	-- Format time as HH:MM AM/PM
	local hours = math.floor(timeData.clockTime)
	local minutes = math.floor((timeData.clockTime - hours) * 60)
	local ampm = hours >= 12 and "PM" or "AM"
	local displayHours = hours % 12
	if displayHours == 0 then
		displayHours = 12
	end
	local timeString = string.format("%d:%02d %s - %s", displayHours, minutes, ampm, timeData.period)

	local timeDisplay = elements.timeDisplay :: TextLabel
	timeDisplay.Text = timeString

	-- Update icon
	local timeIcon = elements.timeIcon :: TextLabel
	if timeData.period == "Night" then
		timeIcon.Text = "🌙"
	elseif timeData.period == "Dusk" or timeData.period == "Dawn" then
		timeIcon.Text = "🌅"
	else
		timeIcon.Text = "☀️"
	end

	-- Danger indicator color
	if timeData.isDangerous then
		timeDisplay.TextColor3 = Color3.fromRGB(255, 100, 100)
	else
		timeDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

function HUDController:UpdateObjective(objectiveData: { text: string, step: number, total: number })
	_currentObjective = objectiveData

	local objectiveText = elements.objectiveText :: TextLabel
	objectiveText.Text = objectiveData.text

	local objectiveStep = elements.objectiveStep :: TextLabel
	objectiveStep.Text = string.format("Step %d of %d", objectiveData.step, objectiveData.total)
end

function HUDController:UpdateProgress(progressData: { generatorParts: number?, survivors: number? })
	if progressData.generatorParts then
		currentProgress.generatorParts = progressData.generatorParts
	end
	if progressData.survivors then
		currentProgress.survivors = progressData.survivors
	end

	local generatorProgress = elements.generatorProgress :: TextLabel
	generatorProgress.Text = string.format(
		"⚙️ Generator Parts: %d/%d",
		currentProgress.generatorParts,
		Config.OBJECTIVES.GENERATOR_PARTS_TOTAL
	)

	local survivorProgress = elements.survivorProgress :: TextLabel
	survivorProgress.Text =
		string.format("👤 Survivors: %d/%d", currentProgress.survivors, Config.OBJECTIVES.SURVIVORS_TOTAL)
end

function HUDController:UpdateZone(zoneName: string)
	local zoneLabel = elements.zoneName :: TextLabel
	zoneLabel.Text = zoneName
end

-- ==========================================
-- WARNING OVERLAY
-- ==========================================

function HUDController:ShowEarthquakeWarning(magnitude: number)
	local overlay = elements.warningOverlay :: Frame
	overlay.Visible = true

	-- Pulse effect
	local warningGlow = elements.warningGlow :: ImageLabel
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local tween = TweenService:Create(warningGlow, tweenInfo, { ImageTransparency = 0.2 })
	tween:Play()

	-- Scale text based on magnitude
	local warningText = elements.warningText :: TextLabel
	if magnitude >= 0.9 then
		warningText.Text = "⚠️ MAJOR EARTHQUAKE ⚠️"
		warningText.TextColor3 = Color3.fromRGB(255, 50, 50)
	elseif magnitude >= 0.6 then
		warningText.Text = "⚠️ EARTHQUAKE WARNING ⚠️"
		warningText.TextColor3 = Color3.fromRGB(255, 150, 0)
	else
		warningText.Text = "⚠️ Tremor Detected ⚠️"
		warningText.TextColor3 = Color3.fromRGB(255, 200, 100)
	end
end

function HUDController:HideEarthquakeWarning()
	local overlay = elements.warningOverlay :: Frame
	overlay.Visible = false
end

-- ==========================================
-- INTERACTION PROMPT
-- ==========================================

function HUDController:ShowInteractPrompt(text: string)
	local prompt = elements.interactPrompt :: TextLabel

	-- Adjust text for touch devices
	if InputService:IsTouchDevice() and not InputService:HasPhysicalKeyboard() then
		text = text:gsub("Press E", "Tap")
	end

	prompt.Text = text
	prompt.Visible = true
end

function HUDController:HideInteractPrompt()
	local prompt = elements.interactPrompt :: TextLabel
	prompt.Visible = false
end

-- ==========================================
-- VISIBILITY TOGGLE
-- ==========================================

function HUDController:Toggle()
	isVisible = not isVisible
	local container = elements.container :: Frame

	local targetTransparency = isVisible and 0 or 1
	for _, element in pairs(container:GetDescendants()) do
		if element:IsA("GuiObject") then
			TweenService:Create(element, TweenInfo.new(0.3), {
				BackgroundTransparency = element.BackgroundTransparency == 1 and 1 or targetTransparency,
				TextTransparency = targetTransparency,
				ImageTransparency = targetTransparency,
			}):Play()
		end
	end

	print("[HUDController] HUD visibility:", isVisible)
end

function HUDController:Show()
	if not isVisible then
		self:Toggle()
	end
end

function HUDController:Hide()
	if isVisible then
		self:Toggle()
	end
end

function HUDController:IsVisible(): boolean
	return isVisible
end

-- ==========================================
-- EXPAND PANEL (Small Screens)
-- ==========================================

function HUDController:ToggleExpand()
	isExpanded = not isExpanded

	local expandButton = elements.expandButton :: TextButton
	local expandedPanel = elements.expandedPanel :: Frame

	if isExpanded then
		expandButton.Text = "-"
		expandedPanel.Visible = true

		-- Animate in
		expandedPanel.Position = UDim2.new(1, 0, 1, -220)
		TweenService:Create(expandedPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -300, 1, -220),
		}):Play()

		-- Update expanded panel content
		self:UpdateExpandedPanel()
	else
		expandButton.Text = "+"

		-- Animate out
		local tween = TweenService:Create(expandedPanel, TweenInfo.new(0.2), {
			Position = UDim2.new(1, 0, 1, -220),
		})
		tween:Play()
		tween.Completed:Connect(function()
			if not isExpanded then
				expandedPanel.Visible = false
			end
		end)
	end

	print("[HUDController] Expand panel:", isExpanded)
end

function HUDController:UpdateExpandedPanel()
	-- Update expanded panel with current data
	local expandedGenerator = elements.expandedGenerator :: TextLabel
	local expandedSurvivors = elements.expandedSurvivors :: TextLabel
	local expandedTime = elements.expandedTime :: TextLabel
	local expandedZone = elements.expandedZone :: TextLabel

	expandedGenerator.Text = string.format(
		"⚙️ Generator Parts: %d/%d",
		currentProgress.generatorParts,
		Config.OBJECTIVES.GENERATOR_PARTS_TOTAL
	)
	expandedSurvivors.Text =
		string.format("👤 Survivors: %d/%d", currentProgress.survivors, Config.OBJECTIVES.SURVIVORS_TOTAL)
	expandedTime.Text = string.format("🕐 %s", (elements.timeDisplay :: TextLabel).Text)
	expandedZone.Text = string.format("📍 %s", (elements.zoneName :: TextLabel).Text)
end

-- ==========================================
-- ADAPTIVE LAYOUT
-- ==========================================

function HUDController:ApplyLayout(screenSize: "Small" | "Medium" | "Large")
	currentScreenSize = screenSize
	print("[HUDController] Applying layout for:", screenSize)

	local statusBars = elements.container:FindFirstChild("StatusBars") :: Frame
	local topCenter = elements.container:FindFirstChild("TopCenter") :: Frame
	local bottomLeft = elements.container:FindFirstChild("BottomLeft") :: Frame
	local bottomRight = elements.container:FindFirstChild("BottomRight") :: Frame
	local expandButton = elements.expandButton :: TextButton

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad)

	if screenSize == "Small" then
		-- ========== SMALL SCREEN (Phone) ==========
		-- Compact everything, hide secondary info, show expand button

		-- Status bars: smaller, top left
		TweenService:Create(statusBars, tweenInfo, {
			Size = UDim2.new(0, 120, 0, 60),
		}):Play()

		-- Resize individual bars
		local hungerBar = elements.hungerBar :: Frame
		local staminaBar = elements.staminaBar :: Frame
		local healthBar = elements.healthBar :: Frame

		TweenService:Create(hungerBar, tweenInfo, {
			Size = UDim2.new(0, 100, 0, 14),
			Position = UDim2.new(0, 10, 0, 10),
		}):Play()
		TweenService:Create(staminaBar, tweenInfo, {
			Size = UDim2.new(0, 100, 0, 14),
			Position = UDim2.new(0, 10, 0, 28),
		}):Play()
		TweenService:Create(healthBar, tweenInfo, {
			Size = UDim2.new(0, 100, 0, 14),
			Position = UDim2.new(0, 10, 0, 46),
		}):Play()

		-- Hide labels on small bars
		for _, barName in { "hungerBar", "staminaBar", "healthBar" } do
			local bar = elements[barName] :: Frame
			local label = bar:FindFirstChild("Label") :: TextLabel?
			if label then
				label.Visible = false
			end
		end

		-- Top center: very compact
		TweenService:Create(topCenter, tweenInfo, {
			Size = UDim2.new(0, 150, 0, 30),
			Position = UDim2.new(0.5, -75, 0, 5),
		}):Play()		-- Hide zone name, show only time icon on small
;
		(elements.zoneName :: TextLabel).Visible = false;
		(elements.timeDisplay :: TextLabel).TextSize = 10

		-- Bottom left: compact objective
		TweenService:Create(bottomLeft, tweenInfo, {
			Size = UDim2.new(0, 200, 0, 50),
			Position = UDim2.new(0, 10, 1, -60),
		}):Play();
		(elements.objectiveTitle :: TextLabel).Visible = false;
		(elements.objectiveText :: TextLabel).TextSize = 12;
		(elements.objectiveStep :: TextLabel).Visible = false

		-- Hide bottom right progress (available in expand panel)
		bottomRight.Visible = false

		-- Show expand button
		expandButton.Visible = true
	elseif screenSize == "Medium" then
		-- ========== MEDIUM SCREEN (Tablet) ==========
		-- Moderate sizes, abbreviated labels

		-- Status bars: medium size
		TweenService:Create(statusBars, tweenInfo, {
			Size = UDim2.new(0, 180, 0, 80),
		}):Play()

		local hungerBar = elements.hungerBar :: Frame
		local staminaBar = elements.staminaBar :: Frame
		local healthBar = elements.healthBar :: Frame

		TweenService:Create(hungerBar, tweenInfo, {
			Size = UDim2.new(0, 160, 0, 16),
			Position = UDim2.new(0, 15, 0, 15),
		}):Play()
		TweenService:Create(staminaBar, tweenInfo, {
			Size = UDim2.new(0, 160, 0, 16),
			Position = UDim2.new(0, 15, 0, 36),
		}):Play()
		TweenService:Create(healthBar, tweenInfo, {
			Size = UDim2.new(0, 160, 0, 16),
			Position = UDim2.new(0, 15, 0, 57),
		}):Play()

		-- Show labels but smaller
		for _, barName in { "hungerBar", "staminaBar", "healthBar" } do
			local bar = elements[barName] :: Frame
			local label = bar:FindFirstChild("Label") :: TextLabel?
			if label then
				label.Visible = true
				label.TextSize = 10
			end
		end

		-- Top center: compact
		TweenService:Create(topCenter, tweenInfo, {
			Size = UDim2.new(0, 200, 0, 50),
			Position = UDim2.new(0.5, -100, 0, 8),
		}):Play();
		(elements.zoneName :: TextLabel).Visible = true;
		(elements.zoneName :: TextLabel).TextSize = 14;
		(elements.timeDisplay :: TextLabel).TextSize = 12

		-- Bottom left: moderate
		TweenService:Create(bottomLeft, tweenInfo, {
			Size = UDim2.new(0, 280, 0, 60),
			Position = UDim2.new(0, 15, 1, -75),
		}):Play();
		(elements.objectiveTitle :: TextLabel).Visible = false;
		(elements.objectiveText :: TextLabel).TextSize = 14;
		(elements.objectiveStep :: TextLabel).Visible = true;
		(elements.objectiveStep :: TextLabel).TextSize = 10

		-- Show bottom right but compact
		bottomRight.Visible = true
		TweenService:Create(bottomRight, tweenInfo, {
			Size = UDim2.new(0, 150, 0, 50),
			Position = UDim2.new(1, -165, 1, -65),
		}):Play();
		(elements.generatorProgress :: TextLabel).TextSize = 12;
		(elements.survivorProgress :: TextLabel).TextSize = 12

		-- Hide expand button
		expandButton.Visible = false
		if isExpanded then
			self:ToggleExpand()
		end
	else
		-- ========== LARGE SCREEN (Desktop) ==========
		-- Full layout with all details

		-- Status bars: full size
		TweenService:Create(statusBars, tweenInfo, {
			Size = UDim2.new(0, 240, 0, 100),
		}):Play()

		local hungerBar = elements.hungerBar :: Frame
		local staminaBar = elements.staminaBar :: Frame
		local healthBar = elements.healthBar :: Frame

		TweenService:Create(hungerBar, tweenInfo, {
			Size = UDim2.new(0, 200, 0, 20),
			Position = UDim2.new(0, 20, 0, 20),
		}):Play()
		TweenService:Create(staminaBar, tweenInfo, {
			Size = UDim2.new(0, 200, 0, 20),
			Position = UDim2.new(0, 20, 0, 50),
		}):Play()
		TweenService:Create(healthBar, tweenInfo, {
			Size = UDim2.new(0, 200, 0, 20),
			Position = UDim2.new(0, 20, 0, 80),
		}):Play()

		-- Show full labels
		for _, barName in { "hungerBar", "staminaBar", "healthBar" } do
			local bar = elements[barName] :: Frame
			local label = bar:FindFirstChild("Label") :: TextLabel?
			if label then
				label.Visible = true
				label.TextSize = 12
			end
		end

		-- Top center: full
		TweenService:Create(topCenter, tweenInfo, {
			Size = UDim2.new(0, 300, 0, 60),
			Position = UDim2.new(0.5, -150, 0, 10),
		}):Play();
		(elements.zoneName :: TextLabel).Visible = true;
		(elements.zoneName :: TextLabel).TextSize = 18;
		(elements.timeDisplay :: TextLabel).TextSize = 14

		-- Bottom left: full objective
		TweenService:Create(bottomLeft, tweenInfo, {
			Size = UDim2.new(0, 350, 0, 80),
			Position = UDim2.new(0, 20, 1, -100),
		}):Play();
		(elements.objectiveTitle :: TextLabel).Visible = true;
		(elements.objectiveText :: TextLabel).TextSize = 16;
		(elements.objectiveStep :: TextLabel).Visible = true;
		(elements.objectiveStep :: TextLabel).TextSize = 11

		-- Bottom right: full progress
		bottomRight.Visible = true
		TweenService:Create(bottomRight, tweenInfo, {
			Size = UDim2.new(0, 200, 0, 60),
			Position = UDim2.new(1, -220, 1, -80),
		}):Play();
		(elements.generatorProgress :: TextLabel).TextSize = 14;
		(elements.survivorProgress :: TextLabel).TextSize = 14

		-- Hide expand button
		expandButton.Visible = false
		if isExpanded then
			self:ToggleExpand()
		end
	end
end

-- ==========================================
-- TOUCH LONG-PRESS TOGGLE
-- ==========================================

local function setupTouchToggle()
	-- Long-press to toggle HUD
	UserInputService.TouchStarted:Connect(function(touch, gameProcessed)
		if gameProcessed then
			return
		end
		touchStartTime = tick()
		touchStartPosition = touch.Position
	end)

	UserInputService.TouchMoved:Connect(function(touch, _gameProcessed)
		-- Cancel long-press if finger moved too much
		if touchStartPosition then
			local delta = (touch.Position - touchStartPosition).Magnitude
			if delta > TOUCH_MOVE_THRESHOLD then
				touchStartPosition = nil
			end
		end
	end)

	UserInputService.TouchEnded:Connect(function(_touch, gameProcessed)
		if gameProcessed then
			touchStartPosition = nil
			return
		end

		-- Check if this was a long press
		if touchStartPosition and (tick() - touchStartTime) >= LONG_PRESS_DURATION then
			HUDController:Toggle()
			print("[HUDController] Touch long-press toggle")
		end

		touchStartPosition = nil
	end)
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function HUDController:Initialize()
	self:CreateHUD()

	-- Get initial screen size and apply layout
	currentScreenSize = InputService:GetScreenSize()
	self:ApplyLayout(currentScreenSize)
	print("[HUDController] Initial screen size:", currentScreenSize)

	-- Listen for screen size changes (orientation, window resize)
	InputService:OnScreenSizeChanged(function(newSize)
		if newSize ~= currentScreenSize then
			print("[HUDController] Screen size changed:", currentScreenSize, "->", newSize)
			self:ApplyLayout(newSize)
		end
	end)

	-- Set up keyboard toggle (Tab key)
	if InputService:HasPhysicalKeyboard() then
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end
			if input.KeyCode == Config.KEYBINDS.TOGGLE_HUD then
				self:Toggle()
			end
		end)
		print("[HUDController] Keyboard toggle enabled (Tab key)")
	end

	-- Set up touch long-press toggle
	if InputService:IsTouchDevice() then
		setupTouchToggle()
		print("[HUDController] Touch toggle enabled (1s long-press)")
	end

	print("[HUDController] Initialized")
	print("[HUDController] HUD toggle: Tab (keyboard) or 1s long-press (touch)")
end

return HUDController
