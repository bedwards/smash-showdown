--!strict
-- Game UI for Smash Showdown
-- Health bars, combo counter, KO feed

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Wait for remotes
local HealthUpdateRemote = ReplicatedStorage:WaitForChild("HealthUpdate") :: RemoteEvent
local KORemote = ReplicatedStorage:WaitForChild("KO") :: RemoteEvent

-- Create main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SmashShowdownUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Health bar storage
local healthBars: { [string]: Frame } = {}

-- Create player health bar (overhead)
local function createHealthBar(playerName: string): Frame
	local container = Instance.new("Frame")
	container.Name = playerName .. "_HealthBar"
	container.Size = UDim2.new(0, 100, 0, 12)
	container.Position = UDim2.new(0.5, -50, 0, 50)
	container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	container.BorderSizePixel = 0
	container.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = container

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, -4, 1, -4)
	fill.Position = UDim2.new(0, 2, 0, 2)
	fill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	fill.BorderSizePixel = 0
	fill.Parent = container

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 2)
	fillCorner.Parent = fill

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.Position = UDim2.new(0, 0, 0, -18)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = playerName
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.Parent = container

	-- Make it a BillboardGui for 3D positioning
	container.Visible = false -- Will use billboard instead

	return container
end

-- Create overhead health bar (BillboardGui)
local function createOverheadHealthBar(character: Model, playerName: string)
	local head = character:WaitForChild("Head", 5)
	if not head then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.new(0, 80, 0, 20)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = false
	billboard.Adornee = head
	billboard.Parent = character

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 8)
	container.Position = UDim2.new(0, 0, 1, -8)
	container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	container.BorderSizePixel = 0
	container.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = container

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, -2, 1, -2)
	fill.Position = UDim2.new(0, 1, 0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
	fill.BorderSizePixel = 0
	fill.Parent = container

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 2)
	fillCorner.Parent = fill

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 12)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = playerName
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 11
	nameLabel.Parent = billboard

	return billboard
end

-- Update health bar fill
local function updateHealthBar(playerName: string, health: number, maxHealth: number)
	-- Find the player's character
	local player = Players:FindFirstChild(playerName)
	if not player or not player:IsA("Player") then return end

	local character = player.Character
	if not character then return end

	local billboard = character:FindFirstChild("HealthBar") :: BillboardGui?
	if not billboard then
		billboard = createOverheadHealthBar(character, playerName)
	end

	if billboard then
		local container = billboard:FindFirstChildOfClass("Frame")
		if container then
			local fill = container:FindFirstChild("Fill") :: Frame?
			if fill then
				local healthPercent = math.clamp(health / maxHealth, 0, 1)

				-- Animate health bar
				TweenService:Create(fill, TweenInfo.new(0.2), {
					Size = UDim2.new(healthPercent, -2, 1, -2),
				}):Play()

				-- Color based on health
				local color
				if healthPercent > 0.6 then
					color = Color3.fromRGB(80, 220, 80) -- Green
				elseif healthPercent > 0.3 then
					color = Color3.fromRGB(220, 200, 50) -- Yellow
				else
					color = Color3.fromRGB(220, 60, 60) -- Red
				end

				TweenService:Create(fill, TweenInfo.new(0.2), {
					BackgroundColor3 = color,
				}):Play()
			end
		end
	end
end

-- KO Feed
local koFeed = Instance.new("Frame")
koFeed.Name = "KOFeed"
koFeed.Size = UDim2.new(0, 300, 0, 200)
koFeed.Position = UDim2.new(1, -310, 0, 10)
koFeed.BackgroundTransparency = 1
koFeed.Parent = screenGui

local koLayout = Instance.new("UIListLayout")
koLayout.SortOrder = Enum.SortOrder.LayoutOrder
koLayout.VerticalAlignment = Enum.VerticalAlignment.Top
koLayout.Padding = UDim.new(0, 4)
koLayout.Parent = koFeed

local function showKOMessage(victimName: string)
	local message = Instance.new("TextLabel")
	message.Size = UDim2.new(1, 0, 0, 24)
	message.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	message.BackgroundTransparency = 0.3
	message.Text = "💀 " .. victimName .. " was KO'd!"
	message.TextColor3 = Color3.fromRGB(255, 100, 100)
	message.Font = Enum.Font.GothamBold
	message.TextSize = 14
	message.TextXAlignment = Enum.TextXAlignment.Right
	message.Parent = koFeed

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = message

	-- Fade out and remove
	task.delay(3, function()
		TweenService:Create(message, TweenInfo.new(0.5), {
			TextTransparency = 1,
			BackgroundTransparency = 1,
		}):Play()
		task.delay(0.5, function()
			message:Destroy()
		end)
	end)
end

-- Controls hint
local controlsHint = Instance.new("TextLabel")
controlsHint.Size = UDim2.new(0, 400, 0, 30)
controlsHint.Position = UDim2.new(0.5, -200, 1, -40)
controlsHint.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
controlsHint.BackgroundTransparency = 0.5
controlsHint.Text = "WASD: Move | Space: Jump | Q: Dash | F: Block | LMB: Attack | E: Hit Ball"
controlsHint.TextColor3 = Color3.new(1, 1, 1)
controlsHint.Font = Enum.Font.Gotham
controlsHint.TextSize = 12
controlsHint.Parent = screenGui

local controlsCorner = Instance.new("UICorner")
controlsCorner.CornerRadius = UDim.new(0, 6)
controlsCorner.Parent = controlsHint

-- Handle health updates
HealthUpdateRemote.OnClientEvent:Connect(function(data: { player: string, health: number, maxHealth: number })
	updateHealthBar(data.player, data.health, data.maxHealth)
end)

-- Handle KO events
KORemote.OnClientEvent:Connect(function(data: { victim: string, deaths: number })
	showKOMessage(data.victim)
end)

-- Setup overhead health bars for existing players
local function onCharacterAdded(character: Model)
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		task.wait(0.5) -- Wait for character to fully load
		createOverheadHealthBar(character, player.Name)
	end
end

for _, player in Players:GetPlayers() do
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end)

print("[UI] Initialized!")
