#!/bin/bash
# ZOMBIE740-SECURE: SSH + DHCP/DNS + firewall4 + nftables
# Edge router, DROP WAN, masquerade, SSH LAN-only
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENWRT_DIR="$SCRIPT_DIR/openwrt"
CONFIGS_DIR="$SCRIPT_DIR/configs"
FILES_COMMON="$SCRIPT_DIR/files-common"
FILES_VARIANT="$SCRIPT_DIR/files-variants/secure"
OUTPUT_DIR="$SCRIPT_DIR"
VARIANT="secure"
LOG="$SCRIPT_DIR/build-${VARIANT}.log"

echo "=== ZOMBIE740-SECURE build ==="
echo "Log: $LOG"

# Prepare files/ directory
rm -rf "$OPENWRT_DIR/files"
cp -r "$FILES_COMMON" "$OPENWRT_DIR/files"
cp -r "$FILES_VARIANT/." "$OPENWRT_DIR/files/"

# Apply config
cp "$CONFIGS_DIR/${VARIANT}.config" "$OPENWRT_DIR/.config"

# Clean stale gcc artifacts from previous interrupted builds
cd "$OPENWRT_DIR"
rm -rf build_dir/toolchain-*/gcc-*-initial build_dir/toolchain-*/gcc-*-final 2>/dev/null || true

# Fix ownership if needed (root-owned files from pct exec)
chown -R "$(stat -c '%u:%g' "$OPENWRT_DIR")" "$OPENWRT_DIR/tmp" 2>/dev/null || true

echo "Starting build at $(date)"
FORCE_UNSAFE_CONFIGURE=1 make -j$(nproc) 2>&1 | tee "$LOG"

# Check result
BINDIR="$OPENWRT_DIR/bin/targets/ath79/tiny"
DATESTAMP=$(date +%Y%m%d)

SYS_V4=$(find "$BINDIR" -name "*wr740n-v4*sysupgrade.bin" 2>/dev/null | head -1)
FAC_V4=$(find "$BINDIR" -name "*wr740n-v4*factory.bin" 2>/dev/null | head -1)
SYS_V5=$(find "$BINDIR" -name "*wr740n-v5*sysupgrade.bin" 2>/dev/null | head -1)
FAC_V5=$(find "$BINDIR" -name "*wr740n-v5*factory.bin" 2>/dev/null | head -1)

if [ -z "$SYS_V4" ]; then
    echo "ERROR: v4 sysupgrade.bin not found!" >&2
    exit 1
fi

echo "=== SUCCESS ==="
cp "$SYS_V4" "$OUTPUT_DIR/zombie740-${VARIANT}-sysupgrade-${DATESTAMP}.bin"
[ -n "$FAC_V4" ] && cp "$FAC_V4" "$OUTPUT_DIR/zombie740-${VARIANT}-factory-${DATESTAMP}.bin"
echo "v4: $(du -sh "$SYS_V4" | cut -f1)"

if [ -n "$SYS_V5" ]; then
    cp "$SYS_V5" "$OUTPUT_DIR/zombie740-${VARIANT}-v5-sysupgrade-${DATESTAMP}.bin"
    [ -n "$FAC_V5" ] && cp "$FAC_V5" "$OUTPUT_DIR/zombie740-${VARIANT}-v5-factory-${DATESTAMP}.bin"
    echo "v5: $(du -sh "$SYS_V5" | cut -f1)"
fi

echo "Saved to: $OUTPUT_DIR/zombie740-${VARIANT}-*-${DATESTAMP}.bin"
