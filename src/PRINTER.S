*
***********************************
*        PRINTER FUNCTIONS        *
***********************************
*
* SETPRINT  change printer slot
* ASKPR?    ask user if they want a printout, if printer slot is non-zero
* PRON      turn on printer
* PROFF     turn off printer
*
* CHANGE PRINTER SLOT
*
SETPRINT    LDA   #$16
            JSR   TABV
            LDA   #$21
            STA   CH
            LDA   #MSLOT
            JSR   PRINT
            LDA   PSLOT
            JSR   PHHEX
*
            LDA   #$26
            STA   CH
:GETCHAR    JSR   KEYESC
            CMP   #$8D        ;CR?
            BEQ   :DEFAULT
            SEC
            SBC   #$B0        ;CONVERT TO #
            CMP   #8
            BCS   :ERR
            STA   PSLOT
            JMP   PHHEX       ;PRINT IT
*
:ERR        JSR   BELL        ;TRY AGAIN
            JMP   :GETCHAR
*
:DEFAULT    LDA   (BASL),Y    ;REMOVE FLASH
            AND   #$3F
            ORA   #$80        ;FROM EXISTING
            STA   (BASL),Y    ;CHAR
            RTS
*
*
* ASK  PRINTER OPTION QUESTION
ASKPR?      LDX   PSLOT       ;PRINTER SLOT
            BEQ   :OUT        ;NONZERO?
            JSR   PRHERE
            DB    $8D,$8D,$8D,$8D
            ASC   "Do you want a printout (Y/N) ? "
            DB    $0
            JSR   KYESC
            LDX   #$FF
            CMP   #"Y"        ;YES?
            BEQ   :SETIT
            LDX   #$00
            LDA   #"N"
:SETIT      JSR   PCOUT
            STX   PRNTR?
            JMP   HOME
:OUT        STX   PRNTR?      ;SET FLAG
            RTS
*
* TURN ON PRINTER
PRON        LDA   CSWL
            STA   CSWSAV
            LDA   CSWL+1
            STA   CSWSAV+1
            LDA   #$00
            STA   CSWL
            LDA   PSLOT
            ORA   #$C0
            STA   CSWL+1
            RTS
CSWSAV      DB    $0,$0
*
PROFF       LDA   CSWSAV+1
            STA   CSWL+1
            LDA   CSWSAV
            STA   CSWL
            JMP   SETKBD

