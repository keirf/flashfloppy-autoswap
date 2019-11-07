
/* df0:savegame.000 etc */
/* atlantis1:atlantis.000 etc */
/* atlantis1:amiga1.ims etc */

#define VOLNAME_PREFIX "gob"

#include "../shared/amigados_autoswap.c"

static int disknr_from_filename(const char *name)
{
    int disknr = 1;
    char *p;
   

    if ((p = strstr(name, "azerty")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "INTRO.STK")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "JEULET1.LET]")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "JEULET2.LET]")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "JEUMATH.LET")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "DISK1.STK")) != NULL) {
        disknr = 2;
    } else if ((p = strstr(name, "DISK2.STK")) != NULL) {
        disknr = 2;
    } else if ((p = strstr(name, "DISK3.STK")) != NULL) {
        disknr = 3;
    }

    return disknr;
}

static int disknr_from_volname(const char *volname)
{
    int disknr = -1;
    char *p;

    if ((p = strstr(volname, "Gobliiins1")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(volname, "Gobliiins2")) != NULL) {
        disknr = 2;
    } else if ((p = strstr(volname, "Gobliiins3")) != NULL) {
        disknr = 3;
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
