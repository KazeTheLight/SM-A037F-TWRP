# TWRP for Samsung Galaxy A03s (SM-A037F)

Device tree and GitHub Actions build for Team Win Recovery Project on the
Samsung Galaxy A03s (MT6765). The tree is aligned with the firmware currently
installed on the test device, **A037FXXS8CYE1 (Android 13)**.

> **Warning**
> Unlocking the bootloader and flashing custom images trips KNOX, voids the
> warranty and may erase all data. This recovery uses AOSP test keys and cannot
> decrypt the FBE-encrypted `/data` partition. Back up everything before
> flashing and keep a copy of the stock firmware.

## Device

| Item | Value |
| --- | --- |
| Model | SM-A037F (`a03s`, product `a03snnxx`) |
| SoC | MediaTek MT6765 / Helio P35 |
| Display | 720 x 1600, 300 dpi |
| Shipping API | 30 (Android 11) |
| Current firmware | A037FXXS8CYE1 |
| Android version | 13 (TP1A.220624.014) |
| Security patch | 2025-05-01 |
| Dynamic partitions | Yes, `super` = 6,106,906,624 bytes |
| Data encryption | FBE, aes-256-xts |

## What is synced with the device

Values below were read from the running device, not copied from an older
firmware dump:

- Build fingerprint, description and display ID: `A037FXXS8CYE1`
  (`samsung/a03snnxx/a03s:13/TP1A.220624.014/A037FXXS8CYE1:user/release-keys`).
- Partition sizes from `/dev/block/by-name` and `/dev/block/mapper`:
  `boot` 33,554,432; `recovery` 38,797,312; `cache` 209,715,200;
  `userdata` 55,096,377,344; `system` 3,710,476,288; `vendor` 768,069,632;
  `product` 1,317,879,808; `odm` 4,349,952; `metadata` 33,554,432;
  `dtbo` 8,388,608.
- Default kernel/DTB/DTBO: the exact set from the TWRP recovery currently
  installed in the device's recovery partition, which is known to boot on this
  hardware. A stock A037FXXS8CYE1 DTB is included for the `cye1` variant.
- Fstab layout follows the stock vendor fstab: F2FS userdata, `/metadata` on
  `md_udc`, logical `system`/`vendor`/`product`/`odm`.
- Density 300, matching `wm density` and `ro.sf.lcd_density`.
- VNDK 31 and first API level 30, matching `ro.vndk.version` and
  `ro.product.first_api_level`.

## Prebuilt boot assets

Three sets are included:

| Set | Kernel | DTB | DTBO |
| --- | --- | --- | --- |
| `proven` (default) | Samsung 4.19.191 CVK7 (the kernel in the recovery currently on the device) | CVK7 | CVK7 |
| `physwizz` | physwizz 4.19.191 TWRP kernel, SELinux always permissive, DEFEX off | physwizz | CVK7 |
| `cye1` | stock A037FXXS8CYE1 kernel | stock CYE1 | C3 recovery DTBO |

The `proven` set is the safest starting point: it is byte-for-byte the
kernel/DTB/DTBO combination that the device boots today. The `physwizz` kernel
is the more TWRP-friendly option (DEFEX disabled, SELinux permissive) and is
the first fallback if the `proven` kernel rejects the TWRP 12.1 ramdisk.

The `cye1` set uses the kernel and DTB from the current Android 13 boot image.
It keeps Samsung DEFEX enabled and SELinux enforcing, so treat it as
experimental. The DTBO is from an older recovery because the device's recovery
partition currently contains TWRP, not the stock CYE1 recovery.

## Features

- TWRP 12.1 (AOSP 12.1 base), portrait theme
- Dynamic partitions / `super` support
- ext4, F2FS, exFAT and FAT32
- MTP, ADB and USB OTG
- Backup of boot, recovery, dtbo, EFS, metadata, prism, optics, persist and
  the super logical partitions
- Flashable image entries for boot, recovery, dtbo, vbmeta and super images

## Limitations

- **FBE `/data` cannot be decrypted.** See
  [Data encryption (FBE)](#data-encryption-fbe) for the two supported routes.
- Python and NTFS support are disabled to keep `recovery.img` below the
  38,797,312-byte recovery partition.
- The image is signed with AOSP test keys. An unlocked bootloader is required.
- Tested only on SM-A037F. Do not flash on A03s variants with a different
  partition layout without checking the sizes first.

## Data encryption (FBE)

The device ships with file-based encryption:

- `/data` uses `fileencryption=aes-256-xts:aes-256-cts:v2`
- FBE key directory: `/metadata/vold/metadata_encryption`
- Keystore: Samsung `mdfpp` on TEEGRIS

`TW_INCLUDE_CRYPTO` is off, so TWRP cannot unwrap the FBE key and `/data`
appears empty. This matches the other Samsung MTK recovery trees (A12, A05,
A15), none of which provide working FBE decryption for this platform.

There are two practical choices.

### Keep FBE

Use TWRP for boot/recovery/dtbo/EFS/super backups and flashing only. Back up
internal storage with `adb pull /sdcard`, and app data from the booted, rooted
Android system, for example:

```bash
adb exec-out su -c 'tar -C /data --exclude=data/media -cf - .' > data-apps.tar
```

`/data` stays encrypted and TWRP will not mount it.

### Disable FBE (erases data)

This is the standard Samsung MTK route and what the A12/A05 trees document:

1. Back up everything; this wipes `/data`.
2. Flash TWRP and boot it.
3. **Wipe -> Format Data** (not just "Wipe").
4. Open **Advanced -> Terminal** and run:

   ```sh
   multidisabler
   ```

   The script is already in this build at `/system/bin/multidisabler`. It
   replaces `fileencryption=...` with `encryptable` in
   `/vendor/etc/fstab.mt6765`, disables stock recovery restoration and makes
   `/vendor` writable if the filesystem is full.
5. Reboot to Android. The first boot creates a new unencrypted `/data`.

After this, TWRP can mount `/data`, and Android will not re-encrypt it.

Notes:

- Formatting data is irreversible.
- Knox, Secure Folder, some banking apps and OTA updates may complain. A vendor
  OTA can restore the original fstab and re-enable FBE; the procedure then has
  to be repeated.
- This does not decrypt existing data. It only makes future `/data`
  unencrypted.
- If `multidisabler` cannot write to `/vendor`, patch the fstab manually from
  the TWRP terminal:

  ```sh
  mount -o rw /vendor
  sed -i 's/fileencryption=[^,]*/encryptable/' /vendor/etc/fstab.mt6765
  ```

## Build with GitHub Actions

The workflow is `.github/workflows/build-twrp.yml`.

1. Open **Actions -> Build TWRP -> Run workflow**.
2. Choose the prebuilt asset set:
   - `proven` (default): exact kernel, DTB and DTBO from the recovery currently
     installed on the device.
   - `physwizz`: physwizz TWRP kernel and DTB, for testing if the proven kernel
     has trouble with the TWRP 12.1 ramdisk.
   - `cye1`: stock A037FXXS8CYE1 kernel and DTB, experimental.
3. Leave **Publish release** enabled to get a GitHub release, or disable it to
   use the workflow artifact only.

### Dirty / incremental build

The workflow can reuse the previous build output and ccache:

1. Run once with **Dirty build** off. A successful build saves `out/` and the
   ccache to the GitHub Actions cache.
2. Run again with **Dirty build** on. The workflow restores `out/`, sets the
   source mtimes older than the cached objects, touches the device tree so
   configuration changes rebuild, removes the old `recovery.img`, and runs
   `mka recoveryimage` incrementally.
3. The cache key includes a hash of every repo project commit. If the TWRP
   source moved, the cache is not reused and the build is clean again.

GitHub Actions has a 10 GB cache limit per repository. If `out/` is too large,
the cache save is skipped and the build still succeeds; the ccache cache still
helps. If the restored cache looks stale, run once with **Dirty build** off.

The job syncs the TWRP 12.1 minimal manifest, removes `.repo` to free disk
space, copies this device tree to `device/samsung/a03s`, builds
`recoveryimage`, checks the partition limit and packages:

- `recovery.img`
- `recovery.tar` (Odin)
- `SHA256SUMS.txt`

## Local build

Use Ubuntu 22.04 with at least 16 GB RAM and 60 GB free disk space.

```bash
mkdir -p ~/twrp && cd ~/twrp

repo init --depth=1 \
  -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp \
  -b twrp-12.1
repo sync -c -j"$(nproc)"

git clone https://github.com/KazeTheLight/SM-A037F-TWRP.git \
  device/samsung/a03s

source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
lunch twrp_a03s-eng
mka recoveryimage
```

Output: `out/target/product/a03s/recovery.img`.

## Flash

The bootloader is already unlocked on the test device
(`ro.boot.flash.locked=0`).

### Odin

1. Boot to download mode (Vol Down + Power, then Vol Up to confirm).
2. Put `recovery.tar` in the **AP** slot. Do not load anything else.
3. Start the flash. Keep **Auto Reboot** disabled if you want to control the
   first boot.
4. After the flash, boot straight to recovery with **Vol Up + Power**. If
   Android boots first, the stock recovery may be restored.

### Heimdall

```bash
heimdall flash --RECOVERY recovery.img --no-reboot
```

### Restore stock recovery

Extract `recovery.img` from the A037FXXS8CYE1 firmware package and flash it the
same way, or reflash the full stock firmware with Odin.

## Repository layout

```text
BoardConfig.mk                     build configuration
device.mk                          product packages and properties
twrp_a03s.mk                       product definition
prebuilt/Image                     default kernel, CVK7 (proven)
prebuilt/Image.physwizz            physwizz kernel
prebuilt/Image.stock               stock A037FXXS8CYE1 kernel
prebuilt/recovery.img-dtb          default CVK7 DTB
prebuilt/recovery.img-dtb.physwizz physwizz DTB
prebuilt/recovery.img-dtb.cye1     stock A037FXXS8CYE1 DTB
prebuilt/recovery_dtbo             default CVK7/physwizz DTBO
prebuilt/recovery_dtbo.c3          C3 DTBO used by the cye1 variant
recovery/root/                     recovery ramdisk overlay
.github/workflows/build-twrp.yml   GitHub Actions build
```

## Credits

- Team Win Recovery Project for TWRP and the minimal manifest.
- physwizz for the A03s TWRP kernel and earlier recovery work.
- topser9 / Paksan11 for the base device tree.
- twrpdtgen for the generated tree skeleton.
