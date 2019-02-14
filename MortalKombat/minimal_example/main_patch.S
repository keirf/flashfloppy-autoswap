/*
 * main_patch.S
 * 
 * FlashFloppy AutoSwap main game code patch for Mortal Kombat.
 * **** STRIPPED-DOWN MINIMAL EXAMPLE FOR TUTORIAL PURPOSES ****
 *
 * Written & released by Keir Fraser <keir.xen@gmail.com>
 * 
 * This is free and unencumbered software released into the public domain.
 * See the file COPYING for more details, or visit <http://unlicense.org>.
 */

/* We patch over the Copylock entry point, so first instruction must jump to
 * the bypass routine. */
        bra.w   fix_copylock

/* Called on entry to main game executable.
 * Initialises AutoSwap and applies game patches. */
autoswap_init:
        movem.l d1-d4/a0-a6,-(sp)

        /* Patch into disk-swap request loop. */
        move.l  a1,a0            /* a1 = a0 = start of main game code */
        lea.l   0x6a88(a0),a1
        lea.l   fix_diskswap(pc),a2
        jbsr    emit_bsr_w       /* BSR.w fix_diskswap */
        lea.l   0x6a80(a0),a2
        jbsr    emit_bra_w       /* BRA.w retry_disk_id */

        /* Set up the AutoSwap subsystem. */
        lea.l   (0x7ccc0).l,a0   /* trackbuf */
        moveq   #0,d0            /* drive 0 */
        moveq   #0,d1            /* disk 0 */
        jbsr    check_ff_unit

        movem.l (sp)+,d1-d4/a0-a6
        move.l  2(a1),d0         /* instruction we patched over */
        rts

/* Emit BSR.w (a2) at EA (a1). */
emit_bsr_w:
        move.w  #0x6100,(a1)+    /* BSR.w opcode */
_emit:
        move.l  a2,d0
        sub.l   a1,d0
        move.w  d0,(a1)+         /* offset */
        rts
        
/* Emit BRA.w (a2) at EA (a1). */
emit_bra_w:
        move.w  #0x6000,(a1)+    /* BRA.w opcode */
        jra     _emit

/* Trivial Copylock bypass. */
fix_copylock:
        move.l  #0xaa794baf,d0   /* game serial key */
        rts

/* Instead of displaying a disk-swap requester, ask FlashFloppy to do it.
 * (NB. Disk number is already in register d1). */
fix_diskswap:
        movem.l d0-d4/a0-a6,-(sp)
        lea.l   (0x7ccc0).l,a0   /* trackbuf */
        moveq   #0,d0            /* drive 0 */
        jbsr    disk_swap
        movem.l (sp)+,d0-d4/a0-a6
        rts
        
#include "../../shared/autoswap.S"
