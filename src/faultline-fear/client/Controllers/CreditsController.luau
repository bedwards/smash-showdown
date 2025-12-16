--!strict
--[[
	Faultline Fear: Credits Controller

	Handles the ending sequence and credits display:
	- Shows ending screen based on survivors rescued
	- Displays scrolling credits
	- Records completion time
	- Offers post-game options

	This is THE END of the game experience.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

local CreditsController = {}

-- State
local screenGui: ScreenGui = nil :: any
local isShowing: boolean = false

-- ==========================================
-- CREDITS DATA
-- ==========================================

local CreditsText = {
	"FAULTLINE FEAR",
	"",
	"A Survival Experience",
	"",
	"",
	"- CREATED BY -",
	"",
	"bedwards",
	"",
	"",
	"- DEVELOPMENT -",
	"",
	"Game Design: bedwards",
	"Programming: bedwards & Claude",
	"Art Direction: bedwards",
	"Music & Sound: Roblox Library",
	"",
	"",
	"- SPECIAL THANKS -",
	"",
	"The Roblox Developer Community",
	"Anthropic",
	"Players like you",
	"",
	"",
	"- TOOLS USED -",
	"",
	"Rojo",
	"Selene",
	"StyLua",
	"Wally",
	"Claude Code",
	"",
	"",
	"",
	"Thank you for playing.",
	"",
	"",
	"THE END",
}

-- ==========================================
-- UI CREATION
-- ==========================================

function CreditsController:CreateCreditsUI()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Main ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FaultlineFearCredits"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 100 -- Above everything
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Background
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0
	background.Parent = screenGui

	-- Ending title (changes based on ending)
	local endingTitle = Instance.new("TextLabel")
	endingTitle.Name = "EndingTitle"
	endingTitle.Size = UDim2.new(1, 0, 0, 100)
	endingTitle.Position = UDim2.new(0, 0, 0.2, 0)
	endingTitle.BackgroundTransparency = 1
	endingTitle.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	endingTitle.TextSize = 48
	endingTitle.Font = Enum.Font.GothamBold
	endingTitle.Text = "THE END"
	endingTitle.Parent = background

	-- Ending subtitle
	local endingSubtitle = Instance.new("TextLabel")
	endingSubtitle.Name = "EndingSubtitle"
	endingSubtitle.Size = UDim2.new(1, 0, 0, 40)
	endingSubtitle.Position = UDim2.new(0, 0, 0.2, 110)
	endingSubtitle.BackgroundTransparency = 1
	endingSubtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	endingSubtitle.TextSize = 24
	endingSubtitle.Font = Enum.Font.GothamMedium
	endingSubtitle.Text = ""
	endingSubtitle.Parent = background

	-- Stats frame
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsFrame"
	statsFrame.Size = UDim2.new(0, 400, 0, 150)
	statsFrame.Position = UDim2.new(0.5, -200, 0.4, 0)
	statsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	statsFrame.BackgroundTransparency = 0.5
	statsFrame.Parent = background

	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0, 12)
	statsCorner.Parent = statsFrame

	-- Survivors rescued stat
	local survivorsStat = Instance.new("TextLabel")
	survivorsStat.Name = "SurvivorsStat"
	survivorsStat.Size = UDim2.new(1, 0, 0, 30)
	survivorsStat.Position = UDim2.new(0, 0, 0, 30)
	survivorsStat.BackgroundTransparency = 1
	survivorsStat.TextColor3 = Color3.fromRGB(255, 255, 255)
	survivorsStat.TextSize = 20
	survivorsStat.Font = Enum.Font.GothamMedium
	survivorsStat.Text = "Survivors Rescued: 0/10"
	survivorsStat.Parent = statsFrame

	-- Time stat
	local timeStat = Instance.new("TextLabel")
	timeStat.Name = "TimeStat"
	timeStat.Size = UDim2.new(1, 0, 0, 30)
	timeStat.Position = UDim2.new(0, 0, 0, 60)
	timeStat.BackgroundTransparency = 1
	timeStat.TextColor3 = Color3.fromRGB(255, 255, 255)
	timeStat.TextSize = 20
	timeStat.Font = Enum.Font.GothamMedium
	timeStat.Text = "Completion Time: 00:00"
	timeStat.Parent = statsFrame

	-- Signal parts stat
	local signalStat = Instance.new("TextLabel")
	signalStat.Name = "SignalStat"
	signalStat.Size = UDim2.new(1, 0, 0, 30)
	signalStat.Position = UDim2.new(0, 0, 0, 90)
	signalStat.BackgroundTransparency = 1
	signalStat.TextColor3 = Color3.fromRGB(255, 255, 255)
	signalStat.TextSize = 20
	signalStat.Font = Enum.Font.GothamMedium
	signalStat.Text = "Signal Parts: 6/6"
	signalStat.Parent = statsFrame

	-- Credits scroll container
	local creditsContainer = Instance.new("Frame")
	creditsContainer.Name = "CreditsContainer"
	creditsContainer.Size = UDim2.new(1, 0, 0.4, 0)
	creditsContainer.Position = UDim2.new(0, 0, 0.6, 0)
	creditsContainer.BackgroundTransparency = 1
	creditsContainer.ClipsDescendants = true
	creditsContainer.Parent = background

	-- Credits text (will scroll)
	local creditsText = Instance.new("TextLabel")
	creditsText.Name = "CreditsText"
	creditsText.Size = UDim2.new(1, 0, 0, 2000)
	creditsText.Position = UDim2.new(0, 0, 1, 0) -- Start below screen
	creditsText.BackgroundTransparency = 1
	creditsText.TextColor3 = Color3.fromRGB(200, 200, 200)
	creditsText.TextSize = 18
	creditsText.Font = Enum.Font.Gotham
	creditsText.Text = table.concat(CreditsText, "\n")
	creditsText.TextYAlignment = Enum.TextYAlignment.Top
	creditsText.Parent = creditsContainer

	-- Continue button (appears after credits)
	local continueButton = Instance.new("TextButton")
	continueButton.Name = "ContinueButton"
	continueButton.Size = UDim2.new(0, 200, 0, 50)
	continueButton.Position = UDim2.new(0.5, -100, 0.85, 0)
	continueButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	continueButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	continueButton.TextSize = 20
	continueButton.Font = Enum.Font.GothamBold
	continueButton.Text = "Continue Playing"
	continueButton.Visible = false
	continueButton.Parent = background

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = continueButton

	continueButton.MouseButton1Click:Connect(function()
		self:Hide()
	end)

	print("[CreditsController] UI created")
end

-- ==========================================
-- DISPLAY FUNCTIONS
-- ==========================================

function CreditsController:Show(endingData: {
	name: string,
	description: string,
	creditsSuffix: string,
	playTime: number,
	survivorsRescued: number,
	signalPartsCollected: number,
})
	if isShowing then
		return
	end
	isShowing = true

	screenGui.Enabled = true

	local background = screenGui:FindFirstChild("Background") :: Frame
	local endingTitle = background:FindFirstChild("EndingTitle") :: TextLabel
	local endingSubtitle = background:FindFirstChild("EndingSubtitle") :: TextLabel
	local statsFrame = background:FindFirstChild("StatsFrame") :: Frame
	local survivorsStat = statsFrame:FindFirstChild("SurvivorsStat") :: TextLabel
	local timeStat = statsFrame:FindFirstChild("TimeStat") :: TextLabel
	local signalStat = statsFrame:FindFirstChild("SignalStat") :: TextLabel
	local creditsContainer = background:FindFirstChild("CreditsContainer") :: Frame
	local creditsText = creditsContainer:FindFirstChild("CreditsText") :: TextLabel
	local continueButton = background:FindFirstChild("ContinueButton") :: TextButton

	-- Set ending text
	endingTitle.Text = endingData.name:upper()
	endingSubtitle.Text = endingData.description

	-- Set ending color based on quality
	if endingData.name == "True Survivor" then
		endingTitle.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	elseif endingData.name == "Hero" then
		endingTitle.TextColor3 = Color3.fromRGB(100, 200, 100) -- Green
	elseif endingData.name == "Survivor" then
		endingTitle.TextColor3 = Color3.fromRGB(150, 150, 255) -- Blue
	else
		endingTitle.TextColor3 = Color3.fromRGB(200, 100, 100) -- Red
	end

	-- Format play time
	local minutes = math.floor(endingData.playTime / 60)
	local seconds = math.floor(endingData.playTime % 60)
	local hours = math.floor(minutes / 60)
	minutes = minutes % 60

	local timeString
	if hours > 0 then
		timeString = string.format("%d:%02d:%02d", hours, minutes, seconds)
	else
		timeString = string.format("%d:%02d", minutes, seconds)
	end

	-- Set stats
	survivorsStat.Text = string.format("Survivors Rescued: %d/%d", endingData.survivorsRescued, Shared.Config.OBJECTIVES.SURVIVORS_TOTAL)
	timeStat.Text = string.format("Completion Time: %s", timeString)
	signalStat.Text = string.format("Signal Parts: %d/%d", endingData.signalPartsCollected, Shared.Config.OBJECTIVES.SIGNAL_PARTS_TOTAL)

	-- Add ending suffix to credits
	local fullCredits = table.concat(CreditsText, "\n") .. "\n\n\n" .. endingData.creditsSuffix
	creditsText.Text = fullCredits

	-- Animate elements
	background.BackgroundTransparency = 1
	TweenService:Create(background, TweenInfo.new(2), { BackgroundTransparency = 0 }):Play()

	-- Fade in title
	endingTitle.TextTransparency = 1
	task.delay(1, function()
		TweenService:Create(endingTitle, TweenInfo.new(2), { TextTransparency = 0 }):Play()
	end)

	-- Fade in subtitle
	endingSubtitle.TextTransparency = 1
	task.delay(2, function()
		TweenService:Create(endingSubtitle, TweenInfo.new(1.5), { TextTransparency = 0 }):Play()
	end)

	-- Fade in stats
	statsFrame.BackgroundTransparency = 1
	survivorsStat.TextTransparency = 1
	timeStat.TextTransparency = 1
	signalStat.TextTransparency = 1
	task.delay(4, function()
		TweenService:Create(statsFrame, TweenInfo.new(1), { BackgroundTransparency = 0.5 }):Play()
		TweenService:Create(survivorsStat, TweenInfo.new(1), { TextTransparency = 0 }):Play()
		TweenService:Create(timeStat, TweenInfo.new(1), { TextTransparency = 0 }):Play()
		TweenService:Create(signalStat, TweenInfo.new(1), { TextTransparency = 0 }):Play()
	end)

	-- Start credits scroll after delay
	task.delay(6, function()
		creditsText.Position = UDim2.new(0, 0, 1, 0)
		TweenService:Create(creditsText, TweenInfo.new(30, Enum.EasingStyle.Linear), {
			Position = UDim2.new(0, 0, -1, 0),
		}):Play()
	end)

	-- Show continue button after credits
	task.delay(40, function()
		continueButton.Visible = true
		continueButton.BackgroundTransparency = 1
		continueButton.TextTransparency = 1
		TweenService:Create(continueButton, TweenInfo.new(1), {
			BackgroundTransparency = 0,
			TextTransparency = 0,
		}):Play()
	end)

	print("[CreditsController] Showing ending:", endingData.name)
end

function CreditsController:Hide()
	if not isShowing then
		return
	end
	isShowing = false

	local background = screenGui:FindFirstChild("Background") :: Frame
	TweenService:Create(background, TweenInfo.new(1), { BackgroundTransparency = 1 }):Play()

	task.delay(1, function()
		screenGui.Enabled = false
	end)

	print("[CreditsController] Credits hidden")
end

function CreditsController:IsShowing(): boolean
	return isShowing
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function CreditsController:Initialize()
	self:CreateCreditsUI()

	-- Listen for game complete event from server
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local storyEvent = remotes:WaitForChild("StoryEvent", 5)

	if storyEvent then
		(storyEvent :: RemoteEvent).OnClientEvent:Connect(function(event)
			if event.type == "game_complete" then
				-- Show credits with ending data
				self:Show({
					name = event.ending.name,
					description = event.ending.description,
					creditsSuffix = event.ending.creditsSuffix,
					playTime = event.playTime,
					survivorsRescued = event.survivorsRescued,
					signalPartsCollected = event.signalPartsCollected,
				})
			end
		end)
	end

	print("[CreditsController] Initialized")
end

return CreditsController
