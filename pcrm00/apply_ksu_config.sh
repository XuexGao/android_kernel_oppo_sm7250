#!/usr/bin/env bash
# Enable ReSukisu (KernelSU fork) options on top of an existing .config.
#
# Target: OPPO Reno3 Pro 5G (PCRM00) / SM7250 "lito" / kernel 4.19 (non-GKI).
#
# Hooking method notes (from ReSukisu/kernel/Kconfig):
#   KSU_TRACEPOINT_HOOK -> "Support for kernel 5.10+" (GKI2 only)  -> NOT usable here
#   KSU_MANUAL_HOOK     -> "Support for kernel 3.4+" but "depends on KSU != m"
#                          -> must be built-in (y), LKM is not an option on 4.19
#   KSU_SUSFS           -> alternative to MANUAL_HOOK, aimed at newer trees
set -euo pipefail

CFG="${1:?usage: $0 <path/to/.config>}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCONFIG="$ROOT/scripts/config"

[ -f "$CFG" ]     || { echo "[!] no .config at $CFG" >&2; exit 1; }
[ -x "$SCONFIG" ] || { echo "[!] scripts/config missing (run a make target first)" >&2; exit 1; }

"$SCONFIG" --file "$CFG" \
    -e KSU \
    -d KSU_DEBUG \
    -d KSU_TOOLKIT_SUPPORT \
    -d KSU_DISABLE_MANAGER \
    -d KSU_DISABLE_POLICY \
    -e KSU_MULTI_MANAGER_SUPPORT \
    --set-str KSU_FULL_NAME_FORMAT 'ReSukisu-pcrm00-%TAG_NAME%-%COMMIT_SHA%' \
    \
    -d KSU_TRACEPOINT_HOOK \
    -d KSU_SUSFS \
    -e KSU_MANUAL_HOOK \
    -e KSU_MANUAL_HOOK_AUTO_SETUID_HOOK \
    -e KSU_MANUAL_HOOK_AUTO_INITRC_HOOK \
    -e KSU_MANUAL_HOOK_AUTO_INPUT_HOOK \
    \
    -e KALLSYMS \
    -e KALLSYMS_ALL \
    -e KPROBES \
    -e FTRACE \
    -e PROC_FS \
    \
    -d MODULE_SIG_FORCE

echo "[+] ReSukisu config fragment applied to $CFG"
