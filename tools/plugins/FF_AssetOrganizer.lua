--[[
	Faultline Fear: Asset Organizer Plugin

	WHAT THIS DOES:
	1. After you import the combined FBX, click "Organize Assets"
	2. Plugin finds all MeshParts/Models in Workspace
	3. Matches them to AssetManifest names
	4. Moves them to ReplicatedStorage.Assets with correct structure
	5. Applies colors from AssetColors definitions

	INSTALLATION:
	1. Copy this file to your Roblox Plugins folder:
	   - Windows: %LOCALAPPDATA%\Roblox\Plugins\
	   - Mac: ~/Documents/Roblox/Plugins/
	2. Restart Roblox Studio
	3. Look for "Faultline Fear" toolbar

	USAGE (EASIEST):
	1. File → Import 3D
	2. Select: assets/models/combined_all_assets.fbx
	3. Import settings: keep defaults, click Import
	4. All meshes appear in Workspace
	5. Click "Organize Assets" button in Faultline Fear toolbar
	6. Done! Models are in ReplicatedStorage.Assets with colors applied
	7. SAVE THE FILE so models persist!

	The plugin handles:
	- Naming models correctly (FerrisWheel, AbandonedHouse, etc.)
	- Organizing into category folders
	- Applying colors (Roblox doesn't import FBX colors)
]]

local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

-- Create toolbar and buttons
local toolbar = plugin:CreateToolbar("Faultline Fear")
local clearButton = toolbar:CreateButton(
	"1. Clear Assets",
	"Delete all assets from ReplicatedStorage.Assets (do this before re-importing)",
	"rbxassetid://6031075931" -- Trash icon
)
local organizeButton = toolbar:CreateButton(
	"2. Organize",
	"Move imported meshes to ReplicatedStorage and apply colors",
	"rbxassetid://6031075938" -- Folder icon
)
local applyColorsButton = toolbar:CreateButton(
	"3. Recolor",
	"Re-apply colors to all assets in ReplicatedStorage.Assets",
	"rbxassetid://6031075929" -- Paint icon
)

-- ==========================================
-- ASSET NAME MAPPING
-- Maps FBX filename patterns to asset names
-- ==========================================

local NAME_PATTERNS = {
	-- Structures
	{ pattern = "ferris", name = "FerrisWheel", category = "Structures" },
	{ pattern = "radio_tower", name = "RadioTower", category = "Structures" },
	{ pattern = "radiotower", name = "RadioTower", category = "Structures" },
	{ pattern = "water_tower", name = "WaterTower", category = "Structures" },
	{ pattern = "watertower", name = "WaterTower", category = "Structures" },
	{ pattern = "lighthouse", name = "Lighthouse", category = "Structures" },
	{ pattern = "house", name = "AbandonedHouse", category = "Structures" },
	{ pattern = "bridge", name = "Bridge", category = "Structures" },

	-- Animals
	{ pattern = "deer", name = "Deer", category = "Animals" },
	{ pattern = "rabbit", name = "Rabbit", category = "Animals" },
	{ pattern = "bird", name = "Bird", category = "Animals" },
	{ pattern = "squirrel", name = "Squirrel", category = "Animals" },
	{ pattern = "fish", name = "Fish", category = "Animals" },
	{ pattern = "crab", name = "Crab", category = "Animals" },

	-- Creatures
	{ pattern = "stalker", name = "Stalker", category = "Creatures" },
	{ pattern = "gloom", name = "GloomWraith", category = "Creatures" },
	{ pattern = "tremor", name = "TremorWorm", category = "Creatures" },

	-- Terrain
	{ pattern = "rock", name = "Rock", category = "Terrain" },
	{ pattern = "boulder", name = "Boulder", category = "Terrain" },
	{ pattern = "tree", name = "Tree", category = "Terrain" },
	{ pattern = "bush", name = "Bush", category = "Terrain" },
	{ pattern = "grass", name = "GrassClump", category = "Terrain" },
	{ pattern = "log", name = "FallenLog", category = "Terrain" },
	{ pattern = "stump", name = "TreeStump", category = "Terrain" },

	-- NPCs
	{ pattern = "survivor", name = "Survivor", category = "NPCs" },
	{ pattern = "npc", name = "NPC", category = "NPCs" },

	-- Caves
	{ pattern = "cave", name = "CaveEntrance", category = "Caves" },
	{ pattern = "stalactite", name = "Stalactite", category = "Caves" },
	{ pattern = "stalagmite", name = "Stalagmite", category = "Caves" },

	-- Signs
	{ pattern = "sign", name = "Sign", category = "Signs" },

	-- Liminal
	{ pattern = "mall", name = "AbandonedMall", category = "Liminal" },
	{ pattern = "hotel", name = "HotelLobby", category = "Liminal" },
	{ pattern = "school", name = "AbandonedSchool", category = "Liminal" },
	{ pattern = "hospital", name = "Hospital", category = "Liminal" },
	{ pattern = "underpass", name = "HighwayUnderpass", category = "Liminal" },

	-- Pet
	{ pattern = "pet", name = "PetCompanion", category = "Pet" },
	{ pattern = "companion", name = "PetCompanion", category = "Pet" },
	{ pattern = "dog", name = "PetCompanion", category = "Pet" },
	{ pattern = "cat", name = "PetCompanion", category = "Pet" },
}

-- ==========================================
-- COLOR DEFINITIONS (from AssetColors.luau)
-- ==========================================

local COLORS = {
	FerrisWheel = {
		primary = Color3.new(0.3, 0.3, 0.35),
		patterns = {
			Gondola = Color3.new(0.8, 0.2, 0.2),
			Light = Color3.new(1.0, 0.9, 0.7),
			Rust = Color3.new(0.4, 0.25, 0.15),
		},
	},
	RadioTower = {
		primary = Color3.new(0.5, 0.5, 0.55),
		patterns = {
			Red = Color3.new(0.8, 0.1, 0.1),
			Beacon = Color3.new(1.0, 0.2, 0.1),
		},
	},
	AbandonedHouse = {
		primary = Color3.new(0.6, 0.55, 0.5),
		patterns = {
			Roof = Color3.new(0.25, 0.2, 0.18),
			Shingle = Color3.new(0.25, 0.2, 0.18),
			Door = Color3.new(0.35, 0.25, 0.15),
			Porch = Color3.new(0.35, 0.25, 0.15),
			Wood = Color3.new(0.35, 0.25, 0.15),
			Window = Color3.new(0.3, 0.35, 0.4),
		},
	},
	Bridge = {
		primary = Color3.new(0.5, 0.5, 0.48),
		patterns = {
			Steel = Color3.new(0.4, 0.4, 0.45),
			Tower = Color3.new(0.4, 0.4, 0.45),
			Cable = Color3.new(0.2, 0.2, 0.22),
			Rail = Color3.new(0.5, 0.3, 0.2),
			Rust = Color3.new(0.5, 0.3, 0.2),
		},
	},
	WaterTower = {
		primary = Color3.new(0.7, 0.75, 0.8),
		patterns = {
			Tank = Color3.new(0.7, 0.75, 0.8),
			Leg = Color3.new(0.3, 0.3, 0.32),
			Rust = Color3.new(0.5, 0.35, 0.25),
		},
	},
	Lighthouse = {
		primary = Color3.new(0.95, 0.95, 0.9),
		patterns = {
			Red = Color3.new(0.7, 0.15, 0.1),
			Stripe = Color3.new(0.7, 0.15, 0.1),
			Glass = Color3.new(0.8, 0.85, 0.9),
			Lens = Color3.new(1.0, 0.95, 0.8),
		},
	},
	-- Add more as needed...
}

-- Default colors for categories without specific definitions
local CATEGORY_DEFAULTS = {
	Structures = Color3.new(0.6, 0.55, 0.5),
	Animals = Color3.new(0.6, 0.5, 0.4),
	Creatures = Color3.new(0.3, 0.25, 0.35),
	Terrain = Color3.new(0.5, 0.5, 0.45),
	NPCs = Color3.new(0.7, 0.6, 0.5),
	Caves = Color3.new(0.4, 0.35, 0.3),
	Signs = Color3.new(0.3, 0.5, 0.3),
	Liminal = Color3.new(0.7, 0.7, 0.65),
	Pet = Color3.new(0.8, 0.6, 0.4),
}

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================

local function matchAssetName(objectName: string): (string?, string?)
	local lowerName = objectName:lower()
	for _, mapping in ipairs(NAME_PATTERNS) do
		if lowerName:find(mapping.pattern) then
			return mapping.name, mapping.category
		end
	end
	return nil, nil
end

local function ensureFolder(parent, name): Folder
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local function applyColorsToModel(model: Model, assetName: string, category: string)
	local colorDef = COLORS[assetName]
	local defaultColor = CATEGORY_DEFAULTS[category] or Color3.new(0.5, 0.5, 0.5)

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local partName = part.Name
			local colorApplied = false

			-- Try pattern matching first
			if colorDef and colorDef.patterns then
				for pattern, color in pairs(colorDef.patterns) do
					if partName:find(pattern) then
						part.Color = color
						colorApplied = true
						break
					end
				end
			end

			-- Fall back to primary color
			if not colorApplied then
				if colorDef and colorDef.primary then
					part.Color = colorDef.primary
				else
					part.Color = defaultColor
				end
			end
		end
	end
end

-- ==========================================
-- MAIN FUNCTIONS
-- ==========================================

local function organizeAssets()
	ChangeHistoryService:SetWaypoint("Before Asset Organization")

	local assetsFolder = ensureFolder(game.ReplicatedStorage, "Assets")
	local organized = 0
	local unmatched = {}

	-- Find all models/meshes in Workspace that look like imports
	local toProcess = {}
	for _, obj in game.Workspace:GetChildren() do
		-- Skip folders and known game objects
		if obj:IsA("Model") or obj:IsA("MeshPart") then
			if not obj:FindFirstChild("Humanoid") then -- Skip characters
				table.insert(toProcess, obj)
			end
		end
	end

	print("[AssetOrganizer] Found", #toProcess, "objects to process")

	for _, obj in ipairs(toProcess) do
		local assetName, category = matchAssetName(obj.Name)

		if assetName and category then
			-- Create category folder
			local categoryFolder = ensureFolder(assetsFolder, category)

			-- Check if asset already exists
			local existing = categoryFolder:FindFirstChild(assetName)
			if existing then
				-- Add number suffix for duplicates
				local count = 1
				while categoryFolder:FindFirstChild(assetName .. "_" .. count) do
					count = count + 1
				end
				assetName = assetName .. "_" .. count
			end

			-- Wrap MeshPart in Model if needed
			local model
			if obj:IsA("MeshPart") then
				model = Instance.new("Model")
				model.Name = assetName
				obj.Parent = model
				model.PrimaryPart = obj
			else
				model = obj
				model.Name = assetName
			end

			-- Apply colors
			applyColorsToModel(model, assetName:gsub("_%d+$", ""), category)

			-- Move to assets folder
			model.Parent = categoryFolder
			organized = organized + 1
			print("[AssetOrganizer] Organized:", assetName, "→", category)
		else
			table.insert(unmatched, obj.Name)
		end
	end

	ChangeHistoryService:SetWaypoint("After Asset Organization")

	-- Report results
	print("========================================")
	print("[AssetOrganizer] COMPLETE")
	print("  Organized:", organized, "assets")
	print("  Unmatched:", #unmatched, "objects")
	if #unmatched > 0 then
		print("  Unmatched names:")
		for _, name in ipairs(unmatched) do
			print("    -", name)
		end
	end
	print("========================================")

	-- Select the Assets folder so user can see results
	Selection:Set({assetsFolder})
end

local function reapplyColors()
	ChangeHistoryService:SetWaypoint("Before Color Application")

	local assetsFolder = game.ReplicatedStorage:FindFirstChild("Assets")
	if not assetsFolder then
		warn("[AssetOrganizer] No Assets folder found in ReplicatedStorage")
		return
	end

	local colored = 0

	for _, categoryFolder in assetsFolder:GetChildren() do
		if categoryFolder:IsA("Folder") then
			local category = categoryFolder.Name
			for _, model in categoryFolder:GetChildren() do
				if model:IsA("Model") then
					local assetName = model.Name:gsub("_%d+$", "") -- Remove number suffix
					applyColorsToModel(model, assetName, category)
					colored = colored + 1
				end
			end
		end
	end

	ChangeHistoryService:SetWaypoint("After Color Application")

	print("[AssetOrganizer] Applied colors to", colored, "assets")
end

-- ==========================================
-- CLEAR FUNCTION
-- ==========================================

local function clearAssets()
	local assetsFolder = game.ReplicatedStorage:FindFirstChild("Assets")
	if not assetsFolder then
		print("[AssetOrganizer] No Assets folder found - nothing to clear")
		return
	end

	ChangeHistoryService:SetWaypoint("Before Clear Assets")

	local count = 0
	for _, categoryFolder in assetsFolder:GetChildren() do
		if categoryFolder:IsA("Folder") then
			for _, asset in categoryFolder:GetChildren() do
				asset:Destroy()
				count = count + 1
			end
		end
	end

	-- Also clear any meshes left in Workspace from previous imports
	local workspaceCount = 0
	for _, obj in game.Workspace:GetChildren() do
		if obj:IsA("MeshPart") or (obj:IsA("Model") and obj:FindFirstChildOfClass("MeshPart")) then
			-- Skip player characters
			if not obj:FindFirstChild("Humanoid") then
				obj:Destroy()
				workspaceCount = workspaceCount + 1
			end
		end
	end

	ChangeHistoryService:SetWaypoint("After Clear Assets")

	print("========================================")
	print("[AssetOrganizer] CLEARED")
	print("  Deleted from ReplicatedStorage.Assets:", count)
	print("  Deleted from Workspace:", workspaceCount)
	print("========================================")
	print("Now do: File → Import 3D → select combined_all_assets.fbx")
end

-- ==========================================
-- BUTTON HANDLERS
-- ==========================================

clearButton.Click:Connect(function()
	print("[AssetOrganizer] Clearing old assets...")
	clearAssets()
end)

organizeButton.Click:Connect(function()
	print("[AssetOrganizer] Starting asset organization...")
	organizeAssets()
end)

applyColorsButton.Click:Connect(function()
	print("[AssetOrganizer] Re-applying colors...")
	reapplyColors()
end)

print("[FF_AssetOrganizer] Plugin loaded!")
print("[FF_AssetOrganizer] Workflow:")
print("[FF_AssetOrganizer]   1. Click 'Clear Assets' (if re-importing)")
print("[FF_AssetOrganizer]   2. File → Import 3D → combined_all_assets.fbx")
print("[FF_AssetOrganizer]   3. Click 'Organize' to move & color assets")
print("[FF_AssetOrganizer]   4. Save the place!")
