--!strict
-- Rescue objectives for Mertin-Flemmer
-- Signal for rescue, survive nights, protect survivors

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config

-- Create remotes
local ObjectiveUpdateRemote = Instance.new("RemoteEvent")
ObjectiveUpdateRemote.Name = "ObjectiveUpdate"
ObjectiveUpdateRemote.Parent = ReplicatedStorage

-- Objective configuration
local OBJECTIVES = {
	SURVIVE_NIGHTS = 5, -- Survive this many nights to unlock rescue
	SIGNAL_PARTS_NEEDED = 6, -- Collect 6 signal parts to call for rescue (one per chapter!)
	RESCUE_DELAY = 60, -- Seconds after signaling before rescue arrives
}

-- State
local gameState = {
	nightsSurvived = 0,
	signalPartsCollected = 0,
	rescueSignaled = false,
	rescueTimer = 0,
	gameWon = false,
}

local signalParts: { BasePart } = {}
local rescueBeacon: Model? = nil

-- ROBUST floating height calculation
-- For Floor 7½ items, use fixed Y. For outdoor items, calculate terrain + offset.
local FLOAT_HEIGHT = 4 -- How high above terrain/floor to float
local FLOAT_AMPLITUDE = 0.5 -- How much to bob up and down

-- Create a signal part (collectible) with ROBUST terrain height
local function createSignalPart(position: Vector3, partNumber: number, isIndoor: boolean?): BasePart
	local part = Instance.new("Part")
	part.Name = "SignalPart_" .. partNumber
	part.Size = Vector3.new(2, 2, 2)
	part.Shape = Enum.PartType.Ball
	part.Color = Color3.fromRGB(50, 200, 255)
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false

	-- Calculate proper Y position
	local finalY: number
	if isIndoor then
		-- Indoor items (like Floor 7½) - use the provided Y directly + float offset
		finalY = position.Y + FLOAT_HEIGHT
	else
		-- Outdoor items - calculate terrain height and add float offset
		local terrainHeight = Shared.getTerrainHeight(position.X, position.Z)
		finalY = terrainHeight + FLOAT_HEIGHT
		print("[Objectives] Signal part", partNumber, "terrain height:", terrainHeight, "-> floating at Y:", finalY)
	end

	part.Position = Vector3.new(position.X, finalY, position.Z)

	-- Pulsing effect
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(50, 200, 255)
	highlight.FillTransparency = 0.5
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.Parent = part

	-- Billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 140, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "★ SIGNAL PART " .. partNumber .. "/" .. OBJECTIVES.SIGNAL_PARTS_NEEDED .. " ★"
	label.TextColor3 = Color3.fromRGB(50, 200, 255)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	-- Point light - brighter for visibility
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(50, 200, 255)
	light.Brightness = 4
	light.Range = 40
	light.Parent = part

	-- Particle effect for visibility
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Color3.fromRGB(50, 200, 255))
	particles.Transparency = NumberSequence.new(0, 0.5, 1)
	particles.Size = NumberSequence.new(0.5, 1, 0)
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 10
	particles.Speed = NumberRange.new(2, 5)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.LightEmission = 1
	particles.Parent = part

	-- Floating animation with stored base Y
	local baseY = part.Position.Y
	local animOffset = math.random() * math.pi * 2
	local connection: RBXScriptConnection?
	connection = RunService.Heartbeat:Connect(function()
		if not part or not part.Parent then
			if connection then connection:Disconnect() end
			return
		end
		local t = tick() + animOffset
		part.Position = Vector3.new(part.Position.X, baseY + math.sin(t * 2) * FLOAT_AMPLITUDE, part.Position.Z)
		part.Orientation = Vector3.new(0, (t * 50) % 360, 0)
	end)

	part.Parent = workspace
	return part
end

-- Create the rescue beacon at spawn
local function createRescueBeacon()
	local beacon = Instance.new("Model")
	beacon.Name = "RescueBeacon"

	-- Base
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(8, 2, 8)
	base.Position = Vector3.new(0, 1, 20)
	base.Color = Color3.fromRGB(80, 80, 90)
	base.Material = Enum.Material.Metal
	base.Anchored = true
	base.Parent = beacon

	-- Antenna
	local antenna = Instance.new("Part")
	antenna.Name = "Antenna"
	antenna.Size = Vector3.new(1, 12, 1)
	antenna.Position = Vector3.new(0, 8, 20)
	antenna.Color = Color3.fromRGB(150, 150, 160)
	antenna.Material = Enum.Material.Metal
	antenna.Anchored = true
	antenna.Parent = beacon

	-- Signal dish
	local dish = Instance.new("Part")
	dish.Name = "Dish"
	dish.Size = Vector3.new(4, 0.5, 4)
	dish.Position = Vector3.new(0, 14, 20)
	dish.Color = Color3.fromRGB(200, 200, 210)
	dish.Material = Enum.Material.Metal
	dish.Anchored = true
	dish.Parent = beacon

	-- Status light (red = inactive, green = ready, blue = signaling)
	local statusLight = Instance.new("Part")
	statusLight.Name = "StatusLight"
	statusLight.Size = Vector3.new(1, 1, 1)
	statusLight.Shape = Enum.PartType.Ball
	statusLight.Position = Vector3.new(0, 15, 20)
	statusLight.Color = Color3.fromRGB(100, 100, 100)
	statusLight.Material = Enum.Material.Neon
	statusLight.Anchored = true
	statusLight.Parent = beacon

	local statusPointLight = Instance.new("PointLight")
	statusPointLight.Name = "StatusPointLight"
	statusPointLight.Brightness = 0.5
	statusPointLight.Range = 10
	statusPointLight.Parent = statusLight

	-- Billboard for instructions
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Instructions"
	billboard.Size = UDim2.new(0, 200, 0, 80)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.Adornee = base
	billboard.Parent = beacon

	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Name = "Label"
	instructionLabel.Size = UDim2.new(1, 0, 1, 0)
	instructionLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	instructionLabel.BackgroundTransparency = 0.3
	instructionLabel.Text = "RESCUE BEACON\n[Needs Signal Parts]"
	instructionLabel.TextColor3 = Color3.new(1, 1, 1)
	instructionLabel.Font = Enum.Font.GothamBold
	instructionLabel.TextSize = 14
	instructionLabel.Parent = billboard

	local instructionCorner = Instance.new("UICorner")
	instructionCorner.CornerRadius = UDim.new(0, 8)
	instructionCorner.Parent = instructionLabel

	beacon.Parent = workspace
	rescueBeacon = beacon
	return beacon
end

-- Update beacon status
local function updateBeaconStatus()
	if not rescueBeacon then return end

	local statusLight = rescueBeacon:FindFirstChild("StatusLight") :: BasePart?
	local pointLight = statusLight and statusLight:FindFirstChild("StatusPointLight") :: PointLight?
	local billboard = rescueBeacon:FindFirstChild("Instructions") :: BillboardGui?
	local label = billboard and billboard:FindFirstChild("Label") :: TextLabel?

	if not statusLight or not pointLight or not label then return end

	if gameState.gameWon then
		statusLight.Color = Color3.fromRGB(100, 255, 100)
		pointLight.Color = Color3.fromRGB(100, 255, 100)
		label.Text = "RESCUE COMPLETE!\nYou survived!"
	elseif gameState.rescueSignaled then
		local timeLeft = math.ceil(OBJECTIVES.RESCUE_DELAY - gameState.rescueTimer)
		statusLight.Color = Color3.fromRGB(50, 200, 255)
		pointLight.Color = Color3.fromRGB(50, 200, 255)
		label.Text = "RESCUE INCOMING!\nETA: " .. timeLeft .. "s\nSurvive until then!"
	elseif gameState.signalPartsCollected >= OBJECTIVES.SIGNAL_PARTS_NEEDED and gameState.nightsSurvived >= OBJECTIVES.SURVIVE_NIGHTS then
		statusLight.Color = Color3.fromRGB(100, 255, 100)
		pointLight.Color = Color3.fromRGB(100, 255, 100)
		label.Text = "BEACON READY!\n[Walk near to signal]"
	elseif gameState.signalPartsCollected >= OBJECTIVES.SIGNAL_PARTS_NEEDED then
		statusLight.Color = Color3.fromRGB(255, 200, 50)
		pointLight.Color = Color3.fromRGB(255, 200, 50)
		label.Text = "Parts: " .. gameState.signalPartsCollected .. "/" .. OBJECTIVES.SIGNAL_PARTS_NEEDED ..
			"\nNights: " .. gameState.nightsSurvived .. "/" .. OBJECTIVES.SURVIVE_NIGHTS ..
			"\n[Survive more nights!]"
	else
		statusLight.Color = Color3.fromRGB(255, 100, 100)
		pointLight.Color = Color3.fromRGB(255, 100, 100)
		label.Text = "RESCUE BEACON\nParts: " .. gameState.signalPartsCollected .. "/" .. OBJECTIVES.SIGNAL_PARTS_NEEDED ..
			"\nNights: " .. gameState.nightsSurvived .. "/" .. OBJECTIVES.SURVIVE_NIGHTS
	end
end

-- Spawn signal parts across the world - ONE PER CHAPTER!
-- Positions match the chapter sign locations for exploration!
local function spawnSignalParts()
	task.wait(5) -- Wait for world to generate

	-- 6 Signal Parts - one for each chapter location!
	-- CHAPTER 1 IS FLOOR 7½ - The origin of the mystery!
	-- All outdoor parts use terrain height calculation for robust floating
	local positions = {
		-- Chapter 1: FLOOR 7½ - INDOOR! (Y=102 is the floor)
		{ pos = Vector3.new(150, 102, -100), name = "Chapter 1 - FLOOR 7½ (The Origin)", isIndoor = true },
		-- Chapter 2: FAR NORTH - Survivor's Camp (outdoor)
		{ pos = Vector3.new(100, 0, 350), name = "Chapter 2 - North Camp (The Awakening)", isIndoor = false },
		-- Chapter 3: FAR NORTHWEST - Forest Guardian (outdoor)
		{ pos = Vector3.new(-400, 0, 700), name = "Chapter 3 - Deep Forest (Whispering Woods)", isIndoor = false },
		-- Chapter 4: FAR EAST - Frozen Mountain Peak (outdoor)
		{ pos = Vector3.new(800, 0, -300), name = "Chapter 4 - Mountain Summit (Frozen Peaks)", isIndoor = false },
		-- Chapter 5: FAR WEST - Pirate Cove (outdoor)
		{ pos = Vector3.new(-750, 0, 150), name = "Chapter 5 - Coastal Cove (Pirate Territory)", isIndoor = false },
		-- Chapter 6: FAR SOUTH - Prophecy Stone (outdoor)
		{ pos = Vector3.new(0, 0, -600), name = "Chapter 6 - Prophecy Stone (The Final Truth)", isIndoor = false },
	}

	for i, data in positions do
		local part = createSignalPart(data.pos, i, data.isIndoor)
		table.insert(signalParts, part)
		print("[Objectives] Signal part", i, "at:", data.name)
	end

	print("[Objectives] Spawned", #signalParts, "signal parts - ONE PER CHAPTER!")
	print("[Objectives] EXPLORATION MAP:")
	print("[Objectives]   Ch1: Floor 7½ Building | Ch2: FAR NORTH (350)")
	print("[Objectives]   Ch3: FAR NORTHWEST (700) | Ch4: FAR EAST (-300)")
	print("[Objectives]   Ch5: FAR WEST (150) | Ch6: FAR SOUTH (-600)")
end

-- Check for signal part collection and beacon activation
local function checkObjectives()
	-- Check signal part collection
	for i, part in signalParts do
		if not part or not part.Parent then continue end

		for _, player in Players:GetPlayers() do
			local character = player.Character
			if not character then continue end

			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not rootPart then continue end

			local distance = (rootPart.Position - part.Position).Magnitude
			if distance < 5 then
				-- Collect the part!
				gameState.signalPartsCollected += 1
				part:Destroy()
				signalParts[i] = nil :: any

				-- Notify all players
				for _, p in Players:GetPlayers() do
					ObjectiveUpdateRemote:FireClient(p, "PART_COLLECTED", gameState)
				end

				print("[Objectives]", player.Name, "collected signal part!", gameState.signalPartsCollected, "/", OBJECTIVES.SIGNAL_PARTS_NEEDED)
				updateBeaconStatus()
				break
			end
		end
	end

	-- Check beacon activation
	if not gameState.rescueSignaled and
		gameState.signalPartsCollected >= OBJECTIVES.SIGNAL_PARTS_NEEDED and
		gameState.nightsSurvived >= OBJECTIVES.SURVIVE_NIGHTS then

		-- Check if any player is near beacon
		if rescueBeacon then
			local beaconBase = rescueBeacon:FindFirstChild("Base") :: BasePart?
			if beaconBase then
				for _, player in Players:GetPlayers() do
					local character = player.Character
					if not character then continue end

					local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if not rootPart then continue end

					local distance = (rootPart.Position - beaconBase.Position).Magnitude
					if distance < 10 then
						-- Activate rescue signal!
						gameState.rescueSignaled = true
						gameState.rescueTimer = 0

						for _, p in Players:GetPlayers() do
							ObjectiveUpdateRemote:FireClient(p, "RESCUE_SIGNALED", gameState)
						end

						print("[Objectives] RESCUE SIGNALED! Survive for", OBJECTIVES.RESCUE_DELAY, "seconds!")
						updateBeaconStatus()
						break
					end
				end
			end
		end
	end
end

-- Track night survival
local wasNight = false
RunService.Heartbeat:Connect(function(dt)
	local hour = Lighting.ClockTime
	local isNight = hour >= 20 or hour < 5

	-- Count night-to-day transitions as surviving a night
	if wasNight and not isNight then
		gameState.nightsSurvived += 1
		print("[Objectives] Night survived! Total:", gameState.nightsSurvived)

		for _, player in Players:GetPlayers() do
			ObjectiveUpdateRemote:FireClient(player, "NIGHT_SURVIVED", gameState)
		end

		updateBeaconStatus()
	end

	wasNight = isNight

	-- Update rescue timer
	if gameState.rescueSignaled and not gameState.gameWon then
		gameState.rescueTimer += dt

		-- Update beacon every second
		if math.floor(gameState.rescueTimer) ~= math.floor(gameState.rescueTimer - dt) then
			updateBeaconStatus()
		end

		if gameState.rescueTimer >= OBJECTIVES.RESCUE_DELAY then
			-- GAME WON!
			gameState.gameWon = true
			print("[Objectives] RESCUE ARRIVED! Game complete!")

			for _, player in Players:GetPlayers() do
				ObjectiveUpdateRemote:FireClient(player, "GAME_WON", gameState)
			end

			updateBeaconStatus()
		end
	end

	-- Check objectives
	checkObjectives()
end)

-- Send initial state to joining players
Players.PlayerAdded:Connect(function(player)
	task.wait(1)
	ObjectiveUpdateRemote:FireClient(player, "INIT", gameState)
end)

-- Initialize
task.spawn(function()
	createRescueBeacon()
	spawnSignalParts()
	updateBeaconStatus()
	print("[Objectives] Objective system initialized!")
	print("[Objectives] Collect", OBJECTIVES.SIGNAL_PARTS_NEEDED, "signal parts and survive", OBJECTIVES.SURVIVE_NIGHTS, "nights to call for rescue!")
end)
