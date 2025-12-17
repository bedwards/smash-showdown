--[[
	Faultline Fear: Move Imports to Storage
	Version: 1.0.0 - December 2025

	Moves Category_AssetName MeshParts from Workspace to ServerStorage.AssetTemplates
	Run this ONCE after importing combined_all_assets.fbx via File > Import 3D
]]

local PLUGIN_ID = "FF_MoveToStorage_v5"
local TOOLBAR_NAME = "Faultline Import Tools"
local BUTTON_NAME = "Move to Storage"
local BUTTON_TOOLTIP = "Move imported FBX assets from Workspace to ServerStorage.AssetTemplates"

local toolbar = plugin:CreateToolbar(TOOLBAR_NAME)
local moveButton = toolbar:CreateButton(
	BUTTON_NAME,
	BUTTON_TOOLTIP,
	"rbxassetid://6031075938"
)

local diagnoseButton = toolbar:CreateButton(
	"Diagnose Spawn",
	"Show what's near spawn point (0,0,0)",
	"rbxassetid://6031075929"
)

local function log(msg)
	print(string.format("[%s] %s", PLUGIN_ID, msg))
end

local function moveImportsToStorage()
	log("========================================")
	log("Starting asset migration...")
	log("========================================")

	local ServerStorage = game:GetService("ServerStorage")

	-- Create AssetTemplates folder if needed
	local templatesFolder = ServerStorage:FindFirstChild("AssetTemplates")
	if not templatesFolder then
		templatesFolder = Instance.new("Folder")
		templatesFolder.Name = "AssetTemplates"
		templatesFolder.Parent = ServerStorage
		log("Created ServerStorage.AssetTemplates folder")
	else
		log("Found existing ServerStorage.AssetTemplates folder")
	end

	-- Find all Category_AssetName items in Workspace
	local movedCount = 0
	local skippedCount = 0
	local itemsToMove = {}

	-- Collect items first (don't modify while iterating)
	for _, item in game.Workspace:GetChildren() do
		-- Match Category_AssetName pattern (word_word or word_word_word etc)
		if string.match(item.Name, "^%w+_%w+") then
			-- Skip system objects
			local skipNames = {
				Camera = true,
				Terrain = true,
				SpawnLocation = true,
			}
			if not skipNames[item.Name] then
				table.insert(itemsToMove, item)
			end
		end
	end

	-- Also check inside any container models (FBX import sometimes creates a parent model)
	for _, container in game.Workspace:GetChildren() do
		if container:IsA("Model") or container:IsA("Folder") then
			for _, item in container:GetChildren() do
				if string.match(item.Name, "^%w+_%w+") then
					table.insert(itemsToMove, item)
				end
			end
		end
	end

	log(string.format("Found %d items matching Category_AssetName pattern", #itemsToMove))

	-- Move items
	for _, item in itemsToMove do
		-- Check if already exists in destination
		if templatesFolder:FindFirstChild(item.Name) then
			log(string.format("  SKIP: %s (already exists in AssetTemplates)", item.Name))
			skippedCount += 1
		else
			local oldParent = item.Parent.Name
			item.Parent = templatesFolder
			log(string.format("  MOVED: %s (from %s)", item.Name, oldParent))
			movedCount += 1
		end
	end

	-- Clean up empty containers left behind
	for _, container in game.Workspace:GetChildren() do
		if (container:IsA("Model") or container:IsA("Folder")) and #container:GetChildren() == 0 then
			local name = container.Name
			-- Don't delete important folders
			if name ~= "Animals" and name ~= "Creatures" and name ~= "Structures" then
				container:Destroy()
				log(string.format("  CLEANUP: Removed empty container '%s'", name))
			end
		end
	end

	log("========================================")
	log(string.format("Migration complete!"))
	log(string.format("  Moved: %d assets", movedCount))
	log(string.format("  Skipped: %d (already existed)", skippedCount))
	log(string.format("  Location: ServerStorage.AssetTemplates"))
	log("========================================")

	if movedCount > 0 then
		log("SUCCESS! Now save your place (Ctrl+S) and play!")
	elseif skippedCount > 0 then
		log("All assets were already in place. Ready to play!")
	else
		log("No Category_AssetName assets found in Workspace.")
		log("Did you run File > Import 3D with combined_all_assets.fbx?")
	end
end

moveButton.Click:Connect(moveImportsToStorage)

local function diagnoseSpawn()
	log("========================================")
	log("SPAWN AREA DIAGNOSTIC")
	log("========================================")

	-- Find the LOCAL PLAYER's actual position first
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer
	if localPlayer and localPlayer.Character then
		local root = localPlayer.Character:FindFirstChild("HumanoidRootPart")
		if root then
			log(string.format("PLAYER POSITION: %.1f, %.1f, %.1f", root.Position.X, root.Position.Y, root.Position.Z))
		else
			log("Player has no HumanoidRootPart")
		end
	else
		log("No local player character found")
	end

	-- Find actual SpawnLocation
	local spawnLocation = game.Workspace:FindFirstChild("SpawnLocation")
	local spawnPos
	if spawnLocation then
		spawnPos = spawnLocation.Position
		log(string.format("SpawnLocation found at: %.1f, %.1f, %.1f", spawnPos.X, spawnPos.Y, spawnPos.Z))
	else
		spawnPos = Vector3.new(0, 50, 0)
		log("WARNING: No SpawnLocation in Workspace (streaming or missing)")
	end

	-- Check terrain at PLAYER's actual position
	local checkPos = spawnPos
	if localPlayer and localPlayer.Character then
		local root = localPlayer.Character:FindFirstChild("HumanoidRootPart")
		if root then
			checkPos = root.Position
		end
	end

	local terrain = game.Workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		-- Cast a ray down from above player to find terrain surface
		local rayOrigin = Vector3.new(checkPos.X, 500, checkPos.Z)
		local rayDirection = Vector3.new(0, -1000, 0)

		local result = game.Workspace:Raycast(rayOrigin, rayDirection)
		if result then
			local hitName = result.Instance and result.Instance.Name or "unknown"
			log(string.format("Raycast hit: %s at Y = %.1f", hitName, result.Position.Y))
			log(string.format("Player Y: %.1f", checkPos.Y))
			local diff = checkPos.Y - result.Position.Y
			if diff < -1 then
				log(string.format("!!! PLAYER IS %.1f STUDS BELOW SURFACE !!!", -diff))
			elseif diff < 3 then
				log(string.format("Player is %.1f studs above surface", diff))
			else
				log(string.format("Player is %.1f studs above surface (OK)", diff))
			end
		else
			log("Raycast found nothing at player position")
		end
	else
		log("No terrain found in Workspace")
	end

	local checkRadius = 50

	log(string.format("Checking within %d studs of spawn (%.0f, %.0f, %.0f)",
		checkRadius, spawnPos.X, spawnPos.Y, spawnPos.Z))

	local nearbyItems = {}

	-- Check all Workspace children
	for _, item in game.Workspace:GetDescendants() do
		if item:IsA("BasePart") then
			local distance = (item.Position - spawnPos).Magnitude
			if distance < checkRadius then
				table.insert(nearbyItems, {
					name = item:GetFullName(),
					distance = distance,
					size = item.Size,
					position = item.Position,
					canCollide = item.CanCollide,
					transparency = item.Transparency,
				})
			end
		end
	end

	-- Sort by distance
	table.sort(nearbyItems, function(a, b) return a.distance < b.distance end)

	log(string.format("Found %d parts within %d studs:", #nearbyItems, checkRadius))

	for i, item in nearbyItems do
		if i > 20 then
			log(string.format("  ... and %d more", #nearbyItems - 20))
			break
		end
		local collision = item.canCollide and "SOLID" or "pass-through"
		log(string.format("  [%.1f studs] %s", item.distance, item.name))
		log(string.format("      Size: %.1f x %.1f x %.1f, %s, Transparency: %.1f",
			item.size.X, item.size.Y, item.size.Z, collision, item.transparency))
	end

	-- Check specifically for imported assets in Workspace
	local importedAssets = {}
	for _, item in game.Workspace:GetChildren() do
		if string.match(item.Name, "^%w+_%w+") then
			table.insert(importedAssets, item.Name)
		end
	end

	if #importedAssets > 0 then
		log("")
		log("WARNING: Found imported assets still in Workspace!")
		log("Run 'Move to Storage' to fix this:")
		for _, name in importedAssets do
			log("  - " .. name)
		end
	else
		log("")
		log("No imported assets found in Workspace root (good!)")
	end

	-- Check ServerStorage.AssetTemplates
	local ServerStorage = game:GetService("ServerStorage")
	local templates = ServerStorage:FindFirstChild("AssetTemplates")
	if templates then
		local count = #templates:GetChildren()
		log(string.format("ServerStorage.AssetTemplates has %d assets", count))
	else
		log("WARNING: ServerStorage.AssetTemplates folder doesn't exist!")
	end

	log("========================================")
end

diagnoseButton.Click:Connect(diagnoseSpawn)

log("========================================")
log("Plugin loaded!")
log("Click '" .. BUTTON_NAME .. "' in '" .. TOOLBAR_NAME .. "' toolbar")
log("Or click 'Diagnose Spawn' to see what's near spawn point")
log("========================================")
