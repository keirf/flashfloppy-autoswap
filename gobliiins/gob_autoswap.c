
#define VOLNAME_PREFIX "Gobliiins"

#include "../shared/amigados_autoswap.c"

static int disknr_from_filename(const char *name)
{
    int disknr = 1;
    char *p;
   
    if ((p = strstr(name, "DISK1.STK")) != NULL) {
        disknr = 2;
    } else if ((p = strstr(name, "DISK2.STK")) != NULL) {
        disknr = 2;
    } else if ((p = strstr(name, "DISK3.STK")) != NULL) {
        disknr = 3;
    } else if ((p = strstr(name, "DISK4.STK")) != NULL) {
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
