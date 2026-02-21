***********************************
*                                 *
*          MESSAGES               *
*                                 *
***********************************
*
* String pointers. Keep this in sync
* with the message IDs listed in VARS
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
            DW    :VOLUME
*
            DW    :QPRODOS    ;23 MENU 8
            DW    :MONITOR
            DW    :REBOOT
*
            DW    :HEADER
            DW    :DASH17
            DW    DASHES
            DW    :DIR
            DW    :MORE
*
* Remaining messages are stored in MESSAGES2 compressed module.
* Message IDs continue sequentially. PRINT routine takes care of
* decompressing the module when necessary.
*
            DW    XEFGOESC
            DW    XFNGOESC
            DW    XESCEXIT
            DW    XTOOLONG
            DW    XTOOLNG0
            DW    XNOTSUB
            DW    XNOFILES
            DW    XMTSUB
            DW    XINROOT
            DW    XINCDISK
            DW    XNODOS
            DW    XNODOS3
            DW    XNOPRO
            DW    XFLONLY
            DW    XNOSEL
            DW    XREAD
            DW    XWRITE
            DW    XBLANK4
            DW    XBLANK3
            DW    XSLOT
            DW    XPRESS1
            DW    XFILE
            DW    XPSTATE0
            DW    XPSTATE1
            DW    XPSTATE2
            DW    XPSTATE3
            DW    XPSTAT45
            DW    XPSTAT45
            DW    XTRACK
            DW    XSECTOR
            DW    XCRESC
            DW    XCRESC1
            DW    XERROR
            DW    XPRESS
*
            DW    XERR2B
            DW    XERR44
            DW    XERR45
            DW    XERR44
            DW    XERR48
            DW    XERR49
            DW    XERR4E
            DW    XERR3F
            DW    XERR52
            DW    XERR47
            DW    XERR52
            DW    XERR2F
            DW    XERR2F
*
*
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
:DIR        ASC   "directory"
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
*
MONTH1      ASC   "JFMAMJJASOND"
MONTH2      ASC   "AEAPAUUUECOE"
MONTH3      ASC   "NBRRYNLGPTVC"
