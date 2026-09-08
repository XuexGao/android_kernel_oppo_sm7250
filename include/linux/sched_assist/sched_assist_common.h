/* pcrm00 shim header: OPPO vendors these scheduler-assist declarations in the
 * non-released vendor/oplus/kernel/oplus_performance/sched_assist tree.  In-tree
 * files (kernel/sched/*, block/*, mm/*, arch/arm64/*) include this header; we
 * surface the symbols they actually use and back them with no-op/neutral
 * implementations in kernel/oplus_pcrm00_shim.c.  sched_assist_scene() returns
 * false and sysctl_sched_assist_enabled stays 0, so the OPPO ux/boost paths
 * short-circuit to upstream behaviour.
 * SPDX-License-Identifier: GPL-2.0-only */
#ifndef _OPLUS_SCHED_ASSIST_COMMON_H
#define _OPLUS_SCHED_ASSIST_COMMON_H

#include <linux/sched.h>
#include <linux/types.h>

enum SCHED_ASSIST_SCENE {
	SA_SLIDE,
	SA_SCENE_MAX,
};

#define HEAVY_LOAD_RUNTIME	(1000000000)	/* ns; only used when is_heavy_load_task() */

/* scheduler-private structs, forward-declared (all uses here are pointers) */
struct cfs_rq;
struct sched_entity;
struct rq;

extern bool test_task_ux(struct task_struct *task);
extern bool is_heavy_ux_task(struct task_struct *task);
extern bool is_heavy_load_task(struct task_struct *task);
extern bool sched_assist_scene(int scene);
extern bool sched_assist_task_misfit(struct task_struct *p, int cpu, int level);
extern void ux_init_cpu_data(void);
extern void ux_init_rq_data(void *rq);
extern void init_task_ux_info(struct task_struct *p);

extern void ux_skip_sync_wakeup(struct task_struct *p, int *sync);
extern void set_ux_task_cpu_common_by_prio(struct task_struct *p, int *best_cpu,
					   bool a, bool b, int c);
extern void set_ux_task_to_prefer_cpu(struct task_struct *p, int *best_cpu);
extern void find_ux_task_cpu(struct task_struct *p, int *best_cpu);
extern bool should_ux_task_skip_cpu(struct task_struct *p, int cpu);
extern bool should_ux_preempt_wakeup(struct task_struct *p, struct task_struct *curr);
extern void enqueue_ux_thread(void *rq, struct task_struct *p);
extern void dequeue_ux_thread(void *rq, struct task_struct *p);
extern void pick_ux_thread(void *rq, struct task_struct **p, struct sched_entity **se);
extern bool should_ux_task_skip_further_check(struct sched_entity *se);
extern void place_entity_adjust_ux_task(struct cfs_rq *cfs_rq, struct sched_entity *se,
					bool initial);

#endif /* _OPLUS_SCHED_ASSIST_COMMON_H */