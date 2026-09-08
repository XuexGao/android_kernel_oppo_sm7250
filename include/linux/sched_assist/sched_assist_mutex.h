/* pcrm00 shim header: OPPO vendors these mutex hooks in the non-released
 * vendor/oplus/kernel/oplus_performance/sched_assist tree.  kernel/locking/mutex.c
 * includes this and, when sysctl_sched_assist_enabled != 0, routes mutex
 * wait-list management through them.  This build forces
 * sysctl_sched_assist_enabled = 0 (upstream mutex_waiter handling) and keeps these
 * as symbols only, implemented as no-ops in kernel/oplus_pcrm00_shim.c.
 * SPDX-License-Identifier: GPL-2.0-only */
#ifndef _OPLUS_SCHED_ASSIST_MUTEX_H
#define _OPLUS_SCHED_ASSIST_MUTEX_H

struct mutex;
struct task_struct;
struct list_head;

void mutex_list_add(struct task_struct *task, struct list_head *waiter,
		    struct list_head *list, struct mutex *lock);
void mutex_set_inherit_ux(struct mutex *lock, struct task_struct *task);
void mutex_unset_inherit_ux(struct mutex *lock, struct task_struct *task);

#endif /* _OPLUS_SCHED_ASSIST_MUTEX_H */