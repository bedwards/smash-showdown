--[[
	Faultline Fear: Asset Organizer Plugin
	Version: 2.0.1 - December 2024

	WHAT THIS DOES:
	1. "Clear Assets" - Removes ALL imported assets from everywhere:
	   - Workspace (freshly imported meshes)
	   - ReplicatedStorage.Assets (old organize location)
	   - ServerStorage.AssetTemplates (new storage location)

	After clearing, use:
	- File → Import 3D → combined_all_assets.fbx
	- Then use "Move to Storage" plugin to move assets to ServerStorage.AssetTemplates

	INSTALLATION:
	1. Copy this file to your Roblox Plugins folder:
	   - Windows: %LOCALAPPDATA%\Roblox\Plugins\
	   - Mac: ~/Documents/Roblox/Plugins/
	2. Delete plugin cache: ~/Library/Roblox/PluginStorage/ (Mac)
	3. Restart Roblox Studio
	4. Look for "Faultline Fear" toolbar

	WORKFLOW:
	1. Click "Clear Assets" (removes ALL old imports)
	2. File → Import 3D → combined_all_assets.fbx
	3. Use "Move to Storage" plugin (separate plugin)
	4. Save the place!
]]

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create toolbar and button
local toolbar = plugin:CreateToolbar("Faultline Fear")
local clearButton = toolbar:CreateButton(
	"Clear ALL Assets",
	"Delete ALL imported assets from Workspace, ReplicatedStorage, and ServerStorage",
	"rbxassetid://6031075931" -- Trash icon
)

-- ==========================================
-- CLEAR FUNCTION
-- ==========================================

local function clearAssets()
	ChangeHistoryService:SetWaypoint("Before Clear Assets")

	local workspaceCount = 0
	local replicatedCount = 0
	local serverCount = 0

	-- 1. Clear from Workspace (freshly imported meshes)
	for _, obj in game.Workspace:GetChildren() do
		-- Match Category_AssetName pattern
		if string.match(obj.Name, "^%w+_%w+") then
			local skipNames = {
				Camera = true,
				Terrain = true,
				SpawnLocation = true,
			}
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

	-- Also check inside container models
	for _, container in game.Workspace:GetChildren() do
		if container:IsA("Model") or container:IsA("Folder") then
			local cleared = false
			for _, item in container:GetChildren() do
				if string.match(item.Name, "^%w+_%w+") then
					item:Destroy()
					workspaceCount = workspaceCount + 1
					cleared = true
				end
			end
			if cleared and #container:GetChildren() == 0 then
				container:Destroy()
			end
		end
	end

	-- 2. Clear from ReplicatedStorage.Assets (old organize location)
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
		print("[FF_AssetOrganizer] Cleared ReplicatedStorage.Assets")
	end

	-- 3. Clear from ServerStorage.AssetTemplates (new storage location)
	local templatesFolder = ServerStorage:FindFirstChild("AssetTemplates")
	if templatesFolder then
		for _, asset in templatesFolder:GetChildren() do
			asset:Destroy()
			serverCount = serverCount + 1
		end
		print("[FF_AssetOrganizer] Cleared ServerStorage.AssetTemplates")
	end

	ChangeHistoryService:SetWaypoint("After Clear Assets")

	print("========================================")
	print("[FF_AssetOrganizer] CLEARED EVERYTHING")
	print("  Workspace:", workspaceCount)
	print("  ReplicatedStorage.Assets:", replicatedCount)
	print("  ServerStorage.AssetTemplates:", serverCount)
	print("  TOTAL:", workspaceCount + replicatedCount + serverCount)
	print("========================================")
	print("Next steps:")
	print("  1. File → Import 3D → combined_all_assets.fbx")
	print("  2. Click 'Move to Storage' (other plugin)")
	print("  3. Save the place!")
end

-- ==========================================
-- BUTTON HANDLER
-- ==========================================

clearButton.Click:Connect(function()
	print("[FF_AssetOrganizer] Clearing ALL assets from all locations...")
	clearAssets()
end)

print("[FF_AssetOrganizer] Plugin v2.0.1 loaded!")
print("[FF_AssetOrganizer] Click 'Clear ALL Assets' before importing new FBX")
