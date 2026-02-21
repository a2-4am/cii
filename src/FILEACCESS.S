*************************************
*       FILE ACCESS ROUTINES        *
*************************************
*
RDCAT1      LDA   #>CAT1
            JSR   CLRCAT
            LDX   #>VTOC1
RDCT1A      EQU   *
            LDA   #$01
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
WDERR       EQU   *
            LDA   #$52
            JMP   ERROU1
*
WRCAT2      BIT   DOSNOW
            BPL   :DOS33
            JMP   CLOSE
*
:DOS33      LDX   #>VTOC2
WRCT2A      EQU   *
            LDA   #2
DOCAT       EQU   *
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
* called by RDACNT(CATLIB), DELETE DISK(DELLIB),
* RDCAT1, and RDCAT2 (above)
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
* SET POINTER FROM CATALOG ARRAY
*
CURPNT      LDX   CURR
SETPNT      LDA   CBYTE,X
            STA   POINT
            LDA   CSECTR,X
            STA   POINT+1
            RTS
*
* MAKE A 1-BIT MASK FOR A BITMAP WORD
* SECTOR # IN ACC ->
* called from COPY, DISKMAP, FREES(DELLIB),
* and UNDELETE
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
* DOS?
* read T00S00 and check for recognized DOS-shaped bootloader
* called by Copy DOS (COPY) and Delete DOS (DELLIB)
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
:NODOS      LDA   #MNODOS
            JMP   PRTPRS
*
* called by DOS? (above) and also CHANGEBOOT
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
* called by DOS? (above) and also CHANGEBOOT
PUTSEC      STX   RSECTR      ;SET SECTOR
            LDA   #>DATA
            STA   RPAGE       ;SET ADDR
            LDA   #$01
            STA   RTRACK      ;SET TRACK
            STA   RCMND       ;SET COMMAND
            RTS
*
SDFLG       DB    $0
*
* SWAP CHECK
* to the best of our ability, ensure that the correct
* disk is in the drive
*
* called by COPY FILES, DELETE FILES, DISK MAP,
* BOOTPG, VIEW FILES, UNDELETE, and VERIFY FILES
SWPCHK      LDA   DOSNOW
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
            RTS
:VTOC       DB    $0
:LEN        DB    $0
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
* READ TSLIST & UPDATE SECTOR POINTER
* called by RDDATA
RDTSL       JSR   RDTSL1
            BCS   ERR1
SWPRET      RTS
*
* called by RDDATA and DISKMAP
FNDBLK      JSR   FNBLK1
            BCC   :FND1
:ERR?       CMP   #$FF
            BEQ   ERR1
            SEC
:FND1       RTS
ERR1        JMP   ERROUT
*
* called by FNDBLK (above) and VERIFY
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
* called by CATALOG, COPY, DISKMAP, and VIEW
OPNSRC      JSR   OPNFIL
            BCS   ERR1
            RTS
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
            STA   RCMND       ;FALL THRU...
*
* called by RDTSL (above) and VERIFY
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
* SmartPort Format
* called by COPY, FORMAT(DELLIB), and QUIT
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
            AND   #$FE        ;/!\ assumes SDIR is aligned to even page boundary
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
* COMMON TREE
* Choose ProDOS device then choose directory
* called by ALPHABETIZE, DELETE(DELLIB),
* RENAME FILES, MAKESUB, UNDELETE, VERIFY, and VIEW
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
*
* SLIDE SELECTED FILES TO TOP OF
* STATUS ARRAY (ARROW FLAGGED)
*
* called by COPY, DELETE, UNDELETE, and
* VERIFY after files have been selected
* in the catalog display and the user
* has asked to begin the process
*
PATMOV      LDX   #$00
            LDY   #$00
:LOOP       LDA   STATUS,Y
            BEQ   :NEXT
            STA   STATUS,X
            LDA   CBYTE,Y
            STA   CBYTE,X
            LDA   CSECTR,Y
            STA   CSECTR,X
            INX
:NEXT       INY
            CPY   NACTIV
            BCC   :LOOP
            STX   FILNUM
            RTS
*
* called by DIVEIN(DELLIB) and DISKMAP
DIR?        LDY   #0
            LDA   (POINT),Y
            AND   #$F0
            CMP   #$D0
            BNE   :NOTDIR
            LDY   #$10
            LDA   (POINT),Y
            CMP   #$0F
            CLC
            BEQ   :OUT
:NOTDIR     SEC
:OUT        RTS
*
* SHOW A LINE OF CATALOG
CATLIN      PHA
            JSR   PRSPC
            JSR   PRSPC
            PLA
            JMP   CATLN1
