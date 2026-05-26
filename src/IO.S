            TYP   BIN
            DSK   ../build/IO.O
            PUT   VARS
            PUT   ../build/MESSAGES2.VARS
            PUT   ../build/MESSAGES.VARS
            PUT   ../build/DRIVE35.VARS
            ORG   DRIVE35END
*
***********************************
*                                 *
*        CORE I/O ROUTINES        *
*                                 *
***********************************
*
* PINVRS    set inverse mode for PCOUT
* PFLASH    set flash mode for PCOUT
* PNORML    set normal mode for PCOUT
* PCOUT     print 1 character
*           - auto-uppercase on < //e
*           - inverse/flashing/normal (call P* mode routine)
*           - lowercase inverse
*           - 40 and 80 columns
*           - screen or printer
* PHHEX     print 1-digit hex value (0..F)
* PHBYTE    print 2-digit hex value (00..FF)
* PRSPC     print 1 space character
* CROUT2    print 2 carriage returns
* LOWMES
* LOWSET
* INSCOM
* LOHERE
* PRHERE
* LINE24
* PRINT
* KEYESC
* KEYES1
*
* CTRL?     check if ACC is a control character
* DOLLAR    print $, save/restore ACC
* PRDKEY    read 1 key [visible cursor][blocking]
* CASKEY    read 1 key, convert to uppercase [visible cursor][blocking]
* GETKEY    read 1 key, convert to uppercase [no cursor][blocking]
* KYESC     read 1 key, check if it's Esc [no cursor][blocking]
* CKESC     check if Esc has been pressed [non-blocking]
* CHKKEY
*
* CHOPOS    set VTAB/HTAB for main menu
* VLEFT     set VTAB to ACC, then set HTAB to 0
* SETCH     set HTAB
*
* HEXDEC    convert value to decimal, store in DIGIT
* HEXDC1
* HEXDC2
* HEXDC3
* PRTLZ     print 3 DIGITs with leading zeros
* PRT8RJ    print 1 DIGIT right-justified in 8 spaces
* PRT5RJ    print 1 DIGIT right-justified in 5 spaces
* PRT3RJ    print 1 DIGIT right-justified in 3 spaces
* PRT2RJ    print 1 DIGIT right-justified in 2 spaces
* PRT5LJ    print 1 DIGIT left-justified in 5 spaces
* PRT2DG    print 2 DIGITs
* PRTDIG    print 1 DIGIT
*
* COL40     set to 40 columns
* COL80     set to 80 columns
* VDINIT    initialize machine video
*
COL40       LDA   #$19
            STA   SDCH
            BIT   FLAG80      ;(10/6/87)
            BPL   :OUT40
            LDA   #$15        ;
            JSR   $C300       ;
:OUT40
* fall through to VDINIT
VDINIT      JSR   INIT
            JSR   SETNOR
            JSR   SETVID
            JSR   SETKBD
*[4am] fall through to set ALTCHARSET on //e
*DOC00F
            BIT   A2E
            BPL   :C00FQ
            STA   $C00F
:C00FQ      RTS
SDCH        DB    $19
*
COL80       BIT   FLAG80
            BPL   :C00FQ
            LDA   #$C3
            STA   CSWL+1
            LDA   #0
            STA   CSWL
            LDA   #$41
            STA   SDCH
            JMP   CROUT
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
* IS CHAR IN ACC A CONTROL?
CTRL?       CMP   #$A0
            BCS   :OK
            CMP   #$80
            BCS   :BADOUT
:OK         CLC
:BADOUT     RTS
*
* PRINT DOLLAR SIGN, KEEP ACC
DOLLAR      PHA
            LDA   #"$"
            JSR   PCOUT
            PLA
            RTS
*
* RDKEY WITH CASE CONVERT
CASKEY      JSR   PRDKEY
            JMP   :LOW2UP
*
CHKKEY      JSR   KYESC
CHKKEY0     CMP   #$88        ;LEFT ARROW
            BEQ   :RETCLR
            CMP   #$8B        ;UP ARROW
            BEQ   :RETCLR
            CMP   #$95        ;RIGHT ARROW
            BEQ   :RETSET
            CMP   #$8A
            RTS
:RETCLR     CLC
:RETSET     RTS
*
CKESC       LDA   $C000
            JMP   KEYES1
*
KYESC       JSR   GETKEY
            JMP   KEYES1
*
PRDKEY      BIT   $C010       ;NO TYPEAHEAD
            JSR   RDKEY
            JSR   :CHKALT
            BCS   PRDKEY
            RTS
* FOR KEYPRESSES, CHECK FOR CTRL-@
* ALTCHARSET TOGGLE
:CHKALT     CMP   #$80        ;CTRL-@?
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
* POSITION FOR MAIN SCREEN CHOOSES
*
CHOPOS      LDA   #$11
            STA   WNDWTH
            LDA   #$17
            STA   WNDLFT
            LDA   #$04
* fall through to VLEFT
*
* DO VTAB, & HTAB 0
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
            JSR   :MYHEX      ;DIGITS
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
PRT5LJ      LDX   #4
:PRTLJ      LDA   DIGIT,X
            BNE   PRTDIG
            DEX
            BNE   :PRTLJ
            BEQ   PRTDIG
PRT2DG      LDX   #1
PRTDIG      LDA   DIGIT,X
            JSR   :MYHEX
            DEX
            BPL   PRTDIG
            RTS
*
*
* MY PRINT BYTE & HEX ROUTINE
PHBYTE      PHA
            LSR
            LSR
            LSR
            LSR
            JSR   :MYHEX      ;HIGH DIGIT
            PLA
PHHEX       AND   #$0F        ;LOW DIGIT
:MYHEX      ORA   #$B0
            CMP   #$BA
            BCC   PCOUT
            ADC   #$06
            BNE   PCOUT       ;ALWAYS
*
*
PRSPC       LDA   #" "
* falls through to PCOUT
*
* MY COUT ROUTINE
*
PCOUT       BIT   HASLOWER
            BMI   :CHKMASK    ;ON //E
*
* ON A II PLUS: CONVERT LOWERCASE
*
            CMP   #$E0        ;LOWERCASE?
            BCC   :NO80A      ;NO
            SBC   #$20        ;MAKE UPPER.
            BNE   :NO80A      ;ALWAYS
*
:CHKMASK    BIT   FLAG80      ;supports 80-col?
            BPL   :NO80A      ;no
            BIT   $C01F       ;currently 80-col?
            BPL   :NO80A      ;no
*
            CMP   #$20
            BCC   :FLASH      ;MAKE $40-$5F
:NO80A      BIT   PINVFL
            BPL   :CHKPRTR    ;IF MASKED,
            BVC   :FLASH      ;IF INVERSE,
*
* IF II+: NO SPECIAL CHECK
* IF //E: CHECK FOR 80-COL
*
            BIT   A2E         ;//E OR II+?
            BPL   :N2EALTL    ;II+
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
:CHKPRTR
:GOCOUT
:GOCOUT2    JMP   COUT
*
* BOTTOM OF SCREEN MESSAGE
LOWMES      JSR   LOWSET
            JSR   PRINT
            CLC
            RTS
*
* BLANK BOTTOM 4 LINES OF SCREEN
* AND SET VTAB THERE
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
            JSR   :PRINT2     ;PRINT MESS.
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
PRINT       CMP   #MSG2START
            BCC   :PRINT1
            JSR   MESSAGES2   ;decompress extra messages
:PRINT1     ASL               ;LOOK-UP &
            TAY
            LDA   MESSAG,Y    ;POINT AT
            STA   MESPNT      ;MESSAGE
            LDA   MESSAG+$1,Y
            STA   MESPNT+1
:PRINT2     LDY   #$00
            LDA   (MESPNT),Y  ;GET CHAR
            BEQ   :OUT
            CMP   #$40
            BCC   PRINT       ;chain another message
            CMP   #$FF
            BEQ   :CLEAR
            JSR   PCOUT       ;PRINT CHAR
:NEXT       INC   MESPNT      ;2-BYTE INC.
            BNE   :PRINT2
            INC   MESPNT+1
            BNE   :PRINT2     ;(ALWAYS)
:OUT        RTS
*
:CLEAR      JSR   CLREOL
            JMP   :NEXT
*
KYESX       JMP   ($3F2)
*
* GET CHARACTER, CHECK ESC
*
KEYESC      JSR   CASKEY
KEYES1      CMP   #$9B
            BEQ   KYESX
            RTS
*
CROUT2      JSR   CROUT
            JMP   CROUT
*
* READS KEYBOARD WITHOUT CURSOR GAMES
* -> CHARACTER IN ACC
GETKEY      BIT   KBDSTB
            JSR   POSTDZX
]KBDLOOP    LDA   KBD
            BPL   ]KBDLOOP
            JSR   :CHKALT
            BCS   GETKEY
            BIT   KBDSTB
:LOW2UP     CMP   #$E0        ;CONVERT LOWER
            BCC   :LOWQ       ;TO UPPER CASE
            SBC   #$20
:LOWQ       RTS
*
* CLOSE ALL FILES VIA PRODOS MLI
*
CLOSE       JSR   MLI
            DB    $CC
            DW    :CLSLST
            RTS
:CLSLST     DB    $1,$0
*
* GET DATE VIA PRODOS MLI
*
GETDAT      JSR   MLI
            DB    $82
            DB    $0,$0
            LDY   #3
]DATLOOP    LDA   DATE,Y
            STA   CRTDAT,Y
            STA   MODDAT,Y
            DEY
            BPL   ]DATLOOP
            RTS
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
MONTH1      ASC   "JFMAMJJASOND"
MONTH2      ASC   "AEAPAUUUECOE"
MONTH3      ASC   "NBRRYNLGPTVC"
*
* Menus: (USE THE NAMED IDS LISTED IN MESSAGES)
*  0 Main
*  1 Catalog
*  2 Delete
*  3 Verify
*  4 View
*  5 Format
*  6 Copy
*  7 Rename
*
*  Menu:          0       1          2         3        4       5        6         7         8
LAST        DB    MQUIT+1,MWHIDDEN+1,MDELDOS+1,MSPEED+1,MTEXT+1,MDOS33+1,MCOPDOS+1,MVOLUME+1,MREBOOT+1
FIRST       DB    MCOPY,MNORMAL,MDELFILE,MVERFILE,MVALUES,MPRODOS,MCOPFILE,MFILES,MQPRODOS
CHOICE      DB    MCOPY,MNORMAL,MDELFILE,MVERFILE,MVALUES,MPRODOS,MCOPFILE,MFILES,MQPRODOS
*
*
IOEND
