--!strict
--[[
	Faultline Fear: Story Data

	Defines the complete narrative arc:
	- Acts and their objectives
	- NPC dialogue and interactions
	- Ending conditions and text
	- Story events and triggers

	This is the single source of truth for the game's story.
]]

local Config = require(script.Parent.Config)

export type ActId = "ACT_1_CALL" | "ACT_2_TRIALS" | "ACT_3_ORDEAL" | "ACT_4_RETURN" | "ACT_5_RESOLUTION"
export type EndingId = "BAD" | "NEUTRAL" | "GOOD" | "BEST"

export type Objective = {
	id: string,
	title: string,
	description: string,
	requiredCount: number?,
	isOptional: boolean?,
}

export type Act = {
	id: ActId,
	name: string,
	description: string,
	objectives: { Objective },
	triggerCondition: string, -- Description of what triggers this act
	completionCondition: string, -- Description of what completes this act
}

export type Ending = {
	id: EndingId,
	name: string,
	description: string,
	survivorsRequired: number,
	badgeId: number?, -- Roblox badge ID (0 = placeholder)
	creditsSuffix: string, -- Text shown after credits
}

export type NPCDialogue = {
	id: string,
	name: string,
	portrait: string?, -- Asset ID for portrait
	lines: { string },
	triggers: string?, -- When this dialogue plays
}

local StoryData = {}

-- ==========================================
-- ACTS
-- ==========================================

StoryData.Acts = {
	ACT_1_CALL = {
		id = "ACT_1_CALL",
		name = "The Call",
		description = "Wake after The First Quake. Learn to survive and find shelter.",
		objectives = {
			{
				id = "wake_up",
				title = "Wake Up",
				description = "Recover from The First Quake",
				requiredCount = 1,
			},
			{
				id = "find_food",
				title = "Find Food",
				description = "Stave off hunger by finding something to eat",
				requiredCount = 1,
			},
			{
				id = "meet_survivor",
				title = "Find a Survivor",
				description = "You're not alone. Find another survivor.",
				requiredCount = 1,
			},
			{
				id = "reach_town",
				title = "Reach the Coastal Town",
				description = "Make your way to the coastal town for shelter",
				requiredCount = 1,
			},
		},
		triggerCondition = "Game start",
		completionCondition = "Player reaches coastal town zone",
	},

	ACT_2_TRIALS = {
		id = "ACT_2_TRIALS",
		name = "Trials",
		description = "Cross the fault line. Rescue survivors. Fix the generator.",
		objectives = {
			{
				id = "cross_fault",
				title = "Cross the Fault Line",
				description = "Find a way across the dangerous fault line",
				requiredCount = 1,
			},
			{
				id = "rescue_survivors",
				title = "Rescue Survivors",
				description = "Find and rescue survivors across the island",
				requiredCount = 10,
			},
			{
				id = "collect_generator_parts",
				title = "Collect Generator Parts",
				description = "Find parts to repair the radio tower's generator",
				requiredCount = 6,
			},
			{
				id = "survive_night",
				title = "Survive the Night",
				description = "Make it through a dangerous night",
				requiredCount = 1,
				isOptional = true,
			},
		},
		triggerCondition = "Act 1 complete",
		completionCondition = "6 generator parts collected OR The Big One triggers",
	},

	ACT_3_ORDEAL = {
		id = "ACT_3_ORDEAL",
		name = "The Ordeal",
		description = "The Big One strikes. The world changes forever.",
		objectives = {
			{
				id = "survive_big_one",
				title = "Survive The Big One",
				description = "Endure the most devastating earthquake yet",
				requiredCount = 1,
			},
			{
				id = "find_survivors_aftermath",
				title = "Check on Survivors",
				description = "Find your rescued survivors in the aftermath",
				requiredCount = 1,
			},
			{
				id = "adapt_new_terrain",
				title = "Navigate New Terrain",
				description = "Find new paths through the changed landscape",
				requiredCount = 1,
			},
		},
		triggerCondition = "The Big One earthquake event",
		completionCondition = "Player reaches mountain base after terrain changes",
	},

	ACT_4_RETURN = {
		id = "ACT_4_RETURN",
		name = "The Return",
		description = "Ascend the mountain. Reach the radio tower.",
		objectives = {
			{
				id = "ascend_mountain",
				title = "Ascend the Mountain",
				description = "Climb to the radio tower at the summit",
				requiredCount = 1,
			},
			{
				id = "gather_group",
				title = "Gather Your Group",
				description = "Bring your survivors to the extraction point",
				requiredCount = 1,
			},
			{
				id = "activate_radio",
				title = "Power the Radio",
				description = "Start the generator and broadcast a distress signal",
				requiredCount = 1,
			},
		},
		triggerCondition = "Act 3 complete",
		completionCondition = "Generator powered and radio signal sent",
	},

	ACT_5_RESOLUTION = {
		id = "ACT_5_RESOLUTION",
		name = "Resolution",
		description = "Rescue arrives. Your journey ends.",
		objectives = {
			{
				id = "await_rescue",
				title = "Await Rescue",
				description = "Wait for the rescue helicopter",
				requiredCount = 1,
			},
			{
				id = "board_helicopter",
				title = "Board the Helicopter",
				description = "Get to safety",
				requiredCount = 1,
			},
		},
		triggerCondition = "Radio signal broadcast",
		completionCondition = "Player boards helicopter - GAME COMPLETE",
	},
}

-- Act order for progression
StoryData.ActOrder = {
	"ACT_1_CALL",
	"ACT_2_TRIALS",
	"ACT_3_ORDEAL",
	"ACT_4_RETURN",
	"ACT_5_RESOLUTION",
}

-- ==========================================
-- ENDINGS
-- ==========================================

StoryData.Endings = {
	BAD = {
		id = "BAD",
		name = "Lone Survivor",
		description = "You escaped, but left many behind.",
		survivorsRequired = 0,
		badgeId = Config.BADGES.SURVIVOR,
		creditsSuffix = "You made it out... but at what cost?",
	},
	NEUTRAL = {
		id = "NEUTRAL",
		name = "Survivor",
		description = "You saved some, but not all.",
		survivorsRequired = 4,
		badgeId = Config.BADGES.SURVIVOR,
		creditsSuffix = "Some made it. Some didn't. Life goes on.",
	},
	GOOD = {
		id = "GOOD",
		name = "Hero",
		description = "You saved most of the survivors.",
		survivorsRequired = 8,
		badgeId = Config.BADGES.SURVIVOR,
		creditsSuffix = "You gave everything to save others. They'll never forget.",
	},
	BEST = {
		id = "BEST",
		name = "True Survivor",
		description = "You saved everyone. No one was left behind.",
		survivorsRequired = 10,
		badgeId = Config.BADGES.SURVIVOR,
		creditsSuffix = "Against all odds, everyone made it. A miracle.",
	},
}

-- ==========================================
-- DIALOGUE
-- ==========================================

StoryData.Dialogue = {
	first_survivor = {
		id = "first_survivor",
		name = "Riley",
		portrait = nil,
		lines = {
			"Hey! Over here!",
			"I thought I was the only one who made it...",
			"The whole town is destroyed. We need to get to higher ground.",
			"I heard there's a radio tower up in the mountains. If we can get there...",
			"The generator's busted though. We'll need parts - spark plug, carburetor, fuel line...",
			"But first, we need to find the others. I know there are more survivors out there.",
		},
		triggers = "First survivor rescued in Act 1",
	},

	generator_part_found = {
		id = "generator_part_found",
		name = "Riley",
		portrait = nil,
		lines = {
			"That's a generator part! We need six total to get that radio tower running.",
			"Spark plug, carburetor, pull cord, fuel line, air filter, and ignition coil.",
			"Keep your eyes open. They could be anywhere.",
		},
		triggers = "First generator part collected",
	},

	fault_line_warning = {
		id = "fault_line_warning",
		name = "Riley",
		portrait = nil,
		lines = {
			"This is it. The fault line.",
			"Be careful. The ground here is unstable.",
			"I've heard the quakes are getting worse. We need to move fast.",
		},
		triggers = "Player approaches fault line",
	},

	big_one_aftermath = {
		id = "big_one_aftermath",
		name = "Riley",
		portrait = nil,
		lines = {
			"Is everyone okay?!",
			"The whole island has changed... Look at that cliff. It wasn't there before.",
			"We have to keep moving. The mountain is our only hope now.",
		},
		triggers = "After The Big One in Act 3",
	},

	final_ascent = {
		id = "final_ascent",
		name = "Riley",
		portrait = nil,
		lines = {
			"This is it. The radio tower is just ahead.",
			"Once we signal for help, it's out of our hands.",
			"Whatever happens... thank you. For not giving up.",
		},
		triggers = "Start of Act 4",
	},

	rescue_arrives = {
		id = "rescue_arrives",
		name = "Radio",
		portrait = nil,
		lines = {
			"*static* ...Rescue Team Alpha... *static*",
			"We've received your signal. Helicopter en route.",
			"Hold your position. ETA fifteen minutes.",
			"You did it, survivor. Help is on the way.",
		},
		triggers = "Radio broadcast in Act 4",
	},
}

-- ==========================================
-- STORY EVENTS
-- ==========================================

StoryData.Events = {
	FIRST_QUAKE = {
		id = "FIRST_QUAKE",
		name = "The First Quake",
		description = "The earthquake that starts the story",
		triggersAct = "ACT_1_CALL",
	},
	BIG_ONE = {
		id = "BIG_ONE",
		name = "The Big One",
		description = "The massive earthquake that changes the world",
		triggersAct = "ACT_3_ORDEAL",
	},
	BIG_ONE_ENDED = {
		id = "BIG_ONE_ENDED",
		name = "The Aftermath",
		description = "The Big One is over - the world has changed forever",
		triggersObjective = "survive_big_one",
	},
	RADIO_BROADCAST = {
		id = "RADIO_BROADCAST",
		name = "Radio Broadcast",
		description = "The generator is running and the rescue signal has been sent",
		triggersAct = "ACT_5_RESOLUTION",
	},
	RESCUE_ARRIVAL = {
		id = "RESCUE_ARRIVAL",
		name = "Rescue Arrives",
		description = "The helicopter has arrived",
		triggersEnding = true,
	},
}

-- ==========================================
-- STORY BEATS (Data-Driven Triggers)
-- ==========================================

export type TriggerType = "zone_enter" | "object_collect" | "npc_interact" | "time_elapsed" | "event"

export type StoryBeat = {
	id: string,
	actRequired: ActId?,
	triggerType: TriggerType,
	triggerData: {
		zoneId: string?,
		objectTag: string?,
		npcId: string?,
		eventId: string?,
		delaySeconds: number?,
	},
	conditions: {
		objectivesComplete: { string }?,
		survivorsRescued: number?,
		generatorParts: number?,
		timeOfDay: string?,
	}?,
	effects: {
		completeObjective: string?,
		playDialogue: string?,
		triggerEvent: string?,
		advanceAct: boolean?,
	},
	repeatable: boolean,
	globalTrigger: boolean?,
}

StoryData.Beats = {
	-- ==========================================
	-- ACT 1: THE CALL
	-- ==========================================

	wake_up = {
		id = "wake_up",
		actRequired = "ACT_1_CALL",
		triggerType = "event",
		triggerData = { eventId = "GAME_START" },
		effects = {
			completeObjective = "wake_up",
		},
		repeatable = false,
	},

	first_food_found = {
		id = "first_food_found",
		actRequired = "ACT_1_CALL",
		triggerType = "object_collect",
		triggerData = { objectTag = "Food" },
		conditions = {
			objectivesComplete = { "wake_up" },
		},
		effects = {
			completeObjective = "find_food",
		},
		repeatable = false,
	},

	first_survivor_found = {
		id = "first_survivor_found",
		actRequired = "ACT_1_CALL",
		triggerType = "npc_interact",
		triggerData = { objectTag = "Rescuable" },
		effects = {
			completeObjective = "meet_survivor",
			playDialogue = "first_survivor",
		},
		repeatable = false,
	},

	reach_coastal_town = {
		id = "reach_coastal_town",
		actRequired = "ACT_1_CALL",
		triggerType = "zone_enter",
		triggerData = { zoneId = "CoastalTown" },
		conditions = {
			objectivesComplete = { "meet_survivor" },
		},
		effects = {
			completeObjective = "reach_town",
			triggerEvent = "ACT_1_COMPLETE",
			advanceAct = true,
		},
		repeatable = false,
	},

	-- ==========================================
	-- ACT 2: TRIALS
	-- ==========================================

	cross_fault_line = {
		id = "cross_fault_line",
		actRequired = "ACT_2_TRIALS",
		triggerType = "zone_enter",
		triggerData = { zoneId = "FaultLineNorth" },
		effects = {
			completeObjective = "cross_fault",
			playDialogue = "fault_line_warning",
		},
		repeatable = false,
	},

	generator_part_collected = {
		id = "generator_part_collected",
		actRequired = "ACT_2_TRIALS",
		triggerType = "object_collect",
		triggerData = { objectTag = "GeneratorPart" },
		effects = {
			completeObjective = "collect_generator_parts",
		},
		repeatable = true, -- Can collect multiple
	},

	first_generator_part = {
		id = "first_generator_part",
		actRequired = "ACT_2_TRIALS",
		triggerType = "object_collect",
		triggerData = { objectTag = "GeneratorPart" },
		effects = {
			playDialogue = "generator_part_found",
		},
		repeatable = false,
	},

	survivor_rescued = {
		id = "survivor_rescued",
		triggerType = "npc_interact",
		triggerData = { objectTag = "Rescuable" },
		effects = {
			completeObjective = "rescue_survivors",
		},
		repeatable = true, -- Can rescue multiple
	},

	first_night_survived = {
		id = "first_night_survived",
		actRequired = "ACT_2_TRIALS",
		triggerType = "event",
		triggerData = { eventId = "DAWN_AFTER_FIRST_NIGHT" },
		effects = {
			completeObjective = "survive_night",
		},
		repeatable = false,
	},

	-- ==========================================
	-- ACT 3: THE ORDEAL
	-- ==========================================

	big_one_starts = {
		id = "big_one_starts",
		triggerType = "event",
		triggerData = { eventId = "BIG_ONE" },
		effects = {
			triggerEvent = "ACT_2_COMPLETE",
			advanceAct = true,
		},
		repeatable = false,
		globalTrigger = true,
	},

	big_one_survived = {
		id = "big_one_survived",
		actRequired = "ACT_3_ORDEAL",
		triggerType = "event",
		triggerData = { eventId = "BIG_ONE_ENDED" },
		effects = {
			completeObjective = "survive_big_one",
			playDialogue = "big_one_aftermath",
		},
		repeatable = false,
	},

	check_survivors_aftermath = {
		id = "check_survivors_aftermath",
		actRequired = "ACT_3_ORDEAL",
		triggerType = "zone_enter",
		triggerData = { zoneId = "SurvivorCamp" },
		conditions = {
			objectivesComplete = { "survive_big_one" },
		},
		effects = {
			completeObjective = "find_survivors_aftermath",
		},
		repeatable = false,
	},

	reach_mountain_base = {
		id = "reach_mountain_base",
		actRequired = "ACT_3_ORDEAL",
		triggerType = "zone_enter",
		triggerData = { zoneId = "MountainBase" },
		effects = {
			completeObjective = "adapt_new_terrain",
			triggerEvent = "ACT_3_COMPLETE",
			advanceAct = true,
		},
		repeatable = false,
	},

	-- ==========================================
	-- ACT 4: THE RETURN
	-- ==========================================

	reach_radio_tower = {
		id = "reach_radio_tower",
		actRequired = "ACT_4_RETURN",
		triggerType = "zone_enter",
		triggerData = { zoneId = "RadioTower" },
		effects = {
			completeObjective = "ascend_mountain",
			playDialogue = "final_ascent",
		},
		repeatable = false,
	},

	group_gathered = {
		id = "group_gathered",
		actRequired = "ACT_4_RETURN",
		triggerType = "event",
		triggerData = { eventId = "SURVIVORS_AT_TOWER" },
		effects = {
			completeObjective = "gather_group",
		},
		repeatable = false,
	},

	activate_radio = {
		id = "activate_radio",
		actRequired = "ACT_4_RETURN",
		triggerType = "npc_interact",
		triggerData = { objectTag = "RadioTower" },
		conditions = {
			objectivesComplete = { "ascend_mountain" },
			generatorParts = 6,
		},
		effects = {
			completeObjective = "activate_radio",
			triggerEvent = "RADIO_BROADCAST",
			playDialogue = "rescue_arrives",
			advanceAct = true,
		},
		repeatable = false,
	},

	-- ==========================================
	-- ACT 5: RESOLUTION
	-- ==========================================

	helicopter_arrives = {
		id = "helicopter_arrives",
		actRequired = "ACT_5_RESOLUTION",
		triggerType = "time_elapsed",
		triggerData = { delaySeconds = 60, afterEvent = "RADIO_BROADCAST" },
		effects = {
			completeObjective = "await_rescue",
			triggerEvent = "HELICOPTER_ARRIVED",
		},
		repeatable = false,
		globalTrigger = true,
	},

	board_helicopter = {
		id = "board_helicopter",
		actRequired = "ACT_5_RESOLUTION",
		triggerType = "zone_enter",
		triggerData = { zoneId = "HelicopterZone" },
		conditions = {
			objectivesComplete = { "await_rescue" },
		},
		effects = {
			completeObjective = "board_helicopter",
			triggerEvent = "GAME_COMPLETE",
		},
		repeatable = false,
	},
}

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================

function StoryData.GetAct(actId: ActId): Act
	return StoryData.Acts[actId]
end

function StoryData.GetNextAct(currentActId: ActId): ActId?
	for i, actId in ipairs(StoryData.ActOrder) do
		if actId == currentActId and i < #StoryData.ActOrder then
			return StoryData.ActOrder[i + 1]
		end
	end
	return nil
end

function StoryData.GetEndingForSurvivors(survivorCount: number): Ending
	local result = StoryData.Endings.BAD

	for _, ending in pairs(StoryData.Endings) do
		if survivorCount >= ending.survivorsRequired then
			if ending.survivorsRequired > result.survivorsRequired then
				result = ending
			end
		end
	end

	return result
end

function StoryData.GetDialogue(dialogueId: string): NPCDialogue?
	return StoryData.Dialogue[dialogueId]
end

return StoryData
