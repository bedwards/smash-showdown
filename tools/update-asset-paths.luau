--[[
	Update Asset Paths

	Scans assets/faultline-fear/rbxm/ for .rbxm files and updates
	faultline-fear.project.json to include them in AssetTemplates.

	Usage: lune run tools/update-asset-paths.luau
]]

local fs = require("@lune/fs")
local serde = require("@lune/serde")
local process = require("@lune/process")

local RBXM_FOLDER = "assets/faultline-fear/rbxm"
local PROJECT_FILE = "faultline-fear.project.json"

print("╔════════════════════════════════════════════════╗")
print("║       UPDATE ASSET PATHS IN PROJECT.JSON       ║")
print("╚════════════════════════════════════════════════╝")
print("")

-- Check if rbxm folder exists
if not fs.isDir(RBXM_FOLDER) then
	print("[ERROR] RBXM folder not found: " .. RBXM_FOLDER)
	print("Create the folder and add .rbxm files exported from Roblox Studio")
	process.exit(1)
end

-- Read project file
if not fs.isFile(PROJECT_FILE) then
	print("[ERROR] Project file not found: " .. PROJECT_FILE)
	process.exit(1)
end

local projectContent = fs.readFile(PROJECT_FILE)
local project = serde.decode("json", projectContent)

-- Scan for .rbxm files
local rbxmFiles = {}
for _, entry in fs.readDir(RBXM_FOLDER) do
	if string.match(entry, "%.rbxm$") or string.match(entry, "%.rbxmx$") then
		table.insert(rbxmFiles, entry)
	end
end

print(string.format("[INFO] Found %d .rbxm files in %s", #rbxmFiles, RBXM_FOLDER))

if #rbxmFiles == 0 then
	print("")
	print("[WARN] No .rbxm files found!")
	print("To export models from Roblox Studio:")
	print("  1. Right-click on model in Explorer")
	print("  2. Select 'Save to File'")
	print("  3. Save to: " .. RBXM_FOLDER .. "/")
	print("")
	process.exit(0)
end

-- Build AssetTemplates structure
local assetTemplates: { [string]: any } = {
	["$className"] = "Folder",
}

for _, filename in rbxmFiles do
	-- Remove extension to get asset name
	local assetName = string.gsub(filename, "%.rbxm[x]?$", "")
	local relativePath = RBXM_FOLDER .. "/" .. filename

	assetTemplates[assetName] = {
		["$path"] = relativePath,
	}

	print(string.format("  [+] %s → %s", assetName, relativePath))
end

-- Update project structure
if not project.tree then
	project.tree = { ["$className"] = "DataModel" }
end

if not project.tree.ServerStorage then
	project.tree.ServerStorage = { ["$className"] = "ServerStorage" }
end

project.tree.ServerStorage.AssetTemplates = assetTemplates

-- Write updated project file
local updatedContent = serde.encode("json", project, true)
fs.writeFile(PROJECT_FILE, updatedContent)

print("")
print(string.format("[OK] Updated %s with %d asset references", PROJECT_FILE, #rbxmFiles))
print("")
print("Next steps:")
print("  1. Run: rojo build faultline-fear.project.json -o faultline-fear.rbxl")
print("  2. Verify assets are present in the built place")
print("  3. Commit the .rbxm files and updated project.json")
