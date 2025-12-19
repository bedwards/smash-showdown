--[[
	Verify Assets

	Checks that all expected .rbxm asset files are present.
	Compares against the structures defined in code.

	Usage: lune run tools/verify-assets.luau
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local RBXM_FOLDER = "assets/faultline-fear/rbxm"

print("╔════════════════════════════════════════════════╗")
print("║           VERIFY RBXM ASSETS                   ║")
print("╚════════════════════════════════════════════════╝")
print("")

-- Expected structures (must match StructureSpawner and BuildingService)
local EXPECTED_STRUCTURES = {
	"Structures_FerrisWheel",
	"Structures_Lighthouse",
	"Structures_WaterTower",
	"Structures_Bridge",
	"Structures_RadioTower",
}

-- Expected buildings (from BuildingService)
local EXPECTED_BUILDINGS = {
	"Buildings_Resort",
	"Buildings_ModernHouse",
	"Buildings_RanchHouse",
	"Buildings_SpanishHouse",
	"Buildings_BeachShack",
	"Buildings_Warehouse",
}

-- Check if rbxm folder exists
if not fs.isDir(RBXM_FOLDER) then
	print("[ERROR] RBXM folder not found: " .. RBXM_FOLDER)
	print("")
	print("To create:")
	print("  mkdir -p " .. RBXM_FOLDER)
	print("")
	process.exit(1)
end

-- Get existing files
local existingFiles: { [string]: boolean } = {}
for _, entry in fs.readDir(RBXM_FOLDER) do
	if string.match(entry, "%.rbxm[x]?$") then
		local assetName = string.gsub(entry, "%.rbxm[x]?$", "")
		existingFiles[assetName] = true
	end
end

-- Check structures
print("[Structures]")
local missingStructures = 0
for _, name in EXPECTED_STRUCTURES do
	if existingFiles[name] then
		print(string.format("  [OK] %s", name))
	else
		print(string.format("  [MISSING] %s", name))
		missingStructures += 1
	end
end
print("")

-- Check buildings
print("[Buildings]")
local missingBuildings = 0
for _, name in EXPECTED_BUILDINGS do
	if existingFiles[name] then
		print(string.format("  [OK] %s", name))
	else
		print(string.format("  [MISSING] %s", name))
		missingBuildings += 1
	end
end
print("")

-- Summary
local totalMissing = missingStructures + missingBuildings
local totalExpected = #EXPECTED_STRUCTURES + #EXPECTED_BUILDINGS

print("────────────────────────────────────────────────")
if totalMissing == 0 then
	print(string.format("[OK] All %d expected assets found!", totalExpected))
else
	print(string.format("[WARN] Missing %d of %d expected assets", totalMissing, totalExpected))
	print("")
	print("To export missing assets:")
	print("  1. Open faultline-fear.rbxl in Roblox Studio")
	print("  2. Import FBX: File → Import 3D → combined_all_assets.fbx")
	print("  3. Click 'Move to Storage' plugin")
	print("  4. Right-click each model in ServerStorage.AssetTemplates")
	print("  5. Select 'Save to File' → Save to " .. RBXM_FOLDER .. "/")
end
print("────────────────────────────────────────────────")

-- Exit with error code if missing assets
if totalMissing > 0 then
	process.exit(1)
end
