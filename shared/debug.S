/*
 * debug.S
 * 
 * Debug logging to serial line.
 *
 * Written & released by Keir Fraser <keir.xen@gmail.com>
 * 
 * This is free and unencumbered software released into the public domain.
 * See the file COPYING for more details, or visit <http://unlicense.org>.
 */

dbg_putch:
        move.w  #0x1e,0xdff032  /* serper -> 115200 baud */
1:      move.w  0xdff018,d1
        and.w   #0x2000,d1      /* serdatr -> busy? */
        jeq     1b
        and.w   #0xff,d0
        or.w    #0x100,d0
        move.w  d0,0xdff030     /* serdat */
        rts

dbg_puts:
        move.b  (a0)+,d0
        jeq     1f
        jbsr    dbg_putch
        jra     dbg_puts
1:      rts

dbg_put32:
        move.l  d0,d2
        moveq   #8-1,d3
3:      rol.l   #4,d2
        move.b  d2,d0
        and.b   #0xf,d0
        cmp.b   #0xa,d0
        jcs     1f
        add.b   #'a'-0xa,d0
        jra     2f
1:      add.b   #'0',d0
2:      jbsr    dbg_putch
        dbf     d3,3b
        rts

dbg_put8:
        move.l  d0,d2
        rol.w   #8,d2
        swap    d2
        moveq   #2-1,d3
        jra     3b
        
dbg_regs:
        movem.l d0-d7/a0-a7,-(sp)
        move.l  sp,a1
        lea.l   17*4(sp),a0
        move.l  a0,15*4(sp)
        moveq   #4-1,d4
2:      moveq   #4-1,d5
1:      move.l  (a1)+,d0
        jbsr    dbg_put32
        move.b  #' ',d0
        jbsr    dbg_putch
        dbf     d5,1b
        move.b  #'\n',d0
        jbsr    dbg_putch
        dbf     d4,2b
        move.l  16*4(sp),d0
        jbsr    dbg_put32
        move.b  #'\n',d0
        jbsr    dbg_putch
        move.b  #'\n',d0
        jbsr    dbg_putch
        movem.l (sp)+,d0-d7/a0-a6
        addq.l  #4,sp
        rts

dbg_mem:
        movem.l d0-d7/a0-a6,-(sp)
        move.l  16*4(sp),a2
        move.l  17*4(sp),a1
        move.l  15*4(sp),17*4(sp)
2:      moveq   #32,d4
1:      cmp.l   a1,a2
        jls     1f
        move.b  (a1)+,d0
        jbsr    dbg_put8
        move.b  #' ',d0
        jbsr    dbg_putch
        subq.b  #1,d4
        jne     1b
        move.b  #'\n',d0
        jbsr    dbg_putch
        jra     2b
1:      move.b  #'\n',d0
        jbsr    dbg_putch
        move.b  #'\n',d0
        jbsr    dbg_putch
        movem.l (sp)+,d0-d7/a0-a6
        addq.l  #8,sp
        rts
