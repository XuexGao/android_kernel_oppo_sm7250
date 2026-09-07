#!/usr/bin/env bash
#
# Package a flashable ReSukisu boot image for PCRM00 from a STOCK boot.img.
#
#   ./pcrm00/pack_boot.sh /path/to/stock_boot.img [output.img]
#
# Requires:
#   ksud  - ReSukisu userspace. Grab the host build from the ksud workflow, or
#           build it:  cargo build --release -p ksud   (in userspace/ksud)
#
# Why a STOCK boot image matters: your phone currently runs a FolkPatch-patched
# boot. ReSukisu also owns /init in the ramdisk. Feeding it an already-patched
# boot stacks two boot-level root solutions in one ramdisk; start from stock.
#
set -euo pipefail

BOOT="${1:?usage: $0 <stock_boot.img> [out.img]}"
OUT="${2:-resukisu_pcrm00_boot.img}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMG="$ROOT/out/pcrm00/Image-dtb"

command -v ksud >/dev/null || { echo "[!] ksud not in PATH" >&2; exit 1; }
[ -f "$BOOT" ] || { echo "[!] no such boot image: $BOOT" >&2; exit 1; }
[ -f "$IMG"  ] || { echo "[!] no such kernel: $IMG  (run pcrm00/build.sh first)" >&2; exit 1; }

echo "[.] input boot : $BOOT ($(stat -c%s "$BOOT") bytes)"
echo "[.] kernel     : $IMG ($(stat -c%s "$IMG") bytes)"
echo "[.] output     : $OUT"

# Refuse to build on top of an already-patched image rather than silently
# producing something that will not boot.
if command -v magiskboot >/dev/null 2>&1; then
    tmpd="$(mktemp -d)"
    ( cd "$tmpd" && magiskboot unpack -h "$BOOT" >/dev/null 2>&1 || true )
    if [ -e "$tmpd/ramdisk.cpio" ] && \
       magiskboot cpio "$tmpd/ramdisk.cpio" "exists .backup/.magisk" >/dev/null 2>&1; then
        echo "[!] this boot image looks Magisk/FolkPatch-patched." >&2
        echo "    Use a stock boot.img instead, or unpack it first." >&2
        rm -rf "$tmpd"; exit 1
    fi
    rm -rf "$tmpd"
fi

ksud boot-patch -b "$BOOT" -k "$IMG" -o "$OUT"

echo
echo "[+] wrote $OUT"
echo
echo "Flash (fastboot-capable firmware):"
echo "    fastboot flash boot $OUT"
echo "    fastboot reboot"
echo
echo "Then install the ReSukisu manager APK and reboot once more."
echo
echo "DO NOT flash until you have:"
echo "  1. a dump of your current boot partition saved off-device"
echo "  2. a confirmed recovery path (fastboot, or an authorized OPPO EDL account)"
