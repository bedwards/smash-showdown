--!strict
--[[
	Faultline Fear: Debug Overlay Controller

	Desktop-only debug overlay activated by F3 key.
	NOT available on mobile devices.

	Features:
	- FPS counter
	- Memory usage
	- Network stats
	- Service status
	- Player position/zone
	- Active entities count
	- Error log viewer

	Press F3 to toggle overlay
	Press F4 for detailed metrics dump to console
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Heightmap = Shared.Heightmap
local InputService = Shared.InputService

local DebugOverlayController = {}

-- State
local isVisible: boolean = false
local overlay: ScreenGui? = nil
local mainFrame: Frame? = nil

-- Metrics
local frameCount: number = 0
local lastFpsUpdate: number = 0
local currentFps: number = 0
local errorLog: { string } = {}
local MAX_ERRORS = 20

-- ==========================================
-- OVERLAY CREATION
-- ==========================================

local function createLabel(parent: GuiObject, name: string, position: UDim2, size: UDim2): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(0, 255, 0)
	label.TextStrokeTransparency = 0.5
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Font = Enum.Font.RobotoMono
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Text = ""
	label.Parent = parent
	return label
end

local function createOverlay(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "DebugOverlay"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000
	gui.IgnoreGuiInset = true

	-- Main container
	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Position = UDim2.new(0, 10, 0, 10)
	frame.Size = UDim2.new(0, 350, 0, 400)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.7
	frame.BorderSizePixel = 1
	frame.BorderColor3 = Color3.fromRGB(0, 255, 0)
	frame.Parent = gui

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Position = UDim2.new(0, 5, 0, 5)
	title.Size = UDim2.new(1, -10, 0, 20)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(0, 255, 0)
	title.Font = Enum.Font.RobotoMono
	title.TextSize = 16
	title.Text = "=== FAULTLINE FEAR DEBUG (F3) ==="
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = frame

	-- Metrics labels
	createLabel(frame, "FPS", UDim2.new(0, 5, 0, 30), UDim2.new(1, -10, 0, 16))
	createLabel(frame, "Memory", UDim2.new(0, 5, 0, 48), UDim2.new(1, -10, 0, 16))
	createLabel(frame, "Ping", UDim2.new(0, 5, 0, 66), UDim2.new(1, -10, 0, 16))
	createLabel(frame, "Position", UDim2.new(0, 5, 0, 90), UDim2.new(1, -10, 0, 16))
	createLabel(frame, "Zone", UDim2.new(0, 5, 0, 108), UDim2.new(1, -10, 0, 16))
	createLabel(frame, "TerrainHeight", UDim2.new(0, 5, 0, 126), UDim2.new(1, -10, 0, 16))
	createLabel(frame, "Instances", UDim2.new(0, 5, 0, 150), UDim2.new(1, -10, 0, 16))
	createLabel(frame, "Heartbeat", UDim2.new(0, 5, 0, 168), UDim2.new(1, -10, 0, 16))

	-- Service status section
	local servicesTitle = Instance.new("TextLabel")
	servicesTitle.Name = "ServicesTitle"
	servicesTitle.Position = UDim2.new(0, 5, 0, 195)
	servicesTitle.Size = UDim2.new(1, -10, 0, 16)
	servicesTitle.BackgroundTransparency = 1
	servicesTitle.TextColor3 = Color3.fromRGB(255, 255, 0)
	servicesTitle.Font = Enum.Font.RobotoMono
	servicesTitle.TextSize = 14
	servicesTitle.Text = "--- Services ---"
	servicesTitle.TextXAlignment = Enum.TextXAlignment.Left
	servicesTitle.Parent = frame

	createLabel(frame, "Heightmap", UDim2.new(0, 5, 0, 213), UDim2.new(1, -10, 0, 16))
	createLabel(frame, "Remotes", UDim2.new(0, 5, 0, 231), UDim2.new(1, -10, 0, 16))

	-- Errors section
	local errorsTitle = Instance.new("TextLabel")
	errorsTitle.Name = "ErrorsTitle"
	errorsTitle.Position = UDim2.new(0, 5, 0, 255)
	errorsTitle.Size = UDim2.new(1, -10, 0, 16)
	errorsTitle.BackgroundTransparency = 1
	errorsTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
	errorsTitle.Font = Enum.Font.RobotoMono
	errorsTitle.TextSize = 14
	errorsTitle.Text = "--- Recent Errors ---"
	errorsTitle.TextXAlignment = Enum.TextXAlignment.Left
	errorsTitle.Parent = frame

	createLabel(frame, "Errors", UDim2.new(0, 5, 0, 273), UDim2.new(1, -10, 0, 120))

	mainFrame = frame
	return gui
end

-- ==========================================
-- METRICS COLLECTION
-- ==========================================

local function getLabel(name: string): TextLabel?
	if not mainFrame then
		return nil
	end
	return mainFrame:FindFirstChild(name) :: TextLabel?
end

local function updateMetrics()
	if not isVisible or not mainFrame then
		return
	end

	local player = Players.LocalPlayer
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?

	-- FPS
	frameCount += 1
	local now = tick()
	if now - lastFpsUpdate >= 1 then
		currentFps = frameCount
		frameCount = 0
		lastFpsUpdate = now
	end

	local fpsLabel = getLabel("FPS")
	if fpsLabel then
		fpsLabel.Text = string.format("FPS: %d", currentFps)
		fpsLabel.TextColor3 = Color3.fromRGB(currentFps >= 55 and 0 or 255, currentFps >= 30 and 255 or 0, 0)
	end

	-- Memory
	local memLabel = getLabel("Memory")
	if memLabel then
		local mem = Stats:GetTotalMemoryUsageMb()
		memLabel.Text = string.format("Memory: %.1f MB", mem)
	end

	-- Ping
	local pingLabel = getLabel("Ping")
	if pingLabel then
		local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
		pingLabel.Text = string.format("Ping: %.0f ms", ping)
	end

	-- Position
	local posLabel = getLabel("Position")
	if posLabel and rootPart then
		local pos = rootPart.Position
		posLabel.Text = string.format("Pos: (%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z)
	elseif posLabel then
		posLabel.Text = "Pos: N/A"
	end

	-- Zone
	local zoneLabel = getLabel("Zone")
	if zoneLabel and rootPart then
		local zone = Heightmap:GetZone(rootPart.Position.X, rootPart.Position.Z)
		zoneLabel.Text = string.format("Zone: %s", zone)
	elseif zoneLabel then
		zoneLabel.Text = "Zone: N/A"
	end

	-- Terrain height
	local heightLabel = getLabel("TerrainHeight")
	if heightLabel and rootPart then
		local terrainHeight = Heightmap:GetHeight(rootPart.Position.X, rootPart.Position.Z)
		local playerHeight = rootPart.Position.Y
		local diff = playerHeight - terrainHeight
		heightLabel.Text = string.format("Terrain: %.1f (player +%.1f)", terrainHeight, diff)
	elseif heightLabel then
		heightLabel.Text = "Terrain: N/A"
	end

	-- Instance count
	local instanceLabel = getLabel("Instances")
	if instanceLabel then
		local count = Stats.InstanceCount:GetValue()
		instanceLabel.Text = string.format("Instances: %d", count)
	end

	-- Heartbeat
	local heartbeatLabel = getLabel("Heartbeat")
	if heartbeatLabel then
		local dt = RunService.Heartbeat:Wait()
		heartbeatLabel.Text = string.format("Heartbeat: %.2f ms", dt * 1000)
	end

	-- Service status
	local heightmapLabel = getLabel("Heightmap")
	if heightmapLabel then
		local ready = Heightmap:IsGenerated()
		heightmapLabel.Text = string.format("Heightmap: %s", ready and "✓ Ready" or "✗ Not Ready")
		heightmapLabel.TextColor3 = ready and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
	end

	local remotesLabel = getLabel("Remotes")
	if remotesLabel then
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local count = remotes and #remotes:GetChildren() or 0
		remotesLabel.Text = string.format("Remotes: %d registered", count)
	end

	-- Errors
	local errorsLabel = getLabel("Errors")
	if errorsLabel then
		if #errorLog == 0 then
			errorsLabel.Text = "(none)"
			errorsLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		else
			local recentErrors = {}
			for i = math.max(1, #errorLog - 5), #errorLog do
				table.insert(recentErrors, errorLog[i])
			end
			errorsLabel.Text = table.concat(recentErrors, "\n")
			errorsLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
		end
	end
end

-- ==========================================
-- ERROR CAPTURE
-- ==========================================

local function captureError(message: string, _stack: string?)
	local timestamp = os.date("%H:%M:%S")
	local shortMsg = string.sub(message, 1, 50)
	table.insert(errorLog, string.format("[%s] %s", timestamp, shortMsg))

	-- Keep log bounded
	while #errorLog > MAX_ERRORS do
		table.remove(errorLog, 1)
	end
end

-- ==========================================
-- TOGGLE & INPUT
-- ==========================================

local function toggleOverlay()
	isVisible = not isVisible

	if overlay then
		overlay.Enabled = isVisible
	end

	if isVisible then
		print("[DebugOverlay] Overlay enabled (F3 to hide, F4 for dump)")
	else
		print("[DebugOverlay] Overlay hidden")
	end
end

local function dumpDetailedMetrics()
	print("\n========== FAULTLINE FEAR DEBUG DUMP ==========")
	print(string.format("Timestamp: %s", os.date("%Y-%m-%d %H:%M:%S")))
	print(string.format("FPS: %d", currentFps))
	print(string.format("Memory: %.1f MB", Stats:GetTotalMemoryUsageMb()))
	print(string.format("Instances: %d", Stats.InstanceCount:GetValue()))
	print(string.format("Heightmap Ready: %s", tostring(Heightmap:IsGenerated())))

	local player = Players.LocalPlayer
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if rootPart then
		local pos = rootPart.Position
		print(string.format("Player Position: (%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z))
		print(string.format("Player Zone: %s", Heightmap:GetZone(pos.X, pos.Z)))
		print(string.format("Terrain Height: %.1f", Heightmap:GetHeight(pos.X, pos.Z)))
	end

	-- Check workspace contents
	local workspace = game:GetService("Workspace")
	print("\n--- Workspace Folders ---")
	for _, child in workspace:GetChildren() do
		if child:IsA("Folder") then
			print(string.format("  %s: %d children", child.Name, #child:GetChildren()))
		end
	end

	-- Check remotes
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		print("\n--- Remote Events ---")
		for _, remote in remotes:GetChildren() do
			print(string.format("  %s (%s)", remote.Name, remote.ClassName))
		end
	end

	-- Error log
	if #errorLog > 0 then
		print("\n--- Error Log ---")
		for i, err in ipairs(errorLog) do
			print(string.format("  %d. %s", i, err))
		end
	else
		print("\n--- No Errors Logged ---")
	end

	print("================================================\n")
end

local function handleInput(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.F3 then
		toggleOverlay()
	elseif input.KeyCode == Enum.KeyCode.F4 then
		dumpDetailedMetrics()
	end
end

-- ==========================================
-- PUBLIC API
-- ==========================================

function DebugOverlayController:IsVisible(): boolean
	return isVisible
end

function DebugOverlayController:LogError(message: string, stack: string?)
	captureError(message, stack)
end

function DebugOverlayController:GetErrorCount(): number
	return #errorLog
end

function DebugOverlayController:Initialize()
	-- Only enable on desktop (not mobile/touch)
	if not InputService:HasPhysicalKeyboard() then
		print("[DebugOverlay] Disabled (no physical keyboard detected)")
		return
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Create overlay
	overlay = createOverlay()
	overlay.Enabled = false
	overlay.Parent = playerGui

	-- Input handling
	UserInputService.InputBegan:Connect(handleInput)

	-- Update loop (connection retained for lifetime of client)
	RunService.Heartbeat:Connect(function()
		if isVisible then
			updateMetrics()
		end
	end)

	-- Capture script errors
	local logService = game:GetService("LogService")
	logService.MessageOut:Connect(function(message, messageType)
		if messageType == Enum.MessageType.MessageError then
			captureError(message, nil)
		end
	end)

	print("[DebugOverlay] Initialized - Press F3 to toggle, F4 for dump")
end

return DebugOverlayController
