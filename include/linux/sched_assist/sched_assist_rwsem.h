/* pcrm00 shim header: OPPO vendors these rwsem hooks in the non-released
 * vendor/oplus/kernel/oplus_performance/sched_assist tree.  kernel/locking/rwsem.h
 * uses them when sysctl_sched_assist_enabled != 0; we keep that 0 (upstream
 * rwsem path) and provide no-op bodies in kernel/oplus_pcrm00_shim.c.
 * SPDX-License-Identifier: GPL-2.0-only */
#ifndef _OPLUS_SCHED_ASSIST_RWSEM_H
#define _OPLUS_SCHED_ASSIST_RWSEM_H

#include <linux/types.h>

struct rw_semaphore;
struct task_struct;
struct list_head;

bool rwsem_list_add(struct task_struct *task, struct list_head *waiter,
		    struct list_head *list, struct rw_semaphore *sem);
void rwsem_set_inherit_ux(struct task_struct *task, struct task_struct *waiter_task,
			   struct task_struct *owner, struct rw_semaphore *sem);
void rwsem_unset_inherit_ux(struct rw_semaphore *sem, struct task_struct *task);

#endif /* _OPLUS_SCHED_ASSIST_RWSEM_H */