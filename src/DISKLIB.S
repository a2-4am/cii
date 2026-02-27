            TYP   BIN
            DSK   ../build/DISKLIB.O
            PUT   VARS
            PUT   ../build/PHRWTS.VARS
            PUT   ../build/PRODOS.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/UILIB.VARS
            PUT   ../build/READLIB.VARS
            ORG   READLIBEND

**********************************
*          DISK LIBRARY          *
* DORBLK - read block (w/error)  *
* DOWBLK - write block (w/error) *
* FNDBLK - find block (w/error)  *
* DOVTOC - read/write VTOC       *
* CLRCAT - clear catalog sectors *
* DOCAT - read/write catalog     *
* DOMASK - make a bitmap mask    *
* STVTOC - setup for R/W VTOC    *
* DOS? - read T00S00, is DOS boot?*
* CHKDOS - buffer is DOS boot?   *
* PUTSEC - write sector to T01   *
* SET1A2 - mark T01+T02 in VTOC  *
* DORWTS - call PHRWTS (w/error) *
* SDFLG - used by SWCK           *
* SWPCHK - is correct disk? w/err*
* SWCK - verify is correct disk  *
* DOSTYP - ProDOS or DOS?        *
* PATMOV - reorder STATUS array  *
* DIR? - *POINT is directory?    *
**********************************

*
DOWBLK      JSR   WTBLK
            BCS   DORBER
            RTS
*
DORBLK      JSR   RDBLK
            BCS   DORBER
            RTS
DORBER      EQU   *
            JMP   ERROUT
*
* READ/WRITE VTOC, READY FOR CATALOG
*
* TAKES PAGE IN X
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
                              ;R/W CATALOG
            >>>   JSRMODULE,PHRWTSLIB;PHRWTSINTERNAL
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
* called by DOS? and also CHANGEBOOT
PUTSEC      STX   RSECTR      ;SET SECTOR
            LDA   #>DATA
            STA   RPAGE       ;SET ADDR
            LDA   #$01
            STA   RTRACK      ;SET TRACK
            STA   RCMND       ;SET COMMAND
            RTS
*
SET1A2      STA   CVTOC+$3C
            STA   CVTOC+$3D
            STA   CVTOC+$40
            STA   CVTOC+$41
            LDA   #2
            STA   RCMND
* falls through to DORWTS
DORWTS
            >>>   JSRMODULE,PHRWTSLIB;PHRWTSINTERNAL
            BCS   DISKLIBERR
            RTS
*
DISKLIBERR  EQU   *
            JMP   ERROUT
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
DOSTYP      LDA   #0
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
            >>>   JSRMODULE,PHRWTSLIB;FAKTRKINTERNAL
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
*
NODOS3      JSR   DOSTYP
            BCS   :BLK2ER
            LDA   #MNODOS3
            JMP   PRTPRS
:BLK2ER     JMP   BLK2ER
*
DISKLIBEND
