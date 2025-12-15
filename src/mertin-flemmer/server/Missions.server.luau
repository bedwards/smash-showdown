--!strict
-- Mission & Quest System for Mertin-Flemmer
-- Always have 2-4 active goals, clear status tracking
-- Inspired by Elder Scrolls quest system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

-- Create remotes
local MissionUpdateRemote = Instance.new("RemoteEvent")
MissionUpdateRemote.Name = "MissionUpdate"
MissionUpdateRemote.Parent = ReplicatedStorage

local MissionCompleteRemote = Instance.new("RemoteEvent")
MissionCompleteRemote.Name = "MissionComplete"
MissionCompleteRemote.Parent = ReplicatedStorage

-- ==========================================
-- MISSION DEFINITIONS
-- ==========================================

type Mission = {
	id: string,
	title: string,
	description: string,
	category: string, -- "main", "side", "daily", "exploration"
	objectives: { {
		id: string,
		description: string,
		type: string, -- "collect", "kill", "visit", "survive", "craft", "talk"
		target: string,
		required: number,
		current: number,
	} },
	rewards: {
		experience: number,
		items: { string }?,
		unlocks: string?,
	},
	prerequisites: { string }?, -- Mission IDs that must be completed first
	repeatable: boolean,
	timeLimit: number?, -- In seconds, nil = no limit
}

-- MAIN STORY MISSIONS
local MAIN_MISSIONS: { Mission } = {
	{
		id = "survive_first_night",
		title = "Survive the Night",
		description = "The darkness brings danger. Find shelter and survive until dawn.",
		category = "main",
		objectives = {
			{ id = "survive", description = "Survive 1 night", type = "survive", target = "night", required = 1, current = 0 },
		},
		rewards = { experience = 100, items = { "Torch" } },
		repeatable = false,
	},
	{
		id = "find_campfire",
		title = "Light in the Darkness",
		description = "Campfires provide safety from creatures. Find one before nightfall.",
		category = "main",
		objectives = {
			{ id = "visit_campfire", description = "Reach a campfire", type = "visit", target = "Campfire", required = 1, current = 0 },
		},
		rewards = { experience = 50, items = { "Wood", "Wood", "Wood" } },
		repeatable = false,
	},
	{
		id = "meet_hermit",
		title = "The Hermit's Wisdom",
		description = "Seek out one of the hermits who live in the caves. They may have knowledge to share.",
		category = "main",
		objectives = {
			{ id = "find_cave", description = "Find a hermit's cave", type = "visit", target = "Cave_", required = 1, current = 0 },
		},
		rewards = { experience = 150, unlocks = "alchemy" },
		prerequisites = { "survive_first_night" },
		repeatable = false,
	},
	{
		id = "explore_biomes",
		title = "The Wide World",
		description = "This land is vast and varied. Explore the different regions.",
		category = "main",
		objectives = {
			{ id = "visit_forest", description = "Explore the Whispering Woods", type = "visit", target = "Waystone_Northern", required = 1, current = 0 },
			{ id = "visit_snow", description = "Brave the Frozen Wastes", type = "visit", target = "Portal_Frozen", required = 1, current = 0 },
			{ id = "visit_desert", description = "Cross the Scorched Sands", type = "visit", target = "Portal_Scorched", required = 1, current = 0 },
		},
		rewards = { experience = 300, items = { "Map Fragment", "Compass" } },
		prerequisites = { "find_campfire" },
		repeatable = false,
	},
	{
		id = "floor_seven_half",
		title = "The 7½ Floor",
		description = "Strange rumors speak of an office building with an impossible floor. Find the Mertin-Flemmer building.",
		category = "main",
		objectives = {
			{ id = "find_building", description = "Find the Mertin-Flemmer building", type = "visit", target = "MertinFlemmerBuilding", required = 1, current = 0 },
			{ id = "reach_floor", description = "Reach Floor 7½", type = "visit", target = "Floor75_Floor", required = 1, current = 0 },
		},
		rewards = { experience = 500, unlocks = "office_secrets" },
		prerequisites = { "survive_first_night" },
		repeatable = false,
	},
	{
		id = "face_the_stalker",
		title = "Face the Stalker",
		description = "The Deer Monster lurks in the darkness. Encounter it and survive.",
		category = "main",
		objectives = {
			{ id = "encounter", description = "Encounter the Deer Monster", type = "visit", target = "DeerMonster_", required = 1, current = 0 },
			{ id = "survive", description = "Escape with your life", type = "survive", target = "stalker_encounter", required = 1, current = 0 },
		},
		rewards = { experience = 400, items = { "Stalker's Tooth" } },
		prerequisites = { "survive_first_night" },
		repeatable = false,
	},
}

-- SIDE MISSIONS (always rotating)
local SIDE_MISSIONS: { Mission } = {
	{
		id = "gather_wood",
		title = "Fuel for the Fire",
		description = "Gather wood to keep campfires burning through the night.",
		category = "side",
		objectives = {
			{ id = "collect_wood", description = "Collect wood", type = "collect", target = "WOOD", required = 5, current = 0 },
		},
		rewards = { experience = 30 },
		repeatable = true,
	},
	{
		id = "gather_food",
		title = "Staving Off Hunger",
		description = "Find food to survive. Starvation is a slow death.",
		category = "side",
		objectives = {
			{ id = "collect_food", description = "Collect food", type = "collect", target = "FOOD", required = 3, current = 0 },
		},
		rewards = { experience = 30 },
		repeatable = true,
	},
	{
		id = "find_batteries",
		title = "Power Up",
		description = "Your flashlight is your lifeline. Find batteries to keep it running.",
		category = "side",
		objectives = {
			{ id = "collect_batteries", description = "Find batteries", type = "collect", target = "BATTERY", required = 2, current = 0 },
		},
		rewards = { experience = 40 },
		repeatable = true,
	},
	{
		id = "slay_wolves",
		title = "Wolf Hunter",
		description = "The wolves grow bold. Thin their numbers.",
		category = "side",
		objectives = {
			{ id = "kill_wolves", description = "Defeat wolves", type = "kill", target = "Wolf_", required = 3, current = 0 },
		},
		rewards = { experience = 80, items = { "Wolf Pelt" } },
		repeatable = true,
	},
	{
		id = "survive_blood_night",
		title = "Blood Moon Rising",
		description = "A blood night approaches. Survive until dawn.",
		category = "side",
		objectives = {
			{ id = "survive", description = "Survive the Blood Night", type = "survive", target = "blood_night", required = 1, current = 0 },
		},
		rewards = { experience = 200, items = { "Blood Moon Crystal" } },
		repeatable = true,
	},
	{
		id = "waterfall_meditation",
		title = "Serenity",
		description = "Find peace at a waterfall. Stand in its mist.",
		category = "side",
		objectives = {
			{ id = "visit_waterfall", description = "Visit a waterfall", type = "visit", target = "Waterfall_", required = 1, current = 0 },
		},
		rewards = { experience = 50 },
		repeatable = true,
	},
	{
		id = "beach_combing",
		title = "Treasures of the Shore",
		description = "The beaches hold secrets. Explore the coastline.",
		category = "side",
		objectives = {
			{ id = "visit_beach", description = "Visit a beach", type = "visit", target = "Beach", required = 1, current = 0 },
		},
		rewards = { experience = 40, items = { "Pearl" } },
		repeatable = true,
	},
}

-- DAILY MISSIONS (reset each day cycle)
local DAILY_MISSIONS: { Mission } = {
	{
		id = "daily_survival",
		title = "Another Day",
		description = "Survive another full day/night cycle.",
		category = "daily",
		objectives = {
			{ id = "survive_day", description = "Survive until night", type = "survive", target = "day", required = 1, current = 0 },
			{ id = "survive_night", description = "Survive the night", type = "survive", target = "night", required = 1, current = 0 },
		},
		rewards = { experience = 100 },
		repeatable = true,
	},
	{
		id = "daily_explore",
		title = "Wanderer",
		description = "Travel far from spawn today.",
		category = "daily",
		objectives = {
			{ id = "travel", description = "Travel 1000 studs from spawn", type = "visit", target = "distance_1000", required = 1, current = 0 },
		},
		rewards = { experience = 60 },
		repeatable = true,
	},
	{
		id = "daily_gather",
		title = "Provisions",
		description = "Gather supplies for the coming night.",
		category = "daily",
		objectives = {
			{ id = "gather", description = "Collect any 5 resources", type = "collect", target = "ANY", required = 5, current = 0 },
		},
		rewards = { experience = 50 },
		repeatable = true,
	},
}

-- ==========================================
-- PLAYER MISSION STATE
-- ==========================================

type PlayerMissionState = {
	activeMissions: { [string]: Mission },
	completedMissions: { [string]: boolean },
	experience: number,
	level: number,
	stats: {
		nightsSurvived: number,
		creaturesKilled: number,
		resourcesCollected: number,
		distanceTraveled: number,
		cavesExplored: number,
	},
}

local playerMissions: { [Player]: PlayerMissionState } = {}

-- ==========================================
-- MISSION FUNCTIONS
-- ==========================================

local function createMissionCopy(mission: Mission): Mission
	local copy: Mission = {
		id = mission.id,
		title = mission.title,
		description = mission.description,
		category = mission.category,
		objectives = {},
		rewards = {
			experience = mission.rewards.experience,
			items = mission.rewards.items,
			unlocks = mission.rewards.unlocks,
		},
		prerequisites = mission.prerequisites,
		repeatable = mission.repeatable,
		timeLimit = mission.timeLimit,
	}

	for _, obj in mission.objectives do
		table.insert(copy.objectives, {
			id = obj.id,
			description = obj.description,
			type = obj.type,
			target = obj.target,
			required = obj.required,
			current = 0,
		})
	end

	return copy
end

local function initPlayerMissions(player: Player)
	playerMissions[player] = {
		activeMissions = {},
		completedMissions = {},
		experience = 0,
		level = 1,
		stats = {
			nightsSurvived = 0,
			creaturesKilled = 0,
			resourcesCollected = 0,
			distanceTraveled = 0,
			cavesExplored = 0,
		},
	}

	-- Assign initial missions
	local state = playerMissions[player]

	-- Main missions (first few unlocked)
	state.activeMissions["survive_first_night"] = createMissionCopy(MAIN_MISSIONS[1])
	state.activeMissions["find_campfire"] = createMissionCopy(MAIN_MISSIONS[2])

	-- Random side mission
	local sideIndex = math.random(1, #SIDE_MISSIONS)
	local sideMission = createMissionCopy(SIDE_MISSIONS[sideIndex])
	state.activeMissions[sideMission.id] = sideMission

	-- Daily mission
	local dailyIndex = math.random(1, #DAILY_MISSIONS)
	local dailyMission = createMissionCopy(DAILY_MISSIONS[dailyIndex])
	state.activeMissions[dailyMission.id] = dailyMission

	-- Send initial state to client
	sendMissionUpdate(player)

	print("[Missions] Initialized missions for", player.Name)
end

local function cleanupPlayerMissions(player: Player)
	playerMissions[player] = nil
end

function sendMissionUpdate(player: Player)
	local state = playerMissions[player]
	if not state then return end

	-- Build mission summary for UI
	local missionData = {}
	for id, mission in state.activeMissions do
		local objectives = {}
		for _, obj in mission.objectives do
			table.insert(objectives, {
				description = obj.description,
				current = obj.current,
				required = obj.required,
				complete = obj.current >= obj.required,
			})
		end

		missionData[id] = {
			title = mission.title,
			description = mission.description,
			category = mission.category,
			objectives = objectives,
		}
	end

	MissionUpdateRemote:FireClient(player, "UPDATE", {
		missions = missionData,
		experience = state.experience,
		level = state.level,
		stats = state.stats,
	})
end

local function checkMissionCompletion(player: Player, missionId: string)
	local state = playerMissions[player]
	if not state then return end

	local mission = state.activeMissions[missionId]
	if not mission then return end

	-- Check if all objectives complete
	local allComplete = true
	for _, obj in mission.objectives do
		if obj.current < obj.required then
			allComplete = false
			break
		end
	end

	if allComplete then
		-- Complete the mission!
		state.completedMissions[missionId] = true
		state.activeMissions[missionId] = nil

		-- Award rewards
		state.experience += mission.rewards.experience

		-- Level up check (every 500 XP)
		local newLevel = math.floor(state.experience / 500) + 1
		if newLevel > state.level then
			state.level = newLevel
			MissionCompleteRemote:FireClient(player, "LEVEL_UP", state.level)
		end

		MissionCompleteRemote:FireClient(player, "COMPLETE", {
			title = mission.title,
			experience = mission.rewards.experience,
			items = mission.rewards.items,
		})

		print("[Missions]", player.Name, "completed:", mission.title)

		-- Unlock new missions based on prerequisites
		for _, mainMission in MAIN_MISSIONS do
			if mainMission.prerequisites then
				local canUnlock = true
				for _, prereq in mainMission.prerequisites do
					if not state.completedMissions[prereq] then
						canUnlock = false
						break
					end
				end

				if canUnlock and not state.activeMissions[mainMission.id] and not state.completedMissions[mainMission.id] then
					state.activeMissions[mainMission.id] = createMissionCopy(mainMission)
					MissionUpdateRemote:FireClient(player, "NEW_MISSION", mainMission.title)
				end
			end
		end

		-- Assign new side mission if needed (maintain 2-4 active)
		local activeCount = 0
		for _ in state.activeMissions do
			activeCount += 1
		end

		if activeCount < 3 then
			-- Add a new side mission
			local available = {}
			for _, side in SIDE_MISSIONS do
				if not state.activeMissions[side.id] then
					table.insert(available, side)
				end
			end

			if #available > 0 then
				local newMission = available[math.random(1, #available)]
				state.activeMissions[newMission.id] = createMissionCopy(newMission)
				MissionUpdateRemote:FireClient(player, "NEW_MISSION", newMission.title)
			end
		end

		sendMissionUpdate(player)
	end
end

-- ==========================================
-- MISSION PROGRESS TRACKING
-- ==========================================

-- Track visiting locations
local function trackVisit(player: Player, objectName: string)
	local state = playerMissions[player]
	if not state then return end

	for missionId, mission in state.activeMissions do
		for _, obj in mission.objectives do
			if obj.type == "visit" and obj.current < obj.required then
				if string.find(objectName, obj.target) then
					obj.current += 1
					sendMissionUpdate(player)
					checkMissionCompletion(player, missionId)
				end
			end
		end
	end
end

-- Track collecting resources
local function trackCollect(player: Player, resourceType: string)
	local state = playerMissions[player]
	if not state then return end

	state.stats.resourcesCollected += 1

	for missionId, mission in state.activeMissions do
		for _, obj in mission.objectives do
			if obj.type == "collect" and obj.current < obj.required then
				if obj.target == resourceType or obj.target == "ANY" then
					obj.current += 1
					sendMissionUpdate(player)
					checkMissionCompletion(player, missionId)
				end
			end
		end
	end
end

-- Track killing creatures
local function trackKill(player: Player, creatureName: string)
	local state = playerMissions[player]
	if not state then return end

	state.stats.creaturesKilled += 1

	for missionId, mission in state.activeMissions do
		for _, obj in mission.objectives do
			if obj.type == "kill" and obj.current < obj.required then
				if string.find(creatureName, obj.target) then
					obj.current += 1
					sendMissionUpdate(player)
					checkMissionCompletion(player, missionId)
				end
			end
		end
	end
end

-- Track survival
local function trackSurvival(player: Player, survivalType: string)
	local state = playerMissions[player]
	if not state then return end

	if survivalType == "night" then
		state.stats.nightsSurvived += 1
	end

	for missionId, mission in state.activeMissions do
		for _, obj in mission.objectives do
			if obj.type == "survive" and obj.current < obj.required then
				if obj.target == survivalType then
					obj.current += 1
					sendMissionUpdate(player)
					checkMissionCompletion(player, missionId)
				end
			end
		end
	end
end

-- ==========================================
-- EVENT LISTENERS
-- ==========================================

-- Listen for resource collection
local CollectResourceRemote = ReplicatedStorage:WaitForChild("CollectResource")
CollectResourceRemote.OnServerEvent:Connect(function(player: Player, action: string, resourceType: string)
	if action == "COLLECTED" then
		trackCollect(player, resourceType)
	end
end)

-- Listen for objective updates
local ObjectiveUpdateRemote = ReplicatedStorage:WaitForChild("ObjectiveUpdate")
ObjectiveUpdateRemote.OnServerEvent:Connect(function(player: Player, eventType: string, data: any)
	if eventType == "NIGHT_SURVIVED" then
		trackSurvival(player, "night")
	elseif eventType == "DAY_SURVIVED" then
		trackSurvival(player, "day")
	elseif eventType == "BLOOD_NIGHT_SURVIVED" then
		trackSurvival(player, "blood_night")
	end
end)

-- Track proximity to objects for visit missions
local function checkPlayerProximity()
	for player, state in playerMissions do
		local character = player.Character
		if not character then continue end

		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not rootPart then continue end

		local playerPos = rootPart.Position

		-- Check distance from spawn for exploration
		local distFromSpawn = playerPos.Magnitude
		if distFromSpawn > 1000 then
			trackVisit(player, "distance_1000")
		end

		-- Check proximity to objects
		for _, obj in workspace:GetDescendants() do
			if obj:IsA("Model") or obj:IsA("BasePart") then
				local objPos: Vector3
				if obj:IsA("Model") then
					local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
					if primary then
						objPos = primary.Position
					else
						continue
					end
				else
					objPos = obj.Position
				end

				local distance = (playerPos - objPos).Magnitude
				if distance < 20 then
					trackVisit(player, obj.Name)
				end
			end
		end
	end
end

-- ==========================================
-- GAME LOOP
-- ==========================================

local proximityCheckTimer = 0
RunService.Heartbeat:Connect(function(dt)
	proximityCheckTimer += dt
	if proximityCheckTimer >= 2 then -- Check every 2 seconds
		proximityCheckTimer = 0
		checkPlayerProximity()
	end
end)

-- ==========================================
-- PLAYER SETUP
-- ==========================================

Players.PlayerAdded:Connect(function(player)
	task.wait(2) -- Wait for other systems to initialize
	initPlayerMissions(player)
end)

Players.PlayerRemoving:Connect(cleanupPlayerMissions)

-- Initialize existing players
for _, player in Players:GetPlayers() do
	task.spawn(function()
		task.wait(2)
		initPlayerMissions(player)
	end)
end

print("[Missions] Mission system initialized!")
print("[Missions] Players always have 2-4 active objectives")
print("[Missions] Categories: Main Story, Side Quests, Daily Challenges")
