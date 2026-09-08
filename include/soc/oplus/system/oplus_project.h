/* pcrm00 shim header: OPPO vendors the project/eng-version plumbing in the
 * non-released vendor/oplus/kernel tree.  In-repo callers need get_eng_version()
 * and the PREVERSION stage; provide a minimal surface and back it with a
 * conservative default in kernel/oplus_pcrm00_shim.c.
 * SPDX-License-Identifier: GPL-2.0-only */
#ifndef _OPLUS_OPLUS_PROJECT_H
#define _OPLUS_OPLUS_PROJECT_H

int get_eng_version(void);

/* OPPO engineering-build stage (reported by get_eng_version). */
#define PREVERSION		0x05
#define HIGH_TEMP_AGING		0x0B
#define AGING			0x01
#define FACTORY			0x0C

#endif /* _OPLUS_OPLUS_PROJECT_H */
