--!strict
--[[
	Faultline Fear: Liminal Zone Controller (Client)

	Handles client-side liminal zone effects:
	- Mutes regular music when in liminal spaces
	- Plays ambient sounds (HVAC, fluorescent hum, etc.)
	- Creates unsettling atmosphere
	- Manages visual effects

	Exports: Initialize(), IsInLiminalZone()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local _Config = Shared.Config

local LiminalZoneController = {}

-- State
local isInLiminal: boolean = false
local currentZone: string? = nil
local currentZoneType: string? = nil

-- Audio
local ambientSounds: { [string]: Sound } = {}
local currentAmbient: Sound? = nil
local musicMuted: boolean = false

-- Audio Controller reference (set during init)
local AudioController: any = nil

-- Ambient sound configurations
local AMBIENT_CONFIGS: { [string]: { soundId: string, volume: number } } = {
	fluorescent_hum = {
		soundId = "rbxassetid://9043836498", -- Electrical hum placeholder
		volume = 0.4,
	},
	elevator_music = {
		soundId = "rbxassetid://9043887091", -- Muzak placeholder
		volume = 0.2,
	},
	hvac_drone = {
		soundId = "rbxassetid://9043836498", -- HVAC drone placeholder
		volume = 0.3,
	},
	beeping_equipment = {
		soundId = "rbxassetid://9043887091", -- Medical beeps placeholder
		volume = 0.25,
	},
	distant_traffic = {
		soundId = "rbxassetid://9043836498", -- Traffic echo placeholder
		volume = 0.35,
	},
}

-- ==========================================
-- AUDIO MANAGEMENT
-- ==========================================

local function createAmbientSound(ambientType: string): Sound
	local config = AMBIENT_CONFIGS[ambientType]
	if not config then
		config = AMBIENT_CONFIGS.hvac_drone -- Default
	end

	local sound = Instance.new("Sound")
	sound.Name = "LiminalAmbient_" .. ambientType
	sound.SoundId = config.soundId
	sound.Volume = 0 -- Start silent for fade in
	sound.Looped = true
	sound.Parent = SoundService

	return sound
end

local function fadeInAmbient(ambientType: string)
	-- Create or get sound
	if not ambientSounds[ambientType] then
		ambientSounds[ambientType] = createAmbientSound(ambientType)
	end

	local sound = ambientSounds[ambientType]
	local config = AMBIENT_CONFIGS[ambientType] or AMBIENT_CONFIGS.hvac_drone

	-- Stop any current ambient
	if currentAmbient and currentAmbient ~= sound then
		local old = currentAmbient
		TweenService:Create(old, TweenInfo.new(1), { Volume = 0 }):Play()
		task.delay(1, function()
			old:Stop()
		end)
	end

	-- Start and fade in new ambient
	currentAmbient = sound
	sound:Play()

	TweenService:Create(sound, TweenInfo.new(2, Enum.EasingStyle.Sine), {
		Volume = config.volume,
	}):Play()

	print("[LiminalZoneController] Playing ambient:", ambientType)
end

local function fadeOutAmbient()
	if currentAmbient then
		local sound = currentAmbient
		TweenService:Create(sound, TweenInfo.new(2, Enum.EasingStyle.Sine), {
			Volume = 0,
		}):Play()

		task.delay(2, function()
			sound:Stop()
		end)

		currentAmbient = nil
		print("[LiminalZoneController] Fading out ambient")
	end
end

-- ==========================================
-- MUSIC CONTROL
-- ==========================================

local function muteMusic()
	if musicMuted then return end
	musicMuted = true

	if AudioController and AudioController.Mute then
		AudioController:Mute()
		print("[LiminalZoneController] Music muted for liminal zone")
	end
end

local function unmuteMusic()
	if not musicMuted then return end
	musicMuted = false

	if AudioController and AudioController.Unmute then
		AudioController:Unmute()
		print("[LiminalZoneController] Music unmuted after leaving liminal zone")
	end
end

-- ==========================================
-- ZONE ENTRY/EXIT
-- ==========================================

local function onEnterLiminalZone(zoneName: string, zoneType: string, ambientSound: string)
	isInLiminal = true
	currentZone = zoneName
	currentZoneType = zoneType

	print(string.format("[LiminalZoneController] Entered %s (%s)", zoneName, zoneType))

	-- Mute regular music
	muteMusic()

	-- Start ambient sound
	fadeInAmbient(ambientSound)
end

local function onExitLiminalZone(zoneName: string)
	print(string.format("[LiminalZoneController] Exited %s", zoneName))

	isInLiminal = false
	currentZone = nil
	currentZoneType = nil

	-- Fade out ambient
	fadeOutAmbient()

	-- Restore music
	unmuteMusic()
end

-- ==========================================
-- PUBLIC API
-- ==========================================

function LiminalZoneController:IsInLiminalZone(): boolean
	return isInLiminal
end

function LiminalZoneController:GetCurrentZone(): string?
	return currentZone
end

function LiminalZoneController:GetCurrentZoneType(): string?
	return currentZoneType
end

function LiminalZoneController:Initialize()
	-- Get AudioController reference
	local success, controller = pcall(function()
		return require(script.Parent.AudioController)
	end)
	if success then
		AudioController = controller
	else
		warn("[LiminalZoneController] Could not load AudioController")
	end

	-- Connect to server events
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local liminalEvent = remotes:WaitForChild("LiminalEvent", 10)

	if liminalEvent then
		(liminalEvent :: RemoteEvent).OnClientEvent:Connect(function(event)
			if event.type == "enter" then
				onEnterLiminalZone(event.zone, event.zoneType, event.ambientSound)
			elseif event.type == "exit" then
				onExitLiminalZone(event.zone)
			end
		end)
		print("[LiminalZoneController] Connected to LiminalEvent")
	else
		warn("[LiminalZoneController] LiminalEvent not found")
	end

	print("[LiminalZoneController] Initialized")
	print("[LiminalZoneController] Liminal zones will mute music and play ambient sounds")
end

return LiminalZoneController
