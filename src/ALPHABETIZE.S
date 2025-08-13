************************************
*       ALPHABETIZE CATALOG        *
************************************
*
ALPHA       JSR   COMTRE
            LDA   #$01
            STA   DELFLG
            JSR   RDACNT      ;READ FILES
            LDA   NACTIV
            BEQ   :NOFILES
            LDX   #$FF
            STX   CURR
:ALPHA1     INC   CURR        ;NEXT POSN TO
            LDX   CURR        ;ALPHABETIZE
            CPX   NACTIV      ;GOT EM ALL?
            BCS   :DUNALFA
            LDA   CBYTE,X     ;MAKE THIS
            STA   POINT2      ;FILE CHOICE
            LDA   CSECTR,X    ;FOR NOW
            STA   POINT2+1
:SEARCH1    INX               ;LOOK AHEAD
            CPX   NACTIV      ;NO FILES TO
            BCS   :SWAPALF    ;COMPARE WITH?
            JSR   SETPNT      ;POINT AT IT.
            JSR   CKDEL
            BCS   :SEARCH1
            LDA   (POINT2),Y
            JSR   CKDEL1
            BCS   :CHOICE
            LDA   (POINT2),Y
            AND   #$0F
            STA   :LAST2      ;LENGTH OF POINT2 NAME
            LDA   (POINT),Y   ;ANTICIPATE PRODOS
            AND   #$0F
            STA   :LAST
            BIT   DOSNOW
            BMI   :COMP0      ;Y ALREADY 0
            LDA   #$20
            STA   :LAST2
            STA   :LAST
            LDY   #$02
:COMP0      INC   :LAST2
:COMPARE    CPY   :LAST       ;EXACT MATCH?
            BCS   :CHOICE     ;YES: SWAP (MIGHT BE F12 & F1)
            INY
            CPY   :LAST2      ;PAST LENGTH OF POINT2?
            BCS   :SEARCH1    ;YES: SKIP IT
            LDA   (POINT),Y   ;COMPARE CHARS
            CMP   (POINT2),Y
            BEQ   :COMPARE    ;UNTIL DIFF.
            BCS   :SEARCH1    ;FORGET IF HI.
:CHOICE     LDA   POINT       ;IF LOWER MAKE
            STA   POINT2      ;IT THE NEW
            LDA   POINT+1     ;CHOICE.
            STA   POINT2+1
            BNE   :SEARCH1    ;(ALWAYS)
*
:NOFILES    JMP   NOFIL0
*
* PUT CHOSEN ENTRY INTO POSITION
:SWAPALF    JSR   CURPNT      ;POINT AT POSN
            LDY   #$22
            BIT   DOSNOW
            BPL   :SWAPLP
            LDY   #$26
:SWAPLP     LDA   (POINT),Y   ;SWAP WITH
            TAX               ;CHOICE
            LDA   (POINT2),Y
            STA   (POINT),Y
            TXA
            STA   (POINT2),Y
            DEY
            BPL   :SWAPLP
            BMI   :ALPHA1     ;(ALWAYS)
*
*
* SEE ALPHABETIZED CATALOG
:DUNALFA    LDX   #$00
            STX   SHOW
:COUNTIT    LDA   #$14        ;20 FILES/SCRN
            STA   :COUNT
:SEEALFA    JSR   SETPNT
            JSR   CKDEL       ;DELETED?
            BCS   :NXTFILE    ;YES:DONT SHOW
            LDA   #$FF        ;SHORT DISPLAY
            JSR   CATLIN      ;NO:SHOW
            JSR   CROUT
            DEC   :COUNT      ;& COUNT
:NXTFILE    INC   SHOW        ;NEXT FILE
            LDX   SHOW
            CPX   NACTIV      ;SEEN EM ALL?
            BCS   :DUNSEE     ;YES.
            LDA   :COUNT      ;NO:PAGE FULL?
            BNE   :SEEALFA    ;NO.
            JSR   KYESC       ;YES:KEYPRESS.
            JMP   :COUNTIT    ;COUNT MORE.
*
* ASK TO SAVE IT
:DUNSEE     JSR   PRHERE
            DB    $8D
            ASC   "[G]-Go, [Esc]-Exit"
            DB    $0
            JSR   GETKEY
            CMP   #"G"
            BEQ   FIXSUB
:ALPHAQ     RTS
*
:ORDER      DB    $0
:COUNT      DB    $0
:LAST       DB    $0
:LAST2      DB    $0
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
            BPL   CTOUT       ;DOS 3.3
            LDA   RRTN
            BEQ   CTOUT       ;NO ERROR
            CMP   #$52
            BEQ   CTERR1
            CMP   #$40
            BCC   CTERR       ;I/O ERROR
CTOUT       RTS
*
* BLOCK 2 ERROR
*
CTERR       JMP   BLK2ER
*
* NOT A DOS OR PRODOS DISK
*
CTERR1      JMP   WDERR
*
COMHDR      JSR   DODEVP
            JSR   SETA
            JSR   COMH00
            LDA   CHOICE
            CMP   #7          ;VERIFY DISK?
            BNE   CT1         ;NO
            RTS

COMH00      JSR   TOP1
            JMP   PRVNM
OPTCHS      DB    $0

