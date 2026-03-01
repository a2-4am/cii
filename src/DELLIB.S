            TYP   BIN
            DSK   ../build/DELLIB.O
            PUT   VARS
            PUT   ../build/PHRWTS.VARS
            PUT   ../build/PRODOS.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/LINEINPUT.VARS
            PUT   ../build/ERRORS.VARS
            PUT   ../build/UILIB.VARS
            PUT   ../build/READLIB.VARS
            PUT   ../build/DISKLIB.VARS
            PUT   ../build/TREELIB.VARS
            PUT   ../build/CATLIB.VARS
            ORG   CATLIBEND
DELLIB
            ORG   *+3
            RTS

*******************************
*         DELETE LIBRARY      *
* DELETE - option entry point *
* FORMAT - option entry point *
* D1FILE - delete 1 file      *
* PDSTRY - destroy file via MLI*
* PUNLOK - unlock file via MLI*
* STINFO - set info via MLI   *
* GTINFO - get info via MLI   *
* INFLST - data for ST/GTINFO *
* DOMLI - MLI w/err           *
*private:                     *
* DDISK - delete disk (DOS+VTOC)*
* ZIPDOS - install DOS33 boot *
* PBOOT - ProDOS boot data    *
*******************************
*
DELETEINTERNAL
            JSR   TREELIB     ;decompress TREELIB module
            JSR   DISKLIB     ;decompress DISKLIB module
            LDA   CHOOZOPT
            BNE   :NOTFILZ
            JSR   COMTRE
            JMP   :DFILES
*
:NOTFILZ    JSR   COMHDR
            LDA   CHOOZOPT
            CMP   #$02
            BEQ   :DDOS
*
***********  DELETE DISK  **********
*
:DELDSK     JSR   :READY?
            BNE   :DDOUT
            JSR   DOSTYP      ;SETUP VOLNAM
            BMI   :DELPRO     ;PRODOS
*
* READ VTOC JUST TO MAKE SURE THAT
* IT IS REALLY A DOS DISK
*
* These two lines added 2/1/89
*
            LDA   #1
            STA   RCMND
*
            LDX   #>VTOC1
            JSR   DOVTOC
*
:DELPRO     JSR   DEVTYP
            CMP   #1
            BNE   :GODDSK     ;NOT /RAM
*
*
* DISCONNECT /RAM
*
            LDA   #$FF
            STA   ISAUX
            BNE   :DDDONE     ;ALWAYS
*
:DDOUT      RTS
:GODDSK     JSR   DDISK
:DDDONE     JSR   PRHERE
            DB    $8D,$8D
            ASC   "Disk"
            DB    $0
            JMP   :COMDEL
*
*
***********  DELETE DOS  ***********
*
:DDOS       LDA   DOSNOW
            BPL   :DOS33
            JMP   NOPRO
*
:DOS33      JSR   :READY?
            BNE   :DDOUT
            JSR   DOS?
            JSR   STVTOC
            LDA   #>CVTOC
            STA   RPAGE
            LDA   #$01
            STA   RCMND
            JSR   DORWTS
            LDA   #$FF
            JSR   SET1A2
            JSR   ZIPDOS      ;WRITE NO-BOOT
            JSR   PRHERE
            DB    $8D,$8D
            ASC   "DOS"
            DB    $0
:COMDEL     JSR   PRHERE
            ASC   " deleted"
            DB    $8D,$0
            JMP   PRESS
*
:READY?     JSR   PRHERE
            DB    $8D,$8D
            ASC   "Ready to delete (Y/N) ? "
            DB    $0
            JSR   KEYESC
            JSR   PCOUT
            CMP   #"Y"
            BNE   :READY3
            JSR   SETA
            JSR   PRVNM
            JSR   HOME
            LDA   #0
:READY3     RTS
*
*
*********  DELETE FILES  ***********
:DFILES     LDA   #$01
            STA   STATE       ;STATE=1
                              ;DISPLAY
            >>>   JSRMODULE,CATLIB;CATDIS
            JSR   PATMOV
            LDA   FILNUM      ;ANY FILES?
            BNE   :GOTFILS
            JMP   NOSEL
:GOTFILS    JSR   SWPCHK      ;SAME DISK?
            JSR   HOME
            LDY   #$00        ;INIT COUNTER
            STY   SP
            STY   CURR
:DFILELP    JSR   FILEQ
            JSR   CURPNT
            BIT   DOSNOW
            BPL   :SKIPCK     ;DOS 3.3
            LDY   #0
            LDA   (POINT),Y
            AND   #$F0
            CMP   #$D0
            BNE   :SKIPCK     ;NOT SUBDIR
            JSR   DIVEIN
            CLC
            JSR   DIVECK
            JSR   PRVNM
            JSR   SETPFX
            LDX   #$FF
            STX   CURR
            BNE   :DFIL1      ;ALWAYS
*
:SKIPCK     JSR   CURPNT
            LDA   #>TOP10     ;2/16/87
            JSR   SETHIM      ;2/16/87
            LDA   #$00        ;SET CATALOG1
            JSR   D1FILE      ;DELETE A FILE
            LDA   $C000
            CMP   #$9B
            BEQ   :ABORT
:DFIL1      INC   CURR
            LDA   CURR
            CMP   FILNUM
            BCC   :DFILELP
            BIT   DOSNOW
            BPL   :ABORT
            JSR   DIVOUT
            BCS   :ABORT
            LDA   SP
            BEQ   :DFIL2
            LDA   #0
            STA   CURR
:DFIL2      SEC
            JSR   DIVECK
            JSR   PRVNM
            JSR   SETPFX
            JSR   FILEQ
            JMP   :SKIPCK
*
:ABORT      BIT   DOSNOW
            BMI   :JDOWAIT    ;PRODOS
            JSR   WRCAT1      ;WRITE TRACK
:JDOWAIT    JMP   DOWAIT
*
********************************
*          FORMAT DISK         *
********************************
*
FORMATINTERNAL
            LDA   CHOOZOPT
            BEQ   :FPRODOS
            LDA   #$FF
:FPRODOS    EOR   #$FF
            STA   :TEMP
            STA   DOSNOW
            JSR   DODEVF
            >>>   JSRMODULE,TREELIB;COMH00
            LDA   UNIT
            JSR   SETSD
            JSR   DEVTYP
            BEQ   :ISRMV      ;IT'S A DISK II
*
:NOTDII     BIT   :TEMP
            BMI   :PRO1
            JMP   FLONLY
*
* NON-DISK II: CHECK IF REMOVABLE
*
:PRO1       TXA
            BPL   :NOTRMV
*
:ISRMV      JSR   PRHERE
            DB    $8D,$8D
            ASC   "Insert disk to format",8D,8D,00
            JMP   :COMRMV
*
:NOTRMV     JSR   PRHERE
            DB    $8D,$8D,$8D,$8D,$8D,$0
:COMRMV     JSR   PRHERE
            ASC   "Ready to format (Y/N) ? ",00
            JSR   CASKEY
            CMP   #"Y"        ;YES
            BNE   :GOFOUT
            JSR   HOME
*
* CHECK IF ALREADY FORMATTED
*
            >>>   JSRMODULE,DISKLIB;DOSTYP
            STX   :XTEMP
            BCS   :DOIT       ;UNREADABLE
            LDX   CURDEV
            LDY   DVICES,X
            CPY   #$BF
            BNE   :NOTRAM
            LDY   ISAUX
            BMI   :DOIT       ;DISCONNECTED
*
:NOTRAM     PHA
            JSR   PRHERE
            DB    $8D,$8D
            ASC   "Destroy "
            DB    $0
            PLA
            BMI   :CKIT1      ;PRODOS
:NONPRO     JSR   PRHERE
            ASC   "non-ProDOS volume? "
            DB    $0
            JMP   :CKIT2
*
:CKIT1      LDX   :XTEMP
            LDA   VOLNMS,X
            AND   #$0F        ;NAME LEN
            BEQ   :NONPRO
            TAY
            LDA   #"/"
            JSR   PCOUT
:CKITLP     INX
            LDA   VOLNMS,X
            ORA   #$80
            JSR   PCOUT
            DEY
            BNE   :CKITLP
            JSR   PRHERE
            ASC   " ? "
            DB    $0
:CKIT2      JSR   CASKEY
            CMP   #"Y"
            BEQ   :DOIT
:GOFOUT     RTS
*

:DOIT       JSR   HOME
            LDA   :TEMP
            STA   DOSNOW
            BPL   :DOITNOW    ;DOS 3.3
*
* PROMPT USER FOR VOLUME NAME, UNLESS
* THE DEVICE IS /RAM
*
            JSR   DEVTYP
            CMP   #1          ;/RAM?
            BEQ   :DOITNOW    ;YES
            JSR   GETVNM      ;GET VOL NAME
            BCS   :GOFOUT     ;ABORT
*
*
:DOITNOW    JSR   PRHERE
            DB    $8D,$8D,$8D
            ASC   "  Formatting disk",8D,8D,00
            JSR   DEVTYP
            BEQ   :DODSK2     ;DISK II
*
* NOT A DISK II DEVICE. DOES IT
* SUPPORT FORMATTING?
*
            TXA
            AND   #8          ;SUPPORT FMT?
            BEQ   :DVFMT1     ;NO: DONE
*
*
:DOSPCL     JSR   SPLFRM
            BCS   :DVFMTX     ;ERROR
            JSR   DEVTYP
            CMP   #1          ;/RAM?
            BNE   :DVFMT1     ;NOPE
            STA   ISAUX       ;1-->*ISAUX
            LDA   #0          ;Can't get MM anymore.
            STA   GOTMM
:DVFMT1     JMP   :FORMDN
*
:DVFMTX     JMP   ERROUT      ;FMT ERROR
*
*
:DODSK2     LDA   #$40        ;RATCHET!
            STA   RCMND       ;(SETS TRK 0)
            JSR   PHRWTS      ;DON'T CARE IF ERROR
            LDA   #$04        ;FORMAT COMMAND
            STA   RCMND
:FORMLP     JSR   PHRWTS      ;FORMAT TRK.
            BCC   :FORMOK     ;ERROR?
            LDA   RRTN        ;YES:
            CMP   #$2B        ;WP?
            BNE   :NOTWP
            JMP   OUCH
:NOTWP      LDA   #MERROR     ;NO:PRINT
            JSR   LOWMES      ;ERROR
            JSR   PRSPC
            JSR   PRTTRK
            JMP   PRESS       ;GO AWAY.
:TEMP       DB    $0
:XTEMP      DB    $0
*
:FORMOK     INC   RTRACK
            LDA   RTRACK      ;NEXT TRK
            CMP   #$23
            BCC   :FORMLP
*
:FORMDN     JSR   DDISK
:FORMDN1    JSR   PRHERE
            DB    $8D,$8D
            ASC   "Formatting complete",8D,00
            JMP   PRESS
*
* DELETE 1 FILE
* called by Delete operation
* and after failed Copy File operation
*
D1FILE      STA   :TEMP
            LDY   #$00
            LDA   (POINT),Y   ;MOVE TRACK #
            BIT   DOSNOW
            BMI   :DPRODOS
            JMP   :DDOS33
:D1FILEQ    RTS
*
:DPRODOS    PHA
            AND   #$F0
            STA   :TEMP
            PLA
            AND   #$0F        ;NAME LEN
            BEQ   :D1FILEQ    ;ALREADY DEL'D
            STA   (POINT),Y
            LDY   #$0F
:D1LOOP     LDA   (POINT),Y
            STA   FILE,Y
            DEY
            BPL   :D1LOOP
*
* SAVE INDEX BLOCK (IF SAPLING) AND
* MASTER INDEX BLOCK (IF TREE)
*
            LDY   #$11
            LDA   (POINT),Y
            STA   BLKNUM
            STA   :MIBNUM
            INY
            LDA   (POINT),Y
            STA   BLKNUM+1
            STA   :MIBNUM+1
            LDA   :TEMP
            CMP   #$20
            BEQ   :SAVSAP
            CMP   #$30
            BNE   :DODSTRY
            LDA   #>FILBUF
            STA   RPAGE
            JSR   RDBLK
            BCS   :SAVERR
            LDA   FILBUF
            STA   BLKNUM
            LDA   FILBUF+$100
            STA   BLKNUM+1
:SAVSAP     LDA   #>DESBUF
            STA   RPAGE
            JSR   RDBLK
            BCC   :DODSTRY
:SAVERR     LDA   #$10
            STA   :TEMP
:DODSTRY    JSR   PDSTRY
            LDA   :TEMP
            AND   #$EF
            CMP   #$20
            BNE   :RESOUT     ;NOT SAPLING OR TREE FILE
*
* COMPARE SAVED INDEX BLOCK TO INDEX BLOCK ON  DISK
* TO SEE HOW IT CHANGED. IF THE HIGH PART AND LOW
* PART HAVE BEEN SWITCHED, THEN  WE ARE RUNNING UNDER
* PRODOS 1.3 (OR ABOVE) AND WE ARE DONE.
*
* WE DON'T HAVE AN EXTRA BUFFER TO READ BLOCK FROM DISK
* INTO SO WE CAN COMPARE TO OLD BLOCK SITTING IN DESBUF.
* SO WE WILL JUST WRITE OLD BLOCK BACK (BACKWARDS) THEN,
* IF TREE FILE, DETERMINE THINGS.
*
* BLKNUM,+1 & RPAGE ARE STILL SET UP FOR INDEX BLOCK
*
            LDY   #>DESBUF
            JSR   SWAPIB      ;REVERSE IT
            JSR   WTBLK       ;WRITE FIRST INDEX BLOCK
            LDA   :TEMP
            CMP   #$30
            BNE   :RESOUT     ;NOT TREE FILE
*
* FIGURE OUT IF WE NEED TO REVERSE REST OF BLOCKS IN
* TREE FILE
*
* READ MIB OF DISK INTO DESBUF (NOW THAT DESBUF IS FREE)
* AND COMPARE TO OLD MIB IN FILBUF
*
            LDA   :MIBNUM
            STA   BLKNUM
            LDA   :MIBNUM+1
            STA   BLKNUM+1
            JSR   RDBLK
            BCS   :D1ERR
            LDY   #0
:TREELP     LDA   FILBUF+$100,Y
            CMP   DESBUF,Y
            BNE   :DOMORE
            INY
            BPL   :TREELP
*
* MUST BE RUNNING UNDER PRODOS 1.3 OR ABOVE, BECAUSE MIB WAS
* WRITTEN BACK BACKWARDS BY PRODOS.
*
:D1ERR      RTS
*
* WE MUST NOW REVERSE ALL OF THE FILES INDEX BLOCKS
*
:DOMORE     LDY   #>FILBUF
            STY   RPAGE
            JSR   SWAPIB      ;REVERSE MIB
            JSR   WTBLK       ;WRITE OUT REVERSED MIB
            LDY   #1          ;START AT 1 SINCE WE ALREADY
                              ;REVERSED FIRST INDEX BLOCK
            STY   :TEMP
:DOMORE1    LDY   :TEMP
            LDA   FILBUF+$100,Y
            STA   BLKNUM
            LDA   FILBUF,Y
            STA   BLKNUM+1
            ORA   BLKNUM
            BEQ   :DOMORE2    ;NULL ENTRY
            LDA   #>DESBUF
            STA   RPAGE
            JSR   RDBLK
            BCS   :RESOUT
            LDY   #>DESBUF
            JSR   SWAPIB
            JSR   WTBLK
            BCS   :RESOUT
:DOMORE2    INC   :TEMP
            BPL   :DOMORE1
:RESOUT     RTS
*
:DDOS33     STA   TRACK       ;TO END OF
            STA   RTRACK      ;FILENAME BUF
            LDY   #$20
            STA   (POINT),Y
            LDY   #$00
            LDA   #$FF        ;WRITE $FF AS
            STA   (POINT),Y   ;TRACK #
            INY
            LDA   (POINT),Y
            STA   SECTOR
            STA   RSECTR
            LDX   :TEMP
            LDA   :VTOCPAG,X  ;SET POINTERS
            STA   POINT+1     ;TO PROPER
            LDA   :TSLPAG,X   ;VTOC & TSLIST
            STA   POINT2+1
            STA   RPAGE
            LDY   #$00
            STY   POINT
            STY   POINT2
            INY
            STY   RCMND       ;1
            JSR   FREES       ;FREE TSLIST
:NXTSECT                      ;READ TSLIST
            >>>   JSRMODULE,DISKLIB;DORWTS
            LDY   #$0C
            STY   :COUNT
:NXTPAIR    LDY   :COUNT      ;LOOP THROUGH
            LDA   (POINT2),Y  ;NONZERO TS
            STA   TRACK       ;PAIRS FREEING
            INY
            ORA   (POINT2),Y  ;SECTORS
            BEQ   :NEXT
            LDA   (POINT2),Y
            STA   SECTOR
            JSR   FREES
:NEXT       INC   :COUNT
            INC   :COUNT
            BNE   :NXTPAIR
            LDY   #$01
            LDA   (POINT2),Y  ;GET POINTER
            STA   TRACK       ;TO NEXT TSLIST
            STA   RTRACK
            INY
            ORA   (POINT2),Y
            BEQ   :TSOUT      ;OUT IF ZERO
            LDA   (POINT2),Y
            STA   SECTOR
            STA   RSECTR
            JSR   FREES       ;FREE NEXT LIST
            JMP   :NXTSECT    ;BACK FOR MORE.
:TSOUT      RTS
:COUNT      DB    $0
:TEMP       DB    $0
:MIBNUM     DB    $0,$0
:VTOCPAG    DB    #>VTOC1
            DB    #>VTOC2
:TSLPAG     DB    #>SRCTSL
            DB    #>DSTTSL
*
* FREE A SECTOR ON *POINT - VTOC
* T&S IN *TRACK & *SECTOR
*
FREES       EQU   *
            LDA   TRACK
            ASL
            ASL
            ADC   #$38
            TAY
            LDA   SECTOR
            >>>   JSRMODULE,DISKLIB;DOMASK
            LDA   (POINT),Y
            ORA   BITMSK
            STA   (POINT),Y
            INY
            LDA   (POINT),Y
            ORA   BITMSK+1
            STA   (POINT),Y
            RTS
*
PDSTRY      JSR   PUNLOK
            JSR   DOMLI
            DB    $C1
            DW    :DESLST
            RTS
:DESLST     DB    $1
            DW    FILE
*
PUNLOK      EQU   *
            LDA   #$C3
            STA   :TEMP+1
            JSR   GTINFO
:TEMP       LDA   #1
            STA   INFLST+3
* FALL INTO STINFO
STINFO      LDA   #7
            STA   INFLST
            JSR   DOMLI
            DB    $C3
            DW    INFLST
            RTS
*
GTINFO      LDA   #$0A
            STA   INFLST
            JSR   DOMLI
            DB    $C4
            DW    INFLST
            RTS

INFLST      DB    $A
            DW    FILE
            DB    $0
            DB    $0
            DB    $0,$0
            DB    $0
            DB    $0,$0
            DB    $0,$0
            DB    $0,$0
            DB    $0,$0
            DB    $0,$0
*
* DO MLI COMMAND, WITH EXTRA HANDLING ON ERROR
*
DOMLI       PLA
            STA   :ADDR+1
            PLA
            STA   :ADDR+2
            LDY   #3
:ADDR       LDA   $1000,Y
            STA   :LIST-1,Y
            DEY
            BNE   :ADDR
            LDA   :LIST
            STA   LASTOP
            JSR   MLI
:LIST       DB    $0,$0,$0
            STA   RRTN
            BCS   MLIERR
            LDA   :ADDR+1
            CLC
            ADC   #4
            STA   :ADDR+1
            BCC   :SKIP
            INC   :ADDR+2
:SKIP       JMP   (:ADDR+$1)
LASTOP      DB    $0
*
*
MLIERR      EQU   *
            LDA   RRTN
            CMP   #$48        ;DISK FULL?
            BNE   :ERROU2     ;NOPE
*
* DELETE INCOMPLETELY COPIED FILE
*
            JSR   CLOSE       ;CLOSE IT
            LDA   #>FILE
            STA   POINT+1
            LDA   #FILE
            STA   POINT
            LDA   #1
            JSR   D1FILE
            >>>   JSRMODULE,DISKLIB;WRCAT2
            LDA   #$48
            JMP   ERROU1
:ERROU2     JMP   ERROUT
*
* DELETE DISK
*
DDISK       EQU   *
            BIT   DOSNOW
            BPL   :DDDOS33
            JMP   :PDDISK
*
:DDDOS33    LDA   #>CAT1
            JSR   CLRCAT
            LDA   #$00
            TAX
:BLAHLP     STA   VTOC1,X     ;ZERO VTOC
            INX
            BNE   :BLAHLP
            LDX   #$11        ;SET NEEDED
            STX   VTOC1+1     ;PARAMETERS
            STX   VTOC1+$30
            STX   RTRACK
            DEX               ;10
            STX   VTOC1+$35
            DEX               ;F
            STX   RSECTR
            STX   VTOC1+2
            LDA   #$FE
            STA   VTOC1+6
            LDA   #$7A
            STA   VTOC1+$27
            LDA   #$23
            STA   VTOC1+$34
            LDA   #$FF
            LDX   #$3C        ;START AT TRK 1
:FFLOOP     STA   VTOC1,X     ;WRITE PART
            STA   VTOC1+$1,X
            INX               ;OF BITMAPS
            INX
            INX
            INX
            CPX   #$C4
            BCC   :FFLOOP
            LDX   #$00
            STX   VTOC1+$7C   ;ZERO CATALOG
            STX   VTOC1+$7D   ;BITMAP
            INX               ;1
            STX   VTOC1+$31
            STX   VTOC1+$37
            INX               ;2
            STX   RCMND
            INX               ;3
            STX   VTOC1+3
            LDA   #>CAT1
            STA   RPAGE
:LOOP                         ;WRITE ENTIRE
            >>>   JSRMODULE,DISKLIB;DORWTS
            INC   RPAGE       ;TRACK
            DEC   RSECTR
            BNE   :LOOP
            LDA   #>VTOC1
            STA   RPAGE
            JSR   DORWTS
*            JMP   ZIPDOS
* FALL THROUGH TO ZIPDOS
*
* ZIPDOS - WRITE DOS 3.3 NO-BOOT SECTOR
*
ZIPDOS      EQU   *
            LDY   #$00
            LDA   $C083
:BOOTLP     LDA   D3NOBOOT,Y
            STA   DATA,Y
            INY
            BNE   :BOOTLP
            LDA   $C082
            STY   RTRACK      ;0
            STY   RSECTR
            INY
            STY   DATA        ;1
            LDA   #>DATA
            STA   RPAGE
            >>>   JMPMODULE,DISKLIB;DORWTS
*
* DELETE PRODOS DISK
*
* USED TO CREATE NEW DIRECTORY FOR
* FORMAT COMMAND AND FOR DELETE DISK
* COMMAND
*
:PDDISK     JSR   GTBLKS
            BCC   :PDD0
*
* IT'S SOME SORT OF /RAM. IF IT'S
* A LARGE ONE, FORMAT IT.
*
            CPY   #0
            BEQ   :NADA
            JMP   SPLFRM      ;FORMAT IT
:NADA       RTS
*
:PDD0       STX   :TOTBLK
            STY   :TOTBLK+1
*
* WRITE OUT BOOT BLOCK
*
            LDY   #0
            STY   BLKNUM
            STY   BLKNUM+1
:BOOTLP     LDA   PBOOT,Y
            STA   VTOC1,Y
            LDA   PBOOT+$100,Y
            STA   VTOC1+$100,Y
            INY
            BNE   :BOOTLP
            LDA   #>VTOC1
            STA   RPAGE
            STA   POINT+1
            JSR   DOWBLK
*
            LDA   #0
            STA   POINT
            JSR   PNTFIL
*
            LDA   #3
            STA   VTOC1+2
            LDA   #$C3
            STA   VTOC1+$22
            LDA   #$27
            STA   VTOC1+$23
            LDA   #$0D
            STA   VTOC1+$24
            LDA   #6
            STA   VTOC1+$27
            LDA   :TOTBLK+1
            STA   VTOC1+$2A
            LDA   :TOTBLK
            STA   VTOC1+$29
*
* STORE CREATION DATE AND TIME
*
            JSR   GETDAT
            LDY   #4
:CDTLP      LDA   CRTDAT-1,Y
            STA   VTOC1+$1B,Y
            DEY
            BNE   :CDTLP
*
:DLP2       LDA   VOLNAM,Y
            BEQ   :DLP2OUT
            STA   VTOC1+$5,Y
            INY
            BNE   :DLP2
*
:DLP2OUT    TYA
            ORA   #$F0
            STA   VTOC1+4
            LDA   #2
            STA   BLKNUM
            JSR   DOWBLK
*
            JSR   PNTFIL0
*
*
* WRITE OUT REST OF DIRECTORY
*
            LDA   #2
            STA   VTOC1
            ASL               ;2 --> 4
            STA   VTOC1+2
:D4LP       LDY   VTOC1
            INY
            STY   BLKNUM
            JSR   DOWBLK
            INC   VTOC1
            LDY   VTOC1+2
            BEQ   :D4OUT
            INY
            CPY   #6
            BNE   :D4LPA
            LDY   #0
:D4LPA      STY   VTOC1+2
            JMP   :D4LP
*
*
* WRITE OUT BITMAP
*
:D4OUT      LDA   #6
            STA   BLKNUM
:BMLP1      LDA   :TOTBLK+1
            SEC
            SBC   #$10
            BCC   :BM2
            STA   :TOTBLK+1
*
* WRITE A BLOCK OF FF'S
*
            LDA   #$FF
            JSR   PNTFIL
            JSR   :BMWBLK
            INC   BLKNUM
            BNE   :BMLP1
*
* WRITE OUT LAST BLOCK OF BITMAP
*
:BM2        JSR   PNTFIL0     ;RETURNS WITH Y=0
*LDY #0
:BM2LP      LDA   :TOTBLK+1
            BEQ   :BM3
            DEC   :TOTBLK+1
            LDX   #$20
            LDA   #$FF
:BM2LPB     STA   (POINT),Y
            INY
            BNE   :BM2Z
            INC   POINT+1
:BM2Z       DEX
            BNE   :BM2LPB
            BEQ   :BM2LP
*
:BM3        LDA   :TOTBLK
            SEC
            SBC   #8
            BCC   :BM4
            STA   :TOTBLK
            LDA   #$FF
            STA   (POINT),Y
            INY
            BNE   :BM3
            INC   POINT+1
            BNE   :BM3
*
:BM4        LDX   :TOTBLK
            LDA   :BITS,X
            STA   (POINT),Y
            JSR   :BMWBLK
*
* MARK USED BLOCKS IN BITMAP
*
            LDA   BLKNUM
            CMP   #6
            BEQ   :MARKDN     ;ONE BLK BM
            STA   :TEMP
            LDA   #6
            STA   BLKNUM
            LDA   #>VTOC1
            STA   BM
            JSR   RDBLK
            BCS   :ERROUT
:MARKIT     LDX   :TEMP       ;BLK LO
            LDA   #0          ;BLK HI
            JSR   MRKBLK
            DEC   :TEMP
            LDA   :TEMP
            CMP   #7
            BCS   :MARKIT
            >>>   JSRMODULE,DISKLIB;DOWBLK
:MARKDN     RTS
:ERROUT     JMP   ERROUT
*
:BMWBLK     LDA   BLKNUM
            CMP   #6
            BNE   :BMW1
*
* MARK BLOCKS 0 - 6 AS USED
*
            LDA   #$01
            STA   VTOC1
:BMW1       JMP   DOWBLK
*
:TOTBLK     DB    $0,$0
:TEMP       DB    $0
:BITS       DB    $00,$80,$C0,$E0,$F0,$F8,$FC,$FE
*
PNTFIL0     EQU   *
            LDA   #0
PNTFIL      EQU   *
            LDX   #2
            LDY   #0
:PFLP       STA   (POINT),Y
            INY
            BNE   :PFLP
            INC   POINT+1
            DEX
            BNE   :PFLP
            DEC   POINT+1
            DEC   POINT+1
            RTS
*
PBOOT       EQU   *
            PUTBIN  ../build/BOOTSEC.PRO.O
*
DELLIBEND
