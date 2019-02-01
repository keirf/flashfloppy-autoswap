
/* Monkey1:savegame._a_ etc */
/* Monkey1:disk01.lec etc */

#define VOLNAME_PREFIX "Monkey"

#include "../shared/amigados_autoswap.c"

static int disknr_from_filename(const char *name)
{
    char lowername[32];
    int disknr = 1, i;
    char *p;

    for (i = 0; (i < sizeof(lowername)) && name[i]; i++)
        lowername[i] = (name[i] >= 'A') && (name[i] <= 'Z')
            ? name[i]-'A'+'a' : name[i];
    if (i == sizeof(lowername))
        return 1;
    lowername[i] = '\0';

    if (strstr(lowername, "savegame.") != NULL) {
        disknr = 0;
    } else if ((p = strstr(lowername, ".lec")) != NULL) {
        disknr = atoi(p - 1);
    }

    return disknr;
}

static int disknr_from_volname(const char *volname)
{
    int disknr = -1;
    char *p;

    if ((p = strstr(volname, "Save")) != NULL) {
        disknr = 0;
    } else if ((p = strstr(volname, "Monkey")) != NULL) {
        disknr = atoi(volname + 6);
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
