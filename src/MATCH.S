            TYP   BIN
            DSK   ../build/MATCH.O
            PUT   VARS
            PUT   ../build/FILER.VARS
            ORG   MAINEND
MATCH       
            ORG   *+3

*
* CALL THE PATTERN MATCHER HERE
*
            JSR   CURPNT
            JSR   GETTYP
            STA   :FILTYPE    ;SAVE IT
            JSR   FTOCR       ;CONVERT FNAME
            LDX   #$00        ;SET POINTERS
            STX   :SP
            LDY   #$00
            JSR   :RECURSE
            BCS   :MOUT
            LDA   CURR
            STA   LASTM
:MOUT       RTS
*
* THE PATTERN MATCHER ITSELF
:RECURSE    TXA               ;STACK THE
            PHA               ;POINTERS
            TYA
            LDX   :SP
            STA   STACKY,X
            PLA
            STA   STACKX,X
            TAX
            INC   :SP
            LDA   LINEIN,X    ;READ PATTERN
            CMP   #"="        ;CHARACTER
            BEQ   :EQUALS
            CMP   #$AC        ;","
            BEQ   :COMMA
            CMP   #$8D
            BEQ   :CR
            CMP   FILNAM,Y    ;MATCHES FILE-
            BEQ   :CHMATCH    ;NAME CHAR?
            SEC               ;MATCH FAILS
:OUT        DEC   :SP         ;POP STACK
            LDX   :SP
            LDA   STACKX,X
            LDY   STACKY,X
            TAX
            RTS
*
:EQUALS     INX               ;MATCH ON NEXT
:TRYNEXT    JSR   :RECURSE    ;PATTERN CHAR?
            BCC   :OUT        ;NO:
            LDA   FILNAM,Y    ;AT END OF
            CMP   #$8D        ;FILENAME?
            BEQ   :FAILOUT    ;YES: FAILS
            INY               ;ELSE TRY NEXT
            BNE   :TRYNEXT    ;FILE CHAR
*
:COMMA      LDA   #$FF        ;FLAG COMMA
            BMI   :SAVCAMA
*
:CR         LDA   #$00        ;FLAG NO COMMA
:SAVCAMA    STA   :CAMAFLG
            LDA   FILNAM,Y    ;END OF
            CMP   #$8D        ;FILENAME?
            BNE   :FAILOUT
:ENDNAME    LDA   :CAMAFLG    ;ELSE CHECK
            BMI   :DOCAMA     ;COMMA
            CLC               ;SUCCEEDS
            BCC   :OUT
*
:CHMATCH    INX               ;MATCH NEXT
            INY               ;CHAR OF BOTH
            JSR   :RECURSE    ;STRINGS
            JMP   :OUT
*
:PROTYP3    LDA   TYPES,Y     ;FILETYPE
            CMP   :FILTYPE
            BEQ   :SUCCOUT
:DOCAMA     INX               ;NEXT PAT CHAR
            LDA   LINEIN,X
            CMP   #$8D        ;CR?
            BEQ   :FAILOUT    ;YES: FAIL
            CMP   #$AC        ;","
            BEQ   :DOCAMA     ;SKIP COMMAS
            BIT   DOSNOW
            BMI   :PROTYP
*
            LDY   #$08
:TRYTYPE    CMP   TYPCHR,Y    ;MATCH FILTYP?
            BEQ   :GOTTYPE
            DEY               ;NO:TRY NEXT
            BNE   :TRYTYPE
            BEQ   :DOCAMA     ;(NO BAD STOP)
:GOTTYPE    LDA   TYPBYT,Y    ;GET TYPE BYTE
            CMP   :FILTYPE    ;FILTYPE MATCH?
            BNE   :DOCAMA     ;NO:TRY NEXT
:SUCCOUT    CLC               ;YES:SUCCEED
            BCC   :GOOUT
:FAILOUT    SEC
:GOOUT      JMP   :OUT
*
:PROTYP     LDY   #TYPE1-TYPES-1  ;# of filetypes - 1
:PROTYP0    LDA   LINEIN,X
            CMP   TYPE1,Y
            BEQ   :PROTYP1
:PROAGN     DEY
            BPL   :PROTYP0
            BMI   :DOCAMA     ;NO MATCH
:PROTYP1    STX   :XSAVE
            INX
            LDA   LINEIN,X
            CMP   #$8D
            BEQ   :FAILOUT
            CMP   TYPE2,Y
            BNE   :PROTYP2
            INX
            LDA   LINEIN,X
            CMP   #$8D
            BEQ   :FAILOUT
            CMP   TYPE3,Y
            BEQ   :PROTYP3    ;MATCH!
:PROTYP2    LDX   :XSAVE
            JMP   :PROAGN     ;CK NEXT TYPE
*

*
:FILTYPE    DB    $0
:CAMAFLG    DB    $0
:SP         DB    $0
:XSAVE      DB    $0
*
* CONVERT FILENAME TO CR FORMAT
* CAN'T USE DOSNOW TO DETERMINE
* FILENAME FORMAT
*
FTOCR       EQU   *
            LDY   #1
            LDA   (POINT),Y
            CMP   #$10
            BCS   :FTPRODOS
*
:FTDOS33    LDX   #$1E        ;(NAME LENGTH)
            LDY   #$00
            LDA   (POINT),Y   ;DELETED?
            CMP   #$FF
            BNE   :LONG
            DEX               ;DON'T USE
:LONG       TXA               ;LAST CHAR
            TAY
            INC   POINT       ;POINT TO
            INC   POINT       ;FILENAME
            INC   POINT
:SPACE      DEY
            LDA   (POINT),Y   ;LOOP TO IGNORE
            CMP   #" "        ;LAST SPACES
            BEQ   :SPACE
            STA   FILNAM,Y    ;SAVE LAST CHAR
            LDA   #$8D        ;END WITH CR
            STA   FILNAM+$1,Y
            DEY
:NEXTCHR    LDA   (POINT),Y   ;COPY THE REST
            STA   FILNAM,Y    ;OF THE CHARS
            DEY
            BPL   :NEXTCHR
            DEC   POINT
            DEC   POINT
            DEC   POINT
            RTS
*
:FTPRODOS   DEY               ;1 --> 0
            LDA   (POINT),Y
            AND   #$0F        ;NECESSARY?
            BNE   :PRO1
            LDA   #$0F
:PRO1       TAX
            INY               ;0 --> 1
:PRO2       LDA   (POINT),Y
            BEQ   :PRO3
            ORA   #$80
            STA   FILNAM-1,Y
            INY
            DEX
            BNE   :PRO2
:PRO3       LDA   #$8D
            STA   FILNAM-1,Y
            RTS
*
MATCHEND
