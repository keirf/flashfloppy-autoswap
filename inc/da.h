/*
 * da.h
 * 
 * Structure definitions for Direct Access protocol.
 * 
 * Written & released by Keir Fraser <keir.xen@gmail.com>
 * 
 * This is free and unencumbered software released into the public domain.
 * See the file COPYING for more details, or visit <http://unlicense.org>.
 */

#define CMD_NOP          0
#define CMD_SET_LBA      1 /* p[0-3] = LBA (little endian) */
#define CMD_SET_CYL      2 /* p[0] = drive A cyl, p[1] = drive B cyl */
#define CMD_SET_RPM      3 /* p[0] = 0x00 -> default, 0xFF -> 300 RPM */
#define CMD_SELECT_IMAGE 4 /* p[0-1] = slot # (little endian) */
#define CMD_SELECT_NAME 10 /* p[] = name (c string) */

/* Direct-Access Mode: Returned in sector 0 of direct-access track. */
struct da_status_sector {
    char sig[8];
    char fw_ver[12];
    uint32_t lba_base;
    uint8_t cmd_cnt;
    uint8_t read_cnt;
    uint8_t write_cnt;
    uint8_t last_cmd_status;
    uint8_t write_locked;
    uint8_t keys_status;
    uint8_t sd_status;
    uint8_t SD_WP;
    uint8_t SD_CD;
    uint8_t nr_sec;
    uint16_t current_index;
};

/* Direct-Access Mode: Sent to us in sector 0 of direct-access track. */
struct da_cmd_sector {
    char sig[8];
    uint8_t cmd;
    uint8_t param[8];
};

/*
 * Local variables:
 * mode: C
 * c-file-style: "Linux"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
