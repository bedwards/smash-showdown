# Faultline Fear: Game Design Document

**Version**: 1.0
**Last Updated**: December 2024
**Platform**: Roblox
**Target Audience**: Teenagers (13-18)
**Genre**: Survival Horror / Exploration / Adventure

---

## Executive Summary

Faultline Fear is an earthquake-themed survival horror game set in an exaggerated California landscape. Players must survive seismic events, navigate treacherous terrain split by a massive fault line, and complete a hero's journey that leads to a definitive ending. The game emphasizes eerie liminal spaces, constant engagement through survival mechanics, and a rich visual environment that rewards exploration.

---

## Core Concept: What Makes This a GAME

A game, in its truest theoretical sense, requires:

1. **Clear Win/Loss Conditions**: Not just survival, but a definitive END state
2. **Player Agency**: Meaningful choices that affect outcomes
3. **Challenge Progression**: Escalating difficulty that tests mastery
4. **Risk/Reward Balance**: Stakes that matter
5. **Feedback Systems**: The player always knows where they stand

### The Earthquake Theme as Game Mechanic

The earthquake isn't just aesthetic - it's a core gameplay system:

- **Tremor Warning System**: Players learn to read environmental cues (bird flights, water ripples, NPC behavior) to predict quakes
- **Structural Integrity**: Buildings, bridges, and terrain can collapse during quakes - safe paths change
- **Aftershock Chains**: Major quakes trigger aftershocks - risk/reward for staying in dangerous areas
- **Fault Line Crossings**: The fault line creates a natural barrier - crossing points are high-risk, high-reward
- **Ground Liquefaction**: Certain terrain becomes deadly quicksand during quakes

---

## World Geography

### Cardinal Layout

```
                    NORTH
                      |
    +----------------------------------+
    |     MOUNTAIN RANGE (PEAKS)       | <- Continental Divide edge
    |  ================================|    Mountains cut off at world edge
    |                                  |
    |         FOREST / HILLS           |
    |                                  |
    |   ====== FAULT LINE ======       | <- Jagged rift, parallel to shore
    |                                  |
    |        VALLEY / TOWN             |
    |    [Buildings] [Buses]           |
    |                                  |
    |         COASTAL PLAIN            |
    |                                  |
    |  [Boardwalk] [Ferris Wheel]      |
    |     BEACH / SHORELINE            |
    |  ================================|
    |          OCEAN                   | <- Extends to horizon
    +----------------------------------+
    WEST                            EAST
                    SOUTH
```

### Key Zones

1. **Ocean Zone** (South Edge)
   - Water extends to world boundary
   - Swimming mechanics with stamina drain
   - Underwater secrets (collapsed pier, sunken structures)
   - Tsunami warning system during major quakes

2. **Beach/Boardwalk**
   - Abandoned amusement park vibes
   - Ferris wheel (climbable landmark/beacon)
   - Boardwalk shops (loot locations)
   - Sand liquefaction during quakes

3. **Coastal Town**
   - Main hub area
   - Abandoned buildings, buses, cars
   - NPC survivors to rescue
   - Multiple story missions start here

4. **The Fault Line** (Central Feature)
   - Jagged rift running East-West
   - Width varies (jumpable in places, impassable in others)
   - Bridge crossing points (collapse risk)
   - Steam vents and geothermal features
   - The "Big One" slowly widens it throughout the game

5. **Valley/Hills**
   - Dense vegetation overgrown on abandoned structures
   - Friendly animals by day, predators by night
   - Hidden bunkers and survival caches

6. **Mountain Range** (North Edge)
   - Peaks literally cut off by world boundary
   - Rockslide hazards
   - Cave systems
   - Final objective location (radio tower/rescue beacon)

---

## The Hero's Journey: Narrative Structure

### Act 1: Departure (The Call)
- Player wakes after "The First Quake"
- Tutorial: Basic survival (hunger, movement)
- Meet the first NPC who explains the situation
- Discover the fault line has split the region
- Objective: Reach the coastal town

### Act 2: Initiation (Trials)
- Cross the fault line for the first time
- Face day/night cycle dangers
- Rescue survivors (builds toward ending)
- Collect generator parts pieces (6 parts across zones)
- Each zone has a mini-boss or challenge (collapsed building escape, predator encounter, etc.)

### Act 3: The Ordeal (Major Quake Event)
- "The Big One" strikes
- World geometry changes permanently
- Some safe routes now blocked
- New routes opened
- Player must adapt strategies

### Act 4: Return (The Climb)
- Ascend the mountain with collected equipment
- Final challenge sequence
- Reach the radio tower
- Signal for rescue

### Act 5: Resolution (THE END)
Roblox Ending Implementation Options:
- **Badge Award**: "SURVIVOR" badge for completion
- **Credits Sequence**: Display in-game credits on a screen/billboard
- **Teleport to Victory Place**: Separate experience showing aftermath
- **Leaderboard Entry**: Completion time recorded
- **Unlockables**: New game+ mode, cosmetics
- **Definitive Screen**: "YOU SURVIVED FAULTLINE FEAR - THE END"

---

## Core Systems

### 1. Survival Mechanics

#### Hunger System
- Hunger bar depletes over time
- Running accelerates depletion
- Food sources: Abandoned stores, fruit trees, fishing, NPC traders
- Starvation causes: Slow movement, vision blur, eventual death
- **DRY Implementation**: Single `HungerService` module handles all hunger logic

#### Stamina System
- Sprinting, climbing, swimming consume stamina
- Rest to recover
- Stamina upgrades via collectibles

#### Day/Night Cycle
- **Day (6 AM - 8 PM)**: Safer exploration, friendly animals
- **Dusk (8 PM - 9 PM)**: Warning period, animals become agitated
- **Night (9 PM - 6 AM)**: Predators active, reduced visibility, NPC shops closed
- **Dawn (5 AM - 6 AM)**: Transition back to safety

### 2. Earthquake System

```lua
-- Pseudocode for earthquake events
EarthquakeService = {
    tremors = {
        minor = { magnitude = 0.3, frequency = 300, damage = "none" },
        moderate = { magnitude = 0.6, frequency = 900, damage = "minor" },
        major = { magnitude = 0.9, frequency = 3600, damage = "structural" },
        bigOne = { magnitude = 1.0, frequency = "scripted", damage = "catastrophic" }
    },

    onQuake = function(magnitude)
        -- Camera shake
        -- Sound effects
        -- Terrain deformation
        -- Structure damage check
        -- NPC reactions
        -- Player knockdown if standing
    end
}
```

### 3. Music System
- Always playing (music never stops)
- Zone-based automatic station changes
- Radio tower proximity affects reception quality
- Emergency broadcast interruptions during quakes
- Special "eerie" tracks for liminal spaces

### 4. NPC Systems

#### Friendly NPCs
- Survivors to rescue (escort missions)
- Traders (barter food, equipment)
- Quest givers
- Information providers

#### Animals
- **Day**: Deer, birds, rabbits (ambient, flees from player)
- **Night**: Wolves, coyotes (hostile, pack behavior)
- **Special**: Mountain lion (rare, dangerous any time)

#### Pet Companion
- Obtainable early game
- Follows player
- Random funny dialogue
- Gets distracted, runs off, returns
- Warns of dangers (tremors, predators)
- Cannot die (respawns at last safe point)

### 5. Signage and Guidance System

All signs follow these rules:
- **Double-sided**: Same text on front and back
- **High contrast**: Readable from distance
- **Consistent style**: Same font, colors per sign type
- **Placed at decision points**: Never in the middle of a path

Sign Types:
1. **Directional**: Points to locations
2. **Warning**: Hazard alerts
3. **Story**: Lore and narrative
4. **Objective**: Current goal reminders
5. **Tutorial**: Control hints

### 6. Visual Beacon System

Each major location has a unique beacon visible from distance:
- **Ferris Wheel**: Beach landmark (rotating lights)
- **Radio Tower**: Mountain peak (blinking red light)
- **Water Tower**: Town center (spotlight)
- **Lighthouse**: Coastal edge (sweeping beam)
- **Signal Fires**: Player-activated waypoints

---

## HUD Design

```
+--------------------------------------------------+
|  [Hunger Bar]  [Stamina Bar]                     |
|  [Compass with Objective Marker]                 |
|                                                  |
|                                                  |
|                                                  |
|                                                  |
|                                                  |
|                                                  |
|  [Current Objective Text]                        |
|  [Generator Parts: 3/6]  [Survivors: 5/10]         |
+--------------------------------------------------+
```

### HUD Elements
- **Hunger Bar**: Orange, depletes left to right
- **Stamina Bar**: Blue, shows below hunger
- **Compass**: Top center, shows N/S/E/W + objective direction
- **Objective Text**: Bottom left, current goal
- **Progress Counters**: Bottom right, collectibles status
- **Earthquake Warning**: Full-screen edge glow when tremor incoming

---

## Technical Architecture (DRY/SOLID/APIE)

### Module Structure

```
src/faultline-fear/
├── shared/
│   ├── Config.luau           -- All game constants
│   ├── Types.luau            -- Type definitions
│   ├── Utils.luau            -- Shared utility functions
│   └── Events.luau           -- Event name constants
├── server/
│   ├── Services/
│   │   ├── HungerService.luau
│   │   ├── EarthquakeService.luau
│   │   ├── DayNightService.luau
│   │   ├── NPCService.luau
│   │   ├── ObjectiveService.luau
│   │   └── MusicService.luau
│   ├── World/
│   │   ├── TerrainGenerator.luau
│   │   ├── StructureSpawner.luau
│   │   └── ResourceSpawner.luau
│   └── Main.server.luau
└── client/
    ├── Controllers/
    │   ├── HUDController.luau
    │   ├── CameraController.luau
    │   ├── InputController.luau
    │   └── AudioController.luau
    └── Main.client.luau
```

### Design Principles Applied

**Single Responsibility (S)**
- Each Service handles ONE system
- HungerService doesn't know about Earthquakes

**Open/Closed (O)**
- Services extensible via events, not modification
- New earthquake types added via config, not code changes

**Liskov Substitution (L)**
- All NPCs inherit from BaseNPC
- Any NPC can be used where BaseNPC is expected

**Interface Segregation (I)**
- Clients only receive events they need
- Server doesn't send earthquake data to players in safe zones

**Dependency Inversion (D)**
- Services depend on abstractions (Events) not concrete implementations
- Config drives behavior, not hardcoded values

**Abstraction (A from APIE)**
- Complex systems hidden behind simple interfaces
- Player calls `EatFood()`, system handles all hunger math

**Polymorphism (P from APIE)**
- Different NPC types, same interface
- Different earthquake types, same handling code

**Inheritance (I from APIE)**
- Animal -> FriendlyAnimal -> Deer
- Animal -> HostileAnimal -> Wolf

**Encapsulation (E from APIE)**
- Internal state hidden
- Only public methods exposed
- No direct variable access

---

## Blender Integration Workflow

### Assets to Create in Blender

1. **Terrain Meshes**
   - Mountain range segments
   - Fault line crack geometry
   - Rock formations
   - Cave interiors

2. **Structures**
   - Abandoned buildings (modular pieces)
   - Ferris wheel
   - Boardwalk segments
   - Bridges (intact and damaged variants)
   - Vehicles (buses, cars)

3. **NPCs**
   - Human survivors (rigged for animation)
   - Animals (deer, wolf, birds)
   - Pet companion

4. **Props**
   - Signs (various types)
   - Radio equipment pieces
   - Food items
   - Survival gear

### Export Pipeline

```bash
# Blender to Roblox workflow
1. Create model in Blender at 0.01 scale factor
2. Apply all transforms (Ctrl+A > All Transforms)
3. Triangulate mesh if needed
4. Export as FBX with scale 0.01
5. Import to Roblox via Asset Manager
6. Use Tarmac for texture/image assets
```

### LOD (Level of Detail) Strategy
- **LOD0**: Full detail (< 50 studs)
- **LOD1**: Reduced detail (50-200 studs)
- **LOD2**: Silhouette only (> 200 studs)

---

## Performance Optimization Strategy

### Key Metrics
- **Target FPS**: 60 (desktop), 30 (mobile)
- **Frame Budget**: 16.67ms per frame
- **Memory Target**: < 1GB

### Techniques

1. **Streaming Enabled**
   - Load only visible chunks
   - Aggressive culling of distant objects

2. **Instance Reuse**
   - Object pooling for projectiles, particles
   - Reuse NPC instances

3. **Terrain Optimization**
   - Use Roblox terrain for ground (not mesh)
   - Blender meshes only for unique features

4. **Script Optimization**
   - No per-frame loops where avoidable
   - Event-driven architecture
   - Debounce frequent operations

5. **Visual Optimization**
   - Limit shadow casters
   - Use decals over meshes for flat surfaces
   - Particle limits per system

### Profiling Tools
- **MicroProfiler**: Ctrl+Alt+F6 in Studio
- **Developer Console**: F9 > MicroProfiler tab
- **Stats Panel**: Alt+Shift+F7

---

## Liminal Space Aesthetic

### Visual Characteristics
- **Empty parking lots** at dusk
- **Abandoned malls** with working lights but no people
- **Hotel hallways** that seem to go on forever
- **Swimming pools** drained or stagnant
- **Schools** after hours
- **Highway underpasses** at night

### How to Achieve in Roblox
- **Lighting**: Harsh fluorescent (Color 255, 250, 240), no warmth
- **Sound**: Ambient hum, distant echoes, no music in these zones
- **Architecture**: Repetitive patterns, long corridors
- **Fog**: Light fog to obscure far walls
- **NPCs**: Absent - these spaces feel abandoned

### Integration with Earthquake Theme
- Cracks in walls reveal nothing behind them
- Exit signs point to collapsed exits
- Emergency lighting creates harsh shadows
- Aftershock sounds echo unnaturally

---

## Ground Level Elevation System

### The Problem
In Mertin-Flemmer, we had issues with items spawning below or above terrain. This MUST be solved.

### The Solution: Terrain Height Query System

```lua
-- Shared/TerrainUtils.luau
local TerrainUtils = {}

function TerrainUtils.getTerrainHeight(x: number, z: number): number
    local rayOrigin = Vector3.new(x, 1000, z)
    local rayDirection = Vector3.new(0, -2000, 0)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { workspace.Terrain }

    local result = workspace:Raycast(rayOrigin, rayDirection, params)
    if result then
        return result.Position.Y
    end
    return 0 -- Fallback to sea level
end

function TerrainUtils.isPositionAccessible(position: Vector3): boolean
    local terrainHeight = TerrainUtils.getTerrainHeight(position.X, position.Z)
    local heightDiff = math.abs(position.Y - terrainHeight)
    return heightDiff < 5 -- Within 5 studs of ground
end

function TerrainUtils.snapToTerrain(position: Vector3, offset: number?): Vector3
    local height = TerrainUtils.getTerrainHeight(position.X, position.Z)
    return Vector3.new(position.X, height + (offset or 0), position.Z)
end

return TerrainUtils
```

### Placement Validation Script (Run after world generation)

```lua
-- Lune script: validate-placements.luau
local function validateAllPlacements()
    local issues = {}

    for _, obj in workspace:GetDescendants() do
        if obj:GetAttribute("RequiresGroundContact") then
            local terrainHeight = getTerrainHeight(obj.Position.X, obj.Position.Z)
            local objBottom = obj.Position.Y - (obj.Size.Y / 2)

            if math.abs(objBottom - terrainHeight) > 2 then
                table.insert(issues, {
                    object = obj.Name,
                    position = obj.Position,
                    terrainHeight = terrainHeight,
                    issue = objBottom < terrainHeight and "BURIED" or "FLOATING"
                })
            end
        end
    end

    return issues
end
```

---

## Tooling Stack

### Currently Installed
| Tool | Version | Purpose |
|------|---------|---------|
| Aftman | 0.3.0 | Tool manager |
| Rojo | 7.7.0-rc.1 | File sync |
| Wally | 0.3.2 | Package manager |
| Selene | 0.27.1 | Linter |
| StyLua | 0.20.0 | Formatter |
| Blender | 5.0.0 | 3D modeling |

### Need to Install
| Tool | Purpose | Install Command |
|------|---------|-----------------|
| Lune | CLI Luau runtime | `aftman add lune-org/lune` |
| Remodel | Place file manipulation | `aftman add rojo-rbx/remodel` |
| Tarmac | Asset pipeline | `aftman add Roblox/tarmac` |
| run-in-roblox | Script execution | `aftman add rojo-rbx/run-in-roblox` |

### Screenshot Limitations
The roblox-screenshot tool requires:
1. Roblox Studio running and visible
2. Node.js server running
3. Lua code executed inside Studio

**Claude Code CANNOT trigger screenshots automatically.** This requires human interaction.

### What Claude Code CAN Do
- Read/write Luau code
- Run Lune scripts for validation
- Analyze place files with Remodel
- Generate reports from code analysis
- Create GitHub issues
- Sync with Rojo

### What Claude Code CANNOT Do
- See the game visually
- Take screenshots
- Run Roblox Studio
- Test gameplay directly

---

## GitHub Issue Labels for Faultline Fear

- `faultline-fear`: All issues for this project
- `world-building`: Terrain, structures, zones
- `gameplay`: Core mechanics
- `narrative`: Story, quests, dialogue
- `audio`: Music, sound effects
- `visuals`: Graphics, effects, UI
- `performance`: Optimization
- `tooling`: Development infrastructure
- `blender`: 3D asset creation
- `bug`: Something broken
- `enhancement`: Improvement to existing feature

---

## References and Sources

### Roblox Development
- [Rojo Documentation](https://rojo.space/)
- [Lune Runtime](https://github.com/lune-org/lune)
- [Remodel Tool](https://github.com/rojo-rbx/remodel)
- [Tarmac Asset Pipeline](https://github.com/Roblox/tarmac)
- [MicroProfiler Documentation](https://create.roblox.com/docs/performance-optimization/microprofiler/use-microprofiler)

### Blender to Roblox
- [Exporting 1:1 Scale Models](https://devforum.roblox.com/t/exporting-11-scale-models-from-blender-to-roblox-studio/3679265)
- [FBX Scale Settings](https://www.katsbits.com/codex/fbx-scale-roblox/)

### Game Design Theory
- [Hero's Journey in Games](https://www.gamedeveloper.com/design/using-the-hero-s-journey-in-games)
- [Narrative Design in Roblox](https://moldstud.com/articles/p-exploring-narrative-design-in-roblox-games-crafting-compelling-stories)

### Liminal Spaces
- [Liminal Spaces Aesthetic](https://aesthetics.fandom.com/wiki/Liminal_Space)

---

## Appendix: California Earthquake Facts (For Authenticity)

- San Andreas Fault: 800 miles long
- Major fault types: Strike-slip, thrust, normal
- P-waves arrive before S-waves (warning system basis)
- Liquefaction: Sandy soil becomes liquid during shaking
- Aftershock sequences can last months
- Building codes: Soft-story buildings most vulnerable
- Tsunami risk: Primarily from offshore faults

---

*This document serves as the single source of truth for Faultline Fear development. All implementation decisions should reference this document.*
