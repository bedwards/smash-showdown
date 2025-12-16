--!strict
--[[
	Faultline Fear: Flashlight Service (Server)

	Manages flashlight battery and state synchronization.

	Features:
	- Battery drain while flashlight is on
	- Battery collectible integration
	- State sync between players
	- Creature attraction (risk/reward)

	Exports: Initialize(), GetBattery(), AddBattery()
	Depends: Config
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local _Config = Shared.Config -- May be used for flashlight tuning

local FlashlightService = {}

-- State
local playerBattery: { [Player]: number } = {}
local playerFlashlightOn: { [Player]: boolean } = {}

-- Constants
local MAX_BATTERY = 100
local BATTERY_DRAIN_PER_SECOND = 100 / (5 * 60) -- 5 minutes of use
local BATTERY_COLLECTIBLE_AMOUNT = 25 -- How much battery a collectible gives

-- Remote events
local Remotes: Folder = nil :: any
local FlashlightToggle: RemoteEvent = nil :: any
local FlashlightUpdate: RemoteEvent = nil :: any

-- External service references
local _CreatureService: any = nil -- Set via SetCreatureService, for future creature attraction

-- ==========================================
-- STATE SYNC
-- ==========================================

local function broadcastFlashlightState(player: Player, enabled: boolean)
	-- Tell all other players about this player's flashlight state
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= player then
			FlashlightUpdate:FireClient(otherPlayer, "playerToggle", {
				player = player,
				enabled = enabled,
			})
		end
	end
end

-- ==========================================
-- BATTERY MANAGEMENT
-- ==========================================

local function drainBattery(player: Player, dt: number)
	if not playerFlashlightOn[player] then return end

	local current = playerBattery[player] or MAX_BATTERY
	local newBattery = math.max(0, current - BATTERY_DRAIN_PER_SECOND * dt)

	if newBattery ~= current then
		playerBattery[player] = newBattery

		-- Notify client of battery change
		FlashlightUpdate:FireClient(player, "battery", newBattery)

		-- Auto turn off if depleted
		if newBattery <= 0 then
			playerFlashlightOn[player] = false
			broadcastFlashlightState(player, false)
		end
	end
end

local function updateAllBatteries(dt: number)
	for player in pairs(playerFlashlightOn) do
		if player.Parent then -- Still in game
			drainBattery(player, dt)
		end
	end
end

-- ==========================================
-- TOGGLE HANDLING
-- ==========================================

local function onFlashlightToggle(player: Player, enabled: boolean)
	-- Validate battery
	local battery = playerBattery[player] or MAX_BATTERY
	if enabled and battery <= 0 then
		-- Can't turn on with no battery
		FlashlightUpdate:FireClient(player, "battery", 0)
		return
	end

	playerFlashlightOn[player] = enabled
	broadcastFlashlightState(player, enabled)

	-- Note: Creature attraction when flashlight is on would be handled by CreatureService
	-- This creates risk/reward - light helps you see but attracts danger

	print(string.format("[FlashlightService] %s flashlight: %s", player.Name, enabled and "ON" or "OFF"))
end

-- ==========================================
-- PLAYER HANDLING
-- ==========================================

local function onPlayerAdded(player: Player)
	-- Initialize battery
	playerBattery[player] = MAX_BATTERY
	playerFlashlightOn[player] = false
end

local function onPlayerRemoving(player: Player)
	-- Clean up
	playerBattery[player] = nil
	playerFlashlightOn[player] = nil
end

-- ==========================================
-- PUBLIC API
-- ==========================================

function FlashlightService:GetBattery(player: Player): number
	return playerBattery[player] or MAX_BATTERY
end

function FlashlightService:SetBattery(player: Player, amount: number)
	playerBattery[player] = math.clamp(amount, 0, MAX_BATTERY)
	FlashlightUpdate:FireClient(player, "battery", playerBattery[player])
end

function FlashlightService:AddBattery(player: Player, amount: number)
	local current = playerBattery[player] or MAX_BATTERY
	self:SetBattery(player, current + amount)
end

function FlashlightService:CollectBattery(player: Player)
	-- Called when player collects a battery item
	self:AddBattery(player, BATTERY_COLLECTIBLE_AMOUNT)
	print(string.format("[FlashlightService] %s collected battery (+%d%%)", player.Name, BATTERY_COLLECTIBLE_AMOUNT))
end

function FlashlightService:IsFlashlightOn(player: Player): boolean
	return playerFlashlightOn[player] or false
end

function FlashlightService:SetCreatureService(service: any)
	_CreatureService = service
end

function FlashlightService:Initialize()
	-- Get/create remotes
	Remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder

	-- Create flashlight-specific remotes
	FlashlightToggle = Instance.new("RemoteEvent")
	FlashlightToggle.Name = "FlashlightToggle"
	FlashlightToggle.Parent = Remotes

	FlashlightUpdate = Instance.new("RemoteEvent")
	FlashlightUpdate.Name = "FlashlightUpdate"
	FlashlightUpdate.Parent = Remotes

	-- Listen for toggle events from clients
	FlashlightToggle.OnServerEvent:Connect(onFlashlightToggle)

	-- Player handling
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Initialize existing players
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	-- Battery drain loop
	RunService.Heartbeat:Connect(updateAllBatteries)

	print("[FlashlightService] Initialized")
end

return FlashlightService
