
        /* Find boot drive */
        jbsr    CheckDrives

        /* Patch the first loader to use the boot drive. */
        or.w    #0x7000,d0
        move.w  d0,0xbda(a3)            /* moveq #<drive>,d0 */
        move.w  #0x4e71,0xbdc(a3)       /* nop */

        move.w  #0x4e91,0x29c(a3)       /* jmp (a1) -> jsr (a1) */

        lea.l   0xbc6(a3),a0
        move.w  #0x868,d0               /* ~3ms */
        jbsr    rnc_speed_patch

        jra     disable_caches

#include "shared_patch.S"
#include "../shared/disable_caches.S"
#include "../shared/boot_drive_detect.S"
