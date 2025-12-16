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
	-- ==========================================
	-- NEAR SPAWN - Only essential starter signs!
	-- ==========================================

	-- Warning sign near spawn
	{
		chapter = 0,
		title = "Warning: Inactivity Kills",
		position = Vector3.new(-30, 0, 10),
		content = [[MEDICAL NOTICE

The creatures can SMELL despair.
If you stop moving, THEY FIND YOU.

Extended inactivity leads to:
- Accelerated hunger
- Creature attraction
- Doom manifestation

KEEP MOVING. STAY ALIVE.

- Dr. Helena Voss]],
	},

	-- Pointer to the building
	{
		chapter = 0,
		title = "FLOOR 7½ THIS WAY →→→",
		position = Vector3.new(50, 0, -30),
		content = [[→→→ FLOOR 7½ THIS WAY →→→

MERTIN-FLEMMER BUILDING
Location: Northeast (150, -100)
The 20-story glass tower!

HOW TO ACCESS:
1. Enter grand lobby
2. Elevator on LEFT wall
3. Press glowing "7½" button
4. Ceiling is LOW - crouch!

Floor 7½ contains:
- SIGNAL PART #1
- WALKMAN RADIO (Press 6/7/8)
- Food, Batteries, Flashlight
- The origin mystery...

→→→ HEAD NORTHEAST →→→]],
	},

	-- Chapter 1 sign OUTSIDE the building
	{
		chapter = 1,
		title = "★ CHAPTER 1: THE ORIGIN ★",
		position = Vector3.new(120, 0, -65), -- Near building, offset left
		content = [[╔═══════════════════════════════╗
║    CHAPTER 1: THE ORIGIN      ║
║      FLOOR 7½ AWAITS!         ║
╚═══════════════════════════════╝

★★ SIGNAL PART #1 ON FLOOR 7½! ★★

The Mertin-Flemmer Corporation
opened a portal here. Something
came through. This is GROUND ZERO.

ENTER THE BUILDING! FIND FLOOR 7½!
Collect: Signal Part, Walkman,
Food, Batteries, Flashlight!

Press 6/7/8 to change radio stations
on your Walkman once you find it!

The truth starts here.]],
	},

	-- Company name sign (slightly toward entrance)
	{
		chapter = 0,
		title = "Mertin-Flemmer Corp",
		position = Vector3.new(150, 0, -65), -- Slightly toward entrance from building
		content = [[MERTIN-FLEMMER CORPORATION
"Opening Doors to New Dimensions"

FLOOR DIRECTORY:
1-6: Administrative (ABANDONED)
7: Research Labs (SEALED)
7½: [REDACTED] - ENTER HERE!
8-15: Executive Offices (EMPTY)
16-19: Server Rooms (OFFLINE)
20: Penthouse (???)

NOTICE TO ALL PERSONNEL:
Floor 7½ does not exist.
Do not speak of Floor 7½.

- Management]],
	},

	-- ==========================================
	-- CHAPTER 2: FAR NORTH - Survivor's Camp (300+ studs away)
	-- ==========================================
	{
		chapter = 2,
		title = "★ CHAPTER 2: THE AWAKENING ★",
		position = Vector3.new(100, 0, 350), -- FAR NORTH!
		content = [[╔═══════════════════════════════╗
║   CHAPTER 2: THE AWAKENING    ║
║      SURVIVOR'S CAMP          ║
╚═══════════════════════════════╝

★★ SIGNAL PART #2 NEARBY! ★★
Look for the glowing blue orb!

After escaping Floor 7½, survivors
established this camp. But danger
still lurks everywhere...

REWARD SHACK NEARBY! Look for lights!
Contains: Food, flashlight, batteries!

5 MORE SIGNAL PARTS TO FIND!

- Emergency Broadcast System]],
	},

	-- ==========================================
	-- CHAPTER 3: FAR NORTH-WEST - Forest (500+ studs)
	-- ==========================================
	{
		chapter = 3,
		title = "★ CHAPTER 3: WHISPERING WOODS ★",
		position = Vector3.new(-300, 5, 500), -- FAR NORTHWEST!
		content = [[╔═══════════════════════════════╗
║  CHAPTER 3: WHISPERING WOODS  ║
║     THE FOREST GUARDIAN       ║
╚═══════════════════════════════╝

★★ SIGNAL PART #3 AT GUARDIAN! ★★
Continue deeper into the forest!

The forest has changed. Trees move.
The whispers aren't wind - warnings.

REWARD CABIN AT THE GUARDIAN!
Flashlight, batteries, food, seeds!

Follow the glow deeper!

- Ranger Elias Thorne]],
	},
	{
		chapter = 3,
		title = "The Forest Guardian",
		position = Vector3.new(-400, 8, 700), -- DEEP in forest
		content = [[╔═══════════════════════════════╗
║   THE FOREST GUARDIAN AWAITS  ║
╚═══════════════════════════════╝

★★ SIGNAL PART #3 HERE! ★★
Look for the glowing blue orb!

HERMIT'S REWARD CABIN NEARBY!
Food, seeds, flashlight, batteries!

3 MORE SIGNAL PARTS TO FIND!

- Hermit Anise, Keeper of Old Ways]],
	},

	-- ==========================================
	-- CHAPTER 4: FAR EAST - Frozen Peaks (600+ studs)
	-- ==========================================
	{
		chapter = 4,
		title = "★ CHAPTER 4: FROZEN PEAKS ★",
		position = Vector3.new(600, 30, -200), -- FAR EAST
		content = [[╔═══════════════════════════════╗
║   CHAPTER 4: FROZEN PEAKS     ║
║     THE MOUNTAIN SUMMIT       ║
╚═══════════════════════════════╝

★★ SIGNAL PART #4 AT SUMMIT! ★★
Head up the frozen mountain!

The cold isn't natural. A portal
site bleeds near the peak.

WARM CABIN AT THE SUMMIT!
Fire pit, food, batteries, flashlight!

Head UP! Follow the beacon!

- Expedition Leader Bjorn Ironside]],
	},
	{
		chapter = 4,
		title = "The Frozen Dead Memorial",
		position = Vector3.new(800, 60, -300), -- HIGH on mountain
		content = [[╔═══════════════════════════════╗
║   MEMORIAL & REWARD CABIN!    ║
╚═══════════════════════════════╝

★★ SIGNAL PART #4 HERE! ★★
Look for the glowing blue orb!

HERE LIE THE BRAVE
They left SUPPLIES for survivors!

2 MORE SIGNAL PARTS TO FIND!]],
	},

	-- ==========================================
	-- CHAPTER 5: FAR WEST - Pirate Cove (700+ studs)
	-- ==========================================
	{
		chapter = 5,
		title = "★ CHAPTER 5: PIRATE COVE ★",
		position = Vector3.new(-500, 0, 100), -- FAR WEST
		content = [[╔═══════════════════════════════╗
║   CHAPTER 5: PIRATE COVE      ║
║    THE PET KEEPER'S PLEA      ║
╚═══════════════════════════════╝

★★ SIGNAL PART #5 AT PET KEEPER! ★★
Continue west toward the coast!

WANTED: Captain Blackwood Vex
Crime: Kidnapping, Pet Trafficking

REWARD SHACK at Pet Keeper's cabin!

- Resistance Leader Mira Dawncrest]],
	},
	{
		chapter = 5,
		title = "The Pet Keeper's Plea",
		position = Vector3.new(-750, 0, 150), -- DEEP WEST
		content = [[╔═══════════════════════════════╗
║   PET SANCTUARY - REWARD!     ║
╚═══════════════════════════════╝

★★ SIGNAL PART #5 HERE! ★★
Look for the glowing blue orb!

Supplies in the CABIN nearby!
1 MORE SIGNAL PART TO FIND!

- Elder Martha]],
	},

	-- ==========================================
	-- CHAPTER 6: FAR SOUTH - Prophecy Stone (800+ studs)
	-- ==========================================
	{
		chapter = 6,
		title = "★ CHAPTER 6: THE FINAL TRUTH ★",
		position = Vector3.new(0, 0, -600), -- FAR SOUTH!
		content = [[╔═══════════════════════════════╗
║  CHAPTER 6: THE FINAL TRUTH   ║
║     THE PROPHECY STONE        ║
╚═══════════════════════════════╝

★★ FINAL SIGNAL PART #6 HERE! ★★
Look for the glowing blue orb!

When all six parts are gathered,
THE PORTAL CAN BE CLOSED FOREVER.

REWARD CABIN nearby with supplies!

REASSEMBLE ALL 6 PARTS at beacon!
Close the portal. Save the world.

- The Watchers]],
	},
	{
		chapter = 6,
		title = "The Prophecy",
		position = Vector3.new(50, 0, -700), -- DEEP SOUTH
		content = [[THE ANCIENT PROPHECY

"Six lights scattered in the dark,
Six beacons to restore the mark,
From Origin to Final Stone,
The brave shall not walk alone."

Chapter 1: Floor 7½ (Start!)
Chapter 2: North - Survivor's Camp
Chapter 3: Northwest - Forest
Chapter 4: East - Frozen Peaks
Chapter 5: West - Pirate Cove
Chapter 6: South - Prophecy Stone

YOU FOUND THEM ALL!
Go to the RESCUE BEACON!]],
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

	-- Get terrain height at sign position
	local terrainHeight = Shared.getTerrainHeight(signData.position.X, signData.position.Z)
	local basePos = Vector3.new(signData.position.X, terrainHeight, signData.position.Z)

	-- Post (MUCH taller for MASSIVE sign)
	local post = Instance.new("Part")
	post.Name = "Post"
	post.Size = Vector3.new(1, 16, 1)
	post.Position = basePos + Vector3.new(0, 8, 0)
	post.Color = Color3.fromRGB(70, 50, 35)
	post.Material = Enum.Material.Wood
	post.Anchored = true
	post.Parent = sign

	-- Sign board (MASSIVE for BIG BOLD text) - positioned IN FRONT of post
	local board = Instance.new("Part")
	board.Name = "Board"
	board.Size = Vector3.new(16, 12, 0.4)
	board.Position = basePos + Vector3.new(0, 10, 3)  -- 3 studs in front of post
	board.Color = Color3.fromRGB(90, 70, 50)
	board.Material = Enum.Material.Wood
	board.Anchored = true
	board.Parent = sign

	-- Support beam connecting post to board
	local support = Instance.new("Part")
	support.Name = "Support"
	support.Size = Vector3.new(0.8, 0.8, 3)
	support.Position = basePos + Vector3.new(0, 10, 1.5)
	support.Color = Color3.fromRGB(70, 50, 35)
	support.Material = Enum.Material.Wood
	support.Anchored = true
	support.Parent = sign

	-- Chapter number decoration (bigger badge) - on BACK of sign (toward post)
	local chapterBadge = Instance.new("Part")
	chapterBadge.Size = Vector3.new(2.5, 2.5, 0.5)
	chapterBadge.Position = board.Position + Vector3.new(4, 3, -0.3)
	chapterBadge.Color = Color3.fromRGB(150, 100, 50)
	chapterBadge.Material = Enum.Material.Metal
	chapterBadge.Shape = Enum.PartType.Cylinder
	chapterBadge.Orientation = Vector3.new(0, 0, 90)
	chapterBadge.Anchored = true
	chapterBadge.Parent = sign

	-- Sign content on BOTH sides
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local signGui = Instance.new("SurfaceGui")
		signGui.Face = face
		signGui.PixelsPerStud = 50  -- Higher resolution for crisp text
		signGui.Parent = board

		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 1, 0)
		container.BackgroundColor3 = Color3.fromRGB(50, 40, 30)
		container.BackgroundTransparency = 0.1
		container.Parent = signGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 15)
		corner.Parent = container

		-- Title - MASSIVE, BOLD, handwritten style
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -20, 0, 80)
		titleLabel.Position = UDim2.new(0, 10, 0, 10)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = "~ " .. signData.title .. " ~"
		titleLabel.TextColor3 = Color3.fromRGB(255, 230, 180)
		titleLabel.Font = Enum.Font.Fondamento  -- Handwritten/script style
		titleLabel.TextSize = 72  -- BIG BOLD!
		titleLabel.TextStrokeTransparency = 0.3  -- More visible stroke
		titleLabel.TextStrokeColor3 = Color3.fromRGB(40, 30, 20)
		titleLabel.TextXAlignment = Enum.TextXAlignment.Center
		titleLabel.Parent = container

		-- Chapter subtitle (bigger)
		local chapterLabel = Instance.new("TextLabel")
		chapterLabel.Size = UDim2.new(1, -20, 0, 40)
		chapterLabel.Position = UDim2.new(0, 10, 0, 85)
		chapterLabel.BackgroundTransparency = 1
		chapterLabel.Text = "Chapter " .. signData.chapter
		chapterLabel.TextColor3 = Color3.fromRGB(180, 160, 120)
		chapterLabel.Font = Enum.Font.Merriweather
		chapterLabel.TextSize = 32  -- Bigger
		chapterLabel.TextStrokeTransparency = 0.5
		chapterLabel.TextStrokeColor3 = Color3.fromRGB(40, 30, 20)
		chapterLabel.TextXAlignment = Enum.TextXAlignment.Center
		chapterLabel.Parent = container

		-- Content - BIG, BOLD, readable handwritten
		local contentLabel = Instance.new("TextLabel")
		contentLabel.Size = UDim2.new(1, -30, 1, -140)
		contentLabel.Position = UDim2.new(0, 15, 0, 130)
		contentLabel.BackgroundTransparency = 1
		contentLabel.Text = signData.content
		contentLabel.TextColor3 = Color3.fromRGB(240, 235, 220)
		contentLabel.Font = Enum.Font.Fondamento  -- Handwritten style
		contentLabel.TextSize = 40  -- MUCH BIGGER!
		contentLabel.TextStrokeTransparency = 0.4  -- More visible
		contentLabel.TextStrokeColor3 = Color3.fromRGB(30, 25, 20)
		contentLabel.TextWrapped = true
		contentLabel.TextXAlignment = Enum.TextXAlignment.Left
		contentLabel.TextYAlignment = Enum.TextYAlignment.Top
		contentLabel.LineHeight = 1.2
		contentLabel.Parent = container
	end

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
