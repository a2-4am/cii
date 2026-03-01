            TYP   BIN
            DSK   ../build/READLIB.O
            PUT   VARS
            PUT   ../build/PHRWTS.VARS
            PUT   ../build/PRODOS.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/ERRORS.VARS
            PUT   ../build/UILIB.VARS
            ORG   UILIBEND

**********************************
*      FILE READING LIBRARY      *
* RDTSL - read track/sector list *
* OPNSRC - open source file      *
* OPNFIL - open file             *
* RDDATA - read file data        *
* CURPNT - set POINT to sector   *
* SETPNT - set POINT from catalog*
*          array                 *
**********************************

*
*
* READ TSLIST & UPDATE SECTOR POINTER
RDTSL       LDA   RPAGE
            PHA
            LDA   #>SRCTSL    ;READ INTO
            STA   RPAGE       ;TSLIST AREA
            INC   TSLCTR
            BNE   :RDTS1
            INC   TSLCTR+1
:RDTS1                        ;GET TSLIST
            >>>   JSRMODULE,PHRWTSLIB;PHRWTSINTERNAL
            LDA   #$0C        ;RESET SOURCE
            STA   STSP        ;TS POINTER
            PLA
            STA   RPAGE
            RTS
*
*
* READ SOURCE DATA
*
RDDATAERR1  EQU   *
            JMP   ERROUT
RDDATA      
            LDY   RELCNT
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
            BCS   RDDATAERR1
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
                              ;READ DATA
            >>>   JSRMODULE,PHRWTSLIB;PHRWTSINTERNAL
            BCS   RDDATAERR2
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
RDDATAERR2  EQU   *
            JMP   ERROUT
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
:READ2      JSR   FNBLK1
            BCS   :GOTEOF
            CMP   #$FF
            BEQ   :ERROUT2
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
            BCS   :ERROUT2
            RTS
:ERROUT2    JMP   ERROUT
:RBLST      DB    $3
:UNIT       DB    $0
:BUFF       DB    $0,$0
:BLKNUM     DB    $0,$0
*
*
*-------------------------------------
*
* OPEN SOURCE FILE
* called by CATALOG, COPY, DISKMAP, and VIEW
OPNSRC      JSR   OPNFIL
            BCS   :ERR1
            RTS
:ERR1       JMP   ERROUT
*
* called by OPNSRC (above) and VERIFY
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
            STA   RCMND
            JMP   RDTSL
*
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
READLIBEND
