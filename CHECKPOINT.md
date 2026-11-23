# Project Checkpoint — SM-A037F TWRP

Last updated: 2026-11-23

This file is the versioned checkpoint for the TWRP work on the Samsung Galaxy
A03s (SM-A037F). Local build artifacts are not committed to this repository.

## Device

- Model: SM-A037F (a03s / a03snnxx, MT6765)
- Firmware: A037FXXS8CYE1, Android 13, security patch 2025-05-01
- Kernel: 4.19.325-ge6e36d3a858e (#22 watermark)
- Recovery partition: 38,797,312 bytes
- Bootloader: unlocked (`ro.boot.flash.locked=0`, verified boot orange)

## Repositories

- Kernel: https://github.com/KazeTheLight/SM-A037F-Kernel
  - Branch `kernelsu-next`, kernel build #22 watermark
- Recovery: https://github.com/KazeTheLight/SM-A037F-TWRP
  - Branch `main`: non-crypto TWRP 12.1
  - Branch `fbe-experimental`: FBE experimental build

## Working main recovery

- TWRP 12.1, non-crypto, unsigned (no AVB), full partition padding.
- Local artifact: `TWRP-main-1/recovery-fixdtb.tar`
- Image SHA256: `f89da6d361497c981c758aa39cbe04da6680979f0053af5b600e484f04e75edf`
- Tar SHA256: `5a2ac56a466738259cad7cd464b8ae5a6a67d9d83772423a4674ca0d6abad94f`
- Boots successfully. `/data` stays FBE-encrypted; this build cannot decrypt it.
- Do not use release `twrp-1-1`; it was built with the wrong DTB.

## Root cause fixed

The original `prebuilt/recovery.img-dtb` (`699acf47...`) was a DTBO+DTB mix
extracted at the wrong offset. The bootloader panicked at:

`ASSERT at app/mt_boot/bootargs.c:101: fdt_bootargs`

The real TWRP V4 DTB is `28adb2ea...` (`prebuilt/recovery.img-dtb.physwizz`).
With that DTB the recovery boots. The repo now uses the correct DTB.

## FBE experimental

- FBE build #5 (`twrp-fbe-5-1`) succeeded but hung at the Samsung logo.
  - TWRP log was an empty 10-byte gzip; pstore empty → not a kernel panic.
  - Suspected cause: `teegris_v4.rc` `on post-fs` mounts
    (`efs`, `protect1/2`, `nvcfg`, `nvdata`, `persist`) before TWRP UI.
- FBE debug #6 (`twrp-fbe-6-1`, commit `c079bed`) succeeded:
  - `import /teegris_v4.rc` removed; no TEEGRIS/keymaster/gatekeeper.
  - This is a boot test only; `/data` cannot be decrypted.
  - Verified: image 38,797,312 bytes, DTB `28adb2ea`, no AVB,
    ramdisk 21,838,979 (cpio 57,803,776 / 3,579 entries).
  - Image SHA256: `2877f267aaa7388577272790e2d20201caf095255703f46ca55504130ba468bd`
  - Tar SHA256: `2abbbc214951f8b0cdb40fa7192f6d98c31fc647b6daf364d66f32a51474999d`
  - Boot test pending.
- If debug #6 boots, the teegris init/mounts were the hang. Re-add teegris but
  move the vendor mounts until after the TWRP UI/crypto trigger.
- If debug #6 still hangs, it also removed the `keystore2`/`hwservicemanager`
  imports, so the next test is: keep teegris, remove only `on post-fs` mounts.

## Build cache checkpoint

- The workflow caches `out/` for dirty builds (`dirty_build: true`) and saves
  it after a successful build.
- FBE #6 reported `out size: 12078 MB`; the old 12,000 MB limit skipped the
  cache save.
- The limit is now 14,000 MB on both `main` and `fbe-experimental`, with a
  warning when skipped. Cache restore itself was successful.

## Local fallback artifacts (not in repo)

- Working main TWRP: `TWRP-main-1/recovery-fixdtb.tar`
- FBE debug #6: `TWRP-FBE-debug-6/recovery.tar`
- TWRP V4 fallback: `DTRecoveryV4/recovery.tar`
- Stock CYE1 boot: `boot-stock.tar`
- Kernel #22 AnyKernel: `SM-A037F_4.19.325-ksu8-ged1-gpu800-watermark.zip`

## Next steps

1. Flash FBE debug #6 via Odin AP; boot recovery.
2. If it boots, add teegris back with the mounts moved after TWRP UI.
3. Test `/data` decryption with the device lock; never format data for a test.
4. Keep fixdtb and V4 recovery as fallbacks.
