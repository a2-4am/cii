***********************************
*                                 *
*          MESSAGES               *
*                                 *
***********************************
*
*
* (Menus 5 & 6 unused)
*
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
            DW    :WRITE
            DW    :BLANK4      ;27
            DW    :BLANK3      ;28
            DW    :CPYENT
            DW    :SLOT        ;2A
            DW    :PRESS1      ;2B
            DW    :FILE
            DW    :PSTATE0
            DW    :PSTATE1
            DW    :PSTATE2
            DW    :PSTATE3     ;30
            DW    :PSTAT45

            DW    :PSTAT45
            DW    :TRACK
            DW    :SECTOR
            DW    :CRESC
            DW    :NOFILES
            DW    :INIT
            DW    :INROOT      ;38
            DW    :IO
            DW    :ERROR
            DW    :QUITOPT     ;3B
            DW    :SPACE
            DW    0            ;[4am] unused, previously :COPYTP
            DW    :HEADER
            DW    :DRIVE
            DW    :FILES       ;40 MENU 9
            DW    :VOLUME
            DW    :DASHES      ;42
            DW    :PRESS
            DW    :MORE
            DW    :ERR2B
            DW    :ERR44
            DW    :ERR45
            DW    :ERR44       ;48
            DW    :ERR48
            DW    :ERR49
            DW    :ERR4E
            DW    :ERR3F
            DW    :ERR52
            DW    :ERR47
            DW    :ERR52       ;4F
            DW    :ERR2F       ;50
            DW    :ERR2F       ;51
            DW    :CRESC1
            DW    :MTSUB       ;now 53
            DW    :TOOLNG0     ;now 54
            DW    :MSG55
            DW    :MSG56
            DW    :MSG57
            DW    :MSG58
            DW    :MSG59
            DW    :MSG5A
            DW    :MSG5B
            DW    :MSG5C
            DW    :MSG5D
            DW    :MSG5E
            DW    :MSG5F
            DW    :MSG60
            DW    :MSG61
            DW    :MSG62
            DW    :MSG63
            DW    :MSG64
            DW    :MSG65
            DW    :MSG66
            DW    :MSG67
            DW    :MSG68
            DW    :MSG69
            DW    :MSG6A
            DW    :MSG6B
            DW    :MSG6C
            DW    :MSG6D
            DW    :MSG6E
            DW    :MSG6F
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
            ASC   "[Return]-Mark File, [U]nmark, [E]nter"
            DB    $8D
            ASC   "Filename, Number-Insert, [G]o,"
            DB    $8D
            ASC   "[ESC]-EXIT"
            DB    $0
:PSTATE1
            ASC   "[Return]-Toggle marker, [E]nter"
            DB    $8D
            ASC   "Filename, [G]o, [Esc]-Exit"
            DB    $0
:PSTATE2
            ASC   "[Return]-Toggle Asterisk, [E]nter"
            DB    $8D
            ASC   " Filename, [G]o, [ESC]-Exit"
            DB    $0
:PSTATE3
            ASC   "[Return]-Select to rename, [E]nter"
            DB    $8D
            ASC   "Filename, [G]o, [ESC]-Exit"
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
:NOFILES    DB    $8D
            ASC   "No files"
            DB    $8D
:INIT       DB    $0
:IO         ASC   "I/O"
            DB    $0
:ERROR      ASC   "Error"
            DB    $0
:SPACE      DB    $8D
            ASC   "[Space]-Next File "
            DB    $0
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
*
:HEADER
            ASC   "           Copy ][ Plus  8.5"
            DB    $8D
            ASC   "(C) 1982-9 Central Point Software, Inc."
            DB    $8D
:DASHES     ASC   "----------------------------------------"
            DB    $0
:DRIVE      ASC   "Drive "
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
:MSG55      ASC   "Use arrow keys"
            DB    $2F,$8D
            ASC   "& [Return] to"
            DB    $2F,$8D
            ASC   "select function"
            DB    $2F,$8D,0
*
:MSG56      DB    $2F,$8D,$2F,$8D
            ASC   "Select option:"
            DB    $2F,$8D,0
*
:MSG57      ASC   "Insert source disk"
            DB    $8D,$0
*
:MSG58      ASC   "Insert target disk"
            DB    $8D,$0
*
:MSG59      ASC   "   NAME           TYPE  BLKS  MODIFIED"
            DB    $0
*
:MSG5A      ASC   "         CREATED          ENDFILE SUBTYPE"
            DB    $0
*
:MSG5B      ASC   "Can't find file: "
            DB    $0
*
:MSG5C      ASC   "Copy same onto another disk (Y/N) ? "
            DB    $0
*
:MSG5D      DB    $8D,$8D
            ASC   "Target file name: "
            DB    $0
*
:MSG5E      DB    $8D,$8D
            ASC   "Device size mismatch"
            DB    $8D,$8D,$0
*
:MSG5F      DB    $8D,$8D,$8D
            ASC   "Insert disks"
            DB    $8D,$8D,$0
*
:MSG60      DB    $8D,$8D
            ASC   "Duplicate volume online"
            DB    $8D,$0
*
:MSG61      DB    $0
*
:MSG62      DB    $8D,$8D
            ASC   "Insert disk to format"
            DB    $8D,$8D,$0
*
:MSG63      ASC   "Ready to format (Y/N) ? "
            DB    $0
*
:MSG64      DB    $8D,$8D,$8D
            ASC   "  Formatting disk"
            DB    $8D,$8D,$0
*
:MSG65      DB    $8D,$8D
            ASC   "Formatting complete"
            DB    $8D,$0
*
:MSG66      DB    $8D,$8D
            ASC   "Subdirectory created"
            DB    $8D,$0
*
:MSG67      DB    $8D
            ASC   "[L]ock or [U]nlock? "
            DB    $0
*
:MSG68      DB    $8D,$8D,$8D
            ASC   "Insert a blank disk in "
            DB    $0
*
:MSG69      DB    $8D,$8D,$8D
            ASC   "Drive speed should be between 198.0 ms."
            DB    $8D
            ASC   "and 202.0 ms."
            DB    $8D,$8D
            ASC   "Drive speed is       ms."
            DB    $8D,$8D
            ASC   "([Esc]-Exit)"
            DB    $0
*
:MSG6A
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
:MSG6B      ASC   "   Use arrow keys to map other files  "
            DB    $0
*
:MSG6C      DB    $8D,$8D,$8D,$8D
            ASC   "No boot program to change"
            DB    $0
*
:MSG6D      DB    $8D,$8D,$8D
            ASC   "Disk II function only"
            DB    $8D,$0
*
:MSG6E      DB    $8D,$8D,$8D
            ASC   "Not a ProDOS function"
            DB    $8D,$0
*
:MSG6F      DB    $8D,$8D,$8D
            ASC   "Not a DOS 3.3 function"
            DB    $8D,$0
