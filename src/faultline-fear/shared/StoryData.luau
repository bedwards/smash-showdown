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
		description = "Cross the fault line. Rescue survivors. Build the signal.",
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
				id = "collect_signal_parts",
				title = "Collect Signal Equipment",
				description = "Gather parts for the emergency radio",
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
		completionCondition = "6 signal parts collected OR The Big One triggers",
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
				id = "activate_signal",
				title = "Activate the Signal",
				description = "Use the signal equipment to call for rescue",
				requiredCount = 1,
			},
		},
		triggerCondition = "Act 3 complete",
		completionCondition = "Signal activated at radio tower",
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
		triggerCondition = "Signal activated",
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
		badgeId = 0, -- Placeholder
		creditsSuffix = "You made it out... but at what cost?",
	},
	NEUTRAL = {
		id = "NEUTRAL",
		name = "Survivor",
		description = "You saved some, but not all.",
		survivorsRequired = 4,
		badgeId = 0,
		creditsSuffix = "Some made it. Some didn't. Life goes on.",
	},
	GOOD = {
		id = "GOOD",
		name = "Hero",
		description = "You saved most of the survivors.",
		survivorsRequired = 8,
		badgeId = 0,
		creditsSuffix = "You gave everything to save others. They'll never forget.",
	},
	BEST = {
		id = "BEST",
		name = "True Survivor",
		description = "You saved everyone. No one was left behind.",
		survivorsRequired = 10,
		badgeId = 0,
		creditsSuffix = "Against all odds, everyone made it. A miracle.",
	},
}

-- ==========================================
-- DIALOGUE
-- ==========================================

StoryData.Dialogue = {
	first_survivor = {
		id = "first_survivor",
		name = "Marcus",
		portrait = nil,
		lines = {
			"Hey! Over here!",
			"I thought I was the only one who made it...",
			"The whole town is destroyed. We need to get to higher ground.",
			"I heard there's a radio tower up in the mountains. If we can get there...",
			"But first, we need to find the others. I know there are more survivors out there.",
		},
		triggers = "First survivor rescued in Act 1",
	},

	fault_line_warning = {
		id = "fault_line_warning",
		name = "Marcus",
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
		name = "Marcus",
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
		name = "Marcus",
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
		triggers = "Signal activated in Act 4",
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
	SIGNAL_ACTIVATED = {
		id = "SIGNAL_ACTIVATED",
		name = "Signal Activated",
		description = "The rescue signal has been sent",
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
