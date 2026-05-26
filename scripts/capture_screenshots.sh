#!/bin/bash
set -euo pipefail

# Capture screenshots of Pocket NOC for App Store / Play Store submission.
#
# Usage:
#   ./scripts/capture_screenshots.sh
#
# Process:
#   1. Run the app on the simulator first (flutter run ... -d <id>)
#   2. Navigate to a screen you want to capture
#   3. Run this script — it captures the current simulator screen
#   4. Repeat for each screen
#
# Output:
#   store/screenshots/<device>/<NN>_<name>.png

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/store/screenshots"

# Detect booted simulator
DEVICE_UDID=$(xcrun simctl list devices booted 2>/dev/null | grep -oE '\([A-F0-9-]{36}\)' | tr -d '()' | head -1)
if [ -z "$DEVICE_UDID" ]; then
    echo "No booted iOS simulator found."
    echo "Boot one with: xcrun simctl boot <UDID>"
    echo "Then run: flutter run -d <UDID>"
    exit 1
fi

DEVICE_NAME=$(xcrun simctl list devices booted | grep -oE '(iPhone|iPad)[^()]+' | head -1 | xargs)
DEVICE_SLUG=$(echo "$DEVICE_NAME" | tr ' ' '_' | tr -d "'")
DEVICE_DIR="$OUT_DIR/$DEVICE_SLUG"
mkdir -p "$DEVICE_DIR"

# Find next available number
NEXT_NUM=$(ls "$DEVICE_DIR"/*.png 2>/dev/null | wc -l | xargs)
NEXT_NUM=$((NEXT_NUM + 1))
PADDED_NUM=$(printf "%02d" $NEXT_NUM)

# Get screen name from arg or prompt
NAME="${1:-screen}"
NAME=$(echo "$NAME" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')

OUTPUT="$DEVICE_DIR/${PADDED_NUM}_${NAME}.png"

xcrun simctl io "$DEVICE_UDID" screenshot "$OUTPUT"
echo "Captured: $OUTPUT"
echo ""

# Show all captured so far
echo "All screenshots for $DEVICE_NAME:"
ls -1 "$DEVICE_DIR" 2>/dev/null
