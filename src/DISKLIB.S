            TYP   BIN
            DSK   ../build/DISKLIB.O
            PUT   VARS
            PUT   ../build/PHRWTS.VARS
            PUT   ../build/PRODOS.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/LINEINPUT.VARS
            PUT   ../build/ERRORS.VARS
            PUT   ../build/UILIB.VARS
            ORG   UILIBEND
DISKLIB
**********************************
*          DISK LIBRARY          *
* DOWBLK - write block (w/error) *
* DOVTOC - read/write VTOC       *
* CLRCAT - clear catalog sectors *
* WRCAT1
* WRCAT2
* DOCAT - read/write catalog     *
* DOS? - read T00S00, is DOS boot?*
* SET1A2 - mark T01+T02 in VTOC  *
* DORWTS - call PHRWTS (w/error) *
* SWPCHK - is correct disk? w/err*
* SWCK - verify is correct disk  *
* DOSTYP - ProDOS or DOS?        *
* RDTSL - read track/sector list *
* OPNSRC - open source file      *
* OPNFIL - open file             *
* RDDATA - read file data        *
**********************************
            ORG   *+3
            RTS

*
* WRITE BLOCK, WITH ERROR HANDLING
*
DOWBLK
            JSR   WTBLK
            BCS   :ERROUT
            RTS
:ERROUT     JMP   ERROUT
*
*
* READ/WRITE VTOC, READY FOR CATALOG
*
* TAKES PAGE IN X
DOVTOC
            STX   RPAGE       ;SET PAGE
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
            BNE   :WDERR
            LDY   #1
            LDA   (POINT),Y
            BEQ   :WDERR
            RTS
:WDERR      JMP   WDERR
*
*
* CLEAR CATALOG SECTORS
* called by RDACNT(CATLIB), DELETE DISK(DELLIB),
* RDCAT1, and RDCAT2
CLRCAT
            STA   POINT+1
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
WRCAT1
            LDX   #>VTOC1
            LDA   #$02
            BNE   DOCAT       ;ALWAYS
*
WRCAT2
            BIT   DOSNOW
            BPL   :DOS33
            JMP   CLOSE       ;NO JUST CLEAN UP
:DOS33      LDX   #>VTOC2     ;YES WRITE CATALOG
            LDA   #$02
*            JMP   DOCAT
* fall through to DOCAT
*
* READ OR WRITE CATALOG
*
* TAKES VTOC PAGE IN X
* TAKES RWTS COMMAND (1 OR 2) IN A
*
DOCAT
            STA   RCMND
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
*
*
* PDOCAT
*   READ OR WRITE PRODOS DIRECTORY
*
*   INPUT
*  DIRADR = BUFFER HI ADDR
*  RCMND  = 1 -> RD, 2 -> WT
*  DIRBLK = STARTING BLOCK
PDOCAT      EQU   *
            LDA   RCMND
            CMP   #2
            BNE   :OUT
*
:DOWRT      LDA   DIRBLK
            STA   BLKNUM
            LDA   DIRBLK+1
            STA   BLKNUM+1
            LDA   DIRADR
            STA   RPAGE
            STA   POINT+1
            LDA   #0
            STA   POINT
:WTMORE     JSR   DOWBLK
            LDY   #2
            LDA   (POINT),Y
            STA   BLKNUM      ;NEXT BLOCK
            INY
            LDA   (POINT),Y
            STA   BLKNUM+1
            INC   POINT+1
            INC   POINT+1
            INC   RPAGE
            INC   RPAGE
*
* DON'T WRITE MORE THAN 20 BLOCKS
* (260 FILES) OF DIRECTORY
*
            LDY   RPAGE
            CPY   #$3C
            BCS   :OUT
            ORA   BLKNUM
            BNE   :WTMORE
:OUT        RTS
*
* DOS?
* read T00S00 and check for recognized DOS-shaped bootloader
* called by Copy DOS (COPY) and Delete DOS (DELLIB)
* 
DOS?
            LDX   #0
            JSR   PUTSEC
            STX   RTRACK
            JSR   DORWTS
            LDX   #3
            LDY   #1
            JSR   CHKDOS
            BCC   :NODOS
            RTS
:NODOS      LDA   #MNODOS
            JMP   PRTPRS
*
SET1A2
            STA   CVTOC+$3C
            STA   CVTOC+$3D
            STA   CVTOC+$40
            STA   CVTOC+$41
            LDA   #2
            STA   RCMND
* falls through to DORWTS
DORWTS
            JSR   PHRWTS
            BCS   DISKLIBERR
            RTS
*
DISKLIBERR  EQU   *
            JMP   ERROUT
*
* SWAP CHECK
* to the best of our ability, ensure that the correct
* disk is in the drive
*
* called by COPY FILES, DELETE FILES, DISK MAP,
* BOOTPG, VIEW FILES, UNDELETE, and VERIFY FILES
SWPCHK
            LDA   DOSNOW
            STA   CURDOS
:SWPCHK0    LDA   #>PFX
            LDY   #PFX
            LDX   #>VTOC1
            JSR   SWCK
            BCS   :SWPCHK0
            RTS
* alternate entry point also called by COPY FILES
SWCK
* -> A/Y points to prefix
* -> X is high byte of VTOC buffer
            STA   PFXADR+1
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
:BADSWP     LDA   #MINCDISK
            JSR   LOWMES
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
SWPRET      EQU   *
            RTS
:VTOC       DB    $0
:LEN        DB    $0
*
*
* ONLY THE FORMAT ROUTINE CARES ABOUT
* THE CARRY STATUS RETURNED BY *DOSTYP.
*
* called by COPY DISK, DELETE DISK(DELLIB),
* FORMAT(DELLIB), SWCK
DOSTYP
            LDA   #0
            STA   RRTN
            LDA   UNIT
            STA   :UNIT
            JSR   SETSD
            LDA   CURDEV
            ASL
            ASL
            ASL
            ASL
            STA   :BUFF
            JSR   MLI
            DB    $C5
            DW    :OLNLST
            LDX   :BUFF
            LDA   VOLNMS,X
            AND   #$0F
            BEQ   :ERR
            STA   :TEMP
            INX
            LDY   #0
:MOVELP     LDA   VOLNMS,X
            CPY   :TEMP
            BCC   :USEIT
            LDA   #0
            BEQ   :CHROK
:USEIT      CMP   #$5B        ;'Z'+1
            BCS   :ERR52      ;>Z
            CMP   #$41
            BCS   :CHROK      ;A-Z
            CPY   #0
            BEQ   :ERR52      ;IS 1ST
            CMP   #$2E
            BEQ   :CHROK      ;.
            CMP   #$30
            BCC   :ERR52      ;<0
            CMP   #$3A
            BCS   :ERR52      ;>9
:CHROK      STA   VOLNAM,Y
            INX
            INY
            CPY   #$10
            BCC   :MOVELP
*
* VALID PRODOS DISK
*
            BCS   :ISPRO
*
*
* PRODOS DISK WITH INVALID VOLUME NAME
*
:ERR52      LDA   #$52
            BNE   :DTERR
*
:ERR        LDA   VOLNMS+$1,X
:DTERR      STA   RRTN
*
            CMP   #$52
            BNE   :NOT52
*
* ERROR=$52 (NOT A PRODOS DISK). IF
* DEVICE IS A FLOPPY, ASSUME
* DOS 3.3.  IF DEVICE IS NON-FLOPPY,
* ASSUME PRODOS. IN EITHER CASE
* RETURN C=0.
*
            JSR   UNTDV0
            LDX   #$52        ;RESTORE ERR
            STX   RRTN
            TAX               ;RESTORE Z
            CLC
            BCC   :CKUNIT     ;ALWAYS
*
* IF ERR <> 52 AND ERR > 3F, RETURN
* WITH C=0 SO FORMAT KNOWS THAT DISK
* WAS READABLE.
*
:NOT52      CMP   #$40
            BCS   :ISPRO      ;ERR # > $3F
*
* ERROR <$40, WHICH MEANS AN I/O ERR.
* IF NON-FLOPPY, ASSUME PRODOS.
* IF FLOPPY, ASSUME DOS 3.3. IN EITHER
* CASE, RETURN C=1.
*
            JSR   UNTDV0
            SEC
:CKUNIT     BEQ   :COMDUN     ;A ALREADY 0
            BNE   :ISPRO0
*
:ISPRO      CLC
:ISPRO0     LDA   #$FF        ;ASSUME PRODOS
*
:COMDUN     STA   DOSNOW
            PHP
            CMP   #0
            BNE   :SKIPFAK    ;NOT DOS
            LDA   #0
            JSR   FAKTRK
:SKIPFAK    LDX   :BUFF
            PLP
            LDA   DOSNOW
            RTS
*
:OLNLST     DB    $2
:UNIT       DB    $0
:BUFF       DW    VOLNMS
:TEMP       DB    $0
*
*
*
* READ TSLIST & UPDATE SECTOR POINTER
*
* called by RDDATA and also VERIFY
RDTSL
            LDA   RPAGE
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
            JSR   PHRWTS      ;READ DATA
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
OPNSRC
            JSR   OPNFIL
            BCS   :ERR1
            RTS
:ERR1       JMP   ERROUT
*
* called by OPNSRC (above) and VERIFY
OPNFIL
            JSR   CURPNT      ;POINT TO FILE
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
DISKLIBEND
