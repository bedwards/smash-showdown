--!strict
-- Respawn System for Mertin-Flemmer
-- When players die, respawn them 1/3 of the way back to spawn from death location

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

-- Original spawn location
local SPAWN_POSITION = Vector3.new(0, 5, -30)

-- Create remote for client notification
local RespawnRemote = Instance.new("RemoteEvent")
RespawnRemote.Name = "RespawnNotify"
RespawnRemote.Parent = ReplicatedStorage

-- Track death positions for each player
local deathPositions: { [Player]: Vector3 } = {}

-- Calculate respawn position (1/3 of the way from death to spawn)
local function calculateRespawnPosition(deathPos: Vector3): Vector3
	-- Vector from death to spawn
	local toSpawn = SPAWN_POSITION - deathPos

	-- Move 1/3 of the way toward spawn
	local respawnPos = deathPos + (toSpawn * (1/3))

	-- Get terrain height at respawn position
	local terrainHeight = Shared.getTerrainHeight(respawnPos.X, respawnPos.Z)

	-- Ensure we're above ground
	respawnPos = Vector3.new(respawnPos.X, terrainHeight + 5, respawnPos.Z)

	return respawnPos
end

-- Handle player death
local function onCharacterDied(player: Player, character: Model)
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if rootPart then
		deathPositions[player] = rootPart.Position
		print("[Respawn]", player.Name, "died at", rootPart.Position)
	end
end

-- Handle character spawning
local function onCharacterAdded(player: Player, character: Model)
	-- Wait for humanoid
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

	-- Check if this is a respawn (we have a death position)
	local deathPos = deathPositions[player]
	if deathPos then
		-- Calculate respawn position
		local respawnPos = calculateRespawnPosition(deathPos)

		-- Small delay to let character fully load
		task.wait(0.1)

		-- Teleport to respawn position
		rootPart.CFrame = CFrame.new(respawnPos)

		-- Calculate how far back they went (as percentage)
		local distanceFromSpawn = (deathPos - SPAWN_POSITION).Magnitude
		local distanceLost = (respawnPos - deathPos).Magnitude

		-- Notify client
		RespawnRemote:FireClient(player, {
			deathPosition = deathPos,
			respawnPosition = respawnPos,
			distanceLost = math.floor(distanceLost),
			progressKept = 67, -- They keep 2/3 of their progress
		})

		print("[Respawn]", player.Name, "respawned at", respawnPos, "(1/3 way back from", deathPos, ")")

		-- Clear death position after respawn
		deathPositions[player] = nil
	end

	-- Listen for death
	humanoid.Died:Connect(function()
		onCharacterDied(player, character)
	end)
end

-- Setup player
local function setupPlayer(player: Player)
	-- Handle existing character
	if player.Character then
		onCharacterAdded(player, player.Character)
	end

	-- Handle future characters
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end

-- Cleanup player
local function cleanupPlayer(player: Player)
	deathPositions[player] = nil
end

-- Connect events
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(cleanupPlayer)

-- Setup existing players
for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

print("[Respawn] Respawn system initialized - players respawn 1/3 way back to spawn!")
