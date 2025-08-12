***********************************
*                                 *
*          MESSAGES               *
*                                 *
***********************************
*
*
* (Menus 5 & 6 unused)
*
            DUM   0
* top-level menu items
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
MNEWINFO    DS    1
MQUIT       DS    1
*
* COPY submenu
*
            DS    1           ;[4am] unused, previously :BCPY525
            DS    1           ;[4am] unused, previously :BCPY35
MCOPFILE    DS    1           ;11 MENU 0
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
MTOOLONG    DS    1           ;21
*
* FORMAT submenu
*
MPRODOS     DS    1           ;22 MENU 7
MDOS33      DS    1
*
MNOTSUB     DS    1           ;24
*
MREAD       DS    1           ;25
MWRITE      DS    1           ;26
*
MBLANK4     DS    1           ;27
MBLANK3     DS    1           ;28
MCPYENT     DS    1           ;29
MSLOT       DS    1           ;2A
MPRESS1     DS    1           ;2B
MFILE       DS    1           ;2C
*
MPSTATE0    DS    1           ;2D
MPSTATE1    DS    1
MPSTATE2    DS    1           ;2F
MPSTATE3    DS    1           ;30
MPSTAT45    DS    1           ;31
            DS    1
*
MTRACK      DS    1           ;33
MSECTOR     DS    1           ;34
MCRESC      DS    1           ;35
MNOFILES    DS    1           ;36
            DS    1           ;[4am] unused, previously :INIT
MINROOT     DS    1           ;38
            DS    1           ;[4am] unused, previously :IO
MERROR      DS    1           ;3A
MQUITOPT    DS    1           ;3B
MSPACE      DS    1           ;3C
            DS    1           ;[4am] unused, previously :COPYTP
MHEADER     DS    1           ;3E
            DS    1           ;[4am] unused, previously :DRIVE
*
* RENAME submenu
*
MFILES      DS    1           ;40 MENU 9
MVOLUME     DS    1           ;41
*
MDASHES     DS    1           ;42
MPRESS      DS    1           ;43
MMORE       DS    1           ;44
*
* Error messages handled by OUCH/ERRMSG
*
MERR2B      DS    1           ;45
MERR44      DS    1
MERR45      DS    1
            DS    1
MERR48      DS    1
MERR49      DS    1
MERR4E      DS    1
MERR3F      DS    1
MERR52      DS    1
MERR47      DS    1
            DS    1
MERR2F      DS    1
            DS    1
*
MCRESC1     DS    1           ;52
MMTSUB      DS    1           ;now 53
MTOOLNG0    DS    1           ;now 54
MSELFUNC    DS    1           ;55
MSELOPT     DS    1           ;56
MINSSRC     DS    1           ;57
MINSTGT     DS    1           ;58
MPROHDR1    DS    1           ;59
MPROHDR2    DS    1           ;5A
            DS    1           ;[4am] unused, previously :MSG5B 'can't find file: '
MANOTHER    DS    1           ;5C
            DS    1           ;[4am] unused, previously :MSG5D 'enter file name: '
MDIFSIZE    DS    1           ;5E
MINSDSKS    DS    1           ;5F
MDUPVOL     DS    1           ;60
            DS    1
MINS2FRM    DS    1           ;62
MRDY2FRM    DS    1           ;63
MFMTING     DS    1           ;64
MFMTDONE    DS    1           ;65
MDIRMADE    DS    1           ;66
MASKLOCK    DS    1           ;67
MINSBLNK    DS    1           ;68
MBETWEEN    DS    1           ;69
MMAPGRID    DS    1           ;6A
MMAPOTHR    DS    1           ;6B
MNOBOOTP    DS    1           ;6C
MNOTFL      DS    1           ;6D
MNOTPRO     DS    1           ;6E
MNOTDOS     DS    1           ;6F
            DEND

MESSAG      DW    :COPY        ;0 MENU 0
            DW    :CATALOG
            DW    :DELETE
            DW    :LOCK
            DW    :RENAME
            DW    :ALPHA
            DW    :FORMAT
            DW    :VERIFY
            DW    :VIEW        ;8
            DW    :TSMAP
            DW    :NEWBOOT
            DW    :UNDEL
            DW    :MKDIR
            DW    :NEWINFO
            DW    :QUIT
*
            DW    0            ;[4am] unused, previously :BCPY525
            DW    0            ;[4am] unused, previously :BCPY35
            DW    :FILES       ;11 MENU 0
            DW    :DISK
            DW    :DSKWFMT
            DW    :DOS
*
            DW    :NORMAL      ;15 MENU 1
            DW    :WLENGTH
            DW    :WDELETE
            DW    :WHIDDEN
*
            DW    :DISK        ;19 MENU 3
            DW    :FILES
            DW    :SPEED
*
            DW    :VALUES      ;1C MENU 4
            DW    :TEXT
*
            DW    :FILES       ;1E MENU 2
            DW    :DISK
            DW    :DOS
*
            DW    :TOOLONG     ;21
*
            DW    :PRODOS      ;22 MENU 7
            DW    :DOS33
*
            DW    :NOTSUB      ;24
            DW    :READ        ;25
            DW    :WRITE       ;26
            DW    :BLANK4      ;27
            DW    :BLANK3      ;28
            DW    :CPYENT      ;29
            DW    :SLOT        ;2A
            DW    :PRESS1      ;2B
            DW    :FILE        ;2C
            DW    :PSTATE0     ;2D
            DW    :PSTATE1     ;2E
            DW    :PSTATE2     ;2F
            DW    :PSTATE3     ;30
            DW    :PSTAT45     ;31
            DW    :PSTAT45     ;32
            DW    :TRACK       ;33
            DW    :SECTOR      ;34
            DW    :CRESC       ;35
            DW    :NOFILES     ;36
            DW    0            ;[4am] unused, previously :INIT
            DW    :INROOT      ;38
            DW    0            ;[4am] unused, previously :IO
            DW    :ERROR       ;3A
            DW    :QUITOPT     ;3B
            DW    :SPACE       ;3C
            DW    0            ;[4am] unused, previously :COPYTP
            DW    :HEADER      ;3E
            DW    0            ;[4am] unused, previously :DRIVE
            DW    :FILES       ;40 MENU 9
            DW    :VOLUME      ;41
            DW    :DASHES      ;42
            DW    :PRESS       ;43
            DW    :MORE        ;44
            DW    :ERR2B       ;45
            DW    :ERR44       ;46
            DW    :ERR45       ;47
            DW    :ERR44       ;48
            DW    :ERR48       ;49
            DW    :ERR49       ;4A
            DW    :ERR4E       ;4B
            DW    :ERR3F       ;4C
            DW    :ERR52       ;4D
            DW    :ERR47       ;4E
            DW    :ERR52       ;4F
            DW    :ERR2F       ;50
            DW    :ERR2F       ;51
            DW    :CRESC1      ;52
            DW    :MTSUB       ;now 53
            DW    :TOOLNG0     ;now 54
            DW    :SELFUNC     ;55
            DW    :SELOPT      ;56
            DW    :INSSRC      ;57
            DW    :INSTGT      ;58
            DW    :PROHDR1     ;59
            DW    :PROHDR2     ;5A
            DW    0            ;[4am] unused, previously 'can't find file: '
            DW    :ANOTHER     ;5C
            DW    0            ;[4am] unused, previously 'enter file name: '
            DW    :DIFSIZE     ;5E
            DW    :INSDSKS     ;5F
            DW    :DUPVOL      ;60
            DW    0
            DW    :INS2FRM     ;62
            DW    :RDY2FRM     ;63
            DW    :FMTING      ;64
            DW    :FMTDONE     ;65
            DW    :DIRMADE     ;66
            DW    :ASKLOCK     ;67
            DW    :INSBLNK     ;68
            DW    :BETWEEN     ;69
            DW    :MAPGRID     ;6A
            DW    :MAPOTHR     ;6B
            DW    :NOBOOTP     ;6C
            DW    :NOTFL       ;6D
            DW    :NOTPRO      ;6E
            DW    :NOTDOS      ;6F
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
:CATALOG    ASC   "Catalog Disk"
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
:NEWINFO    ASC   "Set Printer Slot"
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
:WLENGTH    ASC   "W/ File Lengths"
            DB    $0
:WDELETE    ASC   "W/ Deleted Files"
            DB    $0
:WHIDDEN    ASC   "W/ Hidden Chars"
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
:CPYENT
            ASC   "Enter filename (,opt. filetypes)"
            DB    $8D
            ASC   "? "
            DB    $0
:SLOT       ASC   "Slot "
            DB    $0
:FILE       ASC   "File"
            DB    $0
:PSTATE0
            ASC   "[Return]-Mark file, [U]nmark, [E]nter"
            DB    $8D
            ASC   "filename, Number-Insert, [G]o,"
            DB    $8D
            ASC   "[ESC]-Exit"
            DB    $0
:PSTATE1
            ASC   "[Return]-Toggle marker, [E]nter"
            DB    $8D
            ASC   "filename, [G]o, [Esc]-Exit"
            DB    $0
:PSTATE2
            ASC   "[Return]-Toggle asterisk, [E]nter"
            DB    $8D
            ASC   "filename, [G]o, [ESC]-Exit"
            DB    $0
:PSTATE3
            ASC   "[Return]-Select to rename, [E]nter"
            DB    $8D
            ASC   "filename, [G]o, [ESC]-Exit"
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
:SPACE      DB    $8D
            ASC   "[Space]-Next File "
            DB    $0
*
:QUITOPT    DB    $8D,$8D
            ASC   " Press [Esc] to re-enter utilities"
            DB    $8D,$8D
            ASC   " Press [Return] to quit to ProDOS"
            DB    $8D,$8D
            ASC   " Press [M] to enter monitor"
            DB    $8D,$8D
            ASC   " Press [Reset] to reboot"
            DB    $0
*
:HEADER
            ASC   "           Copy ][ Plus  8.5"
            DB    $8D
            ASC   "(C) 1982-9 Central Point Software, Inc."
            DB    $8D
:DASHES     ASC   "----------------------------------------"
            DB    $0
:READ       ASC   "Read"
            DB    $0
:WRITE      ASC   "Write"
            DB    $0
:PRESS      DB    $8D
:PRESS1     ASC   "Press [Return] "
            DB    $0
:MORE       ASC   "----------------- MORE -----------------"
            DB    $0
*
:SELFUNC    ASC   "Use arrow keys"
            DB    $2F,$8D
            ASC   "& [Return] to"
            DB    $2F,$8D
            ASC   "select function"
            DB    $2F,$8D,0
*
:SELOPT     DB    $2F,$8D,$2F,$8D
            ASC   "Select option:"
            DB    $2F,$8D,0
*
:INSSRC     ASC   "Insert source disk"
            DB    $8D,$0
*
:INSTGT     ASC   "Insert target disk"
            DB    $8D,$0
*
:PROHDR1    ASC   "   NAME           TYPE  BLKS  MODIFIED"
            DB    $0
*
:PROHDR2    ASC   "         CREATED          ENDFILE SUBTYPE"
            DB    $0
*
:ANOTHER    ASC   "Copy same onto another disk (Y/N) ? "
            DB    $0
*
:DIFSIZE    DB    $8D,$8D
            ASC   "Device size mismatch"
            DB    $8D,$8D,$0
*
:INSDSKS    DB    $8D,$8D,$8D
            ASC   "Insert disks"
            DB    $8D,$8D,$0
*
:DUPVOL     DB    $8D,$8D
            ASC   "Duplicate volume online"
            DB    $8D,$0
*
:INS2FRM    DB    $8D,$8D
            ASC   "Insert disk to format"
            DB    $8D,$8D,$0
*
:RDY2FRM    ASC   "Ready to format (Y/N) ? "
            DB    $0
*
:FMTING     DB    $8D,$8D,$8D
            ASC   "  Formatting disk"
            DB    $8D,$8D,$0
*
:FMTDONE    DB    $8D,$8D
            ASC   "Formatting complete"
            DB    $8D,$0
*
:DIRMADE    DB    $8D,$8D
            ASC   "Subdirectory created"
            DB    $8D,$0
*
:ASKLOCK    DB    $8D
            ASC   "[L]ock or [U]nlock? "
            DB    $0
*
:INSBLNK    DB    $8D,$8D,$8D
            ASC   "Insert a blank disk in "
            DB    $0
*
:BETWEEN    DB    $8D,$8D,$8D
            ASC   "Drive speed should be between 198.0 ms."
            DB    $8D
            ASC   "and 202.0 ms."
            DB    $8D,$8D
            ASC   "Drive speed is       ms."
            DB    $8D,$8D
            ASC   "([Esc]-Exit)"
            DB    $0
*
:MAPGRID
            ASC   "   TRACK           1               2"
            DB    $8D
            ASC   "   0123456789ABCDEF0123456789ABCDEF012"
            DB    $8D,$8D
            ASC   "S"
            DB    $8D
            ASC   "E"
            DB    $8D
            ASC   "C"
            DB    $8D
            ASC   "T"
            DB    $8D
            ASC   "O"
            DB    $8D
            ASC   "R"
            DB    $0
*
:MAPOTHR    ASC   "   Use arrow keys to map other files  "
            DB    $0
*
:NOBOOTP    DB    $8D,$8D,$8D,$8D
            ASC   "No boot program to change"
            DB    $0
*
:NOTFL      DB    $8D,$8D,$8D
            ASC   "Disk II function only"
            DB    $8D,$0
*
:NOTPRO     DB    $8D,$8D,$8D
            ASC   "Not a ProDOS function"
            DB    $8D,$0
*
:NOTDOS     DB    $8D,$8D,$8D
            ASC   "Not a DOS 3.3 function"
            DB    $8D,$0
