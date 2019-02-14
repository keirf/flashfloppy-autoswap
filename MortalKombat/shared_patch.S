/*
 * shared_patch.S
 * 
 * FlashFloppy AutoSwap common patch code for Mortal Kombat.
 * Referenced in both the bootblock and main game code.
 *
 * Written & released by Keir Fraser <keir.xen@gmail.com>
 * 
 * This is free and unencumbered software released into the public domain.
 * See the file COPYING for more details, or visit <http://unlicense.org>.
 */

/* Emit BSR.w (a2) at EA (a1). */
emit_bsr_w:
        move.w  #0x6100,(a1)+
_emit:
        move.l  a2,d0
        sub.l   a1,d0
        move.w  d0,(a1)+
        rts

/* Emit BRA.w (a2) at EA (a1). */
emit_bra_w:
        move.w  #0x6000,(a1)+
        jra     _emit

/* Fixes up the stripped-down RNC sector loader for faster track reads:
 *   1. Reads can start from any sector, not just sector 0
 *   2. Seek latency can be adjusted (specified by caller)
 * IN: a0=code, d0=step_delay (in units of 10*cpu_cycle_time).
 * Scratches: a1-a2/d0 */
rnc_speed_patch:
        /* Modify the seek latency. */
        move.b  d0,0x1cb(a0)
        lsr.w   #8,d0
        move.b  d0,0x1d1(a0)
        /* Store first sector# as a local variable. */
        move.l  #0x3542ffea,0x22e(a0)   /* move.w d2,-0x16(a2) */
        /* Write sector-location patch into unused space (vline wait loop). */
        lea     rnc_decode_patch(pc),a1
        lea     0x1b4(a0),a2
        moveq   #(rnc_decode_patch_end-rnc_decode_patch)/2-1,d0
1:      move.w  (a1)+,(a2)+
        dbf     d0,1b
        /* Patch sector-location code to run the below patch. */
        lea     0x114(a0),a1
        move.w  #0x7209,(a1)+           /* moveq #9,d1 */
        lea     0x1b4(a0),a2            /* bsr.w rnc_decode_patch */
        jra     emit_bsr_w

rnc_decode_patch:
        sub.w   -0x16(a2),d0            /* sector -= first_sector */
        jpl     1f                      /* if (sector < 0)  */
        add.w   #11,d0                  /*     sector += 11 */
1:      lsl.w   d1,d0                   /* sector <<= 9 */
        rts
rnc_decode_patch_end:
        
