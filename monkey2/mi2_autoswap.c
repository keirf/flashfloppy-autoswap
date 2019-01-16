
/* df0:savegame.000 etc */
/* Monkey2 Disk 1:monkey2.000 etc */
/* Monkey2 Disk 1:amiga1.ims etc */

#define VOLNAME_PREFIX "Monkey2 "

#include "../shared/amigados_autoswap.c"

static int disknr_from_filename(const char *name)
{
    int disknr = 1;
    char *p;

    if ((p = strstr(name, "savegame.")) != NULL) {
        disknr = 0;
    } else if ((p = strstr(name, "monkey2.")) != NULL) {
        disknr = atoi(p + 8) ?: 1;
    } else if ((p = strstr(name, "amiga")) != NULL) {
        disknr = atoi(p + 5);
    }

    return disknr;
}

static int disknr_from_volname(const char *volname)
{
    int disknr = -1;
    char *p;

    if ((p = strstr(volname, "Disk ")) != NULL) {
        disknr = atoi(p + 5);
    } else if ((p = strstr(volname, "Save")) != NULL) {
        disknr = 0;
    }

    return disknr;
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
