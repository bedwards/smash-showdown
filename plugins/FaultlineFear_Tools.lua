--[[
	Faultline Fear: Studio Tools
	Version: 5.0.0 - December 2024

	Consolidated plugin for all Faultline Fear and Fault-Lite Studio operations.

	BUTTONS:
	1. "Clear ALL" - Removes ALL imported assets from everywhere
	2. "Move to Storage" - Moves imported FBX from Workspace to ServerStorage
	3. "Download & Scale" - Downloads cloud assets and scales to correct size
	4. "Diagnose" - Shows what's near spawn point
	5. "Spawn Structure" - Opens widget to place structures (Fault-Lite)

	SPAWN STRUCTURE WIDGET:
	- Select a spawn point (Spawn, Beach, Forest, Mountain, etc.)
	- Click a structure to spawn TWO versions:
	  1. ANCHORED - Perfectly placed on ground at correct height
	  2. DROPPED - Unanchored, falls from above head height
	- Uses shared placement logic (matches Faultline Fear game)

	INSTALLATION:
	Copy to: ~/Documents/Roblox/Plugins/FaultlineFear_Tools.lua
	Clear cache: rm -rf ~/Library/Caches/com.roblox.RobloxStudio
	Restart Studio
]]

local PLUGIN_VERSION = "5.4.0"
local PLUGIN_ID = "FaultlineFear_Tools"

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")

-- Check if we're in Play mode (game is running)
local function isPlayMode()
	return RunService:IsRunning()
end

-- Create toolbar
local toolbar = plugin:CreateToolbar("Faultline Fear")

local clearButton = toolbar:CreateButton(
	"Clear ALL",
	"Delete ALL imported assets from Workspace, ReplicatedStorage, and ServerStorage",
	"rbxassetid://6031075931"
)

local moveButton = toolbar:CreateButton(
	"Move to Storage",
	"Move imported FBX assets from Workspace to ServerStorage.AssetTemplates",
	"rbxassetid://6031075938"
)

local scaleButton = toolbar:CreateButton(
	"Download & Scale",
	"Download cloud assets and scale to correct size",
	"rbxassetid://6031075938"
)

local diagnoseButton = toolbar:CreateButton(
	"Diagnose",
	"Show what's near spawn point",
	"rbxassetid://6031075929"
)

local spawnButton = toolbar:CreateButton(
	"Spawn Structure",
	"Place a structure in Workspace (Fault-Lite showcase)",
	"rbxassetid://6031075938"
)

local function log(msg)
	print(string.format("[%s] %s", PLUGIN_ID, msg))
end

-- ==========================================
-- CLOUD ASSET DEFINITIONS
-- ==========================================

local CLOUD_ASSETS = {
	FerrisWheel = 128227709441371,
	RadioTower = 119758365110065,
	WaterTower = 74085624282098,
	Lighthouse = 97584625740584,
	AbandonedHouse = 90248483610888,
	Bridge = 105968577364311,
}

local TARGET_SIZES = {
	FerrisWheel = Vector3.new(40, 45, 10),
	RadioTower = Vector3.new(15, 60, 15),
	WaterTower = Vector3.new(15, 35, 15),
	Lighthouse = Vector3.new(10, 30, 10),
	AbandonedHouse = Vector3.new(25, 20, 20),
	Bridge = Vector3.new(80, 5, 15),
}

-- Structure list for UI
local STRUCTURE_LIST = {
	"FerrisWheel",
	"RadioTower",
	"WaterTower",
	"Lighthouse",
	"AbandonedHouse",
	"Bridge",
}

-- Named spawn points (must match TerrainConfig.SPAWN_POINTS)
-- Heights calculated dynamically from terrain
local SPAWN_POINTS = {
	{ name = "Spawn", x = 0, z = 0, description = "Default spawn (flat area)" },
	{ name = "Beach", x = 0, z = -1000, description = "Beach zone, near waterline" },
	{ name = "Boardwalk", x = 200, z = -950, description = "Beach boardwalk area" },
	{ name = "Coastal", x = 0, z = -500, description = "Coastal hills" },
	{ name = "Valley", x = 0, z = 100, description = "Valley floor" },
	{ name = "FaultEdge", x = 0, z = 500, description = "Edge of fault line" },
	{ name = "FaultCenter", x = 0, z = 600, description = "Center of fault rift" },
	{ name = "Forest", x = 0, z = 1100, description = "Forest zone, rolling hills" },
	{ name = "ForestClearing", x = 300, z = 1200, description = "Forest clearing" },
	{ name = "MountainBase", x = 0, z = 1550, description = "Base of mountains" },
	{ name = "MountainSlope", x = 0, z = 1750, description = "Mountain slope" },
}

-- Current selected spawn point
local selectedSpawnPoint = SPAWN_POINTS[1]

-- Drop height above terrain (studs above head height)
local DROP_HEIGHT = 15

-- Spacing between anchored and dropped structures
local STRUCTURE_SPACING = 40

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================

-- Estimate terrain height at a position (for plugin use)
-- This matches the heightmap generation in TerrainCore/Heightmap.luau
local function estimateTerrainHeight(x, z)
	local WORLD_SIZE = 4000
	local halfWorld = WORLD_SIZE / 2

	-- Clamp to world bounds
	x = math.clamp(x, -halfWorld, halfWorld)
	z = math.clamp(z, -halfWorld, halfWorld)

	-- Determine zone and base height
	local height = 0

	if z < -1200 then
		-- Ocean
		height = -10
	elseif z < -800 then
		-- Beach (gradual rise from ocean)
		local t = (z + 1200) / 400
		height = -10 + t * 15
	elseif z < -200 then
		-- Coastal
		local t = (z + 800) / 600
		height = 5 + t * 15
	elseif z < 400 then
		-- Valley
		height = 20 + math.sin(x * 0.01) * 5
	elseif z < 800 then
		-- Fault line (dips in center)
		local faultCenter = 600
		local distFromCenter = math.abs(z - faultCenter)
		local faultWidth = 100
		if distFromCenter < faultWidth then
			local t = distFromCenter / faultWidth
			height = 30 - (1 - t) * 40 -- Drops to -10 at center
		else
			height = 30
		end
	elseif z < 1500 then
		-- Forest (rolling hills)
		local t = (z - 800) / 700
		height = 60 + t * 110 + math.sin(x * 0.02) * 20
	else
		-- Mountains
		local t = (z - 1500) / 500
		height = 200 + t * 200 + math.sin(x * 0.015) * 30
	end

	return height
end

-- Get model bottom offset (distance from pivot to lowest point)
local function getModelBottomOffset(model)
	local minY = math.huge
	local pivot = model:GetPivot()

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local partBottom = part.Position.Y - part.Size.Y / 2
			minY = math.min(minY, partBottom)
		end
	end

	if minY == math.huge then
		return 0
	end

	return pivot.Position.Y - minY
end

-- Get model height
local function getModelHeight(model)
	local minY = math.huge
	local maxY = -math.huge

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local partBottom = part.Position.Y - part.Size.Y / 2
			local partTop = part.Position.Y + part.Size.Y / 2
			minY = math.min(minY, partBottom)
			maxY = math.max(maxY, partTop)
		end
	end

	if minY == math.huge then
		return 0
	end

	return maxY - minY
end

local function getTemplatesFolder()
	local folder = ServerStorage:FindFirstChild("AssetTemplates")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "AssetTemplates"
		folder.Parent = ServerStorage
		log("Created ServerStorage.AssetTemplates folder")
	end
	return folder
end

local function getBoundingBox(model)
	local minBound = Vector3.new(math.huge, math.huge, math.huge)
	local maxBound = Vector3.new(-math.huge, -math.huge, -math.huge)
	local partCount = 0

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			partCount = partCount + 1
			local pos = part.Position
			local halfSize = part.Size / 2

			minBound = Vector3.new(
				math.min(minBound.X, pos.X - halfSize.X),
				math.min(minBound.Y, pos.Y - halfSize.Y),
				math.min(minBound.Z, pos.Z - halfSize.Z)
			)
			maxBound = Vector3.new(
				math.max(maxBound.X, pos.X + halfSize.X),
				math.max(maxBound.Y, pos.Y + halfSize.Y),
				math.max(maxBound.Z, pos.Z + halfSize.Z)
			)
		end
	end

	if partCount == 0 then
		return nil, Vector3.new(0, 0, 0)
	end

	local center = (minBound + maxBound) / 2
	local size = maxBound - minBound

	return center, size, minBound.Y
end

local function getSpawnPosition()
	local spawnLocation = game.Workspace:FindFirstChild("SpawnLocation")
	if spawnLocation then
		return spawnLocation.Position
	end
	return Vector3.new(0, 35, 0)
end

-- ==========================================
-- 1. CLEAR ALL ASSETS
-- ==========================================

local function clearAllAssets()
	ChangeHistoryService:SetWaypoint("Before Clear Assets")

	log("========================================")
	log("CLEARING ALL ASSETS...")
	log("========================================")

	local workspaceCount = 0
	local replicatedCount = 0
	local serverCount = 0

	-- Clear Structures folder
	local structuresFolder = game.Workspace:FindFirstChild("Structures")
	if structuresFolder then
		for _, child in structuresFolder:GetChildren() do
			child:Destroy()
			workspaceCount = workspaceCount + 1
		end
	end

	-- Clear ShowcaseStructure
	local showcase = game.Workspace:FindFirstChild("ShowcaseStructure")
	if showcase then
		showcase:Destroy()
		workspaceCount = workspaceCount + 1
	end

	-- Clear from Workspace (pattern-matched)
	for _, obj in game.Workspace:GetChildren() do
		if string.match(obj.Name, "^%w+_%w+") then
			local skipNames = { Camera = true, Terrain = true, SpawnLocation = true }
			if not skipNames[obj.Name] then
				obj:Destroy()
				workspaceCount = workspaceCount + 1
			end
		elseif obj:IsA("MeshPart") or (obj:IsA("Model") and obj:FindFirstChildOfClass("MeshPart")) then
			if not obj:FindFirstChild("Humanoid") then
				obj:Destroy()
				workspaceCount = workspaceCount + 1
			end
		end
	end

	-- Clear containers
	for _, container in game.Workspace:GetChildren() do
		if container:IsA("Model") or container:IsA("Folder") then
			for _, item in container:GetChildren() do
				if string.match(item.Name, "^%w+_%w+") then
					item:Destroy()
					workspaceCount = workspaceCount + 1
				end
			end
			if #container:GetChildren() == 0 then
				container:Destroy()
			end
		end
	end

	-- Clear ReplicatedStorage.Assets
	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	if assetsFolder then
		for _, categoryFolder in assetsFolder:GetChildren() do
			if categoryFolder:IsA("Folder") then
				for _, asset in categoryFolder:GetChildren() do
					asset:Destroy()
					replicatedCount = replicatedCount + 1
				end
			end
		end
	end

	-- Clear ServerStorage.AssetTemplates
	local templatesFolder = ServerStorage:FindFirstChild("AssetTemplates")
	if templatesFolder then
		for _, asset in templatesFolder:GetChildren() do
			asset:Destroy()
			serverCount = serverCount + 1
		end
	end

	ChangeHistoryService:SetWaypoint("After Clear Assets")

	log("CLEARED:")
	log("  Workspace: " .. workspaceCount)
	log("  ReplicatedStorage: " .. replicatedCount)
	log("  ServerStorage: " .. serverCount)
	log("  TOTAL: " .. (workspaceCount + replicatedCount + serverCount))
	log("========================================")
end

-- ==========================================
-- 2. MOVE TO STORAGE
-- ==========================================

local function moveToStorage()
	log("========================================")
	log("MOVING IMPORTS TO STORAGE...")
	log("========================================")

	local templatesFolder = getTemplatesFolder()
	local movedCount = 0
	local skippedCount = 0
	local itemsToMove = {}

	-- Collect items
	for _, item in game.Workspace:GetChildren() do
		if string.match(item.Name, "^%w+_%w+") then
			local skipNames = { Camera = true, Terrain = true, SpawnLocation = true }
			if not skipNames[item.Name] then
				table.insert(itemsToMove, item)
			end
		end
	end

	-- Check containers
	for _, container in game.Workspace:GetChildren() do
		if container:IsA("Model") or container:IsA("Folder") then
			for _, item in container:GetChildren() do
				if string.match(item.Name, "^%w+_%w+") then
					table.insert(itemsToMove, item)
				end
			end
		end
	end

	log("Found " .. #itemsToMove .. " items to move")

	-- Move items
	for _, item in ipairs(itemsToMove) do
		if templatesFolder:FindFirstChild(item.Name) then
			log("  SKIP: " .. item.Name .. " (already exists)")
			skippedCount = skippedCount + 1
		else
			item.Parent = templatesFolder
			log("  MOVED: " .. item.Name)
			movedCount = movedCount + 1
		end
	end

	-- Cleanup empty containers
	for _, container in game.Workspace:GetChildren() do
		if (container:IsA("Model") or container:IsA("Folder")) and #container:GetChildren() == 0 then
			container:Destroy()
		end
	end

	log("========================================")
	log("Moved: " .. movedCount .. ", Skipped: " .. skippedCount)
	if movedCount > 0 then
		log("SUCCESS! Save your place (Ctrl+S)")
	end
	log("========================================")
end

-- ==========================================
-- 3. DOWNLOAD & SCALE
-- ==========================================

local function scaleModelToSize(model, targetSize)
	local center, currentSize = getBoundingBox(model)

	if not center then
		return false, "No parts found"
	end

	local scaleX = targetSize.X / currentSize.X
	local scaleY = targetSize.Y / currentSize.Y
	local scaleZ = targetSize.Z / currentSize.Z

	log("  Current: " .. string.format("%.1fx%.1fx%.1f", currentSize.X, currentSize.Y, currentSize.Z))
	log("  Target: " .. string.format("%.1fx%.1fx%.1f", targetSize.X, targetSize.Y, targetSize.Z))
	log("  Scale: " .. string.format("X=%.2f Y=%.2f Z=%.2f", scaleX, scaleY, scaleZ))

	-- Scale all parts
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Size = Vector3.new(
				part.Size.X * scaleX,
				part.Size.Y * scaleY,
				part.Size.Z * scaleZ
			)
			local relPos = part.Position - center
			part.Position = Vector3.new(
				relPos.X * scaleX,
				relPos.Y * scaleY,
				relPos.Z * scaleZ
			)
		end
	end

	-- Move bottom to Y=0
	local _, newSize = getBoundingBox(model)
	local newCenter, _ = getBoundingBox(model)
	if newCenter then
		local bottomY = newCenter.Y - newSize.Y / 2
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Position = part.Position - Vector3.new(0, bottomY, 0)
			end
		end
	end

	return true
end

local function downloadAndScale()
	log("========================================")
	log("DOWNLOADING & SCALING CLOUD ASSETS...")
	log("========================================")

	local templatesFolder = getTemplatesFolder()
	local successCount = 0
	local failCount = 0

	for assetName, assetId in pairs(CLOUD_ASSETS) do
		local templateName = "Structures_" .. assetName
		log("")
		log("Processing: " .. assetName .. " (ID: " .. assetId .. ")")

		if templatesFolder:FindFirstChild(templateName) then
			log("  SKIP: Already exists (delete first to re-download)")
			successCount = successCount + 1
			continue
		end

		local success, result = pcall(function()
			return InsertService:LoadAsset(assetId)
		end)

		if not success then
			log("  FAILED: " .. tostring(result))
			failCount = failCount + 1
			continue
		end

		local assetModel = result
		local actualAsset = nil

		for _, child in assetModel:GetChildren() do
			if child:IsA("Model") or child:IsA("MeshPart") or child:IsA("BasePart") then
				actualAsset = child
				break
			end
		end

		if not actualAsset then
			log("  FAILED: No model found in asset")
			assetModel:Destroy()
			failCount = failCount + 1
			continue
		end

		-- Wrap in Model if needed
		local modelToScale
		if actualAsset:IsA("Model") then
			modelToScale = actualAsset
		else
			modelToScale = Instance.new("Model")
			modelToScale.Name = assetName
			actualAsset.Parent = modelToScale
			modelToScale.PrimaryPart = actualAsset
		end

		-- Scale to target
		local targetSize = TARGET_SIZES[assetName] or Vector3.new(20, 20, 20)
		local scaleSuccess = scaleModelToSize(modelToScale, targetSize)

		if not scaleSuccess then
			log("  FAILED: Could not scale")
			assetModel:Destroy()
			failCount = failCount + 1
			continue
		end

		-- Anchor all parts
		for _, part in modelToScale:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end

		-- Set PrimaryPart
		if not modelToScale.PrimaryPart then
			for _, part in modelToScale:GetDescendants() do
				if part:IsA("BasePart") then
					modelToScale.PrimaryPart = part
					break
				end
			end
		end

		-- Save
		modelToScale.Name = templateName
		modelToScale.Parent = templatesFolder
		assetModel:Destroy()

		log("  SUCCESS: Saved as " .. templateName)
		successCount = successCount + 1
	end

	log("")
	log("========================================")
	log("Success: " .. successCount .. ", Failed: " .. failCount)
	if successCount > 0 then
		log("SAVE YOUR PLACE (Ctrl+S) to persist!")
	end
	log("========================================")
end

-- ==========================================
-- 4. DIAGNOSE SPAWN
-- ==========================================

local function diagnoseSpawn()
	log("========================================")
	log("SPAWN AREA DIAGNOSTIC")
	log("========================================")

	local spawnPos = getSpawnPosition()
	log("SpawnLocation: " .. string.format("%.0f, %.0f, %.0f", spawnPos.X, spawnPos.Y, spawnPos.Z))

	local checkRadius = 100
	local nearbyItems = {}

	for _, item in game.Workspace:GetDescendants() do
		if item:IsA("BasePart") then
			local distance = (item.Position - spawnPos).Magnitude
			if distance < checkRadius then
				table.insert(nearbyItems, {
					name = item:GetFullName(),
					distance = distance,
					size = item.Size,
				})
			end
		end
	end

	table.sort(nearbyItems, function(a, b) return a.distance < b.distance end)

	log("Found " .. #nearbyItems .. " parts within " .. checkRadius .. " studs:")
	for i, item in ipairs(nearbyItems) do
		if i > 15 then
			log("  ... and " .. (#nearbyItems - 15) .. " more")
			break
		end
		log(string.format("  [%.1f] %s (%.0fx%.0fx%.0f)",
			item.distance, item.name, item.size.X, item.size.Y, item.size.Z))
	end

	local templates = ServerStorage:FindFirstChild("AssetTemplates")
	if templates then
		log("AssetTemplates: " .. #templates:GetChildren() .. " assets")
	else
		log("WARNING: No AssetTemplates folder!")
	end

	log("========================================")
end

-- ==========================================
-- 5. SPAWN STRUCTURE (Fault-Lite Showcase)
-- ==========================================

-- Widget for structure selection
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,  -- Initially disabled
	false,  -- Override previous state
	320,    -- Width
	550,    -- Height
	280,    -- Min width
	450     -- Min height
)

local spawnWidget = plugin:CreateDockWidgetPluginGui("SpawnStructureWidget", widgetInfo)
spawnWidget.Title = "Spawn Structure"

-- Create widget UI with ScrollingFrame for long content
local mainFrame = Instance.new("ScrollingFrame")
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
mainFrame.BorderSizePixel = 0
mainFrame.ScrollBarThickness = 8
mainFrame.CanvasSize = UDim2.new(0, 0, 0, 800)
mainFrame.Parent = spawnWidget

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 5)
layout.Parent = mainFrame

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundTransparency = 1
title.Text = "FAULT-LITE SHOWCASE v5"
title.TextColor3 = Color3.fromRGB(255, 200, 100)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.LayoutOrder = 0
title.Parent = mainFrame

-- Instructions
local instructions = Instance.new("TextLabel")
instructions.Size = UDim2.new(1, 0, 0, 50)
instructions.BackgroundTransparency = 1
instructions.Text = "1. Select spawn point\n2. Click structure to spawn TWO versions:\n   - ANCHORED (green) on ground\n   - DROPPED (orange) falls from above"
instructions.TextColor3 = Color3.fromRGB(180, 180, 180)
instructions.Font = Enum.Font.Gotham
instructions.TextSize = 11
instructions.TextWrapped = true
instructions.TextYAlignment = Enum.TextYAlignment.Top
instructions.LayoutOrder = 1
instructions.Parent = mainFrame

-- Divider 1
local divider1 = Instance.new("Frame")
divider1.Size = UDim2.new(1, 0, 0, 1)
divider1.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
divider1.BorderSizePixel = 0
divider1.LayoutOrder = 2
divider1.Parent = mainFrame

-- SPAWN POINT SECTION
local spawnLabel = Instance.new("TextLabel")
spawnLabel.Size = UDim2.new(1, 0, 0, 20)
spawnLabel.BackgroundTransparency = 1
spawnLabel.Text = "SPAWN POINT:"
spawnLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
spawnLabel.Font = Enum.Font.GothamBold
spawnLabel.TextSize = 12
spawnLabel.TextXAlignment = Enum.TextXAlignment.Left
spawnLabel.LayoutOrder = 3
spawnLabel.Parent = mainFrame

-- Current spawn point display
local currentSpawnLabel = Instance.new("TextLabel")
currentSpawnLabel.Size = UDim2.new(1, 0, 0, 18)
currentSpawnLabel.BackgroundTransparency = 1
currentSpawnLabel.Text = "Current: Spawn (0, 0)"
currentSpawnLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
currentSpawnLabel.Font = Enum.Font.Gotham
currentSpawnLabel.TextSize = 10
currentSpawnLabel.TextXAlignment = Enum.TextXAlignment.Left
currentSpawnLabel.LayoutOrder = 4
currentSpawnLabel.Parent = mainFrame

-- Spawn point buttons container
local spawnPointsFrame = Instance.new("Frame")
spawnPointsFrame.Size = UDim2.new(1, 0, 0, 110)
spawnPointsFrame.BackgroundTransparency = 1
spawnPointsFrame.LayoutOrder = 5
spawnPointsFrame.Parent = mainFrame

local spawnGrid = Instance.new("UIGridLayout")
spawnGrid.CellSize = UDim2.new(0.48, 0, 0, 24)
spawnGrid.CellPadding = UDim2.new(0.02, 0, 0, 4)
spawnGrid.SortOrder = Enum.SortOrder.LayoutOrder
spawnGrid.Parent = spawnPointsFrame

-- Track spawn point buttons for highlighting
local spawnPointButtons = {}

local function updateSpawnPointDisplay()
	currentSpawnLabel.Text = string.format("Current: %s (%.0f, %.0f) H=%.0f",
		selectedSpawnPoint.name,
		selectedSpawnPoint.x,
		selectedSpawnPoint.z,
		estimateTerrainHeight(selectedSpawnPoint.x, selectedSpawnPoint.z))

	-- Update button colors
	for _, btnData in ipairs(spawnPointButtons) do
		if btnData.point == selectedSpawnPoint then
			btnData.btn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
		else
			btnData.btn.BackgroundColor3 = Color3.fromRGB(50, 60, 50)
		end
	end
end

local function selectSpawnPoint(point)
	selectedSpawnPoint = point
	updateSpawnPointDisplay()

	-- Move SpawnLocation to this point (works in Edit mode)
	local spawnLocation = game.Workspace:FindFirstChild("SpawnLocation")
	if spawnLocation then
		local terrainY = estimateTerrainHeight(point.x, point.z)
		spawnLocation.Position = Vector3.new(point.x, terrainY + 3, point.z)
		log("Moved SpawnLocation to " .. point.name .. " at Y=" .. string.format("%.1f", terrainY + 3))
	end

	-- Fire ChangeSpawnPoint remote event if available (regenerates terrain during Play mode)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local changeSpawnEvent = remotes:FindFirstChild("ChangeSpawnPoint")
		if changeSpawnEvent and changeSpawnEvent:IsA("RemoteEvent") then
			-- Get local player to fire the event
			local Players = game:GetService("Players")
			local localPlayer = Players.LocalPlayer
			if localPlayer then
				changeSpawnEvent:FireServer(point.name)
				log("Fired ChangeSpawnPoint event for terrain regeneration")
			end
		end
	end
end

-- Create spawn point buttons
for i, point in ipairs(SPAWN_POINTS) do
	local btn = Instance.new("TextButton")
	btn.Name = point.name
	btn.Size = UDim2.new(0.48, 0, 0, 24)
	btn.BackgroundColor3 = (i == 1) and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(50, 60, 50)
	btn.Text = point.name
	btn.TextColor3 = Color3.fromRGB(220, 220, 220)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 11
	btn.LayoutOrder = i
	btn.Parent = spawnPointsFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 3)
	btnCorner.Parent = btn

	table.insert(spawnPointButtons, { btn = btn, point = point })

	btn.MouseButton1Click:Connect(function()
		selectSpawnPoint(point)
	end)
end

-- Divider 2
local divider2 = Instance.new("Frame")
divider2.Size = UDim2.new(1, 0, 0, 1)
divider2.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
divider2.BorderSizePixel = 0
divider2.LayoutOrder = 6
divider2.Parent = mainFrame

-- STRUCTURES SECTION
local structLabel = Instance.new("TextLabel")
structLabel.Size = UDim2.new(1, 0, 0, 20)
structLabel.BackgroundTransparency = 1
structLabel.Text = "STRUCTURES:"
structLabel.TextColor3 = Color3.fromRGB(120, 180, 255)
structLabel.Font = Enum.Font.GothamBold
structLabel.TextSize = 12
structLabel.TextXAlignment = Enum.TextXAlignment.Left
structLabel.LayoutOrder = 7
structLabel.Parent = mainFrame

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 18)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready to spawn"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.LayoutOrder = 8
statusLabel.Parent = mainFrame

-- Current structures folder
local showcaseFolder = nil

local function clearShowcaseStructures()
	if showcaseFolder and showcaseFolder.Parent then
		showcaseFolder:Destroy()
	end
	showcaseFolder = nil

	-- Also clear any stray ShowcaseStructure models
	for _, child in game.Workspace:GetChildren() do
		if string.match(child.Name, "^Showcase") then
			child:Destroy()
		end
	end
end

local function loadAssetModel(assetName)
	local assetId = CLOUD_ASSETS[assetName]
	if not assetId then
		return nil, "Unknown asset"
	end

	log("  Loading asset ID: " .. tostring(assetId))

	local success, result = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)

	if not success then
		log("  FAILED to load: " .. tostring(result))
		return nil, tostring(result)
	end

	local assetContainer = result
	log("  Asset container: " .. assetContainer.ClassName .. " with " .. #assetContainer:GetChildren() .. " children")

	-- Log all children for debugging
	for _, child in assetContainer:GetChildren() do
		log("    Child: " .. child.Name .. " (" .. child.ClassName .. ")")
	end

	local model = nil

	for _, child in assetContainer:GetChildren() do
		if child:IsA("Model") or child:IsA("MeshPart") or child:IsA("BasePart") then
			model = child
			break
		end
	end

	if not model then
		assetContainer:Destroy()
		return nil, "No model in asset (container had " .. #assetContainer:GetChildren() .. " children)"
	end

	-- Wrap if needed
	if not model:IsA("Model") then
		local wrapper = Instance.new("Model")
		wrapper.Name = assetName
		model.Parent = wrapper
		wrapper.PrimaryPart = model
		model = wrapper
	end

	-- Set primary part if needed
	if not model.PrimaryPart then
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				model.PrimaryPart = part
				break
			end
		end
	end

	assetContainer:Destroy()
	return model, nil
end

local function spawnDualStructures(assetName)
	ChangeHistoryService:SetWaypoint("Before Spawn Dual Structures")

	-- Check if we're in Play mode - use remote events instead
	if isPlayMode() then
		log("PLAY MODE: Using remote events for spawn")
		statusLabel.Text = "Spawning via server..."

		-- Find the SpawnStructure remote event
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		if remotes then
			local spawnEvent = remotes:FindFirstChild("SpawnStructure")
			if spawnEvent and spawnEvent:IsA("RemoteEvent") then
				-- Fire server to spawn the structure at selected spawn point
				spawnEvent:FireServer(assetName, selectedSpawnPoint.name)
				statusLabel.Text = assetName .. " spawned (via server)"
				log("Fired SpawnStructure event: " .. assetName .. " at " .. selectedSpawnPoint.name)
			else
				statusLabel.Text = "ERROR: No SpawnStructure remote"
				log("ERROR: SpawnStructure remote event not found")
			end
		else
			statusLabel.Text = "ERROR: No Remotes folder"
			log("ERROR: Remotes folder not found - is Fault-Lite running?")
		end
		return
	end

	-- EDIT MODE: Use InsertService directly (works in Edit mode)
	log("EDIT MODE: Using InsertService directly")

	-- Clear previous
	clearShowcaseStructures()

	statusLabel.Text = "Loading " .. assetName .. "..."
	log("Spawning dual structures: " .. assetName .. " at " .. selectedSpawnPoint.name)

	-- Create folder for this spawn
	showcaseFolder = Instance.new("Folder")
	showcaseFolder.Name = "ShowcaseStructures"
	showcaseFolder.Parent = game.Workspace

	-- Calculate positions
	local spawnX = selectedSpawnPoint.x
	local spawnZ = selectedSpawnPoint.z
	local terrainY = estimateTerrainHeight(spawnX, spawnZ)

	-- Structure positions: one left, one right, both in front of spawn
	local forwardOffset = 60
	local leftX = spawnX - STRUCTURE_SPACING / 2
	local rightX = spawnX + STRUCTURE_SPACING / 2
	local structZ = spawnZ + forwardOffset

	-- Load ANCHORED model
	local anchoredModel, err1 = loadAssetModel(assetName)
	if not anchoredModel then
		statusLabel.Text = "ERROR: " .. (err1 or "Unknown")
		log("  ERROR loading anchored: " .. (err1 or "Unknown"))
		return
	end

	anchoredModel.Name = assetName .. "_Anchored"

	-- Anchor all parts
	for _, part in anchoredModel:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			-- Tint green for anchored
			part.Color = part.Color:Lerp(Color3.fromRGB(100, 200, 100), 0.2)
		end
	end

	-- Place anchored on ground (left side)
	local anchoredTerrainY = estimateTerrainHeight(leftX, structZ)
	local bottomOffset = getModelBottomOffset(anchoredModel)
	local anchoredY = anchoredTerrainY + bottomOffset
	anchoredModel:PivotTo(CFrame.new(leftX, anchoredY, structZ))
	anchoredModel.Parent = showcaseFolder

	-- Load DROPPED model
	local droppedModel, err2 = loadAssetModel(assetName)
	if not droppedModel then
		statusLabel.Text = "ERROR: " .. (err2 or "Unknown")
		log("  ERROR loading dropped: " .. (err2 or "Unknown"))
		return
	end

	droppedModel.Name = assetName .. "_Dropped"

	-- Unanchor all parts for drop
	for _, part in droppedModel:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			-- Tint orange for dropped
			part.Color = part.Color:Lerp(Color3.fromRGB(255, 180, 100), 0.2)
		end
	end

	-- Place dropped above ground (right side)
	local droppedTerrainY = estimateTerrainHeight(rightX, structZ)
	local droppedBottomOffset = getModelBottomOffset(droppedModel)
	local droppedY = droppedTerrainY + droppedBottomOffset + DROP_HEIGHT
	droppedModel:PivotTo(CFrame.new(rightX, droppedY, structZ))
	droppedModel.Parent = showcaseFolder

	-- Select both
	Selection:Set({anchoredModel, droppedModel})

	local modelHeight = getModelHeight(anchoredModel)
	statusLabel.Text = string.format("%s spawned (H=%.0f)", assetName, modelHeight)

	log(string.format("  ANCHORED: (%.0f, %.0f, %.0f) - on ground", leftX, anchoredY, structZ))
	log(string.format("  DROPPED: (%.0f, %.0f, %.0f) - will fall", rightX, droppedY, structZ))
	log(string.format("  Terrain at spawn: %.0f", terrainY))

	ChangeHistoryService:SetWaypoint("After Spawn Dual Structures")
end

-- Create structure buttons
for i, assetName in ipairs(STRUCTURE_LIST) do
	local btn = Instance.new("TextButton")
	btn.Name = assetName
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
	btn.Text = assetName
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.LayoutOrder = 10 + i
	btn.Parent = mainFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		spawnDualStructures(assetName)
	end)

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
	end)

	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
	end)
end

-- Clear button
local clearShowcaseBtn = Instance.new("TextButton")
clearShowcaseBtn.Size = UDim2.new(1, 0, 0, 32)
clearShowcaseBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
clearShowcaseBtn.Text = "Clear All Structures"
clearShowcaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearShowcaseBtn.Font = Enum.Font.GothamBold
clearShowcaseBtn.TextSize = 14
clearShowcaseBtn.LayoutOrder = 50
clearShowcaseBtn.Parent = mainFrame

local clearCorner = Instance.new("UICorner")
clearCorner.CornerRadius = UDim.new(0, 4)
clearCorner.Parent = clearShowcaseBtn

clearShowcaseBtn.MouseButton1Click:Connect(function()
	clearShowcaseStructures()
	statusLabel.Text = "Cleared"
	log("Cleared showcase structures")
end)

-- ==========================================
-- EARTHQUAKE SECTION
-- ==========================================

-- Divider 3
local divider3 = Instance.new("Frame")
divider3.Size = UDim2.new(1, 0, 0, 1)
divider3.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
divider3.BorderSizePixel = 0
divider3.LayoutOrder = 60
divider3.Parent = mainFrame

-- Earthquake section label
local earthquakeLabel = Instance.new("TextLabel")
earthquakeLabel.Size = UDim2.new(1, 0, 0, 20)
earthquakeLabel.BackgroundTransparency = 1
earthquakeLabel.Text = "EARTHQUAKES:"
earthquakeLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
earthquakeLabel.Font = Enum.Font.GothamBold
earthquakeLabel.TextSize = 12
earthquakeLabel.TextXAlignment = Enum.TextXAlignment.Left
earthquakeLabel.LayoutOrder = 61
earthquakeLabel.Parent = mainFrame

-- Earthquake trigger function
local function triggerEarthquake(earthquakeType)
	-- Only works in Play mode
	if not isPlayMode() then
		statusLabel.Text = "ERROR: Start Play mode first!"
		log("ERROR: Earthquakes only work in Play mode")
		return
	end

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local triggerEvent = remotes:FindFirstChild("TriggerEarthquake")
		if triggerEvent and triggerEvent:IsA("RemoteEvent") then
			triggerEvent:FireServer(earthquakeType)
			statusLabel.Text = earthquakeType .. " earthquake triggered!"
			log("Triggered " .. earthquakeType .. " earthquake")
		else
			statusLabel.Text = "ERROR: No TriggerEarthquake remote"
			log("ERROR: TriggerEarthquake remote event not found")
		end
	else
		statusLabel.Text = "ERROR: No Remotes folder"
		log("ERROR: Remotes folder not found - is Fault-Lite running?")
	end
end

-- Earthquake buttons
local earthquakeTypes = {
	{ name = "MINOR", color = Color3.fromRGB(80, 120, 80), description = "Small tremor (3s)" },
	{ name = "MODERATE", color = Color3.fromRGB(180, 140, 60), description = "Moderate shake (8s)" },
	{ name = "MAJOR", color = Color3.fromRGB(180, 60, 60), description = "The Big One! (15s)" },
}

for i, quake in ipairs(earthquakeTypes) do
	local btn = Instance.new("TextButton")
	btn.Name = "Earthquake_" .. quake.name
	btn.Size = UDim2.new(1, 0, 0, 28)
	btn.BackgroundColor3 = quake.color
	btn.Text = quake.name .. " - " .. quake.description
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.LayoutOrder = 62 + i
	btn.Parent = mainFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		triggerEarthquake(quake.name)
	end)
end

-- Toggle widget
local function toggleWidget()
	spawnWidget.Enabled = not spawnWidget.Enabled
end

-- Auto-size canvas
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	mainFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
end)

-- ==========================================
-- CONNECT BUTTONS
-- ==========================================

clearButton.Click:Connect(clearAllAssets)
moveButton.Click:Connect(moveToStorage)
scaleButton.Click:Connect(downloadAndScale)
diagnoseButton.Click:Connect(diagnoseSpawn)
spawnButton.Click:Connect(toggleWidget)

log("========================================")
log("Faultline Fear Tools v" .. PLUGIN_VERSION .. " loaded!")
log("Buttons: Clear ALL | Move to Storage | Download & Scale | Diagnose | Spawn Structure")
log("========================================")
