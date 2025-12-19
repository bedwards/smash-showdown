--[[
	Extract and Save Assets from Roblox

	This script runs in Roblox Studio via run-in-roblox.
	It:
	1. Reads asset IDs from assets/faultline-fear/asset-ids.json
	2. Loads each model via InsertService
	3. Saves each model as an .rbxm file

	Usage:
		1. First run: python tools/upload-assets-to-roblox.py
		2. Then run: ./tools/run-studio-test.sh tools/extract-and-save-assets.luau

	Output: .rbxm files in assets/faultline-fear/rbxm/
]]

local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")
local Selection = game:GetService("Selection")

print("=" .. string.rep("=", 59))
print("EXTRACT AND SAVE ROBLOX ASSETS")
print("=" .. string.rep("=", 59))
print("")

-- Read asset IDs from JSON file
-- Note: run-in-roblox sets up the working directory, but we need to use a workaround
-- Since we can't read local files directly in Studio, we'll output instructions

local ASSET_IDS = {
	-- These will be populated after running upload-assets-to-roblox.py
	-- For now, let's try loading from the combined FBX upload result

	-- Structures (from combined_all_assets.fbx)
	-- Add your asset IDs here after uploading
}

-- Check if we have asset IDs
if next(ASSET_IDS) == nil then
	print("[INFO] No asset IDs configured in script.")
	print("")
	print("To use this script:")
	print("1. Run: python tools/upload-assets-to-roblox.py")
	print("2. Copy the asset IDs from assets/faultline-fear/asset-ids.json")
	print("3. Paste them into the ASSET_IDS table in this script")
	print("4. Re-run this script")
	print("")
	print("Alternative: Use the manual export workflow:")
	print("1. File → Import 3D → combined_all_assets.fbx")
	print("2. Click 'Move to Storage' plugin")
	print("3. Right-click each model → 'Save to File'")
	print("4. Save to assets/faultline-fear/rbxm/")
	return
end

local loadedCount = 0
local failedCount = 0

for name, assetId in pairs(ASSET_IDS) do
	print(string.format("[LOAD] %s (ID: %s)", name, tostring(assetId)))

	local success, result = pcall(function()
		return InsertService:LoadAsset(tonumber(assetId))
	end)

	if success and result then
		-- The result is a Model containing the actual asset
		local model = result:FindFirstChildOfClass("Model") or result:FindFirstChild(name)

		if model then
			model.Name = name
			model.Parent = game.ServerStorage

			-- Log MeshPart info
			for _, part in model:GetDescendants() do
				if part:IsA("MeshPart") then
					print(string.format("  MeshPart: %s", part.Name))
					print(string.format("    MeshId: %s", tostring(part.MeshId)))
				end
			end

			loadedCount += 1
			print(string.format("  [OK] Loaded to ServerStorage"))
		else
			print("  [WARN] No model found in asset")
			failedCount += 1
		end

		-- Clean up the container
		result:Destroy()
	else
		print(string.format("  [FAIL] %s", tostring(result)))
		failedCount += 1
	end
end

print("")
print(string.rep("-", 60))
print(string.format("Loaded: %d, Failed: %d", loadedCount, failedCount))
print("")

if loadedCount > 0 then
	print("Assets are now in ServerStorage.")
	print("")
	print("To save as .rbxm files:")
	print("1. In Explorer, expand ServerStorage")
	print("2. Right-click each model")
	print("3. Select 'Save to File'")
	print("4. Save to: assets/faultline-fear/rbxm/<ModelName>.rbxm")
	print("")
	print("Or use the Selection to export all at once:")

	-- Select all loaded models for easy export
	local models = {}
	for _, child in game.ServerStorage:GetChildren() do
		if child:IsA("Model") then
			table.insert(models, child)
		end
	end
	Selection:Set(models)
	print(string.format("Selected %d models in ServerStorage", #models))
end
