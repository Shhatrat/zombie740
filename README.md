```
  ______  ___  __  __ ____ ___ _____  ____  _  _  ___
 |___  / / _ \|  \/  | __ )_ _| ____||__  || || |/ _ \
    / / | | | | |\/| |  _ \| ||  _|    / / | || | | | |
   / /  | |_| | |  | | |_) | || |___  / /  |__  | |_| |
  /_/    \___/|_|  |_|____/___|_____| /_/      |_|\___/

          by shhatrat  ::  TL-WR740N v4  ::  OpenWrt 24.10
  ----------------------------------------------------------
   ath79 | AR9331 400MHz MIPS | 4MB flash | 32MB RAM
  ----------------------------------------------------------
```

# ZOMBIE740

> *This router was supposed to be dead. It's not.*

![I'm tired boss](docs/tired.jpg)

Custom **OpenWrt 24.10** firmware for the **TP-Link TL-WR740N v4** — a 2011 router with 4MB flash that most people threw away years ago. ZOMBIE740 squeezes a modern kernel (6.6.151), firewall4/nftables, WireGuard and DHCP/DNS into 4MB with baked-in configs so the router is ready to use immediately after flashing — no manual configuration needed.

**Pre-built firmware binaries → [Releases](../../releases)**

---

## Hardware

| | |
|---|---|
| **Device** | TP-Link TL-WR740N v4 |
| **SoC** | Qualcomm Atheros AR9331 (MIPS 24Kc, 400 MHz) |
| **RAM** | 32 MB |
| **Flash** | 4 MB SPI NOR |
| **Switch** | AR8229 (4x LAN + 1x WAN, 100 Mbps) |
| **WiFi** | AR9330 2.4 GHz b/g/n (see [WiFi note](#wifi)) |
| **OpenWrt target** | `ath79/tiny` |
| **Kernel** | 6.6.151 |
| **Flash budget** | 3904 kB (3.81 MB) for sysupgrade |

---

## Variants

Eight variants fit in 4MB flash. Pick one based on your use case.

| Variant | Size | Use case |
|---|---|---|
| 🟢 **BRIDGE** | ~3.0 MB | Dumb switch / L2 bridge. All ports in one segment, no routing, no DHCP. Just SSH management. |
| 📶 **BRIDGE-WIFI** | ~3.6 MB | Like BRIDGE + WiFi AP. SSID: `ZOMBIE740`, WPA2: `zombie740`. |
| 🟡 **MINI** | ~3.1 MB | Second router behind your main router. DHCP+DNS on LAN, no firewall (not for WAN exposure). |
| 📶 **MINI-WIFI** | ~3.6 MB | Like MINI + WiFi AP. DHCP+DNS on LAN. SSID: `ZOMBIE740`, WPA2: `zombie740`. |
| 🔴 **SECURE** | ~3.5 MB | Edge router. Full firewall, DROP WAN, NAT/masquerade, DHCP+DNS, SSH LAN-only. |
| 🌐 **SECURE-WEB** | ~3.6 MB | Like SECURE + shell CGI web panel in Polish at `http://192.168.1.1`. |
| 🌐 **SECURE-WEB-EN** | ~3.6 MB | Like SECURE-WEB but with English web panel. |
| 🔵 **VPN** | ~3.0 MB | VPN gateway. Like SECURE but routes LAN traffic through a WireGuard tunnel. |

### Package comparison

| Package | BRIDGE | BRIDGE-WIFI | MINI | MINI-WIFI | SECURE | SECURE-WEB(-EN) | VPN |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| dropbear (SSH) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| dnsmasq (DHCP+DNS) | — | — | ✅ | ✅ | ✅ | ✅ | ✅ |
| firewall4 | — | — | — | — | ✅ | ✅ | ✅ |
| nftables | — | — | — | — | ✅ | ✅ | ✅ |
| uhttpd (web server) | — | — | — | — | — | ✅ | — |
| kmod-wireguard | — | — | — | — | — | — | ✅ |
| wireguard-tools | — | — | — | — | — | — | ✅ |
| swconfig (VLAN) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| netifd | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| mtd (flash tool) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| kmod-ath9k (WiFi) | — | ✅ | — | ✅ | — | — | — |
| hostapd / wpad | — | wpad | — | hostapd-mini | — | — | — |
| etherwake (WoL) | — | — | — | — | — | ✅ | — |
| iperf3 | — | — | — | — | — | ✅ | — |
| LuCI (web UI) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

### What's baked in (all variants)

| Setting | Value |
|---|---|
| LAN IP | `192.168.1.1/24` |
| SSH port | `22` (LAN only) |
| Root password | `admin` ← **change this** |
| SSH banner | ZOMBIE740 ASCII art |
| Hostname | `OpenWrt` |
| Timezone | `CET-1CEST` (Europe/Warsaw) |
| NTP | openwrt.pool.ntp.org |

### SECURE / VPN firewall defaults

| Direction | Action |
|---|---|
| LAN → WAN | ✅ ACCEPT + masquerade |
| WAN → router | ❌ DROP |
| WAN → LAN | ❌ DROP |
| LAN → router (SSH) | ✅ ACCEPT |
| SYN flood protection | ✅ enabled |

### SECURE-WEB panel

The SECURE-WEB and SECURE-WEB-EN variants add a lightweight web panel (uhttpd + shell CGI + PicoCSS dark theme) served at `http://192.168.1.1`. SECURE-WEB is in Polish, SECURE-WEB-EN in English — identical functionality.

| Page | URL | Description |
|---|---|---|
| Status | `/cgi-bin/status` | Uptime, RAM, load, firewall state, DHCP leases, system logs |
| Network | `/cgi-bin/network` | LAN/WAN config (DHCP/static/PPPoE), interface list |
| DHCP/DNS | `/cgi-bin/dhcp` | Pool, lease time, DNS servers, static assignments |
| Firewall | `/cgi-bin/firewall` | nft ruleset view, start/stop, add/delete UCI rules |
| VLAN | `/cgi-bin/vlan` | Switch VLAN config (AR8229), port map, add/delete VLANs, bridge interfaces |
| Diagnostics | `/cgi-bin/diag` | Ping, traceroute, DNS lookup, routing table, active connections |
| System | `/cgi-bin/system` | Hostname, password, NTP sync, reboot, sysupgrade flash |

**Default login:** `admin` / `admin` (Digest auth — change immediately)

To change the password on the router:
```bash
# On the router via SSH
echo "admin:ZOMBIE740:$(echo -n 'admin:ZOMBIE740:newpassword' | md5sum | cut -c1-32)" > /etc/uhttpd.auth
/etc/init.d/uhttpd reload
```

> No HTTPS — web panel is only accessible from LAN (firewall blocks WAN access).

---

## Download

Pre-built binaries are attached to each [Release](../../releases).

| File | Purpose |
|---|---|
| `zombie740-<variant>-factory-<date>.bin` | First flash from stock TP-Link firmware |
| `zombie740-<variant>-sysupgrade-<date>.bin` | Upgrade from existing OpenWrt |

---

## Flashing

### First flash — stock TP-Link → OpenWrt

> Use the **factory** image.

1. Connect your PC to one of the **LAN ports** (not WAN)
2. Open the TP-Link web UI: **http://192.168.0.1** (default login: `admin` / `admin`)
3. Go to **System Tools → Firmware Upgrade**
4. Select `zombie740-<variant>-factory-<date>.bin` → click **Upgrade**
5. Wait ~90 seconds — the router reboots automatically
6. The power LED blinks rapidly during flash, then goes solid when done
7. New IP: **192.168.1.1** — connect via SSH:
   ```bash
   ssh root@192.168.1.1
   # password: admin
   ```

> ⚠️ Do not power off during flashing. If the power LED is blinking fast — wait.

### Upgrade — OpenWrt → OpenWrt

> Use the **sysupgrade** image.

```bash
# Copy image to router
scp zombie740-secure-sysupgrade-20260919.bin root@192.168.1.1:/tmp/

# Flash and reboot (connection will drop — that's normal)
ssh root@192.168.1.1 'mtd -r write /tmp/zombie740-secure-sysupgrade-20260919.bin firmware'
```

Router reboots in ~60 seconds. Config is baked-in, no setup needed after reboot.

### Switching variants

Same process as upgrade — just flash the sysupgrade image of the new variant.

---

## After flashing

```bash
ssh root@192.168.1.1   # password: admin

# Change root password immediately
passwd

# Check system status
uptime
cat /proc/meminfo | grep MemFree
ip addr

# SECURE/VPN: check firewall
nft list ruleset

# Check DHCP leases (MINI/SECURE/VPN)
cat /tmp/dhcp.leases
```

### WireGuard setup (VPN variant)

After flashing, configure your WireGuard peer:

```bash
# Generate keys on the router
wg genkey | tee /tmp/privkey | wg pubkey > /tmp/pubkey
cat /tmp/privkey /tmp/pubkey

# Edit the interface config
uci set network.vpn.private_key="$(cat /tmp/privkey)"
uci commit network

# Add a peer (your VPN server)
uci set network.vpnpeer=wireguard_vpn
uci set network.vpnpeer.public_key="<server_pubkey>"
uci set network.vpnpeer.endpoint_host="<server_ip>"
uci set network.vpnpeer.endpoint_port="51820"
uci set network.vpnpeer.allowed_ips="0.0.0.0/0"
uci commit network
/etc/init.d/network restart
```

---

## Building from source

### Prerequisites

```bash
# Arch Linux
pacman -S base-devel git ncurses zlib gawk gettext unzip python3 perl wget rsync

# Ubuntu / Debian
apt install build-essential git libncurses5-dev zlib1g-dev gawk gettext \
    unzip python3 python3-distutils perl wget rsync
```

### First-time setup

```bash
git clone https://git.openwrt.org/openwrt/openwrt.git
cd openwrt
git checkout v24.10.0
./scripts/feeds update -a
./scripts/feeds install -a
```

### Build

```bash
# Single variant
bash build-secure.sh

# All variants (skips already-built ones)
bash build-all.sh
```

Build times (i7-3720QM, `-j1` for thermal safety):

| Phase | Time |
|---|---|
| Full build (first time, toolchain + kernel + packages) | ~90 min |
| Subsequent variant (toolchain + kernel cached) | ~20–30 min |
| Image-only rebuild (e.g. config change) | ~5 min |

> `-j1` keeps CPU under 75°C on laptops. Use `-j$(nproc)` on a desktop with good cooling.

### Repository structure

```
zombie740/
├── README.md
├── build-all.sh              ← build all variants sequentially
├── build-bridge.sh
├── build-mini.sh
├── build-secure.sh
├── build-secure-web.sh
├── build-vpn.sh
├── configs/
│   ├── bridge.config         ← OpenWrt .config per variant
│   ├── mini.config
│   ├── secure.config
│   ├── secure-web.config     ← secure + uhttpd
│   └── vpn.config
├── files-common/             ← baked into every variant
│   └── etc/
│       ├── banner            ← SSH login banner
│       ├── shadow            ← root password hash
│       └── config/
│           ├── dropbear      ← SSH: LAN-only, port 22
│           └── system        ← hostname, timezone, NTP
└── files-variants/           ← per-variant overrides
    ├── bridge/etc/config/network
    ├── mini/etc/config/network
    ├── secure/etc/config/
    │   ├── network
    │   └── firewall
    ├── secure-web/           ← SECURE + web panel
    │   ├── etc/
    │   │   ├── config/uhttpd
    │   │   └── uhttpd.auth   ← Digest auth (admin:admin — change this)
    │   └── www/
    │       ├── pico.min.css
    │       └── cgi-bin/
    │           ├── common.sh ← shared functions
    │           ├── status    ← /cgi-bin/status
    │           ├── network   ← /cgi-bin/network
    │           ├── dhcp      ← /cgi-bin/dhcp
    │           ├── firewall  ← /cgi-bin/firewall
    │           ├── diag      ← /cgi-bin/diag
    │           ├── system    ← /cgi-bin/system
    │           └── logout    ← forces 401 re-auth
    └── vpn/etc/config/
        ├── network           ← WireGuard interface template
        └── firewall
```

### Updating to a new OpenWrt version

```bash
cd openwrt
git fetch
git checkout v<new-version>
./scripts/feeds update -a
./scripts/feeds install -a

# Expand configs against new package list
for VARIANT in bridge mini secure vpn; do
    cp configs/${VARIANT}.config .config
    make defconfig
    cp .config configs/${VARIANT}.config
done

bash build-all.sh
```

---

## LEDs

LEDs are defined in the device tree (kernel) and work out of the box.

| LED | Default behavior |
|---|---|
| Power (green) | Heartbeat — slow blink = system running |
| WAN | Blinks on WAN traffic |
| LAN 1–4 | Blink on LAN traffic |
| WPS | Configurable (off by default) |

During flashing: power LED blinks rapidly — do not power off.

---

## WiFi

The AR9330 WiFi chip is physically present on the board. It fits in the BRIDGE-WIFI and MINI-WIFI variants, but **not alongside firewall4/nftables** (SECURE/VPN) — the nftables stack leaves no room for the ~650–900 KB WiFi driver stack.

| Variant | WiFi | Notes |
|---|---|---|
| BRIDGE-WIFI | ✅ AP, WPA2 | wpad-basic-mbedtls, ~900 KB overhead |
| MINI-WIFI | ✅ AP, WPA2 | hostapd-mini (AP-only), ~650 KB overhead |
| SECURE / VPN | ❌ | firewall4+nftables leaves no room |

Default WiFi credentials (change after flashing!):
- **SSID:** `ZOMBIE740`
- **Password:** `zombie740`
- **Band:** 2.4 GHz b/g/n, channel auto, country PL

To change WiFi password on the router:
```bash
uci set wireless.default_radio0.key='newpassword'
uci commit wireless
wifi reload
```

If you need WiFi + full firewall:
- **OpenWrt 21.02** — older kernel (5.10), iptables instead of nftables, smaller footprint. WiFi + basic firewall fits.
- **Use as wired-only router** and add a separate access point on the LAN.

---

## Security notes

- Change the root password immediately after first flash: `passwd`
- SSH is LAN-only (SECURE/VPN/MINI) — WAN access is blocked
- SECURE/VPN: WAN input is DROP by default — no services exposed
- No telnetd, no web UI, no unnecessary services running
- Kernel 6.6.151 with security backports from OpenWrt 24.10

---

## License

Build scripts and configs: MIT  
OpenWrt: GPL-2.0 — see [openwrt.org](https://openwrt.org)

---

> *— TL-WR740N v4, 2011–∞ · 400 MHz · 32 MB RAM · 4 MB flash · still routing your packets*
