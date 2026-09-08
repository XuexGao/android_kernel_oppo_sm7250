/* pcrm00 shim header: OPPO vendors fork-time scheduler hooks in
 * vendor/oplus/kernel/oplus_performance/sched_assist.  kernel/fork.c includes
 * this; we expose the symbols it uses and back them with no-ops in
 * kernel/oplus_pcrm00_shim.c.
 * SPDX-License-Identifier: GPL-2.0-only */
#ifndef _OPLUS_SCHED_ASSIST_FORK_H
#define _OPLUS_SCHED_ASSIST_FORK_H

#include <linux/sched.h>

extern void init_task_ux_info(struct task_struct *p);

#endif /* _OPLUS_SCHED_ASSIST_FORK_H */