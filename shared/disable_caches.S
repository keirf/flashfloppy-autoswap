/*
 * disable_caches.S
 *
 * Disable caches on 680x0 and clears the VBR.
 *
 * This code is from ross / EAB. Thanks!
 */

#define Exec_Supervisor -0x1e
#define Exec_Disable    -0x78
#define Exec_Enable     -0x7e
        
        .text
        .balign 2

        /* All registers preserved.
         * Disables caches and sets VBR to zero. */
disable_caches:
        movem.l a0-a6/d0,-(sp)

        moveq   #0,d0
        lea     _trap_disable_caches(pc),a5
        lea     0x10.w,a1
        lea     0x2c.w,a2

        movea.l 4.w,a6
        jsr     Exec_Disable(a6)

        movea.l (a1),a3
        movea.l (a2),a4
        move.l  a5,(a1)
        move.l  a5,(a2)

        lea     _super_disable_caches(pc),a5
        jsr     Exec_Supervisor(a6)

        move.l  a3,(a1)
        move.l  a4,(a2)

        jsr     Exec_Enable(a6)

        movem.l (sp)+,a0-a6/d0
        rts

_super_disable_caches:
        /*dc.l    0x4e7a1801*/    /* movec vbr,d1  */
        dc.l    0x4e7b0801        /* movec d0,vbr  */
        dc.l    0xf4784e71        /* cpusha dc     */
        dc.l    0x4e7b0002        /* movec d0,cacr */
        dc.l    0x4e7b0808        /* movec d0,pcr  */
        rte
_trap_disable_caches:
        addq.l  #4,2(sp)
        rte
