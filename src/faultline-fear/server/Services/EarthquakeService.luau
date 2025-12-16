--!strict
-- Faultline Fear: Earthquake Service
-- The core mechanic - periodic earthquakes that shape the world

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

	-- Apply knockdown if applicable
	if quakeData.knockdown then
		self:ApplyKnockdown(quakeData.magnitude)
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

			-- Random knockback direction
			local angle = math.random() * math.pi * 2
			local direction = Vector3.new(math.cos(angle), 0.5, math.sin(angle))

			-- Apply impulse
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = direction * knockbackForce
			bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
			bodyVelocity.Parent = rootPart

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

			print("[EarthquakeService] Knocked down:", player.Name)
		end
	end
end

-- ==========================================
-- STRUCTURAL DAMAGE
-- ==========================================

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

function EarthquakeService:ApplyPermanentChanges()
	if bigOneTriggered then
		print("[EarthquakeService] The Big One already triggered")
		return
	end

	bigOneTriggered = true
	print("[EarthquakeService] THE BIG ONE - Permanent world changes!")

	-- Clear terrain cache (terrain has changed)
	Shared.TerrainUtils.clearCache()

	-- TODO: Major terrain deformation along fault line
	-- TODO: Collapse specific buildings
	-- TODO: Open new areas
	-- TODO: Trigger narrative events

	-- For now, just log
	warn("[EarthquakeService] THE BIG ONE complete - implement terrain changes!")
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
	lastQuakeTimes["MINOR_TREMOR"] = now - Config.EARTHQUAKE.MINOR_TREMOR.interval * 0.8
	lastQuakeTimes["MODERATE"] = now - Config.EARTHQUAKE.MODERATE.interval * 0.9
	lastQuakeTimes["MAJOR"] = now

	-- Start scheduler
	RunService.Heartbeat:Connect(schedulerTick)

	print("[EarthquakeService] Initialized")
	print("[EarthquakeService] Minor tremors every ~", Config.EARTHQUAKE.MINOR_TREMOR.interval, "seconds")
	print("[EarthquakeService] Moderate quakes every ~", Config.EARTHQUAKE.MODERATE.interval, "seconds")
	print("[EarthquakeService] Major quakes every ~", Config.EARTHQUAKE.MAJOR.interval, "seconds")
end

return EarthquakeService
