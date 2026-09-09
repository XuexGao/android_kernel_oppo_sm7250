#!/usr/bin/env bash
#
# Package a flashable ReSukiSU release for PCRM00 (OPPO Reno3 Pro 5G / SM7250 / lito).
#
#   ./pcrm00/package.sh <Image> <dtb> <stock_boot.img> <out_dir>
#
# Produces (from a kernel built by pcrm00/build.sh):
#   out_dir/ReSukiSU_PCRM00_<tag>_<date>-boot.img   complete boot image (our kernel +
#                                                   stock ramdisk + stock DTB), for
#                                                   `fastboot flash boot`
#   out_dir/ReSukiSU_PCRM00_<tag>_<date>.zip        AnyKernel3 package (recovery flash)
#
# Requirements:
#   magiskboot  - in $NATIVE/BIN or on PATH. CI extracts it from a Magisk APK
#                 (lib/x86_64/libmagiskboot.so) using pcrm00/get_magiskboot.py.
#   AnyKernel3  - in $ANYKERNEL3 (default /workspace/AnyKernel3 or ./AnyKernel3).
#                 CI clones https://github.com/osm0sis/AnyKernel3.
#
# Notes:
#   * kernel stored raw (boot image header reports KERNEL_FMT [raw])
#   * the boot image has a SEPARATE DTB section (bootimg v2). We keep the stock
#     ramdisk + stock DTB and only swap the kernel, which is the correct layout
#     for QC non-GKI (NOT the appended Image-dtb form).
#   * AK3 device check is ON and driven by $AK3_DEVICE_NAMES (space-separated
#     ro.product.device values). Set it to empty to disable device checking.
#
set -euo pipefail

IMG="${1:?usage: $0 <Image> <dtb> <stock_boot.img> <out_dir>}"
DTB="${2:?no dtb given}"
STOCK_BOOT="${3:?no stock boot.img given}"
OUT_DIR="${4:?no out_dir given}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TAG="${REKUSISU_TAG:-v4.2.0-rc1}"
DATE="$(date +'%Y%m%d')"
BOOT_OUT="$OUT_DIR/ReSukiSU_PCRM00_${TAG}_${DATE}-boot.img"
ZIP_OUT="$OUT_DIR/ReSukiSU_PCRM00_${TAG}_${DATE}.zip"
KERNEL_STRING="${REKUSISU_KSTRING:-ReSukiSU ${TAG} for OPPO Reno3 Pro 5G (PCRM00) @XuexGao}"
# AK3 device check: if AK3_DEVICE_NAMES is UNSET, fall back to defaults;
# if it is set (even empty), honour it exactly (empty = disable the check).
if [ -z "${AK3_DEVICE_NAMES+x}" ]; then
    AK3_DEVICE_NAMES="${AK3_DEVICE_NAMES_DEFAULT:-PCRM00 rno rno1}"
fi

# --- locate magiskboot ------------------------------------------------------
MAGISKBOOT="${NATIVE_BIN}/magiskboot"
[ -x "$MAGISKBOOT" ] || MAGISKBOOT="$(command -v magiskboot || true)"
[ -x "$MAGISKBOOT" ] || { echo "[!] magiskboot not found (set NATIVE_BIN)" >&2; exit 1; }

# --- locate AnyKernel3 template -------------------------------------------
AK3="${ANYKERNEL3:-/tmp/AnyKernel3}"
[ -d "$AK3" ] && [ -f "$AK3/anykernel.sh" ] || AK3="$ROOT/AnyKernel3"
[ -d "$AK3" ] && [ -f "$AK3/anykernel.sh" ] || { echo "[!] AnyKernel3 template not found" >&2; exit 1; }

[ -f "$IMG" ]        || { echo "[!] no kernel Image: $IMG" >&2; exit 1; }
[ -f "$DTB" ]        || { echo "[!] no dtb: $DTB" >&2; exit 1; }
[ -f "$STOCK_BOOT" ] || { echo "[!] no stock boot: $STOCK_BOOT" >&2; exit 1; }
mkdir -p "$OUT_DIR"

echo "=============================================================="
echo " Package ReSukiSU release"
echo " kernel : $IMG ($(stat -c%s "$IMG") bytes)"
echo " dtb    : $DTB ($(stat -c%s "$DTB") bytes)"
echo " stock  : $STOCK_BOOT ($(stat -c%s "$STOCK_BOOT") bytes)"
echo " tag    : $TAG / $DATE"
echo "=============================================================="

# ---------------------------------------------------------------------------
# 1) Complete boot image: swap the kernel in the stock boot.img
# ---------------------------------------------------------------------------
BOOTDIR="$(mktemp -d)"
trap 'rm -rf "$BOOTDIR"' EXIT

( cd "$BOOTDIR" && "$MAGISKBOOT" unpack "$STOCK_BOOT" )
cp "$IMG" "$BOOTDIR/kernel"
( cd "$BOOTDIR" && "$MAGISKBOOT" repack "$STOCK_BOOT" "$BOOT_OUT" )
[ -f "$BOOT_OUT" ] || { echo "[!] boot repack failed" >&2; exit 1; }
echo "[+] boot : $BOOT_OUT ($(stat -c%s "$BOOT_OUT") bytes)"

# ---------------------------------------------------------------------------
# 2) AnyKernel3 zip
# ---------------------------------------------------------------------------
rm -rf "$BOOTDIR/ak3"
cp -r "$AK3" "$BOOTDIR/ak3"
rm -f "$BOOTDIR/ak3/Image" "$BOOTDIR/ak3/Image-dtb" "$BOOTDIR/ak3/Image.gz" "$BOOTDIR/ak3/zImage" "$BOOTDIR/ak3/dtb" "$BOOTDIR/ak3/*.zip"
cp "$IMG" "$BOOTDIR/ak3/Image"
cp "$DTB" "$BOOTDIR/ak3/dtb"

NL=$'\n'
DEVICE_LINES=""
i=1
for n in $AK3_DEVICE_NAMES; do
    DEVICE_LINES="${DEVICE_LINES}${NL}device.name${i}=${n}"
    i=$((i + 1))
done
DO_DEVICE_CHECK=$([ -n "$AK3_DEVICE_NAMES" ] && echo 1 || echo 0)

cat > "$BOOTDIR/ak3/anykernel.sh" <<EOF
### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers
### AnyKernel setup
# global properties
properties() { '
kernel.string=${KERNEL_STRING}
do.devicecheck=${DO_DEVICE_CHECK}
do.modules=0
do.systemless=1
do.dtb=1
do.cleanup=1
do.cleanuponabort=0${DEVICE_LINES}
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties
### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 \$RAMDISK/*;
set_perm_recursive 0 0 750 750 \$RAMDISK/init* \$RAMDISK/sbin;
} # end attributes
# boot shell variables
BLOCK=auto;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;
NO_MAGISK_CHECK=1;
# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;
# boot install
split_boot;
flash_dtb;
flash_boot;
## end boot install
EOF

( cd "$BOOTDIR/ak3" && /usr/bin/python3 -m zipfile -c "$ZIP_OUT" . 2>/dev/null || true )
# Recreate cleanly, excluding VCS / build droppings from the AnyKernel3 clone.
rm -f "$ZIP_OUT"
/usr/bin/python3 - "$ZIP_OUT" "$BOOTDIR/ak3" <<'PY'
import zipfile, os, sys
zip_out, src = sys.argv[1], sys.argv[2]
skip = {".git", ".github", ".gitignore"}
with zipfile.ZipFile(zip_out, "w", zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk(src):
        dirs[:] = [d for d in dirs if d not in skip]
        for f in files:
            full = os.path.join(root, f)
            arc = os.path.relpath(full, src)
            if arc.endswith(".zip"):
                continue
            z.write(full, arc)
PY
[ -f "$ZIP_OUT" ] || { echo "[!] AK3 zip failed" >&2; exit 1; }
echo "[+] ak3  : $ZIP_OUT ($(stat -c%s "$ZIP_OUT") bytes)"

echo ""
echo "=============================================================="
echo " done."
ls -l "$BOOT_OUT" "$ZIP_OUT"
echo " fastboot: fastboot flash boot $BOOT_OUT"
echo " recovery: install $ZIP_OUT"
echo "=============================================================="