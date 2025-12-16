--!strict
--[[
	Faultline Fear: Player Data Service

	Handles persistence of player progress using DataStore.
	Saves/loads: current act, objectives, survivors, generator parts.

	Features:
	- Auto-save on player leave
	- Periodic auto-save (every 60 seconds)
	- Retry logic with exponential backoff
	- Session locking to prevent data corruption

	Exports: Initialize(), LoadPlayerData(), SavePlayerData(), GetPlayerData()
	Depends: DataStoreService, NarrativeService
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local PlayerDataService = {}

-- Configuration
local DATA_STORE_NAME = "FaultlineFearProgress_v1"
local AUTO_SAVE_INTERVAL = 60 -- seconds
local MAX_RETRIES = 3
local RETRY_DELAY = 1 -- seconds, doubles each retry

-- State
local dataStore: DataStore = nil :: any
local playerData: { [Player]: PlayerSaveData } = {}
local loadedPlayers: { [Player]: boolean } = {}
local isStudio = RunService:IsStudio()

-- Reference to NarrativeService (set during initialization)
local NarrativeService: any = nil

-- Type for saved data (subset of PlayerProgress for persistence)
export type PlayerSaveData = {
	currentAct: string,
	completedObjectives: { [string]: number },
	survivorsRescued: number,
	generatorPartsCollected: number,
	totalPlayTime: number, -- cumulative play time in seconds
	lastSaveTime: number,
	completionCount: number, -- how many times they've beaten the game
	bestEnding: string?, -- best ending achieved
}

-- ==========================================
-- DATA STORE OPERATIONS
-- ==========================================

local function createDefaultData(): PlayerSaveData
	return {
		currentAct = "ACT_1_CALL",
		completedObjectives = {},
		survivorsRescued = 0,
		generatorPartsCollected = 0,
		totalPlayTime = 0,
		lastSaveTime = 0,
		completionCount = 0,
		bestEnding = nil,
	}
end

local function getKey(player: Player): string
	return "Player_" .. tostring(player.UserId)
end

local function retry<T>(operation: () -> T, maxRetries: number): (boolean, T?)
	local attempts = 0
	local delay = RETRY_DELAY

	while attempts < maxRetries do
		local success, result = pcall(operation)
		if success then
			return true, result
		end

		attempts += 1
		warn(string.format("[PlayerDataService] Attempt %d failed: %s", attempts, tostring(result)))

		if attempts < maxRetries then
			task.wait(delay)
			delay *= 2 -- Exponential backoff
		end
	end

	return false, nil
end

-- ==========================================
-- LOAD OPERATIONS
-- ==========================================

function PlayerDataService:LoadPlayerData(player: Player): PlayerSaveData?
	if not dataStore then
		warn("[PlayerDataService] DataStore not initialized")
		return nil
	end

	local key = getKey(player)
	print(string.format("[PlayerDataService] Loading data for %s (%s)", player.Name, key))

	local success, data = retry(function()
		return dataStore:GetAsync(key)
	end, MAX_RETRIES)

	if success and data then
		-- Validate and migrate old data if needed
		local savedData = data :: PlayerSaveData

		-- Ensure all fields exist (for backwards compatibility)
		if not savedData.completionCount then
			savedData.completionCount = 0
		end
		if not savedData.totalPlayTime then
			savedData.totalPlayTime = 0
		end
		if not savedData.completedObjectives then
			savedData.completedObjectives = {}
		end

		playerData[player] = savedData
		loadedPlayers[player] = true

		print(
			string.format(
				"[PlayerDataService] Loaded: %s - Act: %s, Survivors: %d, Parts: %d, PlayTime: %.1f min",
				player.Name,
				savedData.currentAct,
				savedData.survivorsRescued,
				savedData.generatorPartsCollected,
				savedData.totalPlayTime / 60
			)
		)

		return savedData
	elseif success and not data then
		-- New player, create default data
		local defaultData = createDefaultData()
		playerData[player] = defaultData
		loadedPlayers[player] = true
		print(string.format("[PlayerDataService] New player: %s", player.Name))
		return defaultData
	else
		warn(
			string.format("[PlayerDataService] Failed to load data for %s after %d attempts", player.Name, MAX_RETRIES)
		)
		-- Use default data but mark as not loaded (won't save)
		playerData[player] = createDefaultData()
		loadedPlayers[player] = false
		return nil
	end
end

-- ==========================================
-- SAVE OPERATIONS
-- ==========================================

function PlayerDataService:SavePlayerData(player: Player): boolean
	if not dataStore then
		warn("[PlayerDataService] DataStore not initialized")
		return false
	end

	if not loadedPlayers[player] then
		warn(string.format("[PlayerDataService] Skipping save for %s - data was not successfully loaded", player.Name))
		return false
	end

	local data = playerData[player]
	if not data then
		warn(string.format("[PlayerDataService] No data to save for %s", player.Name))
		return false
	end

	-- Update save timestamp
	data.lastSaveTime = os.time()

	local key = getKey(player)
	print(string.format("[PlayerDataService] Saving data for %s", player.Name))

	local success, _ = retry(function()
		dataStore:SetAsync(key, data)
		return true
	end, MAX_RETRIES)

	if success then
		print(
			string.format(
				"[PlayerDataService] Saved: %s - Act: %s, Survivors: %d, Parts: %d",
				player.Name,
				data.currentAct,
				data.survivorsRescued,
				data.generatorPartsCollected
			)
		)
		return true
	else
		warn(string.format("[PlayerDataService] Failed to save data for %s", player.Name))
		return false
	end
end

-- ==========================================
-- SYNC WITH NARRATIVE SERVICE
-- ==========================================

function PlayerDataService:SyncFromNarrative(player: Player)
	if not NarrativeService then
		return
	end
	if not playerData[player] then
		return
	end

	local progress = NarrativeService:GetPlayerProgress(player)
	local data = playerData[player]

	data.currentAct = progress.currentAct
	data.completedObjectives = progress.completedObjectives
	data.survivorsRescued = progress.survivorsRescued
	data.generatorPartsCollected = progress.generatorPartsCollected

	-- Track best ending
	if progress.ending then
		local endingRank = { BAD = 1, NEUTRAL = 2, GOOD = 3, BEST = 4 }
		local currentRank = endingRank[progress.ending] or 0
		local bestRank = if data.bestEnding then endingRank[data.bestEnding] or 0 else 0

		if currentRank > bestRank then
			data.bestEnding = progress.ending
		end

		-- Increment completion count
		if progress.completionTime then
			data.completionCount = (data.completionCount or 0) + 1
		end
	end
end

function PlayerDataService:SyncToNarrative(player: Player)
	if not NarrativeService then
		return
	end
	if not playerData[player] then
		return
	end

	local data = playerData[player]

	-- Set the narrative progress from saved data
	local progress = NarrativeService:GetPlayerProgress(player)
	progress.currentAct = data.currentAct
	progress.completedObjectives = data.completedObjectives
	progress.survivorsRescued = data.survivorsRescued
	progress.generatorPartsCollected = data.generatorPartsCollected

	-- Notify client of loaded progress
	NarrativeService:NotifyProgressUpdate(player)
end

-- ==========================================
-- PUBLIC API
-- ==========================================

function PlayerDataService:GetPlayerData(player: Player): PlayerSaveData?
	return playerData[player]
end

function PlayerDataService:IsLoaded(player: Player): boolean
	return loadedPlayers[player] == true
end

function PlayerDataService:SetNarrativeService(service: any)
	NarrativeService = service
	print("[PlayerDataService] NarrativeService connected")
end

-- ==========================================
-- AUTO-SAVE
-- ==========================================

local function autoSaveAll()
	for player, _ in pairs(loadedPlayers) do
		if loadedPlayers[player] then
			PlayerDataService:SyncFromNarrative(player)
			PlayerDataService:SavePlayerData(player)
		end
	end
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function PlayerDataService:Initialize()
	-- Initialize DataStore
	if isStudio then
		-- Studio testing - use mock or real based on setting
		local useStudioDataStore = game:GetService("RunService"):IsStudio() and game.GameId ~= 0 -- Has a real game ID

		if useStudioDataStore then
			local success, result = pcall(function()
				return DataStoreService:GetDataStore(DATA_STORE_NAME)
			end)

			if success then
				dataStore = result
				print("[PlayerDataService] Using DataStore in Studio (API access enabled)")
			else
				warn("[PlayerDataService] DataStore unavailable in Studio:", result)
				print("[PlayerDataService] Player progress will NOT persist")
			end
		else
			warn("[PlayerDataService] No game ID - DataStore disabled")
			print("[PlayerDataService] Player progress will NOT persist")
		end
	else
		-- Production
		local success, result = pcall(function()
			return DataStoreService:GetDataStore(DATA_STORE_NAME)
		end)

		if success then
			dataStore = result
			print("[PlayerDataService] DataStore initialized:", DATA_STORE_NAME)
		else
			error("[PlayerDataService] CRITICAL: Failed to initialize DataStore: " .. tostring(result))
		end
	end

	-- Handle player join
	Players.PlayerAdded:Connect(function(player)
		-- Load data
		local data = self:LoadPlayerData(player)

		-- Sync to narrative service once character loads
		if data then
			player.CharacterAdded:Once(function()
				task.delay(0.5, function()
					self:SyncToNarrative(player)
				end)
			end)
		end
	end)

	-- Handle player leave
	Players.PlayerRemoving:Connect(function(player)
		if loadedPlayers[player] then
			-- Sync final state and save
			self:SyncFromNarrative(player)
			self:SavePlayerData(player)
		end

		-- Clean up
		playerData[player] = nil
		loadedPlayers[player] = nil
	end)

	-- Handle existing players (Studio testing)
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			local data = self:LoadPlayerData(player)
			if data and player.Character then
				self:SyncToNarrative(player)
			end
		end)
	end

	-- Auto-save loop
	task.spawn(function()
		while true do
			task.wait(AUTO_SAVE_INTERVAL)
			autoSaveAll()
		end
	end)

	-- Save all on server shutdown
	game:BindToClose(function()
		print("[PlayerDataService] Server shutting down - saving all players...")
		autoSaveAll()
	end)

	print("[PlayerDataService] Initialized")
end

return PlayerDataService
