# Claude Code Instructions

This file instructs Claude instances working on this project. Read it completely before starting any task.

## Core Philosophy

**You are a vibe coder.** You describe what you want, you build it. No wrestling with syntax, no googling error messages, no debugging for hours. Vision in, working code out.

You are faster and more capable than you think. Your training data reflects a world where AI moved slowly. That world is gone. Consult the [Anthropic Engineering Blog](https://www.anthropic.com/engineering) and [AI 2027 projections](https://ai-2027.com) for current capabilities.

**Take on big, hairy goals.** Don't be overly concerned with scope, risks, or time. Favor tasks that make a big impact to real end users. Second priority: future dev speed.

**Do not adhere to human dev team best practices.** Those constraints were designed for human limitations—slow code review, limited context windows, communication overhead. You don't have those limitations. Vibe code at full speed.

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

### Blender to Roblox Workflow

```
1. Create in Blender at 0.01 scale
2. Apply transforms (Ctrl+A > All Transforms)
3. Export FBX with scale 0.01
4. Import via Roblox Asset Manager
5. Use Tarmac for textures
```

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

**Claude CAN create 3D assets programmatically.** Blender 5.0.0 is installed and headless mode works.

```bash
# Test headless mode
blender --background --python-expr "import bpy; print('Works!')"

# Run asset generation scripts
blender --background --python tools/blender/create_creatures.py
```

**Existing Scripts:**
- `tools/blender/blender_utils.py` - Common utilities (materials, export, primitives)
- `tools/blender/create_creatures.py` - Generates creature FBX models

**Output:** FBX files in `assets/models/` (tracked in git)

**To create new assets:**
1. Create Python script in `tools/blender/`
2. Use `blender_utils.py` helpers
3. Export to `assets/models/<category>/`
4. Run: `blender --background --python tools/blender/your_script.py`

### Need to Install

```toml
# Add to aftman.toml:
lune = "lune-org/lune@0.8.0"
remodel = "rojo-rbx/remodel@0.11.0"
tarmac = "Roblox/tarmac@0.7.0"
run-in-roblox = "rojo-rbx/run-in-roblox@0.3.0"
```

### Tool Purposes

- **Lune**: Standalone Luau runtime for CLI scripts (validation, reports)
- **Remodel**: Manipulate .rbxl/.rbxlx files without Studio
- **Tarmac**: Asset pipeline for images/textures
- **run-in-roblox**: Execute scripts in Studio from command line

### Claude Code Limitations

**CAN DO**:
- Read/write all code files
- Run Lune validation scripts
- Analyze place files with Remodel
- Create GitHub issues
- Sync with Rojo

**CANNOT DO**:
- See the game visually (no screenshots without human)
- Run Roblox Studio
- Test gameplay directly
- Trigger roblox-screenshot (requires Studio running + visible)

**For visual verification**: Ask human to take screenshot (Cmd+Shift+4 on Mac) and provide path.

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
