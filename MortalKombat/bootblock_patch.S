/*
 * bootblock_patch.S
 * 
 * FlashFloppy AutoSwap bootblock patch for Mortal Kombat.
 *
 * Written & released by Keir Fraser <keir.xen@gmail.com>
 * 
 * This is free and unencumbered software released into the public domain.
 * See the file COPYING for more details, or visit <http://unlicense.org>.
 */

        /* Find boot drive */
        jbsr    CheckDrives

        /* Patch the first loader to use the boot drive. */
        or.w    #0x7000,d0
        move.w  d0,0xbda(a3)            /* moveq #<drive>,d0 */
        move.w  #0x4e71,0xbdc(a3)       /* nop */

        /* Clobber ExecBase after loader and pretend to be a 68000
         * (we disabled caches so no need for flushes). */
        lea     0x294(a3),a0
        move.l  #0x46b80004,(a0)+       /* not.l 4.w (clobber ExecBase) */
        move.l  #0x72007200,(a0)+       /* moveq #0,d1 (fake AttnFlags) */
        move.w  #0x4e91,(a0)+           /* jsr (a1) */

        /* Speed up the first loader. */
        lea.l   0xbc6(a3),a0
        move.w  #0x868,d0               /* ~3ms */
        jbsr    rnc_speed_patch

        /* Disable caches and then continue the load. */
        jra     disable_caches

#include "shared_patch.S"
#include "../shared/disable_caches.S"
#include "../shared/boot_drive_detect.S"
