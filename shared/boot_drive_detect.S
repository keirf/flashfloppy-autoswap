#define _LVOOpenDevice  -444
#define _LVOCloseDevice -450

#define io_Unit         24

        .text
        .balign 2

/* IN: a1: Boot TDIOReq, a6: ExecBase
 * OUT: d0.l: boot drive
 * Scratches: a0/a2/d1-d3 */
CheckDrives:
        move.l  a1,a2            /* a2 = Boot TDIOReq */
        moveq   #-1,d2           /* d2 = boot drive (-1 = unknown) */
        moveq   #4-1,d3          /* d3 = device number and loop counter */
_loop:
        lea     tdname(pc),a0
        lea     IOReq(pc),a1
        move.l  d3,d0            /* drive# */
        moveq   #0,d1            /* flags */
        jsr     _LVOOpenDevice(a6)
        tst.l   d0
        jne     _nodev
        lea     IOReq(pc),a1
        move.l  io_Unit(a1),d0
        cmp.l   io_Unit(a2),d0
        jne     1f
        move.l  d3,d2            /* Found the boot drive! */
1:      jsr     _LVOCloseDevice(a6)
_nodev: dbf     d3,_loop
        move.l  a2,a1
        move.l  d2,d0
        rts

IOReq:  ds.b    56 /* sizeof(IOExtTD) */
tdname: .asciz "trackdisk.device"
