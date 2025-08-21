*************************************
*       FILE ACCESS ROUTINES        *
*************************************
*
*
*
****** NEW TRACK READ/WRITE STUFF ***
*
* *DELFLG=$80 FOR ACTIVE FILES
*        =$00 FOR DELETED
*
RDACNT      BIT   DOSNOW
            BPL   :ISDOS33    ;DOS 3.3 DISK
*
* IT'S A PRODOS DISK
*
            LDA   #>SDIR
            STA   DIRADR
            LDA   #$14
            STA   COUNT
            JMP   PRDCNT

*
:ISDOS33    LDA   #>DOSDAT    ;SET UP DATADR
            STA   DATADR
            LDA   #>CAT1
            JSR   CLRCAT      ;ZERO CATALOG
            LDX   #$00
            STX   NACTIV      ;NO FILES YET
            INX
            STX   RCMND       ;READ COMMAND
            LDX   #>VTOC1
            JSR   DOVTOC      ;READ VTOC.
*
:SECTLP     LDY   #$01        ;FIND PTR TO
            LDA   (POINT),Y   ;NEXT SECTOR
            BEQ   :OUT        ;NIL PTR?
            CMP   #$28
            BCS   WDERR
            STA   RTRACK      ;NO:SAVE TRACK
            INY
            LDA   (POINT),Y   ;& SECTOR
            CMP   #$10
            BCS   WDERR
            STA   RSECTR
            INC   RPAGE       ;NEXT PAGE
            INC   POINT+1
            JSR   PHRWTS      ;READ CATALOG
            BCS   :OUT        ;BAD SECTOR?
            LDY   #$0B
:POSNLP     LDA   (POINT),Y
            BEQ   :OUT        ;NO MORE FILES?
            AND   #$80
            EOR   DELFLG
            BEQ   :NOTWANT    ;WANTED FILE?
            TYA
            LDX   NACTIV
            STA   CBYTE,X     ;PUT INTO ARRAY
            LDA   RPAGE
            STA   CSECTR,X
            INC   NACTIV
:NOTWANT    TYA               ;NEXT FILE IN
            CLC               ;SECTOR
            ADC   #$23
            TAY
            BNE   :POSNLP     ;DONE SECTOR?
            DEC   COUNT       ;ROOM 4 MORE?
            BNE   :SECTLP
:OUT        RTS
*
*
RDCAT1      LDA   #>CAT1
            JSR   CLRCAT
            LDX   #>VTOC1
RDCT1A      LDA   #$01
            BNE   DOCAT
*
RDCAT2      LDA   #>CAT2
            JSR   CLRCAT
            LDX   #>VTOC2
            BNE   RDCT1A
*
WRCAT1      LDX   #>VTOC1
            BNE   WRCT2A
*
WDERR       LDA   #$52
            JMP   ERROU1
*
WRCAT2      BIT   DOSNOW
            BPL   :DOS33
            JMP   CLOSE
*
:DOS33      LDX   #>VTOC2
WRCT2A      LDA   #2
DOCAT       STA   RCMND
            BIT   DOSNOW
            BPL   :DOS33
            LDX   #>SDIR
            STX   DIRADR
            JMP   PDOCAT
*
:DOS33      JSR   DOVTOC      ;R/W VTOC.
:SECTLP     LDY   #$01        ;FIND PTR TO
            LDA   (POINT),Y   ;NEXT SECTOR
            BEQ   :OUT        ;NIL PTR?
            STA   RTRACK      ;NO:SAVE TRACK
            INY
            LDA   (POINT),Y   ;& SECTOR
            STA   RSECTR
            INC   RPAGE       ;NEXT PAGE
            INC   POINT+1
            JSR   PHRWTS      ;R/W CATALOG
            BCS   :OUT        ;ERROR?
            LDY   #$0B
:POSNLP     LDA   (POINT),Y
            BEQ   :OUT        ;NO MORE FILES?
            TYA
            CLC
            ADC   #$23        ;NEXT FILE
            TAY
            BNE   :POSNLP     ;DONE SECTOR?
            DEC   COUNT       ;ROOM 4 MORE?
            BNE   :SECTLP
:OUT        RTS
*
* READ/WRITE VTOC, READY FOR CATALOG
*
DOVTOC      STX   RPAGE       ;SET PAGE
            STX   POINT+1
            JSR   STVTOC      ;RETURNS A=0
            STA   POINT
            STA   RSECTR      ;SECTOR 0
            LDA   #$0F        ;UP TO 15
            STA   COUNT       ;CATALOG PAGES
            JSR   DORWTS      ;R/W VTOC.
            LDY   #$35
            LDA   (POINT),Y
            CMP   #$10
            BNE   WDERR
            LDY   #1
            LDA   (POINT),Y
            BEQ   WDERR
            RTS
*
* CLEAR CATALOG SECTORS
CLRCAT      STA   POINT+1
            LDA   #$00
            STA   POINT
            TAY
            LDX   #$0E
:NXTSECT    STA   (POINT),Y
            INY
            CPX   #$00
            BEQ   :NOLINK
            LDA   #$11
:NOLINK     STA   (POINT),Y   ;TRACK LINK
            INY
            TXA
            STA   (POINT),Y   ;SECTOR LINK
            INY
            LDA   #$00
:ZEROLP     STA   (POINT),Y   ;ZEROS
            INY
            BNE   :ZEROLP
            INC   POINT+1
            DEX
            BPL   :NXTSECT    ;BACK FOR MORE
            RTS
*
*
*
* FIND FREE & USED SPACE IN VTOC
* ACC=PAGE# OF VTOC ->
*
SPACE       BIT   DOSNOW
            BPL   :DOS33
            JMP   PSPACE      ;DO PRODOS
*
:DOS33      STA   POINT+1
            LDA   #$38        ;BITMAP START
            STA   POINT
            LDA   #$00        ;CLEAR BUFFER
            STA   FREEL
            STA   FREEH
            LDY   #$8B        ;BITMAP LENGTH
:NXTBYTE    LDA   (POINT),Y
            LDX   #$07
:NEXTBIT    LSR               ;SHIFT BITS TO
            BCC   :USED       ;FIND FREE
            INC   FREEL       ;SECTORS
            BNE   :USED
            INC   FREEH
:USED       DEX
            BPL   :NEXTBIT
            DEY
            BNE   :NXTBYTE
            SEC               ;SUBTRACT FROM
            LDA   #$30        ;TOTAL # OF
            SBC   FREEL       ;SECTORS TO
            STA   USEDL       ;GET # USED
            LDA   #2
            SBC   FREEH
            STA   USEDH
            RTS
*
*
*
* PLACE INPUT FILE INTO ENTRY
*   AT (*POINT)
*
PLACE       LDX   #0
:CRLP       INX
            LDA   LINEIN,X
            CMP   #$8D
            BNE   :CRLP
            BIT   DOSNOW
            BMI   :PIPRODOS
            LDA   #" "        ;MOVE LINE TO
            LDY   #$20        ;ENTRY:
:SPACELP    STA   (POINT),Y   ;COPY SPACES
            DEY               ;TO ENTRY
            CPY   #$03
            BPL   :SPACELP
            TXA
            TAY
            DEX               ;BEFORE CR
            INY               ;ENTRY OFFSET 3
            INY               ;MORE
            LDA   #$FF
:PUTLP0     STA   :MASK
:PUTLP      LDA   LINEIN,X    ;COPY CHARS
            AND   :MASK
            STA   (POINT),Y
            DEY
            DEX
            BPL   :PUTLP
            CLC
            RTS
:PIPRODOS   LDY   #0
            LDA   (POINT),Y
            AND   #$F0
            STA   (POINT),Y
            TXA
            AND   #$0F
            TAX
            ORA   (POINT),Y
            STA   (POINT),Y
            TXA
            TAY
            DEX
            LDA   #$7F
            BNE   :PUTLP0     ;ALWAYS
*
:MASK       DB    $0
*
* SET POINTER FROM CATALOG ARRAY
*
CURPNT      LDX   CURR
SETPNT      LDA   CBYTE,X
            STA   POINT
            LDA   CSECTR,X
            STA   POINT+1
            RTS
*
*
* FREE A SECTOR ON *POINT - VTOC
* T&S IN *TRACK & *SECTOR
*
FREES       LDA   TRACK
            ASL
            ASL
            ADC   #$38
            TAY
            LDA   SECTOR
            JSR   DOMASK
            LDA   (POINT),Y
            ORA   BITMSK
            STA   (POINT),Y
            INY
            LDA   (POINT),Y
            ORA   BITMSK+1
            STA   (POINT),Y
            RTS
*
* MAKE A 1-BIT MASK FOR A BITMAP WORD
* SECTOR # IN ACC ->
*
DOMASK      TAX
            LDA   #$00
            STA   BITMSK+1
            STA   BITMSK
            SEC
:NEXT       ROL   BITMSK+1
            ROL   BITMSK
            DEX
            BPL   :NEXT
:OUT        RTS
*
*
STVTOC      LDA   #$11
            STA   RTRACK
            LDA   #$00
            STA   RSECTR
            RTS
*
*
DOS?        LDX   #0
            JSR   PUTSEC
            STX   RTRACK
            JSR   DORWTS
            LDX   #3
            LDY   #1
            JSR   CHKDOS
            BCC   :NODOS
            RTS
:NODOS      JSR   PRHERE
            DB    $8D,$8D
            ASC   "No DOS on disk"
            DB    $8D,$0
            JMP   PRESS
*
CHKDOS      LDA   #2
            STA   TEMP
:CHECKLP    LDA   DATA,Y      ;MATCH PATTERN
            CMP   :DOSPAT,X   ;TO VERIFY
            SEC
            BNE   :NO         ;DOS IS THERE
            INX
            INY
            DEC   TEMP
            BPL   :CHECKLP
            CLC
:NO         RTS
*
:DOSPAT     DB    $E0,$00,$F0,$A6,$2B,$BD
*
PUTSEC      STX   RSECTR      ;SET SECTOR
            LDA   #>DATA
            STA   RPAGE       ;SET ADDR
            LDA   #$01
            STA   RTRACK      ;SET TRACK
            STA   RCMND       ;SET COMMAND
            RTS
*
* INSERT SOURCE OR DESTINATION DISKS
*
*
INSS        LDA   PDOS
            STA   CURDOS
:INSS0      JSR   INSS1
            CMP   #1
            BNE   :NOSWS      ;DIDN'T SWITCH
            LDA   #>PPFX
            LDY   #PPFX
            LDX   #>VTOC1
            JSR   SWCK
            BCS   :INSS0
:NOSWS      JMP   SETP
*
INSS1       LDA   ONLY1       ;IF ONLY 1:
            BEQ   :SELECT
            LDA   SDFLG
            BPL   :SELECT
            LDA   #0
            STA   SDFLG
            LDA   #MINSSRC    ;'INSERT SOURCE DISK'
            JSR   LOWMES
            JSR   INSCOM      ;WAIT FOR KEY
            STA   PDOS        ;1
:SELECT     RTS
*
INSD        LDA   SDOS
            STA   CURDOS
:INSD0      JSR   INSD1
            CMP   #1
            BNE   :NOSWP
            LDA   #>SPFX
            LDY   #SPFX
            LDX   #>VTOC2
            JSR   SWCK
            BCS   :INSD0
:NOSWP      JMP   SETS
*
INSD1       LDA   ONLY1
            BEQ   :SELECT
            LDA   SDFLG
            BMI   :SELECT
            LDA   #$FF
            STA   SDFLG
            LDA   #MINSTGT    ;'INSERT TARGET DISK'
            JSR   LOWMES
            JSR   INSCOM
            STA   SDOS        ;1
:SELECT     RTS
*
SDFLG       DB    $0
*
SWCK        STA   PFXADR+1
            STY   PFXADR
            STX   :VTOC
            JSR   DOSTYP
            LDA   CURDOS
            CMP   #1
            BEQ   :SWCK0
            EOR   DOSNOW
            BNE   :BADSWP     ;NOT SAME DOS
:SWCK0      LDA   DOSNOW
            BPL   :DOSCK
            LDY   #0
            LDA   (PFXADR),Y
            BEQ   :SWCKOUT    ;DON'T CHECK
            BMI   :SWCKOUT
            LDA   VOLNMS,X
            AND   #$0F
            CLC
            ADC   #2
            STA   :LEN
            LDY   #2
:SWCKLP     LDA   (PFXADR),Y
            CMP   VOLNMS+$1,X
            BNE   :BADSWP
            INY
            INX
            CPY   :LEN
            BCC   :SWCKLP
:SWCKOUT    CLC
            RTS
:BADSWP     JSR   LOHERE
            ASC   "Incorrect disk"
            DB    $8D,$87,$0
            JSR   INSCOM
            LDA   SDFLG
            EOR   #$FF
            STA   SDFLG
            SEC
            RTS
*
:DOSCK      LDA   :VTOC
            STA   MESPNT+1
            LDY   #0
            STY   MESPNT
            INY
            LDA   (MESPNT),Y
            BEQ   :SWCKOUT    ;DON'T CHECK
            JSR   STVTOC
            LDA   #$01
            STA   RCMND
            LDA   RPAGE
            PHA
            LDA   #>CVTOC
            STA   RPAGE
            JSR   DORWTS
            PLA
            STA   RPAGE
            LDY   #$00
:LOOPCHK    LDA   (MESPNT),Y
            CMP   CVTOC,Y
            BNE   :BADSWP
            DEY
            BNE   :LOOPCHK
            CLC
            RTS
:VTOC       DB    $0
:LEN        DB    $0
*
SWPCHK      LDA   DOSNOW
            STA   CURDOS
:SWPCHK0    LDA   #>PFX
            LDY   #PFX
            LDX   #>VTOC1
            JSR   SWCK
            BCS   :SWPCHK0
SWPRET      RTS
*
SET1A2      STA   CVTOC+$3C
            STA   CVTOC+$3D
            STA   CVTOC+$40
            STA   CVTOC+$41
            LDA   #2
            STA   RCMND
*
DORWTS      JSR   PHRWTS
            BCC   SWPRET
            JMP   ERROUT
*
* READ SOURCE DATA
*
RDDATA      LDY   RELCNT
            BEQ   :RDD1
            LDA   RBLKL-1,Y
            STA   RBLKL-1
            LDA   RBLKH-1,Y
            STA   RBLKH-1
:RDD1       LDA   #$00
            STA   RELCNT
            STA   EOF
            BIT   DOSNOW
            BPL   :RDDOS33
            JMP   :RDPRODOS
*
:RDDOS33    LDA   #$01
            STA   RCMND
            LDA   DATADR
            STA   RPAGE
            LDA   STSP        ;TSLIST EMPTY?
            BNE   :RDMORE
:NXTTSL     LDA   SRCTSL+1    ;POINT TO IT
            STA   RTRACK
            LDA   SRCTSL+2
            STA   RSECTR
            JSR   RDTSL       ;READ IT
*
:RDMORE     LDX   STSP
            LDA   SRCTSL,X    ;NONZERO TS
            STA   RTRACK      ;PAIR?
            ORA   SRCTSL+$1,X
            BEQ   :NEXTRD
            LDA   SRCTSL+$1,X  ;SET TRACK
            STA   RSECTR      ;& SECTOR
*
* SET RBLKH = $7A*TSLCTR+(STSP-$C)/2
*
            LDA   #0
            STA   :SUM
            STA   :SUM+1
            LDX   #7
            LDA   #$7A
            STA   :TEMP2
            LDA   TSLCTR
            STA   :TEMP0
            LDA   TSLCTR+1
            STA   :TEMP1
:MULTLP     LSR   :TEMP2
            BCC   :SKIPADD
            LDA   :SUM
            CLC
            ADC   :TEMP0
            STA   :SUM
            LDA   :SUM+1
            ADC   :TEMP1
            STA   :SUM+1
:SKIPADD    ASL   :TEMP0
            ROL   :TEMP1
            DEX
            BPL   :MULTLP
            LDA   STSP
            SEC
            SBC   #$0C
            LSR
            CLC
            ADC   :SUM
            LDY   RELCNT
            STA   RBLKL,Y
            LDA   :SUM+1
            ADC   #0
            STA   RBLKH,Y
*
            INC   RELCNT
            JSR   PHRWTS      ;READ DATA
            BCS   :ERROUT
            INC   RPAGE       ;NEXT PAGE
:NEXTRD     INC   STSP        ;NEXT TS PAIR
            INC   STSP
            BEQ   :EOTSL      ;END OF LIST?
            LDA   RPAGE
            CMP   HIMEM       ;OUT OF MEMORY?
            BCC   :RDMORE
            RTS
:EOTSL      LDA   SRCTSL+1    ;A NEXT TSLIST?
            ORA   SRCTSL+2
            BEQ   :OUT
            JMP   :NXTTSL
:OUT        DEC   EOF         ;NO: EOF
            RTS
:TEMP0      DB    $0
:TEMP1      DB    $0
:TEMP2      DB    $0
:SUM        DB    $0,$0
:ERROUT     JMP   ERROUT
*
:RDPRODOS   LDA   DATADR
            STA   :TEMP
            LDA   BLKNUM
            ORA   BLKNUM+1
            BEQ   :READ2
            LDA   :TEMP
:READLP     STA   RPAGE
            JSR   :RDBLOK
            JSR   CURPNT
            LDY   #$15
            LDA   (POINT),Y
            INY
            ORA   (POINT),Y
            INY
            ORA   (POINT),Y
            BEQ   :GTEOF1
            LDY   RELCNT
            LDA   IBPTR
            STA   RBLKL,Y
            LDA   MIBPTR
            STA   RBLKH,Y
            INC   RELCNT
            INC   :TEMP
            INC   :TEMP
:READ2      JSR   FNDBLK
            BCS   :GOTEOF
            LDA   :TEMP
            CMP   HIMEM
            BCC   :READLP
            STA   RPAGE
            RTS
*
:GOTEOF     LDA   :TEMP
            STA   RPAGE
            LDA   :BUFF
            BEQ   :GTEOF1
            LDY   RELCNT
            LDA   RBLKL-1,Y
            CLC
            ADC   #1
            STA   RBLKL,Y
            LDA   RBLKH-1,Y
            ADC   #0
            STA   RBLKH,Y
            INC   RELCNT
            INC   RPAGE
:GTEOF1     DEC   EOF
            RTS
:TEMP       DB    $0
*
:RDBLOK     LDA   UNIT
            STA   :UNIT
            LDA   BLKNUM
            STA   :BLKNUM
            LDA   BLKNUM+1
            STA   :BLKNUM+1
            LDA   RPAGE
            STA   :BUFF+1
            LDA   RADR
            STA   :BUFF
            JSR   MLI
            DB    $80
            DW    :RBLST
            STA   RRTN
            BCS   ERR1
            RTS
:RBLST      DB    $3
:UNIT       DB    $0
:BUFF       DB    $0,$0
:BLKNUM     DB    $0,$0
*
* READ TSLIST & UPDATE SECTOR POINTER
RDTSL       JSR   RDTSL1
            BCS   ERR1
            RTS
*
FNDBLK      JSR   FNBLK1
            BCC   :FND1
:ERR?       CMP   #$FF
            BEQ   ERR1
            SEC
:FND1       RTS
ERR1        JMP   ERROUT
*
FNBLK1      LDA   STRTYP      ;IF SAPLING,
            CMP   #$10        ; RETURN EOF
            BEQ   :FNDEOF
            CMP   #$D0
            BEQ   :SUBDIR
:CKINDX     INC   IBPTR
            BEQ   :CKTREE
:LOOKDAT    LDX   IBPTR
            LDA   SIB,X
            STA   BLKNUM
            ORA   SIB+$100,X
            BEQ   :CKINDX     ;NO ENTRY
            LDA   SIB+$100,X
            STA   BLKNUM+1
            CLC
            RTS
*
* INDEX BLOCK USED UP
*
:CKTREE     LDA   STRTYP
            CMP   #$30
            BNE   :FNDEOF     ;NOT TREE
:CKMSTR     INC   MIBPTR
            LDX   MIBPTR
            BMI   :FNDEOF
            LDA   SMIB,X
            STA   BLKNUM
            ORA   SMIB+$100,X
            BEQ   :CKMSTR
            LDA   SMIB+$100,X
            STA   BLKNUM+1
            LDA   #>SIB
            STA   RPAGE
            JSR   RDBLK
            BCC   :LOOKDAT
            LDA   #$FF
            DB    $CD
:FNDEOF     LDA   #0
:ERR        SEC
            RTS
*
:SUBDIR     LDA   #0
            STA   RADR
            JSR   RDBLK
            LDA   #$FF
            BCS   :ERR
            LDY   #2
            LDA   (RADR),Y
            STA   BLKNUM
            INY
            LDA   (RADR),Y
            STA   BLKNUM+1
            ORA   BLKNUM
            BEQ   :FNDEOF     ;END OF SUBDIR
*
* CARRY ALREADY CLEAR
*
*CLC
            RTS
*
*
*-------------------------------------
*
* OPEN SOURCE FILE
*
OPNSRC      JSR   OPNFIL
            BCS   ERR1
            RTS
*
OPNFIL      JSR   CURPNT      ;POINT TO FILE
            BIT   DOSNOW
            BPL   :DOS33
*
:PRODOS     LDY   #$11
            LDA   (POINT),Y   ;KEY BLK LO
            STA   BLKNUM
            INY
            LDA   (POINT),Y   ;KEY BLK HI
            STA   BLKNUM+1
            LDY   #$0F
:NAMELP     LDA   (POINT),Y
            STA   FILE,Y
            DEY
            BPL   :NAMELP
            LDA   FILE
            PHA
            AND   #$0F
            STA   FILE
            PLA
            AND   #$F0
            STA   STRTYP
            CMP   #$10
            BEQ   :OPENDAT
            CMP   #$20
            BEQ   :OPENIB
            CMP   #$30
            BNE   :OPENDAT    ;SUBDIRECTORY
*
:OPENMIB    LDA   #>SMIB
            STA   RPAGE
            JSR   RDBLK
            BCS   :ERR
            LDA   SMIB
            STA   BLKNUM
            LDA   SMIB+$100
            STA   BLKNUM+1
:OPENIB     LDA   #>SIB
            STA   RPAGE
            JSR   RDBLK
            BCS   :ERR
            LDA   SIB
            STA   BLKNUM
            LDA   SIB+$100
            STA   BLKNUM+1
:OPENDAT    LDA   #0
            STA   MIBPTR
            STA   IBPTR
            STA   RELCNT
            CLC
:ERR        RTS
*
:DOS33      LDA   #$10
            STA   STRTYP
            LDY   #$FF
            STY   TSLCTR
            STY   TSLCTR+1
            LDY   #0
            LDA   (POINT),Y
            STA   RTRACK
            INY
            LDA   (POINT),Y
            STA   RSECTR
            INY
:DNMLP      LDA   (POINT),Y
            STA   FILE-2,Y
            INY
            CPY   #$21
            BCC   :DNMLP
            LDA   #$1E
            STA   FILE        ;LENGTH
            LDA   #$01
            STA   RCMND       ;FALL THRU...
*
*
RDTSL1      LDA   RPAGE
            PHA
            LDA   #>SRCTSL    ;READ INTO
            STA   RPAGE       ;TSLIST AREA
            INC   TSLCTR
            BNE   :RDTS1
            INC   TSLCTR+1
:RDTS1      JSR   PHRWTS      ;GET TSLIST
            LDA   #$0C        ;RESET SOURCE
            STA   STSP        ;TS POINTER
            PLA
            STA   RPAGE
            RTS
*
*
*
INCPT2      LDA   POINT2
            CLC
            ADC   #$10
            STA   POINT2
            BCC   IP3
            INC   POINT2+1
IP3         RTS
*
*
*
*
SPLFRM      LDA   #3
SPLGO1      STA   $42
            LDA   UNIT
            STA   $43
            LDA   #0
            STA   $46
            STA   $47
            STA   $44
            LDA   #>FILBUF
            STA   $45
            LDA   GODEV+2
            CMP   #$D0
            BCC   :SKIP1
            LDA   $C08B
            LDA   $C08B
:SKIP1      JSR   GODEV
            STA   RRTN        ;4/5/86
            LDA   $C082
            RTS

*
GVCOM       JSR   PRHERE
            ASC   "Volume name: /"
            DB    $0
GVCOM1      LDA   #$0F
            STA   LINLIM
            JSR   GETLN
            BCS   :GVOUT
            LDY   #0
            LDX   #0
:DOIT1      LDA   LINEIN,Y
            CMP   #$8D
            BNE   :DOIT2
            LDA   #0
            BEQ   :DOIT3
:DOIT2      INY
            AND   #$7F
:DOIT3      STA   VOLNAM,X
            INX
            CPX   #$10
            BCC   :DOIT1
            LDA   VOLNAM
            BEQ   :GVOUT      ;C IS SET
            LDA   #0
            STA   VOLNAM+$0F
            CLC
:GVOUT      RTS
*
ZIPDOS      LDY   #$00
            LDA   $C083
:BOOTLP     LDA   $D000,Y
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
            JMP   DORWTS
*
*
*
*
* *FIXSUB IS CALLED BY LOCK/UNLOCK,
* RENAME AND ALPHABETIZE TO MAKE
* THE NEEDED CHANGES TO THE SUBDIR
* HEADER. HEADER NAME, ACCESS AND
* PARENT POINTERS ARE UPDATED.
*
FIXSUB      JSR   SWPCHK
            BIT   DOSNOW
            BPL   :FXSB1      ;NOT PRODOS
*
            LDA   #0
            STA   CURR
:FXLOOP     JSR   CURPNT
            JSR   :FIXSUB
            INC   CURR
            LDA   CURR
            CMP   NACTIV
            BNE   :FXLOOP
*
:FXSB1      JMP   WRCAT1
*
:OUT        RTS
:FIXSUB     JSR   DIR?
            BCS   :OUT        ;NOT SUBDIR
            LDA   #>DATA      ;TEMP BUFFER
            STA   POINT2+1
            STA   RPAGE
            LDA   #4
            STA   POINT2
*
* READ 1ST BLOCK OF SUBDIR
*
            LDY   #$11
            LDA   (POINT),Y
            STA   BLKNUM
            INY
            LDA   (POINT),Y
            STA   BLKNUM+1
            JSR   RDBLK
            BCS   :OUT
*
* COPY FILENAME TO HEADER NAME
*
            LDY   #$0F
:FSLP1      LDA   (POINT),Y
            STA   (POINT2),Y
            DEY
            BNE   :FSLP1
            LDA   (POINT),Y
            AND   #$0F
            ORA   #$E0
            STA   (POINT2),Y
*
* DON'T NEED TO CHANGE ACCESS BYTE
* BECAUSE PRODOS DOESN'T.
*
* LDY #$1E
* LDA (*POINT),Y
* STA (*POINT2),Y
*
* SET UP PARENT POINTERS
*
            LDA   POINT+1
            AND   #$FE
            CMP   #>SDIR      ;14
            BNE   :FS2        ;NOT 1ST
            LDA   DIRBLK
            LDX   DIRBLK+1
            JMP   :FS3
*
:FS2        SEC
            SBC   #$2
            STA   TEMP+1
            LDA   #0
            STA   TEMP
            LDY   #3
            LDA   (TEMP),Y    ;PARENT BLK HI
            TAX
            DEY
            LDA   (TEMP),Y    ;PARENT BLK LO
:FS3        LDY   #$23
            STA   (POINT2),Y
            INY
            TXA
            STA   (POINT2),Y
*
* FIGURE OUT PARENT ENTRY NUMBER
*
            LDY   #$26
            LDA   (POINT2),Y  ;ENTRY LENGTH
            STA   TEMP
*
            LDA   POINT
            LDX   #1
:FS4        CMP   #4
            BEQ   :FS5
            SEC
            SBC   TEMP
            INX
            BNE   :FS4        ;ALWAYS
*
:FS5        TXA
            DEY
            STA   (POINT2),Y
*
* WRITE SUBDIR BLOCK BACK
*
            JMP   WTBLK
*
*
COMTRE      JSR   DODEVP
            JSR   TREEA
            JSR   COMH00
CT1         BIT   DOSNOW
            BPL   :CTOUT      ;DOS 3.3
            LDA   RRTN
            BEQ   :CTOUT      ;NO ERROR
            CMP   #$52
            BEQ   :CTERR1
            CMP   #$40
            BCC   :CTERR      ;I/O ERROR
:CTOUT      RTS
*
* BLOCK 2 ERROR
*
:CTERR      JMP   BLK2ER
*
* NOT A DOS OR PRODOS DISK
*
:CTERR1     JMP   WDERR
*
COMHDR      JSR   DODEVP
            JSR   SETA
            JSR   COMH00
            LDA   CHOICE
            CMP   #MVERIFY    ;VERIFY DISK?
            BNE   CT1         ;NO
            RTS

COMH00      JSR   TOP1
            JMP   PRVNM
OPTCHS      DB    $0
