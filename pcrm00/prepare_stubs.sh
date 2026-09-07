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

# ---------------------------------------------------------------------------
# Pass 2: paths that are not symlinks at all - simply never shipped.
# Some (e.g. net/oplus_modules) are even listed in the tree's .gitignore, so
# they are absent rather than dangling. Kconfig aborts on `source "<missing>"`,
# so those have to be stubbed too or the build never reaches compilation.
# ---------------------------------------------------------------------------

stub_dir() { # $1 = path relative to repo root, $2 = tag, $3 = referencer
    [ -n "$1" ] || return 0
    case "$1" in */|.|..) return 0 ;; esac
    # Kconfig `source` accepts make-style variables; those lines are expanded by
    # the real Kconfig preprocessor. Never create a literal '$(...)' directory.
    case "$1" in *'$'*) return 0 ;; esac
    [ -e "$1" ] || [ -L "$1" ] && return 0
    mkdir -p "$1" 2>/dev/null || return 0
    printf '# stubbed: upstream source not released by OPPO\n' > "$1/Kconfig"
    printf '# stubbed: upstream source not released by OPPO\nobj-y :=\n' > "$1/Makefile"
    echo "$2  $1  (referenced by $3)" | tee -a "$OUTLOG"
    n_dir=$((n_dir+1))
}

# 2a. every `source "x/Kconfig"` / `osource "x/Kconfig"` in the tree
while IFS=$'\t' read -r kfile src; do
    [ -n "$src" ] || continue
    case "$src" in *Kconfig) d="${src%/Kconfig}" ;; *) continue ;; esac
    [ -n "$d" ] || continue
    stub_dir "$d" "STUB-K" "$kfile"
done < <(find . -name Kconfig -type f 2>/dev/null | while read -r kf; do
             grep -hoE '(osource|source)[[:space:]]+"[^"]+"' "$kf" 2>/dev/null \
               | sed -E 's/^(osource|source)[[:space:]]+"//; s/"$//' \
               | while read -r s; do printf '%s\t%s\n' "$kf" "$s"; done
         done)

# 2b. unconditional `obj-y += some/dir/` - Kbuild always descends into these.
while IFS=$'\t' read -r mk dir; do
    [ -n "$dir" ] || continue
    base="$(dirname "$mk")"
    [ "$base" = "." ] && rel="$dir" || rel="$base/$dir"
    stub_dir "$rel" "STUB-M" "$mk"
done < <(find . -name Makefile -type f 2>/dev/null | while read -r mf; do
             grep -hoE '^obj-y[[:space:]]*\+[[:space:]]*=[[:space:]]*[A-Za-z0-9_./-]+/' "$mf" 2>/dev/null \
               | sed -E 's#.*=[[:space:]]*##' \
               | while read -r d; do printf '%s\t%s\n' "$mf" "$d"; done
         done)

echo
echo "[+] stubs: $n_dir dirs, $n_file files; devicetree linked: $n_dt"
echo "[+] log:   $OUTLOG"

# ---------------------------------------------------------------------------
# Pass 3: hook in the Kconfig shim that re-declares symbols OPPO deleted while
# leaving the corresponding driver sources in the tree (see the file's header).
# ---------------------------------------------------------------------------
SHIM='pcrm00/kconfig/shim/Kconfig'
if [ -f "$ROOT/$SHIM" ]; then
    if ! grep -q "$SHIM" "$ROOT/drivers/Kconfig"; then
        sed -i "/^endmenu\$/i source \"$SHIM\"" "$ROOT/drivers/Kconfig"
        echo "[+] sourced $SHIM from drivers/Kconfig"
    else
        echo "[=] $SHIM already sourced"
    fi
fi
