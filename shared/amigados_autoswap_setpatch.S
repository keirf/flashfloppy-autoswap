/*
 * amigados_autoswap_setpatch.S
 *
 * Tiny stub to load AmigaDOS Auto-Swap patches. Startup from CLI only.
 *
 * Written & released by Keir Fraser <keir.xen@gmail.com>
 */

/* Exec Library Vector Offsets */
#define EXEC_OpenLibrary -0x198
#define EXEC_CloseLibrary -0x19e

/* DOS Library Vector Offsets */
#define DOS_LoadSeg -0x96

        .text
start:
        /* Open dos.library. */
        move.l  4,a6
        lea     .dos(pc),a1
        moveq   #0,d0
        jsr     EXEC_OpenLibrary(a6)
        move.l  d0,-(sp)
        
        /* Load the main patch binary. */
        move.l  d0,a6
        move.l  #.patch,d1
        jsr     DOS_LoadSeg(a6)
        lsl.l   #2,d0
        jeq     .fail

        /* Execute its initialiser, then leave it resident. */
        add.l   #4,d0
        move.l  d0,a0
        move.l  (sp),a1 /* a1 = DOSBase */
        jsr     (a0)
        tst.l   d0
        jne     .fail

        /* Success - keep handle on dos.library */
        lea.l   4(sp),sp
        rts

.fail:
        /* Close dos.library. */
        move.l  (sp)+,a1
        move.l  4,a6
        jsr     EXEC_CloseLibrary(a6)

        /* High enough error return to fail the startup-sequence. */
        moveq   #10,d0
        rts

.dos:   .asciz  "dos.library"
