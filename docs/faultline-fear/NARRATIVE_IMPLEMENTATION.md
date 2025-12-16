# Faultline Fear: Narrative Implementation Architecture

**Purpose**: Deep technical analysis of how to implement the hero's journey narrative in Roblox such that story and gameplay are inseparable.

---

## The Core Problem

We have a `StoryData.luau` with acts and objectives, and a `NarrativeService.luau` that tracks progress. But this is just **bookkeeping**. The critical question is:

> **How does the player EXPERIENCE the story through GAMEPLAY, not through text boxes?**

A story told through UI popups is a cutscene. A story told through the world is a game.

---

## What's Missing from the Current Implementation

### 1. Triggers Are Descriptions, Not Code

Current StoryData has:
```lua
triggerCondition = "Player reaches coastal town zone"
completionCondition = "6 generator parts collected OR The Big One triggers"
```

These are **human-readable descriptions**, not executable triggers. The NarrativeService has no actual connection to:
- Zone detection
- Object collection
- World events

### 2. Objectives Are Passive, Not Active

Objectives like "Cross the Fault Line" or "Survive The Big One" describe what the player should do, but there's no:
- Detection of player crossing
- Definition of what "surviving" means
- Physical representation in the world

### 3. No World-Story Integration

The terrain system, zone system, and earthquake system operate independently. The narrative doesn't:
- Modify the world based on progress
- Gate areas behind story progress
- Create physical consequences for story events

---

## Roblox Systems We Can Leverage Creatively

### 1. **Workspace.Touched Events + Zone Parts**
Large invisible parts define story zones. When the player enters, it triggers story beats.

```lua
-- Zone part triggers story progression
local faultLineZone = workspace.Zones.FaultLine
faultLineZone.Touched:Connect(function(hit)
    local player = Players:GetPlayerFromCharacter(hit.Parent)
    if player and not hasTriggered[player] then
        hasTriggered[player] = true
        NarrativeService:CompleteObjective(player, "cross_fault")
        NarrativeService:PlayDialogue(player, "fault_line_warning")
    end
end)
```

### 2. **Attributes for Object State**
Every collectible, NPC, and interactable uses Attributes to track state.

```lua
-- Signal part knows what it is
generatorPart:SetAttribute("StoryObjectType", "GeneratorPart")
generatorPart:SetAttribute("PartNumber", 3)
generatorPart:SetAttribute("Collected", false)
generatorPart:SetAttribute("RequiresAct", "ACT_2_TRIALS")  -- Story gating
```

### 3. **CollectionService Tags for Bulk Operations**
Tag all story-relevant objects for efficient queries.

```lua
CollectionService:AddTag(generatorPart, "StoryCollectible")
CollectionService:AddTag(survivor, "Rescuable")
CollectionService:AddTag(faultLineZone, "StoryZone")
```

### 4. **BindableEvents for Internal Signaling**
Services communicate story events without tight coupling.

```lua
-- When player collects generator part
StoryEvents.GeneratorPartCollected:Fire(player, partNumber)

-- EarthquakeService listens
StoryEvents.GeneratorPartCollected:Connect(function(player, partNumber)
    if partNumber == 6 then
        -- All parts collected, allow signal activation
        self:EnableRadioTower()
    end
end)
```

### 5. **Terrain:WriteVoxels for Permanent World Changes**
The Big One doesn't just shake the camera - it permanently changes terrain.

```lua
function EarthquakeService:ApplyBigOneTerrainChanges()
    -- Widen the fault line
    local materials = { Enum.Material.Air } -- Replace with air (create gap)
    Terrain:WriteVoxels(region, resolution, materials, occupancy)

    -- Create new cliff face
    Terrain:FillBlock(cliffCFrame, cliffSize, Enum.Material.Rock)

    -- Notify all systems that world has changed
    StoryEvents.WorldChanged:Fire("BIG_ONE")
end
```

### 6. **Model:PivotTo for Structure Movement**
Buildings collapse, bridges fall, paths open.

```lua
function StructureService:CollapseBuilding(building)
    -- Animate collapse
    local startCFrame = building:GetPivot()
    local endCFrame = startCFrame * CFrame.new(0, -10, 0) * CFrame.Angles(0.3, 0, 0.2)

    TweenService:Create(building, TweenInfo.new(2), {
        Pivot = endCFrame
    }):Play()

    -- Enable collision on rubble
    task.delay(2, function()
        building:SetAttribute("Collapsed", true)
        rubble.CanCollide = true
    end)
end
```

### 7. **PathfindingService for NPC Escort**
Survivors follow paths that change based on world state.

```lua
function NPCService:EscortSurvivor(survivor, destination)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = false,
    })

    path:ComputeAsync(survivor.Position, destination)

    -- Path may be blocked after Big One
    if path.Status == Enum.PathStatus.NoPath then
        -- Find alternate route or notify player
        self:NotifyPathBlocked(survivor)
    end
end
```

---

## The StoryBeat Pattern: DRY/SOLID Architecture

Instead of hardcoding each story moment, we create a **StoryBeat** abstraction that all story moments inherit from.

### StoryBeat Base Type

```lua
export type StoryBeat = {
    id: string,
    actRequired: ActId?,           -- Only triggers if player is in this act

    -- TRIGGER: What causes this beat to activate?
    triggerType: "zone_enter" | "object_collect" | "npc_interact" | "time_elapsed" | "event",
    triggerData: {
        zoneId: string?,           -- For zone_enter
        objectTag: string?,        -- For object_collect
        npcId: string?,            -- For npc_interact
        eventId: string?,          -- For event
        delaySeconds: number?,     -- For time_elapsed
    },

    -- CONDITION: Additional requirements?
    conditions: {
        objectivesComplete: { string }?,  -- Must have completed these first
        survivorsRescued: number?,        -- Minimum survivors
        timeOfDay: "Day" | "Night"?,      -- Must be this time
    }?,

    -- EFFECTS: What happens when triggered?
    effects: {
        completeObjective: string?,       -- Mark this objective complete
        playDialogue: string?,            -- Show this dialogue
        triggerEvent: string?,            -- Fire this story event
        spawnObject: {                    -- Spawn something
            prefabId: string,
            position: Vector3,
        }?,
        modifyWorld: {                    -- Change the world
            action: "collapse" | "open" | "close" | "destroy",
            targetId: string,
        }?,
        teleportPlayer: Vector3?,         -- Move player
        setWeather: string?,              -- Change weather
        playMusic: string?,               -- Change music
    },

    -- STATE
    repeatable: boolean,                  -- Can trigger again?
    globalTrigger: boolean,               -- Once per server, not per player?
}
```

### Defining Story Beats (Data-Driven)

```lua
StoryData.Beats = {
    -- ==========================================
    -- ACT 1: THE CALL
    -- ==========================================

    wake_up = {
        id = "wake_up",
        actRequired = "ACT_1_CALL",
        triggerType = "event",
        triggerData = { eventId = "GAME_START" },
        effects = {
            completeObjective = "wake_up",
            playDialogue = "wake_up_monologue",
            setWeather = "overcast",
        },
        repeatable = false,
    },

    first_food_found = {
        id = "first_food_found",
        actRequired = "ACT_1_CALL",
        triggerType = "object_collect",
        triggerData = { objectTag = "Food" },
        conditions = {
            objectivesComplete = { "wake_up" },
        },
        effects = {
            completeObjective = "find_food",
            playDialogue = "hunger_explained",
        },
        repeatable = false,
    },

    first_survivor_found = {
        id = "first_survivor_found",
        actRequired = "ACT_1_CALL",
        triggerType = "zone_enter",
        triggerData = { zoneId = "FirstSurvivorArea" },
        effects = {
            completeObjective = "meet_survivor",
            playDialogue = "first_survivor",
            spawnObject = {
                prefabId = "Marcus_NPC",
                position = Vector3.new(100, 50, -200),
            },
        },
        repeatable = false,
    },

    reach_coastal_town = {
        id = "reach_coastal_town",
        actRequired = "ACT_1_CALL",
        triggerType = "zone_enter",
        triggerData = { zoneId = "CoastalTown" },
        conditions = {
            objectivesComplete = { "meet_survivor" },
        },
        effects = {
            completeObjective = "reach_town",
            playDialogue = "town_arrival",
            triggerEvent = "ACT_1_COMPLETE",
        },
        repeatable = false,
    },

    -- ==========================================
    -- ACT 2: TRIALS
    -- ==========================================

    cross_fault_line = {
        id = "cross_fault_line",
        actRequired = "ACT_2_TRIALS",
        triggerType = "zone_enter",
        triggerData = { zoneId = "FaultLineNorthSide" },
        effects = {
            completeObjective = "cross_fault",
            playDialogue = "fault_line_crossed",
        },
        repeatable = false,
    },

    signal_part_collected = {
        id = "signal_part_collected",
        actRequired = "ACT_2_TRIALS",
        triggerType = "object_collect",
        triggerData = { objectTag = "GeneratorPart" },
        effects = {
            completeObjective = "collect_generator_parts",
            -- Dialogue varies by part number, handled in effect processor
        },
        repeatable = true,  -- Can collect multiple
    },

    survivor_rescued = {
        id = "survivor_rescued",
        actRequired = nil,  -- Can happen any act
        triggerType = "npc_interact",
        triggerData = { objectTag = "Rescuable" },
        effects = {
            completeObjective = "rescue_survivors",
        },
        repeatable = true,
    },

    first_night_survived = {
        id = "first_night_survived",
        actRequired = "ACT_2_TRIALS",
        triggerType = "event",
        triggerData = { eventId = "DAWN_AFTER_FIRST_NIGHT" },
        effects = {
            completeObjective = "survive_night",
            playDialogue = "night_survived",
        },
        repeatable = false,
    },

    -- ==========================================
    -- ACT 3: THE ORDEAL
    -- ==========================================

    big_one_starts = {
        id = "big_one_starts",
        actRequired = "ACT_2_TRIALS",
        triggerType = "event",
        triggerData = { eventId = "BIG_ONE_TRIGGER" },
        effects = {
            triggerEvent = "BIG_ONE",
            modifyWorld = {
                action = "collapse",
                targetId = "BridgeMain",
            },
            playDialogue = "big_one_starts",
        },
        repeatable = false,
        globalTrigger = true,  -- Affects all players
    },

    big_one_survived = {
        id = "big_one_survived",
        actRequired = "ACT_3_ORDEAL",
        triggerType = "event",
        triggerData = { eventId = "BIG_ONE_ENDED" },
        effects = {
            completeObjective = "survive_big_one",
            playDialogue = "big_one_aftermath",
        },
        repeatable = false,
    },

    -- ==========================================
    -- ACT 4: THE RETURN
    -- ==========================================

    reach_mountain_base = {
        id = "reach_mountain_base",
        actRequired = "ACT_3_ORDEAL",
        triggerType = "zone_enter",
        triggerData = { zoneId = "MountainBase" },
        effects = {
            triggerEvent = "ACT_3_COMPLETE",
            playDialogue = "final_ascent",
        },
        repeatable = false,
    },

    activate_signal = {
        id = "activate_signal",
        actRequired = "ACT_4_RETURN",
        triggerType = "npc_interact",
        triggerData = { objectTag = "RadioTower" },
        conditions = {
            objectivesComplete = { "ascend_mountain", "gather_group" },
        },
        effects = {
            completeObjective = "activate_signal",
            triggerEvent = "SIGNAL_ACTIVATED",
            playDialogue = "rescue_arrives",
        },
        repeatable = false,
    },

    -- ==========================================
    -- ACT 5: RESOLUTION
    -- ==========================================

    helicopter_arrives = {
        id = "helicopter_arrives",
        actRequired = "ACT_5_RESOLUTION",
        triggerType = "time_elapsed",
        triggerData = { delaySeconds = 60 },  -- 1 minute after signal
        effects = {
            spawnObject = {
                prefabId = "RescueHelicopter",
                position = Vector3.new(0, 500, 1800),  -- Mountain top
            },
            playDialogue = "helicopter_landing",
        },
        repeatable = false,
        globalTrigger = true,
    },

    board_helicopter = {
        id = "board_helicopter",
        actRequired = "ACT_5_RESOLUTION",
        triggerType = "zone_enter",
        triggerData = { zoneId = "HelicopterZone" },
        effects = {
            completeObjective = "board_helicopter",
            triggerEvent = "GAME_COMPLETE",
        },
        repeatable = false,
    },
}
```

---

## StoryBeatProcessor: The Runtime Engine

A single processor handles ALL story beats, keeping logic DRY:

```lua
-- server/Services/StoryBeatProcessor.luau
local StoryBeatProcessor = {}

local triggeredBeats: { [Player]: { [string]: boolean } } = {}
local globalTriggeredBeats: { [string]: boolean } = {}

-- Listen for all trigger types
function StoryBeatProcessor:Initialize()
    -- Zone triggers
    for _, zone in CollectionService:GetTagged("StoryZone") do
        self:SetupZoneTrigger(zone)
    end

    -- Object collection triggers
    for _, obj in CollectionService:GetTagged("StoryCollectible") do
        self:SetupCollectTrigger(obj)
    end

    -- NPC interaction triggers
    for _, npc in CollectionService:GetTagged("StoryNPC") do
        self:SetupNPCTrigger(npc)
    end

    -- Event triggers (from other services)
    StoryEvents.EventFired:Connect(function(eventId, player)
        self:ProcessEventTrigger(eventId, player)
    end)

    -- Time elapsed triggers (checked periodically)
    self:StartTimerProcessor()
end

function StoryBeatProcessor:SetupZoneTrigger(zone)
    local zoneId = zone:GetAttribute("ZoneId")

    zone.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            self:ProcessTrigger("zone_enter", { zoneId = zoneId }, player)
        end
    end)
end

function StoryBeatProcessor:ProcessTrigger(triggerType, triggerData, player)
    for beatId, beat in pairs(StoryData.Beats) do
        if beat.triggerType == triggerType then
            if self:MatchesTriggerData(beat.triggerData, triggerData) then
                self:TryExecuteBeat(beat, player)
            end
        end
    end
end

function StoryBeatProcessor:TryExecuteBeat(beat, player)
    -- Check if already triggered
    if beat.globalTrigger then
        if globalTriggeredBeats[beat.id] and not beat.repeatable then
            return
        end
    else
        triggeredBeats[player] = triggeredBeats[player] or {}
        if triggeredBeats[player][beat.id] and not beat.repeatable then
            return
        end
    end

    -- Check act requirement
    if beat.actRequired then
        local currentAct = NarrativeService:GetCurrentAct(player)
        if currentAct ~= beat.actRequired then
            return
        end
    end

    -- Check conditions
    if beat.conditions then
        if not self:CheckConditions(beat.conditions, player) then
            return
        end
    end

    -- Execute!
    self:ExecuteBeat(beat, player)

    -- Mark as triggered
    if beat.globalTrigger then
        globalTriggeredBeats[beat.id] = true
    else
        triggeredBeats[player][beat.id] = true
    end
end

function StoryBeatProcessor:ExecuteBeat(beat, player)
    local effects = beat.effects

    if effects.completeObjective then
        NarrativeService:CompleteObjective(player, effects.completeObjective)
    end

    if effects.playDialogue then
        NarrativeService:PlayDialogue(player, effects.playDialogue)
    end

    if effects.triggerEvent then
        StoryEvents.EventFired:Fire(effects.triggerEvent, player)
    end

    if effects.spawnObject then
        ObjectSpawner:Spawn(effects.spawnObject.prefabId, effects.spawnObject.position)
    end

    if effects.modifyWorld then
        WorldModifier:Apply(effects.modifyWorld.action, effects.modifyWorld.targetId)
    end

    if effects.teleportPlayer then
        player.Character:PivotTo(CFrame.new(effects.teleportPlayer))
    end

    if effects.setWeather then
        WeatherService:SetWeather(effects.setWeather)
    end

    if effects.playMusic then
        MusicService:ChangeStation(effects.playMusic)
    end

    print(string.format("[StoryBeat] Executed: %s for %s", beat.id, player.Name))
end
```

---

## Making Story VISIBLE to the Player

The player must ALWAYS know where they are in the story without reading text:

### 1. **Environmental Storytelling**

| Story State | World Change | How Player Sees It |
|-------------|--------------|-------------------|
| Act 1 start | Rubble everywhere, fires burning | Visual destruction |
| First survivor found | NPC waves, calls out | Movement, sound |
| Cross fault line | Steam vents, unstable ground | Visual + audio warnings |
| Big One happens | Terrain shifts, buildings fall | MASSIVE visual event |
| Post-Big One | New cliff, blocked paths | Changed navigation |
| Signal activated | Helicopter sound approaches | Audio cue |
| Game complete | Credits roll in-world | On a billboard/screen |

### 2. **HUD Integration**

The HUD shows story state through:

```lua
-- HUDController receives story updates
ObjectiveUpdateEvent.OnClientEvent:Connect(function(data)
    -- Update objective text
    objectiveText.Text = getCurrentObjectiveText(data)

    -- Update progress counters
    generatorPartsLabel.Text = string.format("Signal: %d/6", data.generatorPartsCollected)
    survivorsLabel.Text = string.format("Survivors: %d/10", data.survivorsRescued)

    -- Show act name on major transitions
    if data.actChanged then
        showActTitle(data.actName)  -- Big centered text that fades
    end
end)
```

### 3. **Audio Cues**

| Story Moment | Audio |
|--------------|-------|
| Objective complete | Positive chime |
| Act transition | Dramatic stinger |
| Approaching danger | Tense music swell |
| Big One imminent | Emergency broadcast |
| Rescue arriving | Helicopter rotors |

### 4. **Visual Beacons**

Key objectives have visible beacons:

```lua
-- Create objective beacon
function ObjectiveBeacon:Create(position, color)
    local beam = Instance.new("Beam")
    beam.Width0 = 2
    beam.Width1 = 0.1
    beam.Color = ColorSequence.new(color)
    beam.LightEmission = 1
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1),
    })
    -- Attaches from ground to sky
end
```

---

## Performance Considerations

### 1. **Lazy Trigger Setup**

Don't set up triggers for all beats at once. Load them per-act:

```lua
function StoryBeatProcessor:OnActChanged(player, newAct)
    -- Clean up old act triggers
    self:CleanupActTriggers(player)

    -- Setup new act triggers
    for beatId, beat in pairs(StoryData.Beats) do
        if beat.actRequired == newAct or beat.actRequired == nil then
            self:SetupBeatTrigger(beat, player)
        end
    end
end
```

### 2. **Zone Detection Optimization**

Use spatial hashing instead of per-frame distance checks:

```lua
-- Grid-based zone detection
local CELL_SIZE = 50
local playerCells: { [Player]: string } = {}

function ZoneDetector:Update()
    for _, player in Players:GetPlayers() do
        local pos = player.Character and player.Character:GetPivot().Position
        if pos then
            local cellKey = getCellKey(pos)
            if cellKey ~= playerCells[player] then
                playerCells[player] = cellKey
                self:CheckZonesInCell(player, cellKey)
            end
        end
    end
end
```

### 3. **Event Debouncing**

Story triggers shouldn't fire multiple times per frame:

```lua
local lastTriggerTime: { [string]: number } = {}
local DEBOUNCE_TIME = 0.5

function StoryBeatProcessor:ProcessTrigger(...)
    local key = tostring({...})
    local now = tick()

    if lastTriggerTime[key] and now - lastTriggerTime[key] < DEBOUNCE_TIME then
        return
    end
    lastTriggerTime[key] = now

    -- ... actual processing
end
```

### 4. **Attribute Caching**

Don't read attributes every frame:

```lua
local attributeCache: { [Instance]: { [string]: any } } = {}

function getCachedAttribute(instance, name)
    attributeCache[instance] = attributeCache[instance] or {}
    if attributeCache[instance][name] == nil then
        attributeCache[instance][name] = instance:GetAttribute(name)
    end
    return attributeCache[instance][name]
end

-- Invalidate on change
instance:GetAttributeChangedSignal(name):Connect(function()
    if attributeCache[instance] then
        attributeCache[instance][name] = nil
    end
end)
```

---

## What's Still Challenging in Roblox

### 1. **Persistent World State**

Roblox servers reset. We need DataStore for:
- Player's current act
- Completed objectives
- Rescued survivors
- Collected items

```lua
function NarrativeService:SaveProgress(player)
    local key = "progress_" .. player.UserId
    DataStoreService:GetDataStore("FaultlineFear"):SetAsync(key, {
        currentAct = progress.currentAct,
        completedObjectives = progress.completedObjectives,
        survivorsRescued = progress.survivorsRescued,
        generatorPartsCollected = progress.generatorPartsCollected,
        startTime = progress.startTime,
    })
end
```

### 2. **Multi-Player Story Synchronization**

If players are in different acts, the world state must accommodate:
- The Big One is global - triggers for all
- Collected generator parts are per-player or shared?
- Rescued survivors stay rescued for all?

**Decision**:
- Signal parts: Per-player (everyone needs their own 6)
- Survivors: Shared (once rescued, rescued for all)
- World events: Global (The Big One happens for everyone)

### 3. **Cutscene-Like Moments**

Roblox doesn't have native cutscene support. Options:
- Lock player movement, tween camera
- Use ViewportFrames for "flashback" moments
- In-world events that players watch (helicopter landing)

### 4. **Dialogue System UI**

We need a DialogueController (client) to display dialogue:

```lua
function DialogueController:ShowDialogue(dialogue)
    -- Show portrait if available
    if dialogue.portrait then
        portraitImage.Image = dialogue.portrait
    end

    -- Show speaker name
    speakerLabel.Text = dialogue.name

    -- Typewriter effect for lines
    for i, line in ipairs(dialogue.lines) do
        await(self:TypewriteLine(line))
        await(self:WaitForInput())  -- Tap to continue
    end

    self:Hide()
end
```

---

## Implementation Roadmap

### Phase 1: Infrastructure (No Visual Assets Needed)
1. Create `StoryBeatProcessor` service
2. Define all `StoryBeats` in `StoryData`
3. Create zone parts with `ZoneId` attributes
4. Wire up trigger system

### Phase 2: Triggers (Placeholder Assets OK)
1. Place trigger zones in world
2. Tag all collectibles and NPCs
3. Test trigger → effect flow
4. Verify act progression

### Phase 3: Effects (Requires Assets)
1. Create DialogueController UI
2. Implement world modification effects
3. Add visual/audio feedback
4. Connect to HUD updates

### Phase 4: Polish
1. Add environmental storytelling details
2. Tune timing and pacing
3. Test complete playthrough
4. Performance optimization

---

## Summary: Story as Gameplay

The key insight is that **every story beat should have a GAMEPLAY component**:

| Story Beat | NOT Just | BUT ALSO |
|------------|----------|----------|
| Wake up | Text popup | Camera shake, vision blur clearing |
| Find food | Counter increment | Hunger bar fills, relief sound |
| Meet survivor | Dialogue | NPC physically appears, waves |
| Cross fault | Zone detection | Ground rumbles, player wobbles |
| Big One | Event flag | EVERYTHING shakes, terrain moves |
| Signal activated | Objective complete | Radio static → voice → helicopter sound |
| Board helicopter | Game end | Player physically enters, doors close, lift off |

**The story IS the game. The game IS the story.**

---

*This document defines how narrative and gameplay merge in Faultline Fear. All implementation should follow the StoryBeat pattern for consistency and maintainability.*
