--!strict
--[[
	Faultline Fear: Pet Service

	Creates and manages the player's pet companion.
	Pet provides comic relief, ambient commentary, and danger warnings.

	Features:
	- Following behavior with terrain awareness
	- Distraction events (butterflies, shiny objects, etc.)
	- Dialogue via billboard text bubbles
	- Danger warnings for nearby creatures
	- Wandering and returning behavior

	Exports: Initialize(), GetPet(), CallPet()
	Depends: Config, Heightmap, CreatureService, EarthquakeService
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local _TweenService = game:GetService("TweenService") -- For future animations
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local _Config = Shared.Config -- May be used for pet behavior tuning
local Heightmap = Shared.Heightmap
local AssetManifest = Shared.AssetManifest
local AssetColors = Shared.AssetColors

local PetService = {}

-- External service references (set via setter methods)
local CreatureService: any = nil
local _EarthquakeService: any = nil -- Set via SetEarthquakeService, used for future earthquake reactions

-- State
local pets: { [Player]: Model } = {}
local petStates: { [Player]: PetState } = {}
local petsFolder: Folder = nil :: any

-- Pet behavior constants
local FOLLOW_DISTANCE = 4 -- Studs behind player
local FOLLOW_SPEED = 16 -- Walk speed when following
local MAX_FOLLOW_DISTANCE = 30 -- Teleport if too far
local DISTRACTION_CHANCE = 0.002 -- Per frame chance when idle
local DISTRACTION_DURATION = { min = 3, max = 8 } -- Seconds
local WANDER_DISTANCE = 15 -- Max distance to wander
local DIALOGUE_DURATION = 3 -- Seconds to show dialogue
local DANGER_DETECT_RANGE = 40 -- Studs to detect nearby threats

-- Pet state machine
export type PetStateType = "following" | "distracted" | "wandering" | "sleeping" | "scared" | "returning"

type PetState = {
	state: PetStateType,
	stateStartTime: number,
	distractionTarget: Vector3?,
	lastDialogueTime: number,
	idleTime: number,
}

-- Dialogue categories
local DIALOGUE = {
	idle = {
		"Are we there yet?",
		"I smell something interesting...",
		"*yawn* Can we take a break?",
		"What's over there?",
		"I'm hungry...",
		"This place is weird.",
	},
	earthquake = {
		"WHAT WAS THAT?!",
		"Not again!",
		"Hold on to your fur!",
		"THE GROUND IS ANGRY!",
		"Hide! Hide!",
	},
	predator_nearby = {
		"I don't like the smell of this...",
		"Something's watching us...",
		"Maybe we should run?",
		"*whimper*",
		"Stay close...",
	},
	food_found = {
		"FOOD! Can I have some?",
		"Ooh, is that for me?",
		"My tummy says yes!",
	},
	survivor_rescued = {
		"New friend!",
		"They seem nice!",
		"The more the merrier!",
	},
	returning = {
		"Wait for me!",
		"I'm coming!",
		"Don't leave me!",
	},
	distracted = {
		"Ooh, what's that?",
		"Shiny!",
		"Must... investigate...",
		"I'll be right back!",
	},
	sleeping = {
		"*zzz*",
		"*snore*",
		"Five more minutes...",
	},
	scared = {
		"AHHH!",
		"RUN!",
		"Nope nope nope!",
	},
}

-- ==========================================
-- PET CREATION
-- ==========================================

local function createPetModel(): Model
	-- Try to get imported model first
	local model = AssetManifest:CloneAsset("PetCompanion")

	if model then
		-- Apply colors to imported model (Roblox doesn't import FBX colors)
		AssetColors:ApplyColors(model, "PetCompanion")
	else
		-- Create placeholder pet
		model = Instance.new("Model")
		model.Name = "Pet"

		-- Body (small, cute shape)
		local body = Instance.new("Part")
		body.Name = "HumanoidRootPart"
		body.Size = Vector3.new(1.5, 1, 2)
		body.Anchored = true
		body.CanCollide = false
		body.Color = Color3.fromRGB(180, 140, 100) -- Tan/brown
		body.Material = Enum.Material.SmoothPlastic
		body.Parent = model

		-- Head
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Shape = Enum.PartType.Ball
		head.Size = Vector3.new(1, 1, 1)
		head.Position = body.Position + Vector3.new(0.5, 0.3, 0)
		head.Anchored = true
		head.CanCollide = false
		head.Color = Color3.fromRGB(180, 140, 100)
		head.Material = Enum.Material.SmoothPlastic
		head.Parent = model

		-- Ears (two small wedges)
		for i, offset in ipairs({ Vector3.new(0.3, 0.6, 0.3), Vector3.new(0.3, 0.6, -0.3) }) do
			local ear = Instance.new("Part")
			ear.Name = "Ear" .. i
			ear.Size = Vector3.new(0.3, 0.4, 0.2)
			ear.Position = head.Position + offset
			ear.Anchored = true
			ear.CanCollide = false
			ear.Color = Color3.fromRGB(160, 120, 80)
			ear.Material = Enum.Material.SmoothPlastic
			ear.Parent = model
		end

		-- Tail (small cylinder)
		local tail = Instance.new("Part")
		tail.Name = "Tail"
		tail.Shape = Enum.PartType.Cylinder
		tail.Size = Vector3.new(0.8, 0.3, 0.3)
		tail.Position = body.Position + Vector3.new(-1, 0.2, 0)
		tail.Anchored = true
		tail.CanCollide = false
		tail.Color = Color3.fromRGB(180, 140, 100)
		tail.Material = Enum.Material.SmoothPlastic
		tail.Parent = model

		-- Eyes (two small black parts)
		for i, zOffset in ipairs({ 0.2, -0.2 }) do
			local eye = Instance.new("Part")
			eye.Name = "Eye" .. i
			eye.Shape = Enum.PartType.Ball
			eye.Size = Vector3.new(0.15, 0.15, 0.15)
			eye.Position = head.Position + Vector3.new(0.4, 0.1, zOffset)
			eye.Anchored = true
			eye.CanCollide = false
			eye.Color = Color3.fromRGB(30, 30, 30)
			eye.Material = Enum.Material.SmoothPlastic
			eye.Parent = model
		end

		-- Nose
		local nose = Instance.new("Part")
		nose.Name = "Nose"
		nose.Shape = Enum.PartType.Ball
		nose.Size = Vector3.new(0.2, 0.15, 0.15)
		nose.Position = head.Position + Vector3.new(0.5, -0.1, 0)
		nose.Anchored = true
		nose.CanCollide = false
		nose.Color = Color3.fromRGB(50, 30, 30)
		nose.Material = Enum.Material.SmoothPlastic
		nose.Parent = model

		model.PrimaryPart = body
	end

	-- Add humanoid for name display
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = "Buddy"
	humanoid.HealthDisplayDistance = 0
	humanoid.NameDisplayDistance = 15
	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge
	humanoid.Parent = model

	-- Add dialogue billboard GUI
	local dialogueBillboard = Instance.new("BillboardGui")
	dialogueBillboard.Name = "DialogueBillboard"
	dialogueBillboard.Size = UDim2.new(0, 150, 0, 40)
	dialogueBillboard.StudsOffset = Vector3.new(0, 2.5, 0)
	dialogueBillboard.AlwaysOnTop = false
	dialogueBillboard.Enabled = false
	dialogueBillboard.Parent = model.PrimaryPart

	local dialogueBackground = Instance.new("Frame")
	dialogueBackground.Size = UDim2.new(1, 0, 1, 0)
	dialogueBackground.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	dialogueBackground.BackgroundTransparency = 0.2
	dialogueBackground.BorderSizePixel = 0
	dialogueBackground.Parent = dialogueBillboard

	local dialogueCorner = Instance.new("UICorner")
	dialogueCorner.CornerRadius = UDim.new(0, 8)
	dialogueCorner.Parent = dialogueBackground

	local dialogueText = Instance.new("TextLabel")
	dialogueText.Name = "DialogueText"
	dialogueText.Size = UDim2.new(1, -10, 1, -6)
	dialogueText.Position = UDim2.new(0, 5, 0, 3)
	dialogueText.BackgroundTransparency = 1
	dialogueText.TextColor3 = Color3.fromRGB(60, 40, 20)
	dialogueText.TextScaled = true
	dialogueText.Font = Enum.Font.GothamBold
	dialogueText.Text = ""
	dialogueText.Parent = dialogueBackground

	-- Add CollectionService tags
	CollectionService:AddTag(model, "Pet")
	CollectionService:AddTag(model, "Companion")

	-- Set attributes
	model:SetAttribute("PetName", "Buddy")
	model:SetAttribute("IsPet", true)

	return model
end

-- ==========================================
-- DIALOGUE SYSTEM
-- ==========================================

local function showDialogue(player: Player, category: string)
	local pet = pets[player]
	local state = petStates[player]
	if not pet or not state then
		return
	end

	-- Rate limit dialogue
	local now = tick()
	if now - state.lastDialogueTime < 5 then
		return
	end
	state.lastDialogueTime = now

	-- Get random dialogue from category
	local dialogueList = DIALOGUE[category]
	if not dialogueList then
		return
	end

	local text = dialogueList[math.random(1, #dialogueList)]

	-- Show dialogue billboard
	local billboard = pet.PrimaryPart and pet.PrimaryPart:FindFirstChild("DialogueBillboard") :: BillboardGui?
	if not billboard then
		return
	end

	local background = billboard:FindFirstChild("Frame")
	local textLabel = background and background:FindFirstChild("DialogueText") :: TextLabel?
	if not textLabel then
		return
	end

	textLabel.Text = text
	billboard.Enabled = true

	-- Hide after duration
	task.delay(DIALOGUE_DURATION, function()
		if pet.Parent and billboard then
			billboard.Enabled = false
		end
	end)
end

-- ==========================================
-- STATE MACHINE
-- ==========================================

local function setState(player: Player, newState: PetStateType)
	local state = petStates[player]
	if not state then
		return
	end

	state.state = newState
	state.stateStartTime = tick()

	-- Dialogue on state change
	if newState == "distracted" then
		showDialogue(player, "distracted")
	elseif newState == "sleeping" then
		showDialogue(player, "sleeping")
	elseif newState == "scared" then
		showDialogue(player, "scared")
	elseif newState == "returning" then
		showDialogue(player, "returning")
	end
end

local function getRandomDistraction(petPos: Vector3): Vector3
	local angle = math.random() * math.pi * 2
	local distance = math.random(5, WANDER_DISTANCE)
	return petPos + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
end

-- ==========================================
-- DANGER DETECTION
-- ==========================================

local function checkForNearbyDangers(player: Player): boolean
	local pet = pets[player]
	if not pet or not pet.PrimaryPart then
		return false
	end

	local petPos = pet.PrimaryPart.Position

	-- Check for creatures via CreatureService
	if CreatureService then
		local creatures = Workspace:FindFirstChild("Creatures")
		if creatures then
			for _, creature in creatures:GetChildren() do
				if creature:IsA("Model") and creature.PrimaryPart then
					local dist = (creature.PrimaryPart.Position - petPos).Magnitude
					if dist < DANGER_DETECT_RANGE then
						return true
					end
				end
			end
		end
	end

	return false
end

-- ==========================================
-- PET UPDATE LOOP
-- ==========================================

local function updatePet(player: Player, _dt: number)
	local pet = pets[player]
	local state = petStates[player]
	local character = player.Character

	if not pet or not state or not character then
		return
	end
	if not pet.PrimaryPart or not pet.Parent then
		return
	end

	local playerRoot = character:FindFirstChild("HumanoidRootPart")
	if not playerRoot then
		return
	end

	local petPos = pet.PrimaryPart.Position
	local playerPos = playerRoot.Position
	local distanceToPlayer = (playerPos - petPos).Magnitude
	local now = tick()

	-- State machine update
	if state.state == "following" then
		-- Check for dangers
		if checkForNearbyDangers(player) then
			setState(player, "scared")
			showDialogue(player, "predator_nearby")
			return
		end

		-- Check for idle time
		local playerVelocity = playerRoot.AssemblyLinearVelocity.Magnitude
		if playerVelocity < 1 then
			state.idleTime += 0.016
			if state.idleTime > 10 and math.random() < 0.01 then
				setState(player, "sleeping")
				return
			end
		else
			state.idleTime = 0
		end

		-- Random distraction chance
		if math.random() < DISTRACTION_CHANCE then
			state.distractionTarget = getRandomDistraction(petPos)
			setState(player, "distracted")
			return
		end

		-- Random idle dialogue
		if math.random() < 0.0005 then
			showDialogue(player, "idle")
		end

		-- Follow player
		if distanceToPlayer > MAX_FOLLOW_DISTANCE then
			-- Teleport to player
			local behindPlayer = playerPos - playerRoot.CFrame.LookVector * FOLLOW_DISTANCE
			local terrainY = Heightmap:GetHeight(behindPlayer.X, behindPlayer.Z)
			pet:PivotTo(CFrame.new(behindPlayer.X, terrainY + 0.5, behindPlayer.Z))
		elseif distanceToPlayer > FOLLOW_DISTANCE then
			-- Move toward player
			local direction = (playerPos - petPos).Unit
			local targetPos = petPos + direction * FOLLOW_SPEED * 0.016

			local terrainY = Heightmap:GetHeight(targetPos.X, targetPos.Z)
			local lookCFrame = CFrame.lookAt(
				Vector3.new(targetPos.X, terrainY + 0.5, targetPos.Z),
				Vector3.new(playerPos.X, terrainY + 0.5, playerPos.Z)
			)
			pet:PivotTo(lookCFrame)
		end
	elseif state.state == "distracted" then
		local stateDuration = now - state.stateStartTime
		local maxDuration = math.random(DISTRACTION_DURATION.min, DISTRACTION_DURATION.max)

		if stateDuration > maxDuration or distanceToPlayer > MAX_FOLLOW_DISTANCE then
			state.distractionTarget = nil
			setState(player, "returning")
			return
		end

		-- Move toward distraction
		if state.distractionTarget then
			local direction = (state.distractionTarget - petPos).Unit
			local targetPos = petPos + direction * (FOLLOW_SPEED * 0.5) * 0.016

			local terrainY = Heightmap:GetHeight(targetPos.X, targetPos.Z)
			pet:PivotTo(CFrame.new(targetPos.X, terrainY + 0.5, targetPos.Z))
		end
	elseif state.state == "sleeping" then
		-- Wake up if player moves or after a while
		local stateDuration = now - state.stateStartTime
		if stateDuration > 5 or distanceToPlayer > 15 then
			setState(player, "following")
		end
	elseif state.state == "scared" then
		-- Run to player
		if distanceToPlayer < FOLLOW_DISTANCE + 1 then
			setState(player, "following")
			return
		end

		-- Move quickly toward player
		local direction = (playerPos - petPos).Unit
		local targetPos = petPos + direction * (FOLLOW_SPEED * 1.5) * 0.016

		local terrainY = Heightmap:GetHeight(targetPos.X, targetPos.Z)
		pet:PivotTo(CFrame.new(targetPos.X, terrainY + 0.5, targetPos.Z))
	elseif state.state == "returning" then
		if distanceToPlayer < FOLLOW_DISTANCE + 2 then
			setState(player, "following")
			return
		end

		-- Move toward player
		local direction = (playerPos - petPos).Unit
		local targetPos = petPos + direction * (FOLLOW_SPEED * 1.2) * 0.016

		local terrainY = Heightmap:GetHeight(targetPos.X, targetPos.Z)
		pet:PivotTo(CFrame.new(targetPos.X, terrainY + 0.5, targetPos.Z))
	end
end

local function updateAllPets()
	local dt = 0.016 -- Approximate frame time
	for player, _ in pairs(pets) do
		updatePet(player, dt)
	end
end

-- ==========================================
-- PUBLIC API
-- ==========================================

function PetService:SpawnPet(player: Player)
	if pets[player] then
		return
	end -- Already has pet

	local character = player.Character
	if not character then
		return
	end

	local playerRoot = character:FindFirstChild("HumanoidRootPart")
	if not playerRoot then
		return
	end

	-- Create pet
	local pet = createPetModel()

	-- Position behind player
	local spawnPos = playerRoot.Position - playerRoot.CFrame.LookVector * FOLLOW_DISTANCE
	local terrainY = Heightmap:GetHeight(spawnPos.X, spawnPos.Z)
	pet:PivotTo(CFrame.new(spawnPos.X, terrainY + 0.5, spawnPos.Z))

	-- Parent
	pet.Parent = petsFolder
	pets[player] = pet

	-- Initialize state
	petStates[player] = {
		state = "following",
		stateStartTime = tick(),
		distractionTarget = nil,
		lastDialogueTime = 0,
		idleTime = 0,
	}

	print(string.format("[PetService] Spawned pet for %s", player.Name))
end

function PetService:DespawnPet(player: Player)
	local pet = pets[player]
	if pet then
		pet:Destroy()
	end
	pets[player] = nil
	petStates[player] = nil
end

function PetService:GetPet(player: Player): Model?
	return pets[player]
end

function PetService:CallPet(player: Player)
	local state = petStates[player]
	if state and state.state ~= "following" then
		setState(player, "returning")
		showDialogue(player, "returning")
	end
end

function PetService:TriggerEarthquakeReaction(player: Player)
	showDialogue(player, "earthquake")
	local state = petStates[player]
	if state then
		setState(player, "scared")
	end
end

function PetService:TriggerFoodReaction(player: Player)
	showDialogue(player, "food_found")
end

function PetService:TriggerSurvivorReaction(player: Player)
	showDialogue(player, "survivor_rescued")
end

-- ==========================================
-- SERVICE CONNECTIONS
-- ==========================================

function PetService:SetCreatureService(service: any)
	CreatureService = service
end

function PetService:SetEarthquakeService(service: any)
	_EarthquakeService = service
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function PetService:Initialize()
	-- Create folder
	petsFolder = Instance.new("Folder")
	petsFolder.Name = "Pets"
	petsFolder.Parent = Workspace

	-- Update loop
	RunService.Heartbeat:Connect(updateAllPets)

	-- Spawn pet when character loads
	local function onCharacterAdded(player: Player, character: Model)
		-- Wait for character to be fully loaded
		local humanoid = character:WaitForChild("Humanoid", 5)
		if not humanoid then
			return
		end

		-- Small delay for everything to settle
		task.delay(1, function()
			if player.Parent then
				self:SpawnPet(player)
			end
		end)
	end

	-- Handle existing players
	for _, player in Players:GetPlayers() do
		if player.Character then
			task.spawn(onCharacterAdded, player, player.Character)
		end
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end

	-- Handle new players
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end)

	-- Clean up on player leave
	Players.PlayerRemoving:Connect(function(player)
		self:DespawnPet(player)
	end)

	print("[PetService] Initialized")
end

return PetService
