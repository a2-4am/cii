            TYP   BIN
            DSK   ../build/PRODOS.O
            PUT   VARS
            PUT   ../build/DRIVE35.VARS
            ORG   DRIVE35END

**********************************
*         PRODOS LIBRARY         *
* always returns to caller (never*
* calls IO routines/print error) *
*                                *
* RDBLK - read block             *
* RDBLK2 - read block 2 specifically*
* WTBLK - write block            *
* FNBLK1 - find block            *
* GTBLKS - get device size       *
* READBM - read volume bitmap    *
* TOTBLK - set by READBM         *
* BMLEN - set by READBM          *
* BMBLK - set by READBM          *
* MRKBLK - mark block in bitmap  *
* BITS - used by MRKBLK,DISKMAP  *
* BLKCNT - set by MRKBLK,DISKMAP *
* SWAPIB - swap index block      *
* SETSD - set slot/drive by unit *
* SPLFRM - format SmartPort device*
* UNTDEV - device info by unit   *
* UNTDV0 - device info current unit*
* DEVTYP - get current device info*
* DVTYPX - get device info       *
* GODEV - vector to device info  *
**********************************

*
RDBLK2      LDA   #>VTOC1
            STA   RPAGE
            LDA   #0
            STA   BLKNUM+1
            LDA   #2
            STA   BLKNUM
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
* called by READLIB and VERIFY
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
* SmartPort Format
* called by COPY, FORMAT(DELLIB), and QUIT
*
SPLFRM      LDA   #3
SPLGO1      EQU   *
            STA   $42
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
* called by COPY DISK, COPY DOS, COPY FILES, and QUIT
UNTDEV      STA   UNIT
*
* alternate entry point called by DOSTYP(DISKLIB)
UNTDV0      LDA   #0
* [4am] clear GODEV ptr before starting
* so caller can tell if it didn't work
            STA   GODEV+1
            STA   GODEV+2
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
* RETURNS
* A = 0 --> DISK II
* A = 1 --> /RAM
* A = 2 --> ROM DEVICE DRIVER DEVICE
* A = 3 --> RAM DEVICE DRIVER DEVICE
*
* BIT 7 OF X = 1 --> REMOVABLE MEDIA
* BIT 3 OF X = 1 --> CAN FORMAT DEVICE
* BITS 1 & 0 = BITS 1 & 0 OF A REG.
*
* EXAMPLES:
* DISK II   : A = 0, X = $88
* /RAM      : A = 1, X = $09
* ROM DEVICE: A = 2, X DEPENDS ON CsFE
* RAM DEVICE: A = 3, X = $8B
*
* called by COPY DISK, DELETE DISK, DISK MAP, and VERIFY
DEVTYP      LDX   CURDEV
* alternate entry point called by DODEV
* takes device ID in X
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
* READ VOLUME BITMAP
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
            JSR   RDBLK
            BCS   :READBMER
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
:NXTBLK     JSR   RDBLK
            BCS   :READBMER
            INC   BLKNUM
            BNE   :READBM2
            INC   BLKNUM+1
:READBM2    INC   RPAGE
            INC   RPAGE
            DEC   :TEMP
            BNE   :NXTBLK
            CLC
            RTS
:READBMER   SEC
            RTS
:TEMP       DB    $0
TOTBLK      DB    $0,$0
BMLEN       DB    $0
BMBLK       DB    $0,$0
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
PRODOSEND
