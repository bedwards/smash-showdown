--!strict
--[[
	Faultline Fear: Music Service (Server)

	Server-side music coordination:
	- Broadcasts emergency alerts during earthquakes
	- Coordinates zone-based music changes
	- Manages global audio events

	Actual playback happens on client via AudioController.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config

export type Station = "Coastal" | "Mountain" | "Town" | "Wilderness" | "Eerie" | "Emergency"

export type MusicEvent = {
	type: "station_change" | "emergency" | "resume" | "volume",
	station: Station?,
	duration: number?,
	volume: number?,
}

local MusicService = {}

-- State
local isEmergencyActive: boolean = false
local _currentEmergencyDuration: number = 0 -- Stored for future duration queries

-- Remote events
local MusicEvent: RemoteEvent = nil :: any

-- ==========================================
-- STATION DETERMINATION
-- ==========================================

--[[
	Determine which station should play based on player position.
]]
function MusicService:GetStationForPosition(position: Vector3): Station
	local Heightmap = Shared.Heightmap
	local zone = Heightmap:GetZone(position.X, position.Z)

	-- Map zones to stations
	if zone == "Ocean" or zone == "Beach" or zone == "Coastal" then
		return "Coastal"
	elseif zone == "Mountains" then
		return "Mountain"
	elseif zone == "Valley" then
		return "Town"
	elseif zone == "Fault Line" then
		return "Eerie" -- Fault line has eerie vibes
	else
		return "Wilderness"
	end
end

-- ==========================================
-- EMERGENCY BROADCAST
-- ==========================================

--[[
	Start emergency broadcast (called during earthquakes).
]]
function MusicService:StartEmergency(duration: number)
	if isEmergencyActive then
		return
	end

	isEmergencyActive = true
	_currentEmergencyDuration = duration

	print("[MusicService] Emergency broadcast started, duration:", duration)

	-- Notify all clients
	if MusicEvent then
		MusicEvent:FireAllClients({
			type = "emergency",
			station = "Emergency",
			duration = duration,
		})
	end

	-- Schedule end of emergency
	task.delay(duration, function()
		self:EndEmergency()
	end)
end

--[[
	End emergency broadcast and resume normal music.
]]
function MusicService:EndEmergency()
	if not isEmergencyActive then
		return
	end

	isEmergencyActive = false
	_currentEmergencyDuration = 0

	print("[MusicService] Emergency broadcast ended, resuming normal music")

	-- Notify all clients to resume
	if MusicEvent then
		MusicEvent:FireAllClients({
			type = "resume",
		})
	end
end

--[[
	Check if emergency broadcast is active.
]]
function MusicService:IsEmergencyActive(): boolean
	return isEmergencyActive
end

-- ==========================================
-- ZONE CHANGE NOTIFICATIONS
-- ==========================================

--[[
	Notify a player their station should change.
]]
function MusicService:NotifyStationChange(player: Player, station: Station)
	if MusicEvent then
		MusicEvent:FireClient(player, {
			type = "station_change",
			station = station,
		})
	end
end

-- ==========================================
-- PLAYER ZONE TRACKING
-- ==========================================

local playerZones: { [Player]: Station } = {}

local function checkPlayerZone(player: Player)
	local character = player.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	-- Don't change during emergency
	if isEmergencyActive then
		return
	end

	local newStation = MusicService:GetStationForPosition(rootPart.Position)
	local oldStation = playerZones[player]

	if newStation ~= oldStation then
		playerZones[player] = newStation
		MusicService:NotifyStationChange(player, newStation)
		print("[MusicService] Player", player.Name, "entered", newStation, "zone")
	end
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function MusicService:Initialize()
	-- Create music remote event
	local remotes = ReplicatedStorage:WaitForChild("Remotes")

	-- Create MusicEvent if it doesn't exist
	local musicEvent = remotes:FindFirstChild("MusicEvent")
	if not musicEvent then
		musicEvent = Instance.new("RemoteEvent")
		musicEvent.Name = "MusicEvent"
		musicEvent.Parent = remotes
	end
	MusicEvent = musicEvent :: RemoteEvent

	-- Track player zones
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			-- Initial zone check after character loads
			task.delay(1, function()
				checkPlayerZone(player)
			end)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerZones[player] = nil
	end)

	-- Periodic zone checks (every 2 seconds)
	task.spawn(function()
		while true do
			task.wait(2)
			for _, player in Players:GetPlayers() do
				checkPlayerZone(player)
			end
		end
	end)

	-- Handle existing players
	for _, player in Players:GetPlayers() do
		if player.Character then
			task.spawn(function()
				checkPlayerZone(player)
			end)
		end
	end

	print("[MusicService] Initialized")
	print("[MusicService] Crossfade duration:", Config.MUSIC.CROSSFADE_DURATION, "seconds")
end

return MusicService
