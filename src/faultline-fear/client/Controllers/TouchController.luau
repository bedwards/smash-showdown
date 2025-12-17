--!strict
--[[
	Faultline Fear: Touch Controller

	Handles all touch controls for mobile devices:
	- Virtual joystick for movement
	- Action buttons (eat, item, flashlight, sprint, jump, call pet)
	- Contextual interact button
	- Layout adaptation for portrait/landscape

	Only active on touch devices without physical keyboard.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local InputService = Shared.InputService

local TouchController = {}

-- State
local isEnabled: boolean = false
local isSprinting: boolean = false
local touchGui: ScreenGui = nil :: any
local elements: { [string]: GuiObject } = {}

-- Joystick state
local joystickActive: boolean = false
local joystickStartPosition: Vector2 = Vector2.zero
local joystickCurrentPosition: Vector2 = Vector2.zero
local joystickTouch: InputObject? = nil -- Store touch reference (GetHashCode doesn't exist in Luau)

-- Gesture state
local lastTapTime: number = 0
local lastTapPosition: Vector2 = Vector2.zero
local swipeStartPosition: Vector2? = nil
local swipeStartTime: number = 0

-- Gesture constants
local DOUBLE_TAP_TIME = 0.3 -- Max time between taps
local DOUBLE_TAP_DISTANCE = 50 -- Max distance between taps
local SWIPE_MIN_DISTANCE = 100 -- Min swipe distance
local SWIPE_MAX_TIME = 0.5 -- Max time for swipe

-- Constants
local BUTTON_SIZE = 60 -- 60px, good touch target
local BUTTON_SIZE_LARGE = 70
local BUTTON_SPACING = 10
local JOYSTICK_SIZE = 120
local JOYSTICK_INNER_SIZE = 50
local JOYSTICK_MAX_DISTANCE = 50

-- ==========================================
-- UI CREATION HELPERS
-- ==========================================

local function createActionButton(
	parent: Frame,
	name: string,
	text: string,
	position: UDim2,
	size: number?,
	callback: () -> ()
): ImageButton
	local buttonSize = size or BUTTON_SIZE

	local button = Instance.new("ImageButton")
	button.Name = name
	button.Size = UDim2.fromOffset(buttonSize, buttonSize)
	button.Position = position
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	button.BackgroundTransparency = 0.3
	button.AutoButtonColor = false
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0) -- Circle
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(100, 100, 100)
	stroke.Transparency = 0.5
	stroke.Parent = button

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = buttonSize > 60 and 24 or 20
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.Parent = button

	-- Touch feedback
	button.MouseButton1Down:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			BackgroundTransparency = 0.1,
			Size = UDim2.fromOffset(buttonSize * 0.9, buttonSize * 0.9),
		}):Play()
	end)

	button.MouseButton1Up:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			BackgroundTransparency = 0.3,
			Size = UDim2.fromOffset(buttonSize, buttonSize),
		}):Play()
		callback()
	end)

	-- Cancel if touch leaves button
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			BackgroundTransparency = 0.3,
			Size = UDim2.fromOffset(buttonSize, buttonSize),
		}):Play()
	end)

	return button
end

local function createToggleButton(
	parent: Frame,
	name: string,
	text: string,
	position: UDim2,
	onToggle: (isOn: boolean) -> ()
): ImageButton
	local button = createActionButton(parent, name, text, position, BUTTON_SIZE, function()
		-- Toggle handled separately
	end)

	local isOn = false
	local label = button:FindFirstChild("Label") :: TextLabel

	button.MouseButton1Click:Connect(function()
		isOn = not isOn
		if isOn then
			button.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
			label.TextColor3 = Color3.fromRGB(200, 255, 200)
		else
			button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
		onToggle(isOn)
	end)

	return button
end

-- ==========================================
-- VIRTUAL JOYSTICK
-- ==========================================

local function createJoystick(parent: Frame): Frame
	local container = Instance.new("Frame")
	container.Name = "Joystick"
	container.Size = UDim2.fromOffset(JOYSTICK_SIZE, JOYSTICK_SIZE)
	container.Position = UDim2.new(0, 30, 1, -JOYSTICK_SIZE - 80)
	container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	container.BackgroundTransparency = 0.5
	container.Parent = parent

	local outerCorner = Instance.new("UICorner")
	outerCorner.CornerRadius = UDim.new(0.5, 0)
	outerCorner.Parent = container

	local outerStroke = Instance.new("UIStroke")
	outerStroke.Thickness = 3
	outerStroke.Color = Color3.fromRGB(80, 80, 80)
	outerStroke.Transparency = 0.3
	outerStroke.Parent = container

	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.Size = UDim2.fromOffset(JOYSTICK_INNER_SIZE, JOYSTICK_INNER_SIZE)
	inner.Position = UDim2.new(0.5, 0, 0.5, 0)
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	inner.BackgroundTransparency = 0.2
	inner.Parent = container

	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(0.5, 0)
	innerCorner.Parent = inner

	return container
end

local function updateJoystick()
	if not joystickActive then
		return
	end

	local joystick = elements.joystick :: Frame
	local inner = joystick:FindFirstChild("Inner") :: Frame

	local delta = joystickCurrentPosition - joystickStartPosition
	local distance = delta.Magnitude
	local direction = distance > 0 and delta / distance or Vector2.zero

	-- Clamp to max distance
	if distance > JOYSTICK_MAX_DISTANCE then
		distance = JOYSTICK_MAX_DISTANCE
		delta = direction * distance
	end

	-- Update inner knob position
	local centerOffset = JOYSTICK_SIZE / 2
	inner.Position = UDim2.new(0, centerOffset + delta.X, 0, centerOffset + delta.Y)

	-- Calculate movement input (normalized -1 to 1)
	local moveX = delta.X / JOYSTICK_MAX_DISTANCE
	local moveY = delta.Y / JOYSTICK_MAX_DISTANCE

	-- Apply movement to character
	local player = Players.LocalPlayer
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:Move(Vector3.new(moveX, 0, moveY))
		end
	end
end

local function resetJoystick()
	joystickActive = false
	joystickTouch = nil

	local joystick = elements.joystick :: Frame
	local inner = joystick:FindFirstChild("Inner") :: Frame

	TweenService:Create(inner, TweenInfo.new(0.2), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()

	-- Stop movement
	local player = Players.LocalPlayer
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:Move(Vector3.zero)
		end
	end
end

-- ==========================================
-- ACTION HANDLERS
-- ==========================================

local function onEatFood()
	print("[TouchController] Eat food action")
	-- TODO: Fire eat request to server
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local eatRequest = remotes:FindFirstChild("EatRequest")
		if eatRequest and eatRequest:IsA("RemoteEvent") then
			eatRequest:FireServer()
		end
	end
end

local function onUseItem()
	print("[TouchController] Use item action")
	-- TODO: Open inventory or use equipped item
end

local function onFlashlight()
	print("[TouchController] Toggle flashlight")
	-- TODO: Toggle flashlight
end

local function onSprint(isOn: boolean)
	isSprinting = isOn
	print("[TouchController] Sprint:", isOn)

	local player = Players.LocalPlayer
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = isOn and 24 or 16 -- Sprint vs normal
		end
	end
end

local function onJump()
	local player = Players.LocalPlayer
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end

local function onCallPet()
	print("[TouchController] Call pet")
	-- TODO: Fire call pet request to server
end

local function onInteract()
	print("[TouchController] Interact")
	-- TODO: Fire interact request to server
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local interactRequest = remotes:FindFirstChild("InteractRequest")
		if interactRequest and interactRequest:IsA("RemoteFunction") then
			local result = interactRequest:InvokeServer()
			print("[TouchController] Interact result:", result)
		end
	end
end

-- ==========================================
-- CONTEXTUAL INTERACT BUTTON
-- ==========================================

function TouchController:ShowInteractButton(text: string)
	local interactButton = elements.interactButton :: ImageButton
	if interactButton then
		local label = interactButton:FindFirstChild("Label") :: TextLabel
		if label then
			label.Text = text
		end
		interactButton.Visible = true

		-- Animate in
		interactButton.Size = UDim2.fromOffset(BUTTON_SIZE_LARGE * 0.8, BUTTON_SIZE_LARGE * 0.8)
		TweenService:Create(interactButton, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(BUTTON_SIZE_LARGE, BUTTON_SIZE_LARGE),
		}):Play()
	end
end

function TouchController:HideInteractButton()
	local interactButton = elements.interactButton :: ImageButton
	if interactButton then
		interactButton.Visible = false
	end
end

-- ==========================================
-- GESTURE HANDLERS
-- ==========================================

local function onDoubleTap()
	print("[TouchController] Double tap - center camera")
	-- Center camera on character
	local player = Players.LocalPlayer
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local camera = workspace.CurrentCamera
			if camera then
				-- Smooth camera reset to behind character
				local targetCFrame = CFrame.new(rootPart.Position + Vector3.new(0, 10, 15), rootPart.Position)
				TweenService:Create(camera, TweenInfo.new(0.3), {
					CFrame = targetCFrame,
				}):Play()
			end
		end
	end
end

local function onSwipeLeft()
	print("[TouchController] Swipe left - previous item")
	-- TODO: Switch to previous item in hotbar
end

local function onSwipeRight()
	print("[TouchController] Swipe right - next item")
	-- TODO: Switch to next item in hotbar
end

local function processGesture(touchPosition: Vector2, touchDuration: number)
	local now = tick()

	-- Check for double tap
	if touchDuration < 0.2 then -- Quick tap
		local timeSinceLastTap = now - lastTapTime
		local distanceFromLastTap = (touchPosition - lastTapPosition).Magnitude

		if timeSinceLastTap < DOUBLE_TAP_TIME and distanceFromLastTap < DOUBLE_TAP_DISTANCE then
			-- Double tap detected
			onDoubleTap()
			lastTapTime = 0 -- Reset to prevent triple-tap
			return true
		else
			-- Single tap - save for potential double tap
			lastTapTime = now
			lastTapPosition = touchPosition
		end
	end

	return false
end

local function processSwipe(startPos: Vector2, endPos: Vector2, duration: number)
	if duration > SWIPE_MAX_TIME then
		return false
	end

	local delta = endPos - startPos
	local distance = delta.Magnitude

	if distance < SWIPE_MIN_DISTANCE then
		return false
	end

	-- Determine swipe direction (horizontal vs vertical)
	local absX = math.abs(delta.X)
	local absY = math.abs(delta.Y)

	if absX > absY then
		-- Horizontal swipe
		if delta.X > 0 then
			onSwipeRight()
		else
			onSwipeLeft()
		end
		return true
	end

	-- Vertical swipes not used currently
	return false
end

-- ==========================================
-- UI CREATION
-- ==========================================

function TouchController:CreateUI()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Main ScreenGui
	touchGui = Instance.new("ScreenGui")
	touchGui.Name = "FaultlineFearTouchControls"
	touchGui.ResetOnSpawn = false
	touchGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	touchGui.DisplayOrder = 10 -- Above HUD
	touchGui.Parent = playerGui

	-- Main container
	local container = Instance.new("Frame")
	container.Name = "TouchContainer"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = touchGui
	elements.container = container

	-- ========== JOYSTICK (Left Side) ==========
	elements.joystick = createJoystick(container)

	-- ========== LEFT ACTION BUTTONS (Bottom Left) ==========
	local leftActions = Instance.new("Frame")
	leftActions.Name = "LeftActions"
	leftActions.Size = UDim2.fromOffset(200, 70)
	leftActions.Position = UDim2.new(0, 20, 1, -70)
	leftActions.BackgroundTransparency = 1
	leftActions.Parent = container
	elements.leftActions = leftActions

	-- Food button
	elements.foodButton =
		createActionButton(leftActions, "FoodButton", "🍎", UDim2.new(0, 30, 0.5, 0), nil, onEatFood)

	-- Item/Backpack button
	elements.itemButton = createActionButton(
		leftActions,
		"ItemButton",
		"🎒",
		UDim2.new(0, 30 + BUTTON_SIZE + BUTTON_SPACING, 0.5, 0),
		nil,
		onUseItem
	)

	-- Flashlight button
	elements.flashlightButton = createActionButton(
		leftActions,
		"FlashlightButton",
		"🔦",
		UDim2.new(0, 30 + (BUTTON_SIZE + BUTTON_SPACING) * 2, 0.5, 0),
		nil,
		onFlashlight
	)

	-- ========== RIGHT ACTION BUTTONS (Bottom Right) ==========
	local rightActions = Instance.new("Frame")
	rightActions.Name = "RightActions"
	rightActions.Size = UDim2.fromOffset(200, 200)
	rightActions.Position = UDim2.new(1, -120, 1, -220)
	rightActions.BackgroundTransparency = 1
	rightActions.Parent = container
	elements.rightActions = rightActions

	-- Jump button (large, top)
	elements.jumpButton = createActionButton(
		rightActions,
		"JumpButton",
		"⬆️",
		UDim2.new(0.5, 0, 0, BUTTON_SIZE_LARGE / 2),
		BUTTON_SIZE_LARGE,
		onJump
	)

	-- Interact button (contextual, middle) - initially hidden
	elements.interactButton = createActionButton(
		rightActions,
		"InteractButton",
		"👆",
		UDim2.new(0.5, 0, 0, BUTTON_SIZE_LARGE + BUTTON_SPACING + BUTTON_SIZE_LARGE / 2),
		BUTTON_SIZE_LARGE,
		onInteract
	)
	elements.interactButton.Visible = false

	-- Sprint toggle (bottom)
	elements.sprintButton = createToggleButton(
		rightActions,
		"SprintButton",
		"🏃",
		UDim2.new(0.5, 0, 0, (BUTTON_SIZE_LARGE + BUTTON_SPACING) * 2 + BUTTON_SIZE / 2),
		onSprint
	)

	-- ========== TOP RIGHT BUTTONS ==========
	local topRight = Instance.new("Frame")
	topRight.Name = "TopRight"
	topRight.Size = UDim2.fromOffset(80, 60)
	topRight.Position = UDim2.new(1, -140, 0, 60) -- Below toggle button from HUD
	topRight.BackgroundTransparency = 1
	topRight.Parent = container
	elements.topRight = topRight

	-- Pet button
	elements.petButton = createActionButton(topRight, "PetButton", "🐕", UDim2.new(0.5, 0, 0.5, 0), nil, onCallPet)

	print("[TouchController] UI created")
end

-- ==========================================
-- INPUT HANDLING
-- ==========================================

local function setupJoystickInput()
	local joystick = elements.joystick :: Frame

	-- Handle touch on joystick area
	joystick.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			joystickActive = true
			joystickTouch = input
			joystickStartPosition = Vector2.new(input.Position.X, input.Position.Y)
			joystickCurrentPosition = joystickStartPosition
		end
	end)

	-- Global touch tracking for joystick movement
	UserInputService.TouchMoved:Connect(function(touch, _gameProcessed)
		if joystickActive and touch == joystickTouch then
			joystickCurrentPosition = Vector2.new(touch.Position.X, touch.Position.Y)
			updateJoystick()
		end
	end)

	UserInputService.TouchEnded:Connect(function(touch, _gameProcessed)
		if joystickActive and touch == joystickTouch then
			resetJoystick()
		end
	end)
end

local function setupGestureInput()
	-- Track touches for gesture detection (on empty screen areas)
	UserInputService.TouchStarted:Connect(function(touch, gameProcessed)
		if gameProcessed then
			return
		end
		swipeStartPosition = Vector2.new(touch.Position.X, touch.Position.Y)
		swipeStartTime = tick()
	end)

	UserInputService.TouchEnded:Connect(function(touch, gameProcessed)
		if gameProcessed then
			swipeStartPosition = nil
			return
		end

		local touchEndPosition = Vector2.new(touch.Position.X, touch.Position.Y)
		local touchDuration = tick() - swipeStartTime

		-- Check for swipe first (takes priority over tap)
		if swipeStartPosition then
			if processSwipe(swipeStartPosition, touchEndPosition, touchDuration) then
				swipeStartPosition = nil
				return
			end
		end

		-- Check for double-tap
		processGesture(touchEndPosition, touchDuration)

		swipeStartPosition = nil
	end)
end

-- ==========================================
-- LAYOUT ADAPTATION
-- ==========================================

function TouchController:ApplyLayout(screenSize: "Small" | "Medium" | "Large")
	local joystick = elements.joystick :: Frame
	local leftActions = elements.leftActions :: Frame
	local rightActions = elements.rightActions :: Frame
	local topRight = elements.topRight :: Frame

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad)

	if screenSize == "Small" then
		-- Portrait phone - compact layout
		TweenService:Create(joystick, tweenInfo, {
			Size = UDim2.fromOffset(100, 100),
			Position = UDim2.new(0, 20, 1, -180),
		}):Play()

		TweenService:Create(leftActions, tweenInfo, {
			Position = UDim2.new(0, 10, 1, -60),
		}):Play()

		TweenService:Create(rightActions, tweenInfo, {
			Position = UDim2.new(1, -100, 1, -200),
		}):Play()
	elseif screenSize == "Medium" then
		-- Tablet/landscape phone
		TweenService:Create(joystick, tweenInfo, {
			Size = UDim2.fromOffset(JOYSTICK_SIZE, JOYSTICK_SIZE),
			Position = UDim2.new(0, 30, 1, -JOYSTICK_SIZE - 80),
		}):Play()

		TweenService:Create(leftActions, tweenInfo, {
			Position = UDim2.new(0, 20, 1, -70),
		}):Play()

		TweenService:Create(rightActions, tweenInfo, {
			Position = UDim2.new(1, -120, 1, -220),
		}):Play()
	else
		-- Large screen - shouldn't show touch controls but handle just in case
		TweenService:Create(joystick, tweenInfo, {
			Size = UDim2.fromOffset(JOYSTICK_SIZE, JOYSTICK_SIZE),
			Position = UDim2.new(0, 40, 1, -JOYSTICK_SIZE - 100),
		}):Play()

		TweenService:Create(leftActions, tweenInfo, {
			Position = UDim2.new(0, 30, 1, -80),
		}):Play()

		TweenService:Create(rightActions, tweenInfo, {
			Position = UDim2.new(1, -140, 1, -240),
		}):Play()
	end

	-- Top right stays consistent
	TweenService:Create(topRight, tweenInfo, {
		Position = UDim2.new(1, -140, 0, 60),
	}):Play()

	print("[TouchController] Applied layout:", screenSize)
end

-- ==========================================
-- ENABLE/DISABLE
-- ==========================================

function TouchController:Enable()
	if isEnabled then
		return
	end
	isEnabled = true

	if touchGui then
		touchGui.Enabled = true
	end

	-- Disable Roblox's default touch controls since we're handling our own
	-- ContextActionService handles automatic touch buttons for bound actions

	print("[TouchController] Enabled")
end

function TouchController:Disable()
	if not isEnabled then
		return
	end
	isEnabled = false

	if touchGui then
		touchGui.Enabled = false
	end

	-- Reset sprint if it was on
	if isSprinting then
		onSprint(false)
	end

	-- Reset joystick
	resetJoystick()

	print("[TouchController] Disabled")
end

function TouchController:IsEnabled(): boolean
	return isEnabled
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function TouchController:Initialize()
	-- Only initialize on touch devices
	if not InputService:ShouldShowTouchControls() then
		print("[TouchController] Not a touch device, skipping initialization")
		return false
	end

	self:CreateUI()
	setupJoystickInput()
	setupGestureInput()

	-- Apply initial layout
	local screenSize = InputService:GetScreenSize()
	self:ApplyLayout(screenSize)

	-- Listen for screen size changes
	InputService:OnScreenSizeChanged(function(newSize)
		self:ApplyLayout(newSize)
	end)

	-- Listen for input type changes
	InputService:OnInputTypeChanged(function(deviceType)
		if deviceType == "Mobile" then
			self:Enable()
		else
			self:Disable()
		end
	end)

	-- Enable by default on touch devices
	self:Enable()

	print("[TouchController] Initialized")
	print("[TouchController] Touch controls active")
	print("[TouchController] Gestures: double-tap (center camera), swipe L/R (switch item)")

	return true
end

return TouchController
