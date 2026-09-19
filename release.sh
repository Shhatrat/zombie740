#!/bin/bash
# Auto-release: update README + create GitHub release with all new .bin files
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
DATE=$(date +%Y%m%d)
TAG="v24.10-${DATE}-2"

echo "=== ZOMBIE740 release ===" | tee /tmp/release.log

# Check all expected binaries exist
MISSING=0
for v in secure-web secure-web-en bridge-wifi mini-wifi; do
    f="zombie740-${v}-sysupgrade-${DATE}.bin"
    if [ ! -f "$f" ]; then
        echo "MISSING: $f" | tee -a /tmp/release.log
        MISSING=1
    else
        SIZE=$(du -sh "$f" | cut -f1)
        echo "OK: $f ($SIZE)" | tee -a /tmp/release.log
    fi
done

if [ "$MISSING" = "1" ]; then
    echo "Aborting — missing binaries." | tee -a /tmp/release.log
    exit 1
fi

# Get sizes for README
SW_SIZE=$(du -sh "zombie740-secure-web-sysupgrade-${DATE}.bin" | cut -f1)
SWEN_SIZE=$(du -sh "zombie740-secure-web-en-sysupgrade-${DATE}.bin" | cut -f1)
BW_SIZE=$(du -sh "zombie740-bridge-wifi-sysupgrade-${DATE}.bin" | cut -f1)
MW_SIZE=$(du -sh "zombie740-mini-wifi-sysupgrade-${DATE}.bin" | cut -f1)

echo "Sizes: secure-web=$SW_SIZE secure-web-en=$SWEN_SIZE bridge-wifi=$BW_SIZE mini-wifi=$MW_SIZE" | tee -a /tmp/release.log

git add -A
git commit -m "feat: add bridge-wifi, mini-wifi variants; web panel +portfw, logs, routes, LED, SSH keys, backup, WoL, iperf3, SVG charts" || true

# Create release notes
NOTES=$(cat << EOF
## ZOMBIE740 v24.10 — $(date +%Y-%m-%d)

### New variants
- 📶 **BRIDGE-WIFI** (~${BW_SIZE}) — L2 bridge + WiFi AP. SSID: \`ZOMBIE740\`, WPA2: \`zombie740\`
- 📶 **MINI-WIFI** (~${MW_SIZE}) — MINI + WiFi AP. DHCP+DNS on LAN. SSID: \`ZOMBIE740\`, WPA2: \`zombie740\`

### Web panel — new features (SECURE-WEB / SECURE-WEB-EN)
- **Port forwarding** — DNAT rules via UCI (new tab)
- **Logs** — logread with grep + level filter (new tab)
- **Static routes** — add/delete via UCI (Network tab)
- **Backup/restore** — download/restore /etc/config/ tar.gz (System tab)
- **LED control** — /sys/class/leds/ triggers (System tab)
- **SSH key management** — authorized_keys UI (System tab)
- **Wake-on-LAN** — etherwake (Diagnostics tab)
- **iperf3** — 5s bandwidth test (Diagnostics tab)
- **Conntrack viewer** — /proc/net/nf_conntrack (Diagnostics tab)
- **SVG gauges** — RAM and load bar charts on Status page
- **Bug fix** — EN panel logout link was garbled

### Packages added
- \`etherwake\` and \`iperf3\` included in SECURE-WEB and SECURE-WEB-EN

### Default WiFi credentials (bridge-wifi / mini-wifi)
| Setting | Value |
|---|---|
| SSID | \`ZOMBIE740\` |
| Password | \`zombie740\` ← **change this** |
| Band | 2.4 GHz b/g/n |
| Channel | auto |
| Country | PL |
EOF
)

gh release create "$TAG" \
    zombie740-secure-web-sysupgrade-${DATE}.bin \
    zombie740-secure-web-factory-${DATE}.bin \
    zombie740-secure-web-en-sysupgrade-${DATE}.bin \
    zombie740-secure-web-en-factory-${DATE}.bin \
    zombie740-bridge-wifi-sysupgrade-${DATE}.bin \
    zombie740-bridge-wifi-factory-${DATE}.bin \
    zombie740-mini-wifi-sysupgrade-${DATE}.bin \
    zombie740-mini-wifi-factory-${DATE}.bin \
    --title "ZOMBIE740 v24.10 ($(date +%Y-%m-%d)) — WiFi variants + web panel update" \
    --notes "$NOTES" \
    --latest \
    2>&1 | tee -a /tmp/release.log

echo "=== Release done: $TAG ===" | tee -a /tmp/release.log
