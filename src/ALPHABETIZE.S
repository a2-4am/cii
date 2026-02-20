            TYP   BIN
            DSK   ../build/ALPHABETIZE.O
            PUT   VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/DELLIB.VARS
            ORG   DELLIBEND
ALPHA       
            ORG   *+3

************************************
*       ALPHABETIZE CATALOG        *
************************************
*
            JSR   COMTRE
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
:COUNT      DB    $0
:LAST       DB    $0
:LAST2      DB    $0
*
* ASK TO SAVE IT
:DUNSEE     JSR   PRHERE
            DB    $8D
            ASC   "[G]-Go, [Esc]-Exit"
            DB    $0
            JSR   GETKEY
            CMP   #"G"
            BNE   :ALPHAQ
            JMP   FIXSUB
:ALPHAQ     RTS
*
ALPHAEND
