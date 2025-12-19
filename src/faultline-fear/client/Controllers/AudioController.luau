--!strict
--[[
	Faultline Fear: Audio Controller

	LAYERED AUDIO SYSTEM:
	- Ambient Layer: Full volume nature sounds (waves, wind, forest)
	- Music Layer: Low volume with reverb for distant, eerie feel

	Creates atmosphere like: you're at the beach hearing waves crash,
	but faint carnival music drifts from the abandoned pier...

	California Beach Horror Survival Theme
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

-- Sound groups (separate for ambient and music layers)
local ambientGroup: SoundGroup = nil :: any
local musicGroup: SoundGroup = nil :: any

-- Current playing sounds
local currentAmbient: Sound? = nil
local currentMusic: Sound? = nil

-- ==========================================
-- AUDIO CONFIGURATION - California Beach Horror Survival
-- ==========================================

-- Ambient sounds (full volume, nearby nature)
local AmbientSounds: { [Station]: string } = {
	Coastal = "rbxassetid://959532448", -- Ocean Waves
	Mountain = "rbxassetid://1842660840", -- Cave/Mountain Wind
	Town = "rbxassetid://7524653769", -- Creepy Urban Ambience
	Wilderness = "rbxassetid://169736440", -- Forest Sounds
	Eerie = "rbxassetid://2893921424", -- Scary Ambience (liminal)
	Emergency = "rbxassetid://5743541225", -- Siren (takes over both layers)
}

-- Distant music (low volume with reverb - sounds far away)
-- Theme: California beach town with something WRONG
local DistantMusic: { [Station]: string } = {
	Coastal = "rbxassetid://143382469", -- Creepy Music Box (distant carnival)
	Mountain = "rbxassetid://9039981149", -- Horror (isolated dread)
	Town = "rbxassetid://209322206", -- Scary Music Box (abandoned shops)
	Wilderness = "rbxassetid://5201293422", -- Horror Ambient (something watching)
	Eerie = "rbxassetid://1837805876", -- Music Box of Death (backrooms)
	Emergency = "", -- No distant music during emergency
}

-- Fallback IDs if primary fails
local AmbientFallbacks: { [Station]: number } = {
	Coastal = 419321414, -- Ocean Wave Effects
	Mountain = 728506251, -- Wind/Nature
	Town = 1846999567, -- Creepy Night
	Wilderness = 728506251, -- Nature sounds
	Eerie = 7524653769, -- Creepy Ambience
	Emergency = 428391167, -- Tornado Siren
}

local MusicFallbacks: { [Station]: number } = {
	Coastal = 1847830052, -- Spooky Clouds
	Mountain = 1841151748, -- Out of the Music Box
	Town = 5252159074, -- Creepy Music Box Loud
	Wilderness = 4476735716, -- Reversed Music Box
	Eerie = 1844758350, -- Choir Harmony (eerie)
	Emergency = 0, -- No fallback
}

-- Volume settings for layers
local AMBIENT_VOLUME = 0.6 -- Nearby, clear
local MUSIC_VOLUME = 0.15 -- Distant, faint
local MUSIC_REVERB_DECAY = 3.0 -- Seconds of reverb tail
local MUSIC_REVERB_WET = 0.7 -- How much reverb (0-1)

-- ==========================================
-- SOUND SETUP
-- ==========================================

local function createSoundGroups()
	-- Ambient group (no effects)
	ambientGroup = Instance.new("SoundGroup")
	ambientGroup.Name = "FaultlineFearAmbient"
	ambientGroup.Volume = AMBIENT_VOLUME
	ambientGroup.Parent = SoundService

	-- Music group (will have reverb)
	musicGroup = Instance.new("SoundGroup")
	musicGroup.Name = "FaultlineFearMusic"
	musicGroup.Volume = MUSIC_VOLUME
	musicGroup.Parent = SoundService

	-- Add reverb to music group for distant sound
	local reverb = Instance.new("ReverbSoundEffect")
	reverb.Name = "DistantReverb"
	reverb.DecayTime = MUSIC_REVERB_DECAY
	reverb.Density = 0.8
	reverb.Diffusion = 0.9
	reverb.DryLevel = 1 - MUSIC_REVERB_WET
	reverb.WetLevel = MUSIC_REVERB_WET
	reverb.Parent = musicGroup
end

local function createSound(soundId: string, fallbackId: number, group: SoundGroup, name: string): Sound?
	local hasValidPrimary = Shared.isValidSoundId(soundId)
	local hasValidFallback = fallbackId > 0

	if not hasValidPrimary and not hasValidFallback then
		warn("[AudioController] No valid sound ID for:", name)
		return nil
	end

	local sound = Instance.new("Sound")
	sound.Name = name
	sound.Looped = true
	sound.Volume = 0 -- Start silent for crossfade

	if hasValidPrimary then
		sound.SoundId = soundId
	else
		sound.SoundId = "rbxassetid://" .. tostring(fallbackId)
	end

	sound.SoundGroup = group
	sound.Parent = group

	-- Log what we're trying to play
	print(string.format("[AudioController] Created sound '%s' with ID: %s", name, sound.SoundId))

	-- Listen for load errors (common with Roblox audio policy)
	sound.Loaded:Connect(function()
		print(string.format("[AudioController] Sound loaded: %s (length: %.1fs)", name, sound.TimeLength))
	end)

	-- Check if sound fails to load after a delay
	task.delay(3, function()
		if sound.Parent and sound.TimeLength == 0 then
			warn(string.format("[AudioController] Sound may have failed to load: %s (ID: %s)", name, sound.SoundId))
		end
	end)

	return sound
end

-- ==========================================
-- CROSSFADE (handles both layers)
-- ==========================================

local function crossfadeLayer(
	oldSound: Sound?,
	newSoundId: string,
	fallbackId: number,
	group: SoundGroup,
	name: string,
	targetVolume: number
): Sound?
	local fadeTime = Config.MUSIC.CROSSFADE_DURATION

	-- Create new sound
	local newSound = createSound(newSoundId, fallbackId, group, name)

	-- Fade out old sound
	if oldSound then
		local old = oldSound
		local fadeOut = TweenService:Create(old, TweenInfo.new(fadeTime, Enum.EasingStyle.Sine), {
			Volume = 0,
		})
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			old:Destroy()
		end)
	end

	-- Fade in new sound
	if newSound then
		newSound:Play()
		local fadeIn = TweenService:Create(newSound, TweenInfo.new(fadeTime, Enum.EasingStyle.Sine), {
			Volume = targetVolume,
		})
		fadeIn:Play()
	end

	return newSound
end

local function crossfadeTo(newStation: Station)
	if newStation == currentStation and currentAmbient then
		return
	end

	print("[AudioController] Crossfading to:", newStation, "(layered audio)")

	-- Crossfade ambient layer
	currentAmbient = crossfadeLayer(
		currentAmbient,
		AmbientSounds[newStation],
		AmbientFallbacks[newStation],
		ambientGroup,
		newStation .. "_Ambient",
		AMBIENT_VOLUME * masterVolume
	)

	-- Crossfade music layer (distant, with reverb)
	local musicId = DistantMusic[newStation]
	if musicId and musicId ~= "" then
		currentMusic = crossfadeLayer(
			currentMusic,
			musicId,
			MusicFallbacks[newStation],
			musicGroup,
			newStation .. "_Music",
			MUSIC_VOLUME * masterVolume
		)
	else
		-- No music for this station (e.g., Emergency)
		if currentMusic then
			local old = currentMusic
			local fadeOut = TweenService:Create(old, TweenInfo.new(1), { Volume = 0 })
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				old:Destroy()
			end)
			currentMusic = nil
		end
	end

	currentStation = newStation
end

-- ==========================================
-- EMERGENCY BROADCAST
-- ==========================================

local endEmergencyInternal: (Station?) -> ()

local function startEmergency(duration: number)
	if isEmergencyActive then
		return
	end

	isEmergencyActive = true
	print("[AudioController] EMERGENCY BROADCAST - Earthquake Warning!")

	local previousStation = currentStation

	-- Fade down both layers quickly
	if currentAmbient then
		TweenService:Create(currentAmbient, TweenInfo.new(0.5), { Volume = 0.1 }):Play()
	end
	if currentMusic then
		TweenService:Create(currentMusic, TweenInfo.new(0.3), { Volume = 0 }):Play()
	end

	-- Play emergency siren at full volume
	local emergencySound = createSound(
		AmbientSounds.Emergency,
		AmbientFallbacks.Emergency,
		ambientGroup,
		"Emergency_Siren"
	)
	if emergencySound then
		emergencySound.Volume = Config.MUSIC.EMERGENCY_BROADCAST_VOLUME
		emergencySound:Play()
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
	print("[AudioController] Emergency ended, resuming normal audio")

	-- Find and fade out emergency sound
	for _, sound in ambientGroup:GetChildren() do
		if sound:IsA("Sound") and sound.Name == "Emergency_Siren" then
			local fadeOut = TweenService:Create(sound, TweenInfo.new(1), { Volume = 0 })
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				sound:Destroy()
			end)
		end
	end

	-- Resume previous station
	if resumeStation then
		currentStation = "Emergency" -- Force crossfade
		crossfadeTo(resumeStation)
	end
end

-- ==========================================
-- VOLUME CONTROL
-- ==========================================

function AudioController:SetVolume(volume: number)
	masterVolume = math.clamp(volume, 0, 1)

	if ambientGroup then
		ambientGroup.Volume = AMBIENT_VOLUME * masterVolume
	end
	if musicGroup then
		musicGroup.Volume = MUSIC_VOLUME * masterVolume
	end

	print("[AudioController] Master volume:", masterVolume)
end

function AudioController:GetVolume(): number
	return masterVolume
end

function AudioController:Mute()
	if ambientGroup then ambientGroup.Volume = 0 end
	if musicGroup then musicGroup.Volume = 0 end
end

function AudioController:Unmute()
	if ambientGroup then ambientGroup.Volume = AMBIENT_VOLUME * masterVolume end
	if musicGroup then musicGroup.Volume = MUSIC_VOLUME * masterVolume end
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
-- EARTHQUAKE RUMBLE
-- ==========================================

local rumbleSound: Sound? = nil

function AudioController:PlayEarthquakeRumble(magnitude: number, duration: number)
	if rumbleSound then
		rumbleSound:Destroy()
	end

	rumbleSound = Instance.new("Sound")
	rumbleSound.Name = "EarthquakeRumble"
	rumbleSound.SoundId = "rbxassetid://9043887091" -- Deep rumble
	rumbleSound.Volume = magnitude * 0.8
	rumbleSound.Looped = true
	rumbleSound.Parent = SoundService

	-- Add low-pass filter for rumble effect
	local eq = Instance.new("EqualizerSoundEffect")
	eq.HighGain = -20
	eq.MidGain = -5
	eq.LowGain = 10
	eq.Parent = rumbleSound

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
	print("[AudioController] Initializing layered audio system...")
	print("[AudioController] Theme: California Beach Horror Survival")

	-- Create sound groups with reverb
	createSoundGroups()

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

	-- Start with wilderness (player spawns in safe area)
	print("[AudioController] Starting ambient: forest sounds")
	print("[AudioController] Starting music: distant horror (with reverb)")
	crossfadeTo("Wilderness")

	print("[AudioController] Layered audio active - music NEVER stops!")
end

return AudioController
