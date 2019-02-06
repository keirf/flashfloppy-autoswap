/*
 * autoswap.S
 * 
 * FlashFloppy AutoSwap for inserting into Amiga trackloaders.
 *
 * Written & released by Keir Fraser <keir.xen@gmail.com>
 * 
 * This is free and unencumbered software released into the public domain.
 * See the file COPYING for more details, or visit <http://unlicense.org>.
 */

/* Local variables (a6 offsets). */
#define loc_cyl      -1
#define loc_drive    -2
#define loc_disk     -3
#define loc_mfm      -8

/* CIA registers (a5 offsets). */
#define ciaapra      0xf01
#define ciabprb      /*0*/

/* Custom registers (a4 offsets). */
#define vhposr       0x006
#define intreqr      0x01e
#define dskpt        0x020
#define dsklen       0x024
#define dsksync      0x07e
#define dmacon       0x096
#define intreq       0x09c
#define adkcon       0x09e
#define color00      0x180

/* Direct Access: Command IDs. */
#define CMD_SET_LBA      1 /* p[0-3] = LBA (little endian) */
#define CMD_SELECT_NAME 10 /* p[] = name (c string) */

/* Direct Access: Status sector offsets. */
#define da_sts_lba      20

/* Chipmem buffer: Offsets (from loc_mfm). */
#define mfm_off        0
#define crc_table_off  1080
#define buffer_len     (1080+512) /* 1592 bytes */

        /**************************
         * d0 = drive #, d1 = disk #, a0 = trackbuf
         * Scratches: d0-d4/a0-a6 */
disk_swap:
        /*movem.l d0-d4/a0-a6,-(sp)*/
        link.w  a6,#-8
        jbsr    setup_state
        jbsr    motor_on
        jbsr    seek_da
        jeq     total_fail
        lea.l   _sel_name(pc),a3
        jbsr    write_cmd       /* send the req */
        jbsr    seek_0
        unlk    a6
        /*movem.l (sp)+,d0-d4/a0-a6*/
        rts

_sel_name:
        move.b  #CMD_SELECT_NAME,(a2)+
        lea.l   image_name(pc),a0
1:      move.b  (a0)+,(a2)+
        jpl     1b              /* Copy up to '\xff' */
        moveq   #'0',d0
        add.b   loc_disk(a6),d0
        move.b  d0,-1(a2)       /* '\xff' -> Disk number */
1:      move.b  (a0)+,(a2)+
        jne     1b
        rts

total_fail:
        move.w  vhposr(a4),color00(a4)
        jra     total_fail

setup_state:
        moveq   #1,d2
        addq.w  #3,d0
        lsl.b   d0,d2
        not.b   d2
        move.b  d2,loc_drive(a6) /* CIAAPRA select mask */
        move.b  d1,loc_disk(a6)
        move.l  a0,loc_mfm(a6)
        sf.b    loc_cyl(a6)
        lea     (0xDFF000).l,a4
        lea     (0xBFD100).l,a5
        /* Generate CRC table */
        move.l  a0,a1
        lea.l   crc_table_off(a1),a1
        jra     crc16_ccitt_gentable

        /**************************
         * d0 = drive#, a0 = trackbuf
         * Scratches: d0-d4/a0-a6 */
check_ff_unit:
        /*movem.l d0-d4/a0-a6,-(sp)*/
        link.w  a6,#-8
        jbsr    setup_state

        /* Motor off and wait 500ms for the motor to spin down. */
        jbsr    motors_off
        move.w  #8000,d1        /* ~500ms */
1:      jbsr    wait_vline
        dbf     d1,1b

        /* Re-enable the motor and almost immediately check if the drive
         * is READY. A real drive will not be ready. */
        jbsr    motor_on
        jbsr    wait_vline
        jbsr    wait_vline
        btst    #5,ciaapra(a5)
        jne     total_fail

        jbsr    seek_da
        jra     1f

        /* Check the status sector and get us to LBA -1. */
_check_status:
        jbsr    read_status
1:      jeq     total_fail
        tst.b   da_sts_lba+3(a0)
        jpl     _set_lba

        /* We are at LBA -1. Now we need sector #1. */
        moveq   #5,d4           /* d4 = retry counter */
1:      subq.w  #1,d4
        jeq     total_fail
        moveq   #1,d0
        jbsr    read_sector
        jeq     1b

        /* Parse the image name string (a0). */
        lea.l   image_name(pc),a1
        moveq   #0,d2
        moveq   #31,d1
2:      move.b  (a0)+,d0
        cmp.b   #'0',d0
        jne     1f
        addq.w  #1,d2
        moveq   #-1,d0                /* Disk number -> '\xff' */
1:      move.b  d0,(a1)+
        dbeq    d1,2b
        jne     total_fail            /* Name too long! */
        subq.w  #1,d2
        jne     total_fail            /* Exactly one substitution */

        /* All done, return the drive to original state. */
        jbsr    seek_0
        unlk    a6
        /*movem.l (sp)+,d0-d4/a0-a6*/
        rts

_set_lba:
        /* Create command sector. */
        lea.l   __set_lba(pc),a3
        jbsr    write_cmd
        jra     _check_status
__set_lba:
        move.b  #CMD_SET_LBA,(a2)+      /* Command */
        moveq   #4-1,d0
1:      move.b  #0xff,(a2)+             /* Param[4] */
        dbf     d0,1b
        rts

        /**************************
         * IN: a3 = cmd routine
         * Scratches a0-a2/d0-d4 */
write_cmd:
        /* Create command sector. */
        move.l  loc_mfm(a6),a2          /* a2 = buffer_start */
        lea     12(a2),a1               /* a1 = sync_start */
        move.w  #crc_table_off/4-1,d0
        moveq   #0,d1
1:      move.l  d1,(a2)+                /* Clear the whole mfm buffer */
        dbf     d0,1b
        move.l  a1,a2                   /* a2 = sync_start */
        moveq   #3-1,d0
1:      move.b  #0xa1,(a2)+             /* 3 * Sync */
        dbf     d0,1b
        move.b  #0x01,(a2)+             /* Named Sector */
        addq.l  #1,a2                   /* Sector #0 */
        lea     sig(pc),a0
        moveq   #8-1,d0
1:      move.b  (a0)+,(a2)+             /* Signature */
        dbf     d0,1b
        jsr     (a3)                    /* Call the command routine */
        move.l  a1,a0                   /* a0 = data to crc */
        moveq   #-1,d0                  /* d0.w = crc_in (0xffff) */
        move.w  #5+512,d1               /* d1.w = #bytes = header + data */
        move.l  loc_mfm(a6),a1
        lea.l   crc_table_off(a1),a1    /* a1 = crc_table */
        jbsr    crc16_ccitt
        move.b  d0,5+512+1(a0)          /* CRC.lo */
        lsr.w   #8,d0
        move.b  d0,5+512+0(a0)          /* CRC.hi */
        /* Convert to MFM */
        lea.l   12(a0),a2
        lea.l   -12(a0),a0
        move.w  #540/2,d0
        jbsr    bin2mfm
        /* Poke true Sync */
        moveq   #3-1,d0
1:      move.w  #0x4489,(a2)+
        dbf     d0,1b
        /* Perform the actual write. */
        move.w  #540,d0
        jra     write

        /**************************
         * IN: d0 = nr_words; a0 = buf
         * OUT: a0 = buf = mfm_start; a1 = mfm_end
         * Scratches: d0-d4 */
bin2mfm:
        /* First create space for clock bits. */
        move.w  d0,d3
        subq.w  #1,d3         /* d3 = nr_words - 1 */
        move.w  d3,d4         /* d4 = " */
        add.w   d0,d0         /* d0 = nr_bytes */
        lea.l   (a0,d0.w),a0  /* a0 = buf + nr_bytes */
        lea.l   (a0,d0.w),a1  /* a1 = buf + 2*nr_bytes */
1:      move.w  -(a0),d0
        moveq   #0,d1
        moveq   #16-1,d2
2:      roxr.w  #1,d0
        roxr.l  #2,d1
        dbf     d2,2b
        move.l  d1,-(a1)
        dbf     d4,1b
        /* Now compute clock bits. */
        move.l  #0xaaaaaaaa,d2
1:      move.l  (a1),d0       /* get a longword of data bits */
        move.l  d0,d1
        roxr.l  #1,d0         /* d0 = (X . data_bits) >> 1 -> X */
        rol.l   #1,d1         /* d1 = data_bits << 1 */
        or.l    d0,d1
        not.l   d1            /* clock[n] = data[n-1] NOR data[n] */
        and.l   d2,d1
        or.l    d1,(a1)+      /* OR the clock bits into the longword */
        dbf     d3,1b
        rts

        /**************************
         * Turn on drive motor, wait for DSKRDY, or 500ms to pass.
         * Scratches: d0-d1 */
motor_on:
        move.b  loc_drive(a6),d1
        ori.b   #0xF8,ciabprb(a5)
        andi.b  #0x7F,ciabprb(a5)
        and.b   d1,ciabprb(a5)
        move.w  #8000,d1        /* 8000 * 63us ~= 500ms */
1:      btst    #5,ciaapra(a5)
        jeq     2f
        jbsr    wait_vline
        dbf     d1,1b
2:      rts

        /**************************/
motors_off:
        ori.b   #0xF8,ciabprb(a5)
        andi.b  #0x87,ciabprb(a5)
        ori.b   #0x78,ciabprb(a5)
        rts

        /**************************
         * IN: d2.b = cyl
         * Scratches: d0-d3 */
seek_0:
        /* Find the current cylinder by counting steps out to cyl 0. */
        bset    #1,ciabprb(a5)  /* outwards */
        jra     2f
1:      jbsr    _step_one
2:      btst    #4,ciaapra(a5)
        jne     1b
        rts

        /**************************
         * OUT: a0 = d0 = da_status (NULL on failure), CC.Z set
         * Scratches: d1-d3/a1-a2 */
seek_da:
        bset    #2,ciabprb(a5)  /* side 0 */
        bclr    #1,ciabprb(a5)  /* inwards */
        moveq   #3-1,d4
1:      move.w  #259,d2         /* more than enough */
2:      jbsr    _step_one
        dbf     d2,2b
        jbsr    read_status
        jne     3f
        dbf     d4,1b
3:      rts

_step_one:
        moveq   #0,d0
        bclr    d0,ciabprb(a5)
        mulu.w  d0,d0
        bset    d0,ciabprb(a5)  /* step pulse */
        move.w  #18-1,d1        /* 18 * 63us ~= 1.1ms */
1:      jbsr    wait_vline
        dbf     d1,1b
        rts

        /**************************
         * Scratches: d0 */
wait_vline:
        move.b  vhposr(a4),d0
1:      cmp.b   vhposr(a4),d0
        jeq     1b
        rts

        /**************************
         * OUT: a0 = d0 = da_status (NULL on failure), CC.Z set
         * Scratches: d1-d3/a1-a2 */
read_status:
        moveq   #3+1,d0
        move.l  d0,-(sp)        /* (sp) = retry counter */
_read_status_retry:
        sub.l   a0,a0           /* Return NULL if no match */
        subq.l  #1,(sp)
        jeq     _read_status_out
        moveq   #0,d0
        jbsr    read_sector
        jeq     _read_status_retry
        lea     sig(pc),a1
        moveq   #8-1,d0
1:      cmpm.b  (a0)+,(a1)+     /* Check the signature 8 bytes */
        jne     _read_status_retry
        dbf     d0,1b
        subq.l  #8,a0
_read_status_out:
        addq.l  #4,sp
        move.l  a0,d0
        rts

        /**************************
         * IN: d0 = sector #
         * OUT: a0 = d0 = data[512], or NULL ; CC.Z set appropriately
         * Scratches: d1-d3/a1-a2 */
read_sector:
        move.l  d0,-(sp)        /* 2(sp) = sector # */
        moveq   #19+1,d0
        move.w  d0,(sp)         /* (sp) = retry counter */
_retry_read_sector:
        sub.l   a2,a2
        subq.w  #1,(sp)
        jeq     _read_sector_out
        /* Read an IDAM or DAM. */
        moveq   #8,d0
        move.l  loc_mfm(a6),a0
        move.l  a0,a2
        jbsr    read
        /* Check the header we read. */
        move.l  a2,a0
        moveq   #3-1,d0
1:      cmp.b   #0xa1,(a0)+     /* Sync? */
        dbne    d0,1b
        cmp.b   #0xfe,-(a0)     /* IDAM? */
        jne     _retry_read_sector
        move.w  2(sp),d0
        cmp.b   3(a0),d0        /* Sector? */
        jne     _retry_read_sector
        /* Okay, we're in the right place: now read the DAM. */
        move.w  #4+512+2+2,d0
        move.l  a2,a0
        move.l  #0xa1a1a1a1,(a0)+
        jbsr    read
        /* Check the header we read. */
        move.l  a2,a0
        moveq   #4+3-1,d0
1:      cmp.b   #0xa1,(a0)+     /* Sync? */
        dbne    d0,1b
        cmp.b   #0xfb,-1(a0)    /* DAM? */
        jne     _retry_read_sector
        /* Check CRC. */
        move.l  a0,a2
        subq.l  #4,a0
        move.l  loc_mfm(a6),a1
        lea.l   crc_table_off(a1),a1
        moveq   #-1,d0
        move.w  #4+512+2,d1
        jbsr    crc16_ccitt     /* Check the sector CRC */
        jne     _retry_read_sector
_read_sector_out:
        addq.l  #4,sp
        move.l  a2,a0
        move.l  a0,d0
        rts

        /**************************
         * IN: d0 = # words, a0 = mfm = dest
         *  Scratches: d0-d3/a0-a1 */
read:   move.w  d0,d3
        /* Scratch the input buffer in case read fails. */
        moveq   #0,d1
        move.l  d1,(a0)
        /* Read MFM. */
        move.l  #0x27F00,intreq(a4) /* clear intreq & adkcon */
        move.w  #0x9500,adkcon(a4)  /* adkcon -- MFM, wordsync */
        move.w  #0x4489,dsksync(a4) /* sync 4489 */
        or.w    #0x8000,d0
        jbsr    _do_dma
        /* Decode MFM. */
        move.l  a0,a1           /* a0 = a1 = mfm_buf */
        lsr.w   #1,d3
        subq.w  #1,d3           /* d3 = (nr_words/2)-1 */
1:      move.l  (a0)+,d0
        moveq   #16-1,d2
2:      roxl.l  #2,d0
        roxl.w  #1,d1
        dbf     d2,2b
        move.w  d1,(a1)+
        dbf     d3,1b
        rts

        /**************************
         * IN: a0 = mfm buffer; d0 = # words
         * Scratches: d0-d1 */
write:  move.l  #0x27F00,intreq(a4) /* clear intreq & adkcon */
        move.w  #0x9100,adkcon(a4)  /* adkcon -- MFM, no wordsync */
        or.w    #0xc000,d0
_do_dma:
        move.l  a0,dskpt(a4)        /* dskpt */
        move.w  #0x8210,dmacon(a4)  /* dmacon -- enable disk dma */
        move.w  d0,dsklen(a4)
        move.w  d0,dsklen(a4)
        move.w  #800,d1             /* 800 * 63us ~= 50ms */
1:      jbsr    wait_vline
        subq.w  #1,d1
        jeq     1f
        btst    #1,intreqr+1(a4)    /* intreqr -- disk dma done? */
        jeq     1b
1:      move.w  #0x4000,dsklen(a4)  /* dsklen -- no more dma */
        rts

sig:    .asciz  "HxCFEDA"
image_name:
        dc.l 0,0,0,0,0,0,0,0

#include "../shared/crc16_ccitt.S"

#if 0
dbg_putch:
        move.w  #0x1e,0x32(a4)  /* serper -> 115200 baud */
1:      move.w  0x18(a4),d1
        and.w   #0x2000,d1      /* serdatr -> busy? */
        jeq     1b
        and.w   #0xff,d0
        or.w    #0x100,d0
        move.w  d0,0x30(a4)     /* serdat */
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
#endif
