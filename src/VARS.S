*
* Constants:
*
CIIPVER     =     $85         ;version 8.5
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
* 80 - 90 ALSO USED IN PHRWTS
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
TERROR      =     $A7
ISAUX       =     $A8
A2E         =     $A9
*
FIRSTC      =     $AC
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
RPSLOT      =     $F8
RPDRIV      =     $F9
* ZXMODULE uses $FA,$FB,$FC,$FD,$FE,$FF
HSLOT       =     $F0
HDRIVE      =     $F1
*
*
*
LINEIN      =     $200
IN20        =     $220
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
SCREEN      =     $5A2
*
            DUM   $800
CVTOC       DS    $100        ;800
STATUS      DS    $100        ;900
CBYTE       DS    $100        ;A00
CSECTR      DS    $100        ;B00
*
FILBUF      =     *           ;C00
DSTTSL      DS    $200        ;C00
DESBUF      DS    $200        ;E00  used in DESTROY FILE
SMIB        DS    $200
RBLKL       =     SMIB+$0081
RBLKH       =     SMIB+$0181
SIB         DS    $200
SRCTSL      =     SIB
VTOC1       =     SRCTSL+$100
CAT1        DS    $F00
SDIR        =     CAT1
DOSDAT      =     *
BMDATA      =     SDIR+$800   ;1C00 - variable buffer for bitmap, which
                              ; can take up to $2000 bytes for giant disks
DATA        =     SDIR+$2800
DATPAG      =     DATA+$100
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
MENUTSZ     EQU   $1C
ZXMODSZ     EQU   $32
ZXUNPSZ     EQU   $13B
*
TOPMEM      =     CODEADR-$300  ;$300 for VOLNMS, PRIM, SECOND, etc.
VOLNMS      =     TOPMEM
TRKBUF      =     TOPMEM-$5000
TOP40       =     TOPMEM-$4000
TOP30       =     TOPMEM-$3000
TOP11       =     TOPMEM-$1100
TOP10       =     TOPMEM-$1000
*
            DUM   TOP10
VTOC2       DS    $100
VTRACK      =     VTOC2+$30
VDIR        =     VTOC2+$31
NSECTS      =     VTOC2+$35
CAT2        DS    $F00
            DEND
*
MMIOBUF     =     TOP10       ;ProDOS buffer for MM
MMSPOT      =     MMIOBUF+$400  ;MM code sits after MM ProDOS buffer
*
*-------------------
AUXMM       =     $0800       ;MM's home in aux memory
*-------------------
*
            DUM   CODEADR-$200
PRIM        DS    $100
SECOND      DS    $57
VOLNAM      DS    $10
BTPFX       DS    $50
ASYNC       DS    1           ;# OF SYNC TO WRITE
*
AINFO       DS    0           ;PHRWTS stuff:
ADRCSUM     DS    1
ADRSEC      DS    1
ADRTRK      DS    1
ADRVOL      DS    1
*
DSYNC       DS    1
DRES        DS    1           ;Data checksum result
AUXFLG      DS    1           ;Read/write aux mem?
TRKFLG      DS    1           ;Check track
*
SOFAR       DS    $10
INTRLV      DS    $10
INTLV1      DS    $10
*SECS        DS    $10        ;now in PHRWTS
ZXMODULE    DS    ZXMODSZ
ZXUNPACK    DS    ZXUNPSZ
MENUTBL     DS    MENUTSZ
JDDISK      DS    3
JD1FILE     DS    3
JDOTREE     DS    3
JDODEV      DS    3
JMATCH      DS    3
JCATLN1     DS    3
            DS    $0B         ;free space here
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
