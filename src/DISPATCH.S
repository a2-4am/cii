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
            DW    SETCLOCK
            DW    QUIT
            ERR   *-]SPOT-MENUTSZ
*DELETE
            >>>   JMPMODULE,DELLIB;DELETEINTERNAL
*FORMAT
            >>>   JMPMODULE,DELLIB;FORMATINTERNAL
*MAKESUB
            >>>   JMPMODULE,MISCLIB;MAKESUBINTERNAL
*SETCLOCK
            >>>   JMPMODULE,MISCLIB;SETCLOCKINTERNAL
*BOOTPG
            >>>   JMPMODULE,MISCLIB;BOOTPGINTERNAL
*VIEW
            >>>   JMPMODULE,MISCLIB;VIEWINTERNAL
*ALPHA
            >>>   JMPMODULE,MISCLIB;ALPHAINTERNAL
*RENAME
            >>>   JMPMODULE,MISCLIB;RENAMEINTERNAL
*LOCK
            >>>   JMPMODULE,MISCLIB;LOCKINTERNAL
