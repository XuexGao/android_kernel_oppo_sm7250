#!/usr/bin/env bash
#
# OPPO's public sm7250 GPL release is NOT self-contained: it ships ~80 symlinks
# into vendor/oplus/kernel/... (and vendor/qcom/proprietary/...) that were never
# released. Kbuild dies on the first `obj-y += <missing>/`.
#
# This script makes the tree compile so we can see exactly what is lost:
#   * directory symlinks  -> real dir with an empty Kconfig + no-op Makefile
#   * file symlinks       -> empty file
#   * arch/arm64/boot/dts/vendor -> linked to the real devicetree repo if present
#
# Every stub is recorded in build/stubs.log so the damage is auditable.
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTLOG="$ROOT/build/stubs.log"
DT_SRC="${DT_SRC:-$ROOT/vendor/qcom/proprietary/devicetree-4.19}"

mkdir -p "$(dirname "$OUTLOG")"
: > "$OUTLOG"

n_dir=0; n_file=0; n_dt=0

cd "$ROOT"
while IFS= read -r link; do
    target="$(readlink "$link")"

    # The device tree is genuinely available from OPPO's companion repo.
    if [ "$link" = "arch/arm64/boot/dts/vendor" ]; then
        if [ -d "$DT_SRC" ]; then
            rm -f "$link"; ln -s "$(realpath --relative-to="$(dirname "$link")" "$DT_SRC")" "$link"
            echo "FIXED   $link -> $(readlink "$link")  (real devicetree)" | tee -a "$OUTLOG"
            n_dt=$((n_dt+1)); continue
        else
            echo "WARN    $link left dangling (no devicetree repo at $DT_SRC)" | tee -a "$OUTLOG"
        fi
    fi

    # A link ending in .c/.h/.txt is a file, not a directory.
    case "$link" in
        *.c|*.h|*.txt|*.S)
            rm -f "$link"; : > "$link"
            echo "STUB-F  $link -> $target" | tee -a "$OUTLOG"
            n_file=$((n_file+1)); continue ;;
    esac

    if [ -d "$link" ]; then continue; fi

    rm -f "$link"
    mkdir -p "$link"
    printf '# stubbed: upstream source not released by OPPO\n' > "$link/Kconfig"
    printf '# stubbed: upstream source not released by OPPO\nobj-y :=\n' > "$link/Makefile"
    echo "STUB-D  $link -> $target" | tee -a "$OUTLOG"
    n_dir=$((n_dir+1))
done < <(find . -type l | while read -r l; do [ -e "$l" ] || echo "${l#./}"; done)

echo
echo "[+] stubs: $n_dir dirs, $n_file files; devicetree linked: $n_dt"
echo "[+] log:   $OUTLOG"
