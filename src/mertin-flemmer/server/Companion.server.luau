--!strict
-- Companion System for Mertin-Flemmer
-- Every player gets an NPC companion with personality
-- The companion helps but also does mischievous things!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

-- Create remotes
local CompanionRemote = Instance.new("RemoteEvent")
CompanionRemote.Name = "Companion"
CompanionRemote.Parent = ReplicatedStorage

-- ==========================================
-- COMPANION PERSONALITIES
-- ==========================================

local PERSONALITIES = {
	{
		name = "Pickles",
		species = "Camel",
		trait = "Mischievous",
		color = Color3.fromRGB(200, 170, 120),
		helpfulness = 0.6,
		chaosChance = 0.3,
		dialogues = {
			greeting = { "Mrrrph!", "Pickles is HERE!", "*spits excitedly*" },
			following = { "*trots along*", "Where we going?", "Pickles follows!" },
			mischief = { "*runs away cackling*", "CATCH ME IF YOU CAN!", "Pickles needs adventure!" },
			hiding = { "*giggles from behind rock*", "You can't see Pickles!", "*sticks head out*" },
			found_item = { "LOOK LOOK LOOK!", "Pickles found treasure!", "*stomps excitedly*" },
			combat = { "Pickles will SPIT on them!", "*angry camel noises*", "BAD CREATURE!" },
			returning = { "Pickles is back!", "Miss me?", "*proud trot*" },
			hungry = { "*sad camel eyes*", "Pickles is STARVING...", "Feed Pickles??" },
			scared = { "*hides behind player*", "Pickles doesn't like this...", "*nervous humming*" },
		},
	},
	{
		name = "Gerald",
		species = "Camel",
		trait = "Grumpy but Loyal",
		color = Color3.fromRGB(180, 150, 100),
		helpfulness = 0.8,
		chaosChance = 0.15,
		dialogues = {
			greeting = { "*sighs*", "Gerald supposes we're doing this.", "Fine. Let's go." },
			following = { "*reluctant footsteps*", "Gerald is coming...", "*grumbles*" },
			mischief = { "Gerald needs a moment.", "*wanders off judgmentally*", "Gerald will return. Maybe." },
			hiding = { "*hiding poorly*", "Gerald is NOT hiding.", "*visible behind small bush*" },
			found_item = { "Gerald found something. You're welcome.", "*nudges item*", "Take it before Gerald changes mind." },
			combat = { "*protective stance*", "Gerald will handle this.", "Nobody hurts Gerald's human." },
			returning = { "Gerald is back. Don't make it weird.", "*nuzzles briefly*", "Gerald was just... checking perimeter." },
			hungry = { "Gerald requires sustenance.", "*pointed stare*", "Gerald is withering." },
			scared = { "Gerald is not scared. Gerald is... cautious.", "*stands very close*", "*definitely scared*" },
		},
	},
	{
		name = "Princess Humpsalot",
		species = "Camel",
		trait = "Dramatic Diva",
		color = Color3.fromRGB(220, 200, 180),
		helpfulness = 0.5,
		chaosChance = 0.4,
		dialogues = {
			greeting = { "The Princess has ARRIVED!", "*poses dramatically*", "You may bask in my presence." },
			following = { "*graceful trot*", "The Princess accompanies you. Feel honored.", "*flicks tail*" },
			mischief = { "The Princess needs her SPACE!", "*dramatic exit*", "I CANNOT with this right now!" },
			hiding = { "*hiding behind own tail*", "The Princess is INVISIBLE!", "*dramatic gasp when found*" },
			found_item = { "A GIFT for the Princess!", "This is CLEARLY meant for ME.", "*hoards item*" },
			combat = { "HOW DARE THEY!", "*angry screech*", "PROTECT THE PRINCESS!" },
			returning = { "The Princess has returned from her JOURNEY!", "*expects applause*", "Did you miss me? Of course you did." },
			hungry = { "The Princess is FAMISHED!", "*dramatic collapse*", "I cannot go on without sustenance!" },
			scared = { "*hides in mane*", "The Princess does NOT get scared!", "*screams*" },
		},
	},
	{
		name = "Mr. Wobbles",
		species = "Camel",
		trait = "Clumsy Helper",
		color = Color3.fromRGB(190, 160, 130),
		helpfulness = 0.9,
		chaosChance = 0.25,
		dialogues = {
			greeting = { "*trips over nothing*", "Mr. Wobbles is ready!", "*falls but recovers*" },
			following = { "*slightly off-balance*", "Following! Following!", "*bumps into rock*" },
			mischief = { "*accidentally wanders off*", "Wait, where did everyone go?", "*got distracted by butterfly*" },
			hiding = { "*hides behind player*", "Am I hidden?", "*tail visible*" },
			found_item = { "*steps on item*", "OOH I found-- oops.", "*picks it up carefully*" },
			combat = { "*charges but trips*", "Mr. Wobbles will-- WHOOPS!", "*still tries to help*" },
			returning = { "*stumbles back*", "Mr. Wobbles found his way!", "*proud despite scratches*" },
			hungry = { "*tummy rumbles*", "Mr. Wobbles' belly is noisy...", "*tries to eat rock*" },
			scared = { "*wobbles more than usual*", "M-Mr. Wobbles is f-fine!", "*definitely not fine*" },
		},
	},
	{
		name = "Shadow",
		species = "Camel",
		trait = "Mysterious Protector",
		color = Color3.fromRGB(80, 70, 60),
		helpfulness = 0.85,
		chaosChance = 0.1,
		dialogues = {
			greeting = { "*appears silently*", "Shadow is here.", "*nods*" },
			following = { "*silent footsteps*", "...", "*watchful eyes*" },
			mischief = { "*vanishes*", "Shadow must scout.", "*already gone*" },
			hiding = { "*actually invisible*", "...", "*you feel watched*" },
			found_item = { "*places item before you*", "Shadow found this.", "*disappears*" },
			combat = { "*already fighting*", "Shadow protects.", "*fierce glare*" },
			returning = { "*appears from nowhere*", "Shadow has returned.", "*as if never left*" },
			hungry = { "...", "*meaningful stare at food*", "*silent request*" },
			scared = { "*positions between player and danger*", "Shadow is alert.", "*not scared, vigilant*" },
		},
	},
}

-- ==========================================
-- COMPANION BEHAVIORS
-- ==========================================

local BEHAVIORS = {
	FOLLOWING = "following",
	IDLE = "idle",
	MISCHIEF = "mischief", -- Running away for fun
	HIDING = "hiding",
	SCOUTING = "scouting", -- Looking for items
	COMBAT = "combat",
	RETURNING = "returning",
}

local BEHAVIOR_DURATIONS = {
	[BEHAVIORS.MISCHIEF] = { min = 10, max = 30 },
	[BEHAVIORS.HIDING] = { min = 5, max = 15 },
	[BEHAVIORS.SCOUTING] = { min = 15, max = 40 },
}

-- ==========================================
-- COMPANION STATE
-- ==========================================

local companions: { [Player]: {
	model: Model,
	personality: typeof(PERSONALITIES[1]),
	behavior: string,
	behaviorTimer: number,
	targetPosition: Vector3?,
	lastDialogue: number,
	hideSpot: Vector3?,
	foundItems: { string },
	loyalty: number, -- Increases over time, reduces chaos
} } = {}

-- ==========================================
-- CREATE COMPANION MODEL
-- ==========================================

-- Track riding state
local ridingPlayers: { [Player]: Model } = {}

local function createCamelModel(personality: typeof(PERSONALITIES[1]), position: Vector3): Model
	local camel = Instance.new("Model")
	camel.Name = "Companion_" .. personality.name

	-- SCALED DOWN CAMEL (0.5x size so it can fit through doors)
	local SCALE = 0.5

	-- Body (HumanoidRootPart) - MUST collide to stand on terrain!
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 2.5, 5) * SCALE
	body.Position = position + Vector3.new(0, 3, 0)  -- Spawn higher above ground
	body.Color = personality.color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = false
	body.CanCollide = true  -- MUST collide to walk on terrain!
	body.Parent = camel

	-- Hump 1
	local hump1 = Instance.new("Part")
	hump1.Name = "Hump1"
	hump1.Size = Vector3.new(2, 1.5, 2) * SCALE
	hump1.Position = body.Position + Vector3.new(0, 1.5 * SCALE, 1 * SCALE)
	hump1.Color = personality.color
	hump1.Material = Enum.Material.SmoothPlastic
	hump1.Shape = Enum.PartType.Ball
	hump1.Anchored = false
	hump1.CanCollide = false
	hump1.Parent = camel

	-- Hump 2
	local hump2 = Instance.new("Part")
	hump2.Name = "Hump2"
	hump2.Size = Vector3.new(2, 1.5, 2) * SCALE
	hump2.Position = body.Position + Vector3.new(0, 1.5 * SCALE, -1 * SCALE)
	hump2.Color = personality.color
	hump2.Material = Enum.Material.SmoothPlastic
	hump2.Shape = Enum.PartType.Ball
	hump2.Anchored = false
	hump2.CanCollide = false
	hump2.Parent = camel

	-- Neck
	local neck = Instance.new("Part")
	neck.Name = "Neck"
	neck.Size = Vector3.new(1, 3, 1) * SCALE
	neck.Position = body.Position + Vector3.new(0, 2 * SCALE, 2.5 * SCALE)
	neck.Color = personality.color
	neck.Material = Enum.Material.SmoothPlastic
	neck.Anchored = false
	neck.CanCollide = false
	neck.Parent = camel

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.5, 1.5, 2) * SCALE
	head.Position = neck.Position + Vector3.new(0, 2 * SCALE, 0.5 * SCALE)
	head.Color = personality.color
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = false
	head.CanCollide = false
	head.Parent = camel

	-- Eyes
	local eye1 = Instance.new("Part")
	eye1.Name = "Eye1"
	eye1.Size = Vector3.new(0.3, 0.3, 0.1) * SCALE
	eye1.Position = head.Position + Vector3.new(0.5 * SCALE, 0.3 * SCALE, 0.9 * SCALE)
	eye1.Color = Color3.fromRGB(40, 30, 20)
	eye1.Material = Enum.Material.SmoothPlastic
	eye1.Anchored = false
	eye1.CanCollide = false
	eye1.Parent = camel

	local eye2 = Instance.new("Part")
	eye2.Name = "Eye2"
	eye2.Size = Vector3.new(0.3, 0.3, 0.1) * SCALE
	eye2.Position = head.Position + Vector3.new(-0.5 * SCALE, 0.3 * SCALE, 0.9 * SCALE)
	eye2.Color = Color3.fromRGB(40, 30, 20)
	eye2.Material = Enum.Material.SmoothPlastic
	eye2.Anchored = false
	eye2.CanCollide = false
	eye2.Parent = camel

	-- Legs - need collision to walk on terrain
	for i, offset in { Vector3.new(1, -2, 1.5), Vector3.new(-1, -2, 1.5), Vector3.new(1, -2, -1.5), Vector3.new(-1, -2, -1.5) } do
		local leg = Instance.new("Part")
		leg.Name = "Leg" .. i
		leg.Size = Vector3.new(0.6, 2.5, 0.6) * SCALE
		leg.Position = body.Position + offset * SCALE
		leg.Color = personality.color
		leg.Material = Enum.Material.SmoothPlastic
		leg.Anchored = false
		leg.CanCollide = true  -- Legs need collision for walking
		leg.Parent = camel
	end

	-- Tail
	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.3, 0.3, 1.5) * SCALE
	tail.Position = body.Position + Vector3.new(0, 0.5 * SCALE, -3 * SCALE)
	tail.Color = personality.color
	tail.Material = Enum.Material.SmoothPlastic
	tail.Anchored = false
	tail.CanCollide = false
	tail.Parent = camel

	-- VEHICLE SEAT for riding! Player can control with WASD/arrows
	local seat = Instance.new("VehicleSeat")
	seat.Name = "CamelSeat"
	seat.Size = Vector3.new(2, 0.5, 2) * SCALE
	seat.Position = body.Position + Vector3.new(0, 1.8 * SCALE, 0)
	seat.Color = Color3.fromRGB(139, 90, 43) -- Saddle brown
	seat.Material = Enum.Material.Leather
	seat.Anchored = false
	seat.CanCollide = true -- Player can sit on it!
	seat.Transparency = 0
	seat.MaxSpeed = 50  -- Fast camel!
	seat.Torque = 20
	seat.TurnSpeed = 2
	seat.Parent = camel

	-- Movement handler - reads VehicleSeat throttle/steer to move the camel
	local function updateCamelMovement()
		local throttle = seat.Throttle  -- -1 (back) to 1 (forward)
		local steer = seat.Steer        -- -1 (left) to 1 (right)

		if seat.Occupant then
			-- Get the camel's humanoid
			local camelHumanoid = camel:FindFirstChildOfClass("Humanoid")
			if camelHumanoid and body then
				local speed = 20 * throttle  -- Base movement speed

				if math.abs(throttle) > 0.1 or math.abs(steer) > 0.1 then
					-- Calculate movement direction based on camel's facing direction
					local lookVector = body.CFrame.LookVector
					local rightVector = body.CFrame.RightVector

					-- Apply steering by rotating
					if math.abs(steer) > 0.1 then
						body.CFrame = body.CFrame * CFrame.Angles(0, -steer * 0.05, 0)
					end

					-- Move forward/backward
					if math.abs(throttle) > 0.1 then
						local moveDirection = lookVector * throttle
						camelHumanoid:Move(moveDirection)
					end
				else
					-- Stop moving when no input
					camelHumanoid:Move(Vector3.zero)
				end
			end
		end
	end

	-- Connect to heartbeat for smooth movement
	local moveConnection = RunService.Heartbeat:Connect(updateCamelMovement)

	-- Saddle blanket underneath
	local blanket = Instance.new("Part")
	blanket.Name = "SaddleBlanket"
	blanket.Size = Vector3.new(2.5, 0.2, 3) * SCALE
	blanket.Position = body.Position + Vector3.new(0, 1.5 * SCALE, 0)
	blanket.Color = Color3.fromRGB(150, 50, 50) -- Red blanket
	blanket.Material = Enum.Material.Fabric
	blanket.Anchored = false
	blanket.CanCollide = false
	blanket.Parent = camel

	-- ProximityPrompt to make mounting easy!
	local ridePrompt = Instance.new("ProximityPrompt")
	ridePrompt.ObjectText = personality.name
	ridePrompt.ActionText = "Ride Camel"
	ridePrompt.KeyboardKeyCode = Enum.KeyCode.E
	ridePrompt.HoldDuration = 0.3
	ridePrompt.MaxActivationDistance = 10
	ridePrompt.Parent = body

	-- When prompted, seat the player
	ridePrompt.Triggered:Connect(function(player: Player)
		local character = player.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.SeatPart == nil then
			seat:Sit(humanoid)
			print("[Companion]", player.Name, "is now riding", personality.name, "!")
		end
	end)

	-- Name tag (adjusted for smaller camel)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 35)
	billboard.StudsOffset = Vector3.new(0, 3, 0) -- Lowered for smaller camel
	billboard.Adornee = body
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = personality.name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.Parent = billboard

	local traitLabel = Instance.new("TextLabel")
	traitLabel.Size = UDim2.new(1, 0, 0.4, 0)
	traitLabel.Position = UDim2.new(0, 0, 0.6, 0)
	traitLabel.BackgroundTransparency = 1
	traitLabel.Text = "(" .. personality.trait .. ")"
	traitLabel.TextColor3 = Color3.fromRGB(200, 200, 150)
	traitLabel.TextStrokeTransparency = 0.5
	traitLabel.Font = Enum.Font.GothamMedium
	traitLabel.TextSize = 10
	traitLabel.Parent = billboard

	-- Make body the PrimaryPart
	camel.PrimaryPart = body

	-- Weld all parts
	for _, part in camel:GetChildren() do
		if part:IsA("BasePart") and part ~= body then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = part
			weld.Parent = body
		end
	end

	-- Add humanoid for movement
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.WalkSpeed = 16
	humanoid.Parent = camel

	-- Rename body to HumanoidRootPart for pathfinding
	body.Name = "HumanoidRootPart"

	camel.Parent = workspace
	return camel
end

-- ==========================================
-- COMPANION DIALOGUE
-- ==========================================

local function sayDialogue(player: Player, category: string)
	local companion = companions[player]
	if not companion then return end

	-- Rate limit dialogue
	if tick() - companion.lastDialogue < 5 then return end
	companion.lastDialogue = tick()

	local dialogues = companion.personality.dialogues[category]
	if dialogues then
		local text = dialogues[math.random(#dialogues)]
		CompanionRemote:FireClient(player, "DIALOGUE", {
			name = companion.personality.name,
			text = text,
		})

		-- Chat bubble above companion
		local body = companion.model:FindFirstChild("HumanoidRootPart") :: BasePart?
		if body then
			local chatBillboard = Instance.new("BillboardGui")
			chatBillboard.Size = UDim2.new(0, 150, 0, 50)
			chatBillboard.StudsOffset = Vector3.new(0, 7, 0)
			chatBillboard.Adornee = body
			chatBillboard.Parent = body

			local chatLabel = Instance.new("TextLabel")
			chatLabel.Size = UDim2.new(1, 0, 1, 0)
			chatLabel.BackgroundColor3 = Color3.new(0, 0, 0)
			chatLabel.BackgroundTransparency = 0.3
			chatLabel.Text = text
			chatLabel.TextColor3 = Color3.new(1, 1, 1)
			chatLabel.TextWrapped = true
			chatLabel.Font = Enum.Font.Gotham
			chatLabel.TextSize = 12
			chatLabel.Parent = chatBillboard

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = chatLabel

			-- Fade out
			task.delay(4, function()
				if chatBillboard and chatBillboard.Parent then
					chatBillboard:Destroy()
				end
			end)
		end
	end
end

-- ==========================================
-- COMPANION MOVEMENT
-- ==========================================

local function moveToward(companion: typeof(companions[Players:GetPlayers()[1]]), target: Vector3)
	if not companion or not companion.model then return end

	local humanoid = companion.model:FindFirstChildOfClass("Humanoid")
	local rootPart = companion.model:FindFirstChild("HumanoidRootPart") :: BasePart?

	if humanoid and rootPart then
		-- Simple movement toward target
		humanoid:MoveTo(target)
	end
end

local function getRandomNearbyPosition(center: Vector3, minDist: number, maxDist: number): Vector3
	local angle = math.random() * math.pi * 2
	local distance = minDist + math.random() * (maxDist - minDist)
	return center + Vector3.new(
		math.cos(angle) * distance,
		0,
		math.sin(angle) * distance
	)
end

-- ==========================================
-- BEHAVIOR HANDLERS
-- ==========================================

local function startMischief(player: Player)
	local companion = companions[player]
	if not companion then return end

	companion.behavior = BEHAVIORS.MISCHIEF
	local duration = BEHAVIOR_DURATIONS[BEHAVIORS.MISCHIEF]
	companion.behaviorTimer = math.random(duration.min, duration.max)

	-- Pick a random direction to run
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if rootPart then
			companion.targetPosition = getRandomNearbyPosition(rootPart.Position, 30, 80)
		end
	end

	sayDialogue(player, "mischief")
end

local function startHiding(player: Player)
	local companion = companions[player]
	if not companion then return end

	companion.behavior = BEHAVIORS.HIDING
	local duration = BEHAVIOR_DURATIONS[BEHAVIORS.HIDING]
	companion.behaviorTimer = math.random(duration.min, duration.max)

	-- Find a hiding spot near player
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if rootPart then
			companion.hideSpot = getRandomNearbyPosition(rootPart.Position, 10, 25)
			companion.targetPosition = companion.hideSpot
		end
	end

	sayDialogue(player, "hiding")
end

local function startScouting(player: Player)
	local companion = companions[player]
	if not companion then return end

	companion.behavior = BEHAVIORS.SCOUTING
	local duration = BEHAVIOR_DURATIONS[BEHAVIORS.SCOUTING]
	companion.behaviorTimer = math.random(duration.min, duration.max)

	-- Scout in a direction
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if rootPart then
			companion.targetPosition = getRandomNearbyPosition(rootPart.Position, 20, 50)
		end
	end
end

local function returnToPlayer(player: Player)
	local companion = companions[player]
	if not companion then return end

	companion.behavior = BEHAVIORS.RETURNING
	companion.behaviorTimer = 0
	companion.targetPosition = nil
	companion.hideSpot = nil

	sayDialogue(player, "returning")
end

local function triggerRandomBehavior(player: Player)
	local companion = companions[player]
	if not companion then return end

	-- Loyalty reduces chaos
	local effectiveChaosChance = companion.personality.chaosChance * (1 - companion.loyalty * 0.5)

	if math.random() < effectiveChaosChance then
		local behaviors = { "mischief", "hiding", "scouting" }
		local chosen = behaviors[math.random(#behaviors)]

		if chosen == "mischief" then
			startMischief(player)
		elseif chosen == "hiding" then
			startHiding(player)
		elseif chosen == "scouting" then
			startScouting(player)
		end
	end
end

-- ==========================================
-- UPDATE COMPANION
-- ==========================================

local function updateCompanion(player: Player, dt: number)
	local companion = companions[player]
	if not companion or not companion.model then return end

	local character = player.Character
	if not character then return end

	local playerRoot = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local companionRoot = companion.model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not playerRoot or not companionRoot then return end

	local distanceToPlayer = (playerRoot.Position - companionRoot.Position).Magnitude

	-- Handle current behavior
	if companion.behavior == BEHAVIORS.FOLLOWING or companion.behavior == BEHAVIORS.IDLE then
		-- Follow player
		if distanceToPlayer > 8 then
			moveToward(companion, playerRoot.Position)
			companion.behavior = BEHAVIORS.FOLLOWING
		else
			companion.behavior = BEHAVIORS.IDLE
		end

		-- Random chance to do something chaotic
		if math.random() < 0.001 * dt * 60 then -- ~0.1% per second
			triggerRandomBehavior(player)
		end

	elseif companion.behavior == BEHAVIORS.MISCHIEF then
		if companion.targetPosition then
			moveToward(companion, companion.targetPosition)

			-- Check if reached target or timer expired
			local distToTarget = (companionRoot.Position - companion.targetPosition).Magnitude
			if distToTarget < 5 or companion.behaviorTimer <= 0 then
				returnToPlayer(player)
			end
		else
			returnToPlayer(player)
		end

		companion.behaviorTimer -= dt

	elseif companion.behavior == BEHAVIORS.HIDING then
		if companion.hideSpot then
			local distToSpot = (companionRoot.Position - companion.hideSpot).Magnitude
			if distToSpot > 3 then
				moveToward(companion, companion.hideSpot)
			end
			-- "Hide" by being still
		end

		companion.behaviorTimer -= dt
		if companion.behaviorTimer <= 0 then
			returnToPlayer(player)
		end

	elseif companion.behavior == BEHAVIORS.SCOUTING then
		if companion.targetPosition then
			moveToward(companion, companion.targetPosition)

			local distToTarget = (companionRoot.Position - companion.targetPosition).Magnitude
			if distToTarget < 5 then
				-- Found something?
				if math.random() < companion.personality.helpfulness then
					sayDialogue(player, "found_item")
					-- Could actually spawn an item here
				end
				returnToPlayer(player)
			end
		end

		companion.behaviorTimer -= dt
		if companion.behaviorTimer <= 0 then
			returnToPlayer(player)
		end

	elseif companion.behavior == BEHAVIORS.RETURNING then
		moveToward(companion, playerRoot.Position)
		if distanceToPlayer < 8 then
			companion.behavior = BEHAVIORS.FOLLOWING
		end
	end

	-- If too far from player, teleport back
	if distanceToPlayer > 150 then
		companion.model:PivotTo(CFrame.new(playerRoot.Position + Vector3.new(5, 0, 5)))
		companion.behavior = BEHAVIORS.FOLLOWING
		sayDialogue(player, "returning")
	end

	-- Increase loyalty over time
	if companion.behavior == BEHAVIORS.FOLLOWING or companion.behavior == BEHAVIORS.IDLE then
		companion.loyalty = math.min(1, companion.loyalty + dt * 0.001)
	end
end

-- ==========================================
-- SPAWN COMPANION FOR PLAYER
-- ==========================================

local function spawnCompanion(player: Player)
	-- Wait for character
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not rootPart then return end

	-- Pick random personality
	local personality = PERSONALITIES[math.random(#PERSONALITIES)]

	-- Create camel - spawn OUTSIDE the spawn house (house is at 0, 0, -30)
	-- Always spawn in the front yard area, not inside buildings
	local CAMEL_SPAWN_SPOTS = {
		Vector3.new(30, 0, -10),   -- Front right of spawn house
		Vector3.new(-30, 0, -10),  -- Front left of spawn house
		Vector3.new(25, 0, 15),    -- Further out front
		Vector3.new(-25, 0, 15),   -- Further out front left
		Vector3.new(40, 0, 0),     -- Side yard right
	}
	local spawnSpot = CAMEL_SPAWN_SPOTS[math.random(#CAMEL_SPAWN_SPOTS)]
	local terrainHeight = Shared.getTerrainHeight(spawnSpot.X, spawnSpot.Z)
	local position = Vector3.new(spawnSpot.X, terrainHeight + 2, spawnSpot.Z)
	local model = createCamelModel(personality, position)

	companions[player] = {
		model = model,
		personality = personality,
		behavior = BEHAVIORS.FOLLOWING,
		behaviorTimer = 0,
		targetPosition = nil,
		lastDialogue = 0,
		hideSpot = nil,
		foundItems = {},
		loyalty = 0,
	}

	-- Greeting
	task.delay(2, function()
		sayDialogue(player, "greeting")
	end)

	CompanionRemote:FireClient(player, "COMPANION_SPAWNED", {
		name = personality.name,
		species = personality.species,
		trait = personality.trait,
	})

	print("[Companion]", player.Name, "received companion:", personality.name, "the", personality.trait, "Camel")
end

local function despawnCompanion(player: Player)
	local companion = companions[player]
	if companion then
		if companion.model and companion.model.Parent then
			companion.model:Destroy()
		end
		companions[player] = nil
	end
end

-- ==========================================
-- REMOTE HANDLERS
-- ==========================================

CompanionRemote.OnServerEvent:Connect(function(player: Player, action: string, data: any?)
	local companion = companions[player]
	if not companion then return end

	if action == "CALL" then
		-- Player is calling companion back
		returnToPlayer(player)
		sayDialogue(player, "returning")

	elseif action == "COMMAND_SCOUT" then
		startScouting(player)
		sayDialogue(player, "following") -- Acknowledge command

	elseif action == "FEED" then
		sayDialogue(player, "hungry") -- Happy eating sounds
		companion.loyalty = math.min(1, companion.loyalty + 0.1)

	elseif action == "PET" then
		companion.loyalty = math.min(1, companion.loyalty + 0.05)
		-- Random happy response
		local responses = { "greeting", "following" }
		sayDialogue(player, responses[math.random(#responses)])
	end
end)

-- ==========================================
-- PLAYER CONNECTIONS
-- ==========================================

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		-- Small delay then spawn companion
		task.delay(3, function()
			if not companions[player] then
				spawnCompanion(player)
			else
				-- Teleport existing companion
				local companion = companions[player]
				if companion and companion.model then
					local rootPart = char:FindFirstChild("HumanoidRootPart") :: BasePart?
					if rootPart then
						companion.model:PivotTo(CFrame.new(rootPart.Position + Vector3.new(5, 0, 0)))
						companion.behavior = BEHAVIORS.FOLLOWING
					end
				end
			end
		end)
	end)
end)

Players.PlayerRemoving:Connect(despawnCompanion)

-- Initialize existing players
for _, player in Players:GetPlayers() do
	if player.Character then
		task.spawn(function()
			spawnCompanion(player)
		end)
	end
end

-- ==========================================
-- GAME LOOP
-- ==========================================

RunService.Heartbeat:Connect(function(dt)
	for player, companion in companions do
		updateCompanion(player, dt)
	end
end)

print("[Companion] Companion system initialized!")
print("[Companion] - Every player gets a camel companion")
print("[Companion] - Companions have unique personalities")
print("[Companion] - They help... but also cause mischief!")
