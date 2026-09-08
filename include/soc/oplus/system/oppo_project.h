/* pcrm00 shim header: OPPO vendors the real project/PCB plumbing in the
 * non-released vendor/oplus/kernel tree.  drivers/soc/oplus/oplus_gpio
 * includes this and uses get_PCB_Version() plus the EVT/DVT board stages;
 * provide a minimal, self-contained surface so that driver compiles and
 * links against the conservative default in kernel/oplus_pcrm00_shim.c.
 * SPDX-License-Identifier: GPL-2.0-only */
#ifndef _OPLUS_OPPO_PROJECT_H
#define _OPLUS_OPPO_PROJECT_H

int get_PCB_Version(void);

/* Board stages used by oplus_gpio to pick the DTB-matching GPIO driver. */
#define EVT6	6
#define DVT6	8

#endif /* _OPLUS_OPPO_PROJECT_H */