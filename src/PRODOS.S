**************************************
*          PRODOS ROUTINES           *
**************************************
*
*
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
            JSR   FAKTRK
:SKIPFAK    LDX   :BUFF
            PLP
            LDA   DOSNOW
            RTS
*
*
*
:OLNLST     DB    $2
:UNIT       DB    $0
:BUFF       DW    VOLNMS
:TEMP       DB    $0
*
*
*
*GTBLKS
*------
*
* RETURNS IN X & Y THE TOTAL NUMBER OF
* BLOCKS ON THE DEVICE.
* RETURNS C = 1 IF THE DEVICE DOES
* NOT HAVE A STANDARD DIRECTORY
* STRUCTURE (/RAM ONLY?).
*
* called by COPY DISK, DELETE DISK(DELLIB),
* UNDELETE, VERIFY
GTBLKS      JSR   DEVTYP
            BCS   :RAM
            BEQ   :DISKII
*
* DEVICE IS NOT A DISK II OR /RAM.
* GET NUMBER OF BLOCKS FROM DRIVER ROM
* IF ROM DRIVER OR THRU STATUS CALL
* IF RAM DRIVER.
*
            CMP   #3
            BNE   ROMBLK
*
:RAMDRVR    JSR   RDBLK2
            BCS   NOTROM
            LDX   VTOC1+$29
            LDY   VTOC1+$2A
*
* CARRY IS ALREADY CLEAR
*
            RTS
*
:DISKII     LDX   #$18
            LDY   #1
            CLC
            RTS
*
* FOR /RAM, GET NUMBER OF BLOCKS FROM
* BLOCK 2. THIS IS TO TAKE CARE OF
* CASES WHERE /RAM IS LARGER THAN 127
* BLOCKS. (I.E. APPLIED ENGINEERING
* RAMWORKSS II). WE WILL ASSUME THAT
* ALL /RAMs, REGARDLESS OF SIZE, SET
* UP THERE OWN, PROBABLY NON-STANDARD,
* DIRECTORY AND BITMAP.
*
:RAM        JSR   :RAMDRVR
            SEC
            RTS
*
ROMBLK      EQU   *
            LDY   #$FC
            LDA   (TMPPTR),Y  ;BLKS LO
            TAX
            INY
            LDA   (TMPPTR),Y  ;BLKS HI
            TAY
            BNE   GTBDON      ;BLKS VALID
            CPX   #0
            BNE   GTBDON      ;BLKS VALID
*
* GET TOTAL BLOCKS THRU STATUS REQUEST
*
NOTROM      EQU   *
            LDA   #0
            JSR   SPLGO1
GTBDON      EQU   *
            CLC
            RTS
*
*

*
*
* MARK BLOCK AS USED IN BITMAP
*
* RETURNS: BNE --> BLOCK WAS FREE
*    BEQ --> BLOCK ALREADY IN USE
*
* called by DELETE DISK, UNDELETE
MRKBLK      STX   POINT
            LSR
            ROR   POINT
            LSR
            ROR   POINT
            LSR
            ROR   POINT
            CLC
            ADC   BM
            STA   POINT+1
            TXA
            AND   #7
            TAX
            LDY   #0
            LDA   (POINT),Y
            AND   BITS,X
            PHA
            LDA   BITS,X
            EOR   #$FF
            AND   (POINT),Y
            STA   (POINT),Y
            PLA
            PHA
            BEQ   :MRKOUT     ;DON'T INC
            INC   BLKCNT
            BNE   :MRKOUT
            INC   BLKCNT+1
:MRKOUT     PLA
            RTS
* used by MRKBLK (above) but also DISKMAP
BITS        DB    $80,$40,$20,$10,$08,$04,$02,$01
* used by MRKBLK (above) but also DISKMAP
BLKCNT      DB    $0,$0
*
* SWAP BOTTOM HALF AND TOP HALF OF INXDEX BLOCK
*
* called by D1FILE(DELLIB) and UNDELETE
SWAPIB      STY   :SWAPIB1+2
            STY   :SWAPIB3+2
            INY
            STY   :SWAPIB2+2
            STY   :SWAPIB4+2
            LDY   #0
:SWAPIB1    LDX   SIB,Y
:SWAPIB2    LDA   SIB+$100,Y
:SWAPIB3    STA   SIB,Y
            TXA
:SWAPIB4    STA   SIB+$100,Y
            INY
            BNE   :SWAPIB1
            RTS
*
*
*
DOWBLK      JSR   WTBLK
            BCS   DORBER
            RTS
*
RDBLK2      LDA   #>VTOC1
            STA   RPAGE
            LDA   #0
            STA   BLKNUM+1
            LDA   #2
            STA   BLKNUM
*
DORBLK      JSR   RDBLK
            BCS   DORBER
            RTS
DORBER      JMP   ERROUT
*
RDBLK       LDA   #$80
            DB    $2C
WTBLK       LDA   #$81
            STA   :OPER
            LDA   UNIT
            STA   :UNIT
            LDA   RPAGE
            STA   :BUFFHI
            LDA   BLKNUM
            STA   :BLKNUM
            LDA   BLKNUM+1
            STA   :BLKNUM+1
            JSR   MLI
:OPER       DB    $80
            DW    :RBLST
            STA   RRTN
            RTS
*
:RBLST      DB    $3
:UNIT       DB    $0
            DB    $0
:BUFFHI     DB    $0
:BLKNUM     DB    $0,$0
*
*
*
*
* called by CATALOG, DISKMAP, and UNDELETE
READBM      STA   BM
            STA   RPAGE
            STA   POINT+1
            LDA   #2
            STA   BLKNUM
            LDA   #0
            STA   POINT
            STA   BLKNUM+1
            JSR   DORBLK
            LDY   #$2A
            LDA   (POINT),Y
            STA   TOTBLK+1
            TAX
            DEY
            LDA   (POINT),Y
            STA   TOTBLK
            BNE   :PSPC1
            DEX
:PSPC1      TXA
            LSR
            LSR
            LSR
            LSR
            CLC
            ADC   #1
*
* A NOW CONTAINS # OF BLKS IN BITMAP
*
            STA   BMLEN
            STA   :TEMP
            LDY   #$27
            LDA   (POINT),Y
            STA   BLKNUM
            STA   BMBLK
            INY
            LDA   (POINT),Y
            STA   BLKNUM+1
            STA   BMBLK+1
            LDA   BM
            STA   RPAGE
:NXTBLK     JSR   DORBLK
            INC   BLKNUM
            BNE   :READBM2
            INC   BLKNUM+1
:READBM2    INC   RPAGE
            INC   RPAGE
            DEC   :TEMP
            BNE   :NXTBLK
            RTS
:TEMP       DB    $0
TOTBLK      DB    $0,$0
BMLEN       DB    $0
BMBLK       DB    $0,$0
*
*
*
* SHOW CURRENT SLOT & DRIVE
* AND/OR CURRENT PREFIX. (*PFX<>0)
*
* RETURNS WITH CV = 3, CH = 0
*
PRVNM       LDX   #PFX
            LDY   #>PFX
            LDA   UNIT
PRVCOM      STA   UNIT
            STX   TMPPTR
            STY   TMPPTR+1
            LDA   #0
            JSR   TABV
            LDA   CHOICE
            BNE   :CONTIN     ;CMD NOT COPY
            LDA   SDCH
            SEC
            SBC   #8
            STA   CH
            LDA   SRCTAR
            BNE   :NOTSRC
            JSR   PRHERE
            ASC   "Source:"
            DB    $0
            JMP   :CONTIN
*
:NOTSRC     CMP   #$FF
            BNE   :CONTIN
            JSR   PRHERE
            ASC   "Target:"
            DB    $0
*
:CONTIN     LDA   SDCH
            STA   CH
            LDA   UNIT
            JSR   SEEDEV
*            LDA   PRNTR?
*            BPL   :SKIPCR
*            JSR   CROUT
:SKIPCR     LDA   #1
            JSR   VLEFT
            LDY   #0
            STY   HEXNUM+1
            LDA   (TMPPTR),Y
            STA   :PFXLEN
            BMI   :BLNKLP     ;NO PFX
            BIT   DOSNOW
            BPL   :SDDOS33
            CMP   #0
            BEQ   :BLNKLP
            BNE   :SDPRODOS
*
:SDDOS33    LDY   #5
            LDA   (TMPPTR),Y
            BEQ   :BLNKLP
            STA   HEXNUM
            JSR   PRHERE
            ASC   "Disk Volume "
            DB    $0
            JSR   HEXDEC
            JSR   PRTLZ
            LDY   #$14
            BNE   :BLNKLP     ;ALWAYS
*
:SDPRODOS   INY
            LDA   (TMPPTR),Y
            ORA   #$80
            JSR   PCOUT
            CPY   :PFXLEN
            BCC   :SDPRODOS
:BLNKLP     INY
            LDA   #$A0
            JSR   PCOUT
            CPY   #$42
            BCC   :BLNKLP
:NOPFX      LDA   #3
            STA   WNDTOP
            JMP   VLEFT
:PFXLEN     DB    $0
*
GETDAT      JSR   MLI
            DB    $82
            DB    $0,$0
            LDY   #3
:LOOP       LDA   DATE,Y
            STA   CRTDAT,Y
            STA   MODDAT,Y
            DEY
            BPL   :LOOP
            RTS
*
*
SHDAT0      JSR   PRSPC
            LDA   (POINT),Y
            TAX
            DEY
            LDA   (POINT),Y
SHODAT      CMP   #0
            BEQ   :NODATE
            PHA
            STX   :DATEMP
            AND   #$1F
            JSR   HEXDC1
            JSR   PRT2DG      ;WAS PRT2RJ
            LDA   #"-"
            JSR   PCOUT
            PLA
            LSR   :DATEMP
            ROR
            LSR
            LSR
            LSR
            LSR
            TAX
            LDA   MONTH1-1,X
            JSR   PCOUT
            LDA   MONTH2-1,X
            JSR   PCOUT
            LDA   MONTH3-1,X
            JSR   PCOUT
            LDA   #"-"
            JSR   PCOUT
            LDA   :DATEMP
            JSR   HEXDC1
            JMP   PRT2DG
*
:NODATE     JSR   PRHERE
            ASC   "<No Date>"
            DB    $0
            RTS
:DATEMP     DB    $0
*
*
*
*
NODOS3      JSR   DOSTYP
            BCS   BLK2ER
            JSR   PRHERE
            DB    $8D,$8D,$8D
            ASC   "Not a DOS 3.3 function",8D,00
            JMP   PRESS
*
FLONLY      JSR   PRHERE
            DB    $8D,$8D,$8D
            ASC   "Disk II function only",8D,00
            JMP   PRESS
*
NOPRO       JSR   PRHERE
            DB    $8D,$8D,$8D
            ASC   "Not a ProDOS function",8D,00
            JMP   PRESS
*
BLK2ER      LDY   #0
            STY   BLKNUM+1
            DEY
            STY   DOSNOW
            LDA   #2
            STA   BLKNUM
            JMP   ERROUT
*
* called by COPY DISK, COPY DOS, COPY FILES, and QUIT
UNTDEV      STA   UNIT
*
* [4am] clear GODEV ptr before starting
* so caller can tell if it didn't work
*
            LDA   #0
            STA   GODEV+1
            STA   GODEV+2
UNTDV0      EQU   *
            LDX   NUMDEV
:LOOP       LDA   UNIT
            EOR   DVICES,X
            AND   #$F0
            BEQ   :GOTIT
            DEX
            BPL   :LOOP
*
* CAN'T FALL THROUGH
*
            RTS
:GOTIT      STX   CURDEV
* fall through to DEVTYP
*
*
* DEVTYP RETURNS INFO ON *CURDEV
*
* A = 0 --> DISK II
* A = 1 --> /RAM
* A = 2 --> ROM DEVICE DRIVER DEVICE
* A = 3 --> RAM DEVICE DRIVER DEVICE
*
* BIT 7 OF X = 1 --> REMOVABLE MEDIA
* BIT 3 OF X = 1 --> CAN FORMAT DEVICE
* BITS 1 & 0 = BITS 1 & 0 OF A REG.
*
* DISK II   : A = 0, X = $88
* /RAM      : A = 1, X = $09
* ROM DEVICE: A = 2, X DEPENDS ON CsFE
* RAM DEVICE: A = 3, X = $8B
*
* called by COPY DISK, DELETE DISK, DISK MAP, and VERIFY
DEVTYP      LDX   CURDEV
DVTYPX      LDA   #0
            STA   TMPPTR
            LDA   DVICES,X
            STA   TEMP2
            AND   #$F0
            LSR
            LSR
            LSR
            PHA
            LSR
            AND   #7
            ORA   #$C0
            STA   TMPPTR+1
            PLA
            TAY
            LDA   DEVADR,Y
            STA   GODEV+1
            LDA   DEVADR+$1,Y
            STA   GODEV+2
            CMP   #$FF
            BEQ   :RAM        ;MAYBE /RAM
            CMP   #$C8
            BCS   :RAMDRV
            CMP   #$C1
            BCC   :RAMDRV
            STA   TMPPTR+1
*
* ROM BASED DRIVER. GET REMOVABLE MEDIA
* BIT AND CAN FORMAT BIT FROM CsFE.
* FIRST GET NUMBER OF BLOCKS AND SEE
* IF $118
*
            JSR   ROMBLK
            CPX   #$18
            BNE   :ROMDRV1
            DEY
            BEQ   :ISDSKII    ;ASSUME DISK II
:ROMDRV1    LDY   #$FE
            LDA   (TMPPTR),Y
            AND   #$88
            BMI   :ISRMV
*
* [4am] This drive has a ROM-based driver,
* is not a Disk II, and CsFE claims that
* it is non-removable. But maybe we should
* treat it as removable anyway. Some modern
* peripherals such as CFFA3000 should really
* count as 'removable' media for our purposes,
* because the user can hot-swap the mounted
* disk image at any time, either through a
* physical switch or a GS CDA (or emulator UI,
* if they are using an emulated CFFA).
* This primarily affects whole-disk copy
* operations -- if the user selects a CFFA-
* controlled drive as both the source and
* target drive, we should prompt for the source
* and destination disks and assume the user can
* handle swapping out the disk images when
* prompted.
*
* CFFA 1.0: $CsF6 = 43 46 46 41 10
* CFFA 1.2: $CsF6 = 43 46 46 41 12
* CFFA 2.0: $CsF6 = 43 46 46 41 FF
* CFFA3000: $CsF6 = 43 46 33 4B 31

            TAX
            LDY   #$F6
            LDA   (TMPPTR),Y
            CMP   #$43
            BNE   :NOTCFFA
            INY
            LDA   (TMPPTR),Y
            CMP   #$46
            BNE   :NOTCFFA
            INY
            LDA   (TMPPTR),Y
            CMP   #$46
            BNE   :MAYBE3K
            INY
            LDA   (TMPPTR),Y
            CMP   #$41
            BNE   :NOTCFFA
            BEQ   :ISCFFA     ;ALWAYS
:MAYBE3K    CMP   #$33
            BNE   :NOTCFFA
            INY
            LDA   (TMPPTR),Y
            CMP   #$4B
            BNE   :NOTCFFA
:ISCFFA     TXA
            ORA   #$80        ;BIT 7=REMOVABLE
            TAX
:NOTCFFA    TXA
:ISRMV      ORA   #$02
:COMOUT     CLC
            DB    $B0
:RAMOUT     SEC
            TAX
            AND   #$03
            RTS
*
:RAM        LDA   GODEV+1
            BNE   :RAMDRV     ;NOT /RAM
*
* DRIVER ADDRESS IS $FF00, NOW CHECK
* IF ENTRY IN DEVICE TABLE IS $BF.
* IF NOT, THAN THIS IS REALLY SOME
* OTHER TYPE OF RAM BASED DRIVER
* THAT SITS AT $FF00. (PROBABLY
* THE APPLIED ENGINEERING RAM
* DISK).
*
* THIS CODE COMMENTED OUT 5/6/86.
* PUT BACK IN 8/26/86
*
            LDA   #$09
            LDX   TEMP2
            CPX   #$BF
            BEQ   :RAMOUT     ;IT IS /RAM
*
* IT IS SOME SORT OF /RAM DEVICE,
* BUT NOT THE USUAL ONE
*
            LDA   #$0B
            BNE   :RAMOUT
*
*
* RAM-BASED DRIVER OR DISK II
*
:RAMDRV     LDX   #3
:DIICHK     LDY   :TBL1,X
            LDA   (TMPPTR),Y
            EOR   :TBL2,X
            BNE   :NOTDII
            DEX
            BPL   :DIICHK
*
* IT IS A DISK II
*
:ISDSKII    LDA   #$88
            BNE   :COMOUT
*
:NOTDII     LDA   #$8B
            BNE   :COMOUT
*
:TBL1       DB    $01,$03,$05,$FF
:TBL2       DB    $20,$00,$03,$00
*
GODEV       JMP   $0000
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
*
* only called by DOCAT
PDOCAT      LDA   RCMND
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
* called by COPY FILE and MAKESUB
MKDIR       LDA   #$0D
            BNE   PCTCOM
*
* called by COPY FILE
PCREAT      LDA   #1
PCTCOM      EQU   *
            STA   :STRTYP
            LDA   FTYPE
            STA   :FTYPE
            LDA   AUXTYP
            STA   :AUXTYP
            LDA   AUXTYP+1
            STA   :AUXTYP+1
            LDA   CRTDAT
            STA   :CRTDAT
            LDA   CRTDAT+1
            STA   :CRTDAT+1
            LDA   CRTTIM
            STA   :CRTTIM
            LDA   CRTTIM+1
            STA   :CRTTIM+1
            JSR   MLI
            DB    $C0
            DW    :CRTLST
            STA   RRTN
            RTS
*
:CRTLST     DB    $7
            DW    FILE
:ACCESS     DB    $E3
:FTYPE      DB    $0
:AUXTYP     DB    $0,$0
:STRTYP     DB    $0
:CRTDAT     DB    $0,$0
:CRTTIM     DB    $0,$0
*
*
PDSTRY      JSR   PUNLOK
            JSR   DOMLI
            DB    $C1
            DW    :DESLST
            RTS
:DESLST     DB    $1
            DW    FILE
*
*
*
SETPFX      LDX   #PFX
            LDA   #>PFX
STPFXC      STA   TMPPTR+1
            STX   TMPPTR
            LDY   #$3F
:MVLP       LDA   (TMPPTR),Y
            STA   PFX,Y
            DEY
            BPL   :MVLP
            JSR   MLI
            DB    $C6
            DW    :PFXLST
            BCC   :OUT
            STA   RRTN
:OUT        RTS
:PFXLST     DB    $1
            DW    PFX
*
*
PLOK        LDA   #$1
            DB    $2C
PUNLOK      LDA   #$C3
            STA   :TEMP+1
            JSR   GTINFO
:TEMP       LDA   #1
            STA   INFLST+3
*
* FALL INTO STINFO
*
*
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
MLIERR      LDA   RRTN
            CMP   #$48        ;DISK FULL?
            BNE   ERROUT      ;NOPE
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
            JSR   WRCAT2
            LDA   #$48
ERROU1      STA   RRTN
*
ERROUT      JSR   CROUT
            JSR   OUCH
            JMP   FILER
*
*
*
DEVFLG      DB    $0
DODEVF      LDA   #$FF
            DB    $2C
DODEVP      LDA   #0
DODEV0      EQU   *
            STA   DEVFLG
            JSR   HOME
            JSR   PRHERE
            ASC   "Select device:"
            DB    $0
            LDA   CURDVA
            JSR   JDODEV
            STX   CURDVA
            RTS
*
* called by COPY FILE and DELETE FILE(DELLIB)
DOWAIT      LDX   #$03
:WAITLP     LDA   #$C4
            JSR   WAIT
            DEX
            BNE   :WAITLP
            RTS
*
TREEA       JSR   DOSTYP
            LDA   #APFX
            STA   PFXADR
            LDA   #>APFX
            STA   PFXADR+1
            LDA   ACURR
            JSR   JDOTREE
            BCS   SETA        ;I/O ERROR
            STA   ACURR
            RTS
SETA        JSR   DOSTYP
            LDA   UNIT
*           JMP   UNTPFX
* falls through to UNTPFX
*
* SET PREFIX TO UNIT IN A REG
*
UNTPFX
            LDA   UNIT
            STA   :UNIT
* BIT *DOSNOW
* BPL DOS33
            JSR   MLI
            DB    $C5
            DW    :ONLST
            LDA   PFX+1
            AND   #$0F
            BNE   :PRODOS
:DOS33      LDA   #0
            STA   ADRVOL
            STA   PFX
            LDA   PFX+2
            CMP   #$28
            BEQ   :NOTDSK2    ;NO DRIVE
            BIT   DOSNOW
            BMI   :NOTDSK2
            JSR   RDDRIVE
:NOTDSK2    LDA   ADRVOL
            STA   PFX+5
            CLC
            RTS
*
:ONLST      DB    $2
:UNIT       DB    $0
            DW    PFX+1
*
:PRODOS     LDA   PFX+1
            AND   #$0F
            TAY
            INY
            STY   PFX
            LDA   #$2F        ;"/"
            STA   PFX+1
            JSR   MLI
            DB    $C6
            DW    :SPLST
            STA   RRTN
            RTS
*
:SPLST      DB    $1
            DW    PFX
*
SRCTAR      DB    $0
*
*
* Setup HSLOT and HDRIVE from UNIT number passed in A
*
SETSD
            STA   UNIT
            PHA
            AND   #$70
            STA   HSLOT
            TAX
            PLA
            ASL
            LDA   #1
            ADC   #0
            STA   HDRIVE
*
* Check if we have to translate the slot and drive numbers
*
*CPX #$20
*BEQ :CKUDC
*CPX #$50
*BNE :SETSD9
*
* Slot number is 2 or 5: check if slot 5 has UDC
*
            TXA
            CPX   #$20
            BNE   :CKUDC0
            LDA   #$50
:CKUDC0
            STA   :UDCSLOT
            LSR
            LSR
            LSR
            LSR
            ORA   #$C0
            STA   :CKUDC2+2
*:CKUDC
            LDA   $CFFF
            LDY   #5
:CKUDC1
            LDX   :UDCTBL1,Y
:CKUDC2     LDA   $C500,X
            CMP   :UDCTBL2,Y
            BNE   :SETSD9     ;Not a UDC
            DEY
            BPL   :CKUDC1
*
* Slot 5 contains a UDC
*
            LDY   HDRIVE
            LDA   HSLOT
            CMP   #$20
            BNE   :CKUDC3
            INY
            INY
:CKUDC3
            LDA   $CAD2-1,Y
            CMP   #2
            BCS   :SETSD9     ;Never(?)
            ADC   #1          ;C already clear
            STA   HDRIVE
            LDX   :UDCSLOT
            STX   HSLOT
:SETSD9
            RTS
*
:UDCSLOT    DB    0
:UDCTBL1    DB    $00,$01,$03,$05,$07,$12
:UDCTBL2    DB    $E5,$20,$00,$03,$00,$4C
*
*
* CHECK IF WE ARE DIVING IN TO OR OUT
* OF THE STARTING DIRECTORY. IF SO,
* RESTORE OR SAVE *STATUS, *CBYTE,
* *CSECTR,*FILNUM
*
* called by COPY FILES and DELETE FILES(DELLIB)
DIVECK      BCS   :GOOUT
            LDA   SP
            CMP   #1
            BNE   :DVCK00
            LDX   #>STATUS
            LDY   HIMEM
            DEY
            DEY
            DEY
            STY   :MYHI
            LDA   FILNUM
            STA   :SAVE1
            LDA   #4
            STA   TOPDIF
            JSR   :DVCK0
            LDA   HIMEM       ;8/27/86
            JSR   SETHIM      ;8/27/86
:DVCK00     JMP   :DVINIT
*
:GOOUT      LDA   SP
            BNE   :DVINIT
            JSR   :DVINIT
            LDX   :MYHI
            LDY   #>STATUS
            LDA   :SAVE1
            STA   FILNUM
            LDA   #0
            STA   TOPDIF
*
:DVCK0      STX   POINT+1
            STY   MESPNT+1
            LDY   #0
            STY   MESPNT
            STY   POINT
            LDX   #3
:DCKLP      LDA   (POINT),Y
            STA   (MESPNT),Y
            INY
            BNE   :DCKLP
            INC   POINT+1
            INC   MESPNT+1
            DEX
            BNE   :DCKLP
            RTS
:SAVE1      DB    $0
:MYHI       DB    $0
*
*
* INITIALIZE THINGS AFTER DIVING IN TO
* OR OUT OF A SUBDIRECTORY
*
:DVINIT     LDA   CURR
            PHA
            JSR   INITCD
            PLA
            STA   CURR
            JSR   RDACNT
            LDA   NACTIV
            STA   FILNUM
            SEC
            BEQ   :DVINT1     ;NO FILES
            LDX   #0
:CFLP2      INX
            TXA
            STA   STATUS-1,X
            CPX   NACTIV
            BCC   :CFLP2
            CLC
:DVINT1     RTS
*
* called by COPY DISK, COPY FILE, DELETE FILE
SETHIM      SEC
            SBC   DATADR
            AND   #$FE
            CLC
            ADC   DATADR
            SEC
            SBC   TOPDIF      ;0 OR 3
            STA   HIMEM
            RTS
