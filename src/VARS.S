*
* Constants:
*
CIIRVER     =     $10         ;version 1.0
*
* Memory equates:
*
*  WARNING: ENHANCED APPLE //C CHANGES LOCATIONS
*           $00 - $08 AT RESET
*  MUST MAKE SURE VARIABLES AT $00 - $08 ARE NOT
*  NEEDED AFTER RESET
*
LINLIM      =     $00
CURR        =     $01
CURRV       =     $02
LASTM       =     $03
POINT2      =     $04         ;4-5
CURDOS      =     $06
DOSNOW      =     $07
GO          =     $08
ONLY1       =     $09
SHOW        =     $0A
MESPNT      =     $0B         ;2
POINT       =     $0D         ;2
STATE       =     $0F
NACTIV      =     $10
DELFLG      =     $11
HEXNUM      =     $12         ;3
*PRNTR?      =     $15
SECTOR      =     $16
CPYDIG      =     $17         ;3 Insert-digits in COPY FILES display.
* RAMFactor incorrectly uses zp location $19 during Smartport
*  status call. My MM code stuffs $19 to make it work. Make
*  sure $19 remains a temporary location.
FILNUM      =     $1A
*PSLOT       =     $1B
BITMSK      =     $1C         ;2
TRACK       =     $1E
*
WNDLFT      =     $20
WNDWTH      =     $21
WNDTOP      =     $22
WNDBTM      =     $23
CH          =     $24
CV          =     $25
BASL        =     $28
YSAV        =     $34
CSWL        =     $36
A1L         =     $3C
A1H         =     $3D
A2L         =     $3E
A2H         =     $3F
A4L         =     $42
A4H         =     $43
*
IRQSAV      =     $50         ;IN AUX ZP
*
FILELN      =     $50         ;50-52
ACCESS      =     $53
DATADR      =     $54
SP          =     $55
*
* New (10/6/87) for MM:
FMT400K     =     $56
* A Smartport call on GS clobbers locations $57 - $5A.
*  Avoid 'em!
SLOTPTR     =     $5B         ;2
TEMPCNT     =     $5B         ;2 same as SLOTPTR
HANDLE      =     $5D         ;4
GOTMM       =     $61
MMISOPEN    =     $62
*
USEDL       =     $66
USEDH       =     $68
FREEL       =     $6A
FREEH       =     $6C
*
DIGIT       =     $6F         ;6F - 76
*
FLAG80      =     $77
PFXADR      =     $78         ;2
PINVFL      =     $7A
*
* 80 - 8F ALSO USED IN PHRWTS
*
CURMOM      =     $80
BLKPTR      =     $81
SISPTR      =     $82
YCUR        =     $83
XCUR        =     $84
XSTART      =     $85
YSTART      =     $86
XPOS        =     $87
YPOS        =     $88
END         =     $89
XMAX        =     $8A
DSPNUM      =     $8B
CHMAX       =     $8C
*
COUNT       =     $A6
CHOOZOPT    =     $A7         ;[4am] reuse unused address to store chosen menu index
ISAUX       =     $A8
A2E         =     $A9
*
TEMP        =     $B3
TEMP2       =     $B4
DIRBLK      =     $B5         ;2
DIRADR      =     $B7         ;1
BM          =     $B8         ;1
BLKNUM      =     $B9         ;2
UNIT        =     $BB         ;1
BOOTDV      =     $BC
CURDEV      =     $BD
VOLFLG      =     $BE
NUMDEV      =     $BF
DVICES      =     $C0         ;C0 - CF
PNADDR      =     $D0         ;D0 - D1
CURDVP      =     $D2
CURDVS      =     $D3
PUNIT       =     $D4
SUNIT       =     $D5
PDOS        =     $D6
SDOS        =     $D7
CURDVA      =     $D8
*
STSP        =     $D9
HIMEM       =     $DA
MIBPTR      =     $DB
RELCNT      =     $DC
IBPTR       =     $DD
TSLCTR      =     $DE         ;2
MODDAT      =     $E0         ;2
MODTIM      =     $E2         ;2
EOF         =     $E4
TOPDIF      =     $E5
ACURR       =     $E6
PCURR       =     $E7
SCURR       =     $E8
TMPPTR      =     $E9         ;2
* ZXMODULE uses $EB,$EC,$ED,$EE,$EF
*
* RWTS PARAMETERS
*
RSLOT       =     $F0
RDRIVE      =     $F1
RTRACK      =     $F2
RSECTR      =     $F3
RADR        =     $F4
RPAGE       =     $F5
RCMND       =     $F6
RRTN        =     $F7
RPSLOT      =     $F8         ;must be within $16 of ACURR
                              ;due to optimizations in LOADER
RPDRIV      =     $F9
* ZXMODULE uses $FA,$FB,$FC,$FD,$FE,$FF
HSLOT       =     $F0
HDRIVE      =     $F1
*
*
SOFAR       =     $110        ;110-11F
VOLNAM      =     $120        ;120-12F
*
LINEIN      =     $200
*
STACKX      =     $240        ;240-255
STACKY      =     $256        ;256-26A
CURSTK      =     $26B        ;26B-27F
FILNAM      =     $280        ;280-29F
FILE        =     $2A0        ;2A0-2BF
PFX         =     $2C0        ;2C0-301
PPFX        =     $302        ;302-343
SPFX        =     $344        ;344-385
APFX        =     $386        ;386-3C7
FTYPE       =     $3C8
AUXTYP      =     $3C9
CRTDAT      =     $3CB
CRTTIM      =     $3CD
STRTYP      =     $3CF
*
* PRODOS RESERVES 3D0 - 3FF
*
* SIDER FIRMWARE PUTS A $4C AT $3D0
*
* 3D6 - 3EB RESERVED FOR PRODOS
*           RAM-BASED DRIVERS
*
* $3F0=APPLEVECTORS
*
SCREEN      =     $5A2        ;6 bytes, used by VIEW
*
            DUM   $900
STATUS      DS    $100        ;900
CBYTE       DS    $100        ;A00
CSECTR      DS    $100        ;B00
*
FILBUF      =     *           ;C00
DSTTSL      DS    $200        ;C00
DESBUF      DS    $200        ;E00  used in DESTROY FILE
SMIB        DS    $200        ;1000
RBLKL       =     SMIB+$0081
RBLKH       =     SMIB+$0181
SIB         DS    $200        ;1200
SRCTSL      =     SIB
VTOC1       =     SRCTSL+$100 ;1300
CAT1        DS    $F00        ;1400
SDIR        =     CAT1        ;1400
                              ;/!\ must be aligned on even page boundary
                              ;due to 'AND #$FE' logic in FIXSUB
DOSDAT      =     *
BMDATA      =     SDIR+$800   ;2900 - variable buffer for bitmap, which
                              ; can take up to $2000 bytes for giant disks
DATA        =     SDIR+$2800  ;4900
DATPAG      =     DATA+$100   ;4A00
            DEND
*
*
*-------------------------------------
*
* THESE NEXT FEW BUFFERS ARE USED ONLY
* IN GENERATING THE SUBDIRECTORY TREE
* DISPLAY
*
            DUM   DATA
MOM         DS    $100
KITTEN      DS    $100
PREV        DS    $100
SIS         DS    $100
SDBLKL      DS    $100
SDBLKH      DS    $100
XS          DS    $100
YS          DS    $100
SDNAME      DS    $100
            DEND
*
*-------------------------------------
* Working backwards from program itself::
*
CODEADR     =     $5B00       ;<----
*
MENUTSZ     EQU   $1E
ZXMODSZ     EQU   $32
ZXUNPSZ     EQU   $13B
*
TOPMEM      =     CODEADR-$300 ;5800 - permanently reserve $300 for VOLNMS, PRIM, SECOND, etc.
VOLNMS      =     TOPMEM      ;5800 - $100 bytes
                              ;Used by 'display volume names' in device selection.
                              ;Also used by DOSTYP.
                              ;May also be used in Copy Files to verify the
                              ;correct disk is in the drive after swapping.
                              ;May also be used in Format Disk when formatting
                              ;an already-formatted ProDOS disk.
CVTOC       =     TOPMEM      ;5800 - $100 bytes
                              ;Used by Copy DOS
                              ;Used by Delete DOS
                              ;Used by SWCK which is called by INSS and INSD
                              ;which are called by many 1-drive operations
                              ;including Copy Files to verify the correct disk
                              ;is in the drive after swapping.
                              ;However it is not used by Copy Disk.
TRKBUF      =     TOPMEM-$5000 ;800
TOP40       =     TOPMEM-$4000 ;1800
TOP30       =     TOPMEM-$3000 ;2800
TOP11       =     TOPMEM-$1100 ;4700
TOP10       =     TOPMEM-$1000 ;4800
*
            DUM   TOP10
VTOC2       DS    $100        ;4800
VTRACK      =     VTOC2+$30   ;4830
VDIR        =     VTOC2+$31   ;4831
NSECTS      =     VTOC2+$35   ;4835
CAT2        DS    $F00        ;4900-57FF
            DEND
*
MMIOBUF     =     TOP10       ;4800 - $400 byte ProDOS buffer for MM
MMSPOT      =     MMIOBUF+$400 ;4C00 - MM code sits after MM ProDOS buffer
*
*-------------------
AUXMM       =     $0800       ;Memory Manager home (in aux memory)
D3NOBOOT    =     $D000       ;DOS 3.3 no-boot sector data (in LC RAM bank 2)
*-------------------
*
            DUM   CODEADR-$200
PRIM        DS    $100        ;used by PHRWTS during write
SECOND      DS    $57         ;used by PHRWTS during write
ASYNC       DS    1           ;# OF SYNC TO WRITE
*
AINFO       DS    0           ;PHRWTS stuff:
ADRCSUM     DS    1
ADRSEC      DS    1
ADRTRK      DS    1
ADRVOL      DS    1
*
DSYNC       DS    1
*
ZXMODULE    DS    ZXMODSZ
ZXUNPACK    DS    ZXUNPSZ
MENUTBL     DS    MENUTSZ
*
* entry points for functions inside
* compressed libraries
*
PHRWTS      DS    6
RDDRIVE     DS    6
FAKTRK      DS    6
DELETE      DS    6
FORMAT      DS    6
D1FILE      DS    6
JDOTREE     DS    3
JDODEV      DS    3
CATLN1      DS    6
CATDIS      DS    6
CDDOKEY     DS    6
FILEQ       DS    6
UNMARK      DS    6
DIVOUT      DS    6
DIVEIN      DS    6
INITCD      DS    6
RDACNT      DS    6
MAKESUB     DS    6
SETCLOCK    DS    6
BOOTPG      DS    6
VIEW        DS    6
ALPHA       DS    6
RENAME      DS    6
LOCK        DS    6
            DS    $24 ;free space here
*
* PHRWTS tables (now built in LOADER)
*
RDTR62      DS    $6A
MIX1ST      DS    $40
MIX2ND      DS    $40
MIX3RD      DS    $40
WRTRANS     DS    $40
PHRWTSADR   DS    1
            DEND
WAITBL2     =     RDTR62+$2A
            ERR   {RDTR62&$FF}-$96
            DEND
*
*
* ProDOS global page stuff:
MLI         =     $BF00
JCLOCK      =     $BF06
DEVADR      =     $BF10
DEVNUM      =     $BF30
DEVCNT      =     $BF31
DEVLST      =     $BF32
MEMTABL     =     $BF58
DATE        =     $BF90
TIME        =     $BF92
LEVEL       =     $BF94
MACHID      =     $BF98
IVERSION    =     $BFFD
KVERSION    =     $BFFF
*
* Hardware equates:
KBD         =     $C000
KBDSTB      =     $C010
*
* Monitor routines:
AUXMOVE     =     $C311
PRBL2       =     $F94A
INIT        =     $FB2F
SETTXT      =     $FB39
TABV        =     $FB5B
HOME        =     $FC58
CLREOL      =     $FC9C
WAIT        =     $FCA8
RDKEY       =     $FD0C
CROUT       =     $FD8E
COUT        =     $FDED
SETNOR      =     $FE84
SETKBD      =     $FE89
SETVID      =     $FE93
BELL        =     $FF3A
*
* Commands for MMCMD:
MMOPEN      EQU   0
MMREAD      EQU   1
MMWRITE     EQU   2
MMCLOSE     EQU   3
MMCHECK     EQU   4
*
* Additional error numbers for MMERRNUM:
OPENERR     EQU   $80         ;MM already open.
SIZEERR     EQU   $81         ;Request exceeds end of memory.
TRANSERR    EQU   $82         ;Not all requested bytes were transferred.
HNDERR      EQU   $83         ;Handle in zero page invalid (overwritten!)
NOMEMERR    EQU   $84         ;No memory found in OPEN call.
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
MHEADER     DS    1
MDASH17     DS    1
MDASHES     DS    1
MDIR        DS    1
MMORE       DS    1
*
* Remaining messages are stored in MESSAGES2 compressed module.
* Messages IDs continue sequentially. PRINT routine takes care of
* decompressing the module when necessary.
*
MSG2START   DS    0
*
MEFGOESC    DS    1
MFNGOESC    DS    1
MESCEXIT    DS    1
*
MTOOLONG    DS    1
MTOOLNG0    DS    1
MNOTSUB     DS    1
MNOFILES    DS    1
MMTSUB      DS    1
MINROOT     DS    1
*
* READ and WRITE messages are enumerated
* (WRITE must be READ+1)
MREAD       DS    1
MWRITE      DS    1
*
MBLANK4     DS    1
MBLANK3     DS    1
MSLOT       DS    1
MPRESS1     DS    1
MFILE       DS    1
*
* PSTATE messages are enumerated
MPSTATE0    DS    1
MPSTATE1    DS    1
MPSTATE2    DS    1
MPSTATE3    DS    1
MPSTAT45    DS    1
            DS    1
*
MTRACK      DS    1
MSECTOR     DS    1
MCRESC      DS    1
MCRESC1     DS    1
MERROR      DS    1
MPRESS      DS    1
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
