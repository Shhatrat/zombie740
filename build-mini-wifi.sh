#!/bin/bash
# ZOMBIE740-MINI-WIFI: DHCP+DNS on LAN, WiFi AP (SSID: ZOMBIE740, WPA2: zombie740)
# Based on MINI but adds kmod-ath9k + hostapd-mini (~650KB total WiFi overhead)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENWRT_DIR="$SCRIPT_DIR/openwrt"
CONFIGS_DIR="$SCRIPT_DIR/configs"
FILES_COMMON="$SCRIPT_DIR/files-common"
FILES_VARIANT="$SCRIPT_DIR/files-variants/mini-wifi"
OUTPUT_DIR="$SCRIPT_DIR"
VARIANT="mini-wifi"
LOG="$SCRIPT_DIR/build-${VARIANT}.log"

echo "=== ZOMBIE740-MINI-WIFI build ==="
echo "Log: $LOG"

rm -rf "$OPENWRT_DIR/files"
cp -r "$FILES_COMMON" "$OPENWRT_DIR/files"
cp -r "$FILES_VARIANT/." "$OPENWRT_DIR/files/"

cp "$CONFIGS_DIR/${VARIANT}.config" "$OPENWRT_DIR/.config"

cd "$OPENWRT_DIR"
rm -rf build_dir/toolchain-*/gcc-*-initial build_dir/toolchain-*/gcc-*-final 2>/dev/null || true
chown -R "$(stat -c '%u:%g' "$OPENWRT_DIR")" "$OPENWRT_DIR/tmp" 2>/dev/null || true

echo "Starting build at $(date)"
FORCE_UNSAFE_CONFIGURE=1 make -j1 2>&1 | tee "$LOG"

SYSUPGRADE=$(find "$OPENWRT_DIR/bin/targets/ath79/tiny/" -name "*sysupgrade.bin" 2>/dev/null | head -1)
FACTORY=$(find "$OPENWRT_DIR/bin/targets/ath79/tiny/" -name "*factory.bin" 2>/dev/null | head -1)

if [ -z "$SYSUPGRADE" ]; then
    echo "ERROR: sysupgrade.bin not found!" >&2
    exit 1
fi

SIZE=$(du -sh "$SYSUPGRADE" | cut -f1)
echo "=== SUCCESS: sysupgrade.bin $SIZE ==="

DATESTAMP=$(date +%Y%m%d)
cp "$SYSUPGRADE" "$OUTPUT_DIR/zombie740-${VARIANT}-sysupgrade-${DATESTAMP}.bin"
[ -n "$FACTORY" ] && cp "$FACTORY" "$OUTPUT_DIR/zombie740-${VARIANT}-factory-${DATESTAMP}.bin"
echo "Saved to: $OUTPUT_DIR/zombie740-${VARIANT}-*-${DATESTAMP}.bin"
