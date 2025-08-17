            TYP   BIN
            DSK   ../build/VIEW.O
            PUT   VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/VERIFY.VARS
            ORG   VERIFYEND
VIEW        
            ORG   *+3

************************************
*           VIEW FILES             *
************************************
*
            LDX   #$04        ;VALUES OR TEXT
            JSR   CHOOZ1
            STA   :T1V0
            JSR   COMTRE
            LDA   #$05
            STA   STATE
            JSR   INITCD
            JSR   RDACNT
            LDA   NACTIV
            BNE   :NEXTFIL
            JMP   NOFIL0
*
:NEXTFIL    LDA   #3
            STA   WNDTOP
            JSR   PRTFL1      ;CLEAR FILENAME
            JSR   HOME
            LDA   #MPSTAT45
            JSR   LOWMES
            JSR   DOKEY       ;CAT DISPLAY
            JSR   HOME        ;VIEW FILES
*
            LDA   #4
            JSR   VLEFT
            LDA   #MDASHES
            JSR   PRINT
            LDA   #5
            STA   WNDTOP
            JSR   :SEEFILE    ;FILENAME
            JSR   ASKPR?      ;PRINT IT?
            JSR   SWPCHK      ;CHECK DISK
            JSR   OPNSRC      ;OPEN FILE
            LDA   #$FF
            STA   :RDFLAG
            LDA   PRNTR?      ;PRINTER?
            BNE   :PRINTIT
*
            LDA   PSLOT       ;ASKED?
            BEQ   :NOASK
            JSR   HOME        ;CLEAR
:NOASK      LDA   #$05
            STA   WNDTOP
:PAGELP     JSR   :PAGE       ;SEE PAGE
            BCS   :NEXTFIL
            JSR   :PROMPT     ;MORE?
            BCS   :NEXTFIL
            LDA   :DONE       ;MORE TO DO?
            BEQ   :PAGELP
            BNE   :NEXTFIL
*
:PRINTIT    JSR   PRON
            JSR   TOP1        ;PRINT HEADER
            JSR   CROUT
            JSR   :SEEFILE    ;& FILENAME
            JSR   CROUT2
            JSR   PROFF
            LDA   #$05
            STA   WNDTOP
:PPAGELP    JSR   PRON
            JSR   :PAGE       ;PRINT PAGE
            PHP
            JSR   PROFF
            PLP
            BCS   :PENDFIL
            LDA   :DONE
            BEQ   :PPAGELP
:PENDFIL    JSR   PRON        ;FINISH WITH
            JSR   CROUT2      ;2 BLANK LINES
            JSR   PROFF
            JMP   :NEXTFIL
*
*
* PRINT FILENAME
:SEEFILE    LDA   #$05        ;RESET
            STA   :TEMPV      ;VIEW CHAR
            LDA   #$00        ;POSITION
            STA   :TEMPH
            STA   :DONE       ;& END OF VIEW
            JSR   CURPNT
            JMP   PRTFIL
*
:PROMPT     LDA   #$03
            JSR   VLEFT       ;VTAB
            LDA   :DONE
            BMI   :PROMPT2
            LDA   #MCRESC
            JSR   PRINT
:PROMPT3    JSR   GETKEY
            CMP   #$9B
            BEQ   :SECOUT     ;(BEQ->CS)
            CLC
:SECOUT     RTS
*
:PROMPT2    LDA   #MPRESS1
            JSR   PRINT
            LDA   #$1E        ;CLEAR LINE
            STA   WNDWTH      ;UP TO BYTE
            JSR   CLREOL      ;COUNT
            LDA   #$28
            STA   WNDWTH
            BNE   :PROMPT3    ;ALWAYS
*
* PRINT PAGE OF VIEW DATA
:PAGE       LDA   :RDFLAG     ;NEED TO READ
            BEQ   :GOTDATA    ;DATA?
            JSR   SWPCHK
            JSR   RDDATA      ;READ IT
            LDA   #$00
            STA   :RDFLAG     ;CLEAR FLAG
            STA   POINT       ;POINT AT DATA
            LDA   DATADR
            STA   POINT+1
:GOTDATA    LDA   :TEMPV      ;RESTORE HTAB
            JSR   TABV        ;& VTAB
            LDA   :TEMPH
            STA   CH
            LDA   :T1V0       ;TEXT OR
            BNE   :TEXT       ;VALUES?
            LDA   #$11
            STA   :NCRS       ;LINE COUNTER
:LINELP     LDA   $C000
            CMP   #$9B
            BEQ   :PGABORT
            LDY   #$00        ;VALUES HERE<-
            JSR   CROUT
:HEXLP      JSR   :COUNTER
            LDA   (POINT),Y   ;GET BYTE
            JSR   PHBYTE      ;PRINT IT
            JSR   PRSPC
            INY
            CPY   #$08        ;8 BYTES
            BNE   :HEXLP
            JSR   PRSPC
            LDY   #$00        ;REWIND FOR
:CHRLP      LDA   (POINT),Y   ;ASCII OUT
            ORA   #$80
            JSR   CTRL?       ;NO CTRLS
            BCC   :SEECHR
            LDA   #"."
:SEECHR     JSR   PCOUT       ;PRINT CHAR
            INY
            CPY   #$08        ;8 BYTES
            BNE   :CHRLP
            TYA               ;8
            CLC
            ADC   POINT       ;UPDATE DATA
            STA   POINT
            LDA   POINT+1
            ADC   #0
            STA   POINT+1
            CMP   RPAGE       ;OUT OF DATA
            BCC   :VTEST      ;IN MEMORY?
            DEC   :RDFLAG
            LDA   EOF         ;END OF FILE?
            BNE   :SAYDONE
            BEQ   :POUT
:VTEST      DEC   :NCRS       ;ENOUGH LINES?
            BNE   :LINELP
            BEQ   :POUT
*
:PGABORT    SEC
            RTS
*
:TEXT       LDA   #$28        ;SET 40-CHAR
            STA   :NCHARS     ;LINES
            LDA   #$10        ;16 LINES
            STA   :NCRS
            LDY   #$00
:TEXTLP     LDA   $C000
            CMP   #$9B
            BEQ   :PGABORT
            JSR   :COUNTER
            LDA   (POINT),Y   ;GET CHAR
            ORA   #$80
            CMP   #$8D
            BEQ   :DOCR
            JSR   CTRL?       ;NO CTRLS
            BCS   :NXTCHR     ;(EXCEPT CR)
            JSR   PCOUT       ;PRINT CHAR
            DEC   :NCHARS     ;DEC CHAR COUNT
            BNE   :NXTCHR     ;TO ZERO?
            LDA   PRNTR?
            BEQ   :DECNCRS
:DOCR       JSR   CROUT
:DECNCRS    DEC   :NCRS
            LDA   #$28
            STA   :NCHARS
:NXTCHR     INC   POINT
            BNE   :NXTCHR0
            INC   POINT+1
:NXTCHR0    LDA   POINT+1
            CMP   RPAGE       ;OUT OF DATA
            BCC   :TTEST      ;IN MEMORY?
            DEC   :RDFLAG
            LDA   EOF
            BNE   :SAYDONE    ;END OF FILE?
            BEQ   :POUT
:TTEST      LDA   :NCRS       ;ENOUGH LINES?
            BEQ   :POUT
            BNE   :TEXTLP
*
:SAYDONE    DEC   :DONE
:POUT       LDA   CV          ;SAVE HTAB &
            STA   :TEMPV      ;VTAB
            LDA   CH
            STA   :TEMPH
            CLC
            RTS
*
*
:COUNTER    LDX   #$05
:COUNTIT    LDA   SCREEN,X
            CMP   #" "
            BEQ   :SPACE
            CMP   #"9"
            BEQ   :NINE
            CLC
            ADC   #$01
            DB    $CD
:SPACE      LDA   #"1"
            STA   SCREEN,X
:CNTOUT     RTS
:NINE       LDA   #"0"
            STA   SCREEN,X
            DEX
            BPL   :COUNTIT
            RTS
*
*
:T1V0       DB    $0
:TEMPY      DB    $0
:NCHARS     DB    $0
:NCRS       DB    $0
:TEMPH      DB    $0
:TEMPV      DB    $0
:DONE       DB    $0
:RDFLAG     DB    $0
*
VIEWEND
