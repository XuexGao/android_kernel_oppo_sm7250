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
    -e PROC_FS

# --- kprobes -------------------------------------------------------------
# KSU_MANUAL_HOOK_AUTO_INPUT_HOOK registers an input kprobe, and
# runtime/ksud_integration.c calls register_kprobe() directly.
# The STOCK PCRM00 config ships "# CONFIG_KPROBES is not set", so this has to be
# turned on explicitly or the hook silently cannot install.
"$SCONFIG" --file "$CFG" -e KPROBES -e HAVE_KPROBES -e FTRACE

# --- drop the other SoC the released devicetree cannot support ------------
# Stock enables ARCH_LAGOON, but the published devicetree repo carries no lagoon
# board sources for this product. Keeping it on only risks a dtb build error.
"$SCONFIG" --file "$CFG" -d ARCH_LAGOON

# --- module signing -------------------------------------------------------
# Stock embeds OPPO's signing key. A rebuilt kernel generates a fresh one and
# would then reject every stock .ko. Only 5 modules exist (MSM_RDBG, DVB_MPQ,
# DVB_MPQ_DEMUX, LCD_CLASS_DEVICE, QCOM_LLCC_PERFMON) and none are functional,
# so relaxing the check is safe and cheap.
"$SCONFIG" --file "$CFG" -d MODULE_SIG_FORCE

# --- recover the Synaptics TCM touch driver -------------------------------
# OPPO deleted the Kconfig that gated drivers/input/touchscreen/synaptics_tcm/
# while leaving all 10 .c files in place. pcrm00/kconfig/shim/Kconfig re-declares
# those symbols so the driver can actually be built. Reno3 Pro's DT declares
# compatible = "synaptics,tcm-i2c", which this driver matches.
# Set ENABLE_TCM_SHIM=0 to skip (then there is simply no touchscreen).
if [ "${ENABLE_TCM_SHIM:-1}" = "1" ]; then
    "$SCONFIG" --file "$CFG" \
        -e TOUCHSCREEN_SYNAPTICS_TCM \
        -e TOUCHSCREEN_SYNAPTICS_TCM_CORE \
        -e TOUCHSCREEN_SYNAPTICS_TCM_DEVICE \
        -e TOUCHSCREEN_SYNAPTICS_TCM_TOUCH \
        -e TOUCHSCREEN_SYNAPTICS_TCM_I2C \
        -e TOUCHSCREEN_SYNAPTICS_TCM_REFLASH \
        -e TOUCHSCREEN_SYNAPTICS_TCM_RECOVERY \
        -e TOUCHSCREEN_SYNAPTICS_TCM_DIAGNOSTICS
    echo "[+] Synaptics TCM shim enabled (OPPO's TOUCHPANEL_* wrapper is still lost)"
fi

echo "[+] ReSukisu config fragment applied to $CFG"
