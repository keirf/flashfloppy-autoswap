/*
 * amigados_autoswap_entry.S
 *
 * Stub to load AmigaDOS Auto-Swap patches.
 *
 * Written & released by Keir Fraser <keir.xen@gmail.com>
 */

/* Exec Library Vector Offsets */
#define EXEC_Forbid   -0x84
#define EXEC_FindTask -0x126
#define EXEC_GetMsg   -0x174
#define EXEC_ReplyMsg -0x17a
#define EXEC_WaitPort -0x180
#define EXEC_OpenLibrary -0x198
#define EXEC_CloseLibrary -0x19e

/* Offsets into DOS Process structure (extends Exec Task) */
#define pr_MsgPort   0x5c
#define pr_CLI       0xac

        .text
start:
        move.l  4,a6

        moveq   #0,d0
        move.l  d0,-(sp)          /* No WB startup msg yet */
        
        /* Find our Process structure and determine how we were started. */
        sub.l   a1,a1
        jsr     EXEC_FindTask(a6) /* FindTask(NULL) */
        move.l  d0,a4
        tst.l   pr_CLI(a4)        /* Running from CLI? */
        jne     1f

        /* Started from Workbench: wait for start message */
        lea     pr_MsgPort(a4),a0
        jsr     EXEC_WaitPort(a6)
        lea     pr_MsgPort(a4),a0
        jsr     EXEC_GetMsg(a6)
        move.l  d0,(sp)           /* Save the startup msg */
1:
        /* Open dos.library. */
        lea     .dos(pc),a1
        moveq   #0,d0
        jsr     EXEC_OpenLibrary(a6)
        move.l  d0,-(sp)          /* Save DOSBase */
        
        /* Find the main patch hunk. */
        lea.l   start-4(pc),a0
        move.l  (a0),a0
        add.l   a0,a0
        add.l   a0,a0
        addq.l  #4,a0

        /* Execute the main patch. */
        move.l  (sp),a1           /* a1 = DOSBase */
        jsr     (a0)

        /* Restore registers, save return code. */
        move.l  4,a6              /* a6 = SysBase */
        move.l  (sp),a1           /* a1 = DOSBase */
        move.l  d0,(sp)           /* save return code */
        jne     .fail             /* failure? */

        /* Success: Unhook the main patch, leaving it resident. */
        lea.l   start-4(pc),a0
        clr.l   (a0)
2:
        /* Workbench only: Return the startup message to our parent */
        move.l  4(sp),d0
        jeq     1f
        move.l  d0,a1             /* a1 = workbench msg */
        jsr     EXEC_Forbid(a6)
        jsr     EXEC_ReplyMsg(a6)
1:
        /* Set return code, fix up stack, and return. */
        move.l  (sp)+,d0          /* d0 = return code */
        jeq     1f
        moveq   #10,d0        /* high enough to fail the startup-sequence */
1:
        addq.l  #4,sp             /* skip WB msg */
        rts

.fail:
        /* Failure: Close dos.library. */
        jsr     EXEC_CloseLibrary(a6)
        jbra    2b

.dos:   .asciz  "dos.library"
