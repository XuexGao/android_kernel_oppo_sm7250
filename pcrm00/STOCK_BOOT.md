# Provenance of `stock_boot.img.xz`

`package.sh` needs a real PCRM00 **stock** boot image: it keeps the original
ramdisk and DTB and swaps only the kernel. Until now CI pulled it from a
personal网盘 URL (`pan.xiegao.top`), which returned intermittent 500/403 and
took ~9 minutes, and which nobody else can reproduce a build against.

It is now committed here, xz-compressed, so the build is self-contained.

## Identity

| | |
|---|---|
| file | `stock_boot.img.xz` (14,015,812 B) |
| decompressed size | 100,663,296 B (= exactly the device's boot partition size) |
| sha256 (uncompressed) | `e47998b3290f2ec3420d961cf170a87ced1d11193111985c9e37a224cb1ed94d` |
| source | dumped from the owner's own OPPO Reno3 Pro 5G (PCRM00) running ColorOS 11.1 / Android 11 (`image_version 10:RKQ1.200903.002:1640347520724`) |
| boot header | `ANDROID!`, **header_version 2**, page size 4096 |
| kernel_size field | 40,960,012 B |
| ramdisk_size field | 931,477 B |
| cmdline | `console=ttyMSM0,115200,n8 earlycon=msm_geni_serial,0x888000 androidboot.hardware=qcom ...` |

## Cross-checks that this really is stock PCRM00

1. `kernel_size` = **40,960,012 B**, byte-for-byte the size of
   `prebuilt/kernel` in `SekaiMoeArchive/android_device_oppo_PCRM00` (an
   independent extraction from OPPO firmware).
2. The DTB section (at offset 41,902,080, 8,526,635 B) hashes to
   `26f6b131bb8f2ecca049ffdea7562b32470095c72e1f9b1b0f924adc3865f1f8` —
   **identical to `pcrm00/dtb.img`**, which came from that same independent
   LineageOS repo. Two unrelated sources agreeing on the device tree.
3. `recovery_dtbo_size` = 0 and header_version = 2 → this is a boot image, not
   a recovery image (both would otherwise be plausible at 96 MiB).

## Regenerate

```bash
unxz < pcrm00/stock_boot.img.xz > /tmp/boot.img
sha256sum /tmp/boot.img    # must equal e47998b3...ed94d
```

## Note on `*.xz`

The kernel's own top-level `.gitignore` has a bare `*.xz` rule, which silently
ignores this file. `.gitignore` carries a `!pcrm00/stock_boot.img.xz`
negation; if you re-compress under a different name, force-add it or nothing
will be committed and CI will fall back to the网盘 URL.

## If you would rather not have the blob in every clone

Move it to a release asset instead (14 MB does not bloat much, but a clone of
this repo now carries it). CI can still fetch it with the built-in
`GITHUB_TOKEN`, since the workflow already has `contents: write`.
