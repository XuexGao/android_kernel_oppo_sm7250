/* pcrm00 shim header: OPPO vendors the fb-kevent plumbing in the
 * non-released vendor/oplus/kernel tree.  drivers/soc/qcom/subsys-pil-tz.c
 * calls oplus_kevent_fb_str() unconditionally on ADSP/CDSP/SLPI crash; give it
 * a self-contained surface and back it with a no-op in
 * kernel/oplus_pcrm00_shim.c so the tree compiles and links.
 * SPDX-License-Identifier: GPL-2.0-only */
#ifndef _OPLUS_KERNEL_FB_H
#define _OPLUS_KERNEL_FB_H

#include <linux/types.h>

/* Minimal subset of the OPPO fb-kevent module/event ids referenced by
 * in-repo drivers; full enum lives in the unreleased vendor tree. */
#define FB_SENSOR		3

/* used by subsys-pil-tz.c */
#define FB_SENSOR_ID_CRASH	1

void oplus_kevent_fb_str(unsigned int module, unsigned int event,
			 const char *str);

#endif /* _OPLUS_KERNEL_FB_H */