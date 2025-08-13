***********************************
*                                 *
*     MISC. I/O ROUTINES          *
*                                 *
***********************************

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
*
*
* MY OWN INVERSE FLAG...
PINVRS      LDY   #$C0
            DB    $2C
PFLASH      LDY   #$80
            DB    $2C
PNORML      LDY   #$00
            STY   PINVFL
            RTS
*
DOC00E      BIT   A2E
            BPL   :C00EQ
            STA   $C00E
:C00EQ      RTS
*
DOC00F      BIT   A2E
            BPL   :C00FQ
            STA   $C00F
:C00FQ      RTS
*
*
* IS CHAR IN ACC A CONTROL?
*
CTRL?       CMP   #$A0
            BCS   :OK
            CMP   #$80
            BCS   :BADOUT
:OK         CLC
:BADOUT     RTS
*
* PRINT DOLLAR SIGN, KEEP ACC
*
DOLLAR      PHA
            LDA   #"$"
            JSR   PCOUT
            PLA
            RTS
*
*
* RDKEY WITH CASE CONVERT
*
CASKEY      JSR   PRDKEY
            JMP   LOW2UP
*
* READS KEYBOARD WITHOUT CURSOR GAMES
* -> CHARACTER IN AREG
*
GETKEY      BIT   KBDSTB
:LOOP       LDA   KBD
            BPL   :LOOP
            JSR   CHKALT
            BCS   GETKEY
            BIT   KBDSTB
LOW2UP      CMP   #$E0        ;CONVERT LOWER
            BCC   :LOWQ       ;TO UPPER CASE
            SBC   #$20
:LOWQ       RTS
*
*
CKESC       LDA   $C000
            JMP   KEYES1
*
KYESC       JSR   GETKEY
            JMP   KEYES1
*
PRDKEY      BIT   $C010       ;NO TYPEAHEAD
            JSR   RDKEY
            JSR   CHKALT
            BCS   PRDKEY
            RTS
*
* FOR KEYPRESSES, CHECK FOR CTRL-@
* ALTCHARSET TOGGLE
*
CHKALT      CMP   #$80        ;CTRL-@?
            BNE   :CHKQ
*
* CARRY SET NOW
*
            BIT   A2E         ;ON A //E?
            BPL   :CHKQ       ;NO: CLC OUT.
            LDA   $C01E       ;YES: WHAT'S
            BPL   :ALTON      ;ALTCHARSET?
            STA   $C00E       ;-: GO +
            RTS
:ALTON      STA   $C00F       ;+: GO -
            RTS
:CHKQ       CLC
            RTS
*
*
* DO VTAB, & HTAB 0
*
VLEFT       JSR   TABV
            LDA   #$00
SETCH       STA   CH
* BIT *FLAG80
* BPL NOT80
* STA $57B                ;OURCH
:NOT80      RTS
*
* HEX TO DECIMAL CONVERTER
* PUT 2-BYTE HEX NUMBER IN HEXNUM  ->
* 5 DECIMAL NUMBERS LEFT IN DIGIT
*
HEXDC1      LDX   #0
HEXDC2      STX   HEXNUM+1
            STA   HEXNUM
HEXDEC      LDA   #0
            STA   HEXNUM+2
HEXDC3      LDA   #$00
            LDX   #$07
:CLRLOOP    STA   DIGIT,X
            DEX
            BNE   :CLRLOOP
            LDX   #$07
            BNE   :START
:MAKEIT     INC   DIGIT,X
:START      LDA   HEXNUM
            STA   :LAST
            LDA   HEXNUM+1
            STA   :LAST+1
            LDA   HEXNUM+2
            STA   :LAST+2
:DIGITLP    SEC
            LDA   :LAST
            SBC   :POWER0,X
            STA   HEXNUM
            LDA   :LAST+1
            SBC   :POWER1,X
            STA   HEXNUM+1
            LDA   :LAST+2
            SBC   :POWER2,X
            STA   HEXNUM+2
            BCS   :MAKEIT
            DEX
            BNE   :DIGITLP
            LDA   :LAST
            STA   DIGIT
            RTS
:POWER0     DB    $01,$0A,$64,$E8,$10,$A0,$40,$80
:POWER1     DB    $00,$00,$00,$03,$27,$86,$42,$96
:POWER2     DB    $00,$00,$00,$00,$00,$01,$0F,$98
:LAST       DB    $00,$00,$00
*
* PRINT 3 DECIMAL DIGITS IN *DIGIT
* LEADING ZEROS PRINTED
PRTLZ       LDX   #$02
:NEXTDIG    LDA   DIGIT,X     ;PRINT DECIMAL
            JSR   MYHEX       ;DIGITS
            DEX
            BPL   :NEXTDIG
            RTS
*
*
PRT8RJ      LDX   #7
            DB    $2C
PRT5RJ      LDX   #4
            DB    $2C
PRT3RJ      LDX   #2
            DB    $2C
PRT2RJ      LDX   #1
:PRTRJ      LDA   DIGIT,X
            BNE   PRTDIG
            JSR   PRSPC
            DEX
            BNE   :PRTRJ
            BEQ   PRTDIG      ;ALWAYS
*
PRT8LJ      LDX   #7
            DB    $2C
PRT5LJ      LDX   #4
:PRTLJ      LDA   DIGIT,X
            BNE   PRTDIG
            DEX
            BNE   :PRTLJ
            BEQ   PRTDIG
PRT2DG      LDX   #1
PRTDIG      LDA   DIGIT,X
            JSR   MYHEX
            DEX
            BPL   PRTDIG
            RTS
*
* PRINT TRACK & SECTOR #'S
*
TSVALS      JSR   PRTTRK
            JSR   PRHERE
            ASC   ", "
            DB    $0
            LDA   #MSECTOR
            JSR   PRINT       ;'SECTOR $'
            LDA   RSECTR      ;SECTOR MORE
            CMP   #$10        ;THAN 1 DIGIT?
            BCS   PHBYTE      ;YES:PRINTBYTE
            BCC   PHHEX       ;NO:PRINTDIGIT
*
PRTTRK      LDA   #MTRACK
            JSR   PRINT       ;'TRACK $'
            LDA   RTRACK
* falls through to PHBYTE
*
* MY PRINT BYTE & HEX ROUTINE
PHBYTE      PHA
            LSR
            LSR
            LSR
            LSR
            JSR   MYHEX       ;HIGH DIGIT
            PLA
PHHEX       AND   #$0F        ;LOW DIGIT
MYHEX       ORA   #$B0
            CMP   #$BA
            BCC   PCOUT
            ADC   #$06
            JMP   PCOUT
*
*
PRSPC       LDA   #" "
* falls through to PCOUT
*
* MY COUT ROUTINE
*
PCOUT       BIT   A2E
            BMI   :CHKMASK    ;ON //E
*
* ON A II PLUS: CONVERT LOWERCASE
*
            CMP   #$E0        ;LOWERCASE?
            BCC   :NO80A      ;NO
            SBC   #$20        ;MAKE UPPER.
            BNE   :NO80A      ;ALWAYS
*
:CHKMASK    BIT   $C01F       ;80-COL?
            BPL   :NO80A      ;NO
*
            CMP   #$20
            BCC   :FLASH      ;MAKE $40-$5F
:NO80A      BIT   PINVFL
            BPL   :CHKPRTR    ;IF MASKED,
            BVC   :FLASH      ;IF INVERSE,
*
* IF II+: NO SPECIAL CHECK
* IF //E: CHECK FOR ALTCHARSET
*
            BIT   A2E         ;//E OR II+?
            BPL   :N2EALTL    ;II+
*
*//E:
*IF ALTSET: ALLOW INVERSE LOWER CASE
*
            BIT   $C01F       ;80-COL?
            BPL   :NO80       ;NO
*
* MUST DO SPECIAL CRAP FOR 80-COL
* BECAUSE 80-COL FIRMWARE INTERPRETS
* $00-$1F AS CONTROL CHARS. MUST
* CONVERT TO $40-$5F.
*
            CMP   #$20
            BCS   :Y2EALTL    ;AND $7F
            BCC   :FLASH      ;MAKE $40-$5F
*
:NO80       BIT   $C01E       ;ALTCHARSET?
            BPL   :N2EALTL    ;NO
            CMP   #$E0        ;IF NOT
            BCS   :Y2EALTL    ;LOWERCASE
:N2EALTL    AND   #$3F        ;MASK INVERSE
:Y2EALTL    AND   #$7F        ;MASKALTINVLOW
            BPL   :CHKPRTR
*
:FLASH      AND   #$3F        ;MAKE FLASH
            ORA   #$40
*
:CHKPRTR    CMP   #$80        ;IF FLASH OR
            BCS   :GOCOUT     ;INVERSE:
            PHA               ;SAVE CHAR...
            LDA   PSLOT
            ORA   #$C0
            CMP   CSWL+1      ;PRINTING?
            BNE   :NOTPRTR    ;NO
            PLA               ;YES:
            BIT   A2E         ;WATCHING OUT
            BPL   :NLOWINV    ;FOR ALTCHR,
            BIT   $C01E
            BMI   :MAKNORM
:NLOWINV    AND   #$3F
:MAKNORM    ORA   #$80        ;CONVERT BACK
            CMP   #$A0        ;TO PRINTING
            BCS   :GOCOUT
            ORA   #$40
            BNE   :GOCOUT     ;(ALWAYS)
*
:NOTPRTR    PLA
:GOCOUT     CMP   #$FF        ;SOME PRINTERS
            BNE   :GOCOUT2    ;DELETE WITH
            LDA   #$DF        ;FF'S
:GOCOUT2    JMP   COUT
*
* GIVE CATALOG DISPLAY FUNCTION TITLE
*
TOP1        JSR   HOME
TOP1A       LDA   #0
            STA   WNDTOP
            JSR   TABV
            LDA   CHOICE      ;FUNCTION NAME
            JSR   PRINT
            JSR   PRSPC
            LDA   OPTCHS
            BMI   :TOP1A
            JSR   PRINT
:TOP1A      RTS
*
SEEDEV      PHA
            JSR   PRHERE
            ASC   "Slot "
            DB    $0
            PLA
            PHA
            AND   #$70
            LSR
            LSR
            LSR
            LSR
            JSR   PHHEX
            JSR   PRHERE
            ASC   "  Drive "
            DB    $0
            PLA
            ASL
            LDA   #1
            ADC   #0
            JMP   PHHEX
*
*
* BOTTOM OF SCREEN MESSAGE
*
LOWMES      JSR   LOWSET
            JSR   PRINT
            CLC
            RTS
*
LOWSET      PHA
            LDA   #$14
            JSR   VLEFT
            LDA   #MBLANK4
            JSR   PRINT
            LDA   #$15
            JSR   TABV
            PLA
            RTS
*
INSCOM      LDA   #MCRESC
            JSR   PRINT
            JSR   KYESC
            JSR   LOHERE
            DB    $0
            LDA   #1
            RTS
*
* BLANK BOTTOM 4 LINES THEN
* PRINT TEXT THAT FOLLOWS THE JSR
* AT BOTTOM OF SCREEN
LOHERE      JSR   LOWSET
*
* falls through to PRHERE
*
* PRINT TEXT THAT FOLLOWS THE JSR
* AT CURRENT TEXT POSITION
PRHERE      PLA               ;GET RETURN
            CLC               ;ADDRESS
            ADC   #$01
            STA   MESPNT      ;POINT AT
            PLA               ;FOLLOWING
            ADC   #$00        ;BYTE
            STA   MESPNT+1
            JSR   PRINT2      ;PRINT MESS.
            LDA   MESPNT+1    ;RESTORE
            PHA               ;RETURN ADDR.
            LDA   MESPNT
            PHA
            RTS               ;RETURN!
*
* PRINT MESSAGE BY ID
* AT BOTTOM OF SCREEN
LINE24      PHA
            LDA   #$17
            JSR   VLEFT
            LDA   #3
            STA   CH
            JSR   CLREOL
            PLA
* falls through to PRINT
*
* MESSAGE PRINTER
* MESSAGE # IN ACC ->
*
PRINT       ASL               ;LOOK-UP &
            TAY
            LDA   MESSAG,Y    ;POINT AT
            STA   MESPNT      ;MESSAGE
            LDA   MESSAG+$1,Y
            STA   MESPNT+1
PRINT2      LDY   #$00
            LDA   (MESPNT),Y  ;GET CHAR
            BEQ   :OUT
            CMP   #$2F
            BEQ   :CLEAR
            JSR   PCOUT       ;PRINT CHAR
:NEXT       INC   MESPNT      ;2-BYTE INC.
            BNE   PRINT2
            INC   MESPNT+1
            BNE   PRINT2      ;(ALWAYS)
:OUT        RTS
*
:CLEAR      JSR   CLREOL
            JMP   :NEXT
*
*
*
* NO FILES SELECTED
NOSEL       JSR   LOHERE
            ASC   "No files selected"
            DB    $0
            JMP   PRESS
*
* NO FILES TO WORK WITH
NOFIL0      LDA   #5
            JSR   VLEFT
* falls through to NOFILS
NOFILS      LDA   #MNOFILES
* falls through to PRTPRS
*
* PRINT MESSAGE BY ID THEN RESTART
PRTPRS      JSR   PRINT
* falls through to PRESS
*
* PRESS A KEY & PROGRAM RESTART
PRESS       LDA   #MPRESS
            JSR   PRINT
            JSR   GETKEY
KYESX       JMP   FILER
*
* GET CHARACTER, CHECK ESC
*
KEYESC      JSR   CASKEY
KEYES1      CMP   #$9B
            BEQ   KYESX
            RTS
*
* PRINT BEST ERROR MESSAGE
* FOR ERROR CODE IN RRTN
*
ERRMSG      LDA   RRTN
            LDY   #$0C
:OUCHLP     CMP   :ERRNUM,Y
            BEQ   :OUCH0      ;FOUND ERROR # IN TABLE
            DEY
            BPL   :OUCHLP
*
:OUCH2      CMP   #$40
            BCS   :NOT27
            JSR   PRHERE
            ASC   "I/O "
            DB    $0
*
:NOT27      JSR   PRHERE
            ASC   "Error"
            DB    $0
            BIT   DOSNOW
            BPL   :DOS33
*
            LDA   RRTN
            CMP   #$29
            BCC   :SKIP
            JSR   PRHERE
            ASC   " $"
            DB    $0
            LDA   RRTN
            BNE   :SKIP1      ;ALWAYS (BECAUSE RRTN >= $29)
*
* These are CII-specific error codes, some
* of which happen to match ProDOS error codes.
* We search for the value of RRTN, and the
* match index is used to calculate the message ID
* to PRINT (simple +offset, see :OUCH0 below)
:ERRNUM     DB    $2B,$44,$45,$46,$48,$49,$4E,$3F,$52,$47
            DB    $40,$2F,$28
*
:OUCH0      JSR   CROUT2
            TYA
            CLC
            ADC   #$45
            JSR   PRINT
            JMP   CROUT2

*
:SKIP       JSR   PRHERE
            ASC   ": Block $"
            DB    $0
            LDA   BLKNUM+1
            JSR   PHBYTE
            LDA   BLKNUM
:SKIP1      JSR   PHBYTE
:SKIPBLK    JMP   :OUCH1
*
:DOS33      JSR   PRHERE
            ASC   ": "
            DB    $0
            JSR   TSVALS
:OUCH1      JMP   CROUT
*
CROUT2      JSR   CROUT
            JMP   CROUT
*
OUCH        JSR   HOME
            JSR   ERRMSG
            JSR   CROUT
*LDA LEVEL
*PHA
*LDA #1
*STA LEVEL
            JSR   CLOSE
*PLA
*STA LEVEL
            LDA   #MPRESS
            JSR   PRINT
            JMP   GETKEY

