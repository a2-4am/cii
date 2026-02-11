***********************************
*                                 *
*          MESSAGES               *
*                                 *
***********************************
HOTKEYS
            ASC   "XCDLRAFYVMPU/EQ"  ; main menu
            ASC   "PD"        ; FORMAT submenu
            ASC   "FDWO"      ; COPY submenu
            ASC   "NFDH"      ; CATALOG submenu
            ASC   "DFS"       ; VERIFY submenu
            ASC   "VT"        ; VIEW submenu
            ASC   "FDO"       ; DELETE submenu
            ASC   "FV"        ; RENAME submenu

*
* Menu IDs
*
            DUM   0
UMAIN       DS    1
UCATALOG    DS    1
UDELETE     DS    1
UVERIFY     DS    1
UVIEW       DS    1
UFORMAT     DS    1
UCOPY       DS    1
URENAME     DS    1
            DEND
*
* Message IDs
* Some are opaque, others are enumerated.
* Read the comments!
*
            DUM   0
* message IDs for top-level menu items (must be first)
MCOPY       DS    1
MCATALOG    DS    1
MDELETE     DS    1
MLOCK       DS    1
MRENAME     DS    1
MALPHA      DS    1
MFORMAT     DS    1
MVERIFY     DS    1
MVIEW       DS    1
MTSMAP      DS    1
MNEWBOOT    DS    1
MUNDEL      DS    1
MMKDIR      DS    1
MNEWDATE    DS    1
MQUIT       DS    1
*
* Message IDs used by each submenu are listed in
* the LAST, FIRST, and CHOICE tables in MENUS.
* Each submenu's messages are enumerated within
* the submenu. Only reorder them as a group.
*
* FORMAT submenu
*
MPRODOS     DS    1           ;0F MENU 5 (was 7)
MDOS33      DS    1
*
* COPY submenu
*
MCOPFILE    DS    1           ;11 MENU 6 (was 8)
MCOPDISK    DS    1
MDSKWFMT    DS    1
MCOPDOS     DS    1
*
* CATALOG submenu
*
MNORMAL     DS    1           ;15 MENU 1
MWLENGTH    DS    1
MWDELETE    DS    1
MWHIDDEN    DS    1
*
* VERIFY submenu
*
MVERDISK    DS    1           ;19 MENU 3
MVERFILE    DS    1
MSPEED      DS    1
*
* VIEW submenu
*
MVALUES     DS    1           ;1C MENU 4
MTEXT       DS    1
*
* DELETE submenu
*
MDELFILE    DS    1           ;1E MENU 2
MDELDISK    DS    1
MDELDOS     DS    1
*
* RENAME submenu
*
MFILES      DS    1           ;21 MENU 7 (was 9)
MVOLUME     DS    1           ;22
*
MTOOLONG    DS    1           ;23
MNOTSUB     DS    1           ;24
* READ and WRITE messages are enumerated
* (WRITE must be READ+1)
MREAD       DS    1           ;25
MWRITE      DS    1           ;26
*
MBLANK4     DS    1           ;27
MBLANK3     DS    1           ;28
MTOOLNG0    DS    1           ;now 29
MSLOT       DS    1           ;2A
MPRESS1     DS    1           ;2B
MFILE       DS    1           ;2C
*
* PSTATE messages are enumerated
MPSTATE0    DS    1           ;2D
MPSTATE1    DS    1           ;2E
MPSTATE2    DS    1           ;2F
MPSTATE3    DS    1           ;30
MPSTAT45    DS    1           ;31
            DS    1           ;32 (enumerated, also PSTAT45, do not remove)
*
MTRACK      DS    1           ;33
MSECTOR     DS    1           ;34
MCRESC      DS    1           ;35
MNOFILES    DS    1           ;36
MMTSUB      DS    1           ;now 37
MINROOT     DS    1           ;38
MCRESC1     DS    1           ;now 39
MERROR      DS    1           ;3A
MDASHES     DS    1           ;now 3B
MPRESS      DS    1           ;now 3C
MMORE       DS    1           ;now 3D
MHEADER     DS    1           ;3E
*
* Enumerated error messages handled by OUCH/ERRMSG
*
MERRENUM    DS    1           ;now 3F
            DS    1
            DS    1
            DS    1
            DS    1
            DS    1
            DS    1
            DS    1
            DS    1
            DS    1
            DS    1
            DS    1
            DS    1
            DEND
*
* String pointers. Keep this in sync
* with the message IDs listed above.
*
MESSAG      DW    :COPY       ;0 MENU 0
            DW    :CATALOG
            DW    :DELETE
            DW    :LOCK
            DW    :RENAME
            DW    :ALPHA
            DW    :FORMAT
            DW    :VERIFY
            DW    :VIEW       ;8
            DW    :TSMAP
            DW    :NEWBOOT
            DW    :UNDEL
            DW    :MKDIR
            DW    :NEWDATE
            DW    :QUIT
*
            DW    :PRODOS     ;0F MENU 5 (was 7)
            DW    :DOS33
*
            DW    :FILES      ;11 MENU 6 (was 8)
            DW    :DISK
            DW    :DSKWFMT
            DW    :DOS
*
            DW    :NORMAL     ;15 MENU 1
            DW    :WLENGTH
            DW    :WDELETE
            DW    :WHIDDEN
*
            DW    :DISK       ;19 MENU 3
            DW    :FILES
            DW    :SPEED
*
            DW    :VALUES     ;1C MENU 4
            DW    :TEXT
*
            DW    :FILES      ;1E MENU 2
            DW    :DISK
            DW    :DOS
*
            DW    :FILES      ;21 MENU 7 (was 9)
            DW    :VOLUME     ;22
*
            DW    :TOOLONG    ;23
            DW    :NOTSUB     ;24
            DW    :READ       ;25
            DW    :WRITE      ;26
            DW    :BLANK4     ;27
            DW    :BLANK3     ;28
            DW    :TOOLNG0    ;now 29
            DW    :SLOT       ;2A
            DW    :PRESS1     ;2B
            DW    :FILE       ;2C
            DW    :PSTATE0    ;2D
            DW    :PSTATE1    ;2E
            DW    :PSTATE2    ;2F
            DW    :PSTATE3    ;30
            DW    :PSTAT45    ;31
            DW    :PSTAT45    ;32
            DW    :TRACK      ;33
            DW    :SECTOR     ;34
            DW    :CRESC      ;35
            DW    :NOFILES    ;36
            DW    :MTSUB      ;now 37
            DW    :INROOT     ;38
            DW    :CRESC1     ;now 39
            DW    :ERROR      ;3A
            DW    DASHES      ;now 3B
            DW    :PRESS      ;now 3C
            DW    :MORE       ;now 3D
            DW    :HEADER     ;3E
*
            DW    :ERR2B      ;3F
            DW    :ERR44      ;40
            DW    :ERR45      ;41
            DW    :ERR44      ;42
            DW    :ERR48      ;43
            DW    :ERR49      ;44
            DW    :ERR4E      ;45
            DW    :ERR3F      ;46
            DW    :ERR52      ;47
            DW    :ERR47      ;48
            DW    :ERR52      ;49
            DW    :ERR2F      ;4A
            DW    :ERR2F      ;4B
*
*
*
:ERR2B      ASC   "Disk is write-protected"
            DB    $0
*
:ERR44      ASC   "Path not found"
            DB    $0
*
:ERR45      ASC   "Volume not online"
            DB    $0
*
:ERR48      ASC   "Disk full"
            DB    $0
*
:ERR49      ASC   "Directory full"
            DB    $0
*
:ERR4E      ASC   "Can not delete non-empty subdirectory"
            DB    $0
*
:ERR3F      ASC   "Subdirectory not found"
            DB    $0
*
:ERR52      ASC   "Not a ProDOS or DOS 3.3 disk"
            DB    $0
*
:ERR47      ASC   "Subdirectory already exists"
            DB    $0
*
:ERR2F      ASC   "No disk in drive"
            DB    $0
*
:INROOT     ASC   "Already in root directory"
            DB    $0
*
:NOTSUB     ASC   "Not a subdirectory"
            DB    $0
*
:MTSUB      ASC   "Empty subdirectory"
            DB    $0
*
:TOOLONG    DB    $8D,$8D
:TOOLNG0    ASC   "Prefix too long"
            DB    $8D,$0
*
*
:COPY       ASC   "Copy"
            DB    $0
:CATALOG    ASC   "Catalog"
            DB    $0
:DELETE     ASC   "Delete"
            DB    $0
:LOCK       ASC   "Lock/Unlock Files"
            DB    $0
:RENAME     ASC   "Rename"
            DB    $0
:ALPHA      ASC   "Alphabetize Catalog"
            DB    $0
:FORMAT     ASC   "Format Disk"
            DB    $0
:VERIFY     ASC   "Verify"
            DB    $0
:VIEW       ASC   "View Files"
            DB    $0
:TSMAP      ASC   "Disk Map"
            DB    $0
:NEWBOOT    ASC   "Change Boot Program"
            DB    $0
:UNDEL      ASC   "Undelete Files"
            DB    $0
:MKDIR      ASC   "Create Subdirectory"
            DB    $0
:NEWDATE    ASC   "Enter Date"
            DB    $0
:QUIT       ASC   "Quit"
            DB    $0
*
:FILES      ASC   "Files"
            DB    $0
:DISK       ASC   "Disk"
            DB    $0
:DSKWFMT    ASC   "Disk w/ Format"
            DB    $0
:DOS        ASC   "DOS"
            DB    $0
*
:VOLUME     ASC   "Volume"
            DB    $0
:DOS33      ASC   "DOS 3.3"
            DB    $0
:PRODOS     ASC   "ProDOS"
            DB    $0
*
:NORMAL     ASC   "Normal"
            DB    $0
:WLENGTH    ASC   "File Lengths"
            DB    $0
:WDELETE    ASC   "Deleted Files"
            DB    $0
:WHIDDEN    ASC   "Hidden Chars"
            DB    $0
*
:SPEED      ASC   "Drive Speed"
            DB    $0
*
:VALUES     ASC   "Values"
            DB    $0
:TEXT       ASC   "Text"
            DB    $0
*
*
:BLANK4     DB    $2F,$8D
:BLANK3     DB    $2F,$8D,$2F,$8D,$2F
            DB    $0
*
:SLOT       ASC   "Slot "
            DB    $0
*
:FILE       ASC   "File"
            DB    $0
*
:PSTATE0
            ASC   "[Return]-Mark file, [U]nmark, [E]nter"
            DB    $8D
            ASC   "filename, Number-Insert, [G]o,"
            DB    $8D
            ASC   "[Esc]-Exit"
            DB    $0
:PSTATE1
            ASC   "[Return]-Toggle marker, [E]nter"
            DB    $8D
            ASC   "filename, [G]o, [Esc]-Exit"
            DB    $0
:PSTATE2
            ASC   "[Return]-Toggle asterisk, [E]nter"
            DB    $8D
            ASC   "filename, [G]o, [Esc]-Exit"
            DB    $0
:PSTATE3
            ASC   "[Return]-Select to rename, [E]nter"
            DB    $8D
            ASC   "filename, [G]o, [Esc]-Exit"
            DB    $8D
            ASC   "(Renamed files are marked)"
            DB    $0
:PSTAT45
            ASC   "[G]o, [E]nter Filename, [Esc] to exit"
            DB    $0
:TRACK      ASC   "Track $"
            DB    $0
:SECTOR     ASC   "Sector $"
            DB    $0
:CRESC1     DB    $8D
:CRESC      ASC   "[Return]-Continue, [Esc]-Exit "
            DB    $0
*
:NOFILES    DB    $8D
            ASC   "No files"
            DB    $8D
            DB    $0
*
:ERROR      ASC   "Error"
            DB    $0
*
:HEADER
            ASC   "           Copy ][ Reboot 1.0"
            DB    $8D
            ASC   " (C) 1982-9 Central Point, (C) 2026 4am"
            DB    $8D
DASHES      ASC   "----------------------------------------"
            DB    $0
:MORE       ASC   "----------------- MORE -----------------"
            DB    $0
:READ       ASC   "Read"
            DB    $0
:WRITE      ASC   "Write"
            DB    $0
:PRESS      DB    $8D
:PRESS1     ASC   "Press [Return] "
            DB    $0
*
MONTH1      ASC   "JFMAMJJASOND"
MONTH2      ASC   "AEAPAUUUECOE"
MONTH3      ASC   "NBRRYNLGPTVC"

