#!/bin/bash
# ZOMBIE740-REPEATER: WiFi client (STA) as WAN, LAN ports bridged, NAT, DHCP, web panel
# Tabs: Status (WiFi signal, LAN clients), WiFi (SSID/key config), WoL (etherwake), System (sysupgrade)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENWRT_DIR="$SCRIPT_DIR/openwrt"
CONFIGS_DIR="$SCRIPT_DIR/configs"
FILES_COMMON="$SCRIPT_DIR/files-common"
FILES_VARIANT="$SCRIPT_DIR/files-variants/repeater"
OUTPUT_DIR="$SCRIPT_DIR"
VARIANT="repeater"
LOG="$SCRIPT_DIR/build-${VARIANT}.log"

echo "=== ZOMBIE740-REPEATER build ==="
echo "Log: $LOG"

rm -rf "$OPENWRT_DIR/files"
cp -r "$FILES_COMMON" "$OPENWRT_DIR/files"
cp -r "$FILES_VARIANT/." "$OPENWRT_DIR/files/"

# Make CGI scripts executable in the image
chmod +x "$OPENWRT_DIR/files/www/cgi-bin/"* 2>/dev/null || true

cp "$CONFIGS_DIR/${VARIANT}.config" "$OPENWRT_DIR/.config"

cd "$OPENWRT_DIR"
chown -R "$(stat -c '%u:%g' "$OPENWRT_DIR")" "$OPENWRT_DIR/tmp" 2>/dev/null || true
echo "Starting build at $(date)"
FORCE_UNSAFE_CONFIGURE=1 make -j$(nproc) 2>&1 | tee "$LOG"

BINDIR="$OPENWRT_DIR/bin/targets/ath79/tiny"
DATESTAMP=$(date +%Y%m%d)

SYS_V4=$(find "$BINDIR" -name "*wr740n-v4*sysupgrade.bin" 2>/dev/null | head -1)
FAC_V4=$(find "$BINDIR" -name "*wr740n-v4*factory.bin" 2>/dev/null | head -1)

if [ -z "$SYS_V4" ]; then
    echo "ERROR: v4 sysupgrade.bin not found!" >&2
    exit 1
fi

echo "=== SUCCESS ==="
cp "$SYS_V4" "$OUTPUT_DIR/zombie740-${VARIANT}-sysupgrade-${DATESTAMP}.bin"
[ -n "$FAC_V4" ] && cp "$FAC_V4" "$OUTPUT_DIR/zombie740-${VARIANT}-factory-${DATESTAMP}.bin"
echo "v4: $(du -sh "$SYS_V4" | cut -f1)"
echo "Saved to: $OUTPUT_DIR/zombie740-${VARIANT}-*-${DATESTAMP}.bin"
