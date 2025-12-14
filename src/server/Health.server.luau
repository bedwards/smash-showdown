--!strict
-- Health and KO system for Smash Showdown
-- Tracks player health, handles deaths, respawns, and round state

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

-- Configuration
local MAX_HEALTH = Shared.Config.BASE_HEALTH
local RESPAWN_TIME = Shared.Config.RESPAWN_TIME

-- Create RemoteEvents
local HealthUpdateRemote = Instance.new("RemoteEvent")
HealthUpdateRemote.Name = "HealthUpdate"
HealthUpdateRemote.Parent = ReplicatedStorage

local KORemote = Instance.new("RemoteEvent")
KORemote.Name = "KO"
KORemote.Parent = ReplicatedStorage

-- Track KOs
local playerKOs: { [Player]: number } = {}
local playerDeaths: { [Player]: number } = {}

-- Get spawn position based on team
local function getSpawnPosition(player: Player): Vector3
	local arena = workspace:FindFirstChild("Arena")
	if arena then
		-- Alternate spawns
		local playerIndex = 0
		for i, p in Players:GetPlayers() do
			if p == player then
				playerIndex = i
				break
			end
		end

		if playerIndex % 2 == 1 then
			local spawn1 = arena:FindFirstChild("Spawn1")
			if spawn1 and spawn1:IsA("BasePart") then
				return spawn1.Position + Vector3.new(0, 3, 0)
			end
		else
			local spawn2 = arena:FindFirstChild("Spawn2")
			if spawn2 and spawn2:IsA("BasePart") then
				return spawn2.Position + Vector3.new(0, 3, 0)
			end
		end
	end

	return Vector3.new(0, 10, 0)
end

-- Handle player death
local function onPlayerDied(player: Player, humanoid: Humanoid)
	playerDeaths[player] = (playerDeaths[player] or 0) + 1

	-- Find killer (last player to damage them)
	-- For now, broadcast KO event
	KORemote:FireAllClients({
		victim = player.Name,
		deaths = playerDeaths[player],
	})

	print("[Health]", player.Name, "was KO'd! Deaths:", playerDeaths[player])

	-- Respawn after delay
	task.delay(RESPAWN_TIME, function()
		if player and player.Parent then
			player:LoadCharacter()
		end
	end)
end

-- Setup player health tracking
local function setupPlayer(player: Player)
	playerKOs[player] = 0
	playerDeaths[player] = 0

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.MaxHealth = MAX_HEALTH
		humanoid.Health = MAX_HEALTH

		-- Broadcast initial health
		HealthUpdateRemote:FireAllClients({
			player = player.Name,
			health = humanoid.Health,
			maxHealth = humanoid.MaxHealth,
		})

		-- Track health changes
		humanoid.HealthChanged:Connect(function(newHealth)
			HealthUpdateRemote:FireAllClients({
				player = player.Name,
				health = newHealth,
				maxHealth = humanoid.MaxHealth,
			})
		end)

		-- Track death
		humanoid.Died:Connect(function()
			onPlayerDied(player, humanoid)
		end)

		-- Set spawn position
		local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
		rootPart.CFrame = CFrame.new(getSpawnPosition(player))

		print("[Health]", player.Name, "spawned with", MAX_HEALTH, "HP")
	end)
end

-- Cleanup player
local function cleanupPlayer(player: Player)
	playerKOs[player] = nil
	playerDeaths[player] = nil
end

-- Player connections
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(cleanupPlayer)

-- Initialize existing players
for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

print("[Health] System initialized!")
