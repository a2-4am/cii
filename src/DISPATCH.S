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
*D1FILE
            >>>   JMPMODULE,DELLIB;D1FILEINTERNAL
*JDOTREE
            JMP   DOTREE
*JDODEV
            JMP   DODEV
*CATLN1
            >>>   JMPMODULE,CATLIB;CATLN1INTERNAL
*CATDIS
            >>>   JMPMODULE,CATLIB;CATDISINTERNAL
*CDDOKEY
            >>>   JMPMODULE,CATLIB;CDDOKEYINTERNAL
*FILEQ
            >>>   JMPMODULE,CATLIB;FILEQINTERNAL
*UNMARK
            >>>   JMPMODULE,CATLIB;UNMARKINTERNAL
*DIVOUT
            >>>   JMPMODULE,CATLIB;DIVOUTINTERNAL
*DIVEIN
            >>>   JMPMODULE,CATLIB;DIVEININTERNAL
*INITCD
            >>>   JMPMODULE,CATLIB;INITCDINTERNAL
*RDACNT
            >>>   JMPMODULE,CATLIB;RDACNTINTERNAL
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
