*
* Dispatch table for main menu
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
            DW    SETCLOCK
            DW    QUIT
            ERR   *-]SPOT-MENUTSZ
*POSTDZX
            LDA   #$60
            STA   POSTDZX
            JSR   CATLIB
            JMP   DISKLIB
