--!strict
-- Faultline Fear: Hunger Service
-- Core survival mechanic - hunger depletion and food consumption

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config

export type HungerData = {
	current: number,
	max: number,
	isStarving: boolean,
	isSlow: boolean,
	isBlurred: boolean,
}

local HungerService = {}

-- Player hunger state
local playerHunger: { [Player]: number } = {}
local playerStates: { [Player]: { sprinting: boolean, swimming: boolean } } = {}
local lastHungerUpdate: { [Player]: number } = {} -- Track last update time to throttle

-- Remote events (set during initialization)
local HungerUpdate: RemoteEvent = nil :: any

-- Throttle updates to once per second to avoid flooding client
local UPDATE_INTERVAL = 1.0

-- ==========================================
-- CORE FUNCTIONS
-- ==========================================

--[[
	Initialize a player's hunger state.
]]
function HungerService:InitPlayer(player: Player)
	playerHunger[player] = Config.HUNGER.MAX
	playerStates[player] = { sprinting = false, swimming = false }

	print("[HungerService] Initialized player:", player.Name, "Hunger:", Config.HUNGER.MAX)

	-- Send initial hunger to client (force immediate)
	self:SendHungerUpdate(player, true)
end

--[[
	Clean up a player's hunger state.
]]
function HungerService:CleanupPlayer(player: Player)
	playerHunger[player] = nil
	playerStates[player] = nil
	lastHungerUpdate[player] = nil
	print("[HungerService] Cleaned up player:", player.Name)
end

--[[
	Get a player's current hunger.
]]
function HungerService:GetHunger(player: Player): number
	return playerHunger[player] or 0
end

--[[
	Modify a player's hunger by an amount (positive = feed, negative = drain).
]]
function HungerService:ModifyHunger(player: Player, amount: number)
	local current = playerHunger[player]
	if not current then
		return
	end

	local newHunger = math.clamp(current + amount, 0, Config.HUNGER.MAX)
	playerHunger[player] = newHunger

	-- Check for death
	if newHunger <= Config.HUNGER.DEATH_THRESHOLD then
		self:OnPlayerStarved(player)
	end

	-- Update client
	self:SendHungerUpdate(player)
end

--[[
	Set a player's sprinting state (affects hunger drain rate).
]]
function HungerService:SetSprinting(player: Player, sprinting: boolean)
	local state = playerStates[player]
	if state then
		state.sprinting = sprinting
	end
end

--[[
	Set a player's swimming state (affects hunger drain rate).
]]
function HungerService:SetSwimming(player: Player, swimming: boolean)
	local state = playerStates[player]
	if state then
		state.swimming = swimming
	end
end

--[[
	Check if a player is starving (hunger at 0).
]]
function HungerService:IsStarving(player: Player): boolean
	return (playerHunger[player] or 0) <= Config.HUNGER.DEATH_THRESHOLD
end

--[[
	Check if a player should have slowed movement.
]]
function HungerService:ShouldSlowPlayer(player: Player): boolean
	return (playerHunger[player] or 100) < Config.HUNGER.SLOW_THRESHOLD
end

--[[
	Check if a player should have blurred vision.
]]
function HungerService:ShouldBlurVision(player: Player): boolean
	return (playerHunger[player] or 100) < Config.HUNGER.BLUR_THRESHOLD
end

--[[
	Get full hunger data for a player.
]]
function HungerService:GetHungerData(player: Player): HungerData
	local hunger = playerHunger[player] or 0
	return {
		current = hunger,
		max = Config.HUNGER.MAX,
		isStarving = hunger <= Config.HUNGER.DEATH_THRESHOLD,
		isSlow = hunger < Config.HUNGER.SLOW_THRESHOLD,
		isBlurred = hunger < Config.HUNGER.BLUR_THRESHOLD,
	}
end

-- ==========================================
-- FOOD SYSTEM
-- ==========================================

--[[
	Have a player eat a food item.
	Food items must have a "HungerRestore" attribute.
]]
function HungerService:EatFood(player: Player, foodItem: BasePart): boolean
	local restoreAmount = foodItem:GetAttribute("HungerRestore")
	if not restoreAmount or typeof(restoreAmount) ~= "number" then
		warn("[HungerService] Food item missing HungerRestore attribute:", foodItem:GetFullName())
		return false
	end

	-- Restore hunger
	self:ModifyHunger(player, restoreAmount)

	print(
		"[HungerService]",
		player.Name,
		"ate",
		foodItem.Name,
		"Restored:",
		restoreAmount,
		"New hunger:",
		playerHunger[player]
	)

	-- Destroy the food item
	foodItem:Destroy()

	return true
end

--[[
	Setup food pickup collision detection for a food item.
]]
function HungerService:SetupFoodItem(foodItem: BasePart)
	if not foodItem:GetAttribute("HungerRestore") then
		warn("[HungerService] Food item missing HungerRestore attribute:", foodItem:GetFullName())
		return
	end

	-- Create touch trigger if not present
	foodItem.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)
		if player and playerHunger[player] then
			self:EatFood(player, foodItem)
		end
	end)
end

-- ==========================================
-- HUNGER TICK
-- ==========================================

local function hungerTick(deltaTime: number)
	for player, hunger in pairs(playerHunger) do
		if hunger <= Config.HUNGER.DEATH_THRESHOLD then
			continue
		end

		local state = playerStates[player]
		local drainRate = Config.HUNGER.DECAY_RATE

		-- Apply multipliers
		if state then
			if state.sprinting then
				drainRate *= Config.HUNGER.SPRINT_MULTIPLIER
			end
			if state.swimming then
				drainRate *= Config.HUNGER.SWIM_MULTIPLIER
			end
		end

		-- Drain hunger
		local drainAmount = drainRate * deltaTime
		HungerService:ModifyHunger(player, -drainAmount)
	end
end

-- ==========================================
-- STARVATION HANDLING
-- ==========================================

function HungerService:OnPlayerStarved(player: Player)
	print("[HungerService] Player starved:", player.Name)

	-- Kill the player's character
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end
end

--[[
	Called when a player respawns - reset hunger to respawn value.
]]
function HungerService:OnPlayerRespawned(player: Player)
	playerHunger[player] = Config.HUNGER.RESPAWN_HUNGER
	print("[HungerService] Player respawned with hunger:", Config.HUNGER.RESPAWN_HUNGER)
	self:SendHungerUpdate(player, true) -- Force immediate update on respawn
end

-- ==========================================
-- CLIENT COMMUNICATION
-- ==========================================

function HungerService:SendHungerUpdate(player: Player, force: boolean?)
	if not HungerUpdate then
		return
	end

	local now = tick()
	local lastUpdate = lastHungerUpdate[player] or 0

	-- Throttle updates unless forced (respawn, eating, etc.)
	if not force and (now - lastUpdate) < UPDATE_INTERVAL then
		return
	end

	lastHungerUpdate[player] = now
	HungerUpdate:FireClient(player, self:GetHungerData(player))
end

-- ==========================================
-- SWIMMING DETECTION
-- ==========================================

local function setupSwimmingDetection(player: Player)
	local function checkSwimming(character: Model)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
				local isInWater = humanoid.FloorMaterial == Enum.Material.Water
				HungerService:SetSwimming(player, isInWater)
			end)
		end
	end

	if player.Character then
		checkSwimming(player.Character)
	end
	player.CharacterAdded:Connect(checkSwimming)
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function HungerService:Initialize()
	-- Get remote event
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	HungerUpdate = remotes:WaitForChild("HungerUpdate") :: RemoteEvent

	-- Connect player events
	Players.PlayerAdded:Connect(function(player)
		self:InitPlayer(player)
		setupSwimmingDetection(player)

		player.CharacterAdded:Connect(function()
			self:OnPlayerRespawned(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayer(player)
	end)

	-- Init existing players
	for _, player in Players:GetPlayers() do
		self:InitPlayer(player)
		setupSwimmingDetection(player)
	end

	-- Start hunger tick
	RunService.Heartbeat:Connect(hungerTick)

	print("[HungerService] Initialized")
end

return HungerService
