            TYP   BIN
            DSK   ../build/UNDELETE.O
            PUT   VARS
            PUT   ../build/PRODOS.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/ERRORS.VARS
            PUT   ../build/UILIB.VARS
            PUT   ../build/DISKLIB.VARS
            PUT   ../build/CATLIB.VARS
            PUT   ../build/TREELIB.VARS
            PUT   ../build/DISKMAP.VARS
            ORG   TSMAPEND
*
************************************
*        UNDELETE FILES            *
************************************
*
            JSR   COMTRE
            LDY   #0
            STY   DELFLG
            INY
            STY   STATE
            JSR   CATDIS
            LDA   #$80
            STA   DELFLG
            JSR   PATMOV
            LDA   FILNUM
            BNE   :GOTFILS
            JMP   NOSEL
:GOTFILS    JSR   SWPCHK
            JSR   COMH00
            LDA   #$00
            STA   :BADNUM
            STA   :MAYBE
            STA   CURR
*
* ATTEMPT REGULAR UNDELETE OF DOS
* AND PRODOS FILES
*
:UNLOOP     JSR   FILEQ
            JSR   :UNDO
            JSR   CKESC
            INC   CURR
            LDA   CURR
            CMP   FILNUM
            BNE   :UNLOOP
*
            JSR   PATMOV      ;SQUISH LIST
            STX   NACTIV
            LDA   :MAYBE
            BEQ   :CKBAD
*
* ATTEMPT 'SMART' UNDELETE OF
* 'MAYBE' FILES.
*
*
            JSR   COMH00
            LDA   #0
            STA   CURR
:SMARTLP    JSR   FILEQ
            LDX   CURR
            LDA   STATUS,X
            CMP   #$FE
            BNE   :ISBAD      ;UNRECOVERABLE
*
* FIRST, RECREATE FILE NAME AND
* STORAGE TYPE AND UNDELETE
* BLOCKS LEFT IN INDEX BLOCKS
*
            JSR   PUNDO0
*
* NOW TRY TO FIGURE OUT WHERE THE REST
* OF THE BLOCKS ARE AND UNDELETE THEM.
*
            JSR   SMART
*
:ISBAD      JSR   CKESC
            INC   CURR
            LDA   CURR
            CMP   FILNUM
            BCC   :SMARTLP
*
:CKBAD      LDA   :BADNUM     ;ANY LOST
            BEQ   :OUT        ;FILES?
            JSR   HOME
            JSR   PATMOV
            LDA   #$03
            JSR   VLEFT
            JSR   PRHERE
            ASC   "Lost files:"
            DB    $8D,$8D,$0
            LDA   #$00
            STA   CURR
:PAGELP     LDA   #$0E        ;14 LINES/PAGE
            STA   :COUNT
:BADLP      DEC   :COUNT
            JSR   CURPNT
            JSR   CFILE       ;SEE FILE
            JSR   CROUT
            INC   CURR
            LDA   CURR
            CMP   FILNUM      ;NO MORE?
            BCS   :PRESS
            LDA   :COUNT      ;LINE COUNT?
            BNE   :BADLP
            LDA   #MCRESC1
            JSR   PRINT
            JSR   KYESC
            JSR   CROUT2
            JMP   :PAGELP
:PRESS      JMP   PRESS
:OUT        RTS
*
*
:UNDO       BIT   DOSNOW
            BPL   :DOS33
            JMP   PUNDO
*
:DOS33      LDA   #>SRCTSL
            STA   RPAGE       ;SET RWTS ADDR
            LDA   #$01
            STA   RCMND       ;& COMMAND
            JSR   CURPNT
            LDY   #$20        ;FIX UP
            LDA   (POINT),Y   ;CATALOG
            STA   TRACK       ;ENTRY
            STA   RTRACK
            LDY   #$00
            STA   (POINT),Y
            INY
            LDA   (POINT),Y
            STA   SECTOR
            STA   RSECTR
            LDY   #$20
            LDA   #" "
            STA   (POINT),Y
:TSLLP      JSR   :USEIT      ;ALLOCATE
            BCS   :CANT       ;TSLIST
            JSR   DORWTS
            LDA   #$0C
            STA   STSP
:PAIRLP     LDX   STSP
            LDA   SRCTSL,X
            STA   TRACK       ;FOR VALID
            ORA   SRCTSL+$1,X  ;TSPAIRS:
            BEQ   :NXTPAIR
            LDA   SRCTSL+$1,X  ;ALLOCATE
            STA   SECTOR      ;SECTORS FROM
            JSR   :USEIT      ;LIST
            BCS   :CANT
:NXTPAIR    INC   STSP
            INC   STSP
            BNE   :PAIRLP
            LDA   SRCTSL+1
            STA   TRACK
            STA   RTRACK      ;POINTER TO
            ORA   SRCTSL+2    ;NEXT TSLIST?
            BEQ   :DID
            LDA   SRCTSL+2    ;YES: LOOP
            STA   SECTOR      ;BACK
            STA   RSECTR
            JMP   :TSLLP
:DID        JSR   WRCAT1      ;WRITE FREED
            LDA   #$00        ;CATALOG
            BEQ   :MARKIT     ;ALWAYS
:CANT       JSR   RDCAT1      ;RE-READ IF
            INC   :BADNUM
            LDA   #$FF
:MARKIT     LDX   CURR        ;MARK FILE
            STA   STATUS,X    ;GOOD OR BAD
            RTS
*
:USEIT      LDA   SECTOR
            JSR   DOMASK
            LDA   TRACK       ;INDEX INTO
            ASL               ;BITMAP
            ASL
            ADC   #$38
            TAX
            LDA   VTOC1,X
            AND   BITMSK
            STA   :TEMP
            LDA   VTOC1+$1,X
            AND   BITMSK+1
            ORA   :TEMP
            SEC
            BEQ   :USED
            LDA   BITMSK
            EOR   #$FF
            AND   VTOC1,X
            STA   VTOC1,X
            LDA   BITMSK+1
            EOR   #$FF
            AND   VTOC1+$1,X
            STA   VTOC1+$1,X
            CLC
:USED       RTS
*
:TEMP       DB    $0
:COUNT      DB    $0
*
SMART       EQU   *
            JSR   CURPNT
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
            BCS   :GOTEM      ;DONE
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
            BCC   :NOPE       ;UNRECOVERABLE
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
            BNE   :GOTEM1     ;NOT TREE
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
            BEQ   :MARKIT2    ;HIT MAX VALUE
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
            BEQ   :DOSOME     ;NO GOOD
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
PUNDO       EQU   *
            JSR   PUNDO0
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
            BCC   UNDOIT      ;GOOD SWAP
*
MRKBAD      EQU   *
            INC   :BADNUM
            LDA   #$FF
            BNE   MRKCOM      ;ALWAYS
*
DOMAYBE     EQU   *
            INC   :MAYBE
            LDA   #$FE
*
* WIPE OUT FIRST CHAR OF FILENAME
*
MRKCOM      EQU   *
            PHA
            JSR   CURPNT
            LDY   #0
            TYA
            STA   (POINT),Y
            PLA
MARKIT      EQU   *
            LDX   CURR        ;MARK FILE
            STA   STATUS,X    ;GOOD OR BAD
            RTS
*
UNDOIT      EQU   *
            JSR   WRITBM
*
* INCREMENT FILE COUNT
*
            INC   SDIR+$25
            BNE   :UNDO1
            INC   SDIR+$26
:UNDO1      JSR   WRCAT1
            LDA   #0
            BEQ   MARKIT      ;ALWAYS
*
KEYBLK      EQU   *
            DB    0,0
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
            JSR   WTBLK       ;WRITE OUT MASTER IB
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
            BEQ   :NXTIBT     ;NULL ENTRY
            LDA   #>SIB
            STA   RPAGE
            JSR   RDBLK       ;READ INDEX BLK
            BCS   :ERR
            LDY   #>SIB
            JSR   SWAPIB      ;SWAP IT
            JSR   WTBLK       ;WRITE IT BACK OUT
            BCS   :ERR
:NXTIBT     INC   MIBPTR
            BPL   :MIBAGNT    ;MIBPTR < $80
:GOODSWP    CLC
:ERR        RTS
*
*
********************************
*
PUNDOERR    EQU   *
            JMP   ERROUT
PUNDO0      EQU   *
            LDA   #>BMDATA    ;[4am] lower to accommodate giant hard drives
                              ;that can use $2000 consecutive bytes for the
                              ;entire bitmap
            JSR   READBM      ;READ IN ENTIRE BITMAP
            BCS   PUNDOERR    ;[4am] READBM now returns C=1 on error
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
            STA   (POINT),Y   ;NAME LEN
            LDY   #$10
            LDA   (POINT),Y   ;FILE TYPE
            CMP   #$0F
            BNE   :NOTDIR
            LDA   #$D0        ;IT'S A SUBDIR FILE
            BNE   :GOTSTR
*
:NOTDIR     LDY   #$17
            LDA   (POINT),Y   ;EOF HI
            CMP   #2
            BCC   :NOTTREE
            LDA   #$30        ;EOF SAYS IT'S A TREE FILE
            BNE   :GOTSTR
*
:NOTTREE    CMP   #0
            BNE   :ISSAP      ;EOF SAYS SAPLING
            DEY
            LDA   (POINT),Y
            CMP   #2
            BCS   :ISSAP
            LDA   #$10        ;SEEDLING
            BNE   :GOTSTR
*
:ISSAP      LDA   #$20
:GOTSTR     STA   STRTYP
            LDY   #0
            ORA   (POINT),Y   ;OR WITH FILENAME LENGTH
            STA   (POINT),Y
            LDY   #$11
            LDA   (POINT),Y   ;KEY LO
            STA   BLKNUM
            STA   KEYBLK
            TAX
            INY
            LDA   (POINT),Y   ;KEY HI
            STA   BLKNUM+1
            STA   KEYBLK+1
            JSR   MRKBLK
            BEQ   :GOBAD      ;KEY BLOCK REALLOCATED
            LDA   STRTYP
            CMP   #$10        ;SEEDLING FILE?
            BEQ   :DID        ;YES: KEY BLOCK IS ALL
            CMP   #$20
            BEQ   :DOSAP
            CMP   #$30
            BEQ   :DOTREE
            JMP   :DODIR
:DOSAP      LDA   #>SIB
            STA   RPAGE
            JSR   RDBLK       ;READ INDEX BLK INTO SIB
            BCS   :GOBAD1     ;I/O ERROR
            JSR   :MRKIDXB
            BCS   :GOBAD1     ;SOME BLOCK WAS REALLOCATED
:DID        CLC
            RTS
*
* TREE FILE
*
:DOTREE     LDA   #>SMIB
            STA   RPAGE
            JSR   RDBLK       ;READ MASTER INDEX BLOCK
            BCS   :GOBAD1     ;I/O ERROR
            LDY   #0
            STY   MIBPTR
*
* CHECK IF ONLY ONE ENTRY IN MASTER INDEX BLOCK
* IF SO, ASSUME THAT THIS FILE WAS DELETED BY
* PRE-1.3 PRODOS
*
            LDA   SMIB
            BEQ   :MIBAGN
            INY               ;0 --> 1
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
:MIBAGN1    JSR   MRKBLK      ;MARK INDEX BLK
:GOBAD      BEQ   :BAD        ;INDEX BLOCK REALLOCATED
            LDA   #>SIB
            STA   RPAGE
            JSR   RDBLK       ;READ INDEX BLK
:GOBAD1     BCS   :BAD
            JSR   :MRKIDXB
            BCS   :BAD        ;SOME BLOCK REALLOCATED
:NXTIB      INC   MIBPTR
            BPL   :MIBAGN     ;MIBPTR < $80
            BMI   :DID
*

:DIRLP      LDA   SIB+2
            STA   BLKNUM
            LDA   SIB+3
            STA   BLKNUM+1
            ORA   BLKNUM
            BEQ   :DID        ;END OF SUBDIR
            LDA   BLKNUM+1
            LDX   BLKNUM
            JSR   MRKBLK
            BEQ   :BAD        ;SUBDIR BLOCK REALLOCATED
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
            BCS   :BAD        ;I/O ERROR
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
            BNE   :IBAGN      ;NOT 1ST INDEX BLOCK IN MIB
            LDA   SIB
            BEQ   :IBAGN
            INY               ;0 --> 1
:MRKCHK     LDA   SIB,Y
            BNE   :IBAGN      ;MORE THAN ONE ENTRY
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
            BEQ   :NXTBLK     ;UNUSED (0,0) ENTRY
            LDA   BLKNUM+1
            LDX   BLKNUM
            JSR   MRKBLK
            BEQ   :GOBAD2
:NXTBLK     INC   IBPTR
            BNE   :IBAGN
            CLC
            RTS
*
:BADNUM     DB    $0
:MAYBE      DB    $0
*
WRITBM      EQU   *
            LDA   BM
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
RDCAT1      EQU   *
            LDA   #>CAT1
            JSR   CLRCAT
            LDX   #>VTOC1
            LDA   #$01
            JMP   DOCAT
*
UNDELEND
