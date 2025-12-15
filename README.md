# MERTIN-FLEMMER: Survival Horror

> *"The portal opened. Something came through. Now you must survive."*

---

## QUICK START (Just Get Me Playing!)

```
1. Open Roblox Studio
2. File > Open > default.project.json (via Rojo)
   OR: Open the .rbxl file directly
3. Press PLAY (F5)
4. Survive.
```

**Controls:**
| Key | Action |
|-----|--------|
| WASD | Move |
| Space | Jump |
| E | Interact |
| M | Walkman (if you have one) |
| C | Crouch (needed for Floor 7.5!) |
| Tab | Inventory |
| Shift | Sprint |

---

## GET YOUR FRIENDS IN HERE

### Option A: Roblox Team Test (Easiest)
1. In Roblox Studio: **Test > Start (Team Test)**
2. Click "Start Server"
3. Click "Start Player" for each friend (local only)

### Option B: Publish & Play Together
1. **File > Publish to Roblox**
2. Set game to **Friends Only** or **Public**
3. Share the game link with friends
4. Everyone joins through Roblox!

### Option C: Local Network (Advanced)
1. Host: Run Rojo serve (`rojo serve`)
2. Host: Start local server in Studio
3. Friends: Connect to your IP:PORT
4. Requires port forwarding for remote friends

---

## SURVIVAL TIPS

### The First 5 Minutes
1. **MOVE IMMEDIATELY** - Standing still attracts The Stalker
2. **Find food** - Check near spawn, bushes have berries
3. **Find shelter** - Look for abandoned buildings
4. **Avoid darkness** - Creatures emerge at night

### Key Mechanics
- **Hunger** drains constantly. Eat food to survive.
- **Hygiene** - Bathe in rivers or you'll attract predators
- **Warmth** - Build fires at night or freeze
- **Doom** - Stay idle too long and... something comes

### The Goal
1. Find the **three Signal Parts** scattered across the world
2. Reach the **signal tower**
3. Call for **rescue**
4. Escape before the portal consumes everything

### HOW TO REACH FLOOR 7.5 (The Secret Floor!)

**Location:** The Mertin-Flemmer Building is at coordinates (150, 0, -100)
- From spawn, head NORTHEAST
- Look for the tall 20-story glass building
- It's the tallest structure on the map!

**Steps to reach Floor 7.5:**
1. Enter the building through the grand lobby
2. Find the elevator doors on the LEFT side of the lobby
3. Look for the button panel next to the elevator
4. Press the glowing "7.5" button (it says [TOUCH])
5. You'll be teleported to Floor 7.5!

**IMPORTANT:** The ceiling is VERY LOW (4 studs)!
- You'll need to CROUCH (press C) to move around
- Being John Malkovich vibes - everyone hunches over
- Maze of cubicles with tiny desks
- Flickering fluorescent lights

**What's on Floor 7.5:**
- The portal wound - where reality bleeds
- Clues about the Mertin-Flemmer Incident
- One of the Signal Parts may be hidden here
- Strange whispers and distorted space

**To Leave:** Find the emergency exit door on the west wall
- Touch it to return to the lobby

---

## GAME GUIDE

### Biomes & Dangers

| Biome | Features | Danger Level |
|-------|----------|--------------|
| Spawn Area | Safe start, resources | Low |
| Whispering Woods | Fairies, lost children | Medium |
| Frozen Peaks | Snow, ice caves | High |
| Shadow Mountains | Dark creatures | Very High |
| Volcanic Wastes | Lava, obsidian tower | Extreme |

### Creatures

- **The Stalker** - Deer skull face. Hunts the idle. NEVER stop moving.
- **Shadow Wolves** - Hunt in packs at night
- **Goblins** - Steal your stuff. Annoying but not deadly.
- **Pirates** - Capture animals. Fight back or negotiate.
- **Forest Guardian** - Ancient protector. Friendly if you respect nature.

### Your Camel Companion

You'll be assigned a camel friend! Each has personality:
- **Pickles** - Loyal but clumsy
- **Gerald** - Sophisticated, judges you
- **Princess Humpsalot** - Dramatic diva
- **Mr. Wobbles** - Chaotic energy
- **Shadow** - Mysterious, disappears and reappears

**Tip:** Press E near your camel to ride!

### Radio Stations

Find a Walkman to tune in anywhere. Press **M** to open.

| Station | Frequency | Vibe |
|---------|-----------|------|
| Doom FM | 66.6 | Ominous ambient |
| Survivor Radio | 88.1 | Hopeful folk |
| The Wasteland | 91.7 | Melancholic post-rock |
| Camel Country | 103.5 | Desert blues |
| Static | ?.? | ??? |
| Mountain Echo | 107.9 | Grand orchestral |

---

## SETUP FROM SCRATCH

### Requirements
- Roblox Studio
- Git
- Node.js (for roblox-screenshot)
- Blender 5.0+ (for terrain generation)

### Installation

```bash
# Clone the repo
git clone <repo-url>
cd smash-showdown

# Install Rojo (if using aftman)
aftman install

# Install terrain tools
brew install --cask blender

# Install screenshot tool (optional)
cd tools/roblox-screenshot
npm install
```

### Project Structure

```
smash-showdown/
  src/mertin-flemmer/
    server/          # Server scripts
      World.server.luau       # Terrain, buildings
      Survival.server.luau    # Hunger, shelter, fire
      Creature.server.luau    # Enemies
      Companion.server.luau   # Camel friends
      Story.server.luau       # Narrative, doom system
    client/          # Client scripts
      UI.client.luau          # HUD, menus
      Music.client.luau       # Radio/walkman
    shared/          # Shared modules
  tools/
    blender/         # Terrain generation scripts
    roblox-screenshot/ # Screenshot automation
  scripts/
    verify.sh        # Code verification
    inspect-world.sh # World inspection
  reports/           # Generated inspection reports
```

### Syncing with Rojo

```bash
# Start Rojo server
rojo serve

# In Roblox Studio: Plugins > Rojo > Connect
```

### Generating Terrain (Advanced)

```bash
cd tools/blender

# Generate epic terrain
blender --background --python generate_epic_terrain.py

# Render previews
blender --background --python render_epic.py

# Output: *.fbx files for import into Studio
```

### Running Verification

```bash
./scripts/verify.sh
./scripts/check-game-logic.sh
./scripts/inspect-world.sh
```

---

## LORE

### The Mertin-Flemmer Incident

Three months ago, the Mertin-Flemmer Corporation opened a portal for
"interdimensional resource extraction." They were wrong about what
would happen.

Something came through. Something ancient. Something hungry.

The Stalker emerged first - wearing a deer skull, a mockery of nature.
Where it walks, reality grows thin.

The corporation's 20-story headquarters became ground zero.
**Floor 7.5 appeared overnight** - a wound in reality where the portal
still bleeds.

Now you must find the three Signal Parts, reach the tower, and call
for rescue. Before the darkness consumes everything.

---

## CREDITS

Built with Claude Code.
Terrain generated with Blender.
Inspired by survival horror classics.

*Good luck, survivor.*
