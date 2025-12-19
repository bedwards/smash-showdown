--[[
	Extract Models from Place File

	Reads a Roblox place file (.rbxl) and extracts models from
	ServerStorage.AssetTemplates as individual .rbxm files.

	Usage:
		lune run tools/extract-models-from-place.luau [place-file]

	Default place file: faultline-fear-with-assets.rbxl

	Output: .rbxm files in assets/faultline-fear/rbxm/

	Workflow:
		1. In Studio: File → Import 3D → combined_all_assets.fbx
		2. Click "Move to Storage" plugin
		3. File → Save to File As → faultline-fear-with-assets.rbxl
		4. Run this script: lune run tools/extract-models-from-place.luau
		5. Run: lune run tools/update-asset-paths.luau
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

print("╔════════════════════════════════════════════════════════╗")
print("║         EXTRACT MODELS FROM PLACE FILE                 ║")
print("╚════════════════════════════════════════════════════════╝")
print("")

-- Configuration
local PLACE_FILE = process.args[1] or "faultline-fear-with-assets.rbxl"
local OUTPUT_DIR = "assets/faultline-fear/rbxm"

-- Check if place file exists
if not fs.isFile(PLACE_FILE) then
	print(string.format("[ERROR] Place file not found: %s", PLACE_FILE))
	print("")
	print("To create the place file:")
	print("  1. Open Roblox Studio")
	print("  2. File → Import 3D → assets/faultline-fear/meshes/combined_all_assets.fbx")
	print("  3. Click 'Move to Storage' plugin button")
	print("  4. File → Save to File As → faultline-fear-with-assets.rbxl")
	print("  5. Re-run this script")
	print("")
	process.exit(1)
end

print(string.format("[INFO] Reading place file: %s", PLACE_FILE))

-- Read the place file
local placeData = fs.readFile(PLACE_FILE)
local game = roblox.deserializePlace(placeData)

print("[OK] Place file loaded")

-- Find ServerStorage
local serverStorage = game:FindFirstChild("ServerStorage")
if not serverStorage then
	print("[ERROR] ServerStorage not found in place file")
	process.exit(1)
end

-- Find AssetTemplates folder
local assetTemplates = serverStorage:FindFirstChild("AssetTemplates")
if not assetTemplates then
	print("[ERROR] ServerStorage.AssetTemplates not found")
	print("")
	print("Make sure you:")
	print("  1. Imported the FBX file")
	print("  2. Clicked 'Move to Storage' plugin")
	print("  3. Saved the place file")
	print("")
	process.exit(1)
end

-- Create output directory
if not fs.isDir(OUTPUT_DIR) then
	fs.writeDir(OUTPUT_DIR)
	print(string.format("[OK] Created output directory: %s", OUTPUT_DIR))
end

-- Extract each model
local extractedCount = 0
local skippedCount = 0

print("")
print("[EXTRACTING MODELS]")

for _, child in assetTemplates:GetChildren() do
	if child:IsA("Model") or child:IsA("MeshPart") or child:IsA("Part") then
		local modelName = child.Name
		local outputPath = string.format("%s/%s.rbxm", OUTPUT_DIR, modelName)

		-- Check if model has any MeshParts (skip empty models)
		local hasMesh = child:IsA("MeshPart")
		if not hasMesh then
			for _, desc in child:GetDescendants() do
				if desc:IsA("MeshPart") then
					hasMesh = true
					break
				end
			end
		end

		if not hasMesh then
			print(string.format("  [SKIP] %s (no MeshParts)", modelName))
			skippedCount += 1
			continue
		end

		-- Serialize and write
		local modelData = roblox.serializeModel({ child })
		fs.writeFile(outputPath, modelData)

		-- Count parts for info
		local partCount = 0
		if child:IsA("BasePart") then
			partCount = 1
		else
			for _, desc in child:GetDescendants() do
				if desc:IsA("BasePart") then
					partCount += 1
				end
			end
		end

		print(string.format("  [OK] %s (%d parts) → %s", modelName, partCount, outputPath))
		extractedCount += 1
	end
end

print("")
print(string.rep("─", 60))
print(string.format("Extracted: %d models, Skipped: %d", extractedCount, skippedCount))
print("")

if extractedCount > 0 then
	print("[SUCCESS] Models extracted!")
	print("")
	print("Next step:")
	print("  lune run tools/update-asset-paths.luau")
	print("")
	print("This will update faultline-fear.project.json to reference the .rbxm files.")
else
	print("[WARN] No models were extracted.")
	print("")
	print("Check that:")
	print("  1. You imported the FBX in Studio")
	print("  2. You clicked 'Move to Storage' plugin")
	print("  3. Models are in ServerStorage.AssetTemplates")
	print("  4. You saved the place file")
end
