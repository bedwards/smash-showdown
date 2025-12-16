--!strict
--[[
	Faultline Fear: Dialogue Controller

	Client-side UI for displaying NPC dialogue.
	Features:
	- Speaker name and portrait
	- Typewriter text effect
	- Tap/click to advance
	- Mobile-friendly bottom bar design

	Exports: Initialize(), ShowDialogue(), Hide()
	Depends: StoryData, RemoteEvents
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local StoryData = Shared.StoryData

local DialogueController = {}

-- UI Elements
local screenGui: ScreenGui = nil :: any
local dialogueFrame: Frame = nil :: any
local speakerLabel: TextLabel = nil :: any
local dialogueText: TextLabel = nil :: any
local continueHint: TextLabel = nil :: any

-- State
local isShowing = false
local currentLines: { string } = {}
local currentLineIndex = 0
local isTyping = false
local skipTyping = false

-- Config
local TYPEWRITER_SPEED = 0.03 -- seconds per character
local FADE_TIME = 0.3

-- ==========================================
-- UI CREATION
-- ==========================================

function DialogueController:CreateUI()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Main ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FaultlineFearDialogue"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 50 -- Above HUD, below credits
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Dialogue frame (bottom bar)
	dialogueFrame = Instance.new("Frame")
	dialogueFrame.Name = "DialogueFrame"
	dialogueFrame.Size = UDim2.new(1, 0, 0, 150)
	dialogueFrame.Position = UDim2.new(0, 0, 1, 0) -- Start off-screen
	dialogueFrame.AnchorPoint = Vector2.new(0, 1)
	dialogueFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	dialogueFrame.BackgroundTransparency = 0.1
	dialogueFrame.BorderSizePixel = 0
	dialogueFrame.Parent = screenGui

	-- Top border accent
	local topBorder = Instance.new("Frame")
	topBorder.Name = "TopBorder"
	topBorder.Size = UDim2.new(1, 0, 0, 3)
	topBorder.Position = UDim2.new(0, 0, 0, 0)
	topBorder.BackgroundColor3 = Color3.fromRGB(200, 150, 50) -- Gold accent
	topBorder.BorderSizePixel = 0
	topBorder.Parent = dialogueFrame

	-- Speaker name
	speakerLabel = Instance.new("TextLabel")
	speakerLabel.Name = "SpeakerLabel"
	speakerLabel.Size = UDim2.new(1, -40, 0, 30)
	speakerLabel.Position = UDim2.new(0, 20, 0, 10)
	speakerLabel.BackgroundTransparency = 1
	speakerLabel.TextColor3 = Color3.fromRGB(200, 150, 50) -- Gold
	speakerLabel.TextSize = 20
	speakerLabel.Font = Enum.Font.GothamBold
	speakerLabel.Text = "Speaker"
	speakerLabel.TextXAlignment = Enum.TextXAlignment.Left
	speakerLabel.Parent = dialogueFrame

	-- Dialogue text
	dialogueText = Instance.new("TextLabel")
	dialogueText.Name = "DialogueText"
	dialogueText.Size = UDim2.new(1, -40, 0, 70)
	dialogueText.Position = UDim2.new(0, 20, 0, 45)
	dialogueText.BackgroundTransparency = 1
	dialogueText.TextColor3 = Color3.fromRGB(230, 230, 230)
	dialogueText.TextSize = 18
	dialogueText.Font = Enum.Font.Gotham
	dialogueText.Text = ""
	dialogueText.TextXAlignment = Enum.TextXAlignment.Left
	dialogueText.TextYAlignment = Enum.TextYAlignment.Top
	dialogueText.TextWrapped = true
	dialogueText.Parent = dialogueFrame

	-- Continue hint
	continueHint = Instance.new("TextLabel")
	continueHint.Name = "ContinueHint"
	continueHint.Size = UDim2.new(1, -40, 0, 20)
	continueHint.Position = UDim2.new(0, 20, 1, -30)
	continueHint.BackgroundTransparency = 1
	continueHint.TextColor3 = Color3.fromRGB(150, 150, 150)
	continueHint.TextSize = 14
	continueHint.Font = Enum.Font.Gotham
	continueHint.Text = "Tap to continue..."
	continueHint.TextXAlignment = Enum.TextXAlignment.Right
	continueHint.Parent = dialogueFrame

	-- Click/tap handler
	local clickDetector = Instance.new("TextButton")
	clickDetector.Name = "ClickDetector"
	clickDetector.Size = UDim2.new(1, 0, 1, 0)
	clickDetector.BackgroundTransparency = 1
	clickDetector.Text = ""
	clickDetector.Parent = dialogueFrame

	clickDetector.MouseButton1Click:Connect(function()
		self:OnAdvance()
	end)

	-- Keyboard handler
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if not isShowing then return end

		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return then
			self:OnAdvance()
		end
	end)

	print("[DialogueController] UI created")
end

-- ==========================================
-- TYPEWRITER EFFECT
-- ==========================================

local function typewriterEffect(text: string): ()
	isTyping = true
	skipTyping = false
	dialogueText.Text = ""
	continueHint.Visible = false

	for i = 1, #text do
		if skipTyping then
			dialogueText.Text = text
			break
		end

		dialogueText.Text = string.sub(text, 1, i)
		task.wait(TYPEWRITER_SPEED)
	end

	isTyping = false
	continueHint.Visible = true

	-- Animate continue hint
	local hintTween = TweenService:Create(continueHint, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		TextTransparency = 0.5,
	})
	hintTween:Play()
end

-- ==========================================
-- DIALOGUE FLOW
-- ==========================================

function DialogueController:OnAdvance()
	if not isShowing then return end

	if isTyping then
		-- Skip typewriter, show full text
		skipTyping = true
		return
	end

	-- Move to next line
	currentLineIndex += 1

	if currentLineIndex <= #currentLines then
		-- Show next line
		task.spawn(typewriterEffect, currentLines[currentLineIndex])
	else
		-- End of dialogue
		self:Hide()
	end
end

function DialogueController:ShowDialogue(dialogueId: string)
	local dialogue = StoryData.GetDialogue(dialogueId)
	if not dialogue then
		warn("[DialogueController] Unknown dialogue:", dialogueId)
		return
	end

	self:ShowDialogueData({
		name = dialogue.name,
		lines = dialogue.lines,
	})
end

function DialogueController:ShowDialogueData(data: { name: string, lines: { string } })
	if isShowing then
		-- Queue or replace? For now, replace
		self:Hide()
		task.wait(FADE_TIME + 0.1)
	end

	isShowing = true
	currentLines = data.lines
	currentLineIndex = 1

	-- Set speaker name
	speakerLabel.Text = data.name

	-- Show UI
	screenGui.Enabled = true
	dialogueFrame.Position = UDim2.new(0, 0, 1, 0)

	-- Slide up animation
	TweenService:Create(dialogueFrame, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 1, -150),
	}):Play()

	-- Start first line
	task.spawn(typewriterEffect, currentLines[1])

	print("[DialogueController] Showing dialogue:", data.name)
end

function DialogueController:Hide()
	if not isShowing then return end

	isShowing = false
	currentLines = {}
	currentLineIndex = 0

	-- Slide down animation
	TweenService:Create(dialogueFrame, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0, 0, 1, 0),
	}):Play()

	task.delay(FADE_TIME, function()
		if not isShowing then
			screenGui.Enabled = false
		end
	end)

	print("[DialogueController] Dialogue hidden")
end

function DialogueController:IsShowing(): boolean
	return isShowing
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function DialogueController:Initialize()
	self:CreateUI()

	-- Listen for dialogue events from server
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local dialogueEvent = remotes:WaitForChild("DialogueEvent", 5)

	if dialogueEvent then
		(dialogueEvent :: RemoteEvent).OnClientEvent:Connect(function(data)
			if data.dialogueId then
				self:ShowDialogue(data.dialogueId)
			elseif data.name and data.lines then
				self:ShowDialogueData(data)
			end
		end)
	end

	print("[DialogueController] Initialized")
end

return DialogueController
