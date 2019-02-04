
/* disk_0:187 etc */
/* df0:advisor etc */

#define VOLNAME_PREFIX "disk_"
#define PRISTINE_NAMEBUF 1

#include "../shared/amigados_autoswap.c"

static const int8_t diskmap[] = { 2,3,4,5,6,7,8,9,10,11,12,-1,13,14,15,1 };

static int disknr_from_volname(const char *name)
{
    int disknr = 1;
    char *p;

    if ((p = strstr(name, "disk_save")) != NULL) {
        disknr = 0;
    } else if ((p = strstr(name, "disk_")) != NULL) {
        disknr = atoi(p + 5);
        disknr = (disknr < sizeof(diskmap)) ? diskmap[disknr] : -1;
    }

    return disknr;
}

static int disknr_from_filename(const char *name)
{
    if (!strncmp(name, "df", 2)) {
        char *p = (char *)name;
        p[2] = ff_unit + '0';
    }

    if (strstr(name, "advisor") != NULL)
        return 0;

    return disknr_from_volname(name);
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
