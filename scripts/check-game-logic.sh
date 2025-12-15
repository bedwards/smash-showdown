#!/bin/bash
# Deep game logic verification for Mertin-Flemmer
# Checks game-specific invariants that static analysis can't catch

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$PROJECT_ROOT/src/mertin-flemmer"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  GAME LOGIC VERIFICATION${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ==========================================
# 1. SPAWN SAFETY
# ==========================================
echo -e "${BLUE}── Spawn Safety ──${NC}"

# Extract spawn position
SPAWN_X=$(grep -o "spawnPoint = Vector3.new([^)]*)" "$SRC_DIR/server/Survival.server.luau" 2>/dev/null | grep -o "([^)]*)" | tr -d '()' | cut -d',' -f1 || echo "0")
SPAWN_Z=$(grep -o "spawnPoint = Vector3.new([^)]*)" "$SRC_DIR/server/Survival.server.luau" 2>/dev/null | grep -o "([^)]*)" | tr -d '()' | cut -d',' -f3 || echo "0")
info "Spawn point: X=$SPAWN_X, Z=$SPAWN_Z"

# Check no mountains within 100 studs of spawn
DANGER_RADIUS=100
MOUNTAIN_POSITIONS=$(grep -o "basePosition = Vector3.new([^)]*)" "$SRC_DIR/server/Mountains.server.luau" 2>/dev/null | grep -o "([^)]*)" | tr -d '()')

SPAWN_BLOCKED=false
while IFS= read -r pos; do
    if [ -n "$pos" ]; then
        MTN_X=$(echo "$pos" | cut -d',' -f1 | tr -d ' ')
        MTN_Z=$(echo "$pos" | cut -d',' -f3 | tr -d ' ')

        # Calculate distance (simplified - just check if within box)
        if [ -n "$MTN_X" ] && [ -n "$MTN_Z" ]; then
            DX=$((${MTN_X%.*} - ${SPAWN_X%.*}))
            DZ=$((${MTN_Z%.*} - ${SPAWN_Z%.*}))
            DX=${DX#-}  # Absolute value
            DZ=${DZ#-}

            if [ "$DX" -lt "$DANGER_RADIUS" ] && [ "$DZ" -lt "$DANGER_RADIUS" ]; then
                warn "Mountain at ($MTN_X, $MTN_Z) is near spawn!"
                SPAWN_BLOCKED=true
            fi
        fi
    fi
done <<< "$MOUNTAIN_POSITIONS"

if [ "$SPAWN_BLOCKED" = false ]; then
    pass "No mountains within ${DANGER_RADIUS} studs of spawn"
fi

# ==========================================
# 2. FOOD NEAR SPAWN
# ==========================================
echo ""
echo -e "${BLUE}── Survival Viability ──${NC}"

# Check there's food near spawn
if grep -q "SPAWN_FOOD_COUNT\|spawn.*food\|food.*spawn" "$SRC_DIR/server/Resources.server.luau" 2>/dev/null; then
    SPAWN_FOOD=$(grep -o "SPAWN_FOOD_COUNT = [0-9]*" "$SRC_DIR/server/Resources.server.luau" 2>/dev/null | grep -o "[0-9]*" || echo "0")
    if [ "$SPAWN_FOOD" -ge 10 ]; then
        pass "Food spawns near spawn point: $SPAWN_FOOD items"
    else
        warn "Low food near spawn: $SPAWN_FOOD items"
    fi
else
    fail "No food spawn near starting area!"
fi

# Check starting inventory
if grep -q "food = [0-9]" "$SRC_DIR/server/Resources.server.luau" 2>/dev/null; then
    STARTING_FOOD=$(grep "food = [0-9]" "$SRC_DIR/server/Resources.server.luau" 2>/dev/null | head -1 | grep -o "[0-9]*" | head -1 || echo "0")
    if [ "$STARTING_FOOD" -ge 3 ]; then
        pass "Starting food inventory: $STARTING_FOOD"
    else
        warn "Low starting food: $STARTING_FOOD"
    fi
fi

# ==========================================
# 3. COMPANION SANITY
# ==========================================
echo ""
echo -e "${BLUE}── Companion System ──${NC}"

# Check companion spawns
if [ -f "$SRC_DIR/server/Companion.server.luau" ]; then
    pass "Companion system exists"

    # Check companion doesn't spawn at exact player position (would look weird)
    if grep -q "rootPart.Position + Vector3" "$SRC_DIR/server/Companion.server.luau"; then
        pass "Companion spawns offset from player"
    else
        warn "Companion may spawn exactly on player"
    fi

    # Check companion follows player
    if grep -q "FOLLOWING\|follow\|moveToward" "$SRC_DIR/server/Companion.server.luau"; then
        pass "Companion has follow behavior"
    else
        fail "Companion doesn't follow player!"
    fi
else
    fail "No companion system!"
fi

# ==========================================
# 4. WATER ACCESSIBILITY
# ==========================================
echo ""
echo -e "${BLUE}── Water for Hygiene ──${NC}"

# Check water bodies exist
if grep -q "RIVERS\|LAKES\|WaterBody\|createWaterBody" "$SRC_DIR/server/Survival.server.luau" 2>/dev/null; then
    pass "Water bodies defined"

    # Check bathing is possible
    if grep -q "Bathe\|bathing\|bathingRestoreAmount" "$SRC_DIR/server/Survival.server.luau"; then
        pass "Bathing mechanic exists"
    else
        warn "Bathing mechanic unclear"
    fi
else
    fail "No water bodies for hygiene!"
fi

# ==========================================
# 5. DIFFICULTY BALANCE
# ==========================================
echo ""
echo -e "${BLUE}── Difficulty Balance ──${NC}"

# Check hunger isn't instant death
HUNGER_DRAIN=$(grep -o "HUNGER_DRAIN = [0-9]*" "$SRC_DIR/shared/init.luau" 2>/dev/null | grep -o "[0-9]*" || echo "0")
if [ "$HUNGER_DRAIN" -gt 0 ]; then
    # Calculate rough survival time with no food
    # MAX_HUNGER is typically 100, drain per minute
    SURVIVAL_MINS=$((100 / HUNGER_DRAIN))
    if [ "$SURVIVAL_MINS" -ge 5 ]; then
        pass "Starvation time reasonable: ~$SURVIVAL_MINS minutes"
    else
        warn "Starvation very fast: ~$SURVIVAL_MINS minutes (may be frustrating)"
    fi
fi

# Check doom system isn't too aggressive
FIRST_WARNING=$(grep -o "time = [0-9]*" "$SRC_DIR/server/Story.server.luau" 2>/dev/null | head -1 | grep -o "[0-9]*" || echo "0")
if [ "$FIRST_WARNING" -ge 20 ]; then
    pass "Doom warning delay reasonable: ${FIRST_WARNING}s"
else
    warn "Doom warning very fast: ${FIRST_WARNING}s"
fi

# ==========================================
# 6. REMOTE EVENT MATCHING
# ==========================================
echo ""
echo -e "${BLUE}── Client-Server Communication ──${NC}"

# Get server-created remotes
SERVER_REMOTES=$(grep -rho 'Instance\.new("RemoteEvent")' "$SRC_DIR/server" -A3 | grep -o '\.Name = "[^"]*"' | sed 's/\.Name = "//;s/"$//' | sort -u)

# Get client-used remotes
CLIENT_REMOTES=$(grep -rho ':WaitForChild("[^"]*")\|:FindFirstChild("[^"]*")' "$SRC_DIR/client" | grep -oP '"\K[^"]+' | sort -u)

# Check client remotes exist on server
MISSING=0
for remote in $CLIENT_REMOTES; do
    if ! echo "$SERVER_REMOTES" | grep -q "^${remote}$"; then
        # Could be a built-in or from another module
        if [[ "$remote" != "Humanoid" ]] && [[ "$remote" != "HumanoidRootPart" ]] && [[ "$remote" != "Shared" ]]; then
            warn "Client uses '$remote' - verify it's created on server"
            MISSING=$((MISSING + 1))
        fi
    fi
done

if [ "$MISSING" -eq 0 ]; then
    pass "Client remotes appear to match server"
fi

# ==========================================
# 7. CRITICAL SYSTEM PRESENCE
# ==========================================
echo ""
echo -e "${BLUE}── Critical Systems ──${NC}"

REQUIRED_SYSTEMS=(
    "World.server.luau:World/terrain generation"
    "Resources.server.luau:Resource spawning"
    "Survival.server.luau:Survival mechanics"
    "Creature.server.luau:Creatures/enemies"
    "Story.server.luau:Story/doom system"
)

for entry in "${REQUIRED_SYSTEMS[@]}"; do
    file="${entry%%:*}"
    desc="${entry##*:}"
    if [ -f "$SRC_DIR/server/$file" ]; then
        pass "$desc exists"
    else
        fail "Missing critical system: $desc ($file)"
    fi
done

# ==========================================
# SUMMARY
# ==========================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  GAME LOGIC CHECK COMPLETE${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}ERRORS: $ERRORS${NC}"
    exit 1
else
    echo -e "${GREEN}ALL GAME LOGIC CHECKS PASSED!${NC}"
fi
