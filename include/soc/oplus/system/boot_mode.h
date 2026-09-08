/* pcrm00 shim: OPPO normally keeps its boot-mode getters in the non-released
 * vendor tree; the in-repo declarations live in <soc/oppo/boot_mode.h>.
 * Forward to that so drivers that #include <soc/oplus/system/boot_mode.h>
 * see the enum and get_boot_mode() prototype. */
#ifndef _OPLUS_SYSTEM_BOOT_MODE_H
#define _OPLUS_SYSTEM_BOOT_MODE_H
#include <soc/oppo/boot_mode.h>
#endif