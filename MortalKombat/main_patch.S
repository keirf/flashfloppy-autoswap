/*
 * main_patch.S
 * 
 * FlashFloppy AutoSwap main game code patch for Mortal Kombat.
 *
 * Written & released by Keir Fraser <keir.xen@gmail.com>
 * 
 * This is free and unencumbered software released into the public domain.
 * See the file COPYING for more details, or visit <http://unlicense.org>.
 */

/* Offsets into variable list. */
#define var_drive  /*0*/ /* Boot drive unit number */
#define var_cyl    2     /* Current drive head position (cylinder) */
#define var_text   4     /* Start of main game code (for patches and jumps) */

        /* We patch the Copylock entry point, so first thing is to
         * branch at our bypass code. */
        bra.w   fix_copylock

        /* Called on entry to main game executable.
         * Initialises AutoSwap and applies game patches. */
autoswap_init:
        /* Change stack. */
        movem.l (sp)+,d6-d7
        lea.l   (400).w,sp              /* From patch point */
        move.l  d6,-(sp)                /* Save return address on new stack */

        movem.l d0-d5/a0-a6,-(sp)

        lea     vars(pc),a5
        move.l  a1,var_text(a5)
        
        /* Get boot drive number from first loader. */
        move.l  d7,a0
        moveq   #0,d0
        move.b  0xbdb-0x29e(a0),d0
        move.w  d0,var_drive(a5)

        /* Set up the AutoSwap subsystem. */
        lea.l   (0x7ccc0).l,a0   /* trackbuf */
        moveq   #0,d1            /* disk 0 */
        jbsr    check_ff_unit
        lea     vars(pc),a5

        /* RNC sector loader: boot drive responds as unit 0. */
        move.l  var_text(a5),a0
        lea.l   0x6f3a(a0),a1
        lea.l   rnc_fixup_entry(pc),a2
        jbsr    emit_bsr_w
        lea.l   0x6f8c(a0),a1
        lea.l   rnc_fixup_exit(pc),a2
        jbsr    emit_bsr_w

        /* RNC sector loader: don't seek cylinder 0. */
        move.w  #0x4e75,0x708e(a0) /* rts (stubs out the seek routine) */

        /* Read-sector retry loop: seek to cyl 0 on fail. */
        lea.l   0x6a00(a0),a1
        lea.l   loader_fix_retry(pc),a2
        jbsr    emit_bsr_w

        /* Patch into disk-swap requester. */
        lea.l   0x6a88(a0),a1
        lea.l   fix_diskswap(pc),a2
        jbsr    emit_bsr_w
        lea.l   0x6a80(a0),a2
        jbsr    emit_bra_w

        /* Speed patches for RNC sector loader. */
        lea.l   0x6f26(a0),a0
        move.w  #0x300,d0       /* ~1.1ms */
        jbsr    rnc_speed_patch

        movem.l (sp)+,d0-d5/a0-a6
        rts

#include "shared_patch.S"

vars:
        dc.w    0 /* var_drive */
        dc.w    0 /* var_cyl */
        dc.l    0 /* var_text */

/* Trivial Copylock bypass. */
fix_copylock:
        move.l  #0xaa794baf,d0
        rts

/* Fix up on common entry path in RNC loader. */
rnc_fixup_entry:
        /* Restore the current head position into RNC local stack frame. */
        clr.w   -0x28(a2)       /* no buffered track */
        move.w  vars+var_cyl(pc),-0x26(a2) /* current cyl */
        /* Drive 0 requested? Bail if not. */
        tst.w   d0
        jne     _loader_fail
        /* Is this our special request for the file-table/disk-id sector? */
        tst.w   d2
        jpl     1f
        neg.w   d2          /* It is the special request, so unswizzle d2... */
        jra     _loader_run /* ...and run the RNC loader. */
        /* Is this an ordinary request for the file-table/disk-id sector? */
1:      cmp.w   #0x18,d1
        jne     _loader_run
        cmp.w   #1,d2
        jne     _loader_run
        /* It is! Then copy that sector out from our cached copy. */
        movem.l a0-a1,-(sp)
        lea.l   id_sector(pc),a1
        moveq   #512/4-1,d0
1:      move.l  (a1)+,(a0)+
        dbf     d0,1b
        movem.l (sp)+,a0-a1
        moveq   #0,d0
        jra     _loader_out
_loader_run:
        /* Jump back into the RNC loader, loading from the boot-drive unit. */
        move.w  vars/*+var_drive*/(pc),d0
        rts
_loader_fail:
        moveq   #0x1d,d0
_loader_out:
        /* Run the common exit path from RNC loader. */
        add.l   #0x6f8c-0x6f3e,(sp)
        rts

/* Fix up on common exit path from RNC loader. */
rnc_fixup_exit:
        lea     vars(pc),a0
        /* Save the current head position for the next RNC invocation. */
        move.w  -0x26(a2),var_cyl(a0)
        /* Jump at the routine we were patched over. */
        move.l  var_text(a0),a0
        jmp     0x7076(a0)
        
/* Seek to cylinder 0 when a normal disk access fails. */
loader_fix_retry:
        move.l  vars+var_text(pc),a1
        jsr     0x6ebe(a1)      /* what we patched over */
        jeq     1f
        /* Read failed: seek back to cylinder 0. */
        movem.l d0-d4/a0-a6,-(sp)
        lea     (0xDFF000).l,a4
        lea     (0xBFD100).l,a5
        jbsr    seek_0
        lea     vars(pc),a0
        clr.w   var_cyl(a0)
        movem.l (sp)+,d0-d4/a0-a6
        tst.w   d0
1:      rts

/* Instead of displaying a disk-swap requester, ask FlashFloppy to do it. */
fix_diskswap:
        movem.l d0-d7/a0-a6,-(sp)
        /* Swizzle the trackbuf. */
        lea.l   (0x7ccc0).l,a1   /* trackbuf */
        move.l  vars+var_text(pc),a0
        jsr     0x6e36(a0)       /* swizzle trackbuf */
        /* Request disk swap. */
        move.l  a1,a0
        move.w  vars/*+var_drive*/(pc),d0
        jbsr    disk_swap
        /* Swap request leaves us at cyl 0. */
        lea.l   vars(pc),a5
        clr.w   var_cyl(a5)
        /* Read ID sector into our cache. */
        moveq   #0,d0
        moveq   #0x18,d1
        moveq   #-1,d2           /* -1 = special request, fill cache */
        moveq   #0,d4
        lea.l   id_sector(pc),a0
        clr.l   (a0)
        lea.l   (0x7ccc0).l,a1   /* trackbuf */
        move.l  var_text(a5),a2
        jsr     0x6f26(a2)       /* RNC_load */
        /* Unswizzle the trackbuf. */
        move.l  a2,a0
        jsr     0x6e42(a0)       /* unswizzle trackbuf */
        movem.l (sp)+,d0-d7/a0-a6
        rts
        
#include "../shared/autoswap.S"

        .balign 2
/* Cached copy of current disk's sector 0x18 (Disk-ID/File-Table). */
id_sector:
        ds.b    512
