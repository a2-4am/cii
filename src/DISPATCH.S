*
* Dispatch table for main menu
* and jump vectors for other
* modularized entry points
*
*labels in VARS
*MENUTBL
]SPOT       =     *
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
            ERR   *-]SPOT-MENUTSZ
*JDDISK
            JMP   DDISK
*JD1FILE
            JMP   D1FILE
*JDOTREE
            JMP   DOTREE
*JDODEV
            JMP   DODEV
*JMATCH
            JMP   MATCH
*JCATLN1
            JMP   CATLN1
