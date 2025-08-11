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
:USEIT      CMP   #$5B             ;'Z'+1
            BCS   :ERR52           ;>Z
            CMP   #$41
            BCS   :CHROK           ;A-Z
            CPY   #0
            BEQ   :ERR52           ;IS 1ST
            CMP   #$2E
            BEQ   :CHROK           ;.
            CMP   #$30
            BCC   :ERR52           ;<0
            CMP   #$3A
            BCS   :ERR52           ;>9
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
            LDX   #$52             ;RESTORE ERR
            STX   RRTN
            TAX                    ;RESTORE Z
            CLC
            BCC   :CKUNIT          ;ALWAYS
*
* IF ERR <> 52 AND ERR > 3F, RETURN
* WITH C=0 SO FORMAT KNOWS THAT DISK
* WAS READABLE.
*
:NOT52      CMP   #$40
            BCS   :ISPRO           ;ERR # > $3F
*
* ERROR <$40, WHICH MEANS AN I/O ERR.
* IF NON-FLOPPY, ASSUME PRODOS.
* IF FLOPPY, ASSUME DOS 3.3. IN EITHER
* CASE, RETURN C=1.
*
            JSR   UNTDV0
            SEC
:CKUNIT     BEQ   :COMDUN          ;A ALREADY 0
            BNE   :ISPRO0
*
:ISPRO      CLC
:ISPRO0     LDA   #$FF             ;ASSUME PRODOS
*
:COMDUN     STA   DOSNOW
            PHP
            CMP   #0
            BNE   :SKIPFAK         ;NOT DOS
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
*
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
ROMBLK      LDY   #$FC
            LDA   (TMPPTR),Y       ;BLKS LO
            TAX
            INY
            LDA   (TMPPTR),Y       ;BLKS HI
            TAY
            BNE   GTBDON           ;BLKS VALID
            CPX   #0
            BNE   GTBDON           ;BLKS VALID
*
* GET TOTAL BLOCKS THRU STATUS REQUEST
*
NOTROM      LDA   #0
            JSR   SPLGO1
GTBDON      CLC
            RTS
*
*

*
* DELETE PRODOS DISK
*
* USED TO CREATE NEW DIRECTORY FOR
* FORMAT COMMAND AND FOR DELETE DISK
* COMMAND
*
PDDISK      JSR   GTBLKS
            BCC   :PDD0
*
* IT'S SOME SORT OF /RAM. IF IT'S
* A LARGE ONE, FORMAT IT.
*
            CPY   #0
            BEQ   :NADA
            JMP   SPLFRM           ;FORMAT IT
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
            ASL                    ;2 --> 4
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
:BM2        JSR   PNTFIL0          ;RETURNS WITH Y=0
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
            BEQ   :MARKDN          ;ONE BLK BM
            STA   :TEMP
            LDA   #6
            STA   BLKNUM
            LDA   #>VTOC1
            STA   BM
            JSR   DORBLK
:MARKIT     LDX   :TEMP            ;BLK LO
            LDA   #0               ;BLK HI
            JSR   MRKBLK
            DEC   :TEMP
            LDA   :TEMP
            CMP   #7
            BCS   :MARKIT
            JSR   DOWBLK
:MARKDN     RTS
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
*
* MARK BLOCK AS USED IN BITMAP
*
* RETURNS: BNE --> BLOCK WAS FREE
*    BEQ --> BLOCK ALREADY IN USE
*
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
            BEQ   :MRKOUT          ;DON'T INC
            INC   BLKCNT
            BNE   :MRKOUT
            INC   BLKCNT+1
:MRKOUT     PLA
            RTS
BITS        DB    $80,$40,$20,$10,$08,$04,$02,$01
BLKCNT      DB    $0,$0
*
*
*
SMART       JSR   CURPNT
            LDA   STRTYP
            CMP   #$20
            BEQ   :ISSAP
            JMP   :NOPE
*
:ISSAP      LDY   #1
            STY   IBPTR
            STY   MIBPTR
*
* SET FILE LOCK/UNLOCK INDICATOR = '?'
*
            LDY   #$1E
            LDA   #$81
            STA   (POINT),Y
            LDY   #$11
            LDA   (POINT),Y
            STA   BLKNUM
            STA   :STRTBLK
            STA   :IBBLK
            STA   :MIBBLK
            INY
            LDA   (POINT),Y
            STA   BLKNUM+1
            STA   :STRTBLK+1
            STA   :IBBLK+1
            STA   :MIBBLK+1
            INY
            LDA   (POINT),Y
            STA   :BLKTOTL
            INY
            LDA   (POINT),Y
            STA   :BLKTOTL+1
*
* RIGHT NOW, BLKTOTL=TOTAL # OF BLOCKS
* LEFT THAT WE HAVE TO ALLOCATE TO
* THIS FILE. BLKNUM=BLOCK BEFORE 1ST
* BLOCK TO ATTEMPT ALLOCATION WITH.
*
            JSR   GTBLKS
            STX   :MAXBLK
            STY   :MAXBLK+1

*

* EXAMINE BLOCKS FROM KEY BLOCK TO
* END OF VOLUME FOR AVAILABILITY.
*
            JSR   :DOSOME
            BCS   :GOTEM           ;DONE
*
* EXAMINE BLOCKS FROM START OF VOLUME
* TO KEY BLOCK FOR AVAILIBILITY.
*
            LDA   #0
            STA   BLKNUM
            STA   BLKNUM+1
            LDA   :STRTBLK
            STA   :MAXBLK
            LDA   :STRTBLK+1
            STA   :MAXBLK+1
            JSR   :DOSOME
            BCC   :NOPE            ;UNRECOVERABLE
*
* FILE SUCCESSFULLY UNDELETED
* WRITE INDEX BLOCK AND MASTER BLOCK
* OUT TO DISK. THEN WRITE OUT
* DIRECTORY AND BITMAP
*
:GOTEM      LDA   :IBBLK
            STA   BLKNUM
            LDA   :IBBLK+1
            STA   BLKNUM+1
            LDA   #>SIB
            JSR   WTBLK
            BCS   :NOPE
            LDA   STRTYP
            CMP   #$30
            BNE   :GOTEM1          ;NOT TREE
            LDA   :MIBBLK
            STA   BLKNUM
            LDA   :MIBBLK+1
            STA   BLKNUM+2
            LDA   #>SMIB
            JSR   WTBLK
            BCS   :NOPE
:GOTEM1     JMP   UNDOIT
:NOPE       JMP   MRKBAD
*
*
:DOSOME     INC   BLKNUM
            BNE   :SMART1
            INC   BLKNUM+1
:SMART1     LDA   BLKNUM
            CMP   :MAXBLK
            BNE   :SMART2
            LDA   BLKNUM+1
            CMP   :MAXBLK+1
            CLC
            BEQ   :MARKIT2         ;HIT MAX VALUE
:SMART2     LDA   STRTYP
            CMP   #$30
            BNE   :SMART3
*
* WORKING WITH TREE FILE.
*
*
*
:SMART3     LDA   BLKNUM+1
            LDX   BLKNUM
            JSR   MRKBLK
            BEQ   :DOSOME          ;NO GOOD
            JSR   :ADDBLK
            LDA   BLKCNT
            CMP   :BLKTOTL
            BNE   :DOSOME
            LDA   BLKCNT+1
            CMP   :BLKTOTL+1
            BNE   :DOSOME
:MARKIT2    RTS
*
* ADD JUST ALLOCATED BLOCK TO INDEX
* BLOCK LIST
*
:ADDBLK     LDY   IBPTR
            LDA   BLKNUM
            STA   SIB,Y
            LDA   BLKNUM+1
            STA   SIB+$100,Y
            INC   IBPTR
            RTS
*
*
:STRTBLK    DB    $0,$0
:BLKTOTL    DB    $0,$0
:MAXBLK     DB    $0,$0
:IBBLK      DB    $0,$0
:MIBBLK     DB    $0,$0
*
*
PUNDO       JSR   PUNDO0
            BCS   MRKBAD

*
* LOOKS LIKE UNDELETE IS OK, BUT CHECK
* TO SEE IF THE NUMBER OF BLOCKS MARKED
* EQUALS NUMBER OF BLOCKS IN FILE.
*
            JSR   CURPNT
            LDY   #$13
            LDA   (POINT),Y
            CMP   BLKCNT
            BNE   DOMAYBE
            INY
            LDA   (POINT),Y
            CMP   BLKCNT+1
            BNE   DOMAYBE
*
* ALL BLOCKS OF FILE HAVE BEEN SUCCESSFULLY UNDELETED.
* NOW GO THRU INDEX BLOCKS AND RESTORE THEM TO PROPER ORDER
*
            JSR   SWAPEM
            BCC   UNDOIT           ;GOOD SWAP
*
MRKBAD      INC   BADNUM
            LDA   #$FF
            BNE   MRKCOM           ;ALWAYS
*
DOMAYBE     INC   MAYBE
            LDA   #$FE
*
* WIPE OUT FIRST CHAR OF FILENAME
*
MRKCOM      PHA
            JSR   CURPNT
            LDY   #0
            TYA
            STA   (POINT),Y
            PLA
MARKIT      LDX   CURR             ;MARK FILE
            STA   STATUS,X         ;GOOD OR BAD
            RTS
*
UNDOIT      JSR   WRITBM
*
* INCREMENT FILE COUNT
*
            INC   SDIR+$25
            BNE   :UNDO1
            INC   SDIR+$26
:UNDO1      JSR   WRCAT1
            LDA   #0
            BEQ   MARKIT           ;ALWAYS
*
KEYBLK      DB    0,0
*
*
********************************
*
* SWAPEM SWAPS HIGH PART OF INDEX BLOCK WITH LOW PART.
* IF SAPLING FILE, JUST SWAPS INDEX BLOCK
* IF TREE, SWAPS MASTER IB AND ALL INDEX BLOCKS
*
*
SWAPEM      EQU   *
            LDA   KEYBLK
            STA   BLKNUM
            LDA   KEYBLK+1
            STA   BLKNUM+1
            LDA   STRTYP
            CMP   #$30
            BEQ   :SWAPTRE
            CMP   #$20
            BNE   :GOODSWP
*
:SWAPSAP    LDY   #>SIB
            JSR   SWAPIB
            JSR   WTBLK
            BCC   :GOODSWP
:ERR1       RTS
*
* RESTORE INDEX BLOCKS FOR TREE FILE
*
:SWAPTRE
            LDY   #>SMIB
            STY   RPAGE
            JSR   SWAPIB
            JSR   WTBLK            ;WRITE OUT MASTER IB
            BCS   :ERR1
            LDY   #0
            STY   MIBPTR
*
:MIBAGNT    LDY   MIBPTR
*
* LOAD BLKNUM & BLKNUM+1 NORMAL NOW BECAUSE
* WE JUST SWAPPED MIB
*
            LDA   SMIB+$100,Y
            STA   BLKNUM+1
            LDA   SMIB,Y
            STA   BLKNUM
            ORA   BLKNUM+1
            BEQ   :NXTIBT          ;NULL ENTRY
            LDA   #>SIB
            STA   RPAGE
            JSR   RDBLK            ;READ INDEX BLK
            BCS   :ERR
            LDY   #>SIB
            JSR   SWAPIB           ;SWAP IT
            JSR   WTBLK            ;WRITE IT BACK OUT
            BCS   :ERR
:NXTIBT     INC   MIBPTR
            BPL   :MIBAGNT         ;MIBPTR < $80
:GOODSWP    CLC
:ERR        RTS
*
*
********************************
*
PUNDO0      LDA   #>DATA
            JSR   READBM           ;READ IN ENTIRE BITMAP
            JSR   CURPNT
*
* FIGURE OUT HOW LONG FILENAME IS
*
            LDY   #$0F
:LOOP1      LDA   (POINT),Y
            BNE   :OUT1
            DEY
            BNE   :LOOP1
:OUT1       TYA
            LDY   #0
            STY   MIBPTR
            STY   BLKCNT
            STY   BLKCNT+1
            STA   (POINT),Y        ;NAME LEN
            LDY   #$10
            LDA   (POINT),Y        ;FILE TYPE
            CMP   #$0F
            BNE   :NOTDIR
            LDA   #$D0             ;IT'S A SUBDIR FILE
            BNE   :GOTSTR
*
:NOTDIR     LDY   #$17
            LDA   (POINT),Y        ;EOF HI
            CMP   #2
            BCC   :NOTTREE
            LDA   #$30             ;EOF SAYS IT'S A TREE FILE
            BNE   :GOTSTR
*
:NOTTREE    CMP   #0
            BNE   :ISSAP           ;EOF SAYS SAPLING
            DEY
            LDA   (POINT),Y
            CMP   #2
            BCS   :ISSAP
            LDA   #$10             ;SEEDLING
            BNE   :GOTSTR
*
:ISSAP      LDA   #$20
:GOTSTR     STA   STRTYP
            LDY   #0
            ORA   (POINT),Y        ;OR WITH FILENAME LENGTH
            STA   (POINT),Y
            LDY   #$11
            LDA   (POINT),Y        ;KEY LO
            STA   BLKNUM
            STA   KEYBLK
            TAX
            INY
            LDA   (POINT),Y        ;KEY HI
            STA   BLKNUM+1
            STA   KEYBLK+1
            JSR   MRKBLK
            BEQ   :GOBAD           ;KEY BLOCK REALLOCATED
            LDA   STRTYP
            CMP   #$10             ;SEEDLING FILE?
            BEQ   :DID             ;YES: KEY BLOCK IS ALL
            CMP   #$20
            BEQ   :DOSAP
            CMP   #$30
            BEQ   :DOTREE
            JMP   :DODIR
:DOSAP      LDA   #>SIB
            STA   RPAGE
            JSR   RDBLK            ;READ INDEX BLK INTO SIB
            BCS   :GOBAD1          ;I/O ERROR
            JSR   :MRKIDXB
            BCS   :GOBAD1          ;SOME BLOCK WAS REALLOCATED
:DID        CLC
            RTS
*
* TREE FILE
*
:DOTREE     LDA   #>SMIB
            STA   RPAGE
            JSR   RDBLK            ;READ MASTER INDEX BLOCK
            BCS   :GOBAD1          ;I/O ERROR
            LDY   #0
            STY   MIBPTR
*
* CHECK IF ONLY ONE ENTRY IN MASTER INDEX BLOCK
* IF SO, ASSUME THAT THIS FILE WAS DELETED BY
* PRE-1.3 PRODOS
*
            LDA   SMIB
            BEQ   :MIBAGN
            INY                    ;0 --> 1
:MIBCHK     LDA   SMIB,Y
            BNE   :MIBAGN
            INY
            BNE   :MIBCHK
            LDA   SMIB+$100
            LDX   SMIB
            JMP   :MIBAGN1
:MIBAGN     LDY   MIBPTR
*
* LOAD BLKNUM & BLKNUM+1 BACKWARDS
*
            LDA   SMIB+$100,Y
            STA   BLKNUM
            LDA   SMIB,Y
            STA   BLKNUM+1
            ORA   BLKNUM
            BEQ   :NXTIB
            LDA   BLKNUM+1
            LDX   BLKNUM
:MIBAGN1    JSR   MRKBLK           ;MARK INDEX BLK
:GOBAD      BEQ   :BAD             ;INDEX BLOCK REALLOCATED
            LDA   #>SIB
            STA   RPAGE
            JSR   RDBLK            ;READ INDEX BLK
:GOBAD1     BCS   :BAD
            JSR   :MRKIDXB
            BCS   :BAD             ;SOME BLOCK REALLOCATED
:NXTIB      INC   MIBPTR
            BPL   :MIBAGN          ;MIBPTR < $80
            BMI   :DID
*

:DIRLP      LDA   SIB+2
            STA   BLKNUM
            LDA   SIB+3
            STA   BLKNUM+1
            ORA   BLKNUM
            BEQ   :DID             ;END OF SUBDIR
            LDA   BLKNUM+1
            LDX   BLKNUM
            JSR   MRKBLK
            BEQ   :BAD             ;SUBDIR BLOCK REALLOCATED
*
* READ NEXT BLOCK OF SUBDIR INTO
* SIB
*
            JSR   RDBLK
            BCC   :DIRLP
:BAD        SEC
            RTS
*
:DODIR      LDA   #>SIB
            STA   RPAGE
            JSR   RDBLK
            BCS   :BAD             ;I/O ERROR
*
* THIS IS THE FIRST BLOCK OF THE
* SUBDIRECTORY. UNDELETE THE SUBDIR
* HEADER.
*
            LDY   #$0F
:SDHLOOP    LDA   SIB+$4,Y
            BNE   :SDHOUT
            DEY
            BNE   :SDHLOOP
:SDHOUT     TYA
            ORA   #$E0
            STA   SIB+4
            JSR   WTBLK
            BCC   :DIRLP
            RTS
*
*
* MARK ALL BLOCKS IN THIS INDEX BLOCK AS IN USE
* IN THE BITMAP
*
:MRKIDXB    LDY   #0
            STY   IBPTR
*
* CHECK IF ONLY ONE ENTRY IN THIS BLOCK. IF SO, ASSUME
* THIS FILE WAS DELETED BY PRE-1.3 PRODOS AND BLOCK
* NUMBER IS STORED IN CORRECT ORDER.
*
            LDA   MIBPTR
            BNE   :IBAGN           ;NOT 1ST INDEX BLOCK IN MIB
            LDA   SIB
            BEQ   :IBAGN
            INY                    ;0 --> 1
:MRKCHK     LDA   SIB,Y
            BNE   :IBAGN           ;MORE THAN ONE ENTRY
            INY
            BNE   :MRKCHK
            LDX   SIB
            LDA   SIB+$100
            JSR   MRKBLK
:GOBAD2     BEQ   :BAD
            CLC
            RTS
*
:IBAGN      LDY   IBPTR
*
* LOAD BLKNUM & BLKNUM+1 BACKWARDS BECAUSE OF HOW
* PRODOS 1.3 DELETES FILES
*
            LDA   SIB,Y
            STA   BLKNUM+1
            LDA   SIB+$100,Y
            STA   BLKNUM
            ORA   BLKNUM+1
            BEQ   :NXTBLK          ;UNUSED (0,0) ENTRY
            LDA   BLKNUM+1
            LDX   BLKNUM
            JSR   MRKBLK
            BEQ   :GOBAD2
:NXTBLK     INC   IBPTR
            BNE   :IBAGN
            CLC
            RTS
*
* SWAP BOTTOM HALF AND TOP HALF OF INXDEX BLOCK
*
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
PNTFIL0     LDA   #0
PNTFIL      LDX   #2
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
* PRDCNT
*
* INPUT
*       DIRBLK,+1 = 1ST BLK OF DIR
*       DIRADR    = BUFFER ADDR
*       COUNT     = MAX. # OF DIR BLKS
*                   ALLOWED
*
* OUTPUT
*       RPAGE = NEXT AVAILABLE PAGE
*
PRDCNT      LDA   DIRBLK
            STA   BLKNUM
            LDA   DIRBLK+1
            STA   BLKNUM+1
            LDA   DIRADR
            STA   RPAGE
            STA   POINT+1
            LDA   #0
            STA   POINT
            STA   NACTIV
            JSR   RDBLK
            BCS   :RDRERR
*
* MAKE SURE THIS IS REALLY THE FIRST
* BLOCK OF THE DIRECTORY
*
            LDY   #0
            LDA   (POINT),Y
            INY
            ORA   (POINT),Y
            BEQ   :REALLY
*
* NOT THE FIRST BLOCK, SO BACK UP
* TO PREVIOUS BLOCK AND CHECK AGAIN
*
            LDA   (POINT),Y
            STA   DIRBLK+1
            DEY
            LDA   (POINT),Y
            STA   DIRBLK
            JMP   PRDCNT

:RDDR2      JSR   RDBLK
            BCS   :RDRERR
*
* SET UP BLKNUM FOR NEXT BLOCK OF DIR
*
:REALLY     LDY   #2
            LDA   (POINT),Y
            STA   BLKNUM
            INY
            LDA   (POINT),Y
            STA   BLKNUM+1
*
* ADD FILE NAME ADDRESSES TO ARRAY
*
            LDY   #4
:RDRLP      INY
            BEQ   :NEXT
            LDA   (POINT),Y
            DEY
            CMP   #0
            BEQ   :SKIP            ;NEVER USED ENTRY
            LDX   DELFLG
            LDA   (POINT),Y
            AND   #$0F
            BNE   :ACTIVE
*
* INACTIVE (DELETED) ENTRY, USE IT?
*
            CPX   #$80
            BEQ   :SKIP            ;WANT ACTIVE
            BNE   :USEIT           ;ALWAYS
*
* ACTIVE ENTRY, USE IT?
*
:ACTIVE     CPX   #0
            BEQ   :SKIP            ;WANT INACTIVE
            LDA   (POINT),Y
            AND   #$F0
            CMP   #$E0
            BCS   :SKIP            ;SUB HEADER
*
:USEIT      TYA
            LDX   NACTIV
            STA   CBYTE,X
            LDA   POINT+1
            STA   CSECTR,X
            INC   NACTIV
            BEQ   :UHOH            ;OVERFLOW
:SKIP       TYA
            CLC
            ADC   #$27
            TAY
            BCC   :RDRLP
            INC   POINT+1
            INC   RPAGE
            BNE   :RDRLP           ;ALWAYS
*
:NEXT       INC   POINT+1
            INC   RPAGE
            LDA   BLKNUM
            ORA   BLKNUM+1
            BEQ   :RDRDON          ;NO MORE BLOCKS
            DEC   COUNT
            BNE   :RDDR2           ;READ NEXT BLK
*
*
*
:RDRDON     LDA   RPAGE
            STA   DATADR
            CLC
:RDRERR     RTS
*
*
* MORE THAN 255 FILE NAMES FOUND
*
:UHOH       DEC   NACTIV
            INC   RPAGE
            BNE   :RDRDON          ;ALWAYS
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
*
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
WRITBM      LDA   BM
            STA   RPAGE
            LDA   BMLEN
            STA   :TEMP
            LDA   BMBLK
            STA   BLKNUM
            LDA   BMBLK+1
            STA   BLKNUM+1
:WTBM0      JSR   DOWBLK
            INC   BLKNUM
            BNE   :WTBM1
            INC   BLKNUM+1
:WTBM1      INC   RPAGE
            INC   RPAGE
            DEC   :TEMP
            BNE   :WTBM0
            RTS
*
:TEMP       DB    $0
*
*
PSPACE      LDA   #>DATA
            JSR   READBM
            LDA   BMLEN
            ASL
            STA   :TEMP
            LDY   #0
            STY   FREEL
            STY   FREEH
:NXTBYTE    LDA   (POINT),Y
            LDX   #7
:NEXTBIT    LSR
            BCC   :USED
            INC   FREEL
            BNE   :USED
            INC   FREEH
:USED       DEX
            BPL   :NEXTBIT
            INY
            BNE   :NXTBYTE
            INC   POINT+1
            DEC   :TEMP
            BNE   :NXTBYTE
*
            LDA   TOTBLK
            SEC
            SBC   FREEL
            STA   USEDL
            LDA   TOTBLK+1
            SBC   FREEH
            STA   USEDH
            RTS
:TEMP       DB    $0
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
            BNE   :CONTIN          ;CMD NOT COPY
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
            LDA   PRNTR?
            BPL   :SKIPCR
            JSR   CROUT
:SKIPCR     LDA   #1
            JSR   VLEFT
            LDY   #0
            STY   HEXNUM+1
            LDA   (TMPPTR),Y
            STA   :PFXLEN
            BMI   :BLNKLP          ;NO PFX
            BIT   DOSNOW
            BPL   :DOS33
            CMP   #0
            BEQ   :BLNKLP
            BNE   :PRODOS
*
:DOS33      LDY   #5
            LDA   (TMPPTR),Y
            BEQ   :BLNKLP
            STA   HEXNUM
            JSR   PRHERE
            ASC   "Disk Volume "
            DB    $0
            JSR   HEXDEC
            JSR   PRTLZ
            LDY   #$14
            BNE   :BLNKLP          ;ALWAYS
*
:PRODOS     INY
            LDA   (TMPPTR),Y
            ORA   #$80
            JSR   PCOUT
            CPY   :PFXLEN
            BCC   :PRODOS
:BLNKLP     INY
            LDA   #$A0
            JSR   PCOUT
            CPY   #$42
            BCC   :BLNKLP
:NOPFX      LDA   #3
            STA   WNDTOP
            JMP   VLEFT
:PFXLEN     DB    $0
SDCH        DB    $19
*
*
SRCHDR      LDA   #0
            STA   SRCTAR
PRVNMP      LDA   PDOS
            STA   DOSNOW
            LDX   #PPFX
            LDY   #>PPFX
            LDA   PUNIT
            JMP   PRVCOM
*
SRCTAR      DB    $0
*
TARHDR      LDA   #$FF
            STA   SRCTAR
PRVNMS      LDA   SDOS
            STA   DOSNOW
            LDX   #SPFX
            LDY   #>SPFX
            LDA   SUNIT
            JMP   PRVCOM
*
*
*
PCFILE      LDY   #0
            LDA   (POINT),Y
            AND   #$0F
            BNE   :PCFL1
            LDA   #$0F
:PCFL1      STA   :LENGTH
            LDY   #1
:PCFL2      LDA   (POINT),Y
            BEQ   :PCFL3
            ORA   #$80
            JSR   PCOUT
            INY
            CPY   :LENGTH
            BCC   :PCFL2
            BEQ   :PCFL2
:PCFL3      RTS
:LENGTH     DB    $0
*
*
PCATLN      STA   :TYPE            ;CAT DPLY TYPE
            LDY   #$1E             ;ACCESS
            LDA   (POINT),Y
            LDX   #"?"
            CMP   #$81
            BEQ   :ISLOKD          ;'MAYBE' STATUS
            LDX   #"*"
            AND   #$C2
            BEQ   :ISLOKD          ;SAY LOCKED ONLY IF 3 BITS OFF
            LDX   #" "
:ISLOKD     TXA
            JSR   PCOUT
            JSR   PCFILE
*
* DISPLAY FILE TYPE
*
            LDA   #" "
:TABLP1     JSR   PCOUT
            INY
            CPY   #$11
            BCC   :TABLP1
            LDY   #$10
            LDA   (POINT),Y
            JSR   PRTYPE
*
* DISPLAY # OF BLOCKS
*
            JSR   PRSPC
            LDY   #$13
            LDA   (POINT),Y
            STA   HEXNUM
            INY
            LDA   (POINT),Y
            STA   HEXNUM+1
            JSR   HEXDEC
            JSR   PRT5RJ
            JSR   PRSPC
*
* MODIFIED DATE
*
            LDY   #$22
            JSR   SHDAT0
            LDA   :TYPE
            CMP   #1
            BEQ   :MODTIM
:GODUN      RTS
*
* MODIFIED TIME
*
:MODTIM     LDY   #$24
            JSR   SHTIM0
*
* CREATION DATE
*
            JSR   PRSPC
            LDY   #$19
            JSR   SHDAT0
*
* CREATION TIME
*
            LDY   #$1B
            JSR   SHTIM0
*
* ENDFILE
*
            JSR   PRSPC
            LDY   #$17
            LDX   #2
:EFLP       LDA   (POINT),Y
            STA   HEXNUM,X
            DEY
            DEX
            BPL   :EFLP
            JSR   HEXDC3
            JSR   PRT8RJ
*
* SUBTYPE
*
            JSR   PRSPC
            LDY   #$10
            LDA   (POINT),Y
            LDX   #:SUBS1-:SUBS-1
:SBTPLP     CMP   :SUBS,X
            BEQ   :GOTSUB
            DEX
            BPL   :SBTPLP
            RTS
*
:GOTSUB     LDA   :SUBS1,X
            PHA
            JSR   PCOUT
            LDA   #"="
            JSR   PCOUT
            PLA
            CMP   #"A"
            BNE   :RSUB
            LDA   #"$"
            JSR   PCOUT
            LDY   #$20
            LDA   (POINT),Y
            JSR   PHBYTE
            LDY   #$1F
            LDA   (POINT),Y
            JMP   PHBYTE
*
:RSUB       LDY   #$20
            LDA   (POINT),Y
            TAX
            DEY
            LDA   (POINT),Y
            JSR   HEXDC2
            JMP   PRT5RJ
*
:TYPE       DB    $0
:SUBS       DB    $04,$06,$FC,$FD,$FB,$FA,$B4,$B5,$B6
:SUBS1      ASC   "RAAAAAAAA"
*
PRTYPE      LDX   #TYPE1-TYPES-1
:PRTY1      CMP   TYPES,X
            BEQ   :GOTIT
            DEX
            BPL   :PRTY1
*
* PRINT FILE TYPE IN HEX
*
            JSR   DOLLAR
            JMP   PHBYTE
*
:GOTIT      LDA   TYPE1,X
            JSR   PCOUT
            LDA   TYPE2,X
            JSR   PCOUT
            LDA   TYPE3,X
            JMP   PCOUT
*
* [4am] backported types from v9
* $5A  CFG  Configuration
* $AD  BDF  Apple IIgs BASIC Data
* $BD  FST  Apple IIgs File System Translator
* $E0  LBR  Archive (format in auxtype)
*
* and added new types based on online sources
* https://www.kreativekorp.com/miscpages/a2info/filetypes.shtml
* http://www.apple-iigs.info/techfiletype.php
* https://public.websites.umich.edu/~archive/apple2/misc/programmers/filetypes.txt
* $16  PFS  PFS Document
* $2E  P8C  ProDOS 8 Code Module
* $42  FTD  File Type Definitions
* $50  GWP  Apple IIgs Word Processing
* $51  GSS  Apple IIgs Spreadsheet
* $52  GDB  Apple IIgs Database
* $53  DRW  Object Oriented Graphics
* $54  GDP  Apple IIgs Desktop Publishing
* $55  HMD  HyperMedia
* $58  HLP  Help File
* $BC  LDF  Apple IIgs Generic Load File
* $C2  ANI  PaintWorks Animation
* $C3  PAL  PaintWorks Palette
* $C5  OOG  Object-Oriented Graphics
* $C7  CDV  Apple IIgs Control Panel
* $D5  MUS  Music sequence
* $D6  INS  Instrument
* $D7  MDI  MIDI
* $D8  SND  Apple IIgs Audio
*
TYPES       DB    $01,$02,$03,$04,$05,$06,$07,$08  ;00-07
            DB    $09,$0A,$0B,$0C,$0F,$10,$11,$16  ;08-0F
            DB    $19,$1A,$1B,$2E,$42,$50,$51,$52  ;10-17
            DB    $53,$54,$55,$58,$5A,$AB,$AC,$AD  ;18-1F
            DB    $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7  ;20-27
            DB    $B8,$B9,$BA,$BB,$BC,$BD,$BF,$C0  ;28-2F
            DB    $C1,$C2,$C3,$C5,$C7,$C8,$C9,$CA  ;30-37
            DB    $D5,$D6,$D7,$D8,$E0,$E2,$EF,$F0  ;38-3F
            DB    $F9,$FA,$FB,$FC,$FD,$FE,$FF  ;40-46
*
*                               1               2               3               4
* Index #          0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456
*
*                  00000000000001111112455555555AAABBBBBBBBBBBBBBBCCCCCCCCCDDDDEEEFFFFFFFF
* Filetype         123456789ABCF0169ABE20123458ABCD0123456789ABCDF01235789A567802F09ABCDEF
*
TYPE1       ASC   "BPPTPBFFBDWSDRRPAAAPFGGGDGHHCGTBSOLSRESTNCTDLFDPPAPOCFFIMIMSLDPCPIIBVRS"
TYPE2       ASC   "ACTXDINOAAPOIPPFDWS8TWSDRDMLFSDDRBI1TXTSDDORDSONINAODONCUNDNBTAM1NVAAEY"
TYPE3       ASC   "DDXTANTT33FSRDISBPPCDPSBWPDPGBFFCJB6LERFAALVFTCTCILGVNDNSSIDRSSD6TRSRLS"
*
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
            JSR   PRT2DG           ;WAS PRT2RJ
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
            JMP   SHOTM0
*
:NODATE     JSR   PRHERE
            ASC   "<No Date>"
            DB    $0
            RTS
:DATEMP     DB    $0
*
*
SHTIM0      JSR   PRSPC
            LDA   (POINT),Y
            TAX
            DEY
            LDA   (POINT),Y
SHOTIM      PHA
            TXA
            JSR   HEXDC1
            JSR   PRT2RJ
            LDA   #":"
            JSR   PCOUT
            PLA
SHOTM0      JSR   HEXDC1
            JMP   PRT2DG
*
*
GETTYP      BIT   DOSNOW
            BPL   :DOS33
            LDY   #$10
            LDA   (POINT),Y
            RTS
:DOS33      LDY   #2
            LDA   (POINT),Y
            AND   #$7F
            RTS
*
SETLOK      BIT   DOSNOW
            BPL   :DOS33
            LDY   #$1E
            LDX   #1               ;ANTICIPATE LOCKING
            CMP   #$FF
            BEQ   :SLK3            ;LOCK IT
            CMP   #$80
            BNE   :SLK2            ;UNLOCK IT
            LDA   (POINT),Y
            AND   #$C2
            BNE   :SLK3            ;TOGGLE UNLOCKED --> LOCKED
:SLK2       LDX   #$C3
:SLK3       LDA   (POINT),Y
            AND   #$20             ;ISOLATE BACKUP BIT
            STA   (POINT),Y
            TXA
            ORA   (POINT),Y
:SLK4       STA   (POINT),Y
            RTS
*
:DOS33      LDY   #2
            CMP   #$80
            BNE   :DS1
            LDA   (POINT),Y
            EOR   #$80
            JMP   :SLK4
:DS1        AND   #$80
            PHA
            LDA   (POINT),Y
            AND   #$7F
            STA   (POINT),Y
            PLA
            ORA   (POINT),Y
            JMP   :SLK4
*
*
CKDEL       LDY   #0
            LDA   (POINT),Y
CKDEL1      BIT   DOSNOW
            BMI   :PRODOS
            ASL
            RTS
:PRODOS     CLC
            AND   #$0F
            BNE   :OUT
            SEC
:OUT        RTS
*
*
*
*
NODOS3      JSR   DOSTYP
            BCS   BLK2ER
            LDA   #$6F
            DB    $2C
*
FLONLY      LDA   #$6D
            DB    $2C
*
NOPRO       LDA   #$6E
            JMP   PRTPRS
*
BLK2ER      LDY   #0
            STY   BLKNUM+1
            DEY
            STY   DOSNOW
            LDA   #2
            STA   BLKNUM
            JMP   ERROUT
*
*
UNTDEV      STA   UNIT
*
* [4am] clear GODEV ptr before starting
* so caller can tell if it didn't work
*
            LDA   #0
            STA   GODEV+1
            STA   GODEV+2
UNTDV0      LDX   NUMDEV
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
            BEQ   :RAM             ;MAYBE /RAM
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
            BEQ   :ISDSKII         ;ASSUME DISK II
:ROMDRV1    LDY   #$FE
            LDA   (TMPPTR),Y
            AND   #$88
            ORA   #$02
:COMOUT     CLC
            DB    $B0
:RAMOUT     SEC
            TAX
            AND   #$03
            RTS
*
:RAM        LDA   GODEV+1
            BNE   :RAMDRV          ;NOT /RAM
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
            BEQ   :RAMOUT          ;IT IS /RAM
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
            STA   BLKNUM           ;NEXT BLOCK
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
MKDIR       LDA   #$0D
            BNE   PCTCOM
*
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
SETBUT      LDA   PFX
            BNE   SETPFX
            LDA   BOOTDV
            STA   UNIT
            JMP   UNTPFX
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
            CMP   #$48             ;DISK FULL?
            BNE   ERROUT           ;NOPE
*
* DELETE INCOMPLETELY COPIED FILE
*
            JSR   CLOSE            ;CLOSE IT
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
DODEV0      STA   DEVFLG
            JSR   HOME
            JSR   PRHERE
            ASC   "Select device:"
            DB    $0
            LDA   CURDVA
            JSR   DODEV
            STX   CURDVA
            RTS
*
DODVP1      JSR   HOME
            LDA   #0
* STA *PPFX
* STA *PPFX+5
            STA   DEVFLG
            LDA   PPFX
            ORA   #$80
            STA   PPFX
            JSR   PRHERE
            ASC   "Select source device:"
            DB    $0
            LDA   CURDVP
            JSR   DODEV
            STA   PUNIT
            STX   CURDVP
            RTS
*
DODVS1      JSR   HOME
            JSR   DOWAIT
            LDA   #0
* STA *SPFX
* STA *SPFX+5
            STA   DEVFLG
            LDA   SPFX
            ORA   #$80
            STA   SPFX
            JSR   PRHERE
            ASC   "Select target device:"
            DB    $0
            LDA   CURDVS
            JSR   DODEV
            STA   SUNIT
            STX   CURDVS
            RTS
*
*
*
DODEV       STA   CURDEV
            LDA   #0
            STA   VOLFLG
            LDA   #$FF
            STA   DOSNOW           ;ASSUME PRODOS
            JSR   LOHERE
            ASC   "Press [?] to display volume names"
            DB    $0
:DEVMNU     JSR   :SEEDEVS
:KEYORD     JSR   CHKKEY
            BNE   :NOTARO
            BCS   :DRIGHT
            BCC   :DLEFT
:NOTARO     CMP   #"?"
            BEQ   :GETVOLS
            CMP   #"/"
            BEQ   :GETVOLS
            CMP   #$8D
            BNE   :KEYORD          ;BAD KEY
*
:CHOOSE     LDX   CURDEV
            LDA   DVICES,X
            CMP   #$BF
* AND #$F0
* CMP #$B0                ;CHOOSE /RAM?
            BNE   :CHOOS0          ;NO
            LDA   ISAUX            ;/RAM ACTIVE?
            BPL   :CHOOS0          ;YES
            LDA   DEVFLG           ;CMD=FORMAT?
            BMI   :CHOOS0          ;YES
            JSR   BELL
            JMP   :DEVMNU
*
:CHOOS0     LDA   #2
            STA   DIRBLK
            LDA   #0
            STA   PFX+5
            STA   PFX
            STA   DIRBLK+1
            LDX   CURDEV
            LDA   DVICES,X
            AND   #$F0
            STA   UNIT
            RTS
*
:DLEFT      LDX   CURDEV
            DEX
            BPL   :DRGTQ
            LDX   NUMDEV
            JMP   :DRGTQ
*
:DRIGHT     LDX   CURDEV
            INX
            CPX   NUMDEV
            BEQ   :DRGTQ
            BCC   :DRGTQ
            LDX   #0
:DRGTQ      STX   CURDEV
            JMP   :DEVMNU
*
*
*
* '?' REQUEST TO SEE VOLUME NAMES
* DO ONLINE CALLS FOR EACH DEVICE
* TO GET CURRENT VOLUME NAMES
*
:GETVOLS    LDX   NUMDEV
:GETVLP     TXA
            ASL
            ASL
            ASL
            ASL
            STA   :ONLINE+2
            LDA   DVICES,X
            STA   :ONLINE+1
            CMP   #$BF
* AND #$F0
* CMP #$B0
            BNE   :GETVL0
            LDA   ISAUX
            BMI   :GETSKIP
:GETVL0     JSR   MLI
            DB    $C5
            DW    :ONLINE
:GETSKIP    DEX
            BPL   :GETVLP
            STX   VOLFLG           ;FF
            JMP   :DEVMNU
:ONLINE     DB    $2
            DB    $0
            DW    VOLNMS
*
*
:SEEDEVS    LDA   #2
            JSR   VLEFT
            LDX   #0
            STX   :SHODEV
:DEVLP      CPX   CURDEV
            BNE   :NOTDEV
            JSR   PINVRS
:NOTDEV     LDA   DVICES,X
            PHA
            JSR   SEEDEV
            PLA
            CMP   #$BF
* AND #$F0
* CMP #$B0
            BNE   :NOTDV0
            LDA   ISAUX
            BPL   :NOTDV0
            JSR   PRHERE
            ASC   ": /RAM disconnected"
            DB    $0
            JMP   :NOVOL
*
:NOTDV0     LDA   VOLFLG
            BEQ   :NOVOL
*
* DISPLAY VOLUME NAMES
*
            JSR   PRHERE
            ASC   ": "
            DB    $0
            LDA   :SHODEV
            JSR   :SEEVOL
            JSR   CLREOL
:NOVOL      JSR   PNORML
            JSR   CROUT
            INC   :SHODEV
            LDX   :SHODEV
            CPX   NUMDEV
            BEQ   :DEVLP
            BCC   :DEVLP
            RTS
:SHODEV     DB    $0
*
*
*
*
* DISPLAY VOLUME NAME
* A = INDEX INTO DEVICE LIST (0 - F)
*
:SEEVOL     ASL
            ASL
            ASL
            ASL
            TAX
            LDA   VOLNMS,X
            AND   #$0F
            BNE   :NAMEOK
            LDA   VOLNMS+$1,X
            CMP   #$52
            BNE   :SEEVOLQ
            LDX   :SHODEV
            JSR   DVTYPX
            BEQ   :SEEDII          ;DISK II
            JSR   PRHERE
            ASC   "non-ProDOS"
            DB    $0
            RTS
*
:SEEDII     JSR   PRHERE
            ASC   "DOS 3.3"
            DB    $0
            RTS
*
:NAMEOK     TAY
            LDA   #"/"
            JSR   PCOUT
:SEEVLP     LDA   VOLNMS+$1,X
            ORA   #$80
            JSR   PCOUT
            INX
            DEY
            BNE   :SEEVLP
:SEEVOLQ    RTS
*
*
*
TREEA       JSR   DOSTYP
            LDA   #APFX
            STA   PFXADR
            LDA   #>APFX
            STA   PFXADR+1
            LDA   ACURR
            JSR   DOTREE
            BCS   SETA             ;I/O ERROR
            STA   ACURR
            RTS
SETA        JSR   DOSTYP
            LDA   UNIT
            JMP   UNTPFX
*
*
*
TREEP       LDA   #0
            STA   SRCTAR
            LDA   PUNIT
            STA   UNIT
            JSR   DOSTYP
            STA   PDOS
            LDA   #PPFX
            STA   PFXADR
            LDA   #>PPFX
            STA   PFXADR+1
            LDA   PCURR
            JSR   DOTREE
            BCS   SETP
            STA   PCURR
            RTS
*
SETP        LDA   PUNIT
            STA   UNIT
            JSR   SETSD
:SETP1      LDA   #>PPFX
            LDX   #PPFX
            JSR   STPFXC
            LDA   PDOS
            CMP   #1
            BNE   :NOT1
            JSR   DOSTYP
            STA   PDOS
:NOT1       STA   DOSNOW
            RTS
*
TREES       LDA   #$FF
            STA   SRCTAR
            LDA   SUNIT
            STA   UNIT
            JSR   DOSTYP
            STA   SDOS
            LDA   #SPFX
            STA   PFXADR
            LDA   #>SPFX
            STA   PFXADR+1
            LDA   SCURR
            JSR   DOTREE
            BCS   SETS
            STA   SCURR
            RTS
*
SETS        LDA   SUNIT
            STA   UNIT
            JSR   SETSD
:SETS1      LDA   #>SPFX
            LDX   #SPFX
            JSR   STPFXC
            LDA   SDOS
            CMP   #1
            BNE   :NOT1
            JSR   DOSTYP
            STA   SDOS
:NOT1       STA   DOSNOW
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
            BNE   :SETSD9          ;Not a UDC
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
            BCS   :SETSD9          ;Never(?)
            ADC   #1               ;C already clear
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
CLOSE       JSR   MLI
            DB    $CC
            DW    :CLSLST
            RTS
:CLSLST     DB    $1,$0
