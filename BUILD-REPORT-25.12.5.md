# ZOMBIE740 Build Report — OpenWrt v25.12.5

**Date:** 2026-10-09  
**Builder:** ubuntu-builder (192.168.0.43)  
**OpenWrt revision:** r33051-f5dae5ece4  
**Toolchain:** GCC 14.3.0 / musl libc  
**Target:** ath79/tiny — TP-Link TL-WR740N v4 + v5 (AR9331, 4MB SPI NOR, 32MB RAM)

---

## Results

All 9 variants built successfully for both hardware revisions (v4 + v5), except repeater (v4 only).

| Variant | v4 sysupgrade | v4 factory | v5 sysupgrade | v5 factory |
|---------|--------------|------------|--------------|------------|
| bridge | 3,932,984 B | 3,932,160 B | 3,146,552 B | 3,932,160 B |
| bridge-wifi | 3,932,984 B | 3,932,160 B | 3,146,552 B | 3,932,160 B |
| mini | 3,932,984 B | 3,932,160 B | 3,212,088 B | 3,932,160 B |
| mini-wifi | 3,932,984 B | 3,932,160 B | 3,212,088 B | 3,932,160 B |
| secure | 3,932,984 B | 3,932,160 B | 3,670,840 B | 3,932,160 B |
| secure-web | 3,932,984 B | 3,932,160 B | 3,801,912 B | 3,932,160 B |
| secure-web-en | 3,932,984 B | 3,932,160 B | 3,801,912 B | 3,932,160 B |
| vpn | 3,932,984 B | 3,932,160 B | 3,867,448 B | 3,932,160 B |
| repeater | 3,932,984 B | 3,932,160 B | — | — |

v4 sysupgrade is always `fw_max_len + 824 B` (fwtool metadata). mktplinkfw pads v4 firmware to `fw_max_len` (0x3C0000), so JFFS2 overlay always starts at flash 0x3E0000 → exactly 64KB (1 erase block) for all v4 builds.  
Factory images are always padded to `fw_max_len` (0x3C0000 = 3,932,160 B).  
v5 sysupgrade is unpadded — varies by package count; smaller than before because APK bloat was removed.

---

## Issues Fixed vs v24.10.2

### 1. Kernel overflow — `mktplinkfw: images are too big`
The v25.12.5 kernel grew to **1,933,612 bytes** — exceeding the old kernel slot limit of 1,900,032 bytes (0x1D0000 − 0x200 header).

**Fix A** — `tools/firmware-utils/patches/100-4mlzma-increase-kernel-partition.patch`:
```diff
-  .rootfs_ofs = 0x1D0000,
+  .rootfs_ofs = 0x1E0000,
```
Moves rootfs start 64KB further, giving the kernel 1,966,080 bytes (0x1E0000 − 0x200).

**Fix B** — `include/image-commands.mk`:
```diff
-  -k $(IMAGE_KERNEL) -r $(IMAGE_ROOTFS) -o $@.new -j -X 0x10000
+  -k $(IMAGE_KERNEL) -r $(IMAGE_ROOTFS) -o $@.new -j -X 0x0
```
Removed the 64KB reserved-space check (`-X`). The JFFS2 overlay lives in flash beyond the firmware partition (defined in DTS as 0x3D0000), not inside the image itself.

### 2. `package/utils/ucode` fails to compile — GCC 14 deprecation error
GCC 14.3.0 (new in v25.12.5, was 13.3.0 in v24.10.2) treats `__attribute__((deprecated))` as `-Werror`. libubox's `uloop_timeout_remaining()` is deprecated in favor of `uloop_timeout_remaining64()`.

CMake's `check_function_exists(uloop_timeout_remaining64)` fails in cross-compilation (linker can't find cross-compiled libubox), leaving `REMAINING64_FUNCTION_EXISTS` unset. The `#ifdef` falls to the deprecated function branch → build error.

**Fix** — `package/utils/ucode/patches/130-fix-uloop-remaining64.patch`:
```diff
-#ifdef HAVE_ULOOP_TIMEOUT_REMAINING64
 	rem = uloop_timeout_remaining64(&timer->timeout);
-#else
-	rem = (int64_t)uloop_timeout_remaining(&timer->timeout);
-#endif
```
Applied to both `lib/uloop.c` and `lib/ubus.c` — always use the 64-bit variant unconditionally.

### 3. `mksquashfs4` fails with invalid arguments
New v25.12.5 options `-block-readers N` and `-small-readers N` require explicit `.config` entries. Without them, the value is empty and mksquashfs4 prints help and exits.

**Fix** — added to all 9 variant configs:
```
CONFIG_TARGET_SQUASHFS_BLOCK_READERS=4
CONFIG_TARGET_SQUASHFS_SMALL_READERS=4
```

### 4. Build script race condition — `ERROR: tools/firmware-utils failed to build`
During parallel `make world`, `target/linux/prereq` updates `.config`, invalidating tool stamps. Then `tools/compile` and `package/cleanup` run in parallel, causing a race that produces a misleading firmware-utils error message.

**Fix** — build scripts now run in this order:
```bash
make target/linux/prereq        # stabilize .config
make -j$(nproc) tools/compile   # pre-build tools with stable .config
make -j$(nproc)                 # full world build
```

### 5. Build script log permission error
Previous runs as root left `build-repeater.log` owned by root. The `tee "$LOG"` step failed silently, causing `set -e` to abort the script before copying firmware files.

**Fix** — removed the root-owned log file before re-running.

### 6. Fresh builds overflow — APK package manager bloat
v25.12.5 switched from opkg to APK. Fresh builds (clean `root-ath79`) installed `apk-mbedtls` (pulls in 616KB of libmbedtls/libmbedcrypto/libmbedx509), and left APK database files in the rootfs (`lib/apk/db/installed` 60KB, `lib/apk/packages/*.list` ~50KB, `lib/apk/db/scripts.tar.gz` 8KB, `etc/apk/` 32KB, `etc/profile.d/apk-cheatsheet.sh` 1KB).

Also: `root-ath79` staging dir accumulates packages from all previously-built variants unless explicitly cleaned before each build.

**Fixes:**
- All 9 configs: `# CONFIG_PACKAGE_apk-mbedtls is not set` (removes 616KB libmbedtls)
- All 9 configs: `CONFIG_CLEAN_IPKG=y`
- All 9 build scripts: `rm -rf "$OPENWRT_DIR/build_dir/target-mips_24kc_musl/root-ath79"` before prereq step
- `include/rootfs.mk`: added to `prepare_rootfs` cleanup:
  ```makefile
  -rm -rf $(1)/lib/apk $(1)/etc/apk $(1)/etc/profile.d/apk-cheatsheet.sh
  ```

### 7. Squashfs still 3,207 bytes over after APK cleanup
After fixes in issue 6, `root-ath79` contents were clean but squashfs (2,004,973 B) + kernel (1,929,882 B) + header (512 B) = 3,935,367 B still exceeded `fw_max_len` (3,932,160 B).

**Root cause:** `base-files` APK package declares `procd-seccomp` as a required dependency. Even with `# CONFIG_PACKAGE_procd-seccomp is not set`, APK always installs it. The procd-seccomp binaries total 74,693 B raw (`libpreload-seccomp.so` 37KB + `utrace` 33KB + `libpreload-trace.so` 4KB + `/etc/capabilities/` JSON files).

**Fix** — `include/rootfs.mk`: added post-install removal of procd-seccomp files:
```makefile
-rm -f $(1)/lib/libpreload-seccomp.so $(1)/lib/libpreload-trace.so $(1)/sbin/utrace $(1)/sbin/seccomp-trace
-rm -rf $(1)/etc/capabilities
```
After removal: squashfs = 1,991,613 B → firmware = 3,922,007 B ≤ fw_max_len ✓.

Note: procd still runs normally — seccomp filtering is optional and skipped if the shared library is absent.

### 8. `libudebug` new in v25.12.5
`libudebug` (debug tracing library, 8KB) was added as an explicit package in all 9 variant configs but is not needed for production firmware.

**Fix** — all 9 configs: `# CONFIG_PACKAGE_libudebug is not set`

---

## Flash Layout (TL-WR740N v4, 4MB)

```
0x000000  u-boot      (0x20000 = 128KB)
0x020000  firmware    (0x3D0000 = 3,997,696 B)
  ├─ header           (0x200 = 512 B)
  ├─ kernel           (0x1E0000 − 0x200 = 1,966,080 B available; actual LZMA = 1,929,882 B)
  └─ rootfs           (squashfs, padded by mktplinkfw to fw_max_len boundary)
0x3E0000  JFFS2       (0x10000 = 64KB = 1 erase block; overlay for UCI config)
0x3F0000  art         (0x10000 = 64KB)
```

mktplinkfw `fw_max_len = 0x3C0000` (firmware minus 64KB for JFFS2).  
v4 firmware is always padded to fw_max_len, so JFFS2 always starts at 0x3E0000 = 64KB available.  
64KB JFFS2 is sufficient for typical UCI configuration (network, wireless, firewall, etc.).

---

## Output Files

All files in `/home/szymon/programming/tplink/`:

```
zombie740-{variant}-sysupgrade-20261009.bin   ← flash via sysupgrade / LuCI
zombie740-{variant}-factory-20261009.bin      ← initial flash via TFTP/web UI
zombie740-{variant}-v5-sysupgrade-20261009.bin
zombie740-{variant}-v5-factory-20261009.bin
```
