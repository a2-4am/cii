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
*PHRWTS
            JSR   PHRWTSLIB   ; ensure library is decompressed
            JMP   PHRWTSINTERNAL
*RDDRIVE
            JSR   PHRWTSLIB   ; ensure library is decompressed
            JMP   RDDRIVEINTERNAL
*FAKTRK
            JSR   PHRWTSLIB   ; ensure library is decompressed
            JMP   FAKTRKINTERNAL
*DELETE
            JSR   DELLIB      ; ensure library is decompressed
            JMP   DELETEINTERNAL
*FORMAT
            JSR   DELLIB      ; ensure library is decompressed
            JMP   FORMATINTERNAL
*D1FILE
            JSR   DELLIB      ; ensure library is decompressed
            JMP   D1FILEINTERNAL
*JDOTREE
            JMP   DOTREE
*JDODEV
            JMP   DODEV
*CATLN1
            JSR   CATLIB      ; ensure library is decompressed
            JMP   CATLN1INTERNAL
*CATDIS
            JSR   CATLIB      ; ensure library is decompressed
            JMP   CATDISINTERNAL
*CDDOKEY
            JSR   CATLIB      ; ensure library is decompressed
            JMP   CDDOKEYINTERNAL
*FILEQ
            JSR   CATLIB      ; ensure library is decompressed
            JMP   FILEQINTERNAL
*UNMARK
            JSR   CATLIB      ; ensure library is decompressed
            JMP   UNMARKINTERNAL
*DIVOUT
            JSR   CATLIB      ; ensure library is decompressed
            JMP   DIVOUTINTERNAL
*DIVEIN
            JSR   CATLIB      ; ensure library is decompressed
            JMP   DIVEININTERNAL
*INITCD
            JSR   CATLIB      ; ensure library is decompressed
            JMP   INITCDINTERNAL
*RDACNT
            JSR   CATLIB      ; ensure library is decompressed
            JMP   RDACNTINTERNAL
*MAKESUB
            JSR   MISCLIB     ; ensure library is decompressed
            JMP   MAKESUBINTERNAL
*SETCLOCK
            JSR   MISCLIB     ; ensure library is decompressed
            JMP   SETCLOCKINTERNAL
*BOOTPG
            JSR   MISCLIB     ; ensure library is decompressed
            JMP   BOOTPGINTERNAL
*VIEW
            JSR   MISCLIB     ; ensure library is decompressed
            JMP   VIEWINTERNAL
*ALPHA
            JSR   MISCLIB     ; ensure library is decompressed
            JMP   ALPHAINTERNAL
