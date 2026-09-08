// SPDX-License-Identifier: GPL-2.0-only
/*
 * pcrm00 shim: implementations of OPPO helper routines whose original source
 * ships in the non-released vendor/oplus/kernel trees.  This build reuses the
 * stock device tree and does not have the PMIC boot-mode plumbing OPPO built,
 * so these return conservative defaults that keep the in-repo callers linking.
 */
#include <linux/types.h>
#include <linux/sched.h>
#include <linux/module.h>
#include <linux/list.h>
#include <soc/oplus/system/boot_mode.h>
#include <linux/sched_assist/sched_assist_common.h>
#include <linux/sched_assist/sched_assist_mutex.h>
#include <linux/sched_assist/sched_assist_rwsem.h>
#include <soc/oplus/system/oppo_process.h>

struct mutex;
struct rw_semaphore;

bool is_critial_process(struct task_struct *task)
{
	return false;
}
EXPORT_SYMBOL(is_critial_process);

int get_boot_mode(void)
{
	return MSM_BOOT_MODE__NORMAL;
}
EXPORT_SYMBOL(get_boot_mode);

bool test_task_ux(struct task_struct *task)
{
	return false;
}
EXPORT_SYMBOL(test_task_ux);

bool is_heavy_ux_task(struct task_struct *task)
{
	return false;
}
EXPORT_SYMBOL(is_heavy_ux_task);

bool sched_assist_scene(int scene)
{
	return false;
}
EXPORT_SYMBOL(sched_assist_scene);

void ux_init_cpu_data(void)
{
}
EXPORT_SYMBOL(ux_init_cpu_data);

void ux_init_rq_data(void *rq)
{
}
EXPORT_SYMBOL(ux_init_rq_data);

void init_task_ux_info(struct task_struct *p)
{
}
EXPORT_SYMBOL(init_task_ux_info);

bool is_heavy_load_task(struct task_struct *task)
{
	return false;
}
EXPORT_SYMBOL(is_heavy_load_task);

bool sched_assist_task_misfit(struct task_struct *p, int cpu, int level)
{
	return false;
}
EXPORT_SYMBOL(sched_assist_task_misfit);

void ux_skip_sync_wakeup(struct task_struct *p, int *sync)
{
}
EXPORT_SYMBOL(ux_skip_sync_wakeup);

void set_ux_task_cpu_common_by_prio(struct task_struct *p, int *best_cpu,
				    bool a, bool b, int c)
{
}
EXPORT_SYMBOL(set_ux_task_cpu_common_by_prio);

void set_ux_task_to_prefer_cpu(struct task_struct *p, int *best_cpu)
{
}
EXPORT_SYMBOL(set_ux_task_to_prefer_cpu);

void find_ux_task_cpu(struct task_struct *p, int *best_cpu)
{
}
EXPORT_SYMBOL(find_ux_task_cpu);

bool should_ux_task_skip_cpu(struct task_struct *p, int cpu)
{
	return false;
}
EXPORT_SYMBOL(should_ux_task_skip_cpu);

bool should_ux_preempt_wakeup(struct task_struct *p, struct task_struct *curr)
{
	return false;
}
EXPORT_SYMBOL(should_ux_preempt_wakeup);

void enqueue_ux_thread(void *rq, struct task_struct *p)
{
}
EXPORT_SYMBOL(enqueue_ux_thread);

void dequeue_ux_thread(void *rq, struct task_struct *p)
{
}
EXPORT_SYMBOL(dequeue_ux_thread);

void pick_ux_thread(void *rq, struct task_struct **p, struct sched_entity **se)
{
}
EXPORT_SYMBOL(pick_ux_thread);

bool should_ux_task_skip_further_check(struct sched_entity *se)
{
	return false;
}
EXPORT_SYMBOL(should_ux_task_skip_further_check);

void place_entity_adjust_ux_task(struct cfs_rq *cfs_rq, struct sched_entity *se,
				 bool initial)
{
}
EXPORT_SYMBOL(place_entity_adjust_ux_task);

void mutex_list_add(struct task_struct *task, struct list_head *waiter,
		    struct list_head *list, struct mutex *lock)
{
	/* SCHED_ASSIST wait-list path is disabled (sysctl_sched_assist_enabled=0). */
}
EXPORT_SYMBOL(mutex_list_add);

void mutex_set_inherit_ux(struct mutex *lock, struct task_struct *task)
{
}
EXPORT_SYMBOL(mutex_set_inherit_ux);

void mutex_unset_inherit_ux(struct mutex *lock, struct task_struct *task)
{
}
EXPORT_SYMBOL(mutex_unset_inherit_ux);

bool rwsem_list_add(struct task_struct *task, struct list_head *waiter,
		    struct list_head *list, struct rw_semaphore *sem)
{
	return false;
}
EXPORT_SYMBOL(rwsem_list_add);

void rwsem_set_inherit_ux(struct task_struct *task, struct task_struct *waiter_task,
			   struct task_struct *owner, struct rw_semaphore *sem)
{
}
EXPORT_SYMBOL(rwsem_set_inherit_ux);

void rwsem_unset_inherit_ux(struct rw_semaphore *sem, struct task_struct *task)
{
}
EXPORT_SYMBOL(rwsem_unset_inherit_ux);