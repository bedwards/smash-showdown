--!strict
-- Music Client - Walkman UI and radio tuning
-- Handles local audio playback and station switching

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for music events
local musicEvents = ReplicatedStorage:WaitForChild("MusicEvents", 10)
if not musicEvents then
	warn("[Music Client] Music system not found")
	return
end

local tuneStationEvent = musicEvents:WaitForChild("TuneStation") :: RemoteEvent
local pickupWalkmanEvent = musicEvents:WaitForChild("PickupWalkman") :: RemoteEvent
local walkmanStatusEvent = musicEvents:WaitForChild("WalkmanStatus") :: RemoteEvent
local radioProximityEvent = musicEvents:WaitForChild("RadioProximity") :: RemoteEvent

-- State
local hasWalkman = false
local currentStation: number? = nil
local stations: { any } = {}
local nearbyStations: { any } = {}
local walkmanSound: Sound? = nil
local isWalkmanOpen = false

-- ==========================================
-- WALKMAN UI
-- ==========================================

local function createWalkmanUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WalkmanUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Main walkman frame (hidden by default)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "WalkmanFrame"
	mainFrame.Size = UDim2.fromOffset(280, 400)
	mainFrame.Position = UDim2.new(1, -300, 0.5, -200)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 80, 90)
	stroke.Thickness = 2
	stroke.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.fromScale(0, 0)
	title.BackgroundTransparency = 1
	title.Text = "WALKMAN"
	title.TextColor3 = Color3.fromRGB(100, 200, 100)
	title.TextSize = 28
	title.Font = Enum.Font.Code
	title.Parent = mainFrame

	-- Display screen
	local screen = Instance.new("Frame")
	screen.Name = "Screen"
	screen.Size = UDim2.new(0.9, 0, 0, 80)
	screen.Position = UDim2.new(0.05, 0, 0, 50)
	screen.BackgroundColor3 = Color3.fromRGB(20, 60, 20)
	screen.BorderSizePixel = 0
	screen.Parent = mainFrame

	local screenCorner = Instance.new("UICorner")
	screenCorner.CornerRadius = UDim.new(0, 6)
	screenCorner.Parent = screen

	local frequencyLabel = Instance.new("TextLabel")
	frequencyLabel.Name = "Frequency"
	frequencyLabel.Size = UDim2.new(1, 0, 0.5, 0)
	frequencyLabel.Position = UDim2.fromScale(0, 0)
	frequencyLabel.BackgroundTransparency = 1
	frequencyLabel.Text = "-- OFF --"
	frequencyLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
	frequencyLabel.TextSize = 32
	frequencyLabel.Font = Enum.Font.Code
	frequencyLabel.Parent = screen

	local stationLabel = Instance.new("TextLabel")
	stationLabel.Name = "StationName"
	stationLabel.Size = UDim2.new(1, 0, 0.5, 0)
	stationLabel.Position = UDim2.fromScale(0, 0.5)
	stationLabel.BackgroundTransparency = 1
	stationLabel.Text = "No Station"
	stationLabel.TextColor3 = Color3.fromRGB(80, 160, 80)
	stationLabel.TextSize = 18
	stationLabel.Font = Enum.Font.Code
	stationLabel.Parent = screen

	-- Station list
	local stationList = Instance.new("ScrollingFrame")
	stationList.Name = "StationList"
	stationList.Size = UDim2.new(0.9, 0, 0, 200)
	stationList.Position = UDim2.new(0.05, 0, 0, 140)
	stationList.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	stationList.BorderSizePixel = 0
	stationList.ScrollBarThickness = 6
	stationList.ScrollBarImageColor3 = Color3.fromRGB(100, 200, 100)
	stationList.CanvasSize = UDim2.new(0, 0, 0, 0)
	stationList.Parent = mainFrame

	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 6)
	listCorner.Parent = stationList

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = stationList

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingAll = UDim.new(0, 8)
	listPadding.Parent = stationList

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.fromOffset(30, 30)
	closeButton.Position = UDim2.new(1, -35, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 20
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.Parent = mainFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton

	-- Power button
	local powerButton = Instance.new("TextButton")
	powerButton.Name = "PowerButton"
	powerButton.Size = UDim2.new(0.4, 0, 0, 40)
	powerButton.Position = UDim2.new(0.05, 0, 1, -50)
	powerButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	powerButton.Text = "POWER"
	powerButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	powerButton.TextSize = 16
	powerButton.Font = Enum.Font.SourceSansBold
	powerButton.Parent = mainFrame

	local powerCorner = Instance.new("UICorner")
	powerCorner.CornerRadius = UDim.new(0, 6)
	powerCorner.Parent = powerButton

	-- Signal indicator
	local signalFrame = Instance.new("Frame")
	signalFrame.Name = "SignalIndicator"
	signalFrame.Size = UDim2.new(0.4, 0, 0, 40)
	signalFrame.Position = UDim2.new(0.55, 0, 1, -50)
	signalFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	signalFrame.BorderSizePixel = 0
	signalFrame.Parent = mainFrame

	local signalCorner = Instance.new("UICorner")
	signalCorner.CornerRadius = UDim.new(0, 6)
	signalCorner.Parent = signalFrame

	local signalLabel = Instance.new("TextLabel")
	signalLabel.Name = "SignalText"
	signalLabel.Size = UDim2.fromScale(1, 1)
	signalLabel.BackgroundTransparency = 1
	signalLabel.Text = "NO SIGNAL"
	signalLabel.TextColor3 = Color3.fromRGB(150, 50, 50)
	signalLabel.TextSize = 14
	signalLabel.Font = Enum.Font.Code
	signalLabel.Parent = signalFrame

	return screenGui
end

-- ==========================================
-- WALKMAN INDICATOR (shows when you have one)
-- ==========================================

local function createWalkmanIndicator(gui: ScreenGui)
	local indicator = Instance.new("TextButton")
	indicator.Name = "WalkmanIndicator"
	indicator.Size = UDim2.fromOffset(50, 50)
	indicator.Position = UDim2.new(1, -60, 0.5, -25)
	indicator.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	indicator.Text = ""
	indicator.Visible = false
	indicator.Parent = gui

	local indCorner = Instance.new("UICorner")
	indCorner.CornerRadius = UDim.new(0, 8)
	indCorner.Parent = indicator

	local indStroke = Instance.new("UIStroke")
	indStroke.Color = Color3.fromRGB(100, 200, 100)
	indStroke.Thickness = 2
	indStroke.Parent = indicator

	-- Walkman icon (simplified)
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromScale(1, 1)
	icon.BackgroundTransparency = 1
	icon.Text = "W"
	icon.TextColor3 = Color3.fromRGB(100, 200, 100)
	icon.TextSize = 32
	icon.Font = Enum.Font.Code
	icon.Parent = indicator

	return indicator
end

-- ==========================================
-- STATION BUTTONS
-- ==========================================

local function populateStationList(stationList: ScrollingFrame)
	-- Clear existing
	for _, child in ipairs(stationList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	-- Add "OFF" option
	local offButton = Instance.new("TextButton")
	offButton.Name = "Station_OFF"
	offButton.Size = UDim2.new(1, -16, 0, 36)
	offButton.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
	offButton.Text = "OFF"
	offButton.TextColor3 = Color3.fromRGB(200, 100, 100)
	offButton.TextSize = 16
	offButton.Font = Enum.Font.SourceSansBold
	offButton.LayoutOrder = 0
	offButton.Parent = stationList

	local offCorner = Instance.new("UICorner")
	offCorner.CornerRadius = UDim.new(0, 4)
	offCorner.Parent = offButton

	offButton.MouseButton1Click:Connect(function()
		tuneStationEvent:FireServer(nil)
	end)

	-- Add stations
	for i, station in ipairs(stations) do
		local button = Instance.new("TextButton")
		button.Name = "Station_" .. i
		button.Size = UDim2.new(1, -16, 0, 50)
		button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		button.Text = ""
		button.LayoutOrder = i
		button.Parent = stationList

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 4)
		btnCorner.Parent = button

		-- Frequency
		local freq = Instance.new("TextLabel")
		freq.Size = UDim2.new(0.3, 0, 1, 0)
		freq.Position = UDim2.fromScale(0, 0)
		freq.BackgroundTransparency = 1
		freq.Text = station.frequency
		freq.TextColor3 = Color3.new(station.color[1], station.color[2], station.color[3])
		freq.TextSize = 14
		freq.Font = Enum.Font.Code
		freq.Parent = button

		-- Name and genre
		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(0.7, 0, 0.5, 0)
		name.Position = UDim2.new(0.3, 0, 0, 0)
		name.BackgroundTransparency = 1
		name.Text = station.name
		name.TextColor3 = Color3.fromRGB(220, 220, 220)
		name.TextSize = 14
		name.Font = Enum.Font.SourceSansBold
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = button

		local genre = Instance.new("TextLabel")
		genre.Size = UDim2.new(0.7, 0, 0.5, 0)
		genre.Position = UDim2.new(0.3, 0, 0.5, 0)
		genre.BackgroundTransparency = 1
		genre.Text = station.genre
		genre.TextColor3 = Color3.fromRGB(150, 150, 150)
		genre.TextSize = 12
		genre.Font = Enum.Font.SourceSans
		genre.TextXAlignment = Enum.TextXAlignment.Left
		genre.Parent = button

		button.MouseButton1Click:Connect(function()
			tuneStationEvent:FireServer(i)
		end)
	end

	-- Update canvas size
	local layout = stationList:FindFirstChild("UIListLayout")
	if layout then
		stationList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
	end
end

-- ==========================================
-- AUDIO PLAYBACK
-- ==========================================

local function createWalkmanSound(): Sound
	if walkmanSound then
		walkmanSound:Destroy()
	end

	local sound = Instance.new("Sound")
	sound.Name = "WalkmanPlayback"
	sound.Volume = 0.8
	sound.Looped = true
	sound.Parent = SoundService

	walkmanSound = sound
	return sound
end

local function playStation(stationData: { index: number, name: string, frequency: string, tracks: { string } })
	local sound = walkmanSound or createWalkmanSound()

	-- Pick a random track
	local trackId = stationData.tracks[math.random(1, #stationData.tracks)]
	sound.SoundId = trackId
	sound:Play()

	currentStation = stationData.index
end

local function stopPlayback()
	if walkmanSound then
		walkmanSound:Stop()
	end
	currentStation = nil
end

-- ==========================================
-- UI UPDATES
-- ==========================================

local function updateDisplay(gui: ScreenGui)
	local mainFrame = gui:FindFirstChild("WalkmanFrame") :: Frame?
	if not mainFrame then return end

	local screen = mainFrame:FindFirstChild("Screen") :: Frame?
	if not screen then return end

	local frequencyLabel = screen:FindFirstChild("Frequency") :: TextLabel?
	local stationLabel = screen:FindFirstChild("StationName") :: TextLabel?

	if currentStation and stations[currentStation] then
		local station = stations[currentStation]
		if frequencyLabel then
			frequencyLabel.Text = station.frequency
			frequencyLabel.TextColor3 = Color3.new(station.color[1], station.color[2], station.color[3])
		end
		if stationLabel then
			stationLabel.Text = station.name
		end
	else
		if frequencyLabel then
			frequencyLabel.Text = "-- OFF --"
			frequencyLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
		end
		if stationLabel then
			stationLabel.Text = "No Station"
		end
	end

	-- Update signal indicator
	local signalFrame = mainFrame:FindFirstChild("SignalIndicator") :: Frame?
	if signalFrame then
		local signalText = signalFrame:FindFirstChild("SignalText") :: TextLabel?
		if signalText then
			if #nearbyStations > 0 then
				local strongest = nearbyStations[1]
				local bars = math.floor(strongest.strength * 5)
				local barStr = string.rep("|", bars) .. string.rep(".", 5 - bars)
				signalText.Text = barStr
				signalText.TextColor3 = Color3.fromRGB(100, 200, 100)
			else
				signalText.Text = "NO SIGNAL"
				signalText.TextColor3 = Color3.fromRGB(150, 50, 50)
			end
		end
	end
end

local function toggleWalkman(gui: ScreenGui)
	local mainFrame = gui:FindFirstChild("WalkmanFrame") :: Frame?
	local indicator = gui:FindFirstChild("WalkmanIndicator") :: TextButton?
	if not mainFrame or not indicator then return end

	isWalkmanOpen = not isWalkmanOpen
	mainFrame.Visible = isWalkmanOpen

	-- Animate
	if isWalkmanOpen then
		mainFrame.Position = UDim2.new(1, 0, 0.5, -200)
		local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Position = UDim2.new(1, -300, 0.5, -200),
		})
		tween:Play()
	end
end

-- ==========================================
-- EVENT HANDLERS
-- ==========================================

local walkmanGui: ScreenGui? = nil

walkmanStatusEvent.OnClientEvent:Connect(function(data: { hasWalkman: boolean, stations: { any }? })
	hasWalkman = data.hasWalkman

	if data.stations then
		stations = data.stations
	end

	if walkmanGui then
		local indicator = walkmanGui:FindFirstChild("WalkmanIndicator")
		if indicator then
			indicator.Visible = hasWalkman
		end

		local stationList = walkmanGui:FindFirstChild("WalkmanFrame")
		if stationList then
			local list = stationList:FindFirstChild("StationList") :: ScrollingFrame?
			if list then
				populateStationList(list)
			end
		end
	end
end)

pickupWalkmanEvent.OnClientEvent:Connect(function(gotWalkman: boolean)
	hasWalkman = gotWalkman

	if walkmanGui then
		local indicator = walkmanGui:FindFirstChild("WalkmanIndicator")
		if indicator then
			indicator.Visible = hasWalkman
		end
	end

	-- Show pickup message
	if gotWalkman then
		-- Could add a nice pickup animation/message here
		print("You picked up a walkman! Press M to open.")
	end
end)

tuneStationEvent.OnClientEvent:Connect(function(stationData: { index: number, name: string, frequency: string, tracks: { string } }?)
	if stationData then
		playStation(stationData)
	else
		stopPlayback()
	end

	if walkmanGui then
		updateDisplay(walkmanGui)
	end
end)

radioProximityEvent.OnClientEvent:Connect(function(nearby: { any })
	nearbyStations = nearby

	if walkmanGui then
		updateDisplay(walkmanGui)
	end
end)

-- ==========================================
-- INPUT HANDLING
-- ==========================================

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end

	-- M key toggles walkman UI
	if input.KeyCode == Enum.KeyCode.M then
		if hasWalkman and walkmanGui then
			toggleWalkman(walkmanGui)
		end
	end

	-- ★★★ WALKMAN RADIO QUICK KEYS (6, 7, 8) ★★★
	-- Only work if player has a walkman!
	if hasWalkman then
		-- Key 6 = Station 1 (Survivor Radio)
		if input.KeyCode == Enum.KeyCode.Six then
			tuneStationEvent:FireServer(1)
			print("[Music] Quick tune: Station 1 - Survivor Radio (88.1 FM)")
		-- Key 7 = Station 2 (Camel Country)
		elseif input.KeyCode == Enum.KeyCode.Seven then
			tuneStationEvent:FireServer(2)
			print("[Music] Quick tune: Station 2 - Camel Country (103.5 FM)")
		-- Key 8 = World Radio (ambient/off - returns to auto-ambient)
		elseif input.KeyCode == Enum.KeyCode.Eight then
			tuneStationEvent:FireServer(nil)
			print("[Music] Quick tune: World Radio (ambient mode)")
		end
	end
end)

-- ==========================================
-- ALWAYS-ON AMBIENT MUSIC (plays nearest station)
-- ==========================================

local ambientSound: Sound? = nil
local currentAmbientStation: number? = nil
local lastStationCheck = 0
local STATION_CHECK_INTERVAL = 1 -- Check every second for performance

local function createAmbientSound(): Sound
	if ambientSound then
		ambientSound:Destroy()
	end

	local sound = Instance.new("Sound")
	sound.Name = "AmbientRadio"
	sound.Volume = 0.5
	sound.Looped = true
	sound.Parent = SoundService

	ambientSound = sound
	return sound
end

-- Default ambient tracks (used when no radio towers nearby)
local DEFAULT_AMBIENT_TRACKS = {
	"rbxassetid://9043887091", -- Ambient nature
	"rbxassetid://1839841276", -- Atmospheric
}

local function playNearestStation()
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	-- MUSIC NEVER STOPS! Always play something
	if #nearbyStations > 0 then
		local nearest = nearbyStations[1] -- Already sorted by strength

		-- Only switch if it's a different station
		if nearest.index ~= currentAmbientStation then
			currentAmbientStation = nearest.index

			-- Check if this is the default ambient (index 0)
			if nearest.index == 0 and nearest.tracks then
				-- Default ambient from server
				if ambientSound then
					local trackId = nearest.tracks[math.random(1, #nearest.tracks)]
					ambientSound.SoundId = trackId
					if not ambientSound.IsPlaying then
						ambientSound:Play()
					end
					print("[Music] Now playing: Wilderness Ambient")
				end
			else
				-- Find full station data from stations list
				for _, station in ipairs(stations) do
					if station.index == nearest.index then
						if ambientSound then
							-- Pick random track from station
							local trackId = station.tracks[math.random(1, #station.tracks)]
							ambientSound.SoundId = trackId
							if not ambientSound.IsPlaying then
								ambientSound:Play()
							end
							print("[Music] Now playing:", station.name, "-", station.frequency)
						end
						break
					end
				end
			end
		end
	else
		-- Fallback: No nearby stations at all, play default ambient
		if currentAmbientStation ~= -1 then
			currentAmbientStation = -1
			if ambientSound then
				local trackId = DEFAULT_AMBIENT_TRACKS[math.random(1, #DEFAULT_AMBIENT_TRACKS)]
				ambientSound.SoundId = trackId
				if not ambientSound.IsPlaying then
					ambientSound:Play()
				end
				print("[Music] Playing fallback ambient music")
			end
		end
	end

	-- Extra safety: If sound isn't playing for some reason, start it
	if ambientSound and not ambientSound.IsPlaying and ambientSound.SoundId ~= "" then
		ambientSound:Play()
	end
end

-- Update ambient music based on proximity
local function updateAmbientMusic()
	local now = tick()
	if now - lastStationCheck < STATION_CHECK_INTERVAL then return end
	lastStationCheck = now

	playNearestStation()
end

-- Connect to RunService for continuous updates
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(updateAmbientMusic)

-- ==========================================
-- INITIALIZATION
-- ==========================================

local function initialize()
	-- Create ambient sound (ALWAYS PLAYING)
	local sound = createAmbientSound()

	-- START PLAYING IMMEDIATELY with default ambient!
	-- Don't wait for server - start music right away
	if sound then
		local trackId = DEFAULT_AMBIENT_TRACKS[math.random(1, #DEFAULT_AMBIENT_TRACKS)]
		sound.SoundId = trackId
		sound:Play()
		currentAmbientStation = -1 -- Mark as playing default
		print("[Music Client] Started ambient music immediately!")
	end

	-- Create UI
	walkmanGui = createWalkmanUI()
	local indicator = createWalkmanIndicator(walkmanGui)

	-- Setup indicator click
	indicator.MouseButton1Click:Connect(function()
		if hasWalkman then
			toggleWalkman(walkmanGui)
		end
	end)

	-- Setup close button
	local mainFrame = walkmanGui:FindFirstChild("WalkmanFrame") :: Frame?
	if mainFrame then
		local closeBtn = mainFrame:FindFirstChild("CloseButton") :: TextButton?
		if closeBtn then
			closeBtn.MouseButton1Click:Connect(function()
				toggleWalkman(walkmanGui)
			end)
		end

		local powerBtn = mainFrame:FindFirstChild("PowerButton") :: TextButton?
		if powerBtn then
			powerBtn.MouseButton1Click:Connect(function()
				if currentStation then
					tuneStationEvent:FireServer(nil)
				end
			end)
		end

		local stationList = mainFrame:FindFirstChild("StationList") :: ScrollingFrame?
		if stationList then
			populateStationList(stationList)
		end
	end

	-- Create sound instance for walkman
	createWalkmanSound()

	print("[Music Client] MUSIC NEVER STOPS! Ambient radio always playing.")
end

initialize()
