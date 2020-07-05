/*
 * disable_caches.S
 *
 * Disable caches on 680x0 and clears the VBR.
 *
 * Heavily based on original code from ross / EAB. Thanks!
 */

#define Exec_Supervisor -0x1e
#define Exec_Disable    -0x78
#define Exec_Enable     -0x7e
        
        .text
        .balign 2

        /* All registers preserved.
         * Disables caches and sets VBR to zero. */
disable_caches:
        movem.l a4-a6/d0-d1,-(sp)

        moveq   #0,d0
        moveq   #0,d1
        lea     _trap_disable_caches(pc),a5
        lea     0x10.w,a4

        movea.l 4.w,a6
        jsr     Exec_Disable(a6)

        move.l  (a4),-(sp)
        move.l  a5,(a4)

        lea     _super_disable_caches(pc),a5
        jsr     Exec_Supervisor(a6)

        move.l  (sp)+,(a4)

        jsr     Exec_Enable(a6)

        movem.l (sp)+,a4-a6/d0-d1
        rts

_super_disable_caches:
        dc.l    0x4e7b0801        /* movec d0,vbr  */
        dc.l    0x4e7a1002        /* movec cacr,d1 */
        tst.l   d1                /* Bit 31 set? (68040+ Data Cache Enabled) */
        jpl     1f                /* Skip CPUSHA if not */
        dc.w    0xf478            /* cpusha dc     */ /* 68040+ only */
1:      dc.l    0x4e7b0002        /* movec d0,cacr */
        dc.l    0x4e7b0808        /* movec d0,pcr  */
        rte
_trap_disable_caches:
        addq.l  #4,2(sp)
        rte
