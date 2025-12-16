# Terrain Architecture: Elevation System

## The Problem

Terrain elevation queries are critical for gameplay. Every spawned item, NPC, creature, player, and building needs to know the ground height at a given (X, Z) position. The naive approach—raycasting from the sky—has serious problems:

1. **Performance**: Raycasting every frame for hundreds of entities is expensive
2. **Race Conditions**: If visual terrain hasn't loaded, raycasts return nothing
3. **Non-determinism**: Roblox terrain voxels may load in different orders
4. **Blender Mesh Sync**: External meshes may have different heights than expected

## The Solution: Two-Phase Terrain Generation

Faultline Fear solves this with a **Heightmap-first architecture**:

```
PHASE 1: HEIGHTMAP (BLOCKING)
    ↓
    Generate mathematical heightmap from seed
    ↓
    All height queries now work (O(1) lookups)
    ↓
    Services can initialize (spawn items, NPCs, etc.)
    ↓
PHASE 2: VISUAL TERRAIN (ASYNC)
    ↓
    Generate Roblox terrain from heightmap data
    ↓
    Import Blender meshes (must match heightmap!)
    ↓
    Players see the world
```

### Why This Works

1. **Heightmap is the source of truth** - Visual terrain is generated FROM the heightmap
2. **No race condition** - Heightmap completes BEFORE any spawning code runs
3. **Deterministic** - Same seed = same heightmap = same heights everywhere
4. **O(1) lookups** - Pre-computed grid, no raycasting needed

## Server Startup Sequence

From `Main.server.luau`:

```lua
-- STEP 1: Create remote events (needed by services)

-- STEP 2: GENERATE HEIGHTMAP (BLOCKING)
-- This MUST complete before any gameplay systems start
print("[FaultlineFear] CRITICAL: Generating heightmap...")
Heightmap:Generate(Config.TERRAIN_SEED)
-- All height queries now work!

-- STEP 3: Initialize services (can now query heights)
TerrainGenerator:Initialize()
CollectibleSpawner:Initialize()  -- Uses Heightmap:GetHeight()
NPCService:Initialize()           -- Uses Heightmap:GetHeight()
CreatureService:Initialize()      -- Uses Heightmap:GetHeight()

-- STEP 4: Generate visual terrain (ASYNC - doesn't block gameplay)
task.spawn(function()
    TerrainGenerator:GenerateVisualTerrain()
end)
```

## How to Query Elevation

### The Single API (Use This!)

```lua
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Heightmap = Shared.Heightmap

-- Basic lookup (O(1), rounds to nearest cell)
local height = Heightmap:GetHeight(x, z)

-- Smooth interpolation (bilinear, slightly slower)
local height = Heightmap:GetHeightInterpolated(x, z)

-- Snap a position to terrain
local snappedPos = Heightmap:SnapToTerrain(position, offsetY)
```

### Convenience Wrappers (TerrainUtils)

```lua
local TerrainUtils = Shared.TerrainUtils

-- Same as Heightmap:GetHeight()
local height = TerrainUtils.getTerrainHeight(x, z)

-- Same as Heightmap:GetHeightInterpolated()
local height = TerrainUtils.getTerrainHeightSmooth(x, z)

-- Same as Heightmap:SnapToTerrain()
local pos = TerrainUtils.snapToTerrain(position, offset)

-- Get zone name
local zone = TerrainUtils.getZone(x, z)  -- "Beach", "Valley", etc.

-- Get slope angle (degrees)
local slope = TerrainUtils.getSlopeAngle(x, z)
```

### What NOT to Do

```lua
-- WRONG: Raycasting (slow, race-condition prone)
local result = Workspace:Raycast(Vector3.new(x, 1000, z), Vector3.new(0, -2000, 0))
local height = result and result.Position.Y or 0

-- WRONG: Querying before heightmap is ready
-- (This should never happen if startup sequence is correct)
local height = Heightmap:GetHeight(x, z)  -- Returns 0 if not generated!
```

### Checking Heightmap Status

```lua
if Heightmap:IsGenerated() then
    -- Safe to query heights
end
```

## Building Placement

Buildings need flat terrain. The system provides `FlattenArea()`:

```lua
-- Flatten terrain for a building
local buildingRadius = 20  -- studs
local flatHeight = Heightmap:FlattenArea(centerX, centerZ, buildingRadius)

-- Now spawn the building at flatHeight
local building = buildingModel:Clone()
building:SetPrimaryPartCFrame(CFrame.new(centerX, flatHeight, centerZ))
building.Parent = workspace.Buildings
```

### How FlattenArea Works

1. **Calculates average height** of the area (or uses provided target height)
2. **Updates heightmap data** with smooth blend toward flat height
3. **Registers flat zone** for future queries (returns flat height within radius)
4. **Returns the height** so you know where to place the building

### TerrainGenerator Integration

For buildings that need visual terrain modification:

```lua
-- TerrainGenerator:PrepareBuilding() handles both:
-- 1. Flattening the heightmap
-- 2. Updating Roblox terrain voxels
local height = TerrainGenerator:PrepareBuilding(centerX, centerZ, sizeX, sizeZ)
```

## Heightmap Technical Details

### Grid Resolution

- **Cell size**: 4 studs (matches Roblox terrain voxel size)
- **World size**: Configurable via `Config.WORLD_SIZE`
- **Total cells**: `(WORLD_SIZE / 4)^2`

### Memory Usage

For a 4096x4096 world:
- Cells: 1024 x 1024 = 1,048,576
- Memory: ~8MB (8 bytes per Lua number)

### Height Calculation

Heights are calculated per-zone using multi-octave Perlin noise:

| Zone | Height Range | Notes |
|------|-------------|-------|
| Ocean | -10 | Ocean floor |
| Beach | 0-5 | Gentle slope |
| Coastal | 5-20 | Rolling hills |
| Valley | 20-30 | Town area |
| Fault Line | -40 to 50 | The dramatic rift |
| Forest | 50-130 | Rolling hills, trees |
| Mountains | 130-400 | Peaks, snow caps |

## Blender Integration

### Exporting Heightmap for Blender

```lua
-- Server-side: Export heightmap as PGM
local pgmData = Heightmap:ExportPGM()
-- Save to file or send to external tool
```

### Blender Import Workflow

1. Import PGM as displacement map
2. Scale to match world size
3. Generate terrain mesh
4. Export as FBX for Roblox

### Critical: Blender Mesh Must Match Heightmap

If Blender terrain doesn't match the heightmap:
- Items will float or be buried
- Use `TerrainUtils.validateTerrainAlignment()` to debug

```lua
-- Debug: Check if visual terrain matches heightmap
local aligned = TerrainUtils.validateTerrainAlignment(x, z, tolerance)
if not aligned then
    warn("Blender mesh doesn't match heightmap at", x, z)
end
```

## Raycast Fallback

For visual mesh surfaces (decorations, Blender imports), use raycasting:

```lua
-- Find actual rendered surface (not heightmap)
local visualHeight = TerrainUtils.raycastSurfaceHeight(x, z)
```

This is slower and should only be used when you specifically need the visual surface, not the gameplay terrain.

## Summary: DRY, SOLID, APIE Compliance

| Principle | How This System Complies |
|-----------|-------------------------|
| **DRY** | Single source of truth (Heightmap module) |
| **Single Responsibility** | Heightmap = height data, TerrainGenerator = visual terrain |
| **Open/Closed** | Extend via FlattenArea(), don't modify base calculation |
| **Liskov Substitution** | TerrainUtils wraps Heightmap transparently |
| **Interface Segregation** | Simple API: GetHeight(), FlattenArea(), SnapToTerrain() |
| **Dependency Inversion** | Services depend on Heightmap abstraction, not raycasting |
| **APIE** | Public API documented, internals (cell conversion) private |

## Quick Reference

```lua
-- Always safe after server starts
Heightmap:GetHeight(x, z)           -- O(1) height lookup
Heightmap:GetHeightInterpolated()   -- Smooth height
Heightmap:SnapToTerrain(pos, off)   -- Snap position
Heightmap:FlattenArea(x, z, r)      -- Flatten for building
Heightmap:GetZone(x, z)             -- Zone name
Heightmap:IsGenerated()             -- Check if ready
```
