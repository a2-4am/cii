*
* LINE INPUT - LINE AT LOC $200
*
GETLN       LDX   #$00
            BEQ   :GETLN1     ;ALWAYS
:BEEP       JSR   BELL
:GETLN1     JSR   CASKEY
            CMP   #$88
            BEQ   :LEFT
            CMP   #$95
            BEQ   :RIGHT
            CMP   #$8D
            BEQ   :CR
            CMP   #$9B
            BEQ   :ESC
            CMP   #$A0
            BCC   :GETLN1     ;CTRL CHAR
:GETLN2     CPX   LINLIM
            BCS   :GETLN1
            JSR   :CKLEGAL
            BCS   :BEEP
            STA   LINEIN,X
            JSR   PCOUT
            INX
            JMP   :GETLN1
*
:RIGHT      LDY   CH
            LDA   (BASL),Y
            JMP   :GETLN2
*
:LEFT       DEX
            BMI   GETLN
            JSR   PCOUT
            JMP   :GETLN1
*
:CR         STA   LINEIN,X
            STX   :TEMP
            PHA
            JSR   CLREOL
            PLA
            LDX   :TEMP
            SEC
            BEQ   :ESC        ;CR ONLY
            CLC
:ESC        RTS
*
:CKLEGAL    CMP   #$C1
            BCC   :CKLEG1
            CMP   #$DB
            BCS   :CKLEG1
:ISLEGAL    CLC
            RTS
*
:CKLEG1
            CMP   #$AC        ;","
            BNE   :NOTCOMA
            LDA   LINLIM
            CMP   #$24
            BNE   :NOTLEGL
            LDA   #$AC        ;","
            BNE   :ISLEGAL    ;ALWAYS
*
:NOTCOMA
            CMP   #$BD        ;"="
            BNE   :NOTEQL
            LDA   LINLIM
            CMP   #$24
            BNE   :NOTLEGL
            LDA   #$BD        ;"="
            BNE   :ISLEGAL    ;ALWAYS
*
:NOTEQL     BIT   DOSNOW
            BMI   :PRODOS
            CPX   #0          ;1ST CHAR?
            BEQ   :NOTLEGL    ;YES
            BNE   :ISLEGAL
*
:PRODOS     CPX   #0
            BNE   :NOT1ST
            CMP   #"/"
            BEQ   :ISLEGAL
:NOTLEGL    SEC
            RTS
*
:NOT1ST     CPX   #1
            BNE   :NOT2ND
            STA   :TEMP
            LDA   LINEIN
            CMP   #"/"
            BEQ   :NOTLEGL
            LDA   :TEMP
:NOT2ND     CMP   #"."
            BEQ   :ISLEGAL
            CMP   #$B0
            BCC   :CKLEG2
            CMP   #$BA
            BCC   :ISLEGAL    ;DIGIT
:CKLEG2     CMP   #"/"
            BNE   :NOTLEGL
            LDA   LINLIM
            CMP   #$40
            BNE   :NOTLEGL
            DEX
            LDA   LINEIN,X
            INX
            CMP   #"/"
            BEQ   :NOTLEGL    ;TWO /'S
            LDA   #"/"
            BNE   :ISLEGAL    ;ALWAYS
:TEMP       DB    $0
*

