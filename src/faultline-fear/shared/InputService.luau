--!strict
-- Faultline Fear: Input Detection Service
-- Centralized device detection - all input queries go through here
-- Handles mobile vs desktop vs console detection

local UserInputService = game:GetService("UserInputService")

export type DeviceType = "Mobile" | "Desktop" | "Console"
export type InputCallback = (deviceType: DeviceType) -> ()

local InputService = {}

-- Internal state
local cachedDeviceType: DeviceType? = nil
local inputChangeCallbacks: { InputCallback } = {}

-- ==========================================
-- DEVICE DETECTION
-- ==========================================

--[[
	Determine the current device type based on available inputs.

	Logic:
	- Touch + No Keyboard = Mobile
	- Gamepad + No Keyboard = Console
	- Keyboard = Desktop (even if touch available, like Surface)

	@return "Mobile" | "Desktop" | "Console"
]]
function InputService:GetDeviceType(): DeviceType
	if cachedDeviceType then
		return cachedDeviceType
	end

	local touchEnabled = UserInputService.TouchEnabled
	local keyboardEnabled = UserInputService.KeyboardEnabled
	local gamepadEnabled = UserInputService.GamepadEnabled

	local deviceType: DeviceType

	if touchEnabled and not keyboardEnabled then
		deviceType = "Mobile"
	elseif gamepadEnabled and not keyboardEnabled then
		deviceType = "Console"
	else
		deviceType = "Desktop"
	end

	cachedDeviceType = deviceType
	return deviceType
end

--[[
	Check if the device has a physical keyboard.
	Note: This can change if a Bluetooth keyboard is connected.
]]
function InputService:HasPhysicalKeyboard(): boolean
	return UserInputService.KeyboardEnabled
end

--[[
	Check if the device has a touch screen.
]]
function InputService:IsTouchDevice(): boolean
	return UserInputService.TouchEnabled
end

--[[
	Check if a gamepad is connected.
]]
function InputService:HasGamepad(): boolean
	return UserInputService.GamepadEnabled
end

--[[
	Check if the device has a gyroscope (for tilt controls).
]]
function InputService:HasGyroscope(): boolean
	return UserInputService.GyroscopeEnabled
end

-- ==========================================
-- SCREEN SIZE DETECTION
-- ==========================================

--[[
	Get the screen size category for responsive UI.

	@return "Small" | "Medium" | "Large"
]]
function InputService:GetScreenSize(): "Small" | "Medium" | "Large"
	local camera = workspace.CurrentCamera
	if not camera then
		return "Medium" -- Safe default
	end

	local viewport = camera.ViewportSize
	local shortSide = math.min(viewport.X, viewport.Y)

	local Config = require(script.Parent.Config)

	if shortSide < Config.HUD.SMALL_SCREEN_MAX then
		return "Small" -- Phone portrait
	elseif shortSide < Config.HUD.MEDIUM_SCREEN_MAX then
		return "Medium" -- Tablet / Phone landscape
	else
		return "Large" -- Desktop / TV
	end
end

--[[
	Check if we should use minimal HUD (small screen OR mobile).
]]
function InputService:ShouldUseMinimalHUD(): boolean
	local screenSize = self:GetScreenSize()
	local deviceType = self:GetDeviceType()

	return screenSize == "Small" or deviceType == "Mobile"
end

--[[
	Check if we should show touch controls.
]]
function InputService:ShouldShowTouchControls(): boolean
	return self:IsTouchDevice() and not self:HasPhysicalKeyboard()
end

-- ==========================================
-- INPUT TYPE CHANGE DETECTION
-- ==========================================

--[[
	Register a callback for when the input type changes.
	This can happen when:
	- Bluetooth keyboard connected/disconnected
	- Gamepad connected/disconnected

	@param callback - Function to call with new device type
]]
function InputService:OnInputTypeChanged(callback: InputCallback)
	table.insert(inputChangeCallbacks, callback)
end

-- Listen for input type changes
local function checkInputTypeChange()
	local oldType = cachedDeviceType

	-- Force recalculation
	cachedDeviceType = nil
	local newType = InputService:GetDeviceType()

	if oldType and newType ~= oldType then
		for _, callback in ipairs(inputChangeCallbacks) do
			task.spawn(callback, newType)
		end
	end
end

-- Monitor for changes
UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(checkInputTypeChange)
UserInputService:GetPropertyChangedSignal("GamepadEnabled"):Connect(checkInputTypeChange)
UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(checkInputTypeChange)

-- Also listen for PreferredInput changes (more reliable on modern Roblox)
if UserInputService:GetPropertyChangedSignal("PreferredInput") then
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(checkInputTypeChange)
end

-- ==========================================
-- VIEWPORT CHANGE DETECTION
-- ==========================================

local viewportChangeCallbacks: { (string) -> () } = {}

--[[
	Register a callback for when screen size category changes.
	Useful for responsive HUD updates.
]]
function InputService:OnScreenSizeChanged(callback: (size: "Small" | "Medium" | "Large") -> ())
	table.insert(viewportChangeCallbacks, callback)
end

-- Monitor viewport changes
local lastScreenSize: string? = nil
local function checkViewportChange()
	local newSize = InputService:GetScreenSize()
	if lastScreenSize and newSize ~= lastScreenSize then
		for _, callback in ipairs(viewportChangeCallbacks) do
			task.spawn(callback, newSize)
		end
	end
	lastScreenSize = newSize
end

task.spawn(function()
	while true do
		task.wait(0.5) -- Check twice per second
		checkViewportChange()
	end
end)

-- ==========================================
-- DEBUG / INFO
-- ==========================================

--[[
	Get a summary of current input capabilities.
	Useful for debugging.
]]
function InputService:GetInputSummary(): {
	deviceType: DeviceType,
	screenSize: string,
	touch: boolean,
	keyboard: boolean,
	gamepad: boolean,
	gyroscope: boolean,
}
	return {
		deviceType = self:GetDeviceType(),
		screenSize = self:GetScreenSize(),
		touch = self:IsTouchDevice(),
		keyboard = self:HasPhysicalKeyboard(),
		gamepad = self:HasGamepad(),
		gyroscope = self:HasGyroscope(),
	}
end

return InputService
