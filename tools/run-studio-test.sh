#!/bin/bash
# run-studio-test.sh - Wrapper for run-in-roblox with automatic cleanup
#
# Usage: ./tools/run-studio-test.sh <script.luau>
#
# This wrapper:
# 1. Kills any existing Studio instances (clean slate)
# 2. Builds the place file
# 3. Runs the test script
# 4. Kills Studio after completion (cleanup)

set -e

SCRIPT_PATH="$1"
PLACE_FILE="faultline-fear.rbxl"
PROJECT_FILE="faultline-fear.project.json"

if [ -z "$SCRIPT_PATH" ]; then
    echo "Usage: $0 <script.luau>"
    echo ""
    echo "Available test scripts:"
    echo "  tools/verify-game.luau              - 35 verification checks"
    echo "  tools/run-testez.luau               - 17 TestEZ BDD tests"
    echo "  tools/capture-world-screenshots.luau - 26 camera positions"
    exit 1
fi

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Error: Script not found: $SCRIPT_PATH"
    exit 1
fi

echo "╔════════════════════════════════════════════════╗"
echo "║  STUDIO TEST RUNNER (with automatic cleanup)   ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Step 1: Kill any existing Studio instances
kill_studio() {
    # Get PIDs and kill them directly (more reliable than pkill on macOS)
    local PIDS=$(pgrep -f "RobloxStudio" 2>/dev/null)
    if [ -n "$PIDS" ]; then
        echo "$PIDS" | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
}

EXISTING=$(pgrep -f "RobloxStudio" 2>/dev/null | wc -l | tr -d ' ')
if [ "$EXISTING" -gt "0" ]; then
    echo "[Cleanup] Killing $EXISTING existing Studio instance(s)..."
    kill_studio
fi

# Step 2: Build place file
echo "[Build] Building $PLACE_FILE..."
rojo build "$PROJECT_FILE" -o "$PLACE_FILE"

# Step 3: Run test (capture exit code)
echo "[Run] Executing $SCRIPT_PATH in Studio..."
echo ""
set +e
run-in-roblox --place "$PLACE_FILE" --script "$SCRIPT_PATH"
EXIT_CODE=$?
set -e

# Step 4: Cleanup - kill Studio
echo ""
echo "[Cleanup] Killing Studio..."
kill_studio

# Report result
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Test completed successfully"
else
    echo "❌ Test failed with exit code $EXIT_CODE"
fi

exit $EXIT_CODE
