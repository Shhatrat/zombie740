#!/bin/bash
# Build all ZOMBIE740 variants sequentially
# Skips variants that are already up to date (same-day build exists)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATESTAMP=$(date +%Y%m%d)
VARIANTS="bridge mini secure vpn"

echo "=== ZOMBIE740 build-all ==="
echo "Date: $DATESTAMP"
echo "Variants: $VARIANTS"
echo ""

for VARIANT in $VARIANTS; do
    EXISTING=$(ls "$SCRIPT_DIR/zombie740-${VARIANT}-sysupgrade-${DATESTAMP}.bin" 2>/dev/null || true)
    if [ -n "$EXISTING" ]; then
        echo "--- SKIP $VARIANT (already built today: $EXISTING)"
        continue
    fi
    echo "--- BUILD $VARIANT ---"
    bash "$SCRIPT_DIR/build-${VARIANT}.sh"
    echo ""
done

echo "=== Done. Built images: ==="
ls -lh "$SCRIPT_DIR"/zombie740-*-sysupgrade-*.bin 2>/dev/null || echo "No images found"
