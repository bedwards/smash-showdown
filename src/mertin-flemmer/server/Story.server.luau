--!strict
-- Story System for Mertin-Flemmer
-- Full backstory, plot signs, danger mechanics, and impending doom

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

-- Create remotes
local StoryRemote = Instance.new("RemoteEvent")
StoryRemote.Name = "Story"
StoryRemote.Parent = ReplicatedStorage

-- ==========================================
-- THE BACKSTORY
-- ==========================================
--[[
THE MERTIN-FLEMMER INCIDENT

Three months ago, the Mertin-Flemmer Corporation opened a portal. They claimed
it was for "interdimensional resource extraction." They were wrong.

Something came through. Something ancient. Something hungry.

The Stalker - a creature from beyond our dimension - emerged first. It wore the
skull of a deer, mockery of nature itself. Where it walked, reality grew thin.

Then came the others: Shadows that wore human form but moved wrong. Wolves with
too many eyes. Creatures that existed only in darkness.

The corporation's 20-story headquarters became ground zero. Floor 7½ appeared
overnight - a space that shouldn't exist, a wound in reality where the portal
still bleeds.

The evacuation was chaos. Most fled. Some stayed to try to close the portal.
None succeeded.

Now the creatures spread further each night. The darkness grows longer.
The signal towers - once used for communication - are the only hope.
Three signal parts, scattered by the desperate, can call for rescue.

But the creatures are learning. They've started taking the pets first -
drawing out the survivors, isolating them. The pirates of the Black Mist
saw opportunity in chaos, capturing animals to sell to whatever waits
on the other side.

You are a survivor who stumbled into this nightmare.
The clock is ticking.
The darkness is hungry.
And something is watching you right now.
]]

-- ==========================================
-- STORY CHAPTERS & SIGNS
-- ==========================================

local STORY_SIGNS = {
	-- CHAPTER 1: THE AWAKENING (Near Spawn)
	{
		chapter = 1,
		title = "The Awakening",
		position = Vector3.new(20, 0, -10),
		content = [[SURVIVOR'S NOTICE

You've awakened in the quarantine zone.
The Mertin-Flemmer Corporation's experiments
have unleashed something upon this land.

IMMEDIATE DANGERS:
- The Stalker hunts at night
- Shadows emerge after dark
- Starvation claims the idle
- The cold takes the unprepared

OBJECTIVES:
1. Find food immediately
2. Locate shelter before nightfall
3. Seek the three Signal Parts
4. Rescue the captured pets

DO NOT REMAIN STILL.
Movement is survival.

- Emergency Broadcast System]],
	},
	{
		chapter = 1,
		title = "Warning: Inactivity Kills",
		position = Vector3.new(-30, 0, 10),
		content = [[MEDICAL NOTICE

Extended inactivity leads to:
- Accelerated hunger (metabolism spike)
- Fear accumulation (paranoia)
- Creature attraction (scent)
- Doom manifestation (???)

The creatures can SMELL despair.
If you stop moving, THEY WILL FIND YOU.

Those who sit idle have been found
as nothing but bones within hours.

KEEP MOVING. STAY ALIVE.

- Dr. Helena Voss, Last Medical Officer]],
	},

	-- CHAPTER 2: THE NORTHERN PATH (Forest Route)
	{
		chapter = 2,
		title = "The Whispering Woods",
		position = Vector3.new(30, 5, 150),
		content = [[RANGER STATION LOG - Day 47

The forest has changed. Trees move when
you're not looking. The whispers aren't
wind - they're warnings.

The Fairy Folk emerged after the portal
opened. Some say they're trying to help.
Others say they're leading us deeper in.

Lost Children Report:
- Tommy Vance, age 8, last seen Day 12
- Sarah Mills, age 6, last seen Day 23
- Marcus Chen, age 10, last seen Day 31

Their mother still searches.
We've seen small footprints near the
fairy circles. Whether hope or tragedy
awaits, we cannot say.

- Ranger Elias Thorne]],
	},
	{
		chapter = 2,
		title = "The Forest Guardian",
		position = Vector3.new(60, 8, 300),
		content = [[ANCIENT MARKER

Here stands the domain of the
Forest Guardian - an entity that
predates the corporation's arrival.

The Guardian protected these woods
for centuries. Now it fights the
creatures alongside us.

OFFERING RITUAL:
Place wood at its roots.
Speak your need.
If worthy, aid comes.

Those who harm the forest
receive no protection.

- Hermit Anise, Keeper of Old Ways]],
	},

	-- CHAPTER 3: THE EASTERN PATH (Frozen Peaks)
	{
		chapter = 3,
		title = "The Frozen Ascent",
		position = Vector3.new(200, 20, -30),
		content = [[EXPEDITION LOG - Final Entry

The cold isn't natural. It's spreading
from the second portal site - a crack
in reality near the peak.

Signal Part #2 is confirmed at the
summit. Previous team reached it.
None returned.

The ice wolves appeared on Day 19.
Unlike natural wolves, they hunt
for sport, not food.

SURVIVAL NOTES:
- Fire is life
- Never travel alone
- The blizzards hide things
- Trust no caves you haven't checked

May the Divines guide you where
we have fallen.

- Expedition Leader Bjorn Ironside]],
	},
	{
		chapter = 3,
		title = "The Frozen Dead",
		position = Vector3.new(400, 40, -50),
		content = [[MEMORIAL

HERE LIE THE BRAVE

24 souls attempted this ascent.
3 reached the summit.
1 claimed the Signal Part.
0 made it back.

Their sacrifice revealed:
The peak guardian - a Frost Wraith -
protects the Signal Part with
eternal vigilance.

Perhaps you will succeed
where we failed.

Or perhaps you'll join us.

The mountain doesn't care either way.]],
	},

	-- CHAPTER 4: THE WESTERN PATH (Pirate Cove)
	{
		chapter = 4,
		title = "Smuggler's Warning",
		position = Vector3.new(-200, 0, 40),
		content = [[BOUNTY NOTICE

WANTED: Captain Blackwood Vex
Crime: Kidnapping, Pet Trafficking
Reward: Signal Part Location

The Black Mist pirates saw the chaos
as opportunity. While we fought to
survive, they captured our companions.

Dogs. Cats. Even the children's ponies.

They sell them to... something.
Ships come in the fog. Gold changes
hands. The pets are never seen again.

Signal Part #3 is aboard the Black Mist.
The Captain keeps it as "insurance."

Stop the pirates. Save the pets.
Claim the Signal Part.

- Resistance Leader Mira Dawncrest]],
	},
	{
		chapter = 4,
		title = "The Pet Keeper's Plea",
		position = Vector3.new(-450, 0, 80),
		content = [[DESPERATE MESSAGE

To whoever finds this:

They took Fluffy. They took Shadow.
They took little Whiskers too.

The pirates laughed as they put them
in cages. Said something about
"dimensional buyers" paying premium.

I can see the ship from here but
the pirates... they're not right anymore.
Their eyes glow at night.

I think whatever they're selling to
has started changing THEM.

Please. Save our friends.
They don't understand what's happening.
They're just scared and alone.

- Elder Martha, Pet Sanctuary Founder]],
	},

	-- CHAPTER 5: THE DOOM APPROACHES
	{
		chapter = 5,
		title = "The Coming Storm",
		position = Vector3.new(0, 0, -100),
		content = [[PROPHECY STONE

When idle survivors number more than active,
When hunger claims more than creatures,
When darkness grows past its boundary,
When hope becomes memory—

THE DOOM MANIFESTS.

Already we see the signs:
- The nights grow longer
- The creatures grow bolder
- The portal pulses brighter
- Reality itself weakens

This is not metaphor.
This is measurement.

The portal at Floor 7½ is EXPANDING.
Each inactive survivor, each death by
despair, each moment of surrender
FEEDS IT.

Act. Move. Fight. Hope.
Or become part of the darkness.

- The Watchers]],
	},

	-- FINAL CHAPTER: THE MERTIN-FLEMMER BUILDING
	{
		chapter = 6,
		title = "Ground Zero",
		position = Vector3.new(400, 0, 400),
		content = [[CLASSIFIED - EYES ONLY

MERTIN-FLEMMER INCIDENT REPORT

What we opened: Unknown dimension
What came through: Multiple entities
Current status: UNCONTAINED

Floor 7½ Details:
- Exists between floors 7 and 8
- Accessible only during specific times
- Portal to source dimension confirmed
- SIGNAL PART ORIGIN LOCATION

The Signal Parts weren't communication
devices. They were CONTAINMENT ANCHORS.

When the entity emerged, it shattered
the containment field. The three parts
scattered across the land.

REASSEMBLING them at the beacon
won't call for rescue.

It will CLOSE THE PORTAL.

This was never about escaping.
It's about STOPPING THIS.

- Dr. James Mertin, Final Recording]],
	},
}

-- ==========================================
-- DANGER / DOOM SYSTEM
-- ==========================================

local playerDoomState: { [Player]: {
	idleTime: number,
	lastPosition: Vector3?,
	lastMoveTime: number,
	doomLevel: number, -- 0-100, at 100 = special event
	warningsGiven: number,
	lastWarning: number,
} } = {}

local IDLE_WARNING_THRESHOLDS = {
	{ time = 30, message = "You feel watched. Movement might be wise.", level = 10 },
	{ time = 60, message = "The darkness stirs. Something has noticed your stillness.", level = 25 },
	{ time = 90, message = "Your scent of despair spreads. Creatures draw near.", level = 50 },
	{ time = 120, message = "THE STALKER HAS FOUND YOU. MOVE OR DIE!", level = 75 },
	{ time = 150, message = "DOOM APPROACHES. YOUR IDLE SOUL FEEDS THE PORTAL.", level = 100 },
}

local function initPlayerDoom(player: Player)
	playerDoomState[player] = {
		idleTime = 0,
		lastPosition = nil,
		lastMoveTime = tick(),
		doomLevel = 0,
		warningsGiven = 0,
		lastWarning = 0,
	}
end

local function updateDoomState(player: Player, dt: number)
	local state = playerDoomState[player]
	if not state then return end

	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	local currentPos = rootPart.Position

	-- Check if moved
	local moved = false
	if state.lastPosition then
		local distance = (currentPos - state.lastPosition).Magnitude
		if distance > 2 then
			moved = true
			state.lastMoveTime = tick()
			state.idleTime = 0

			-- Reduce doom when moving
			state.doomLevel = math.max(0, state.doomLevel - dt * 5)
		end
	end

	state.lastPosition = currentPos

	-- Increase idle time if not moving
	if not moved then
		state.idleTime += dt

		-- Check for warnings
		for i, threshold in IDLE_WARNING_THRESHOLDS do
			if state.idleTime >= threshold.time and state.warningsGiven < i then
				state.warningsGiven = i
				state.doomLevel = threshold.level

				-- Send warning
				StoryRemote:FireClient(player, "DOOM_WARNING", {
					message = threshold.message,
					level = threshold.level,
				})

				-- At high doom levels, spawn danger
				if threshold.level >= 50 then
					spawnDoomCreature(player, threshold.level)
				end

				-- At max doom, trigger special event
				if threshold.level >= 100 then
					triggerDoomEvent(player)
				end
			end
		end
	else
		-- Reset warnings when moving
		state.warningsGiven = 0
	end
end

local function spawnDoomCreature(player: Player, doomLevel: number)
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	-- Spawn shadow creatures around idle player
	local numCreatures = math.ceil(doomLevel / 25)

	for i = 1, numCreatures do
		local angle = (i / numCreatures) * math.pi * 2
		local distance = 50 + math.random() * 30
		local spawnPos = rootPart.Position + Vector3.new(
			math.cos(angle) * distance,
			0,
			math.sin(angle) * distance
		)

		-- Create menacing shadow
		local shadow = Instance.new("Part")
		shadow.Name = "DoomShadow_" .. player.Name
		shadow.Size = Vector3.new(3, 6, 3)
		shadow.Position = spawnPos + Vector3.new(0, 3, 0)
		shadow.Color = Color3.fromRGB(20, 10, 30)
		shadow.Material = Enum.Material.Neon
		shadow.Transparency = 0.3
		shadow.Anchored = false
		shadow.CanCollide = false

		-- Glowing red eyes
		local eyes = Instance.new("Part")
		eyes.Size = Vector3.new(0.5, 0.2, 0.1)
		eyes.Color = Color3.fromRGB(255, 0, 0)
		eyes.Material = Enum.Material.Neon
		eyes.Position = shadow.Position + Vector3.new(0, 2, -1.5)
		eyes.Anchored = true
		eyes.Parent = shadow

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 50, 50)
		light.Brightness = 1
		light.Range = 20
		light.Parent = eyes

		shadow.Parent = workspace

		-- Move toward player
		task.spawn(function()
			local startTime = tick()
			while shadow and shadow.Parent and tick() - startTime < 30 do
				if character and character.Parent then
					local targetRoot = character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if targetRoot then
						local dir = (targetRoot.Position - shadow.Position).Unit
						shadow.Position = shadow.Position + dir * 0.5

						-- Check if reached player
						local dist = (targetRoot.Position - shadow.Position).Magnitude
						if dist < 5 then
							-- Damage player
							local humanoid = character:FindFirstChildOfClass("Humanoid")
							if humanoid then
								humanoid:TakeDamage(10)
								StoryRemote:FireClient(player, "DOOM_DAMAGE", {
									message = "The shadow's touch burns with cold despair!",
								})
							end
							shadow:Destroy()
							break
						end
					end
				end
				task.wait(0.1)
			end

			if shadow and shadow.Parent then
				shadow:Destroy()
			end
		end)
	end
end

local function triggerDoomEvent(player: Player)
	-- The ultimate punishment for idleness - the Stalker appears
	StoryRemote:FireClient(player, "DOOM_EVENT", {
		message = [[

THE STALKER HAS ARRIVED.

Your idle soul called it from beyond.
Your despair was a beacon.
Your inaction, an invitation.

RUN.

]],
	})

	-- Spawn the Stalker near player
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	-- Signal the creature system to spawn Stalker
	local CreatureSpawnRemote = ReplicatedStorage:FindFirstChild("SpawnCreature")
	if CreatureSpawnRemote and CreatureSpawnRemote:IsA("RemoteEvent") then
		-- This would trigger Stalker spawn
	end

	-- Dramatic lighting change
	local originalAmbient = Lighting.Ambient
	Lighting.Ambient = Color3.fromRGB(30, 0, 0)

	task.delay(10, function()
		Lighting.Ambient = originalAmbient
	end)
end

-- ==========================================
-- STORY SIGN CREATION
-- ==========================================

local function createStorySign(signData: typeof(STORY_SIGNS[1]))
	local sign = Instance.new("Model")
	sign.Name = "StorySign_Ch" .. signData.chapter

	-- Post
	local post = Instance.new("Part")
	post.Name = "Post"
	post.Size = Vector3.new(0.5, 6, 0.5)
	post.Position = signData.position + Vector3.new(0, 3, 0)
	post.Color = Color3.fromRGB(70, 50, 35)
	post.Material = Enum.Material.Wood
	post.Anchored = true
	post.Parent = sign

	-- Sign board
	local board = Instance.new("Part")
	board.Name = "Board"
	board.Size = Vector3.new(6, 5, 0.3)
	board.Position = signData.position + Vector3.new(0, 5, 0.5)
	board.Color = Color3.fromRGB(90, 70, 50)
	board.Material = Enum.Material.Wood
	board.Anchored = true
	board.Parent = sign

	-- Chapter number decoration
	local chapterBadge = Instance.new("Part")
	chapterBadge.Size = Vector3.new(1.5, 1.5, 0.4)
	chapterBadge.Position = board.Position + Vector3.new(2, 2, 0.2)
	chapterBadge.Color = Color3.fromRGB(150, 100, 50)
	chapterBadge.Material = Enum.Material.Metal
	chapterBadge.Shape = Enum.PartType.Cylinder
	chapterBadge.Orientation = Vector3.new(0, 0, 90)
	chapterBadge.Anchored = true
	chapterBadge.Parent = sign

	-- Sign content
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = board

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = Color3.fromRGB(50, 40, 30)
	container.BackgroundTransparency = 0.2
	container.Parent = signGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = container

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -10, 0, 30)
	titleLabel.Position = UDim2.new(0, 5, 0, 5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Chapter " .. signData.chapter .. ": " .. signData.title
	titleLabel.TextColor3 = Color3.fromRGB(255, 220, 150)
	titleLabel.Font = Enum.Font.Antique
	titleLabel.TextSize = 18
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = container

	local contentLabel = Instance.new("TextLabel")
	contentLabel.Size = UDim2.new(1, -10, 1, -40)
	contentLabel.Position = UDim2.new(0, 5, 0, 35)
	contentLabel.BackgroundTransparency = 1
	contentLabel.Text = signData.content
	contentLabel.TextColor3 = Color3.fromRGB(220, 210, 190)
	contentLabel.Font = Enum.Font.Gotham
	contentLabel.TextSize = 10
	contentLabel.TextWrapped = true
	contentLabel.TextXAlignment = Enum.TextXAlignment.Left
	contentLabel.TextYAlignment = Enum.TextYAlignment.Top
	contentLabel.Parent = container

	-- Weathering effects (moss/decay)
	for _ = 1, math.random(3, 6) do
		local moss = Instance.new("Part")
		moss.Size = Vector3.new(0.3, 0.3, 0.1)
		moss.Position = board.Position + Vector3.new(
			(math.random() - 0.5) * 5,
			(math.random() - 0.5) * 4,
			0.2
		)
		moss.Color = Color3.fromRGB(60, 100, 50)
		moss.Material = Enum.Material.Grass
		moss.Anchored = true
		moss.Parent = sign
	end

	sign.Parent = workspace
	return sign
end

local function createAllStorySigns()
	print("[Story] Creating story signs along paths...")

	for _, signData in STORY_SIGNS do
		createStorySign(signData)
	end

	print("[Story] Created", #STORY_SIGNS, "story signs")
end

-- ==========================================
-- INTRO SEQUENCE
-- ==========================================

local function playIntroSequence(player: Player)
	task.delay(3, function()
		StoryRemote:FireClient(player, "INTRO", {
			title = "THE MERTIN-FLEMMER INCIDENT",
			messages = {
				"Three months ago, the corporation opened a portal.",
				"Something came through.",
				"The Stalker. The Shadows. The creatures of darkness.",
				"Most fled. Some stayed to fight. None survived.",
				"You are a survivor. The Signal Parts can call for rescue.",
				"Three parts. Scattered across the land.",
				"The pirates took the pets. The creatures took the rest.",
				"The clock is ticking.",
				"The darkness grows.",
				"SURVIVE.",
			},
		})
	end)
end

-- ==========================================
-- PLAYER CONNECTIONS
-- ==========================================

Players.PlayerAdded:Connect(function(player)
	initPlayerDoom(player)
	playIntroSequence(player)
end)

Players.PlayerRemoving:Connect(function(player)
	playerDoomState[player] = nil
end)

for _, player in Players:GetPlayers() do
	initPlayerDoom(player)
end

-- ==========================================
-- GAME LOOP
-- ==========================================

RunService.Heartbeat:Connect(function(dt)
	for player, state in playerDoomState do
		updateDoomState(player, dt)
	end
end)

-- Initialize
task.spawn(function()
	task.wait(5)
	createAllStorySigns()
end)

print("[Story] Story system initialized!")
print("[Story] - Full backstory implemented")
print("[Story] - Doom system active (punishes idle players)")
print("[Story] - Story signs placed throughout world")
