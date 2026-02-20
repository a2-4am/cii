***********************************
*                                 *
*          MESSAGES               *
*                                 *
***********************************
HOTKEYS
            ASC   "XCDLRAFYVMBU/EQ"  ; main menu
            ASC   "PD"        ; FORMAT submenu
            ASC   "FDWO"      ; COPY submenu
            ASC   "NFDH"      ; CATALOG submenu
            ASC   "FDS"       ; VERIFY submenu
            ASC   "VT"        ; VIEW submenu
            ASC   "FDO"       ; DELETE submenu
            ASC   "FV"        ; RENAME submenu
            ASC   "QMR"       ; QUIT submenu

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
MDISK       DS    1
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
MVERFILE    DS    1           ;19 MENU 3
MVERDISK    DS    1
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
* QUIT submenu
*
MQPRODOS    DS    1           ;23 MENU 8
MMONITOR    DS    1           ;24
MREBOOT     DS    1           ;25
*
MTOOLONG    DS    1           ;26
MNOTSUB     DS    1           ;27
* READ and WRITE messages are enumerated
* (WRITE must be READ+1)
MREAD       DS    1           ;28
MWRITE      DS    1           ;29
*
MBLANK4     DS    1           ;2A
MBLANK3     DS    1           ;2B
MTOOLNG0    DS    1           ;2C
MSLOT       DS    1           ;2D
MPRESS1     DS    1           ;2E
MFILE       DS    1           ;2F
*
* PSTATE messages are enumerated
MPSTATE0    DS    1           ;30
MPSTATE1    DS    1           ;31
MPSTATE2    DS    1           ;32
MPSTATE3    DS    1           ;33
MPSTAT45    DS    1           ;34
            DS    1           ;35 (enumerated, also PSTAT45, do not remove)
*
MEFGOESC    DS    1           ;36
MFNGOESC    DS    1           ;37
MESCEXIT    DS    1           ;38
MDIR        DS    1           ;39
MDASH17     DS    1           ;3A
MTRACK      DS    1           ;3B
MSECTOR     DS    1           ;3C
MCRESC      DS    1           ;3D
MNOFILES    DS    1           ;3E
MMTSUB      DS    1           ;3F
MINROOT     DS    1           ;40
MCRESC1     DS    1           ;41
MERROR      DS    1           ;42
MDASHES     DS    1           ;43
MPRESS      DS    1           ;44
MMORE       DS    1           ;45
MHEADER     DS    1           ;46
*
* Enumerated error messages handled by OUCH/ERRMSG
*
MERRENUM    DS    1           ;47
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
            DW    :FILES      ;19 MENU 3
            DW    :DISK
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
            DW    :QPRODOS    ;23 MENU 8
            DW    :MONITOR    ;24
            DW    :REBOOT     ;25
*
            DW    :TOOLONG    ;26
            DW    :NOTSUB     ;27
            DW    :READ       ;28
            DW    :WRITE      ;29
            DW    :BLANK4     ;2A
            DW    :BLANK3     ;2B
            DW    :TOOLNG0    ;2C
            DW    :SLOT       ;2D
            DW    :PRESS1     ;2E
            DW    :FILE       ;2F
            DW    :PSTATE0    ;30
            DW    :PSTATE1    ;31
            DW    :PSTATE2    ;32
            DW    :PSTATE3    ;33
            DW    :PSTAT45    ;34
            DW    :PSTAT45    ;35
            DW    :EFGOESC    ;36
            DW    :FNGOESC    ;37
            DW    :ESCEXIT    ;38
            DW    :DIR        ;39
            DW    :DASH17     ;3A
            DW    :TRACK      ;3B
            DW    :SECTOR     ;3C
            DW    :CRESC      ;3D
            DW    :NOFILES    ;3E
            DW    :MTSUB      ;3F
            DW    :INROOT     ;40
            DW    :CRESC1     ;41
            DW    :ERROR      ;42
            DW    DASHES      ;43
            DW    :PRESS      ;44
            DW    :MORE       ;45
            DW    :HEADER     ;46
*
            DW    :ERR2B      ;47
            DW    :ERR44
            DW    :ERR45
            DW    :ERR44
            DW    :ERR48
            DW    :ERR49
            DW    :ERR4E
            DW    :ERR3F
            DW    :ERR52
            DW    :ERR47
            DW    :ERR52
            DW    :ERR2F
            DW    :ERR2F
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
:ERR4E      ASC   "Can not delete non-empty sub"
            DB    MDIR
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
:INROOT     ASC   "Already in root "
            DB    MDIR
*
:NOTSUB     ASC   "Not a sub"
            DB    MDIR
*
:MTSUB      ASC   "Empty sub"
            DB    MDIR
*
:TOOLONG    DB    $8D,$8D
:TOOLNG0    ASC   "Prefix too long"
            DB    $8D,$0
*
*
:COPY       ASC   "Copy"
            DB    $0
:CATALOG    ASC   "Catalog "
            DB    MDISK
:DELETE     ASC   "Delete"
            DB    $0
:LOCK       ASC   "Lock/Unlock "
            DB    MFILES
:RENAME     ASC   "Rename"
            DB    $0
:ALPHA      ASC   "Alphabetize Catalog"
            DB    $0
:FORMAT     ASC   "Format "
            DB    MDISK
:VERIFY     ASC   "Verify"
            DB    $0
:VIEW       ASC   "View "
            DB    MFILES
:TSMAP      ASC   "Map "
            DB    MDISK
:NEWBOOT    ASC   "Change Boot Program"
            DB    $0
:UNDEL      ASC   "Undelete "
            DB    MFILES
:MKDIR      ASC   "Create Sub"
            DB    MDIR
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
:WDELETE    ASC   "Deleted "
            DB    MFILES
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
:QPRODOS    ASC   "Quit to ProDOS"
            DB    $0
:MONITOR    ASC   "Enter Monitor"
            DB    $0
:REBOOT     ASC   "Reboot"
            DB    $0
*
:BLANK4     DB    $FF,$8D
:BLANK3     DB    $FF,$8D,$FF,$8D,$FF
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
            DB    $8D,MESCEXIT
:PSTATE1
            ASC   "[Return]-Toggle marker, "
            DB    MEFGOESC
:PSTATE2
            ASC   "[Return]-Toggle asterisk, "
            DB    MEFGOESC
:PSTATE3
            ASC   "(Renamed files are marked)"
            DB    $8D
            ASC   "[Return]-Select to rename, "
            DB    MEFGOESC
:PSTAT45
            ASC   "[E]nter "
            DB    MFNGOESC
:EFGOESC    ASC   "[E]nter"
            DB    $8D
:FNGOESC    ASC   "filename, [G]o, "
            DB    MESCEXIT
:ESCEXIT    ASC   "[Esc]-Exit "
            DB    $0
:DIR        ASC   "directory"
            DB    $0
:TRACK      ASC   "Track $"
            DB    $0
:SECTOR     ASC   "Sector $"
            DB    $0
:CRESC1     DB    $8D
:CRESC      ASC   "[Return]-Continue, "
            DB    MESCEXIT
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
DASHES      ASC   "-----------------------"
            DB    MDASH17
:MORE       ASC   "----------------- MORE "
            DB    MDASH17
:DASH17     ASC   "-----------------"
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

