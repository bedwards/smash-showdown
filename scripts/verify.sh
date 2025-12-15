#!/bin/bash
# Mertin-Flemmer Verification System
# Run locally: ./scripts/verify.sh
# Runs static analysis, sanity checks, and game-specific validation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$PROJECT_ROOT/src/mertin-flemmer"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  MERTIN-FLEMMER VERIFICATION SYSTEM${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ERRORS=$((ERRORS + 1))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

section() {
    echo ""
    echo -e "${BLUE}── $1 ──${NC}"
}

# ==========================================
# 1. FILE STRUCTURE VALIDATION
# ==========================================
section "File Structure"

# Check required directories exist
for dir in "server" "client" "shared"; do
    if [ -d "$SRC_DIR/$dir" ]; then
        pass "Directory exists: $dir/"
    else
        fail "Missing directory: $dir/"
    fi
done

# Check server scripts are in server folder
for file in "$SRC_DIR/server"/*.luau; do
    if [[ "$file" == *".server.luau" ]]; then
        pass "Server script correctly named: $(basename "$file")"
    elif [[ "$file" == *".luau" ]] && [[ "$file" != *".server.luau" ]]; then
        warn "Server file without .server.luau suffix: $(basename "$file")"
    fi
done

# Check client scripts are in client folder
for file in "$SRC_DIR/client"/*.luau; do
    if [[ "$file" == *".client.luau" ]]; then
        pass "Client script correctly named: $(basename "$file")"
    elif [[ "$file" == *".luau" ]] && [[ "$file" != *".client.luau" ]]; then
        warn "Client file without .client.luau suffix: $(basename "$file")"
    fi
done

# ==========================================
# 2. SYNTAX AND STRICT MODE
# ==========================================
section "Syntax & Strict Mode"

# Check all Luau files have --!strict
for file in $(find "$SRC_DIR" -name "*.luau" -type f); do
    filename=$(basename "$file")
    if head -1 "$file" | grep -q "^--!strict"; then
        pass "Strict mode enabled: $filename"
    else
        fail "Missing --!strict: $filename"
    fi
done

# Basic syntax check (look for common Luau syntax errors)
for file in $(find "$SRC_DIR" -name "*.luau" -type f); do
    filename=$(basename "$file")

    # Check for mismatched brackets
    opens=$(grep -o '{' "$file" | wc -l)
    closes=$(grep -o '}' "$file" | wc -l)
    if [ "$opens" -ne "$closes" ]; then
        fail "Mismatched braces in $filename: { = $opens, } = $closes"
    fi

    # Check for unclosed strings (very basic)
    if grep -Pn '^\s*[^-]*"[^"]*$' "$file" > /dev/null 2>&1; then
        warn "Possible unclosed string in $filename"
    fi
done

# ==========================================
# 3. SECURITY CHECKS
# ==========================================
section "Security"

# Forbidden patterns
FORBIDDEN_PATTERNS=(
    "loadstring"
    "getfenv"
    "setfenv"
    "rawset.*_G"
    "debug\.set"
    "password.*=.*[\"']"
    "api_key.*=.*[\"']"
    "secret.*=.*[\"']"
)

for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    matches=$(grep -rn "$pattern" "$SRC_DIR" --include="*.luau" 2>/dev/null || true)
    if [ -n "$matches" ]; then
        fail "Forbidden pattern '$pattern' found:"
        echo "$matches" | head -5
    else
        pass "No forbidden pattern: $pattern"
    fi
done

# ==========================================
# 4. REMOTE EVENT VALIDATION
# ==========================================
section "Remote Events"

# Extract all RemoteEvent creations from server
SERVER_REMOTES=$(grep -rho 'Instance\.new("RemoteEvent")' "$SRC_DIR/server" --include="*.luau" -A2 | grep -o '\.Name = "[^"]*"' | sed 's/\.Name = "//;s/"$//' | sort -u)

# Extract all RemoteEvent usages from client
CLIENT_REMOTE_REFS=$(grep -rho 'ReplicatedStorage:WaitForChild("[^"]*")' "$SRC_DIR/client" --include="*.luau" | sed 's/.*WaitForChild("//;s/").*//' | sort -u)
CLIENT_REMOTE_REFS2=$(grep -rho 'ReplicatedStorage:FindFirstChild("[^"]*")' "$SRC_DIR/client" --include="*.luau" | sed 's/.*FindFirstChild("//;s/").*//' | sort -u)

# Check for duplicate remote names
DUPE_REMOTES=$(echo "$SERVER_REMOTES" | uniq -d)
if [ -n "$DUPE_REMOTES" ]; then
    fail "Duplicate RemoteEvent names found:"
    echo "$DUPE_REMOTES"
else
    pass "No duplicate RemoteEvent names"
fi

# Count remotes
REMOTE_COUNT=$(echo "$SERVER_REMOTES" | wc -l)
info "Found $REMOTE_COUNT RemoteEvents defined on server"

# ==========================================
# 5. GROUND AND WORLD CHECKS (CRITICAL!)
# ==========================================
section "Ground & World (CRITICAL)"

# CHECK #1: Does ground exist?
if grep -q "Ground_Main\|Baseplate\|createGround" "$SRC_DIR/server/World.server.luau" 2>/dev/null; then
    pass "Ground creation found in World.server.luau"
else
    fail "NO GROUND FOUND! Players will fall through the world!"
fi

# Check ground has CanCollide = true
if grep -A5 "Ground_Main" "$SRC_DIR/server/World.server.luau" 2>/dev/null | grep -q "CanCollide = true"; then
    pass "Ground is collidable"
else
    fail "Ground may not be collidable - players could fall through!"
fi

# Check ground is anchored
if grep -A5 "Ground_Main" "$SRC_DIR/server/World.server.luau" 2>/dev/null | grep -q "Anchored = true"; then
    pass "Ground is anchored"
else
    fail "Ground is not anchored - it could fall!"
fi

# Check WORLD_SIZE is reasonable
WORLD_SIZE=$(grep -o "WORLD_SIZE = [0-9]*" "$SRC_DIR/server/World.server.luau" 2>/dev/null | grep -o "[0-9]*" || echo "0")
if [ "$WORLD_SIZE" -ge 1000 ]; then
    pass "World size is large: $WORLD_SIZE studs"
else
    warn "World size may be too small: $WORLD_SIZE studs"
fi

# Check ground size covers world
GROUND_MULTIPLIER=$(grep "WORLD_SIZE \* [0-9.]*" "$SRC_DIR/server/World.server.luau" 2>/dev/null | grep -o "\* [0-9.]*" | head -1 | grep -o "[0-9.]*" || echo "1")
info "Ground extends $GROUND_MULTIPLIER x WORLD_SIZE"

# ==========================================
# 6. GAME-SPECIFIC SANITY CHECKS
# ==========================================
section "Game Sanity Checks"

# Check spawn point isn't inside a mountain
if grep -q "basePosition = Vector3.new(0," "$SRC_DIR/server/Mountains.server.luau" 2>/dev/null; then
    fail "Mountain base at origin could block spawn!"
else
    pass "No mountains at spawn origin"
fi

# Check hunger drain is reasonable (1-20 per minute)
HUNGER_DRAIN=$(grep -o "HUNGER_DRAIN = [0-9]*" "$SRC_DIR/shared/init.luau" 2>/dev/null | grep -o "[0-9]*" || echo "0")
if [ "$HUNGER_DRAIN" -gt 0 ] && [ "$HUNGER_DRAIN" -le 20 ]; then
    pass "Hunger drain is reasonable: $HUNGER_DRAIN/min"
elif [ "$HUNGER_DRAIN" -gt 20 ]; then
    warn "Hunger drain very high: $HUNGER_DRAIN/min (players will starve fast!)"
else
    info "Could not determine hunger drain"
fi

# Check for print statements (debug pollution)
PRINT_COUNT=$(grep -rc "print(" "$SRC_DIR" --include="*.luau" | awk -F: '{sum += $2} END {print sum}')
if [ "$PRINT_COUNT" -gt 100 ]; then
    warn "High number of print() calls: $PRINT_COUNT (consider reducing for production)"
else
    pass "Reasonable print() count: $PRINT_COUNT"
fi

# Check companion scale is reasonable
COMPANION_SCALE=$(grep -o "local SCALE = [0-9.]*" "$SRC_DIR/server/Companion.server.luau" 2>/dev/null | grep -o "[0-9.]*" || echo "1")
if [ -n "$COMPANION_SCALE" ]; then
    # Using bc for float comparison
    if echo "$COMPANION_SCALE < 0.3" | bc -l | grep -q "1"; then
        warn "Companion scale very small: $COMPANION_SCALE"
    elif echo "$COMPANION_SCALE > 1.5" | bc -l | grep -q "1"; then
        fail "Companion scale too large: $COMPANION_SCALE (won't fit through doors!)"
    else
        pass "Companion scale reasonable: $COMPANION_SCALE"
    fi
fi

# ==========================================
# 6. POSITION OVERLAP CHECK
# ==========================================
section "Position Conflicts"

# Extract major structure positions and check for overlaps
# This is a simplified check - in production you'd want more sophisticated collision detection

# Get spawn area (assumed at origin)
SPAWN_AREA="0,0"

# Check no major structures at spawn
STRUCTURES_AT_SPAWN=$(grep -rn "Vector3.new(0, [0-9]*, 0)" "$SRC_DIR/server" --include="*.luau" | grep -v "spawnPoint\|SPAWN\|spawn" | head -5)
if [ -n "$STRUCTURES_AT_SPAWN" ]; then
    warn "Structures possibly at spawn point:"
    echo "$STRUCTURES_AT_SPAWN"
else
    pass "No obvious structures blocking spawn"
fi

# ==========================================
# 7. RESOURCE LIMITS
# ==========================================
section "Resource Limits"

# Check for potentially expensive operations in Heartbeat
HEARTBEAT_LINES=$(grep -A 20 "Heartbeat:Connect" "$SRC_DIR/server"/*.luau 2>/dev/null | wc -l)
info "Heartbeat connection code: ~$HEARTBEAT_LINES lines"

if [ "$HEARTBEAT_LINES" -gt 200 ]; then
    warn "Heavy Heartbeat usage detected - may impact performance"
fi

# Count total Parts that might be created
INSTANCE_NEW_COUNT=$(grep -rc 'Instance.new("Part")' "$SRC_DIR" --include="*.luau" | awk -F: '{sum += $2} END {print sum}')
info "Part creation calls: $INSTANCE_NEW_COUNT"

# ==========================================
# 8. CODE QUALITY
# ==========================================
section "Code Quality"

# Check for TODO/FIXME/HACK comments
TODOS=$(grep -rn "TODO\|FIXME\|HACK\|XXX" "$SRC_DIR" --include="*.luau" 2>/dev/null || true)
TODO_COUNT=$(echo "$TODOS" | grep -c "." || echo "0")
if [ "$TODO_COUNT" -gt 0 ]; then
    warn "Found $TODO_COUNT TODO/FIXME comments:"
    echo "$TODOS" | head -10
else
    pass "No TODO/FIXME comments"
fi

# Check for commented-out code blocks
COMMENTED_CODE=$(grep -rn "^--.*function\|^--.*local.*=\|^--.*end$" "$SRC_DIR" --include="*.luau" 2>/dev/null | wc -l)
if [ "$COMMENTED_CODE" -gt 20 ]; then
    warn "Many commented code lines: $COMMENTED_CODE (consider cleanup)"
else
    pass "Commented code lines: $COMMENTED_CODE"
fi

# ==========================================
# 9. REQUIRED PATTERNS
# ==========================================
section "Required Patterns"

# All server scripts should validate player input
for file in "$SRC_DIR/server"/*.luau; do
    filename=$(basename "$file")
    if grep -q "OnServerEvent" "$file"; then
        if grep -q "if not.*player\|if.*player.*nil\|if not.*character" "$file"; then
            pass "Player validation in: $filename"
        else
            warn "OnServerEvent without obvious player validation: $filename"
        fi
    fi
done

# ==========================================
# SUMMARY
# ==========================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  VERIFICATION COMPLETE${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}ERRORS: $ERRORS${NC}"
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}WARNINGS: $WARNINGS${NC}"
fi

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}ALL CHECKS PASSED!${NC}"
fi

echo ""

# Exit with error if there were failures
if [ $ERRORS -gt 0 ]; then
    exit 1
fi

exit 0
