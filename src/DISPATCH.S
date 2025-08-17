*
* Dispatch table for main menu
* and jump vectors for other
* modularized entry points
*
*labels in VARS
*JDOTREE
            JMP   DOTREE
*MENUTBL
            DW    COPY
            DW    CATALOG
            DW    DELETE
            DW    LOCK
            DW    RENAME
            DW    ALPHA
            DW    FORMAT
            DW    VERIFY
            DW    VIEW
            DW    TSMAP
            DW    BOOTPG
            DW    UNDEL
            DW    MAKESUB
            DW    SETPRINT
            DW    QUIT
            ERR   *-MENUTBL-MENUTSZ
