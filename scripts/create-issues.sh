#!/bin/bash
# Create GitHub issues with rate limit handling
# Backs off automatically when rate limited

set -e

REPO="bedwards/smash-showdown"
DELAY=2  # Base delay between requests
MAX_RETRIES=3

create_issue() {
    local title="$1"
    local body="$2"
    local labels="$3"
    local retries=0

    while [ $retries -lt $MAX_RETRIES ]; do
        echo "Creating issue: $title"

        response=$(gh issue create \
            --repo "$REPO" \
            --title "$title" \
            --body "$body" \
            --label "$labels" 2>&1) && {
            echo "Created: $response"
            sleep $DELAY
            return 0
        }

        # Check for rate limit
        if echo "$response" | grep -q "rate limit"; then
            echo "Rate limited. Waiting 60 seconds..."
            sleep 60
            retries=$((retries + 1))
        else
            echo "Error: $response"
            return 1
        fi
    done

    echo "Failed after $MAX_RETRIES retries"
    return 1
}

echo "=== Creating Mertin-Flemmer Enhancement Issues ==="
echo ""

# Issue 1: Client UI for survival mechanics
create_issue \
    "[Mertin-Flemmer] Add client UI for survival mechanics" \
    "## Summary
The survival systems (shelter, fire, hygiene, farming) exist on the server but need client-side UI to display:
- Hygiene meter
- Temperature indicator
- Shelter status
- Farm plot growth timers
- Cooking interface
- Marker/waypoint list

## Current State
Server systems in Survival.server.luau are functional but players can't see their stats.

## Acceptance Criteria
- [ ] Add hygiene bar to HUD
- [ ] Add temperature indicator
- [ ] Create build menu for shelter/fire/farm
- [ ] Add cooking recipe selection UI
- [ ] Display markers on minimap" \
    "enhancement,mertin-flemmer"

# Issue 2: NPCs at merchant locations
create_issue \
    "[Mertin-Flemmer] Add NPC characters at trading posts and checkers boards" \
    "## Summary
Trading posts and checkers boards need visible NPC characters that players can interact with.

## Current State
- Trading and checkers systems exist
- Characters.server.luau has character templates
- No NPCs are spawned at interaction points

## Acceptance Criteria
- [ ] Spawn merchant NPC at each trading post
- [ ] Spawn opponent NPC at each checkers board
- [ ] NPCs should have unique names and appearances
- [ ] Add idle animations/behaviors
- [ ] Connect to existing dialogue system" \
    "enhancement,mertin-flemmer"

# Issue 3: Expand danger systems
create_issue \
    "[Mertin-Flemmer] Expand world dangers and conflict" \
    "## Summary
The game needs more threat variety and environmental hazards to create the 'nearly insurmountable odds' experience.

## Ideas
- Weather hazards (storms, blizzards, heat waves)
- Territorial creature zones
- Trap placement by enemies
- Time-based danger escalation
- Boss encounters at key locations
- Environmental puzzles with lethal failure
- Disease outbreaks
- Food contamination

## Acceptance Criteria
- [ ] Add weather system with survival impacts
- [ ] Create creature territory system
- [ ] Add at least 3 boss encounters
- [ ] Implement environmental hazards" \
    "enhancement,mertin-flemmer,priority:high"

# Issue 4: Sound effects and atmosphere
create_issue \
    "[Mertin-Flemmer] Add ambient sounds and music system" \
    "## Summary
The game lacks audio atmosphere - no ambient sounds, no music, no creature sounds.

## Needed
- Day/night ambient loops
- Creature sounds (footsteps, growls, screeches)
- UI feedback sounds
- Weather audio
- Music that responds to danger level
- River/water sounds

## Acceptance Criteria
- [ ] Create sound manager module
- [ ] Add ambient sound system
- [ ] Add creature audio
- [ ] Add dynamic music system" \
    "enhancement,mertin-flemmer"

# Issue 5: Save/Load system
create_issue \
    "[Mertin-Flemmer] Implement player progress persistence" \
    "## Summary
Player progress (inventory, skills, markers, built structures) is lost on rejoin.

## Required
- Save: inventory, skills, markers, shelter/farm locations
- Load on player join
- Handle data migration for updates

## Technical
- Use Roblox DataStoreService
- Implement versioned save format
- Add autosave on key events

## Acceptance Criteria
- [ ] Save player inventory
- [ ] Save skill levels
- [ ] Save marker positions
- [ ] Save player-built structures
- [ ] Auto-save every 5 minutes" \
    "enhancement,mertin-flemmer,priority:high"

# Issue 6: Story journal/log
create_issue \
    "[Mertin-Flemmer] Add story journal with discovered lore" \
    "## Summary
Players find story signs but have no way to review discovered lore.

## Features
- Journal UI accessible from inventory
- Auto-log story sign content when read
- Track discovered explorer journals
- Progress indicator for story completion

## Acceptance Criteria
- [ ] Create journal UI
- [ ] Log story signs when read
- [ ] Track discovered explorer remains
- [ ] Show story completion percentage" \
    "enhancement,mertin-flemmer"

# Issue 7: Multiplayer cohort system
create_issue \
    "[Mertin-Flemmer] Implement small-group cohort gameplay" \
    "## Summary
Game should support 2-6 player cohorts progressing together, not massive multiplayer dump.

## Features
- Party/cohort system
- Shared objectives progress
- Cohort-only server instances
- Voice chat proximity
- Shared shelter access

## Acceptance Criteria
- [ ] Create party/cohort system
- [ ] Share objective progress
- [ ] Limit server to cohort size
- [ ] Add party invite system" \
    "enhancement,mertin-flemmer,priority:medium"

# Issue 8: Visual polish
create_issue \
    "[Mertin-Flemmer] Improve visual effects and polish" \
    "## Summary
Many systems lack visual feedback and polish.

## Needed
- Particle effects for fire, cooking, crafting
- Weather visual effects
- Better creature animations
- Building construction animation
- Skill level-up effects
- Day/night lighting improvements
- Fog and atmosphere

## Acceptance Criteria
- [ ] Add fire particle effects
- [ ] Add weather visuals
- [ ] Improve lighting system
- [ ] Add skill-up celebration effects" \
    "enhancement,mertin-flemmer"

# Issue 9: Tutorial system
create_issue \
    "[Mertin-Flemmer] Add guided tutorial for new players" \
    "## Summary
Game is complex - new players need guidance on survival basics.

## Tutorial Flow
1. Find food near spawn
2. Build first shelter before nightfall
3. Start a fire
4. Explain hygiene system
5. Introduce companion
6. Point toward first objective

## Acceptance Criteria
- [ ] Create tutorial quest chain
- [ ] Add contextual hints
- [ ] Highlight important items
- [ ] Skip option for experienced players" \
    "enhancement,mertin-flemmer"

# Issue 10: Pet rescue content
create_issue \
    "[Mertin-Flemmer] Complete pet rescue mission system" \
    "## Summary
Pirate ship with captured pets exists but rescue mechanics are incomplete.

## Needed
- Rescue interaction for each cage
- Pet follows player after rescue
- Return pet to sanctuary quest
- Rewards for rescue
- Pet abilities to help survival

## Acceptance Criteria
- [ ] Working rescue prompts
- [ ] Rescued pets follow player
- [ ] Pet sanctuary location
- [ ] Rescue mission rewards
- [ ] Pet companion abilities" \
    "enhancement,mertin-flemmer"

echo ""
echo "=== Issue creation complete ==="
