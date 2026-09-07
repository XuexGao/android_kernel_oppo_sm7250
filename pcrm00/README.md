# ReSukisu kernel for OPPO Reno3 Pro 5G (PCRM00 / SM7250 "lito")

Goal: build a **ReSukisu** (KernelSU fork) enabled boot image for the
**OPPO Reno3 Pro 5G, model PCRM00** — a device OPPO never published a kernel
source release for.

Base: [`oppo-source/android_kernel_oppo_sm7250`](https://github.com/oppo-source/android_kernel_oppo_sm7250)
(Reno4 Pro 5G / PDNM00, ColorOS 12.1, codename *Simba*, kernel **4.19.157**).

---

## 1. Why the Reno4 Pro source is the right base

Verified against the running device, not assumed:

| Check | Result |
|---|---|
| `/sys/devices/soc0/soc_id` | `400` = **LITO / SM7250** — same SoC as the source tree |
| `/sys/devices/soc0/machine` | `SDM765G 5G`, `hw_platform = MTP` |
| Running kernel | `4.19.113-perf+`, built with `clang 10.0.7 for Android NDK` |
| Stock `dtb.img` | 22 DTBs, all `qcom,msm-id = <0x190 …>` (400/Lito) + `<0x1b8 …>` (440/Lito-v2) |
| Stock `dtbo.img` | contains `dsi_oppo19101boe_nt37800_1080_2400_cmd`, `s6sy771_19101@48`, `synaptics19101@4B` |
| Source tree | `devicetree-4.19/19101/` = **OPPO project 19101 = Reno3 Pro**, with those exact panel dtsi files |
| Touch drivers | `drivers/input/touchscreen/synaptics_tcm/` present; `CONFIG_TOUCHPANEL_SAMSUNG_S6SY771=y` |

So Reno3 Pro is not merely "same CPU" — its board support (project `19101`) is
physically present in this release. The companion repo
[`android_kernel_modules_and_devicetree_oppo_sm7250`](https://github.com/oppo-source/android_kernel_modules_and_devicetree_oppo_sm7250)
carries the device trees, which the main repo expects at
`arch/arm64/boot/dts/vendor`.

Independent confirmation: the LineageOS port
[`SekaiMoeArchive/android_device_oppo_PCRM00`](https://github.com/SekaiMoeArchive/android_device_oppo_PCRM00)
lists `android_kernel_oppo_sm7250` in `lineage.dependencies` as PCRM00's kernel.

## 2. The blocker: OPPO's release is not self-contained

The tree ships **81 symlinks into directories that were never published**
(`vendor/oplus/kernel/...`, `vendor/qcom/proprietary/...`). Kbuild dies on the
first unconditional `obj-y += <missing>/`.

Genuinely fatal for a *usable* phone:

| Missing | Impact |
|---|---|
| `drivers/power/oplus` → `vendor/oplus/kernel/charger` | OPPO charging framework (`CONFIG_OPLUS_SM7250R_CHARGER=y`, and its Kconfig *is* present, so it is not silently dropped — it is a hard build error) |
| `drivers/input/touchscreen/oplus_touchscreen` | OPPO touch framework wrapper (`TOUCHPANEL_OPLUS`) |
| `drivers/input/oplus_fp_drivers` | fingerprint |
| `drivers/staging/android/ion/{ion,ion_track,oplus_ion_boost_pool.*}` | QC ION heaps — display/camera memory |
| `drivers/ommc`, `drivers/scsi/oufs` | OPPO's MMC/UFS variants |
| `mm/*`, `kernel/sched_assist`, `kernel/special_opt`, `block/uxio_first` | OPPO memory/scheduler/perf work |
| `fs/{erofs,exfat,oext4,of2fs,osdcardfs}` | extra filesystems (stock kernel has **no** erofs, so vendor is not erofs — not fatal) |
| `drivers/soc/oplus/{thermal,tpd,tpp,sensor,…}` | thermal + input/charging protection daemons |

`pcrm00/prepare_stubs.sh` replaces every dangling link with an empty
`Kconfig` + no-op `Makefile` (or an empty file) so the tree compiles, and logs
each one to `build/stubs.log` — the damage stays auditable instead of silent.

**Read this honestly:** a build that succeeds through the stub path produces a
kernel that may boot, but with charging, fingerprint, and parts of the
touch/display stack depending on what got stubbed out. It is a diagnostic
build, not a daily driver. See `docs/` and the CI logs before flashing anything.

Two things do *not* need stubbing and are handled properly:

* `TARGET_PRODUCT=qssi` flips `drivers/Makefile` and `drivers/scsi/Makefile`
  from OPPO's unreleased `ommc/`/`oufs/` onto the stock QC `mmc/`/`ufs/`
  drivers, which **are** in the tree. Storage works.
* The device tree is real: CI clones the companion repo and links it in, so
  `arch/arm64/boot/dts/vendor` resolves.

## 3. Device tree strategy

We do **not** rebuild the DTB. We reuse the stock `dtb.img`
(`pcrm00/dtb.img`, sha256 `26f6b131…f1f8`, extracted from PCRM00 firmware) and
leave the phone's `dtbo` partition untouched. The hardware description the
kernel sees then stays byte-identical to stock, which removes the single
largest bricking risk in a cross-board port.

`pcrm00/build.sh` emits `out/pcrm00/Image-dtb` = our `Image` + stock `dtb.img`.

## 4. ReSukisu integration

Pinned: `ReSukisu/ReSukisu` @ `f1dd81dc96d7f3f6691e6ac8b50fba9ae8a2f17c`
(v4.2.0-rc1), vendored into `drivers/kernelsu/` (GPL-2.0-only, as upstream
requires for the `kernel/` directory).

Wiring, matching what upstream's `kernel/setup.sh` does:

```
drivers/Makefile   + obj-$(CONFIG_KSU) += kernelsu/
drivers/Kconfig    + source "drivers/kernelsu/Kconfig"
drivers/kernelsu/include/uapi -> ../uapi   (upstream layout assumes repo root)
```

Hook selection is forced by upstream's own Kconfig:

* `KSU_TRACEPOINT_HOOK` — *"Support for kernel 5.10+"* (GKI2 only). **Not usable on 4.19.**
* `KSU_MANUAL_HOOK` — *"Support for kernel 3.4+"*, but `depends on KSU != m`.
  **So on 4.19 ReSukisu must be built-in (`=y`); the LKM route is impossible.**
* `KSU_SUSFS` — mutually exclusive with MANUAL_HOOK in the same `choice`.

`pcrm00/apply_ksu_config.sh` sets `KSU=y` + `KSU_MANUAL_HOOK=y`, the three
`KSU_MANUAL_HOOK_AUTO_*` sub-hooks, `KALLSYMS`/`KALLSYMS_ALL`/`KPROBES`/`PROC_FS`,
and clears `MODULE_SIG_FORCE`.

`MODULE_SIG_FORCE` matters: stock ships OPPO's signing key, so a rebuilt kernel
with a freshly generated key would reject every stock `.ko`. Only four modules
exist in this defconfig (`MSM_RDBG`, `DVB_MPQ`, `DVB_MPQ_DEMUX`,
`QCOM_LLCC_PERFMON`) and none are functional — WiFi, audio and display are all
built in — so a vermagic mismatch against `4.19.113-perf+` is harmless.

## 5. Build

```bash
TARGET_PRODUCT=qssi CC=clang LD=ld.lld ./pcrm00/build.sh
```

`build.sh` runs `prepare_stubs.sh` implicitly? **No** — run it first:

```bash
./pcrm00/prepare_stubs.sh
TARGET_PRODUCT=qssi CC=clang LD=ld.lld ./pcrm00/build.sh
```

Toolchain: stock used clang 10.0.7. CI defaults to **clang 14** on
`ubuntu-22.04` with `KCFLAGS=-Wno-error`; the version is a `workflow_dispatch`
input if a lower one is needed.

## 6. Packaging a flashable boot image

No separate `kptools` needed — ReSukisu's `ksud` patches boot images itself
(`userspace/ksud/src/boot_patch.rs`):

```bash
ksud boot-patch -b stock_boot.img -k out/pcrm00/Image-dtb -o resukisu_boot.img
```

`boot-patch` replaces the kernel, injects `ksud` into the ramdisk `init`, and
preserves the original boot header (OPPO PCRM00: header **v2**, base
`0x00000000`, page size **4096**, boot partition **98404000** bytes,
separate dtbo, `androidboot.hardware=qcom`).

Then flash `boot`, and install the ReSukisu manager APK
(`ReSukiSU_v4.2.0-rc1_*-arm64-v8a-release.apk`).

## 7. Before flashing anything — read this

* PCRM00 is **A-only**. A bad `boot` partition means the phone does not boot.
* OPPO devices recover from a dead boot via **EDL 9008**, which on OPPO requires
  an **authorized service account**. Without that, or without a verified
  `fastboot flash boot` path on your exact firmware, a failed flash can be
  **unrecoverable at home**.
* Your current root is FolkPatch, which patches `boot`. ReSukisu also wants
  `boot`. Starting from a **stock** `boot.img` is strongly preferable to
  stacking two boot-level root solutions.
* Back up the current `boot` partition before touching anything, and confirm
  your recovery route works *before* you need it.

## 8. Layout

```
pcrm00/
  prepare_stubs.sh      neutralise OPPO's 81 dangling vendor symlinks
  apply_ksu_config.sh   ReSukisu config fragment
  check_config.sh       assert KSU really ended up enabled
  build.sh              defconfig -> fragment -> Image -> Image-dtb
  dtb.img               stock PCRM00 device trees (reused, never rebuilt)
  pack_boot.sh          ksud boot-patch wrapper
drivers/kernelsu/       vendored ReSukisu kernel (GPL-2.0-only)
.github/workflows/build-pcrm00.yml
```
