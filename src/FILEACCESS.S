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
RDVTOC      LDA   #1
            STA   RCMND
            JSR   DOVTOC
            LDA   #0
            STA   RTRACK
            RTS
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
CTREE       LDA   #>SDNAME
            STA   POINT2+1
            LDY   #0
            STY   POINT2
            STY   :CURR
:TREELP     LDA   XS,Y
            SEC
            SBC   XSTART
            BCC   :GOSKIP
            CMP   DSPNUM
            BEQ   :TREELP0
            BCS   :GOSKIP
:TREELP0    STA   :CHINDX
            TAX
            LDA   :CH,X
            STA   CH
            LDA   YS,Y
            SEC
            SBC   YSTART
            BCC   :GOSKIP
            CMP   #$09
            BCC   :NOSKIP0
:GOSKIP     JMP   :SKIP
*
:NOSKIP0    ASL
            CLC
            ADC   #4
            JSR   TABV
            CPY   #0
            BEQ   :SPCS
*
            LDA   #"-"
            LDX   PREV,Y
            CPX   #$FF
            BEQ   :NOPRE1
            LDA   #"!"
:NOPRE1     PHA
            LDY   :CURR
            LDA   SIS,Y
            CMP   #$FF
            BEQ   :NOPRE2
            LDA   #$8A
            JSR   PCOUT
            LDA   #"!"
            JSR   PCOUT
            LDA   #$88
            JSR   PCOUT
            DEC   CV
            JSR   $FC22
:NOPRE2     PLA
            JSR   PCOUT
            LDA   #"-"
            JSR   PCOUT
            LDA   #">"
            BNE   :NOARO
*
:SPCS       LDA   #" "
            JSR   PCOUT
            JSR   PCOUT
:NOARO      JSR   PCOUT
            LDA   YS,Y
            CMP   YPOS
            BNE   :NOTINVS
            LDA   XS,Y
            CMP   XPOS
            BNE   :NOTINVS
            LDY   #$C0        ;INVERSE
            STY   PINVFL
:NOTINVS    LDY   #0
            LDA   (POINT2),Y
            STA   :LEN
:CLP        INY
            LDA   (POINT2),Y
            ORA   #$80
            JSR   PCOUT
            CPY   :LEN
            BCC   :CLP
            STY   :LEN
            LDY   #0          ;NORMAL
            STY   PINVFL
            LDY   :CURR
            LDA   KITTEN,Y
            CMP   #$FF
            BEQ   :SKIP
            LDY   :LEN
:DASHLP     LDA   #"-"
            JSR   PCOUT
            LDA   CH
            CMP   CHMAX
            BCS   :SKIP
            INY
            CPY   #$11
            BCC   :DASHLP
            LDA   #">"
            JSR   PCOUT
*
:SKIP       JSR   INCPT2
            INC   :CURR
            LDY   :CURR
            CPY   END
            BCS   :FIN
            JMP   :TREELP
*
:FIN        LDX   #5
:FIN0       LDA   :CHL,X
            TAY
            LDA   #$15
            STA   CV
:FIN1       JSR   $FC22
            LDA   (BASL),Y
            CMP   #"!"
            BEQ   :FIN2A
:FIN1A      DEC   CV
            LDA   CV
            CMP   #4
            BCS   :FIN1
:FIN2       DEX
            BPL   :FIN0
:OUT        RTS
*
:FIN2A      INY
            LDA   (BASL),Y
            DEY
            CMP   #" "
            BNE   :FIN3
            LDA   CV
            PHA
:FIN2B      INC   CV
            JSR   $FC22
            LDA   CV
            CMP   #$16
            BCS   :FIN2C
            LDA   #"!"
            STA   (BASL),Y
            BNE   :FIN2B      ;ALWAYS
*
:FIN2C      PLA
            STA   CV

:FIN3       DEC   CV
            LDA   CV
            CMP   #4
            BCC   :FIN2
            JSR   $FC22
            LDA   (BASL),Y
            CMP   #"-"
            BEQ   :FIN1A
            LDA   #"!"
            STA   (BASL),Y
            BNE   :FIN3       ;ALWAYS

:LEN        DB    $0
:CURR       DB    $0
:CH         DB    $1,$13,$25,$37
:CHINDX     DB    $0
:TEMP       DB    $0
:CHL        DB    $0,$1,$9,$12,$13,$1B
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
MKTREE      LDA   #>FILBUF
            STA   RPAGE
            LDA   #>SDNAME
            STA   POINT2+1
            LDY   #$FF
            STY   CURMOM
            INY
            STY   YCUR
            STY   CURR
            STY   BLKNUM+1
            STY   SDBLKH
            STY   POINT2
            STY   XS
            STY   XCUR
            INY
            INY
            STY   BLKNUM
            STY   SDBLKL
:SBDR00     LDA   #0
            STA   SISPTR
:SBDR0      JSR   RDBLK
            BCS   IP3         ;READ ERR
:SBDR01     LDA   RPAGE
            STA   POINT+1
            LDA   FILBUF+2
            STA   BLKNUM
            LDA   FILBUF+3
            STA   BLKNUM+1
            LDA   #4
            STA   POINT
:SBDR1      LDY   #0
            LDX   CURR
            BEQ   :ISROOT
            LDA   (POINT),Y
            AND   #$F0
            CMP   #$D0
            BNE   :NOTDIR
            LDY   #$11
            LDA   (POINT),Y
            STA   SDBLKL,X
            INY
            LDA   (POINT),Y
            STA   SDBLKH,X
:ISROOT     LDA   #0
            STA   SDBLKL+$1,X
            STA   SDBLKH+$1,X
            LDA   CURMOM
            STA   MOM,X
            LDA   #$FF
            STA   KITTEN,X
            STA   SIS,X
            STA   PREV,X
            LDA   SISPTR
            BEQ   :SBDR2
            LDA   CURR
            STA   SIS-1,X
            SEC
            SBC   #1
            STA   PREV,X
:SBDR2      INC   SISPTR
*
* MOVE NAME INTO SDNAME
*
            LDY   #$0F
:MVNAME     LDA   (POINT),Y
            STA   (POINT2),Y
            DEY
            BNE   :MVNAME
            LDA   (POINT),Y
            AND   #$0F
            STA   (POINT2),Y
            JSR   INCPT2
*
            INC   CURR
            BEQ   :DONE       ;3/29/86
            LDA   CURR
            CMP   #1
            BEQ   :DIRDNE
:NOTDIR     LDA   POINT
            CLC
            ADC   #$27
            STA   POINT
:GOSBDR1    BCC   :SBDR1
            INC   POINT+1
            LDA   POINT+1
            CMP   #$0E        ;<--
            BCC   :GOSBDR1
            LDA   BLKNUM
            ORA   BLKNUM+1
            BEQ   :DIRDNE
            JMP   :SBDR0
*
* DONE WITH CURRENT SUBDIR
*
:DIRDNE     INC   CURMOM
            LDX   CURMOM
            LDA   SDBLKL,X
            STA   BLKNUM
            LDA   SDBLKH,X
            STA   BLKNUM+1
            ORA   BLKNUM
            BEQ   :DONE
            LDA   CURR
            STA   KITTEN,X
            CMP   KITTEN-1,X
            BNE   :DIRDN1
            LDA   #$FF
            STA   KITTEN-1,X
:DIRDN1     JMP   :SBDR00
*
:DONE       LDA   #$FF
            STA   KITTEN-1,X
            STX   END
            LDA   #0
            STA   CURR
            STA   YS
:TREE0      LDY   CURR
            LDA   KITTEN,Y
            CMP   #$FF
            BEQ   :NODAUG
            INC   XCUR
            LDX   XCUR
            STX   XMAX
            JMP   :TREE1
*
:NOSIS      LDA   MOM,Y
            CMP   #$FF
            BEQ   :ATROOT
            DEC   XCUR
            STA   CURR
            TAY
:NODAUG     LDA   SIS,Y
            CMP   #$FF
            BEQ   :NOSIS
            INC   YCUR
:TREE1      STA   CURR
            TAY
            LDA   XCUR
            STA   XS,Y
            LDA   YCUR
            STA   YS,Y
            JMP   :TREE0
*
*
:ATROOT     CLC
            RTS

