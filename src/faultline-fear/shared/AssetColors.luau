--!strict
--[[
	Faultline Fear: Asset Colors

	Roblox doesn't import FBX material colors automatically.
	This module provides color definitions and applies them to imported models.

	USAGE:
	local AssetColors = Shared.AssetColors
	local model = AssetManifest:CloneAsset("Lighthouse")
	AssetColors:ApplyColors(model, "Lighthouse")

	Colors are based on the Blender material definitions in create_structures.py, etc.
]]

local AssetColors = {}

-- ==========================================
-- COLOR DEFINITIONS
-- Maps AssetName → { PartNamePattern → Color3 }
-- ==========================================

type ColorDef = {
	-- Primary color applied to all parts if no specific match
	primary: Color3,
	-- Optional patterns for specific parts (Lua pattern matching)
	patterns: { [string]: Color3 }?,
}

-- Convert 0-1 Blender color to Color3
local function fromBlender(r: number, g: number, b: number): Color3
	return Color3.new(r, g, b)
end

local COLORS: { [string]: ColorDef } = {
	-- ==========================================
	-- STRUCTURES (from create_structures.py)
	-- ==========================================

	FerrisWheel = {
		primary = fromBlender(0.3, 0.3, 0.35), -- Metal
		patterns = {
			["Gondola"] = fromBlender(0.8, 0.2, 0.2),
			["Light"] = fromBlender(1.0, 0.9, 0.7),
			["Rust"] = fromBlender(0.4, 0.25, 0.15),
		},
	},

	RadioTower = {
		primary = fromBlender(0.5, 0.5, 0.55), -- TowerMetal
		patterns = {
			["Red"] = fromBlender(0.8, 0.1, 0.1),
			["Beacon"] = fromBlender(1.0, 0.2, 0.1),
		},
	},

	AbandonedHouse = {
		primary = fromBlender(0.6, 0.55, 0.5), -- WornWall
		patterns = {
			["Roof"] = fromBlender(0.25, 0.2, 0.18),
			["Shingle"] = fromBlender(0.25, 0.2, 0.18),
			["Door"] = fromBlender(0.35, 0.25, 0.15),
			["Porch"] = fromBlender(0.35, 0.25, 0.15),
			["Wood"] = fromBlender(0.35, 0.25, 0.15),
			["Window"] = fromBlender(0.3, 0.35, 0.4),
		},
	},

	Bridge = {
		primary = fromBlender(0.5, 0.5, 0.48), -- Concrete deck
		patterns = {
			["Steel"] = fromBlender(0.4, 0.4, 0.45),
			["Tower"] = fromBlender(0.4, 0.4, 0.45),
			["Cable"] = fromBlender(0.2, 0.2, 0.22),
			["Rail"] = fromBlender(0.5, 0.3, 0.2),
			["Rust"] = fromBlender(0.5, 0.3, 0.2),
		},
	},

	WaterTower = {
		primary = fromBlender(0.5, 0.5, 0.55), -- TankMetal
		patterns = {
			["Tank"] = fromBlender(0.5, 0.5, 0.55),
			["Rust"] = fromBlender(0.45, 0.3, 0.2),
			["Leg"] = fromBlender(0.45, 0.3, 0.2),
			["Brace"] = fromBlender(0.45, 0.3, 0.2),
		},
	},

	Lighthouse = {
		primary = fromBlender(0.9, 0.9, 0.88), -- White tower
		patterns = {
			["Red"] = fromBlender(0.7, 0.15, 0.1),
			["Dome"] = fromBlender(0.7, 0.15, 0.1),
			["Door"] = fromBlender(0.7, 0.15, 0.1),
			["Band"] = fromBlender(0.7, 0.15, 0.1),
			["Railing"] = fromBlender(0.7, 0.15, 0.1),
			["Glass"] = fromBlender(0.4, 0.5, 0.6),
			["Housing"] = fromBlender(0.4, 0.5, 0.6),
			["Light"] = fromBlender(1.0, 0.95, 0.8),
		},
	},

	-- ==========================================
	-- TERRAIN (from create_terrain_assets.py)
	-- ==========================================

	Boulder_Small = { primary = fromBlender(0.4, 0.38, 0.35) },
	Boulder_Medium = { primary = fromBlender(0.45, 0.42, 0.38) },
	Boulder_Large = { primary = fromBlender(0.5, 0.45, 0.4) },
	Boulder_Huge = { primary = fromBlender(0.55, 0.5, 0.45) },
	RockCluster_1 = { primary = fromBlender(0.42, 0.4, 0.36) },
	RockCluster_2 = { primary = fromBlender(0.44, 0.41, 0.37) },
	FallenRocks = { primary = fromBlender(0.46, 0.42, 0.38) },
	FaultEdge_Left = { primary = fromBlender(0.35, 0.32, 0.28) },
	FaultEdge_Right = { primary = fromBlender(0.35, 0.32, 0.28) },
	SteamVent = {
		primary = fromBlender(0.3, 0.28, 0.25),
		patterns = {
			["Vent"] = fromBlender(0.2, 0.18, 0.15),
		},
	},
	Cliff_Coastal = { primary = fromBlender(0.6, 0.55, 0.5) },
	Cliff_Mountain = { primary = fromBlender(0.5, 0.48, 0.45) },

	-- ==========================================
	-- CAVES (from create_caves.py)
	-- ==========================================

	CaveEntrance_Small = { primary = fromBlender(0.25, 0.23, 0.2) },
	CaveEntrance_Medium = { primary = fromBlender(0.25, 0.23, 0.2) },
	CaveEntrance_Large = { primary = fromBlender(0.25, 0.23, 0.2) },
	CaveInteriorSegment = { primary = fromBlender(0.2, 0.18, 0.16) },
	CaveChamber = { primary = fromBlender(0.18, 0.16, 0.14) },
	RockPillar = { primary = fromBlender(0.3, 0.28, 0.25) },
	Stalactite = { primary = fromBlender(0.35, 0.33, 0.3) },
	Stalagmite = { primary = fromBlender(0.32, 0.3, 0.27) },

	-- ==========================================
	-- CREATURES (from create_creatures.py)
	-- ==========================================

	ShadowStalker = {
		primary = fromBlender(0.1, 0.08, 0.12), -- Dark purple-black
		patterns = {
			["Eye"] = fromBlender(0.8, 0.1, 0.1), -- Red eyes
			["Claw"] = fromBlender(0.15, 0.12, 0.1),
		},
	},

	FissureDweller = {
		primary = fromBlender(0.25, 0.15, 0.1), -- Brown-red
		patterns = {
			["Segment"] = fromBlender(0.3, 0.18, 0.12),
			["Mouth"] = fromBlender(0.5, 0.1, 0.1),
		},
	},

	NightBird = {
		primary = fromBlender(0.15, 0.12, 0.18), -- Dark purple
		patterns = {
			["Eye"] = fromBlender(1.0, 0.8, 0.2), -- Yellow glowing eyes
			["Beak"] = fromBlender(0.2, 0.15, 0.1),
		},
	},

	-- ==========================================
	-- ANIMALS (from create_animals.py)
	-- ==========================================

	Deer = {
		primary = fromBlender(0.55, 0.4, 0.25), -- Brown
		patterns = {
			["Belly"] = fromBlender(0.7, 0.6, 0.5),
			["Antler"] = fromBlender(0.4, 0.35, 0.3),
		},
	},

	Bird = { primary = fromBlender(0.6, 0.55, 0.5) }, -- Gray-brown

	Rabbit = {
		primary = fromBlender(0.65, 0.55, 0.45), -- Light brown
		patterns = {
			["Tail"] = fromBlender(0.9, 0.88, 0.85),
		},
	},

	Fish = {
		primary = fromBlender(0.3, 0.5, 0.6), -- Blue-gray
		patterns = {
			["Belly"] = fromBlender(0.8, 0.8, 0.75),
		},
	},

	Wolf = {
		primary = fromBlender(0.35, 0.33, 0.32), -- Gray
		patterns = {
			["Belly"] = fromBlender(0.5, 0.48, 0.45),
			["Eye"] = fromBlender(0.7, 0.6, 0.2),
		},
	},

	Coyote = {
		primary = fromBlender(0.55, 0.45, 0.35), -- Tan
		patterns = {
			["Belly"] = fromBlender(0.7, 0.65, 0.55),
		},
	},

	MountainLion = {
		primary = fromBlender(0.6, 0.5, 0.35), -- Tawny
		patterns = {
			["Belly"] = fromBlender(0.75, 0.7, 0.6),
		},
	},

	-- ==========================================
	-- LIMINAL SPACES (from create_liminal_spaces.py)
	-- ==========================================

	AbandonedMall = {
		primary = fromBlender(0.85, 0.82, 0.78), -- Off-white tile
		patterns = {
			["Floor"] = fromBlender(0.7, 0.68, 0.65),
			["Metal"] = fromBlender(0.5, 0.5, 0.52),
			["Light"] = fromBlender(0.95, 0.98, 1.0), -- Fluorescent
		},
	},

	HotelLobby = {
		primary = fromBlender(0.6, 0.5, 0.4), -- Carpet/wood
		patterns = {
			["Wall"] = fromBlender(0.8, 0.75, 0.65),
			["Metal"] = fromBlender(0.7, 0.6, 0.3), -- Brass
		},
	},

	AbandonedSchool = {
		primary = fromBlender(0.7, 0.68, 0.6), -- Linoleum
		patterns = {
			["Desk"] = fromBlender(0.5, 0.45, 0.35),
			["Chalkboard"] = fromBlender(0.15, 0.25, 0.15),
		},
	},

	Hospital = {
		primary = fromBlender(0.9, 0.92, 0.9), -- White walls
		patterns = {
			["Floor"] = fromBlender(0.7, 0.72, 0.7),
			["Metal"] = fromBlender(0.6, 0.62, 0.65), -- Stainless
		},
	},

	HighwayUnderpass = {
		primary = fromBlender(0.5, 0.48, 0.45), -- Concrete
		patterns = {
			["Road"] = fromBlender(0.25, 0.25, 0.28),
			["Metal"] = fromBlender(0.4, 0.4, 0.42),
			["Light"] = fromBlender(1.0, 0.7, 0.3), -- Sodium light
		},
	},

	-- ==========================================
	-- SIGNS (from create_signs.py)
	-- ==========================================

	DirectionalSign = {
		primary = fromBlender(0.1, 0.4, 0.15), -- Green highway sign
		patterns = {
			["Post"] = fromBlender(0.4, 0.4, 0.42),
			["Text"] = fromBlender(0.95, 0.95, 0.95),
		},
	},

	WarningSign = {
		primary = fromBlender(1.0, 0.8, 0.0), -- Yellow warning
		patterns = {
			["Post"] = fromBlender(0.4, 0.4, 0.42),
			["Symbol"] = fromBlender(0.1, 0.1, 0.1),
		},
	},

	StoryPlaque = {
		primary = fromBlender(0.4, 0.3, 0.2), -- Weathered wood
		patterns = {
			["Post"] = fromBlender(0.35, 0.28, 0.18),
		},
	},

	ObjectiveMarker = {
		primary = fromBlender(0.2, 0.5, 0.8), -- Blue marker
		patterns = {
			["Post"] = fromBlender(0.4, 0.4, 0.42),
			["Light"] = fromBlender(0.3, 0.7, 1.0),
		},
	},

	RoadSign = {
		primary = fromBlender(0.95, 0.95, 0.95), -- White
		patterns = {
			["Post"] = fromBlender(0.4, 0.4, 0.42),
			["Border"] = fromBlender(0.1, 0.1, 0.1),
		},
	},

	-- ==========================================
	-- NPCs
	-- ==========================================

	Survivor = {
		primary = fromBlender(0.3, 0.4, 0.5), -- Clothing
		patterns = {
			["Skin"] = fromBlender(0.8, 0.65, 0.55),
			["Hair"] = fromBlender(0.25, 0.2, 0.15),
		},
	},

	PetCompanion = {
		primary = fromBlender(0.5, 0.4, 0.3), -- Fur
		patterns = {
			["Belly"] = fromBlender(0.7, 0.65, 0.55),
			["Eye"] = fromBlender(0.3, 0.25, 0.15),
		},
	},
}

-- ==========================================
-- COLOR APPLICATION
-- ==========================================

--[[
	Apply colors to all BaseParts in a model based on asset type.
	Uses pattern matching on part names for multi-colored models.
]]
function AssetColors:ApplyColors(model: Model, assetName: string)
	local colorDef = COLORS[assetName]
	if not colorDef then
		-- No color definition, use a default gray
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Color = Color3.fromRGB(150, 150, 150)
			end
		end
		return
	end

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local colorApplied = false

			-- Try pattern matching on part name
			if colorDef.patterns then
				for pattern, color in pairs(colorDef.patterns) do
					if string.find(part.Name, pattern) then
						part.Color = color
						colorApplied = true
						break
					end
				end
			end

			-- Apply primary color if no pattern matched
			if not colorApplied then
				part.Color = colorDef.primary
			end

			-- Ensure good material for visibility
			if part.Material == Enum.Material.Plastic then
				part.Material = Enum.Material.SmoothPlastic
			end
		end
	end
end

--[[
	Check if we have color definitions for an asset.
]]
function AssetColors:HasColors(assetName: string): boolean
	return COLORS[assetName] ~= nil
end

--[[
	Get the primary color for an asset (for placeholders).
]]
function AssetColors:GetPrimaryColor(assetName: string): Color3
	local colorDef = COLORS[assetName]
	if colorDef then
		return colorDef.primary
	end
	return Color3.fromRGB(150, 150, 150)
end

--[[
	Get all defined asset names.
]]
function AssetColors:GetDefinedAssets(): { string }
	local names = {}
	for name in pairs(COLORS) do
		table.insert(names, name)
	end
	return names
end

return AssetColors
