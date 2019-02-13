
#define local_drive  /*0*/
#define local_text   2      
        
        bra.w   fix_copylock

autoswap_init:
        /* Change stack. */
        movem.l (sp)+,d6-d7
        lea.l   (400).w,sp              /* From patch point */
        move.l  d6,-(sp)                /* Save return address on new stack */

        movem.l d0-d5/a0-a6,-(sp)

        lea     locals(pc),a5
        
        /* Get boot drive number from first loader. */
        move.l  d7,a0
        moveq   #0,d0
        move.b  0xbdb-0x29e(a0),d0
        move.w  d0,local_drive(a5)

        /* Find start address of main game executable. */
        move.l  d6,a0
        lea.l   -0x36(a0),a0
        move.l  a0,local_text(a5)

        lea.l   (0x7ccc0).l,a0   /* trackbuf */
        jbsr    check_ff_unit
        lea     locals(pc),a5

        /* Patch into the RNC sector loader. */
        move.l  local_text(a5),a0
        lea.l   0x6f3a(a0),a1
        lea.l   fix_loader(pc),a2
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

locals:
        dc.w    0
        dc.l    0

fix_loader:
        tst.w   d0
        jne     _loader_fail
        move.w  locals/*+local_drive*/(pc),d0
        rts
_loader_fail:
        moveq   #0x1d,d0
        add.l   #0x6f8c-0x6f3e,(sp)
        rts

fix_copylock:
        move.l  #0xaa794baf,d0
        rts

fix_diskswap:
        movem.l d0-d4/a0-a6,-(sp)
        lea.l   (0x7ccc0).l,a1   /* trackbuf */
        move.l  locals+local_text(pc),a0
        jsr     0x6e36(a0)       /* swizzle trackbuf */
        move.l  a1,a0
        move.w  locals/*+local_drive*/(pc),d0
        jbsr    disk_swap
        lea.l   (0x7ccc0).l,a1   /* trackbuf */
        move.l  locals+local_text(pc),a0
        jsr     0x6e42(a0)       /* unswizzle trackbuf */
        movem.l (sp)+,d0-d4/a0-a6
        rts
        
#include "autoswap.S"
