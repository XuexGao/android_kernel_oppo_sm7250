/* pcrm00 shim header: OPPO vendors process-monitor helpers in the non-released
 * vendor tree; the in-tree files include this and we no-op the helpers in
 * kernel/oplus_pcrm00_shim.c.
 * SPDX-License-Identifier: GPL-2.0-only */
#ifndef _OPLUS_SYSTEM_OPPO_PROCESS_H
#define _OPLUS_SYSTEM_OPPO_PROCESS_H

#include <linux/types.h>

struct task_struct;

extern bool is_critial_process(struct task_struct *task);

#endif /* _OPLUS_SYSTEM_OPPO_PROCESS_H */