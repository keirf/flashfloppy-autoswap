/*
 * amigados_autoswap_entry.S
 *
 * AmigaDOS Auto-Swap patch entry point. Startup from *_setpatch stub only.
 *
 * Written & released by Keir Fraser <keir.xen@gmail.com>
 */

/* Exec Library Vector Offsets */
#define EXEC_OpenLibrary -0x198
#define EXEC_CloseLibrary -0x19e

        .text
start:
        move.l  4,a6
        move.l  a6,_SysBase
        move.l  a1,_DOSBase

        jbra    _main
        
        .globl _SysBase, _DOSBase
        .align  4
_SysBase:
        dc.l    0
_DOSBase:
        dc.l    0
