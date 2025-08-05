*
*
* DELETE
* FORMAT
* VIEW
* MAKE DIRECTORY
*
*
*
*******************************
*         DELETE              *
*******************************
*
DELETE   LDX   #$02
         JSR   CHOOZ1     ;DOS, DISK,
         STA   :TEMP      ;OR FILES?
         CMP   #0
         BNE   :NOTFILZ
         JSR   COMTRE
         JMP   :DFILES
*
:NOTFILZ JSR   COMHDR
         LDA   :TEMP
         CMP   #$02
         BEQ   :DDOS
*
***********  DELETE DISK  **********
*
*

:DELDSK  JSR   :READY?
         BNE   :DDOUT
         JSR   DOSTYP     ;SETUP VOLNAM
         BMI   :DELPRO    ;PRODOS
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
:DELPRO  JSR   DEVTYP
         CMP   #1
         BNE   :GODDSK    ;NOT /RAM
*
*
* DISCONNECT /RAM
*
         LDA   #$FF
         STA   ISAUX
         BNE   :DDDONE    ;ALWAYS
*
:DDOUT   RTS
:GODDSK  JSR   DDISK
:DDDONE  JSR   PRHERE
         ASC   "\\Disk"
         DB    $0
         JMP   :COMDEL
*
*
***********  DELETE DOS  ***********
*
:DDOS    LDA   DOSNOW
         BPL   :DOS33
         JMP   NOPRO
*
:DOS33   JSR   :READY?
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
         JSR   ZIPDOS     ;WRITE NO-BOOT
         JSR   PRHERE
         ASC   "\\DOS"
         DB    $0
:COMDEL  JSR   PRHERE
         ASC   " deleted\"
         DB    $0
         JMP   PRESS
*
*
*
:TEMP    DB    $0
*
*
:READY?  JSR   PRHERE
         ASC   "\\Ready to delete (Y/N) ? "
         DB    $0
         JSR   KEYESC
         JSR   PCOUT
         CMP   #"Y"
         BNE   :READY3
         JSR   SETA
         JSR   PRVNM
         JSR   HOME
         LDA   #0
:READY3  RTS
*
*
*********  DELETE FILES  ***********
:DFILES  LDA   #$01
         STA   STATE      ;STATE=1
         JSR   CATDIS     ;DISPLAY
         JSR   PATMOV
         LDA   FILNUM     ;ANY FILES?
         BNE   :GOTFILS
         JMP   NOSEL
:GOTFILS JSR   SWPCHK     ;SAME DISK?
         JSR   HOME
         LDY   #$00       ;INIT COUNTER
         STY   SP
         STY   CURR
:DFILELP JSR   FILEQ
         JSR   CURPNT
         BIT   DOSNOW
         BPL   :SKIPCK    ;DOS 3.3
         LDY   #0
         LDA   (POINT),Y
         AND   #$F0
         CMP   #$D0
         BNE   :SKIPCK    ;NOT SUBDIR
         JSR   DIVEIN
         CLC
         JSR   DIVECK
         JSR   PRVNM
         JSR   SETPFX
         LDX   #$FF
         STX   CURR
         BNE   :DFIL1     ;ALWAYS
*
:SKIPCK  JSR   CURPNT
         LDA   #>TOP10    ;2/16/87
         JSR   SETHIM     ;2/16/87
         LDA   #$00       ;SET CATALOG1
         JSR   D1FILE     ;DELETE A FILE
         LDA   $C000
         CMP   #$9B
         BEQ   :ABORT
:DFIL1   INC   CURR
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
:DFIL2   SEC
         JSR   DIVECK
         JSR   PRVNM
         JSR   SETPFX
         JSR   FILEQ
         JMP   :SKIPCK
*
:ABORT   BIT   DOSNOW
         BMI   DOWAIT     ;PRODOS
         JSR   WRCAT1     ;WRITE TRACK
DOWAIT   LDX   #$03
:WAITLP  LDA   #$C4
         JSR   WAIT
         DEX
         BNE   :WAITLP
D1OUT    RTS
*
*
* DELETE A FILE
*
D1FILE   STA   :TEMP
         LDY   #$00
         LDA   (POINT),Y  ;MOVE TRACK #
         BIT   DOSNOW
         BMI   :PRODOS
         JMP   :DOS33
*
:PRODOS  PHA
         AND   #$F0
         STA   :TEMP
         PLA
         AND   #$0F       ;NAME LEN
         BEQ   D1OUT      ;ALREADY DEL'D
         STA   (POINT),Y
         LDY   #$0F
:D1LOOP  LDA   (POINT),Y
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
:SAVSAP  LDA   #>DESBUF
         STA   RPAGE
         JSR   RDBLK
         BCC   :DODSTRY
:SAVERR  LDA   #$10
         STA   :TEMP
:DODSTRY JSR   PDSTRY
         LDA   :TEMP
         AND   #$EF
         CMP   #$20
         BNE   :RESOUT    ;NOT SAPLING OR TREE FILE
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
         JSR   SWAPIB     ;REVERSE IT
         JSR   WTBLK      ;WRITE FIRST INDEX BLOCK
         LDA   :TEMP
         CMP   #$30
         BNE   :RESOUT    ;NOT TREE FILE
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
         BCS   :ERR
         LDY   #0
:TREELP  LDA   FILBUF+$100,Y
         CMP   DESBUF,Y
         BNE   :DOMORE
         INY
         BPL   :TREELP
*
* MUST BE RUNNING UNDER PRODOS 1.3 OR ABOVE, BECAUSE MIB WAS
* WRITTEN BACK BACKWARDS BY PRODOS.
*
:ERR     RTS

*
* WE MUST NOW REVERSE ALL OF THE FILES INDEX BLOCKS
*
:DOMORE  LDY   #>FILBUF
         STY   RPAGE
         JSR   SWAPIB     ;REVERSE MIB
         JSR   WTBLK      ;WRITE OUT REVERSED MIB
         LDY   #1         ;START AT 1 SINCE WE ALREADY
                          ;REVERSED FIRST INDEX BLOCK
         STY   :TEMP
:DOMORE1 LDY   :TEMP
         LDA   FILBUF+$100,Y
         STA   BLKNUM
         LDA   FILBUF,Y
         STA   BLKNUM+1
         ORA   BLKNUM
         BEQ   :DOMORE2   ;NULL ENTRY
         LDA   #>DESBUF
         STA   RPAGE
         JSR   RDBLK
         BCS   :RESOUT
         LDY   #>DESBUF
         JSR   SWAPIB
         JSR   WTBLK
         BCS   :RESOUT
:DOMORE2 INC   :TEMP
         BPL   :DOMORE1
:RESOUT  RTS
*
*
*
:DOS33   STA   TRACK      ;TO END OF
         STA   RTRACK     ;FILENAME BUF
         LDY   #$20
         STA   (POINT),Y
         LDY   #$00
         LDA   #$FF       ;WRITE $FF AS
         STA   (POINT),Y  ;TRACK #
         INY
         LDA   (POINT),Y
         STA   SECTOR
         STA   RSECTR
         LDX   :TEMP
         LDA   :VTOCPAG,X ;SET POINTERS
         STA   POINT+1    ;TO PROPER
         LDA   :TSLPAG,X  ;VTOC & TSLIST
         STA   POINT2+1
         STA   RPAGE
         LDY   #$00
         STY   POINT
         STY   POINT2
         INY
         STY   RCMND      ;1
         JSR   FREES      ;FREE TSLIST
:NXTSECT JSR   DORWTS     ;READ TSLIST
         LDY   #$0C
         STY   :COUNT
:NXTPAIR LDY   :COUNT     ;LOOP THROUGH
         LDA   (POINT2),Y ;NONZERO TS
         STA   TRACK      ;PAIRS FREEING
         INY
         ORA   (POINT2),Y ;SECTORS
         BEQ   :NEXT
         LDA   (POINT2),Y
         STA   SECTOR
         JSR   FREES
:NEXT    INC   :COUNT
         INC   :COUNT
         BNE   :NXTPAIR
         LDY   #$01
         LDA   (POINT2),Y ;GET POINTER
         STA   TRACK      ;TO NEXT TSLIST
         STA   RTRACK
         INY
         ORA   (POINT2),Y
         BEQ   :TSOUT     ;OUT IF ZERO
         LDA   (POINT2),Y
         STA   SECTOR
         STA   RSECTR
         JSR   FREES      ;FREE NEXT LIST
         JMP   :NXTSECT   ;BACK FOR MORE.
:TSOUT   RTS
:COUNT   DB    $0
:TEMP    DB    $0
:MIBNUM  DB    $0,$0
*
*  KEEP AN EYE ON THESE! <--
*VTOCPAG DB    $13,$4A    ;VTOC1,VTOC2
*TSLPAG  DB    $12,$0C    ;SRCTSL,DSTTSL
:VTOCPAG DB    #>VTOC1
         DB    #>VTOC2
:TSLPAG  DB    #>SRCTSL
         DB    #>DSTTSL
*
*
********************************
*          FORMAT DISK         *
********************************
*
FORMAT   LDX   #7
         JSR   CHOOZ1     ;DOS OR PRODOS
         CMP   #0
         BEQ   :PRODOS
         LDA   #$FF
:PRODOS  EOR   #$FF
         STA   :TEMP
         STA   DOSNOW
         JSR   DODEVF
         JSR   COMH00
         LDA   UNIT
         JSR   SETSD
         JSR   DEVTYP
         BEQ   :ISRMV     ;IT'S A DISK II
*
:NOTDII  BIT   :TEMP
         BMI   :PRO1
         JMP   FLONLY
*
* NON-DISK II: CHECK IF REMOVABLE
*
:PRO1    TXA
         BPL   :NOTRMV
*
:ISRMV   LDA   #$62
         JSR   PRINT
         JMP   :COMRMV
*
:NOTRMV  JSR   PRHERE
         ASC   "\\\\\"
         DB    $0
:COMRMV  LDA   #$63       ;READY?
         JSR   PRINT
         JSR   CASKEY
         CMP   #"Y"       ;YES
         BNE   :GOFOUT
         JSR   HOME
*
* CHECK IF ALREADY FORMATTED
*
         JSR   DOSTYP
         STX   :XTEMP
         BCS   :DOIT      ;UNREADABLE
         LDX   CURDEV
         LDY   DVICES,X
         CPY   #$BF
         BNE   :NOTRAM
         LDY   ISAUX
         BMI   :DOIT      ;DISCONNECTED
*
:NOTRAM  PHA
         JSR   PRHERE
         ASC   "\\Destroy "
         DB    $0
         PLA
         BMI   :CKIT1     ;PRODOS
:NONPRO  JSR   PRHERE
         ASC   "non-ProDOS volume? "
         DB    $0
         JMP   :CKIT2
*
:CKIT1   LDX   :XTEMP
         LDA   VOLNMS,X
         AND   #$0F       ;NAME LEN
         BEQ   :NONPRO
         TAY
         LDA   #"/"
         JSR   PCOUT
:CKITLP  INX
         LDA   VOLNMS,X
         ORA   #$80
         JSR   PCOUT
         DEY
         BNE   :CKITLP
         JSR   PRHERE
         ASC   " ? "
         DB    $0
:CKIT2   JSR   CASKEY
         CMP   #"Y"
         BEQ   :DOIT
:GOFOUT  RTS
*

:DOIT    JSR   HOME
         LDA   :TEMP
         STA   DOSNOW
         BPL   :DOITNOW   ;DOS 3.3
*
* PROMPT USER FOR VOLUME NAME, UNLESS
* THE DEVICE IS /RAM
*
         JSR   DEVTYP
         CMP   #1         ;/RAM?
         BEQ   :DOITNOW   ;YES
         JSR   GETVOL     ;GET VOL NAME
         BCS   :GOFOUT    ;ABORT
*
*
:DOITNOW LDA   #$64
         JSR   PRINT
         JSR   DEVTYP
         BEQ   :DODSK2    ;DISK II
*
* NOT A DISK II DEVICE. DOES IT
* SUPPORT FORMATTING?
*
         TXA
         AND   #8         ;SUPPORT FMT?
         BEQ   :DVFMT1    ;NO: DONE
*
*
:DOSPCL  JSR   SPLFRM
         BCS   :DVFMTX    ;ERROR
         JSR   DEVTYP
         CMP   #1         ;/RAM?
         BNE   :DVFMT1    ;NOPE
         STA   ISAUX      ;1-->*ISAUX
         LDA   #0         ;Can't get MM anymore.
         STA   GOTMM
:DVFMT1  JMP   :FORMDN
*
:DVFMTX  JMP   ERROUT     ;FMT ERROR
*
*
:DODSK2  LDA   #$40       ;RATCHET!
         STA   RCMND      ;(SETS TRK 0)
         JSR   PHRWTS     ;DON'T CARE IF ERROR
         LDA   #$04       ;FORMAT COMMAND
         STA   RCMND
:FORMLP  JSR   PHRWTS     ;FORMAT TRK.
         BCC   :FORMOK    ;ERROR?
         LDA   RRTN       ;YES:
         CMP   #$2B       ;WP?
         BNE   :NOTWP
         JMP   OUCH
:NOTWP   LDA   #$3A       ;NO:PRINT
         JSR   LOWMES     ;ERROR
         JSR   PRSPC
         JSR   PRTTRK
         JMP   PRESS      ;GO AWAY.
:TEMP    DB    $0
:XTEMP   DB    $0
*
:FORMOK  INC   RTRACK
         LDA   RTRACK     ;NEXT TRK
         CMP   #$23
         BCC   :FORMLP
*
:FORMDN  JSR   DDISK
:FORMDN1 LDA   #$65
         JMP   PRTPRS
*
*
*
SPLFRM   LDA   #3
SPLGO1   STA   $42
         LDA   UNIT
         STA   $43
         LDA   #0
         STA   $46
         STA   $47
         STA   $44
         LDA   #>FILBUF
         STA   $45
SPLGO    LDA   GODEV+2
         CMP   #$D0
         BCC   :SKIP1
         LDA   $C08B
         LDA   $C08B
:SKIP1   JSR   GODEV
         STA   RRTN       ;4/5/86
         LDA   $C082
         RTS

*
NEWVOL   JSR   PRHERE
         ASC   "\\New "
         DB    $0
         JMP   GVCOM
GETVOL   JSR   PRHERE
         ASC   "\\"
         DB    $0
GVCOM    JSR   PRHERE
         ASC   "Volume Name: /"
         DB    $0
GVCOM1   LDA   #$0F
         STA   LINLIM
         JSR   GETLN
         BCS   :GVOUT
         LDY   #0
         LDX   #0
:DOIT1   LDA   LINEIN,Y
         CMP   #$8D
         BNE   :DOIT2
         LDA   #0
         BEQ   :DOIT3
:DOIT2   INY
         AND   #$7F
:DOIT3   STA   VOLNAM,X
         INX
         CPX   #$10
         BCC   :DOIT1
         LDA   VOLNAM
         BEQ   :GVOUT     ;C IS SET
         LDA   #0
         STA   VOLNAM+$0F
         CLC
:GVOUT   RTS
*
*
*
*
*
DDISK    BIT   DOSNOW
         BPL   :DOS33
         JMP   PDDISK
*
:DOS33   LDA   #>CAT1
         JSR   CLRCAT
         LDA   #$00
         TAX
:BLAHLP  STA   VTOC1,X    ;ZERO VTOC
         INX
         BNE   :BLAHLP
         LDX   #$11       ;SET NEEDED
         STX   VTOC1+1    ;PARAMETERS
         STX   VTOC1+$30
         STX   RTRACK
         DEX              ;10
         STX   VTOC1+$35
         DEX              ;F
         STX   RSECTR
         STX   VTOC1+2
         LDA   #$FE
         STA   VTOC1+6
         LDA   #$7A
         STA   VTOC1+$27
         LDA   #$23
         STA   VTOC1+$34
         LDA   #$FF
         LDX   #$3C       ;START AT TRK 1
:FFLOOP  STA   VTOC1,X    ;WRITE PART
         STA   VTOC1+$1,X
         INX              ;OF BITMAPS
         INX
         INX
         INX
         CPX   #$C4
         BCC   :FFLOOP
         LDX   #$00
         STX   VTOC1+$7C  ;ZERO CATALOG
         STX   VTOC1+$7D  ;BITMAP
         INX              ;1
         STX   VTOC1+$31
         STX   VTOC1+$37
         INX              ;2
         STX   RCMND
         INX              ;3
         STX   VTOC1+3
         LDA   #>CAT1
         STA   RPAGE
:LOOP    JSR   DORWTS     ;WRITE ENTIRE
         INC   RPAGE      ;TRACK
         DEC   RSECTR
         BNE   :LOOP
         LDA   #>VTOC1
         STA   RPAGE
         JSR   DORWTS
*
ZIPDOS   LDY   #$00
         LDA   $C083
:BOOTLP  LDA   $D000,Y
         STA   DATA,Y
         INY
         BNE   :BOOTLP
         LDA   $C082
         STY   RTRACK     ;0
         STY   RSECTR
         INY
         STY   DATA       ;1
         LDA   #>DATA
         STA   RPAGE
         JMP   DORWTS
*
*
************************************
*           VIEW FILES             *
************************************
*
VIEW     LDX   #$04       ;VALUES OR TEXT
         JSR   CHOOZ1
         STA   :T1V0
         JSR   COMTRE
         LDA   #$05
         STA   STATE
         JSR   INITCD
         JSR   RDACNT
         LDA   NACTIV
         BNE   :NEXTFIL
         JMP   NOFIL0
*
:NEXTFIL LDA   #3
         STA   WNDTOP
         JSR   PRTFL1     ;CLEAR FILENAME
         JSR   HOME
         LDA   #$31       ;STAT4
         JSR   LOWMES
         JSR   DOKEY      ;CAT DISPLAY
         JSR   HOME       ;VIEW FILES
*
         LDA   #4
         JSR   VLEFT
         LDA   #$42       ;DASHES
         JSR   PRINT
         LDA   #5
         STA   WNDTOP
         JSR   :SEEFILE   ;FILENAME
         JSR   ASKPR?     ;PRINT IT?
         JSR   SWPCHK     ;CHECK DISK
         JSR   OPNSRC     ;OPEN FILE
         LDA   #$FF
         STA   :RDFLAG
         LDA   PRNTR?     ;PRINTER?
         BNE   :PRINTIT
*
         LDA   PSLOT      ;ASKED?
         BEQ   :NOASK
         JSR   HOME       ;CLEAR
:NOASK   LDA   #$05
         STA   WNDTOP
:PAGELP  JSR   :PAGE      ;SEE PAGE
         BCS   :NEXTFIL
         JSR   :PROMPT    ;MORE?
         BCS   :NEXTFIL
         LDA   :DONE      ;MORE TO DO?
         BEQ   :PAGELP
         BNE   :NEXTFIL
*
:PRINTIT JSR   PRON
         JSR   TOP1       ;PRINT HEADER
         JSR   CROUT
         JSR   :SEEFILE   ;& FILENAME
         JSR   CROUT2
         JSR   PROFF
         LDA   #$05
         STA   WNDTOP
:PPAGELP JSR   PRON
         JSR   :PAGE      ;PRINT PAGE
         PHP
         JSR   PROFF
         PLP
         BCS   :PENDFIL
         LDA   :DONE
         BEQ   :PPAGELP
:PENDFIL JSR   PRON       ;FINISH WITH
         JSR   CROUT2     ;2 BLANK LINES
         JSR   PROFF
         JMP   :NEXTFIL
*
*
* PRINT FILENAME
:SEEFILE LDA   #$05       ;RESET
         STA   :TEMPV     ;VIEW CHAR
         LDA   #$00       ;POSITION
         STA   :TEMPH
         STA   :DONE      ;& END OF VIEW
         JSR   CURPNT
         JMP   PRTFIL
*
:PROMPT  LDA   #$03
         JSR   VLEFT      ;VTAB
         LDA   :DONE
         BMI   :PROMPT2
         LDA   #$35
         JSR   PRINT
:PROMPT3 JSR   GETKEY
         CMP   #$9B
         BEQ   :SECOUT    ;(BEQ->CS)
         CLC
:SECOUT  RTS
*
:PROMPT2 LDA   #$2B       ;PRESS1
         JSR   PRINT
         LDA   #$1E       ;CLEAR LINE
         STA   WNDWTH     ;UP TO BYTE
         JSR   CLREOL     ;COUNT
         LDA   #$28
         STA   WNDWTH
         BNE   :PROMPT3   ;ALWAYS
*
* PRINT PAGE OF VIEW DATA
:PAGE    LDA   :RDFLAG    ;NEED TO READ
         BEQ   :GOTDATA   ;DATA?
         JSR   SWPCHK
         JSR   RDDATA     ;READ IT
         LDA   #$00
         STA   :RDFLAG    ;CLEAR FLAG
         STA   POINT      ;POINT AT DATA
         LDA   DATADR
         STA   POINT+1
:GOTDATA LDA   :TEMPV     ;RESTORE HTAB
         JSR   TABV       ;& VTAB
         LDA   :TEMPH
         STA   CH
         LDA   :T1V0      ;TEXT OR
         BNE   :TEXT      ;VALUES?
         LDA   #$11
         STA   :NCRS      ;LINE COUNTER
:LINELP  LDA   $C000
         CMP   #$9B
         BEQ   :PGABORT
         LDY   #$00       ;VALUES HERE<-
         JSR   CROUT
:HEXLP   JSR   :COUNTER
         LDA   (POINT),Y  ;GET BYTE
         JSR   PHBYTE     ;PRINT IT
         JSR   PRSPC
         INY
         CPY   #$08       ;8 BYTES
         BNE   :HEXLP
         JSR   PRSPC
         LDY   #$00       ;REWIND FOR
:CHRLP   LDA   (POINT),Y  ;ASCII OUT
         ORA   #$80
         JSR   CTRL?      ;NO CTRLS
         BCC   :SEECHR
         LDA   #"."
:SEECHR  JSR   PCOUT      ;PRINT CHAR
         INY
         CPY   #$08       ;8 BYTES
         BNE   :CHRLP
         TYA              ;8
         CLC
         ADC   POINT      ;UPDATE DATA
         STA   POINT
         LDA   POINT+1
         ADC   #0
         STA   POINT+1
         CMP   RPAGE      ;OUT OF DATA
         BCC   :VTEST     ;IN MEMORY?
         DEC   :RDFLAG
         LDA   EOF        ;END OF FILE?
         BNE   :SAYDONE
         BEQ   :POUT
:VTEST   DEC   :NCRS      ;ENOUGH LINES?
         BNE   :LINELP
         BEQ   :POUT
*
:PGABORT SEC
         RTS
*
:TEXT    LDA   #$28       ;SET 40-CHAR
         STA   :NCHARS    ;LINES
         LDA   #$10       ;16 LINES
         STA   :NCRS
         LDY   #$00
:TEXTLP  LDA   $C000
         CMP   #$9B
         BEQ   :PGABORT
         JSR   :COUNTER
         LDA   (POINT),Y  ;GET CHAR
         ORA   #$80
         CMP   #$8D
         BEQ   :DOCR
         JSR   CTRL?      ;NO CTRLS
         BCS   :NXTCHR    ;(EXCEPT CR)
         JSR   PCOUT      ;PRINT CHAR
         DEC   :NCHARS    ;DEC CHAR COUNT
         BNE   :NXTCHR    ;TO ZERO?
         LDA   PRNTR?
         BEQ   :DECNCRS
:DOCR    JSR   CROUT
:DECNCRS DEC   :NCRS
         LDA   #$28
         STA   :NCHARS
:NXTCHR  INC   POINT
         BNE   :NXTCHR0
         INC   POINT+1
:NXTCHR0 LDA   POINT+1
         CMP   RPAGE      ;OUT OF DATA
         BCC   :TTEST     ;IN MEMORY?
         DEC   :RDFLAG
         LDA   EOF
         BNE   :SAYDONE   ;END OF FILE?
         BEQ   :POUT
:TTEST   LDA   :NCRS      ;ENOUGH LINES?
         BEQ   :POUT
         BNE   :TEXTLP
*
:SAYDONE DEC   :DONE
:POUT    LDA   CV         ;SAVE HTAB &
         STA   :TEMPV     ;VTAB
         LDA   CH
         STA   :TEMPH
         CLC
         RTS
*
*
:COUNTER LDX   #$05
:COUNTIT LDA   SCREEN,X
         CMP   #" "
         BEQ   :SPACE
         CMP   #"9"
         BEQ   :NINE
         CLC
         ADC   #$01
         DB    $CD
:SPACE   LDA   #"1"
         STA   SCREEN,X
:CNTOUT  RTS
:NINE    LDA   #"0"
         STA   SCREEN,X
         DEX
         BPL   :COUNTIT
         RTS
*
*
:T1V0    DB    $0
:TEMPY   DB    $0
:NCHARS  DB    $0
:NCRS    DB    $0
:TEMPH   DB    $0
:TEMPV   DB    $0
:DONE    DB    $0
:RDFLAG  DB    $0
*
*
MAKEDR   JSR   COMTRE
         BIT   DOSNOW
         BMI   :MK0
         JMP   NODOS3
*
:MK0     JSR   PRHERE
         ASC   "\\Subdirectory name: "
         DB    $0
         JSR   GVCOM1
         BCS   :OUT
         LDY   #0
:MKLOOP  LDA   VOLNAM,Y
         BEQ   :MK2
         STA   FILE+$1,Y
         INY
         BNE   :MKLOOP
:MK2     TYA
         STA   FILE
         LDA   #$0F
         STA   FTYPE
         LDA   #0
         STA   AUXTYP
         LDA   #$20
         STA   AUXTYP+1
         JSR   GETDAT
         JSR   MKDIR
         BCS   :ERROUT
         LDA   #$66
         JMP   PRTPRS
:OUT     RTS
:ERROUT  JMP   ERROUT
*
*
