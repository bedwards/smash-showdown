# Faultline Fear: Blender Terrain Workflow

This document describes how to create Blender terrain that matches the game's heightmap exactly.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    HEIGHTMAP (Source of Truth)              │
│                                                              │
│   - 2D grid: heightData[cellX][cellZ] = Y height            │
│   - Resolution: 4 studs per cell                            │
│   - Deterministic from seed                                 │
│   - O(1) lookups for all gameplay systems                   │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
     ┌────────────────┐ ┌────────────┐ ┌─────────────────┐
     │ Roblox Terrain │ │ Blender    │ │ Gameplay Systems│
     │ (Procedural)   │ │ Meshes     │ │ (Items, NPCs)   │
     │                │ │            │ │                 │
     │ Generated FROM │ │ Match the  │ │ Query Heightmap │
     │ heightmap      │ │ heightmap  │ │ for positions   │
     └────────────────┘ └────────────┘ └─────────────────┘
```

## Why This Matters

1. **Instant height queries** - All systems use Heightmap, not raycasting
2. **Blender meshes align** - Import heightmap as displacement = exact match
3. **Buildings work** - Flatten heightmap → Blender + Roblox terrain both update
4. **Loading is fast** - Heightmap generates first, visuals can stream

## Blender Workflow

### Step 1: Export Heightmap from Roblox

In Roblox Studio's command bar or a script:

```lua
local Shared = require(game.ReplicatedStorage.Shared)
local TerrainGenerator = require(game.ServerScriptService.Server.Services.TerrainGenerator)

-- Generate if not already
TerrainGenerator:GenerateHeightmap()

-- Export
local pgmData = TerrainGenerator:ExportForBlender()

-- Copy pgmData to clipboard or save to file
-- The console will also print import instructions
```

This outputs:
- PGM format heightmap data (grayscale image)
- Metadata: world size, height range, cell count

### Step 2: Create Base Plane in Blender

1. **File → New → General**
2. Delete default cube
3. **Add → Mesh → Plane**
4. Set dimensions:
   - Scale X: 4000 (world size)
   - Scale Z: 4000 (world size)
5. Apply scale: **Ctrl+A → Scale**
6. Subdivide:
   - Edit Mode → Subdivide
   - Number of cuts: 999 (to get 1000x1000 grid)
   - OR use Subdivision Surface modifier

### Step 3: Apply Heightmap Displacement

1. **Add Modifier → Displace**
2. Create new texture:
   - Texture Type: Image
   - Load the PGM file
3. Set displacement parameters:
   - **Strength**: Height range (e.g., 500 for 0-500 stud terrain)
   - **Midlevel**: `minHeight / (maxHeight - minHeight)` (from metadata)
   - **Direction**: Z (or Normal)
4. Apply modifier when satisfied

### Step 4: Add Artistic Detail

Now you can sculpt and detail while staying close to the heightmap:

1. **Sculpt Mode** for fine details:
   - Cliffs and rock faces
   - Fault line edges
   - Beach dunes

2. **Add Blender assets**:
   - Rock formations
   - Tree placement guides
   - Building footprints

3. **Material zones** (for reference):
   - Mountains (Z > 1500): Snow/Rock
   - Forest (Z 800-1500): Grass
   - Fault (Z 400-800): Exposed rock
   - Valley (Z -200-400): Grass (town area)
   - Beach (Z < -800): Sand

### Step 5: Export to Roblox

1. **Select mesh**
2. **File → Export → FBX**
3. Settings:
   - **Scale**: 0.01 (Blender meters → Roblox studs)
   - **Apply Transform**: ✓ Checked
   - **Forward**: -Z Forward
   - **Up**: Y Up
4. In Roblox:
   - Game → Import 3D
   - Position at (0, 0, 0)

## Building Placement

Buildings need flat ground. Here's the workflow:

### In Code (Automatic)
```lua
-- Before placing a building:
local TerrainGenerator = require(...)
local buildingHeight = TerrainGenerator:PrepareBuilding(x, z, radius)

-- Place building at returned height
building:PivotTo(CFrame.new(x, buildingHeight, z))
```

This:
1. Flattens the heightmap area
2. Updates visual terrain (if generated)
3. Returns the correct Y position

### In Blender (Manual)
If pre-placing buildings in Blender:
1. Note the building center (X, Z)
2. Note the footprint radius
3. In game config, register the building
4. Heightmap will flatten during generation

## Validation

To check Blender mesh aligns with heightmap:

```lua
local TerrainUtils = require(game.ReplicatedStorage.Shared.TerrainUtils)

-- Check multiple points
for x = -1000, 1000, 100 do
    for z = -1000, 1000, 100 do
        local aligned = TerrainUtils.validateTerrainAlignment(x, z, 2)
        if not aligned then
            warn("Misalignment at", x, z)
        end
    end
end
```

## Asset Scale Reference

| Blender | Roblox | Notes |
|---------|--------|-------|
| 1 m | 100 studs | Use 0.01 scale on export |
| 40 m | 4000 studs | Full world size |
| 0.04 m | 4 studs | Heightmap cell size |
| 5 m | 500 studs | Max mountain height |

## File Organization

```
assets/blender/
├── terrain/
│   ├── heightmap.pgm         # Exported from game
│   ├── heightmap_metadata.txt # Scale info
│   ├── terrain_base.blend    # Base terrain mesh
│   └── terrain_detailed.blend # With sculpting
├── structures/
│   ├── boardwalk.blend
│   ├── ferris_wheel.blend
│   └── abandoned_buildings/
└── props/
    ├── rocks.blend
    ├── trees.blend
    └── signs.blend
```

## Common Issues

### Mesh floats/sinks
- **Cause**: Scale or midlevel wrong
- **Fix**: Check metadata, recalculate midlevel

### Seams between chunks
- **Cause**: Heightmap interpolation vs mesh smoothing
- **Fix**: Use GetHeightInterpolated for placement

### Buildings clip terrain
- **Cause**: Didn't flatten before placing
- **Fix**: Use TerrainGenerator:PrepareBuilding()

### Performance issues
- **Cause**: Too many polygons
- **Fix**: Use LOD meshes, reduce distant detail

## Quick Reference

```lua
-- Get height at position
local height = Shared.Heightmap:GetHeight(x, z)

-- Get smooth interpolated height
local height = Shared.Heightmap:GetHeightInterpolated(x, z)

-- Snap position to terrain
local pos = Shared.Heightmap:SnapToTerrain(Vector3.new(x, 0, z), offset)

-- Flatten area for building
local height = Shared.Heightmap:FlattenArea(x, z, radius)

-- Get zone name
local zone = Shared.Heightmap:GetZone(x, z)

-- Get material
local material = Shared.Heightmap:GetMaterial(x, z)

-- Export for Blender
local pgm = Shared.Heightmap:ExportPGM()
local meta = Shared.Heightmap:GetBlenderMetadata()
```
