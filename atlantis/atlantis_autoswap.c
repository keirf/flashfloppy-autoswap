
/* df0:savegame.000 etc */
/* atlantis1:atlantis.000 etc */
/* atlantis1:amiga1.ims etc */

#define VOLNAME_PREFIX "atlantis"

#include "../shared/amigados_autoswap.c"

static int disknr_from_filename(const char *name)
{
    int disknr = 1;
    char *p;

    if (strstr(name, "savegame.") != NULL) {
        disknr = 0;
    } else if (strstr(name, "iq-points") != NULL) {
        disknr = 0;
    } else if ((p = strstr(name, "atlantis.")) != NULL) {
        disknr = atoi(p + 9) ?: 1;
    } else if ((p = strstr(name, "amiga")) != NULL) {
        disknr = atoi(p + 5);
    }

    return disknr;
}

static int disknr_from_volname(const char *volname)
{
    int disknr = -1;
    char *p;

    if ((p = strstr(volname, "atlantis")) != NULL) {
        disknr = atoi(p + 8);
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
