--!strict
--[[
	Faultline Fear: Audio Controller

	Handles all client-side audio:
	- Background music that NEVER stops
	- Zone-based station switching with crossfade
	- Emergency broadcasts during earthquakes
	- Ambient sounds and effects
]]

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config

export type Station = "Coastal" | "Mountain" | "Town" | "Wilderness" | "Eerie" | "Emergency"

local AudioController = {}

-- State
local currentStation: Station = "Wilderness"
local isEmergencyActive: boolean = false
local masterVolume: number = Config.MUSIC.DEFAULT_VOLUME

-- Sound instances
local musicGroup: SoundGroup = nil :: any
local currentSound: Sound? = nil
local _nextSound: Sound? = nil -- Reserved for future crossfade optimization

-- Station sound IDs - Roblox Creator Marketplace ambient sounds
-- Sources: robloxsong.com, musiccoder.com, robloxmusicids.com
local StationSounds: { [Station]: string } = {
	Coastal = "rbxassetid://898059911", -- Sea Ambience
	Mountain = "rbxassetid://169736440", -- [Nature] Forest Sounds (alpine feel)
	Town = "rbxassetid://7262900392", -- Ambient Music (calm urban)
	Wilderness = "rbxassetid://728506251", -- Nature sounds for Forest
	Eerie = "rbxassetid://5595380425", -- Dark Scary Eerie Horror Ambient
	Emergency = "rbxassetid://5743541225", -- Red Alert Alarm / Siren (looped)
}

-- Fallback sound IDs (alternative tracks if primary fails)
-- Note: Roblox audio privacy may restrict some tracks
local FallbackSounds: { [Station]: number } = {
	Coastal = 959532448, -- Ocean waves
	Mountain = 138089070, -- Forest Ambience (Night)
	Town = 169736440, -- Forest sounds as fallback
	Wilderness = 169736440, -- [Nature] Forest Sounds
	Eerie = 7524653769, -- Creepy Ambience
	Emergency = 428391167, -- Tornado Warning Siren
}

-- ==========================================
-- SOUND SETUP
-- ==========================================

local function createSoundGroup(): SoundGroup
	local group = Instance.new("SoundGroup")
	group.Name = "FaultlineFearMusic"
	group.Volume = masterVolume
	group.Parent = SoundService
	return group
end

local function createSound(station: Station): Sound?
	-- Check if we have a valid sound ID (DRY - use shared utility)
	local soundId = StationSounds[station]
	local fallbackId = FallbackSounds[station]

	local hasValidPrimary = Shared.isValidSoundId(soundId)
	local hasValidFallback = Shared.isValidSoundId(fallbackId)

	-- Skip sound creation entirely if no valid audio
	-- (prevents "Failed to load sound" errors)
	if not hasValidPrimary and not hasValidFallback then
		return nil
	end

	local sound = Instance.new("Sound")
	sound.Name = station .. "Music"
	sound.Looped = true
	sound.Volume = 0 -- Start silent for crossfade

	-- Use primary or fallback sound ID
	if hasValidPrimary then
		sound.SoundId = soundId
	else
		sound.SoundId = "rbxassetid://" .. tostring(fallbackId)
	end

	sound.SoundGroup = musicGroup
	sound.Parent = musicGroup

	return sound
end

-- ==========================================
-- CROSSFADE
-- ==========================================

local function crossfadeTo(newStation: Station)
	if newStation == currentStation and currentSound then
		return
	end

	print("[AudioController] Crossfading to:", newStation)

	local fadeTime = Config.MUSIC.CROSSFADE_DURATION

	-- Create new sound (may be nil if no valid audio)
	local newSound = createSound(newStation)

	-- Fade out and destroy old sound
	if currentSound then
		local oldSound = currentSound
		local fadeOutTween = TweenService:Create(oldSound, TweenInfo.new(fadeTime, Enum.EasingStyle.Sine), {
			Volume = 0,
		})
		fadeOutTween:Play()
		fadeOutTween.Completed:Connect(function()
			oldSound:Destroy()
		end)
	end

	-- Only play if we have a valid sound
	if newSound then
		newSound:Play()

		-- Fade in new sound
		local fadeInTween = TweenService:Create(newSound, TweenInfo.new(fadeTime, Enum.EasingStyle.Sine), {
			Volume = masterVolume,
		})
		fadeInTween:Play()
	end

	currentSound = newSound
	currentStation = newStation
end

-- ==========================================
-- EMERGENCY BROADCAST
-- ==========================================

-- Forward declare for mutual recursion
local endEmergencyInternal: (Station?) -> ()

local function startEmergency(duration: number)
	if isEmergencyActive then
		return
	end

	isEmergencyActive = true
	print("[AudioController] Emergency broadcast started")

	-- Store current station to resume later
	local previousStation = currentStation

	-- Quick fade to emergency
	local emergencySound = createSound("Emergency")
	emergencySound.Volume = Config.MUSIC.EMERGENCY_BROADCAST_VOLUME
	emergencySound:Play()

	-- Fade down current music
	if currentSound then
		TweenService:Create(currentSound, TweenInfo.new(0.5), { Volume = 0.1 }):Play()
	end

	-- Schedule resume
	task.delay(duration, function()
		if isEmergencyActive then
			endEmergencyInternal(previousStation)
		end
	end)
end

endEmergencyInternal = function(resumeStation: Station?)
	if not isEmergencyActive then
		return
	end

	isEmergencyActive = false
	print("[AudioController] Emergency broadcast ended")

	-- Find and fade out emergency sound
	for _, sound in musicGroup:GetChildren() do
		if sound:IsA("Sound") and sound.Name == "EmergencyMusic" then
			local fadeOut = TweenService:Create(sound, TweenInfo.new(1), { Volume = 0 })
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				sound:Destroy()
			end)
		end
	end

	-- Resume previous music
	if resumeStation then
		crossfadeTo(resumeStation)
	elseif currentSound then
		TweenService:Create(currentSound, TweenInfo.new(2), { Volume = masterVolume }):Play()
	end
end

-- ==========================================
-- VOLUME CONTROL
-- ==========================================

function AudioController:SetVolume(volume: number)
	masterVolume = math.clamp(volume, 0, 1)
	if musicGroup then
		musicGroup.Volume = masterVolume
	end
	print("[AudioController] Volume set to:", masterVolume)
end

function AudioController:GetVolume(): number
	return masterVolume
end

function AudioController:Mute()
	if musicGroup then
		musicGroup.Volume = 0
	end
end

function AudioController:Unmute()
	if musicGroup then
		musicGroup.Volume = masterVolume
	end
end

-- ==========================================
-- STATION CONTROL
-- ==========================================

function AudioController:ChangeStation(station: Station)
	if not isEmergencyActive then
		crossfadeTo(station)
	end
end

function AudioController:GetCurrentStation(): Station
	return currentStation
end

-- ==========================================
-- EARTHQUAKE SOUNDS
-- ==========================================

local rumbleSound: Sound? = nil

function AudioController:PlayEarthquakeRumble(magnitude: number, duration: number)
	-- Create rumble sound
	if rumbleSound then
		rumbleSound:Destroy()
	end

	rumbleSound = Instance.new("Sound")
	rumbleSound.Name = "EarthquakeRumble"
	rumbleSound.SoundId = "rbxassetid://9043887091" -- Placeholder rumble
	rumbleSound.Volume = magnitude * 0.8
	rumbleSound.Looped = true
	rumbleSound.Parent = SoundService

	rumbleSound:Play()

	-- Fade out at end
	task.delay(duration - 2, function()
		if rumbleSound then
			local fadeOut = TweenService:Create(rumbleSound, TweenInfo.new(2), { Volume = 0 })
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				if rumbleSound then
					rumbleSound:Destroy()
					rumbleSound = nil
				end
			end)
		end
	end)
end

function AudioController:StopEarthquakeRumble()
	if rumbleSound then
		rumbleSound:Destroy()
		rumbleSound = nil
	end
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function AudioController:Initialize()
	-- Create sound group
	musicGroup = createSoundGroup()

	-- Connect to server music events
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local musicEvent = remotes:WaitForChild("MusicEvent", 5)

	if musicEvent then
		(musicEvent :: RemoteEvent).OnClientEvent:Connect(function(event)
			if event.type == "station_change" and event.station then
				self:ChangeStation(event.station)
			elseif event.type == "emergency" then
				startEmergency(event.duration or 10)
			elseif event.type == "resume" then
				endEmergencyInternal(nil)
			elseif event.type == "volume" and event.volume then
				self:SetVolume(event.volume)
			end
		end)
	end

	-- Start with wilderness music immediately
	print("[AudioController] Starting initial music...")
	crossfadeTo("Wilderness")

	print("[AudioController] Initialized")
	print("[AudioController] Music should NEVER stop!")
end

return AudioController
