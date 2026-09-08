#!/usr/bin/env bash
#
# Build a ReSukisu-enabled kernel image for OPPO Reno3 Pro 5G (PCRM00, SM7250/lito).
#
# Produces:
#   $OUT/arch/arm64/boot/Image        raw arm64 kernel (matches stock format)
#   $OUT/pcrm00/Image-dtb             Image + stock PCRM00 dtb.img  <-- flash payload
#   $OUT/pcrm00/.config               the exact config used
#
# The device tree is NOT rebuilt: we reuse the stock dtb.img/dtbo.img so the
# hardware description stays byte-identical to what the phone ships with.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${OUT:-$ROOT/out}"
DEFCONFIG="${DEFCONFIG:-vendor/lito-perf_defconfig}"
ARCH=arm64
CC_BIN="${CC:-clang}"
LD_BIN="${LD:-ld.lld}"
CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}"
J="${J:-$(nproc)}"
DTB="$ROOT/pcrm00/dtb.img"

MK=(make -C "$ROOT" O="$OUT" "ARCH=$ARCH" "CC=$CC_BIN" "LD=$LD_BIN" "CROSS_COMPILE=$CROSS_COMPILE")

echo "=============================================================="
echo " OPPO Reno3 Pro 5G (PCRM00) - ReSukisu kernel build"
echo " src      : $ROOT"
echo " out      : $OUT"
echo " defconf  : $DEFCONFIG"
echo " toolchain: CC=$CC_BIN LD=$LD_BIN CROSS_COMPILE=$CROSS_COMPILE"
echo " jobs     : $J"
echo "=============================================================="

"$CC_BIN" --version | head -2
echo

echo "[1/5] base config"
# Prefer the config extracted from the phone's own stock kernel over the
# shipped defconfig: pcrm00/stock_config came out of `scripts/extract-ikconfig`
# on the real PCRM00 Image, so it is 6167 lines of what the device actually
# runs, versus 1040 lines of a Reno4 Pro vendor defconfig. Set USE_STOCK_CONFIG=0
# to fall back to $DEFCONFIG.
STOCKCFG="$ROOT/pcrm00/stock_config"
if [ "${USE_STOCK_CONFIG:-1}" = "1" ] && [ -f "$STOCKCFG" ]; then
    echo "      using stock config extracted from the device ($(grep -c '' "$STOCKCFG") lines)"
    mkdir -p "$OUT"
    cp "$STOCKCFG" "$OUT/.config"
    "${MK[@]}" olddefconfig
else
    echo "      using $DEFCONFIG"
    "${MK[@]}" $DEFCONFIG
fi

echo "[2/5] ReSukisu config fragment"
"$ROOT/pcrm00/apply_ksu_config.sh" "$OUT/.config"
"${MK[@]}" olddefconfig

echo "[3/5] sanity check"
"$ROOT/pcrm00/check_config.sh" "$OUT/.config"

echo "[4/5] compiling Image (-j$J)"
"${MK[@]}" Image 2>&1 | tee "$OUT/build.log" | grep --line-buffered -vE "^  (CC|AS|AR|LD|GEN|CALL|HOSTCC|HOSTLD|DESCEND)" || true

IMG="$OUT/arch/arm64/boot/Image"
[ -f "$IMG" ] || { echo "[!] build produced no $IMG -- see $OUT/build.log" >&2; exit 1; }

echo "[5/5] appending stock PCRM00 dtb"
[ -f "$DTB" ] || { echo "[!] missing $DTB (stock dtb.img)" >&2; exit 1; }
mkdir -p "$OUT/pcrm00"
cat "$IMG" "$DTB" > "$OUT/pcrm00/Image-dtb"
cp "$OUT/.config" "$OUT/pcrm00/.config"

echo
echo "=============================================================="
echo " done."
ls -l "$IMG" "$OUT/pcrm00/Image-dtb"
echo
echo " next: flash with pcrm00/pack_boot.sh (needs your stock boot.img)"
echo "=============================================================="
