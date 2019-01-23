/*
 * amigados_autoswap.c
 * 
 * FlashFloppy Auto-Swap support for AmigaDOS games (SCUMM in particular).
 * 
 * Written & released by Keir Fraser <keir.xen@gmail.com>
 * 
 * This is free and unencumbered software released into the public domain.
 * See the file COPYING for more details, or visit <http://unlicense.org>.
 */

#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/intuition.h>
#include <intuition/intuition.h>

#include <string.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

#include "inc/types.h"
#include "inc/amiga_hw.h"
#include "inc/crc.h"
#include "inc/da.h"

#if __GNUC__ < 3
#define attribute_used __attribute__((unused))
#define likely(x) x
#define unlikely(x) x
#else
#define attribute_used __attribute__((used))
#define likely(x) __builtin_expect((x),1)
#define unlikely(x) __builtin_expect((x),0)
#endif

#define LONG_MAX 0x7fffffffl

struct IntuitionBase *IntuitionBase;

#define TRACK_BUFFER_SIZE 540
static uint16_t *track_buffer;

static struct da_cmd_sector da_cmd = { "HxCFEDA" };

static volatile struct amiga_custom * const cust =
    (struct amiga_custom *)0xdff000;
static volatile struct amiga_cia * const ciaa =
    (struct amiga_cia *)0x0bfe001;
static volatile struct amiga_cia * const ciab =
    (struct amiga_cia *)0x0bfd000;

static char image_prefix[128], *image_suffix;
static char ff_unit_name[4] = "dfx:";
static uint8_t ff_unit;
static uint8_t ciabprb;

#ifdef DEBUG

#define BAUD 115200
static void ser_putc(uint8_t c)
{
    cust->serper = (35795460/BAUD + 5) / 10 - 1;
    while (!(cust->serdatr & SERDATR_TBE))
        continue;
    cust->serdat = c | 0x100;
}

static void dbg(char *format, ...)
{
    static char buf[1024];
    va_list ap;
    char *p;

    va_start(ap, format);
    vsnprintf(buf, sizeof(buf), format, ap);
    va_end(ap);

    for (p = buf; *p; p++) {
        if (*p == '\n')
            ser_putc('\r');
        ser_putc(*p);
    }
}

#else

#define dbg(_f, ...) ((void)0)

#endif

static void delay_us(unsigned int us)
{
    uint8_t _v, v = *(volatile uint8_t *)&cust->vhposr;
    us >>= 6; /* div 64 */
    us += 2; /* loss of precision, and first hline may be partial */
    do {
        do {
            _v = *(volatile uint8_t *)&cust->vhposr;
        } while (_v == v);
        v = _v;
    } while (--us);
}

static void delay_ms(unsigned int ms)
{
    while (ms--)
        delay_us(1000);
}

static void drive_deselect(void)
{
    ciab->prb = ciabprb |= 0xf9; /* motor-off, deselect all */
}

/* Select @drv and set motor on or off. */
static void drive_select(unsigned int drv, int on)
{
    Forbid();
    drive_deselect(); /* motor-off, deselect all */
    if (on)
        ciab->prb = ciabprb &= ~CIABPRB_MTR; /* motor-on */
    ciab->prb = ciabprb &= ~(CIABPRB_SEL0 << drv); /* select drv */
    Permit();
}

static void grab_ciabprb(void)
{
    /* Re-grabs CIABPRB value, ensuring motor latch is correct. */
    ciab->prb = ciabprb | 0x78;
    ciab->prb = ciabprb;
}

static bool_t is_ff_unit(int drive)
{
    bool_t is_ff;
    uint8_t ciaapra;

    drive_select(drive, 1);
    delay_us(10);

    /* We let the motor spin down and then re-enable the motor and 
     * almost immediately check if the drive is READY. A real mechanical 
     * drive will need to time to spin back up. */
    ciaapra = ~ciaa->pra;
    is_ff = (ciaapra & CIAAPRA_RDY) && !(ciaapra & CIAAPRA_CHNG);

    drive_select(drive, 0);
    drive_deselect();

    return is_ff;
}

static int get_ff_unit(void)
{
    int i;

    /* Floppy motors off. */
    Forbid();
    ciab->prb = 0xff;
    ciab->prb = 0x87;
    ciab->prb = ciabprb = 0xff;
    Permit();

    delay_ms(100); /* give all motors time to spin down */

    for (i = 0; i < 4; i++)
        if (is_ff_unit(i))
            return i;

    return -1;
}

static void seek(uint8_t t)
{
#define STEP_DELAY 1100
    unsigned int steps = 0, i;

    ciabprb |= CIABPRB_DIR; /* outward */
    delay_us(STEP_DELAY);
    for (;;) {
        Forbid();
        grab_ciabprb();
        if (~ciaa->pra & CIAAPRA_TK0) {
            Permit();
            break;
        }
        ciab->prb = ciabprb & ~CIABPRB_STEP;
        ciab->prb = ciabprb;
        Permit();
        delay_us(STEP_DELAY);
        if (steps++ >= 1024) {
            dbg("seek %d - no track 0???? %02x\n", t, ciab->prb);
            return;
        }
    }

    ciabprb &= ~CIABPRB_DIR; /* inward */
    for (i = 0; i < t; i++) {
        Forbid();
        grab_ciabprb();
        ciab->prb = ciabprb & ~CIABPRB_STEP;
        ciab->prb = ciabprb;
        Permit();
        delay_us(STEP_DELAY);
    }
};

static int disk_wait_dma(void)
{
    unsigned int i;
    uint8_t _v, v = *(volatile uint8_t *)&cust->vhposr;
    for (i = 0; i < 1000; i++) {
        if (cust->intreqr & INT_DSKBLK) /* dsk-blk-done? */
            break;
        /* wait vline */
        do {
            _v = *(volatile uint8_t *)&cust->vhposr;
        } while (_v == v);
        v = _v;
    }
    cust->dsklen = 0x4000; /* no more dma */
    return (i < 1000) ? 0 : -1;
}

static void readtrack(uint16_t *track, uint16_t size)
{
    /* Scratch the buffer */
    memset(track, 0, 16);

    grab_ciabprb();

    cust->dskpt.p = track;
    cust->adkcon = 0x7f00; /* clear disk flags */
    cust->intreq = INT_DSKBLK; /* clear dsk-blk-done */
    cust->adkcon = 0x9500; /* MFM, wordsync */
    cust->dsksync = 0x4489; /* sync 4489 */

    cust->dsklen = size | 0x8000;
    cust->dsklen = size | 0x8000;

    disk_wait_dma();
}

static void writetrack(uint16_t *track, uint16_t size)
{
    Forbid();
    grab_ciabprb();

    cust->dskpt.p = track;
    cust->adkcon = 0x7f00; /* clear disk flags */
    cust->intreq = INT_DSKBLK; /* clear dsk-blk-done */
    cust->adkcon = 0xb100; /* MFM, no wordsync, precomp */

    cust->dsklen = size | 0xc000;
    cust->dsklen = size | 0xc000;

    disk_wait_dma();
    Permit();
}

static void bin2mfm(uint8_t *dat, unsigned int nr_bytes)
{
    unsigned int nr_words = (nr_bytes + 1) >> 1;
    uint32_t dummy;

    asm volatile (
        /* First create space for clock bits. */
        "    move.w %2,d3\n"
        "1:  move.w -(%0),d0\n"
        "    moveq  #0,d1\n"
        "    moveq  #16-1,d2\n"
        "2:  roxr.w #1,d0\n"
        "    roxr.l #2,d1\n"
        "    dbf    d2,2b\n"
        "    move.l d1,-(%1)\n"
        "    dbf    %2,1b\n"
        /* Now compute clock bits. */
        "    move.l #0xaaaaaaaa,d2\n"
        "1:  move.l (%0),d0\n"  /* get a longword of data bits */
        "    move.l d0,d1\n"
        "    roxr.l #1,d0\n"    /* d0 = (X . data_bits) >> 1 -> X */
        "    rol.l  #1,d1\n"    /* d1 = data_bits << 1 */
        "    or.l   d0,d1\n"
        "    not.l  d1\n"       /* clock[n] = data[n-1] NOR data[n] */
        "    and.l  d2,d1\n"
        "    or.l   d1,(%0)+\n" /* OR the clock bits into the longword */
        "    dbf    d3,1b\n"
        : "=a" (dummy), "=a" (dummy), "=d" (dummy)
        : "0" (&dat[nr_words<<1]), "1" (&dat[nr_words<<2]), "2" (nr_words-1)
        : "d0", "d1", "d2", "d3", "memory");
}

static uint8_t *mfm2bin(uint16_t *mfm, unsigned int nr_words)
{
    uint8_t *dat = (uint8_t *)mfm;
    uint32_t dummy;

    asm volatile (
        "1:  move.l (%0)+,d0\n"
        "    moveq  #16-1,d2\n"
        "2:  roxl.l #2,d0\n"
        "    roxl.w #1,d1\n"
        "    dbf    d2,2b\n"
        "    move.w d1,(%1)+\n"
        "    dbf    %2,1b\n"
        : "=a" (dummy), "=a" (dummy), "=d" (dummy)
        : "0" (mfm), "1" (mfm), "2" ((nr_words>>1)-1)
        : "d0", "d1", "d2", "memory");

    return dat;
}

static void write_sector(uint8_t sec, uint8_t *data, unsigned int data_len)
{
    const uint8_t header[4] = { 0xa1, 0xa1, 0xa1, 0x01 };
    uint16_t i, crc;
    uint8_t *dat = (uint8_t *)track_buffer, *p = dat;

    /* Pre-sync */
    for (i = 0; i < 12; i++)
        *p++ = 0x00;
    /* Header */
    memcpy(p, header, 4);
    p += 4;
    *p++ = sec;
    /* Data */
    memcpy(p, data, data_len);
    memset(p+data_len, 0, 512-data_len);
    p += 512;
    /* CRC */
    crc = crc16_ccitt(&dat[12], 5+512, 0xffff);
    memcpy(p, &crc, 2);
    p += 2;
    /* Post-amble */
    for (i = 0; i < 4; i++)
        *p++ = 0x4e;

    /* Convert data bytes to MFM words. */
    bin2mfm(dat, p - dat);

    /* Poke in proper sync words. */
    for (i = 0; i < 3; i++)
        track_buffer[12+i] = 0x4489;

    writetrack(track_buffer, p - dat);
}

static void write_cmd(void)
{
    write_sector(0, (uint8_t *)&da_cmd, sizeof(da_cmd));
}

static void *read_sector(uint8_t sec, bool_t reseek)
{
#define IDAM_RD_SIZE 8
#define DAM_RD_SIZE  (4+512+2+2)
    const uint8_t header[4] = { 0xa1, 0xa1, 0xa1, 0xfb };
    uint8_t *idam, *dam;
    uint16_t i, crc;
    uint8_t retry[3];

    for (retry[2] = 0; retry[2] < 3; retry[2]++) {

        for (retry[1] = 0; retry[1] < 5; retry[1]++) {

            for (retry[0] = 0; retry[0] < 20; retry[0]++) {
                Forbid();
                /* Read an IDAM. */
                readtrack(track_buffer, IDAM_RD_SIZE);
                idam = mfm2bin(track_buffer, IDAM_RD_SIZE);

                /* Skip sync marks. */
                for (i = 0; i < 3; i++)
                    if (idam[i] != 0xa1)
                        break;

                /* Is it IDAM for the requested sector? */
                if (idam[i] == 0xfe) {
                    retry[0] = 0; /* reset retry counter */
                    if (idam[i+3] == sec)
                        break; /* we're done! */
                }
                Permit();
            }

            readtrack(track_buffer, DAM_RD_SIZE);
            Permit();
            dam = mfm2bin(track_buffer, DAM_RD_SIZE);

            /* Skip sync marks. */
            for (i = 0; i < 3; i++)
                if (dam[i] != 0xa1)
                    break;

            /* Is it a DAM? */
            if (dam[i] != 0xfb)
                continue;

            i++;

            /* CRC: Sync words + DAM. */
            crc = crc16_ccitt(header, 4, 0xffff);
            crc = crc16_ccitt(&dam[i], 512+2, crc);

            if (!crc)
                goto found;
        }

        /* After 5 attempts, re-seek to track. */
        if (reseek)
            seek(255);
    }

    dbg("read_sector: failed\n");
    return NULL;

found:
    memcpy(dam, dam+i, 512);
    return dam;
}

static struct da_status_sector *read_status(bool_t reseek)
{
    struct da_status_sector *dass;
    int retries = 0;

    do {
        dass = read_sector(0, reseek);
        if (!dass)
            return NULL;
        if (!strcmp(da_cmd.sig, dass->sig))
            return dass;
    } while (retries++ < 5);

    return NULL;
}

static LONG send_dos_msg(LONG type, LONG arg)
{
    struct Process *tsk = (struct Process *)FindTask(NULL);
    struct StandardPacket *pk = (struct StandardPacket *)track_buffer;

    memset(pk, 0, sizeof(*pk));

    pk->sp_Msg.mn_Node.ln_Name = (char *)&pk->sp_Pkt;
    pk->sp_Pkt.dp_Link = &pk->sp_Msg;
    pk->sp_Pkt.dp_Port = &tsk->pr_MsgPort;
    pk->sp_Pkt.dp_Type = type;
    pk->sp_Pkt.dp_Arg1 = arg;

    PutMsg(DeviceProc((STRPTR)ff_unit_name), (struct Message *)pk);
    WaitPort(&tsk->pr_MsgPort);
    GetMsg(&tsk->pr_MsgPort);

    return pk->sp_Pkt.dp_Res1;
}

static void disk_busy(bool_t lock)
{
    if (lock)
        send_dos_msg(ACTION_FLUSH, 0);
    send_dos_msg(ACTION_INHIBIT, lock ? DOSTRUE : DOSFALSE);
}

static char *current_volume(void)
{
    struct DeviceList *dl;
    char *bname, *cname;
    uint8_t len;
    LONG res;

    res = send_dos_msg(ACTION_CURRENT_VOLUME, 0);
    dl = (struct DeviceList *)(res << 2);
    if (dl == NULL)
        return NULL;

    bname = (char *)(dl->dl_Name << 2);
    cname = (char *)track_buffer;
    len = bname[0];
    memcpy(cname, &bname[1], len);
    cname[len] = '\0';
    return cname;
}

static bool_t ff_unit_lock(void)
{
    disk_busy(TRUE);
    drive_select(ff_unit, 1);
    ciabprb |= CIABPRB_SIDE; /* side 0 */
    seek(255);
    if (read_status(TRUE) == NULL) {
        seek(0);
        disk_busy(FALSE);
        return FALSE;
    }
    return TRUE;
}

static void ff_unit_unlock(void)
{
    uint8_t ciaapra;
    int i;

    da_cmd.cmd = CMD_SET_CYL;
    da_cmd.param[0] = da_cmd.param[1] = 0;
    write_cmd();

    /* Wait for command to be enacted. */
    delay_ms(100);

    /* Wait for track 0 and disk-change to deassert. Step outwards to help 
     * progress. */
    ciabprb |= CIABPRB_DIR; /* outward */
    i = 0;
    do {
        if (i++ >= 500)
            break; /* 1-second timeout */
        delay_ms(2);
        Forbid();
        grab_ciabprb();
        ciaapra = ~ciaa->pra;
        ciab->prb = ciabprb & ~CIABPRB_STEP;
        ciab->prb = ciabprb;
        Permit();
    } while (!(ciaapra & CIAAPRA_TK0) || (ciaapra & CIAAPRA_CHNG));

    /* Tell DOS to mount the new disk. */
    disk_busy(FALSE);

    /* Wait for the volume to be mounted. */
    for (i = 0; i < 50; i++) {
        if (current_volume())
            break;
        delay_ms(100);
    }
}

static int disknr_from_filename(const char *name);
static int disknr_from_volname(const char *volname);

static bool_t disk_change(int disknr)
{
    static volatile int nest = 0;
    struct da_cmd_sector *dac;
    char *volname;
    int cur_disknr, nr;

    Forbid();
    if (nest++) {
        nest--;
        Permit();
        dbg("Nested Disk Change!\n");
        return FALSE;
    }
    Permit();

    dbg("Need=%u ", disknr);

    for (;;) {

        if ((volname = current_volume()) == NULL) {
            dbg("No Volume!\n");
            goto fail;
        }

        cur_disknr = disknr_from_volname(volname);
        dbg("Cur=%u ", cur_disknr);
        if (cur_disknr == -1) {
            dbg("Unknown Vol!\n");
            goto fail;
        }
        if (cur_disknr == disknr)
            break;

        if (!ff_unit_lock()) {
            dbg("Bad FDC!\n");
            goto fail;
        }

        dac = (struct da_cmd_sector *)((uint8_t *)track_buffer + 128);
        da_cmd.cmd = CMD_SELECT_NAME;
        memcpy(dac, &da_cmd, sizeof(da_cmd));
        if (disknr == 0) {
            nr = sprintf((char *)dac->param, "%sSave%s",
                         image_prefix, image_suffix);
        } else {
            nr = sprintf((char *)dac->param, "%s%02u%s",
                         image_prefix, disknr, image_suffix);
        }
        write_sector(0, (uint8_t *)dac, 9 + nr);

        ff_unit_unlock();
    }

    nest = 0;
    return TRUE;

fail:
    nest = 0;
    return FALSE;
}

#define LIBHOOK(name)                           \
void hook_##name(void);                         \
asm (                                           \
"    .text; .align 2                \n"         \
"_hook_"#name":                     \n"         \
"    movem.l d1/a0-a1,-(sp)         \n"         \
"    movem.l d1-d2,-(sp)            \n"         \
"    jbsr    _c_"#name"             \n"         \
"    lea.l   8(sp),sp               \n"         \
"    movem.l (sp)+,d1/a0-a1         \n"         \
"    moveq   #-1,d0                 \n"         \
"    dc.w    0x4ef9,0x0,0x0         \n"         \
)

LIBHOOK(Open);
void c_Open(uint32_t d1, uint32_t d2) attribute_used;
void c_Open(uint32_t d1, uint32_t d2)
{
    char *p, *name = (char *)d1;
    int disknr;

    dbg("Open [%s] -> ", name);

    if (strstr(name, "nil:"))
        goto out;

    disknr = disknr_from_filename(name);

    if (!disk_change(disknr))
        goto out;

    if (strncmp(name, "df", 2)) {
        if (!(p = strchr(name, ':')))
            return;
        strcpy(name + 4, p + 1);
    }
    strncpy(name, ff_unit_name, 4);

out:
    dbg("[%s]\n", name);
}

void hook_DisplayAlert(void);
asm (
"    .text; .align 2                \n"
"_hook_DisplayAlert:                \n"
"    movem.l d0-d1/a0-a1,-(sp)      \n"
"    movem.l d0-d1/a0,-(sp)         \n"
"    jbsr    _c_DisplayAlert        \n"
"    lea.l   12(sp),sp              \n"
"    tst.l   d0                     \n"
"    jne     1f                     \n"
"    movem.l (sp)+,d0-d1/a0-a1      \n"
"    dc.w    0x4ef9,0x0,0x0         \n"
"1:  lea.l   4(sp),sp               \n"
"    movem.l (sp)+,d1/a0-a1         \n"
"    rts                            \n"
);

int c_DisplayAlert(uint32_t d0, uint32_t d1, uint32_t a0) attribute_used;
int c_DisplayAlert(uint32_t d0, uint32_t d1, uint32_t a0)
{
    char *p, *line = (char *)a0;
    int disknr;

    if (d0 & DEADEND_ALERT)
        return 0;

    dbg("DisplayAlert:\n");

    for (;;) { 
        line += 3;
        dbg("  \"%s\"\n", line);
        if ((p = strstr(line, VOLNAME_PREFIX)) != NULL) {
            disknr = disknr_from_volname(p);
            if (disknr >= 0) {
                if (disk_change(disknr)) {
                    dbg("-> Disk Swapped\n");
                    return 1;
                } else {
                    dbg("-> Disk Swap Failed!\n");
                }
            }
        }
        line += strlen(line);
        if (!line[1])
            break;
        line += 2;
    }

    dbg("-> No Action\n");
    return 0;
}

#if 0
static void test(void)
{
    char name[32];
    BPTR h;
    int i;

    for (i = 1; i < 11; i++) {
        sprintf(name, "FakeVol:monkey2.%03u", i);
        dbg("Open(\"%s\")\n", name);
        h = Open((STRPTR)name, MODE_OLDFILE);
        dbg("Returns %08x\n", h);
        if (h)
            Close(h);
    }
}
#endif

int main(void)
{
    struct Library *dos = (struct Library *)DOSBase;
    uint16_t *p;
    uint32_t target;
    char *s, *volname;
    struct da_status_sector *dass;
    int retries;

    dbg("** AutoSwap **\n");

    /* Allocate disk buffer. */
    track_buffer = AllocMem(2 * TRACK_BUFFER_SIZE, MEMF_CHIP);
    if (!track_buffer)
        goto fail;

    /* Get the FlashFloppy drive number. */
    ff_unit = get_ff_unit();
    if (ff_unit < 0)
        goto free_and_fail;
    ff_unit_name[2] = ff_unit + '0';
    dbg("Drive %s\n", ff_unit_name);

    /* Get the image-name pattern. */
    if (!ff_unit_lock())
        goto free_and_fail;
    /* Set LBA to special value 0xffffffff. */
    retries = 0;
    do {
        da_cmd.cmd = CMD_SET_LBA;
        memset(da_cmd.param, 0xff, 4);
        write_cmd();
        if (!(dass = read_status(FALSE)))
            goto unlock_and_fail;
    } while ((dass->lba_base != ~0u) && (retries++ < 3));
    /* Read the special volume-name sector. */
    if ((retries >= 3) || !(volname = read_sector(1, FALSE)))
        goto unlock_and_fail;
    snprintf(image_prefix, sizeof(image_prefix), volname);
    if (!(s = strstr(image_prefix, "01")))
        goto unlock_and_fail;
    /* Extract the image-name pattern. */
    dbg("Volume \"%s\" -> ", image_prefix);
    *s = '\0';
    image_suffix = s+2;
    dbg("\"%sxx%s\"\n", image_prefix, image_suffix);
    ff_unit_unlock();

    /* dos.library Open: 
     * <v36: moveq #-1,d0 (70 ff); bra.w +68 (60 00 00 68) 
     * >=v36: jmp.l abs32 (4e f9 xx xx xx xx) */
    if (dos->lib_Version < 36) {
        p = (uint16_t *)dos - 0xd;
        target = (uint32_t)p + *p;
        p = (uint16_t *)hook_Open;
        while (*p++ != 0x4ef9)
            continue;
        *p++ = target >> 16;
        *p++ = target;
        p = (uint16_t *)dos - 0xf;
        target = (uint32_t)hook_Open;
        Forbid();
        *p++ = 0x4ef9;
        *p++ = target >> 16;
        *p++ = target;
        Permit();
    } else {
        Forbid();
        target = (uint32_t)SetFunction((struct Library *)DOSBase, -0x1e,
                                       (APTR)hook_Open);
        p = (uint16_t *)hook_Open;
        while (*p++ != 0x4ef9)
            continue;
        *p++ = target >> 16;
        *p++ = target;
        Permit();
    }

    /* Hook DOS Alerts. */
    IntuitionBase = (struct IntuitionBase *)
        OpenLibrary((STRPTR)"intuition.library", 0);
    Forbid();
    target = (uint32_t)SetFunction((struct Library *)IntuitionBase, -0x5a,
                                   (APTR)hook_DisplayAlert);
    p = (uint16_t *)hook_DisplayAlert;
    while (*p++ != 0x4ef9)
        continue;
    *p++ = target >> 16;
    *p++ = target;
    Permit();

    /* Success. */
    return 0;

unlock_and_fail:
    ff_unit_unlock();
free_and_fail:
    FreeMem(track_buffer, 2 * TRACK_BUFFER_SIZE);
fail:
    return 1;
}

/*
 * Local variables:
 * mode: C
 * c-file-style: "Linux"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
