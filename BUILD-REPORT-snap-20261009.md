# ZOMBIE740 Build Report — OpenWrt snapshot (kernel 6.18.55)

**Date:** 2026-10-09  
**Builder:** ubuntu-builder (192.168.0.43)  
**OpenWrt revision:** r0-244d2f6 (main branch, 2026-10-09)  
**Toolchain:** GCC 14.4.0 / musl libc  
**Target:** ath79/tiny — TP-Link TL-WR740N v4 + v5 (AR9331, 4MB SPI NOR, 32MB RAM)  
**Kernel:** Linux **6.18.55** (vs 6.12.94 in v25.12.5)

> **Note:** TL-WR740N is disabled from default snapshot builds since 2020-06-27 (`DEFAULT := n`).
> These images are built manually with custom patches. See patches in `patches-snapshot/`.

---

## Results

5 variants built (bridge/mini families + repeater). Larger variants (secure, secure-web, vpn) do not fit
due to the larger kernel — see "Why only 5 variants" below.

| Variant | v4 sysupgrade | v4 factory | v5 sysupgrade | v5 factory |
|---------|--------------|------------|--------------|------------|
| bridge | 3,277,086 B | 3,932,160 B | 3,277,086 B | 3,932,160 B |
| bridge-wifi | 3,277,086 B | 3,932,160 B | 3,277,086 B | 3,932,160 B |
| mini | 3,408,158 B | 3,932,160 B | 3,408,158 B | 3,932,160 B |
| mini-wifi | 3,408,158 B | 3,932,160 B | 3,408,158 B | 3,932,160 B |
| repeater | 3,408,158 B | 3,932,160 B | 3,408,158 B | 3,932,160 B |

v4 sysupgrade = v5 sysupgrade because with `-j` (combined mode) rootfs_ofs is computed dynamically
from actual kernel size — both hardware variants share the same firmware binary.  
Factory images always padded to `fw_max_len` (0x3C0000 = 3,932,160 B).

---

## Why only 5 variants

Kernel 6.18.55 LZMA = **2,029,982 bytes** (vs 1,929,882 in 6.12.94 — **+100KB**).

With `-j` (combined mode), mktplinkfw places rootfs immediately after the kernel:
```
rootfs_ofs = ALIGN(kernel_size + 512, 4) = 2,030,496 bytes
rootfs_max = fw_max_len - rootfs_ofs = 3,932,160 - 2,030,496 = 1,901,664 bytes
```

Squashfs must fit within **1,901,664 bytes** (~1.81MB). The secure/vpn variants have too many
packages to fit in that space.

| Variant | Squashfs | Fits? |
|---------|----------|-------|
| bridge | ~1.28MB | ✓ |
| bridge-wifi | ~1.28MB | ✓ |
| mini | ~1.34MB | ✓ |
| mini-wifi | ~1.34MB | ✓ |
| repeater | ~1.34MB | ✓ |
| secure | ~1.9MB+ | ✗ too big |
| secure-web | ~2.0MB+ | ✗ too big |
| vpn | ~2.1MB+ | ✗ too big |

---

## Patches Applied (vs upstream snapshot)

### 1. `tools/firmware-utils/patches/100-4mlzma-kernel-6.18.patch`
`4Mlzma.rootfs_ofs`: `0x100000` → `0x260000`  
Required because the upstream value (1MB) would truncate the kernel partition for 6.18.

### 2. `include/image-commands.mk`
`-X 0x40000` → `-X 0x0`  
Removes reserved-space check. JFFS2 overlay lives in flash beyond the firmware partition (DTS 0x3D0000), not inside the image.

### 3. `include/rootfs.mk`
Added post-install cleanup (same as v25.12.5):
```makefile
-rm -rf $(1)/lib/apk $(1)/etc/apk $(1)/etc/profile.d/apk-cheatsheet.sh
-rm -f $(1)/lib/libpreload-seccomp.so $(1)/lib/libpreload-trace.so $(1)/sbin/utrace $(1)/sbin/seccomp-trace
-rm -rf $(1)/etc/capabilities
```

### 4. Package exclusions (new OpenWrt main defaults vs v25.12.5)
OpenWrt main switched default firewall from `firewall3` (iptables) to `firewall4` (nftables).
`firewall4` + `libnftables` alone add ~870KB to the rootfs. Excluded in all 5 configs:
```
# CONFIG_PACKAGE_firewall4 is not set
# CONFIG_PACKAGE_nftables-json is not set
# CONFIG_PACKAGE_libnftnl is not set
# CONFIG_PACKAGE_ppp is not set
# CONFIG_PACKAGE_ppp-mod-pppoe is not set
# CONFIG_PACKAGE_odhcp6c is not set
# CONFIG_PACKAGE_odhcpd-ipv6only is not set
# CONFIG_PACKAGE_ca-bundle is not set
# CONFIG_PACKAGE_uboot-envtools is not set
# CONFIG_PACKAGE_knot-resolver_dnstap is not set
# CONFIG_PACKAGE_logd is not set
```

---

## Flash Layout (TL-WR740N v4, 4MB)

```
0x000000  u-boot      (0x20000 = 128KB)
0x020000  firmware    (0x3D0000 = 3,997,696 B)
  ├─ header           (0x200 = 512 B)
  ├─ kernel           (LZMA = 2,029,982 B, fits in patched slot 0x260000 − 0x200 = 2,489,344 B)
  └─ rootfs           (squashfs, starts at kernel_end aligned to 4 bytes)
0x3E0000  JFFS2       (0x10000 = 64KB = 1 erase block; overlay for UCI config)
0x3F0000  art         (0x10000 = 64KB)
```

Note: unlike v25.12.5, the `rootfs_ofs` patch (0x260000) only affects the kernel partition limit check,
not the actual rootfs position — which is determined dynamically by `-j` flag in mktplinkfw.

---

## Differences vs v25.12.5

| | v25.12.5 | snapshot (6.18) |
|---|---|---|
| OpenWrt branch | stable 25.12 | main (rolling) |
| Kernel | 6.12.94 LTS | 6.18.55 |
| GCC | 14.3.0 | 14.4.0 |
| Firewall | firewall3 (iptables) | excluded (too big) |
| IPv6 DHCP | odhcp6c + odhcpd | excluded |
| Variants | 9 | 5 (bridge/mini/repeater) |
| v4+v5 separate binaries | yes | no (same binary, different HWID) |

---

## Output Files

All files in `/home/szymon/programming/tplink/`:

```
zombie740-{variant}-snap-sysupgrade-20261009.bin    ← flash via sysupgrade / LuCI (v4 + v5)
zombie740-{variant}-snap-factory-20261009.bin       ← initial flash via TFTP/web UI (v4)
zombie740-{variant}-snap-v5-sysupgrade-20261009.bin
zombie740-{variant}-snap-v5-factory-20261009.bin
```
