# Faultline Fear: Asset Pipeline

## Overview

This document describes how to create 3D assets in Blender and import them into Roblox for use in Faultline Fear.

## Quick Reference

```bash
# Generate assets
blender --background --python tools/blender/create_creatures.py

# Check asset status in-game
-- In Roblox Studio console:
require(game.ReplicatedStorage.Shared).AssetManifest:PrintStatus()
```

## Pipeline Architecture

```
Blender Script (Python)
    ↓
FBX File (local, not committed)
    ↓
Manual Import to Roblox Studio
    ↓
ReplicatedStorage/Assets/<Category>/<AssetName>
    ↓
AssetManifest:GetAsset() / :CloneAsset()
    ↓
Game Code
```

## Step-by-Step Workflow

### 1. Create/Run Blender Script

All Blender scripts live in `tools/blender/`. They use headless mode.

```bash
# Test Blender headless mode works
blender --background --python-expr "import bpy; print('Works!')"

# Generate creature models
blender --background --python tools/blender/create_creatures.py

# Output goes to: assets/models/creatures/
```

### 2. Import FBX to Roblox Studio

1. Open Roblox Studio with the Faultline Fear place
2. Go to **Asset Manager** (View → Asset Manager)
3. Click **Bulk Import**
4. Select the FBX file(s) from `assets/models/`
5. Wait for import to complete

### 3. Organize in ReplicatedStorage

Create this folder structure in ReplicatedStorage:

```
ReplicatedStorage/
└── Assets/
    ├── Creatures/
    │   ├── ShadowStalker (Model)
    │   ├── FissureDweller (Model)
    │   └── NightBird (Model)
    ├── Animals/
    │   ├── Deer (Model)
    │   └── Wolf (Model)
    ├── Structures/
    │   ├── FerrisWheel (Model)
    │   └── RadioTower (Model)
    └── NPCs/
        ├── Survivor (Model)
        └── PetCompanion (Model)
```

**Important**: Asset names must match exactly what's in `AssetManifest.luau`.

### 4. Verify Import

In Roblox Studio's command bar or output:

```lua
-- Check all assets
require(game.ReplicatedStorage.Shared).AssetManifest:PrintStatus()

-- Check specific asset
local exists = require(game.ReplicatedStorage.Shared).AssetManifest:HasAsset("ShadowStalker")
print("ShadowStalker:", exists)
```

### 5. Use in Code

```lua
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local AssetManifest = Shared.AssetManifest

-- Clone an asset for spawning
local creature = AssetManifest:CloneAsset("ShadowStalker")
if creature then
    creature.Parent = workspace.Creatures
    creature:PivotTo(CFrame.new(spawnPosition))
end

-- Get all creatures
local allCreatures = AssetManifest:GetAssetsInCategory("Creatures")
```

## Blender Scripts

### Existing Scripts

| Script | Output | Description |
|--------|--------|-------------|
| `create_creatures.py` | `assets/models/creatures/` | Night creatures (3 types) |

### Creating New Scripts

Use `blender_utils.py` for common operations:

```python
from blender_utils import (
    clear_scene,
    create_material,
    apply_material,
    join_objects,
    export_fbx,
    create_primitive,
    smooth_shade,
)

def create_my_asset():
    clear_scene()
    parts = []

    # Create geometry...

    model = join_objects(parts)
    model.name = "MyAsset"

    export_fbx("assets/models/category/my_asset.fbx", scale=100)
```

### FBX Export Settings

The `export_fbx()` function uses these settings:
- Scale: 100x (Blender units → Roblox studs)
- Forward axis: -Z
- Up axis: Y
- Apply transforms: Yes

## Git Policy

**DO NOT COMMIT** binary asset files:
- `*.fbx`
- `*.obj`
- `*.blend`

**DO COMMIT** asset generation scripts:
- `tools/blender/*.py`

This ensures:
- Repository stays small
- Assets can be regenerated from scripts
- Different developers can customize assets

## Troubleshooting

### Asset Not Found

```
[AssetManifest] Asset 'X' not found. Run: tools/blender/create_X.py
```

**Solution**: Run the Blender script, import FBX, place in correct folder.

### Wrong Scale

**Symptom**: Asset is huge or tiny in-game.

**Solution**: Ensure Blender script uses `export_fbx(path, scale=100)`.

### Missing Materials

**Symptom**: Asset is grey/default material.

**Solution**: Check that materials use Principled BSDF shader in Blender. Roblox imports these as SurfaceAppearance.

### Collision Issues

**Symptom**: Players walk through asset or float above it.

**Solution**: In Roblox Studio, select the MeshPart and:
- Set `CanCollide = true`
- Adjust collision fidelity if needed

## Asset Categories

| Category | Blender Script | Description |
|----------|---------------|-------------|
| Creatures | `create_creatures.py` | Night monsters |
| Animals | `create_animals.py` | Day/night wildlife |
| Structures | `create_structures.py` | Buildings, landmarks |
| NPCs | `create_npcs.py` | Survivors, pet |
| Props | `create_props.py` | Signs, collectibles |
| Terrain | `create_terrain.py` | Fault line edges, cliffs |

## Adding New Assets

1. Add entry to `AssetManifest.luau`:
```lua
MyNewAsset = {
    name = "MyNewAsset",
    category = "MyCategory",
    blenderScript = "tools/blender/create_myassets.py",
    description = "What this asset is",
    required = false,
},
```

2. Create/update Blender script

3. Run script, import FBX, place in folder

4. Verify with `AssetManifest:PrintStatus()`
