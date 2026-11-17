# Xiaomi Redmi Note 4 — Nikel

English | [Русский](README.ru.md)

Device tree for LineageOS 13.0 based on Android 6.0.1, targeting MediaTek MT6797.
The build product is `lineage_nikel`, with ARM64 and ARM32 support.
Development proceeds incrementally, with separate commits for each subsystem.

Validation covers product selection through `lunch`, a control `boot.img` build,
FMRadio, telephony libraries and native dependencies. On-device testing of boot,
camera, audio, connectivity, FM, fingerprint and encryption is still pending.

Fingerprint userspace includes FPC and Goodix support. The bundled prebuilt kernel
is configured for Goodix. FPC requires a corresponding kernel configuration.
In `userdebug` and `eng` builds, the `mtk_daemon` and `fingerprintd` domains run
in permissive mode to collect SELinux denials during initial bring-up.

## Layout

| File or directory | Purpose |
|---|---|
| `BoardConfig.mk` | MT6797, ABIs, boot image geometry and partitions |
| `lineage.mk`, `full_nikel.mk`, `device.mk` | Product definition, packages and file installation |
| `rootdir/` | Init services, fstab and device permissions |
| `configs/`, `audio/`, `gps/`, `wifi/` | Subsystem configurations |
| `overlay/` | Nikel-specific Android resource settings |
| `sepolicy/` | Device SELinux policy additions |
| `ril-cm13/` | MediaTek RIL adapter for the CM13 telephony API |
| `prebuilt/kernel` | Kernel in `Image.gz-dtb` format |
| `proprietary-blobs.txt` | Blob list grouped by subsystem |
| `patches/` | Platform changes required by this tree |
| `tools/` | Vendor file and boot image verification |

## Sources and environment

Place this tree at `device/xiaomi/nikel` and the vendor tree at
`vendor/xiaomi/nikel`. Use the `cm-13.0` platform branch. Run the commands below
from the LineageOS source root.

The build uses JDK 8 and Android 6-era tools. Legacy Java build scripts require
Python 2.7 under the command name `python`. Scripts in `tools/` run with Python 3
and use `readelf`.

Validation on modern Linux required a `curl` wrapper for legacy Jack that replaces
`--no-proxy` with `--noproxy`. In the current local environment, the wrapper and
the `python` link to Python 2 are in
`/home/ma3axata/nikel-validation/python2-bin`. Add this directory to the beginning
of `PATH` before running Java builds on this machine.

The prebuilt kernel was built from commit
`70e2df0c7b9efa37b920a291ad6e32ac92d4ca98`, using `nikel_defconfig` and GCC 4.9
from ALPS. Blobs come from an unpacked Nikel MIUI `V10.2.1.0.MBFMIXM` stock dump
based on Android 6.0.

Kernel sources are available in the project repository.
[RM4-Nikel/android_kernel_xiaomi_nikel](https://github.com/RM4-Nikel/android_kernel_xiaomi_nikel)

## Platform patches

A clean CM13 tree requires the following patches. They are already applied in
the current workspace. Check each patch with `git apply --check` before applying
it to another revision.

| Patch | Repository | Purpose |
|---|---|---|
| `system-core-mtk-init.patch` | `system/core` | MTK RIL environment and disabling automatic startup of the standard rild |
| `system-core-mtk-ril.patch` | `system/core` | CCMNI network ioctls for MediaTek RIL |
| `frameworks-av-camera-flip.patch` | `frameworks/av` | `CameraParameters` symbols used by the stock camera |
| `tinycompress-prebuilt-kernel.patch` | `external/tinycompress` | Bionic UAPI headers when using the Nikel prebuilt kernel |
| `tinyalsa-prebuilt-kernel.patch` | `external/tinyalsa` | Exported UAPI headers with the Nikel prebuilt kernel |
| `vendor-cm-bundled-maven.patch` | `vendor/cm` | Use Maven already included in the source checkout |
| `vendor-cm-maven-https.patch` | `vendor/cm` | Use HTTPS for Maven Central; apply after the bundled Maven patch |

For example, check and apply the camera patch from the CM13 root.

```bash
git -C frameworks/av apply --check ../../device/xiaomi/nikel/patches/frameworks-av-camera-flip.patch
git -C frameworks/av apply ../../device/xiaomi/nikel/patches/frameworks-av-camera-flip.patch
```

## Working with vendor files

Paths in `proprietary-blobs.txt` are relative to `system/` in the stock dump.
The `source:destination` syntax specifies a different installation path.
Shared dependencies are grouped by their primary role. The purposes of individual
UUID-named Trustonic files still need verification.

To extract files, specify the dump directory containing `system/`.

```bash
device/xiaomi/nikel/extract-files.sh /path/to/stock-dump
python3 device/xiaomi/nikel/tools/audit-vendor.py /path/to/stock-dump
```

Extraction replaces listed files with their stock versions. The audit compares
hashes against stock and checks vendor ELF dependency paths for the matching ABI.
Platform symbol compatibility and hardware behavior require separate validation.

To add a blob manually, update the list, place the file at the corresponding path
under `vendor/xiaomi/nikel/proprietary/`, and regenerate the makefiles.

```bash
device/xiaomi/nikel/setup-makefiles.sh
git -C device/xiaomi/nikel diff
git -C vendor/xiaomi/nikel diff
git -C vendor/xiaomi/nikel status --short
```

`setup-makefiles.sh` preserves blob contents. Intentionally modified libraries
will produce hash differences when compared with stock. Commit changes to the
list and vendor files in their respective Git repositories.

## Control build

```bash
export LC_ALL=C
source build/envsetup.sh
lunch lineage_nikel-userdebug
make -j4 bootimage
python3 device/xiaomi/nikel/tools/verify-boot.py out/target/product/nikel/boot.img
```

Image verification checks the Android header, checksum, kernel, appended DTB and
required initramfs files. The build output is
`out/target/product/nikel/boot.img`.

Build FMRadio separately after preparing the Java build environment.

```bash
make -j4 FMRadio
```

Build the full ROM with the same Java 8, Python 2 and curl compatibility
environment described above:

```bash
make -j6 bacon
```

The resulting package is `out/target/product/nikel/lineage-13.0-*-UNOFFICIAL-nikel.zip`.
The first full build completed successfully. ZIP CRC, the whole-file OTA signature
with the source testkey, the Nikel device assertion, system payload checksum,
boot image identity and all 406 vendor files in target-files were verified.
This is a userdebug build signed with development test keys. Boot and hardware
operation have not been tested on a phone.

To compare another kernel, set `TARGET_PREBUILT_KERNEL` when building.
The kernel must use gzip format with an appended DTB. The `verify-boot.py` script
compares the image with this tree's `prebuilt/kernel`.

```bash
make -j4 bootimage TARGET_PREBUILT_KERNEL=/path/to/Image.gz-dtb
```

The stock scatter file specifies a 16 MiB boot partition. The `/data` partition,
existing encryption, bootloader behavior and hardware variants still require
on-device testing.

The RIL adapter and its original CCMNI patch come from CoreXGT's CM13 device tree,
with the original author headers preserved. FMRadio comes from the CM13 sources.
[CoreXGT Nikel cm-13.0](https://github.com/CoreXGT/android_device_xiaomi-nikel-lineage-14.1/tree/cm-13.0)
