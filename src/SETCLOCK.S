SETCLOCK
            LDA   #$16
            JSR   VLEFT
            LDA   DATE
            BEQ   :NODAT
            LDX   DATE+1
            JSR   SHODAT
            JMP   :NXTIN0
*
:NODAT      JSR   PRHERE
            ASC   "DD-MMM-YY"
            DB    $0
:NXTIN0     LDX   #0
:NXTINX     STX   CH
:NXTIN      JSR   CASKEY
            CMP   #$9B
            BNE   :NOTESC
            RTS
:NOTESC     CMP   #$8D
            BNE   :NOTCR
            JMP   :CR
:NOTCR      CMP   #$88
            BNE   :NOTLFT
            DEX
            BMI   :NXTIN0
            DEC   CH
            CPX   #2
            BEQ   :DECAGN
            CPX   #6
            BNE   :NXTIN
:DECAGN     DEX
            DEC   CH
            JMP   :NXTIN
*
:NOTLFT     CPX   #9
            BCS   :BEEP
            CMP   #$95
            BNE   :NXTIN1
            LDY   CH
            LDA   (BASL),Y
:NXTIN1     CPX   #2
            BCC   :SBDIG
            CPX   #7
            BCS   :SBDIG
            CMP   #$C1
            BCC   :BEEP
            CMP   #$DB
            BCC   :GOODIN
:BEEP       LDA   #$87
            JSR   PCOUT
            JMP   :NXTIN
:GOODIN     STA   LINEIN,X
            JSR   PCOUT
            INX
            CPX   #2
            BEQ   :INCAGN
            CPX   #6
            BNE   :NXTIN
:INCAGN     INC   CH
            INX
            BNE   :NXTIN
*
:SBDIG      CMP   #$B0
            BCC   :BEEP
            CMP   #$BA
            BCC   :GOODIN
            CPX   #1
            BNE   :BEEP
            CMP   #$C1
            BCC   :BEEP
            CMP   #$DB
            BCS   :BEEP
            PHA
            LDA   LINEIN
            STA   LINEIN+1
            LDA   #0
            STA   CH
            LDA   #$B0
            STA   LINEIN
            JSR   PCOUT
            LDA   LINEIN+1
            JSR   PCOUT
            INC   CH
            LDX   #3
            PLA
            JMP   :NXTIN1
:GOSKIP     RTS
*
:CR         CPX   #9
            BCS   :CROK
            CPX   #0
            BEQ   :GOSKIP
            JMP   :BEEP
:CROK       LDA   LINEIN
            LDX   LINEIN+1
            JSR   :CNVT
            STA   :DAY
            CMP   #$20
            BCS   :GBDDAY
            LDY   #$0B
:GETDT1     LDA   LINEIN+3
            CMP   MONTH1,Y
            BEQ   :GETDT3
:GETDT2     DEY
            BPL   :GETDT1
            JMP   :BADMON
:GETDT3     LDA   LINEIN+4
            CMP   MONTH2,Y
            BNE   :GETDT2
            LDA   LINEIN+5
            CMP   MONTH3,Y
            BNE   :GETDT2
            LDA   :DAY
            BEQ   :BADDAY     ;DAY=0
            CMP   :DAYS,Y
:GBDDAY     BCS   :BADDAY     ;DAY TOO BIG
            INY
            STY   :MONTH
            LDA   LINEIN+7
            LDX   LINEIN+8
            JSR   :CNVT
            STA   :YEAR
            AND   #3
            BEQ   :LEAP
            LDA   :MONTH
            CMP   #2
            BNE   :LEAP       ;NOT FEB.
            LDA   :DAY
            CMP   #$1D        ;29TH?
            BEQ   :BADDAY
:LEAP       LDA   :MONTH
            ASL
            ASL
            ASL
            ASL
            ASL
            ORA   :DAY
            STA   DATE
            LDA   :YEAR
            ROL
            STA   DATE+1
*
* set time to 0
            LDA   #0
            STA   TIME
            STA   TIME+1
*
* disable clock driver after setting date
* and update ProDOS machine byte to say there's no clock
            LDA   #$60
            STA   JCLOCK
            LDA   MACHID
            AND   #$FE
            STA   MACHID
            RTS

:BADDAY     LDX   #0
            DB    $2C
:BADMON     LDX   #3
            LDA   #$87
            JSR   PCOUT
            JMP   :NXTINX
*
:CNVT       AND   #$0F
            STA   :TEMP
            ASL
            ASL
            CLC
            ADC   :TEMP
            ASL
            STA   :TEMP
            TXA
            AND   #$0F
            CLC
            ADC   :TEMP
            RTS
:TEMP       DB    $0
:DAY        DB    $0
:MONTH      DB    $0
:YEAR       DB    $0
:DAYS       DB    $20,$1E,$20,$1F,$20,$1F,$20,$20,$1F,$20
            DB    $1F,$20
*
