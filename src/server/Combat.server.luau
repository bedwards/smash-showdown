--!strict
-- Combat server - validates hits, applies damage, handles knockback
-- Server authoritative combat to prevent cheating

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local CombatConfig = Shared.Config

-- Combat stats
local COMBO_DAMAGE = { 3, 3, 4, 4 } -- Damage per hit in combo
local COMBO_KNOCKBACK = { 10, 10, 15, 30 } -- Knockback per hit
local COMBO_HITSTUN = { 0.15, 0.15, 0.2, 0.3 } -- Hitstun duration
local HIT_RANGE = 6
local COMBO_TIMEOUT = 0.8

-- Player combat state
local playerState: { [Player]: {
	combo: number,
	lastHitTime: number,
	isStunned: boolean,
	stunEndTime: number,
} } = {}

-- Create RemoteEvents
local function setupRemotes()
	local attackRemote = Instance.new("RemoteEvent")
	attackRemote.Name = "Attack"
	attackRemote.Parent = ReplicatedStorage

	local combatUpdateRemote = Instance.new("RemoteEvent")
	combatUpdateRemote.Name = "CombatUpdate"
	combatUpdateRemote.Parent = ReplicatedStorage

	return attackRemote, combatUpdateRemote
end

local AttackRemote, CombatUpdateRemote = setupRemotes()

-- Initialize player state
local function initPlayerState(player: Player)
	playerState[player] = {
		combo = 0,
		lastHitTime = 0,
		isStunned = false,
		stunEndTime = 0,
	}
end

-- Clean up player state
local function cleanupPlayerState(player: Player)
	playerState[player] = nil
end

-- Check if player can act
local function canAct(player: Player): boolean
	local state = playerState[player]
	if not state then return false end

	if state.isStunned and tick() < state.stunEndTime then
		return false
	end

	state.isStunned = false
	return true
end

-- Apply hitstun to player
local function applyHitstun(player: Player, duration: number)
	local state = playerState[player]
	if not state then return end

	state.isStunned = true
	state.stunEndTime = tick() + duration

	-- Notify client
	CombatUpdateRemote:FireClient(player, "stunned", duration)
end

-- Apply knockback to character
local function applyKnockback(character: Model, direction: Vector3, force: number)
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	local knockback = Instance.new("BodyVelocity")
	knockback.MaxForce = Vector3.new(50000, 50000, 50000)
	knockback.Velocity = direction * force + Vector3.new(0, force * 0.5, 0)
	knockback.Parent = rootPart

	task.delay(0.15, function()
		knockback:Destroy()
	end)
end

-- Find targets in range
local function getTargetsInRange(attacker: Player, range: number): { Player }
	local targets = {}
	local attackerChar = attacker.Character
	if not attackerChar then return targets end

	local attackerRoot = attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not attackerRoot then return targets end

	local attackerPos = attackerRoot.Position
	local attackerLook = attackerRoot.CFrame.LookVector

	for _, player in Players:GetPlayers() do
		if player == attacker then continue end

		local character = player.Character
		if not character then continue end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then continue end

		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not rootPart then continue end

		local toTarget = rootPart.Position - attackerPos
		local distance = toTarget.Magnitude

		-- Check range
		if distance > range then continue end

		-- Check if target is in front (180 degree arc)
		local dot = attackerLook:Dot(toTarget.Unit)
		if dot < 0 then continue end

		table.insert(targets, player)
	end

	return targets
end

-- Process attack
local function processAttack(attacker: Player, attackType: string)
	if not canAct(attacker) then return end

	local state = playerState[attacker]
	if not state then return end

	local attackerChar = attacker.Character
	if not attackerChar then return end

	local attackerRoot = attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not attackerRoot then return end

	-- Update combo
	local now = tick()
	if now - state.lastHitTime > COMBO_TIMEOUT then
		state.combo = 0
	end

	state.combo = math.min(state.combo + 1, 4)
	state.lastHitTime = now

	local comboIndex = state.combo
	local damage = COMBO_DAMAGE[comboIndex]
	local knockbackForce = COMBO_KNOCKBACK[comboIndex]
	local hitstun = COMBO_HITSTUN[comboIndex]

	-- Heavy attack modifier
	if attackType == "heavy" then
		damage = damage * 2
		knockbackForce = knockbackForce * 1.5
		hitstun = hitstun * 1.5
		state.combo = 0 -- Heavy resets combo
	end

	-- Find and damage targets
	local targets = getTargetsInRange(attacker, HIT_RANGE)
	local hitAnyone = false

	for _, target in targets do
		local targetChar = target.Character
		if not targetChar then continue end

		local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
		local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not targetHumanoid or not targetRoot then continue end

		-- Deal damage
		targetHumanoid:TakeDamage(damage)

		-- Apply hitstun
		applyHitstun(target, hitstun)

		-- Apply knockback
		local knockbackDir = (targetRoot.Position - attackerRoot.Position).Unit
		applyKnockback(targetChar, knockbackDir, knockbackForce)

		-- Notify clients
		CombatUpdateRemote:FireAllClients("hit", {
			attacker = attacker.Name,
			target = target.Name,
			damage = damage,
			combo = comboIndex,
			position = targetRoot.Position,
			isFinalHit = comboIndex == 4,
		})

		hitAnyone = true
		print("[Combat]", attacker.Name, "hit", target.Name, "Combo:", comboIndex, "Damage:", damage)
	end

	-- Notify attacker of swing (for animation)
	CombatUpdateRemote:FireClient(attacker, "swing", {
		combo = comboIndex,
		hitAnyone = hitAnyone,
		attackType = attackType,
	})

	-- Reset combo if no hit on final swing
	if not hitAnyone and comboIndex == 4 then
		state.combo = 0
	end
end

-- Handle attack requests from clients
AttackRemote.OnServerEvent:Connect(function(player: Player, attackType: string)
	if attackType ~= "light" and attackType ~= "heavy" then return end
	processAttack(player, attackType)
end)

-- Player connections
Players.PlayerAdded:Connect(initPlayerState)
Players.PlayerRemoving:Connect(cleanupPlayerState)

-- Initialize existing players
for _, player in Players:GetPlayers() do
	initPlayerState(player)
end

print("[Combat] Server initialized!")
