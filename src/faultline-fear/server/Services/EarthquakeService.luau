--!strict
-- Faultline Fear: Earthquake Service
-- The core mechanic - periodic earthquakes that shape the world

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config

export type QuakeType = "MINOR_TREMOR" | "MODERATE" | "MAJOR" | "BIG_ONE"

export type QuakeData = {
	type: QuakeType,
	magnitude: number,
	duration: number,
	cameraShake: number,
	knockdown: boolean?,
	structuralDamage: boolean?,
	permanentChanges: boolean?,
}

local EarthquakeService = {}

-- State
local isQuakeActive: boolean = false
local currentQuake: QuakeData? = nil
local lastQuakeTimes: { [QuakeType]: number } = {}
local bigOneTriggered: boolean = false

-- Aftershock queue
local aftershockQueue: { { delay: number, magnitude: number } } = {}

-- Fall damage tracking
type LaunchedPlayer = {
	launchTime: number,
	launchY: number,
	maxY: number,
	magnitude: number,
}
local launchedPlayers: { [Player]: LaunchedPlayer } = {}

-- Fall damage config
local FALL_DAMAGE = {
	MIN_HEIGHT = 8, -- Minimum fall height to take damage (reduced from 10)
	DAMAGE_PER_STUD = 3, -- Damage per stud fallen above minimum (increased from 2)
	MAX_DAMAGE = 90, -- Cap damage at 90% of max health (increased from 80)
	IMMUNITY_TIME = 0.5, -- Grace period after launch before tracking starts
}

-- Direct earthquake damage (applied during shaking)
local QUAKE_DIRECT_DAMAGE = {
	-- Damage per tick during earthquake, scaled by magnitude
	BASE_DAMAGE = 2, -- Base damage per tick
	TICK_INTERVAL = 1.5, -- Seconds between damage ticks
	MAGNITUDE_MULTIPLIER = 15, -- Extra damage per magnitude point (0.6 mag = +9 damage)
}

-- Remote events
local EarthquakeEvent: RemoteEvent = nil :: any

-- MusicService reference (set during initialization)
local MusicService: any = nil

-- ==========================================
-- QUAKE TYPE DATA
-- ==========================================

local function getQuakeData(quakeType: QuakeType): QuakeData
	local config = Config.EARTHQUAKE[quakeType]
	return {
		type = quakeType,
		magnitude = config.magnitude,
		duration = config.duration,
		cameraShake = config.cameraShake,
		knockdown = config.knockdown,
		structuralDamage = config.structuralDamage,
		permanentChanges = config.permanentChanges,
	}
end

-- ==========================================
-- CORE FUNCTIONS
-- ==========================================

--[[
	Trigger an earthquake of the specified type.
]]
function EarthquakeService:TriggerQuake(quakeType: QuakeType)
	if isQuakeActive then
		print("[EarthquakeService] Quake already active, queuing as aftershock")
		table.insert(aftershockQueue, { delay = 5, magnitude = Config.EARTHQUAKE[quakeType].magnitude })
		return
	end

	local quakeData = getQuakeData(quakeType)
	isQuakeActive = true
	currentQuake = quakeData
	lastQuakeTimes[quakeType] = tick()

	print("[EarthquakeService] EARTHQUAKE:", quakeType, "Magnitude:", quakeData.magnitude)

	-- Send warning to all clients (P-wave)
	self:SendWarning(quakeData)

	-- After warning delay, trigger main quake (S-wave)
	task.delay(Config.EARTHQUAKE.WARNING_TIME, function()
		self:ExecuteQuake(quakeData)
	end)
end

--[[
	Trigger an earthquake by magnitude (for custom events).
]]
function EarthquakeService:TriggerQuakeByMagnitude(magnitude: number)
	local quakeType: QuakeType
	if magnitude >= 1.0 then
		quakeType = "BIG_ONE"
	elseif magnitude >= 0.9 then
		quakeType = "MAJOR"
	elseif magnitude >= 0.6 then
		quakeType = "MODERATE"
	else
		quakeType = "MINOR_TREMOR"
	end
	self:TriggerQuake(quakeType)
end

--[[
	Send P-wave warning to clients.
]]
function EarthquakeService:SendWarning(quakeData: QuakeData)
	if EarthquakeEvent then
		EarthquakeEvent:FireAllClients({
			warning = true,
			magnitude = quakeData.magnitude,
			type = quakeData.type,
			timeUntilHit = Config.EARTHQUAKE.WARNING_TIME,
		})
	end
end

--[[
	Apply direct damage to all players during an earthquake.
	Damage ticks occur every TICK_INTERVAL seconds while the quake is active.
]]
function EarthquakeService:ApplyDirectDamage(magnitude: number, duration: number)
	local tickInterval = QUAKE_DIRECT_DAMAGE.TICK_INTERVAL
	local numTicks = math.floor(duration / tickInterval)

	-- Calculate damage per tick based on magnitude
	local damagePerTick = QUAKE_DIRECT_DAMAGE.BASE_DAMAGE + (magnitude * QUAKE_DIRECT_DAMAGE.MAGNITUDE_MULTIPLIER)

	print(string.format("[EarthquakeService] Quake damage: %.1f per tick for %d ticks", damagePerTick, numTicks))

	for tick = 1, numTicks do
		task.delay(tick * tickInterval, function()
			-- Only apply if quake is still active
			if not isQuakeActive then
				return
			end

			for _, player in Players:GetPlayers() do
				local character = player.Character
				if not character then
					continue
				end

				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if not humanoid or humanoid.Health <= 0 then
					continue
				end

				-- Apply damage with a visual shake hint
				humanoid:TakeDamage(damagePerTick)

				-- Notify client of damage source
				if EarthquakeEvent then
					EarthquakeEvent:FireClient(player, {
						directDamage = true,
						damage = damagePerTick,
					})
				end
			end
		end)
	end
end

--[[
	Execute the main earthquake effects.
]]
function EarthquakeService:ExecuteQuake(quakeData: QuakeData)
	print("[EarthquakeService] Executing quake effects:", quakeData.type)

	-- Notify clients of main quake
	if EarthquakeEvent then
		EarthquakeEvent:FireAllClients({
			warning = false,
			active = true,
			magnitude = quakeData.magnitude,
			type = quakeData.type,
			duration = quakeData.duration,
			cameraShake = quakeData.cameraShake,
			knockdown = quakeData.knockdown,
		})
	end

	-- Launch unanchored structures into the air (all quakes)
	self:LaunchUnanchoredStructures(quakeData.magnitude)

	-- Apply knockdown if applicable
	if quakeData.knockdown then
		self:ApplyKnockdown(quakeData.magnitude)
	end

	-- Apply direct damage during quake (MODERATE and above)
	if quakeData.magnitude >= 0.6 then
		self:ApplyDirectDamage(quakeData.magnitude, quakeData.duration)
	end

	-- Trigger emergency broadcast for moderate+ quakes
	if MusicService and quakeData.magnitude >= 0.6 then
		MusicService:StartEmergency(quakeData.duration)
	end

	-- Structural damage (future: collapse buildings)
	if quakeData.structuralDamage then
		self:ApplyStructuralDamage(quakeData.magnitude)
	end

	-- Permanent changes (The Big One)
	if quakeData.permanentChanges then
		self:ApplyPermanentChanges()
	end

	-- End quake after duration
	task.delay(quakeData.duration, function()
		self:EndQuake(quakeData)
	end)
end

--[[
	End the current earthquake.
]]
function EarthquakeService:EndQuake(quakeData: QuakeData)
	print("[EarthquakeService] Quake ended:", quakeData.type)
	isQuakeActive = false
	currentQuake = nil

	-- Notify clients quake ended
	if EarthquakeEvent then
		EarthquakeEvent:FireAllClients({
			warning = false,
			active = false,
			ended = true,
		})
	end

	-- Trigger aftershocks for major/big quakes
	if quakeData.type == "MAJOR" or quakeData.type == "BIG_ONE" then
		self:QueueAftershocks(quakeData.magnitude)
	end

	-- Process aftershock queue
	self:ProcessAftershocks()
end

-- ==========================================
-- KNOCKDOWN
-- ==========================================

function EarthquakeService:ApplyKnockdown(magnitude: number)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then
			continue
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?

		if humanoid and rootPart then
			-- Ragdoll-like effect: apply force and briefly disable control
			local knockbackForce = magnitude * 50

			-- Random knockback direction with upward component
			local angle = math.random() * math.pi * 2
			-- Higher magnitude = more upward launch (0.5 base, up to 1.0 for BIG_ONE)
			local upwardComponent = 0.5 + magnitude * 0.5
			local direction = Vector3.new(math.cos(angle), upwardComponent, math.sin(angle)).Unit

			-- Apply impulse
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = direction * knockbackForce
			bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
			bodyVelocity.Parent = rootPart

			-- Start tracking for fall damage
			local currentY = rootPart.Position.Y
			launchedPlayers[player] = {
				launchTime = tick(),
				launchY = currentY,
				maxY = currentY,
				magnitude = magnitude,
			}

			-- Brief stun
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0

			task.delay(1.5, function()
				if bodyVelocity.Parent then
					bodyVelocity:Destroy()
				end
				if humanoid.Parent then
					humanoid.WalkSpeed = 16
					humanoid.JumpPower = 50
				end
			end)

			print("[EarthquakeService] Knocked down:", player.Name, "tracking fall damage")
		end
	end
end

-- ==========================================
-- FALL DAMAGE
-- ==========================================

--[[
	Monitor launched players and apply fall damage when they land.
	Called every heartbeat from the scheduler.
]]
local function monitorFallDamage()
	local now = tick()
	local playersToRemove: { Player } = {}

	for player, data in pairs(launchedPlayers) do
		-- Skip during immunity period
		if now - data.launchTime < FALL_DAMAGE.IMMUNITY_TIME then
			continue
		end

		local character = player.Character
		if not character then
			table.insert(playersToRemove, player)
			continue
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?

		if not humanoid or not rootPart then
			table.insert(playersToRemove, player)
			continue
		end

		local currentY = rootPart.Position.Y

		-- Update max height
		if currentY > data.maxY then
			data.maxY = currentY
		end

		-- Check if player has landed using multiple methods
		local state = humanoid:GetState()
		local isOnGround = state == Enum.HumanoidStateType.Running
			or state == Enum.HumanoidStateType.RunningNoPhysics
			or state == Enum.HumanoidStateType.Landed
			or state == Enum.HumanoidStateType.Freefall == false

		-- Alternative check: Y velocity is near zero or positive (stopped falling)
		local velocity = rootPart.AssemblyLinearVelocity
		local isStopped = math.abs(velocity.Y) < 10 -- More lenient threshold

		-- Raycast check for ground contact
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { player.Character }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local rayResult = Workspace:Raycast(rootPart.Position, Vector3.new(0, -3, 0), rayParams)
		local isNearGround = rayResult ~= nil

		-- Player has landed if any condition indicates ground contact AND they fell
		local fallHeight = data.maxY - currentY
		local hasLanded = (isOnGround or (isStopped and isNearGround)) and fallHeight > 2

		-- Also stop tracking if they've been tracked for too long (10 seconds)
		local trackingTimeout = now - data.launchTime > 10

		if hasLanded or trackingTimeout then
			-- Calculate fall damage
			if fallHeight >= FALL_DAMAGE.MIN_HEIGHT then
				local damageableHeight = fallHeight - FALL_DAMAGE.MIN_HEIGHT
				local baseDamage = damageableHeight * FALL_DAMAGE.DAMAGE_PER_STUD

				-- Scale damage by earthquake magnitude (bigger quakes = more damage)
				local magnitudeMultiplier = 0.5 + data.magnitude * 0.5
				local finalDamage = math.min(baseDamage * magnitudeMultiplier, FALL_DAMAGE.MAX_DAMAGE)

				if finalDamage > 0 and humanoid.Health > 0 then
					humanoid:TakeDamage(finalDamage)
					print(
						string.format(
							"[EarthquakeService] Fall damage: %s fell %.1f studs, took %.1f damage",
							player.Name,
							fallHeight,
							finalDamage
						)
					)

					-- Notify client for screen effect (red flash)
					if EarthquakeEvent then
						EarthquakeEvent:FireClient(player, {
							fallDamage = true,
							damage = finalDamage,
							height = fallHeight,
						})
					end
				end
			end

			table.insert(playersToRemove, player)
		end
	end

	-- Clean up tracked players
	for _, player in ipairs(playersToRemove) do
		launchedPlayers[player] = nil
	end
end

--[[
	Clean up tracking when player leaves.
]]
local function onPlayerRemoving(player: Player)
	launchedPlayers[player] = nil
end

-- ==========================================
-- STRUCTURAL DAMAGE & LAUNCHING
-- ==========================================

--[[
	Launch all unanchored structures into the air.
	Called when earthquake triggers - structures get thrown up and fall back down.
	Launch height is calculated from shared TerrainConfig for consistency with Fault-Lite.
]]
function EarthquakeService:LaunchUnanchoredStructures(magnitude: number)
	-- Use shared config for consistent behavior across both games (DRY)
	local TerrainConfig = Shared.TerrainConfig
	local launchHeight = TerrainConfig.GetLaunchHeight(magnitude)
	if launchHeight <= 0 then
		return
	end

	print("[EarthquakeService] Launching unanchored structures " .. string.format("%.1f", launchHeight) .. " studs up")

	local launchedCount = 0

	-- Check Structures folder
	local structuresFolder = Workspace:FindFirstChild("Structures")
	if structuresFolder then
		for _, model in structuresFolder:GetChildren() do
			if model:IsA("Model") then
				local isUnanchored = false
				for _, part in model:GetDescendants() do
					if part:IsA("BasePart") and not part.Anchored then
						isUnanchored = true
						break
					end
				end

				if isUnanchored then
					local currentCFrame = model:GetPivot()
					model:PivotTo(currentCFrame + Vector3.new(0, launchHeight, 0))
					launchedCount = launchedCount + 1
				end
			end
		end
	end

	-- Also check Destructibles folder
	local destructibles = Workspace:FindFirstChild("Destructibles")
	if destructibles then
		for _, model in destructibles:GetChildren() do
			if model:IsA("Model") then
				local isUnanchored = false
				for _, part in model:GetDescendants() do
					if part:IsA("BasePart") and not part.Anchored then
						isUnanchored = true
						break
					end
				end

				if isUnanchored then
					local currentCFrame = model:GetPivot()
					model:PivotTo(currentCFrame + Vector3.new(0, launchHeight, 0))
					launchedCount = launchedCount + 1
				end
			end
		end
	end

	if launchedCount > 0 then
		print("[EarthquakeService] Launched " .. launchedCount .. " unanchored structures")
	end
end

function EarthquakeService:ApplyStructuralDamage(magnitude: number)
	-- Find destructible structures in workspace
	local destructibles = workspace:FindFirstChild("Destructibles")
	if not destructibles then
		print("[EarthquakeService] No destructibles folder found")
		return
	end

	for _, structure in destructibles:GetChildren() do
		local _weakPoint = structure:GetAttribute("WeakPoint") -- For future collapse direction
		local threshold = structure:GetAttribute("DamageThreshold") or 0.8

		if magnitude >= threshold then
			print("[EarthquakeService] Damaging structure:", structure.Name)
			-- TODO: Trigger collapse animation
			-- For now, just anchor and make transparent to show damage
			if structure:IsA("BasePart") then
				structure.Transparency = 0.5
			elseif structure:IsA("Model") then
				for _, part in structure:GetDescendants() do
					if part:IsA("BasePart") then
						part.Transparency = math.min(part.Transparency + 0.3, 0.8)
					end
				end
			end
		end
	end
end

-- ==========================================
-- PERMANENT CHANGES (THE BIG ONE)
-- ==========================================

-- Reference to TerrainGenerator (set during initialization)
local TerrainGenerator: any = nil

function EarthquakeService:ApplyPermanentChanges()
	if bigOneTriggered then
		print("[EarthquakeService] The Big One already triggered")
		return
	end

	bigOneTriggered = true
	print("[EarthquakeService] THE BIG ONE - Permanent world changes!")

	-- Apply heightmap terrain changes (widen and deepen fault line)
	local Heightmap = Shared.Heightmap
	local changesApplied = Heightmap:ApplyBigOneChanges()

	if changesApplied then
		-- Clear terrain cache since heights have changed
		if Shared.TerrainUtils and Shared.TerrainUtils.clearCache then
			Shared.TerrainUtils.clearCache()
		end

		-- Regenerate visual terrain for the fault line area
		-- This updates the Roblox Terrain voxels to match the new heightmap
		if TerrainGenerator and TerrainGenerator.RegenerateFaultLineArea then
			task.spawn(function()
				TerrainGenerator:RegenerateFaultLineArea()
			end)
		else
			-- Fallback: regenerate all visual terrain (slower but works)
			print("[EarthquakeService] TerrainGenerator not available for partial regeneration")
		end

		-- Apply structural damage to buildings near the fault
		self:ApplyStructuralDamage(1.0)

		-- Fire event for story system
		task.delay(2, function()
			-- Notify clients that terrain has changed
			if EarthquakeEvent then
				EarthquakeEvent:FireAllClients({
					warning = false,
					active = false,
					terrainChanged = true,
					bigOneComplete = true,
				})
			end

			-- Trigger story event
			local NarrativeService = self:GetNarrativeService()
			if NarrativeService then
				NarrativeService:TriggerStoryEvent("BIG_ONE_ENDED")
			end
		end)
	end

	print("[EarthquakeService] THE BIG ONE permanent changes applied!")
end

--[[
	Set reference to TerrainGenerator for visual terrain updates.
]]
function EarthquakeService:SetTerrainGenerator(generator: any)
	TerrainGenerator = generator
	print("[EarthquakeService] TerrainGenerator connected")
end

-- Cached reference to NarrativeService
local NarrativeService: any = nil

function EarthquakeService:GetNarrativeService(): any
	if not NarrativeService then
		-- Try to get it from ServerScriptService
		local ServerScriptService = game:GetService("ServerScriptService")
		local Server = ServerScriptService:FindFirstChild("Server")
		if Server then
			local Services = Server:FindFirstChild("Services")
			if Services then
				local narrativeMod = Services:FindFirstChild("NarrativeService")
				if narrativeMod then
					NarrativeService = require(narrativeMod)
				end
			end
		end
	end
	return NarrativeService
end

--[[
	Trigger The Big One (story event).
]]
function EarthquakeService:TriggerBigOne()
	if bigOneTriggered then
		warn("[EarthquakeService] The Big One already triggered!")
		return
	end

	print("[EarthquakeService] TRIGGERING THE BIG ONE!")
	self:TriggerQuake("BIG_ONE")
end

-- ==========================================
-- AFTERSHOCKS
-- ==========================================

function EarthquakeService:QueueAftershocks(magnitude: number)
	-- Queue 2-4 aftershocks of decreasing magnitude
	local numAftershocks = math.random(2, 4)
	local currentMagnitude = magnitude * 0.6

	for i = 1, numAftershocks do
		local delay = math.random(10, 30) * i
		table.insert(aftershockQueue, {
			delay = delay,
			magnitude = currentMagnitude,
		})
		currentMagnitude *= 0.7
	end

	print("[EarthquakeService] Queued", numAftershocks, "aftershocks")
end

function EarthquakeService:ProcessAftershocks()
	if #aftershockQueue == 0 then
		return
	end

	local aftershock = table.remove(aftershockQueue, 1)
	if aftershock then
		task.delay(aftershock.delay, function()
			if not isQuakeActive then
				self:TriggerQuakeByMagnitude(aftershock.magnitude)
			else
				-- Re-queue if another quake is active
				table.insert(aftershockQueue, aftershock)
			end
		end)
	end
end

-- ==========================================
-- STATE QUERIES
-- ==========================================

function EarthquakeService:IsQuakeActive(): boolean
	return isQuakeActive
end

function EarthquakeService:GetCurrentQuake(): QuakeData?
	return currentQuake
end

function EarthquakeService:GetLastQuakeTime(quakeType: QuakeType?): number
	if quakeType then
		return lastQuakeTimes[quakeType] or 0
	end

	-- Return most recent quake time
	local mostRecent = 0
	for _, time in pairs(lastQuakeTimes) do
		mostRecent = math.max(mostRecent, time)
	end
	return mostRecent
end

function EarthquakeService:HasBigOneTriggered(): boolean
	return bigOneTriggered
end

-- ==========================================
-- PERIODIC QUAKE SCHEDULER
-- ==========================================

local lastSchedulerCheck = 0
local SCHEDULER_INTERVAL = 10 -- Check every 10 seconds

local function schedulerTick()
	local now = tick()
	if now - lastSchedulerCheck < SCHEDULER_INTERVAL then
		return
	end
	lastSchedulerCheck = now

	-- Don't schedule during active quake
	if isQuakeActive then
		return
	end

	-- Check each quake type for timing
	local quakeTypes: { QuakeType } = { "MINOR_TREMOR", "MODERATE", "MAJOR" }

	for _, quakeType in ipairs(quakeTypes) do
		local config = Config.EARTHQUAKE[quakeType]
		local interval = config.interval
		local lastTime = lastQuakeTimes[quakeType] or 0

		-- Add some randomness to intervals (+/- 20%)
		local variance = interval * 0.2
		local adjustedInterval = interval + math.random(-variance, variance)

		if now - lastTime >= adjustedInterval then
			-- Random chance to trigger (so not perfectly predictable)
			if math.random() < 0.5 then
				EarthquakeService:TriggerQuake(quakeType)
				break -- Only one quake at a time
			end
		end
	end
end

-- ==========================================
-- SERVICE INJECTION
-- ==========================================

--[[
	Set the MusicService reference for emergency broadcasts.
	Called after both services are initialized.
]]
function EarthquakeService:SetMusicService(service: any)
	MusicService = service
	print("[EarthquakeService] MusicService connected for emergency broadcasts")
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function EarthquakeService:Initialize()
	-- Get remote event
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	EarthquakeEvent = remotes:WaitForChild("EarthquakeEvent") :: RemoteEvent

	-- Initialize last quake times to current time (delay first quakes)
	local now = tick()
	lastQuakeTimes["MINOR_TREMOR"] = now
	lastQuakeTimes["MODERATE"] = now
	lastQuakeTimes["MAJOR"] = now

	-- Start scheduler (includes quake timing and fall damage monitoring)
	RunService.Heartbeat:Connect(function()
		schedulerTick()
		monitorFallDamage()
	end)

	-- Clean up tracking when player leaves
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	print("[EarthquakeService] Initialized with fall damage system")
	print(
		"[EarthquakeService] Fall damage: min height",
		FALL_DAMAGE.MIN_HEIGHT,
		"studs, max damage",
		FALL_DAMAGE.MAX_DAMAGE
	)
	print("[EarthquakeService] Minor tremors every ~", Config.EARTHQUAKE.MINOR_TREMOR.interval, "seconds")
	print("[EarthquakeService] Moderate quakes every ~", Config.EARTHQUAKE.MODERATE.interval, "seconds")
	print("[EarthquakeService] Major quakes every ~", Config.EARTHQUAKE.MAJOR.interval, "seconds")
end

return EarthquakeService
