
/* df0:savegame.000 etc */
/* atlantis1:atlantis.000 etc */
/* atlantis1:amiga1.ims etc */

#define VOLNAME_PREFIX "flash"

#include "../shared/amigados_autoswap.c"

static int disknr_from_filename(const char *name)
{
    int disknr = -1;
    char *p;
   

    //some files are multiple copies across disks, very unlikekly it will ask for disk swap on those
    //strcasestr()

    if ((p = strstr(name, "FlashBack")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "FlashbackPatch")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "font8.spr")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "intro.cmp")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "logos.cmp")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "icone.spr")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "icon.spr")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "level1.ct")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "level1.lev")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "level1.mbk")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "level1.pal")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "level1.pro")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "level1.sgd")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "perso.spm")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "present.cmp")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "fin")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "intro")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "logo")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "options")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(name, "alimpont.cmp")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "holoseq.cmp")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "map.cmp")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "memo.cmp")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "metro.cmp")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "missions.cmp")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "serrure.cmp")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "level1.ani")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "level1.obc")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "level1.pge")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "level1.rpc")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "level1.spc")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "level1.spl")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "level1.tbn")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "level2")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "ceinture")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "holocube")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "memoire")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "missions")) != NULL) {
        disknr = 2;
    }else if ((p = strstr(name, "espions.cmp")) != NULL) {
        disknr = 3;
    }else if ((p = strstr(name, "dt.")) != NULL) {
        disknr = 3;
    }else if ((p = strstr(name, "level3")) != NULL) {
        disknr = 3;
    }else if ((p = strstr(name, "LEVEL3")) != NULL) {
        disknr = 3;
    }else if ((p = strstr(name, "reunion")) != NULL) {
        disknr = 3;
    }else if ((p = strstr(name, "taxi")) != NULL) {
        disknr = 3;
    }else if ((p = strstr(name, "voyage")) != NULL) {
        disknr = 3;
    }else if ((p = strstr(name, "fin.cmp")) != NULL) {
        disknr = 4;
    }else if ((p = strstr(name, "lift.cmp")) != NULL) {
        disknr = 4;
    }else if ((p = strstr(name, "log.cmp")) != NULL) {
        disknr = 4;
    }else if ((p = strstr(name, "teleport.cmp")) != NULL) {
        disknr = 4;
    }else if ((p = strstr(name, "level4")) != NULL) {
        disknr = 4;
    }else if ((p = strstr(name, "LEVEL4")) != NULL) {
        disknr = 4;
    }else if ((p = strstr(name, "ascenseur")) != NULL) {
        disknr = 4;
    }else if ((p = strstr(name, "journal")) != NULL) {
        disknr = 4;
    }else if ((p = strstr(name, "planetexplo")) != NULL) {
        disknr = 4;
    } 
    

    return disknr;
}

static int disknr_from_volname(const char *volname)
{
    int disknr = -1;
    char *p;

    if ((p = strstr(volname, "flashback disk 1")) != NULL) {
        disknr = 1;
    } else if ((p = strstr(volname, "flashback disk 2")) != NULL) {
        disknr = 2;
    } else if ((p = strstr(volname, "flashback disk 3")) != NULL) {
        disknr = 3;
    } else if ((p = strstr(volname, "flashback disk 4")) != NULL) {
        disknr = 4;
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
