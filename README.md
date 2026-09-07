# android_kernel_oppo_sm7250 — ReSukisu build for OPPO Reno3 Pro 5G (PCRM00)

This is OPPO's published SM7250 kernel source (Reno4 Pro 5G / PDNM00, ColorOS
12.1, kernel 4.19.157) with **ReSukisu** integrated, targeted at the
**OPPO Reno3 Pro 5G (PCRM00)** — a device OPPO never released kernel source for.

**→ Read [`pcrm00/README.md`](pcrm00/README.md) first.** It documents:

* how the Reno3 Pro was confirmed to be the same Lito/SM7250 platform, and how
  its board support (OPPO project `19101`) is present in this tree;
* the reason a clean build is hard: **81 symlinks point at `vendor/oplus/kernel/…`
  subtrees OPPO never published** (charging framework, touch framework,
  fingerprint, ION heaps, OPPO's UFS/MMC variants, memory & scheduler work);
* why the device tree is taken from the stock `dtb.img` rather than rebuilt;
* why ReSukisu must be **built-in with `KSU_MANUAL_HOOK`** on 4.19 (the
  tracepoint hook is 5.10+, and `KSU_MANUAL_HOOK` forbids `=m`);
* what is and is not safe to flash, and the EDL-9008 recovery caveat.

## Quick start

```bash
./pcrm00/prepare_stubs.sh                                   # neutralise dangling links
TARGET_PRODUCT=qssi CC=clang LD=ld.lld ./pcrm00/build.sh    # -> out/pcrm00/Image-dtb
./pcrm00/pack_boot.sh /path/to/stock_boot.img               # -> resukisu_pcrm00_boot.img
```

CI: [Actions → `build-pcrm00-resukisu`](../../actions/workflows/build-pcrm00.yml)
(clang version is a run-time input; artifacts are `Image`, `Image-dtb`, `.config`,
`build.log`, `stubs.log`).

## Provenance

| Component | Source |
|---|---|
| Kernel base | `oppo-source/android_kernel_oppo_sm7250` @ `554371ac` |
| Device trees | `oppo-source/android_kernel_modules_and_devicetree_oppo_sm7250` @ `ee75bb30` |
| ReSukisu | `ReSukisu/ReSukisu` @ `f1dd81dc` (v4.2.0-rc1), vendored in `drivers/kernelsu/` |
| Stock PCRM00 `dtb.img` | `SekaiMoeArchive/android_device_oppo_PCRM00` (sha256 `26f6b131…f1f8`) |

Licensed GPL-2.0-only as upstream; `drivers/kernelsu/` is GPL-2.0-only per
ReSukisu's own terms.
