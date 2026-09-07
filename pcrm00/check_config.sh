#!/usr/bin/env bash
# Fail the build early if ReSukisu did not actually end up enabled.
set -euo pipefail

CFG="${1:?usage: $0 <path/to/.config>}"
fail=0

need_y=(
    CONFIG_KSU
    CONFIG_KSU_MANUAL_HOOK
    CONFIG_KALLSYMS
    CONFIG_KALLSYMS_ALL
    CONFIG_KPROBES
    CONFIG_PROC_FS
    CONFIG_ARCH_LITO
)

for k in "${need_y[@]}"; do
    if grep -qx "$k=y" "$CFG"; then
        printf "  ok   %s\n" "$k"
    else
        printf "  MISS %s (got: %s)\n" "$k" "$(grep -E "^#? ?$k" "$CFG" | head -1 || echo nothing)"
        fail=1
    fi
done

# These must NOT be set: they belong to GKI2 / newer trees and conflict with
# the manual-hook choice on a 4.19 non-GKI kernel.
for k in CONFIG_KSU_TRACEPOINT_HOOK CONFIG_KSU_SUSFS CONFIG_MODULE_SIG_FORCE; do
    if grep -qx "$k=y" "$CFG"; then
        echo "  BAD  $k is enabled but should not be"
        fail=1
    else
        echo "  ok   $k disabled"
    fi
done

# LKM mode cannot carry the manual hook (Kconfig: "depends on KSU != m").
if grep -qx "CONFIG_KSU=m" "$CFG"; then
    echo "  BAD  CONFIG_KSU=m -- manual hook requires built-in (y) on 4.19"
    fail=1
fi

[ "$fail" -eq 0 ] || { echo "[!] config check failed" >&2; exit 1; }
echo "[+] config check passed"
