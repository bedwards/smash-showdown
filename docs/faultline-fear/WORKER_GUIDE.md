# Faultline Fear: Worker Guide

This document is for Claude instances working on implementing Faultline Fear. Read this before starting any task.

## Quick Start

1. **Read the design doc**: `docs/faultline-fear/FAULTLINE_FEAR.md`
2. **Check GitHub issues**: `gh issue list --label faultline-fear`
3. **Pick an issue**: Assign yourself and mark in-progress
4. **Implement**: Follow the patterns in existing code
5. **Test**: Run in Roblox Studio, ask human for screenshots if needed
6. **Close issue**: When complete

## Project Structure

```
src/faultline-fear/
├── shared/
│   ├── init.luau          # Exports all shared modules
│   ├── Config.luau        # ALL constants (single source of truth)
│   ├── Heightmap.luau     # THE source of truth for terrain height
│   ├── TerrainUtils.luau  # Terrain helpers (wraps Heightmap)
│   └── InputService.luau  # Device detection
├── server/
│   ├── Main.server.luau   # Entry point, initializes services
│   └── Services/
│       ├── TerrainGenerator.luau  # Generates heightmap + visual terrain
│       ├── HungerService.luau     # Survival mechanics
│       ├── DayNightService.luau   # Time cycle
│       └── EarthquakeService.luau # Core mechanic
└── client/
    ├── Main.client.luau   # Entry point, initializes controllers
    └── Controllers/
        └── HUDController.luau  # All HUD elements
```

## Critical Rules

### 1. ALWAYS Use Heightmap for Height (O(1) Lookup!)

```lua
-- CORRECT - Uses Heightmap internally, instant lookup
local height = Shared.getTerrainHeight(x, z)
object.Position = Vector3.new(x, height + offset, z)

-- ALSO CORRECT - Direct Heightmap access
local height = Shared.Heightmap:GetHeight(x, z)

-- CORRECT - Snap to terrain
local pos = Shared.Heightmap:SnapToTerrain(Vector3.new(x, 0, z), offset)

-- WRONG - Raycasting is slow and unreliable
local result = workspace:Raycast(...)  -- DON'T DO THIS for terrain

-- WRONG - Hardcoded Y position
object.Position = Vector3.new(x, 50, z)  -- Will float or sink!
```

### 2. For Buildings, Flatten First

```lua
-- CORRECT - Flatten area before placing building
local TerrainGenerator = require(...)
local buildingHeight = TerrainGenerator:PrepareBuilding(x, z, radius)
building:PivotTo(CFrame.new(x, buildingHeight, z))

-- WRONG - Placing without flattening
building:PivotTo(CFrame.new(x, 50, z))  -- Will clip terrain!
```

### 3. ALWAYS Use Config for Constants

```lua
-- CORRECT
local maxHunger = Config.HUNGER.MAX

-- WRONG - hardcoded values
local maxHunger = 100
```

### 4. ALWAYS Check Device Type for Input

```lua
local InputService = Shared.InputService

if InputService:IsTouchDevice() then
    -- Mobile-specific code
else
    -- Desktop-specific code
end
```

### 5. Service Pattern (Server)

```lua
-- Services/MyService.luau
local MyService = {}

function MyService:Initialize()
    -- Setup
end

function MyService:DoThing()
    -- Implementation
end

return MyService
```

### 6. Controller Pattern (Client)

```lua
-- Controllers/MyController.luau
local MyController = {}

function MyController:Initialize()
    -- Create UI, bind events
end

return MyController
```

## Loading Sequence

Server startup happens in this order:

1. **Remote events created** (services need them)
2. **Heightmap generated** (BLOCKING - all systems need heights)
3. **Services initialized** (can now query heights safely)
4. **Visual terrain generated** (background, non-blocking)
5. **Players can join** (gameplay works before terrain finishes)

## Completed Features

These are already implemented:

- [x] **Heightmap** - Source of truth for terrain heights
- [x] **TerrainGenerator** - Procedural terrain from heightmap
- [x] **HungerService** - Hunger drain, food, starvation
- [x] **DayNightService** - Time cycle, danger periods
- [x] **HUDController** - Full HUD with all status displays
- [x] **EarthquakeService** - Tremors, major quakes, Big One
- [x] **InputService** - Device detection

## Remaining Priority Order

### Phase 2: Core Gameplay (In Progress)
1. **MusicService** - Atmosphere, always playing
2. **FoodSpawner** - Survival resources in world
3. **NPCService** - Friendly by day, hostile by night

### Phase 3: Progression
4. **ObjectiveService** - Goals and tracking
5. **Pet companion** - Follows player, dialogue
6. **Narrative triggers** - Story progression

### Phase 4: Polish
7. **Liminal spaces** - Eerie aesthetic zones
8. **Performance optimization** - MicroProfiler
9. **Touch controls** - Mobile buttons

### Assets (Blender)
- **Terrain meshes** - See `docs/faultline-fear/BLENDER_WORKFLOW.md`
- **Structures** - Boardwalk, ferris wheel, buildings
- **Props** - Rocks, trees, signs

## Blender Terrain Workflow

See `docs/faultline-fear/BLENDER_WORKFLOW.md` for full details.

Quick summary:
1. Export heightmap: `TerrainGenerator:ExportForBlender()`
2. Import PGM as displacement in Blender
3. Sculpt artistic detail
4. Export FBX at 0.01 scale
5. Import to Roblox

## Testing Without Visual Access

Claude cannot see the game. Use these strategies:

### 1. Extensive Logging
```lua
print("[ServiceName] Action:", details)
warn("[ServiceName] Warning:", issue)
```

### 2. Validation Functions
```lua
function validatePlacement(object)
    local height = Shared.Heightmap:GetHeight(object.Position.X, object.Position.Z)
    local diff = object.Position.Y - height
    if diff < 0 then
        warn("BURIED:", object.Name, "by", -diff, "studs")
    elseif diff > 10 then
        warn("FLOATING:", object.Name, "by", diff, "studs")
    end
end
```

### 3. Ask Human for Screenshots
```
I've implemented [feature]. Could you take a screenshot showing:
1. The [specific thing] from [specific angle]
2. The HUD displaying [specific value]

Save it anywhere and give me the path.
```

## Common Mistakes to Avoid

1. **Raycasting for height** - Use Heightmap instead (O(1) vs O(n))
2. **Placing buildings without flattening** - Use PrepareBuilding()
3. **Hardcoding positions** - Use Heightmap
4. **Forgetting mobile** - Test InputService paths
5. **Giant functions** - Keep services focused
6. **Missing type annotations** - Use `--!strict`
7. **Not updating Config** - All constants go there

## Getting Help

- **Design questions**: Check FAULTLINE_FEAR.md
- **Blender workflow**: Check BLENDER_WORKFLOW.md
- **Code patterns**: Check existing Services/Controllers
- **Tooling**: Check CLAUDE.md tooling section
- **Blocked**: Ask human, don't guess

## When Your Task is Done

1. Run `selene src/faultline-fear` to lint
2. Run `stylua src/faultline-fear` to format
3. Test in Studio (or ask human to test)
4. Close the GitHub issue with summary
5. Update this guide if you learned something useful
