            TYP   BIN
            DSK   ../build/MESSAGES2.O
            PUT   VARS
            PUT   ../build/PHRWTS.VARS
            ORG   PHRWTSEND
MESSAGES2
            ORG   *+3
            RTS

XEFGOESC    ASC   "[E]nter"
            DB    $8D
XFNGOESC    ASC   "filename, [G]o, "
            DB    MESCEXIT
XESCEXIT    ASC   "[Esc]-Exit "
            DB    $0
XPSTATE0    ASC   "[Return]-Mark file, [U]nmark, [E]nter"
            DB    $8D
            ASC   "filename, Number-Insert, [G]o,"
            DB    $8D,MESCEXIT
XPSTATE1    ASC   "[Return]-Toggle marker, "
            DB    MEFGOESC
XPSTATE2    ASC   "[Return]-Toggle asterisk, "
            DB    MEFGOESC
XPSTATE3    ASC   "(Renamed files are marked)"
            DB    $8D
            ASC   "[Return]-Select to rename, "
            DB    MEFGOESC
XPSTAT45    ASC   "[E]nter "
            DB    MFNGOESC
*
XERR2B      ASC   "Disk is write-protected"
            DB    $0
XERR44      ASC   "Path not found"
            DB    $0
XERR45      ASC   "Volume not online"
            DB    $0
XERR48      ASC   "Disk full"
            DB    $0
XERR49      ASC   "Directory full"
            DB    $0
XERR4E      ASC   "Can not delete non-empty sub"
            DB    MDIR
XERR3F      ASC   "Subdirectory not found"
            DB    $0
XERR52      ASC   "Not a ProDOS or DOS 3.3 disk"
            DB    $0
XERR47      ASC   "Subdirectory already exists"
            DB    $0
XERR2F      ASC   "No disk in drive"
            DB    $0
XINROOT     ASC   "Already in root "
            DB    MDIR
XNOTSUB     ASC   "Not a sub"
            DB    MDIR
XMTSUB      ASC   "Empty sub"
            DB    MDIR
XTOOLONG    DB    $8D,$8D
XTOOLNG0    ASC   "Prefix too long"
            DB    $8D,$0
*
XBLANK4     DB    $FF,$8D
XBLANK3     DB    $FF,$8D,$FF,$8D,$FF
            DB    $0
*
XSLOT       ASC   "Slot "
            DB    $0
*
XFILE       ASC   "File"
            DB    $0
*
XTRACK      ASC   "Track $"
            DB    $0
XSECTOR     ASC   "Sector $"
            DB    $0
XCRESC1     DB    $8D
XCRESC      ASC   "[Return]-Continue, "
            DB    MESCEXIT
*
XNOFILES    DB    $8D
            ASC   "No files"
            DB    $8D
            DB    $0
*
XERROR      ASC   "Error"
            DB    $0
*
XREAD       ASC   "Read"
            DB    $0
XWRITE      ASC   "Write"
            DB    $0
XPRESS      DB    $8D
XPRESS1     ASC   "Press [Return] "
            DB    $0
*
MESSAGES2END
