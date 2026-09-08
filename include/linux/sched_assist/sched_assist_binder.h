/* pcrm00 shim header: OPPO vendors these binder scheduler hooks in the
 * non-released vendor/oplus/kernel/oplus_performance/sched_assist tree.
 * drivers/android/binder.c uses them (gated on sysctl_sched_assist_enabled,
 * which we keep 0); no-op bodies live in kernel/oplus_pcrm00_shim.c.
 * SPDX-License-Identifier: GPL-2.0-only */
#ifndef _OPLUS_SCHED_ASSIST_BINDER_H
#define _OPLUS_SCHED_ASSIST_BINDER_H

struct task_struct;

void binder_set_inherit_ux(struct task_struct *from, struct task_struct *to);
void binder_unset_inherit_ux(struct task_struct *task);

#endif /* _OPLUS_SCHED_ASSIST_BINDER_H */