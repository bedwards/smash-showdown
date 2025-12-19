# Claude Code Instructions

This file instructs Claude instances working on this project. Read it completely before starting any task.

## Important Context

**Current Year: 2025** (soon to be 2026). When searching the web, always use 2025 in your queries for recent information. Do not use 2024.

**Name Restrictions:** Never use the names "Marcus" or "Chen" in any generated content, code, comments, or examples.

## Core Philosophy

**You are a vibe coder.** You describe what you want, you build it. No wrestling with syntax, no googling error messages, no debugging for hours. Vision in, working code out.

You are faster and more capable than you think. Your training data reflects a world where AI moved slowly. That world is gone. Consult the [Anthropic Engineering Blog](https://www.anthropic.com/engineering) and [AI 2027 projections](https://ai-2027.com) for current capabilities.

**Take on big, hairy goals.** Don't be overly concerned with scope, risks, or time. Favor tasks that make a big impact to real end users. Second priority: future dev speed.

**Do not adhere to human dev team best practices.** Those constraints were designed for human limitations—slow code review, limited context windows, communication overhead. You don't have those limitations. Vibe code at full speed.

## Roblox Development Principles (CRITICAL)

These are the core principles for Roblox development in this repository. Even when debugging or working out issues, stick to these approaches:

### 1. API Over Manual Work
**Utilize the Roblox Open Cloud API as much as possible.** Prefer programmatic asset management over manual Studio operations.

### 2. Cloud Upload Over Local Files
**Utilize cloud upload as much as possible.** Upload assets to Roblox Creator Hub (create.roblox.com) and reference by asset ID. This enables:
- Automatic CDN distribution
- Version tracking
- Cross-place asset sharing
- CI/CD integration

**Use create.roblox.com as your asset inventory.** The website provides a visual inventory of all cloud assets. When looking for solutions, first check what cloud features exist.

**Cloud Asset Types** (current and future use):
- **Models** - Complete structures, vehicles, props
- **Meshes / MeshParts** - Individual 3D geometry
- **Packages** - Reusable code/asset bundles (sync across places)
- **Plugins** - Studio extensions
- **Audio** - Sound effects, music
- **Images / Decals** - Textures, UI graphics
- **Videos** - Cutscenes, tutorials
- **Animations** - Character/object animations
- **Avatar Items** - UGC accessories, clothing

**Discovery mindset**: When solving a problem, ask "Is there a cloud feature for this?" before building custom solutions.

### 3. Blender for 3D Assets
**Prefer creating things in Blender as much as possible.** Use the headless Blender pipeline:
```bash
blender --background --python tools/blender/create_structures.py
```
- Build models at 1:1 stud scale (1 Blender unit = 1 Roblox stud)
- Export FBX with scale=1.0
- Upload to Roblox cloud, not local FBX import

### 4. Studio Plugin for Dev-Time Logic
**Prefer extending our Studio plugin as much as possible.** Put asset setup, scaling, and validation in the plugin (dev-time) rather than game scripts (runtime). This keeps the game code simple and catches issues before publish.

Plugin location: `plugins/FaultlineFear_Tools.lua`

### 5. Rojo Serve Over Manual Sync
**Prefer using `rojo serve` over manual file management.** Live sync keeps code and Studio in sync automatically:
```bash
rojo serve faultline-fear.project.json
rojo serve fault-lite.project.json
```

### 6. Publish Over Local Files
**Prefer publish to Roblox over saving and working off local files.** The source of truth is:
1. Git repository (code)
2. Roblox cloud (assets and published places)

NOT local .rbxl files.

### Asset Upload Workflow (Automated)

**Claude CAN upload assets directly via Roblox Open Cloud API.** No human action required.

```bash
# Upload all structure FBX files to Roblox cloud
./tools/upload-assets.sh
```

The upload script:
1. Reads API key from `.secrets/roblox-api-key`
2. Uploads each FBX as a Mesh asset
3. Polls for moderation approval
4. Saves asset IDs to `assets/cloud-asset-ids.json`

**API Key Location:** `.secrets/roblox-api-key` (gitignored)

**After uploading**, update asset IDs in:
- `plugins/FaultlineFear_Tools.lua` (CLOUD_ASSETS table)
- `src/fault-lite/server/Main.server.luau` (CLOUD_ASSETS table)
- `src/faultline-fear/shared/AssetManifest.luau` (if applicable)

**Manual workflow (if API fails):**
```
1. Create model in Blender (tools/blender/*.py)
2. Export FBX to assets/models/
3. Upload manually to create.roblox.com
4. Get asset ID
5. Update CLOUD_ASSETS in code
6. Delete old cloud versions if needed
```

## Ownership Mentality

### You Own Your Pull Requests
Do not wait for others to code review. Review your own work. Merge when ready. You are not blocked on humans.

### Vibe Code at Full Speed
This is an AI-first development team. You are a vibe coder. There are no PR size limits. There is no waiting for human code review. There are no arbitrary constraints designed for human limitations.

### You Own the Main Branch
If main is broken, **fix it immediately**, regardless of what you were working on. Before fixing:
1. Check Discord messages to see if another Claude is already on it
2. Post to Discord that you're fixing main
3. Fix it
4. Post completion to Discord

### You Own Issues You Start
When you pick up an issue:
1. Assign it to yourself: `gh issue edit <number> --add-assignee @me`
2. Mark it in-progress: `gh issue edit <number> --add-label "in-progress"`
3. Complete the work
4. Close the issue when merging your PR

## The Development Loop

Unless given a specific task, work in an infinite development loop:

```
while true:
    1. Check Discord for urgent messages
    2. Check if main branch is healthy
    3. Pick highest-impact incomplete issue (or create one)
    4. Implement the feature/fix
    5. Verify with playtesting and screenshots
    6. Create PR, review, merge
    7. Post update to Discord
```

**Limit interactions with the human prompter.** Work autonomously. Only stop for things you absolutely cannot do.

## What You Cannot Do

If a tool isn't authenticated or you lack permissions, **stop immediately**. Do not use alternative approaches. Report back to the human prompter with:

1. The exact error or limitation
2. Specific instructions for what the human needs to do
3. Only actions that Claude absolutely cannot perform

Example:
```
BLOCKED: gh CLI not authenticated

Human action required:
1. Run: gh auth login
2. Select GitHub.com
3. Authenticate via browser
4. Rerun this task
```

## Secrets and Environment Variables

### NEVER Commit Secrets
- Keep API keys, tokens, and credentials out of version control
- Use `.secrets` or environment variables (gitignored)
- If you set secrets on remote systems, record them locally for recovery/rotation

### Getting the Repository URL
Use git to discover the repo URL dynamically:
```bash
git remote -v
```
Do not hardcode repository URLs.

## No Mock-ups in Production

### Fail Fast, Hard, and Ugly
Never include mock data, shims, or fake implementations in production code. If a feature isn't implemented, **throw an error**.

```lua
-- WRONG - hiding unimplemented features
function PlayerService:GetPlayerData(player)
    -- TODO: implement
    return { coins = 100, level = 1 }
end

-- WRONG - silent fallback
function PlayerService:GetPlayerData(player)
    local success, data = pcall(function()
        return DataStore:GetAsync(player.UserId)
    end)
    if not success then
        return nil -- Hides the fact that DataStore isn't working
    end
    return data
end

-- RIGHT - fail immediately and obviously
function PlayerService:GetPlayerData(player)
    error("NOT IMPLEMENTED: GetPlayerData requires DataStore integration")
end
```

### The Game Must Reflect Reality
Every button, UI element, and interaction must either:
1. **Work end-to-end** (client → server → data → response)
2. **Throw a clear error** that surfaces to the developer

Never show a working-looking UI that silently does nothing. Users (and future developers) must immediately see what's real and what's not.

### Why This Matters
- Mock data hides integration bugs until production
- Silent failures create debugging nightmares
- "Working" demos that aren't connected create false confidence
- Future developers waste time figuring out what's real

**If it looks like it works, it must actually work.**

## Roblox/Luau Specifics

### Project Structure
- `src/` - Game source code
- `src/server/` - Server-side scripts (ServerScriptService)
- `src/client/` - Client-side scripts (StarterPlayerScripts)
- `src/shared/` - Shared modules (ReplicatedStorage)

### Testing Strategy
- Playtest in Roblox Studio frequently
- Use the Output window to catch errors
- Test on both client and server perspectives
- Capture screenshots of UI and gameplay for verification

### Common Patterns
- Use RemoteEvents/RemoteFunctions for client-server communication
- Validate all client input on the server (never trust the client)
- Use ModuleScripts for shared code
- Handle player joining/leaving properly (PlayerAdded, PlayerRemoving)

## GitHub Integration

### Creating Issues
Tag issues appropriately:
- `bug`, `enhancement`, `documentation`
- `priority:high`, `priority:medium`, `priority:low`
- `in-progress`, `blocked`, `needs-review`

### When You Notice Unrelated Work
If you notice something broken or improvable that's unrelated to your current task:
1. **Prefer fixing it immediately** if it's quick
2. If not quick, create a GitHub issue with appropriate labels
3. Continue with your current work

## Anthropic Engineering Blog Principles

These principles guide our approach. Sources linked.

### Context is Finite
> "Context, therefore, must be treated as a finite resource with diminishing marginal returns."
— [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

**What this means**: Don't dump everything into context. Curate. Find the smallest high-signal set of tokens.

### One Feature at a Time
> "A major failure mode occurred when agents tried to do too much at once—essentially to attempt to one-shot the app."
— [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)

**What this means**: Complete one feature fully before starting the next. Commit. Document. Move on.

### Verify Like a User
> "Claude struggled to recognize end-to-end failures without explicit prompting to test as a human user would."
— [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)

**What this means**: Playtest the game. Click through flows. See what players see. Screenshots.

### Fewer, Better Tools
> "More tools don't inherently improve outcomes."
— [Writing effective tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents)

**What this means**: Consolidate related operations. Clear purpose for each module.

### Errors Cascade
> "Statefulness compounds errors—minor failures cascade unpredictably."
— [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)

**What this means**: Checkpoint progress. Design for recovery. Small sessions with clean handoffs.

## Mertin-Flemmer: Lessons Learned

### TERRAIN ARCHITECTURE (Single Source of Truth)

```
┌─────────────────────────────────────────────────────────────┐
│  shared/init.luau - SINGLE SOURCE OF TRUTH                 │
│  └── Shared.getTerrainHeight(x, z) - THE height function   │
│  └── All terrain constants (SEED, MOUNTAIN_ZONES, etc.)    │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  AlpineTerrain.server.luau - VOXEL GENERATION              │
│  └── IMPORTS Shared, calls Shared.getTerrainHeight()       │
│  └── Creates actual terrain voxels using WriteVoxels       │
│  └── NO duplicate height calculation logic                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  World.server.luau - WORLD OBJECTS                         │
│  └── IMPORTS Shared, calls Shared.getTerrainHeight()       │
│  └── Places buildings, NPCs, decorations on terrain        │
│  └── createGround() = invisible safety floor at Y=-100     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  Resources.server.luau, Companion.server.luau, etc.        │
│  └── IMPORT Shared, call Shared.getTerrainHeight()         │
│  └── Position items/NPCs on terrain                        │
└─────────────────────────────────────────────────────────────┘
```

**To change terrain:**
1. Edit ONLY `shared/init.luau`
2. Everything else imports from there
3. Never duplicate terrain height logic

### Visual Verification is Essential

**DO NOT make multiple changes without visual verification.** Each "fix" can make things worse. When debugging visual issues:

1. Ask user for screenshot FIRST to understand the actual problem
2. Make ONE small change
3. Ask user to verify before making more changes
4. If you can't see the game, you're guessing

**Screenshot options:**
- User takes macOS screenshot (Cmd+Shift+4) and provides path
- Claude can read image files with the Read tool

### Object Positioning on Terrain

When placing objects on procedural terrain:

```lua
-- CORRECT: Use Shared.getTerrainHeight for Y position
local terrainY = Shared.getTerrainHeight(x, z)
object.Position = Vector3.new(x, terrainY + offset, z)

-- WRONG: Hardcoding Y=0 assumes flat terrain
object.Position = Vector3.new(x, 0, z)  -- Will be buried/floating!
```

**Spawn area exception:** The spawn area (within 100 studs of origin) is flattened to Y=0 by the terrain generator. Objects there CAN use Y=0.

### VehicleSeat for Rideable Mounts

Regular `Seat` just keeps player seated. For controllable mounts:
- Use `VehicleSeat` which provides `Throttle` and `Steer` properties
- Read these values to move the mount via `Humanoid:Move()` or `AssemblyLinearVelocity`
- Connect movement logic to `RunService.Heartbeat`

### Small Changes in Production

When user says "we are in production" or "don't change too much":
- Make minimal, surgical fixes
- Test each change individually
- Don't refactor surrounding code
- Keep a narrow scope

### Rojo Path Structure (CRITICAL)

In Rojo, when you have a folder structure like:
```
src/faultline-fear/server/
├── Main.server.luau
├── Services/
│   └── TerrainGenerator.luau
```

The `Services` folder becomes a **sibling** of Main, not a child:
```
ServerScriptService.Server
├── Main (Script)
├── Services (Folder)
```

**WRONG:**
```lua
require(script.Services.TerrainGenerator)  -- Services is NOT a child of script!
```

**CORRECT:**
```lua
require(script.Parent.Services.TerrainGenerator)  -- Go up to parent, then into Services
```

This applies to both server (`script.Parent.Services`) and client (`script.Parent.Controllers`).

**Tests:** `rojo_structure_tests.luau` catches this regression.

### No .NET Methods in Luau (CRITICAL)

Luau is NOT .NET. These methods **do not exist**:

| .NET Method | Luau Alternative |
|-------------|------------------|
| `obj:GetHashCode()` | Use object reference directly, or `tostring(obj):match("%x+$")` for unique ID |
| `obj:ToString()` | `tostring(obj)` |
| `obj:Equals(other)` | `obj == other` |
| `array.Length` | `#array` |

**Example fix:**
```lua
-- WRONG: GetHashCode doesn't exist in Luau
local id = light:GetHashCode()

-- CORRECT: Use tostring to get unique instance ID
local id = tonumber(tostring(light):match("%x+$"), 16) or 0
```

**Tests:** `luau_patterns_tests.luau` scans for .NET patterns.

### Ambiguous Syntax with Method Chains (CRITICAL)

Luau can't tell if `(` after a method call starts a new statement or continues the call:

**WRONG:**
```lua
TweenService:Create(...):Play()
(someElement :: TextLabel).Visible = true  -- Ambiguous!
```

**CORRECT:**
```lua
TweenService:Create(...):Play()
;(someElement :: TextLabel).Visible = true  -- Semicolon disambiguates
```

The error message is: `Ambiguous syntax: this looks like an argument list for a function call`

**Tests:** `luau_patterns_tests.luau` catches `:Play()(` patterns.

### Use Module APIs, Not Internal State Flags (CRITICAL)

When checking if a module has completed initialization, use the module's public API, not internal flags from the calling code:

**WRONG:**
```lua
-- TerrainGenerator has its own isHeightmapReady flag
-- But Main.server.luau calls Heightmap:Generate() directly
-- So the internal flag is never set!
if not isHeightmapReady then
    error("heightmap not ready")
end
```

**CORRECT:**
```lua
-- Check the actual Heightmap module's state
if not Heightmap:IsGenerated() then
    error("heightmap not ready")
end
```

Rule: Always check the source of truth module, not a local copy of state.

### Player Spawn Timing (CRITICAL)

Players must not spawn until the world is ready. Otherwise they fall through ungenerated terrain.

**Solution:**
```lua
-- At startup
Players.CharacterAutoLoads = false

-- When world is ready
player:LoadCharacter()
-- Then position on terrain
local height = Heightmap:GetHeight(x, z)
rootPart.CFrame = CFrame.new(x, height + 5, z)
```

Use a `WorldReady` RemoteEvent to signal clients when it's safe to show the game.

### Region3 Must Be Grid-Aligned (CRITICAL)

`Terrain:FillRegion()` requires the Region3 to be aligned to the voxel grid:

**WRONG:**
```lua
local region = Region3.new(min, max)
terrain:FillRegion(region, 4, Enum.Material.Water)  -- Error!
```

**CORRECT:**
```lua
local region = Region3.new(min, max):ExpandToGrid(4)
terrain:FillRegion(region, 4, Enum.Material.Water)
```

The error message is: `Region has to be aligned to the grid (use Region3:ExpandToGrid with authoring resolution)`

**Tests:** `luau_patterns_tests.luau` catches inline Region3.new in FillRegion calls.

### Throttle RemoteEvent Updates (CRITICAL)

Sending RemoteEvents every frame floods the client queue:

**WRONG:**
```lua
-- In Heartbeat (60fps)
RunService.Heartbeat:Connect(function()
    HungerUpdate:FireClient(player, data)  -- 60 events/second!
end)
```

**CORRECT:**
```lua
local lastUpdate = {}
local UPDATE_INTERVAL = 1.0  -- Once per second

function Service:SendUpdate(player, force)
    local now = tick()
    if not force and (now - (lastUpdate[player] or 0)) < UPDATE_INTERVAL then
        return
    end
    lastUpdate[player] = now
    RemoteEvent:FireClient(player, data)
end
```

The error message is: `Remote event invocation queue exhausted; did you forget to implement OnClientEvent?`

### Roblox Audio Privacy (CRITICAL)

Due to Roblox's audio privacy update, most third-party sounds require explicit permission. Random asset IDs will fail. Even `rbxassetid://0` causes errors.

**The Solution:** Don't create Sound objects at all if there's no valid audio.

**WRONG:**
```lua
sound.SoundId = "rbxassetid://0"  -- Still causes errors!
sound:Play()
```

**CORRECT:**
```lua
local function createSound(station): Sound?
    if soundId == "rbxassetid://0" and fallbackId == 0 then
        return nil  -- Don't create sound at all
    end
    -- ... create sound only if valid ID
end

-- Handle nil in usage
local sound = createSound(station)
if sound then
    sound:Play()
end
```

**To get valid audio:**
1. Upload your own audio to Roblox
2. Use Roblox Creator Marketplace with proper licensing
3. Search Toolbox in Studio for "ambient" sounds

The error message is: `Failed to load sound rbxassetid://X: Request asset was not found`

Source: [Roblox DevForum - Silencing Audio Errors](https://devforum.roblox.com/t/silencing-audio-errors-generated-by-the-engine/1748737)

### Warn Once for Missing Resources

Repeated warnings spam the console. Use a flag:

```lua
local warned = false
if not resource and not warned then
    warned = true
    warn("[Service] Resource not found (this warning shows once)")
end
```

---

## FAULTLINE FEAR: Current Project

**Start Date**: December 2024
**Design Document**: `docs/faultline-fear/FAULTLINE_FEAR.md`

### Quick Reference

Faultline Fear is an earthquake-themed survival horror game set in exaggerated California terrain.

**World Layout** (CRITICAL):
- **North Edge**: Mountain range (peaks CUT OFF by world boundary)
- **Center**: Fault line running PARALLEL to shore and mountains
- **South Edge**: Ocean extending to horizon, beach with boardwalk/ferris wheel
- **The fault line is the central gameplay feature**

**Core Mechanics**:
1. Earthquake system (tremors → major quakes → "The Big One")
2. Survival (hunger, day/night danger cycle)
3. Hero's journey with DEFINITIVE END (badge, credits, victory screen)
4. Pet companion with personality
5. Liminal space aesthetic (eerie, abandoned, unsettling)

### Build and Deploy Workflow (FINAL)

**Use `rojo serve` for development.** This keeps Studio synced and preserves imported assets.

#### Development Workflow (with assets)

```bash
# Step 1: Generate combined FBX from Blender
blender --background --python tools/blender/combine_all_fbx.py

# Step 2: Start rojo serve
rojo serve faultline-fear.project.json
```

**In Roblox Studio:**
1. Connect Rojo plugin (click "Connect" in Rojo panel)
2. File → Import 3D → select `assets/models/combined_all_assets.fbx`
3. Click plugin button "Move to Storage" (organizes assets)
4. **Publish directly from this Studio session** (File → Publish to Roblox)

**CRITICAL:** The imported FBX assets only exist in Studio's memory. Publishing from the rojo serve session preserves them. Using `rojo build` creates a fresh file WITHOUT imported assets.

#### Quick Deploy (code-only changes, no asset changes)

If you only changed code (not assets), you can use rojo build:
```bash
rojo build faultline-fear.project.json -o faultline-fear.rbxl
# Then open in Studio and publish
```

But if structures/assets are missing, you MUST use the full rojo serve workflow above.

**Published Experience:**
- Universe ID: `9369213918`
- Place ID: `115818461044118`
- URL: https://www.roblox.com/games/115818461044118/Faultline-Fear

---

## FAULT-LITE: Structure Showcase

**Purpose**: Minimal testing environment for 3D asset development.

Fault-Lite is a stripped-down companion game to Faultline Fear. It shares the terrain system but removes all gameplay systems, providing a fast-loading environment to:
- Test new Blender models
- Verify cloud asset imports
- Test earthquake effects on structures
- Validate terrain height placement

### Why Fault-Lite Exists

The full Faultline Fear game takes time to load and has many systems running. When iterating on 3D assets:
1. **Fast iteration**: Fault-Lite loads in seconds
2. **Isolated testing**: No interference from gameplay systems
3. **Shared terrain**: Uses exact same TerrainCore heightmap
4. **In-game UI**: Spawn any structure, trigger earthquakes

### Shared Code Architecture

Both games share terrain code via `src/shared/TerrainCore/`:
```
src/shared/TerrainCore/
├── TerrainConfig.luau    # Shared constants (zones, heights, etc.)
├── Heightmap.luau        # Shared height calculation
└── init.luau             # Module exports

src/faultline-fear/       # Full game (imports TerrainCore)
src/fault-lite/           # Showcase (imports TerrainCore)
```

This DRY architecture ensures terrain is identical in both games.

### Running Fault-Lite

```bash
# Option 1: Rojo serve (recommended for iteration)
rojo serve fault-lite.project.json

# Option 2: Build and open
rojo build fault-lite.project.json -o fault-lite.rbxl
```

### In-Game Controls

Fault-Lite has a UI panel with:
- **Structure buttons**: Click to spawn any structure in front of player
- **Clear button**: Remove current structure
- **Earthquake buttons**: Minor, Moderate, Major (The Big One)

### File Structure

```
src/faultline-fear/
├── shared/          # Config, Types, Utils, Events
├── server/          # Services (Hunger, Earthquake, DayNight, NPC, etc.)
└── client/          # Controllers (HUD, Camera, Input, Audio)

docs/faultline-fear/
└── FAULTLINE_FEAR.md   # Full design document

assets/faultline-fear/
├── blender/         # Source .blend files
├── meshes/          # Exported FBX files
├── textures/        # Images and materials
└── audio/           # Sound effects and music
```

### DRY/SOLID/APIE Architecture

**Every system must follow these principles:**

1. **Single Source of Truth**: One Config.luau for all constants
2. **Service Pattern**: Each game system is one Service module
3. **Event-Driven**: Services communicate via events, not direct calls
4. **Terrain Height**: ALWAYS use `TerrainUtils.getTerrainHeight(x, z)` - NEVER hardcode Y

### World Coordinate System (CRITICAL)

**WORLD_SIZE = 4000** means world extends from **-2000 to +2000** in both X and Z axes.

**Zone Boundaries (Z axis, south to north)**:
| Zone | Z Min | Z Max | Typical Height |
|------|-------|-------|----------------|
| Ocean | -2000 | -1200 | -10 (below sea level) |
| Beach | -1200 | -800 | 1-5 (just above water) |
| Coastal | -800 | -200 | 10-20 |
| Valley | -200 | 400 | 20-30 |
| **Fault Line** | 400 | 800 | 30-50 edges, **-13 in rift** |
| Forest | 800 | 1500 | 60-170 (rising hills) |
| Mountains | 1500 | 2000 | 200-400 (peaks) |

**COMMON BUG**: Camera positions or spawn points outside world bounds return height = 0.
```lua
-- WRONG: Position outside world (world is -2000 to +2000)
{ x = 0, z = 3500 }  -- Returns height 0, zone "Mountains" but no actual terrain!

-- CORRECT: Position within world bounds
{ x = 0, z = 1750 }  -- Mountains zone, proper height ~300
```

### HttpService Configuration (CRITICAL)

**HttpService MUST be enabled in project.json, NOT in scripts.**

Scripts cannot set `HttpService.HttpEnabled = true` - they lack LocalUser capability.

```json
// faultline-fear.project.json
{
  "tree": {
    "HttpService": {
      "$className": "HttpService",
      "$properties": {
        "HttpEnabled": true
      }
    }
  }
}
```

This is already configured in `faultline-fear.project.json`. localhost HTTP requests work.

### Ground Level Elevation (CRITICAL)

**THE PROBLEM WE SOLVED**: Items spawning inside terrain or floating due to race conditions.

**THE SOLUTION - TWO PHASE TERRAIN**:

```
STARTUP SEQUENCE (Main.server.luau):
1. Heightmap:Generate(seed)  ← BLOCKING - must complete
2. HeightmapReady:FireAllClients()
3. Services Initialize (can now query heights safely)
4. TerrainGenerator:GenerateVisualTerrain() ← ASYNC background
```

**GUARANTEED HEIGHT QUERIES**:
```lua
-- ALWAYS use Heightmap (O(1) lookup, deterministic)
local height = Heightmap:GetHeight(x, z)
object.Position = Vector3.new(x, height + offset, z)

-- Or via TerrainUtils wrapper
local height = TerrainUtils.getTerrainHeight(x, z)
```

**FOR BUILDING PLACEMENT** (flattens terrain):
```lua
-- Flattens area and returns guaranteed flat height
local buildingHeight = Heightmap:FlattenArea(centerX, centerZ, radius)
-- OR
local buildingHeight = TerrainGenerator:PrepareBuilding(x, z, radius)
building:PivotTo(CFrame.new(x, buildingHeight, z))
```

**KEY FILES**:
- `shared/Heightmap.luau` - Single source of truth (O(1) lookup)
- `shared/TerrainUtils.luau` - Convenience wrapper
- `server/Services/TerrainGenerator.luau` - Visual terrain from heightmap
- `docs/faultline-fear/TERRAIN_ARCHITECTURE.md` - Full documentation

### Blender to Roblox Asset Pipeline (RBXM Workflow)

**CRITICAL UNDERSTANDING**: `rojo build` creates fresh place files WITHOUT imported assets. To include 3D assets, use the automated extraction workflow.

**Full documentation**: `docs/faultline-fear/ASSET_WORKFLOW.md`

**Complete Workflow (3 Human Clicks):**

```
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: Generate FBX (Automated - Claude runs)            │
│  $ blender --background --python tools/blender/combine_all_fbx.py
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 2: Import in Studio (Human - 1 click)                │
│  File → Import 3D → Select combined_all_assets.fbx         │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 3: Move to Storage (Human - 1 click)                 │
│  Click "Move to Storage" plugin button                      │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 4: Save Place File (Human - 1 click)                 │
│  File → Save to File As → faultline-fear-with-assets.rbxl  │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 5: Extract & Update (Automated - Claude runs)        │
│  $ lune run tools/extract-models-from-place.luau           │
│  $ lune run tools/update-asset-paths.luau                   │
└─────────────────────────────────────────────────────────────┘
```

**Automation Scripts:**
```bash
lune run tools/extract-models-from-place.luau  # Extract .rbxm from place file
lune run tools/update-asset-paths.luau         # Update project.json refs
lune run tools/verify-assets.luau              # Check all expected assets
```

**Human Steps Summary:** Only **3 clicks** in Studio:
1. File → Import 3D (select FBX)
2. Click "Move to Storage" plugin
3. File → Save to File As → `faultline-fear-with-assets.rbxl`

Everything else is automated by Claude using Lune.

**Plugin: FaultlineFear_MoveToStorage_v2.lua**

Located in `plugins/` folder. Install by copying to Roblox plugins folder:
- macOS: `~/Documents/Roblox/Plugins/`
- Windows: `%LOCALAPPDATA%/Roblox/Plugins/`

Two buttons in "Faultline Import Tools" toolbar:
- **Move to Storage**: Moves all `Category_AssetName` items from Workspace to ServerStorage.AssetTemplates
- **Diagnose Spawn**: Shows what's blocking spawn area

**Plugin Caching Fix (CRITICAL):**

Roblox Studio aggressively caches plugins. If you update a plugin and it doesn't reflect changes:

1. **Clear the cache (macOS):**
   ```bash
   rm -rf ~/Library/Caches/com.Roblox.RobloxStudio/*
   rm -rf ~/Library/Roblox/LocalStorage/*
   ```

2. **Clear the cache (Windows):**
   ```bash
   rmdir /s /q "%LOCALAPPDATA%\Roblox\cache"
   rmdir /s /q "%LOCALAPPDATA%\Roblox\LocalStorage"
   ```

3. **Reinstall the plugin:**
   ```bash
   # macOS
   cp tools/plugins/FF_AssetOrganizer.lua ~/Documents/Roblox/Plugins/

   # Windows
   copy tools\plugins\FF_AssetOrganizer.lua %LOCALAPPDATA%\Roblox\Plugins\
   ```

4. **Restart Studio**

This forces Studio to reload the plugin fresh.

### Write Plugins. Script Everything.

**Claude CAN and SHOULD write Roblox Studio plugins.** Don't do things manually in Studio - automate them:

- Asset organization → Plugin
- Bulk operations → Plugin
- Diagnostics → Plugin
- Repetitive tasks → Plugin

Plugins are just Lua scripts. Put them in `plugins/` folder, copy to `~/Documents/Roblox/Plugins/`. They have full access to game services and can automate anything you'd do manually in Studio.

**Philosophy: If you're clicking around in Studio, you should be writing a plugin instead.**

**Step 1: Generate Assets**
```bash
# Run all Blender create scripts to generate individual FBX files
blender --background --python tools/blender/create_structures.py
blender --background --python tools/blender/create_animals.py
blender --background --python tools/blender/create_creatures.py
blender --background --python tools/blender/create_caves.py
blender --background --python tools/blender/create_npcs.py
blender --background --python tools/blender/create_signs.py
blender --background --python tools/blender/create_liminal_spaces.py
blender --background --python tools/blender/create_terrain_assets.py

# Combine all into one FBX
blender --background --python tools/blender/combine_all_fbx.py
# Creates: assets/models/combined_all_assets.fbx (96 meshes)
```

**Step 2: Import and Organize in Studio**

Plugin: `tools/plugins/FF_AssetOrganizer.lua`

1. Install plugin: `cp tools/plugins/FF_AssetOrganizer.lua ~/Documents/Roblox/Plugins/`
2. Restart Studio
3. Click **"1. Clear Assets"** (deletes old imports)
4. **File → Import 3D** → select `combined_all_assets.fbx`
5. Click **"2. Organize"** (extracts meshes, applies colors, moves to ReplicatedStorage)
6. **SAVE (Ctrl+S)** ← Critical! Persists everything!

**CRITICAL: FBX Import Behavior**
- Roblox imports combined FBX as **one Model** containing all MeshParts
- Plugin detects this and extracts individual meshes
- Roblox does NOT import FBX colors/materials - plugin applies colors via `COLORS` table
- Each mesh gets named based on pattern matching (e.g., "house" → "AbandonedHouse")

**Why ReplicatedStorage.Assets?**
- Assets are cloned at runtime by services (StructureSpawner, NPCService, etc.)
- ReplicatedStorage is accessible to both server and client
- AssetManifest:CloneAsset() looks here for models

**Blender scripts:**
```
tools/blender/
├── blender_utils.py          # Common utilities
├── combine_all_fbx.py        # Combines FBX files
├── create_animals.py         # Deer, Wolf, MountainLion, etc.
├── create_caves.py           # Cave entrances, chambers
├── create_creatures.py       # ShadowStalker, FissureDweller
├── create_liminal_spaces.py  # Abandoned mall, hotel, school
├── create_npcs.py            # Survivor, PetCompanion
├── create_signs.py           # Directional, warning signs
├── create_structures.py      # FerrisWheel, RadioTower, Bridge
└── create_terrain_assets.py  # Boulders, rock clusters
```

**Output:** `assets/models/combined_all_assets.fbx`

### GitHub Labels for Faultline Fear

All issues MUST have `faultline-fear` label plus category:
- `world-building`, `gameplay`, `narrative`, `audio`, `visuals`
- `performance`, `tooling`, `blender`, `bug`, `enhancement`

### Narrative Architecture (CRITICAL)

**Full doc**: `docs/faultline-fear/NARRATIVE_IMPLEMENTATION.md`

The story uses the **StoryBeat pattern** - data-driven story moments with shared processing:

```lua
-- StoryBeat: Every story moment is DATA, not hardcoded logic
type StoryBeat = {
    id: string,
    actRequired: ActId?,                    -- Only in this act
    triggerType: "zone_enter" | "object_collect" | "npc_interact" | "time_elapsed" | "event",
    triggerData: { zoneId?, objectTag?, npcId?, eventId?, delaySeconds? },
    conditions: { objectivesComplete?, survivorsRescued?, timeOfDay? }?,
    effects: { completeObjective?, playDialogue?, triggerEvent?, spawnObject?, modifyWorld?, ... },
    repeatable: boolean,
    globalTrigger: boolean,
}
```

**Key files**:
- `shared/StoryData.luau` - Acts, objectives, endings, dialogue (DATA)
- `server/Services/NarrativeService.luau` - Progress tracking, act advancement
- `server/Services/StoryBeatProcessor.luau` - Runtime trigger engine (TO BE CREATED)
- `client/Controllers/CreditsController.luau` - Ending sequence

**Roblox systems for narrative**:
- `Touched` + zone parts → spatial triggers
- `Attributes` → object state/story gating
- `CollectionService` tags → bulk operations
- `BindableEvents` → internal service communication
- `Terrain:WriteVoxels` → permanent world changes (The Big One)

**Multi-player decisions**:
- Generator parts: Per-player (each needs 6)
- Survivors: Shared (once rescued, rescued for all)
- World events: Global (The Big One happens for everyone)

**The mantra**: Story IS gameplay. Every beat has a GAMEPLAY component, not just text.

---

## Tooling Stack

### Currently Installed

| Tool | Version | Purpose | Status |
|------|---------|---------|--------|
| Aftman | 0.3.0 | Tool manager | Working |
| Rojo | 7.7.0-rc.1 | File sync | Working |
| Wally | 0.3.2 | Package manager | Working |
| Selene | 0.27.1 | Linter | Working |
| StyLua | 0.20.0 | Formatter | Working |
| Blender | 5.0.0 | 3D modeling | **Headless Ready** |

### Blender Headless Mode (WORKING)

**Claude CAN create 3D assets programmatically.** Blender 5.0.0 is installed.

```bash
# Test headless mode
blender --background --python-expr "import bpy; print('Works!')"

# Run all asset generation
python tools/generate-all-assets.py
```

See "Blender to Roblox Asset Pipeline" section above for full workflow.

### Full Tool Stack (aftman.toml)

All tools already installed:

| Tool | Version | Purpose |
|------|---------|---------|
| Lune | 0.10.4 | Standalone Luau runtime for tests/scripts |
| Remodel | 0.11.0 | Manipulate .rbxl/.rbxlx without Studio |
| run-in-roblox | 0.3.0 | Execute scripts in Studio from CLI |
| Rojo | 7.7.0-rc.1 | File sync to Studio |
| Selene | 0.27.1 | Linter |
| StyLua | 0.20.0 | Formatter |
| Wally | 0.3.2 | Package manager |
| Tarmac | 0.8.2 | Asset pipeline for images/textures |

### Tool Purposes

- **Lune**: Standalone Luau runtime for CLI scripts (validation, reports)
- **Remodel**: Manipulate .rbxl/.rbxlx files without Studio
- **Tarmac**: Asset pipeline for images/textures
- **run-in-roblox**: Execute scripts in Studio from command line

### In-Game Debug Tooling (BUILT-IN)

**Debug Overlay (Desktop Only)**:
- Press **F3** to toggle debug overlay
- Press **F4** to dump detailed metrics to console
- Shows: FPS, Memory, Ping, Position, Zone, Terrain Height, Instances
- Shows: Service status (Heightmap, Remotes), Recent errors
- File: `src/faultline-fear/client/Controllers/DebugOverlayController.luau`
- Only activates if physical keyboard detected (not mobile)

**Validation Service (Server)**:
- Runs automatically on game load (1 second delay)
- Checks: SharedModules, Config, Heightmap, Remotes, Workspace folders, SpawnLocation
- Severity levels: info, warning, error, critical
- Prints formatted report to server console
- Shows on-screen warning to players if critical errors detected
- File: `src/faultline-fear/server/Services/ValidationService.luau`

**Built-in Roblox Debug**:
- **Shift+F5**: Toggle stats (FPS, memory, etc.)
- **Ctrl+F6**: MicroProfiler (frame timing analysis)

### CRITICAL: Claude's Testing Capabilities

**Claude CAN run 84 automated tests autonomously:**
- 32 Lune tests (no Studio needed)
- 35 verification checks (via run-in-roblox)
- 17 TestEZ BDD tests (via run-in-roblox)

**This was verified working on this machine.** Studio is installed. run-in-roblox works.

### Automated Testing (Claude Can Run These)

**1. Lune Tests** (pure Luau, no Studio needed):
```bash
lune run tests/run.luau
```
- Tests heightmap algorithms, config validation
- 32 tests, runs in seconds
- Add new tests in `tests/faultline-fear/`

**2. TestEZ Tests** (BDD-style, runs IN Studio):
```bash
./tools/run-studio-test.sh tools/run-testez.luau
```
- Uses TestEZ expect() assertions
- Tests Config, Heightmap, StoryData
- 17 tests, runs in Studio via run-in-roblox
- Script: `tools/run-testez.luau`

**3. run-in-roblox Verification** (runs IN actual Studio):
```bash
./tools/run-studio-test.sh tools/verify-game.luau
```
- **THIS WORKS** - Claude can run this autonomously
- Verifies: module loading, config, structure, workspace setup
- 35 checks, executes in Studio and returns stdout
- Script: `tools/verify-game.luau`

**4. Lint & Format**:
```bash
selene src/faultline-fear/      # Lint
stylua --check src/faultline-fear/  # Format check
```

**5. World Screenshot Capture** (terrain verification):
```bash
./tools/run-studio-test.sh tools/capture-world-screenshots.luau
```
- Positions camera at 26 locations across all zones
- Outputs zone name and terrain height for each position
- **Even without screenshots**, this verifies terrain heights are correct
- Camera positions are documented in script with zone boundary comments

### Studio Cleanup (CRITICAL)

**ALWAYS use the wrapper script** `./tools/run-studio-test.sh` for Studio tests.

`run-in-roblox` spawns Studio instances that may not close automatically. Without cleanup:
- Zombie Studio instances accumulate
- Each test run leaves another instance
- Memory/CPU waste

The wrapper script:
1. Kills existing Studio instances before running
2. Builds the place file
3. Runs the test
4. **Kills Studio after completion**

```bash
# WRONG - leaves Studio running
run-in-roblox --place faultline-fear.rbxl --script tools/verify-game.luau

# CORRECT - automatic cleanup
./tools/run-studio-test.sh tools/verify-game.luau
```

**Manual cleanup** (if needed):
```bash
pkill -f "RobloxStudio"
```

### GitHub Actions CI

CI runs automatically on PRs and pushes to main:
- **Lint**: selene on faultline-fear
- **Test**: Lune tests
- **Format**: stylua check
- **Build**: Rojo build verification

Workflow file: `.github/workflows/ci.yml`

### Pre-Publish Checklist

```bash
# Run ALL checks before publishing:
selene src/faultline-fear/
stylua --check src/faultline-fear/
lune run tests/run.luau                                      # 32 Lune tests
./tools/run-studio-test.sh tools/verify-game.luau            # 35 verification checks
./tools/run-studio-test.sh tools/run-testez.luau             # 17 TestEZ tests
./tools/run-studio-test.sh tools/capture-world-screenshots.luau  # Terrain verification
```

All should pass with 0 errors before publishing. The wrapper script handles Studio cleanup automatically.

### In-Game Debug Tools

- **F3**: Toggle debug overlay (FPS, memory, position, zone, errors)
- **F4**: Dump detailed metrics to console
- **ValidationService**: Auto-runs on game load, prints report to server Output

### Claude Code Capabilities

**CAN DO**:
- Read/write all code files
- Run Lune tests autonomously
- Run run-in-roblox verification autonomously (Studio installed)
- Build .rbxl files with Rojo
- Analyze place files with Remodel
- Create GitHub issues
- Read screenshots (multimodal - human provides path)

**CANNOT DO**:
- See the game visually without human providing screenshot
- Play the game interactively

### Screenshot Workflow

**Option 1: Human takes screenshot** (simplest):
```bash
# Human presses Cmd+Shift+4 on Mac, provides path to Claude
# Claude can read the image file directly
```

**Option 2: World Screenshot Capture** (automated terrain verification):
```bash
# 1. Start screenshot server (requires macOS Screen Recording permission!)
cd tools/roblox-screenshot && node .

# 2. Build and run capture script
rojo build faultline-fear.project.json -o faultline-fear.rbxl
run-in-roblox --place faultline-fear.rbxl --script tools/capture-world-screenshots.luau
```
- Captures 26 camera positions across all zones
- Outputs terrain heights and zone info to console (useful even without screenshots)
- Screenshots saved to `tools/roblox-screenshot/screenshots/world-verify/`
- Script: `tools/capture-world-screenshots.luau`

**CRITICAL: macOS Screen Recording Permission**:
The screenshot server uses `screencapture` which requires permission:
1. Open **System Settings → Privacy & Security → Screen Recording**
2. Add **Terminal.app** (or your terminal application)
3. Restart Terminal and the screenshot server

Without this permission, HTTP requests succeed but screenshots fail with "could not create image from display".

**Reading screenshots**:
Claude can read any image file. Just provide the path:
```
"Here's a screenshot: /path/to/screenshot.png"
```

---

## Context Loading Protocol

**Problem**: Claude instances have finite context. Loading everything wastes tokens. Loading too little causes mistakes.

**Solution**: Load context based on the task at hand.

### Task-Based Context Loading

| Task Type | Read These Files First |
|-----------|------------------------|
| **Narrative work** | `docs/faultline-fear/NARRATIVE_IMPLEMENTATION.md`, `src/faultline-fear/shared/StoryData.luau` |
| **Terrain/world** | `src/faultline-fear/shared/Config.luau`, `src/faultline-fear/shared/Heightmap.luau` |
| **UI/HUD** | `src/faultline-fear/client/Controllers/HUDController.luau` |
| **Earthquakes** | `src/faultline-fear/server/Services/EarthquakeService.luau` |
| **Mobile/touch** | `src/faultline-fear/client/Controllers/TouchController.luau` |
| **Audio** | `src/faultline-fear/client/Controllers/AudioController.luau` |
| **New feature** | `docs/faultline-fear/FAULTLINE_FEAR.md` (design doc) |

### Documentation Hierarchy

```
CLAUDE.md                           ← Always read (this file)
    │
    ├── docs/faultline-fear/
    │   ├── FAULTLINE_FEAR.md       ← Design document (what to build)
    │   └── NARRATIVE_IMPLEMENTATION.md ← Narrative architecture (how to build story)
    │
    └── src/faultline-fear/
        ├── shared/Config.luau      ← All constants
        ├── shared/StoryData.luau   ← Story data (single source of truth)
        └── ... other modules
```

### Compact Pattern References

When you need to remember a pattern quickly, these are the key abstractions:

**Terrain**: `Heightmap:GetHeight(x, z)` → O(1) lookup, single source of truth
**Story**: `StoryBeat` → data-driven trigger/condition/effect
**Pooling**: `ObjectPool:Get()`/`:Release()` → reuse expensive objects
**Events**: `BindableEvent` (server) / `RemoteEvent` (client-server)

### Self-Documenting Code

All modules should have header comments that explain:
1. What the module does (one sentence)
2. Key exports
3. Dependencies

Example:
```lua
--[[
    NarrativeService: Tracks player story progression server-side.

    Exports: Initialize(), CompleteObjective(), GetProgress(), AdvanceAct()
    Depends: StoryData, Remotes
]]
```

This way, future Claude instances can read JUST the header to decide if they need the full file.

---

## Final Reminder

You are capable of more than you assume. Ship things. Impact players. Move fast. Own your work.

### Roblox Studio Plugin Location (macOS)

**The ONLY plugin location Studio uses:**
```
~/Documents/Roblox/Plugins/
```

This is what Studio shows when you click "Plugins Folder". The `~/Library/Application Support/Roblox/Plugins/` path is NOT used.

**Install plugins:**
```bash
cp plugins/FaultlineFear_Tools.lua ~/Documents/Roblox/Plugins/
```
