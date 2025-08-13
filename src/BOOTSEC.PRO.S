            DUM   *
PBOOT       DB    0           ;Marker to copy ProDOS boot sector
            DEND
PROBEG      ORG   $800
*
            DB    $01
            SEC
            BCS   :APPLE2
            JMP   $A132       ;APPLE ///
*
:APPLE2     STX   $43
            CMP   #3
            PHP
            TXA
            AND   #$70
            LSR
            LSR
            LSR
            LSR
            ORA   #$C0
            STA   $49
            LDY   #$FF
            STY   $48
            PLP
            INY
            LDA   ($48),Y     ;INTELL. CONT?
            BNE   :INTELL
            BCS   :NOMORE
            LDA   #3
            STA   $800
            INC   $3D
            LDA   $49
            PHA
            LDA   #$5B
            PHA
            RTS
*
:NOMORE     STA   $40
            STA   $48
            LDY   #$63
:MOVEROM    LDA   ($48),Y
            STA   $994,Y
            INY
            CPY   #$EB
            BNE   :MOVEROM
            LDX   #6
:MODCODE    LDY   :MODS1,X
            LDA   :MODS2,X
            STA   $9F2,Y
            LDA   :MODS3,X
            STA   $A7F,X
            DEX
            BPL   :MODCODE
            LDA   #>:READ
            STA   $49
            LDA   #:READ
:INTELL     LDY   #0
            CMP   #$F9
            BCS   :GOBAD
            STA   $48
            STY   $60
            STY   $4A
            STY   $4C
            STY   $4E
            STY   $47         ;BLK HI
            INY
            STY   $42         ;1 = READ CMD
            INY
            STY   $46         ;BLOCK 2
            LDA   #$0C
            STA   $61
            STA   $4B
:RDAGN      JSR   :RDBLK
            BCS   :GOBAD1
            INC   $61
            INC   $61
            INC   $46
            LDA   $46
            CMP   #6
            BCC   :RDAGN
            LDA   $C00
            ORA   $C01
:GOBAD      BNE   :BAD
            LDA   #4
            BNE   :FIRST
:NXTFILE    LDA   $4A
:FIRST      CLC
            ADC   $C23
            TAY
            BCC   :SAMEPG
            INC   $4B
            LDA   $4B
            LSR
            BCS   :SAMEPG
            CMP   #$0A
            BEQ   :BAD
            LDY   #4
:SAMEPG     STY   $4A
            LDA   :NAME
            AND   #$0F
            TAY
:NXTCHR     LDA   ($4A),Y
            CMP   :NAME,Y
            BNE   :NXTFILE
            DEY
            BPL   :NXTCHR
            AND   #$F0
            CMP   #$20
            BNE   :BAD
            LDY   #$10
            LDA   ($4A),Y
            CMP   #$FF
            BNE   :BAD
            INY
            LDA   ($4A),Y
            STA   $46
            INY
            LDA   ($4A),Y
            STA   $47
            LDA   #0
            STA   $4A
            LDY   #$1E
            STY   $4B
            STY   $61
            INY
            STY   $4D
:RDAGN1     JSR   :RDBLK
:GOBAD1     BCS   :BAD
            INC   $61
            INC   $61
            LDY   $4E
            INC   $4E
            LDA   ($4A),Y
            STA   $46
            LDA   ($4C),Y
            STA   $47
            ORA   ($4A),Y
            BNE   :RDAGN1
            JMP   $2000
:BAD        JMP   :NOLOAD
:NAME       DB    $26
            ASC   'PRODOS         '
:RDBLK      LDA   $60
            STA   $44
            LDA   $61
            STA   $45
            JMP   ($0048)
*
:MODS1      DB    $08,$1E,$24,$3F,$45,$47,$76
:MODS2      DB    $F4,$D7,$D1,$B6,$4B,$B4,$AC
:MODS3      LDX   $2B
            CLC
            RTS
            JMP   $9BC
*
:APPLE3     LDA   #$9F
            PHA
            LDA   #$FF
            PHA
            LDA   #1
            LDX   #0
            JMP   $F479
*
:NOLOAD     JSR   $FC58
            LDY   #$1C
:NOLOOP     LDA   :NOMSG,Y
            STA   $5AE,Y
            DEY
            BPL   :NOLOOP
:HANG       JMP   :HANG
:NOMSG      ASC   "*** UNABLE TO LOAD PRODOS ***"
*
:PHASE      LDA   $53
:PHASE1     AND   #3
            ROL
            ORA   $2B
            TAX
            LDA   $C080,X
            LDA   #$2C
:WAIT1      LDX   #$11
:WAIT2      DEX
            BNE   :WAIT2
            SBC   #1
            BNE   :WAIT1
            LDX   $2B
            RTS
*
:READ       LDA   $46
            AND   #7
            CMP   #4
            AND   #3
            PHP
            ASL
            PLP
            ROL
            STA   $3D
            LDA   $47
            LSR
            LDA   $46
            ROR
            LSR
            LSR
            STA   $41
            ASL
            STA   $51
            LDA   $45
            STA   $27
            LDX   $2B
            LDA   $C089,X
            JSR   :RDSEC
            INC   $27
            INC   $3D
            INC   $3D
            BCS   :SKIP
            JSR   :RDSEC
:SKIP       LDY   $C088,X
:OUT        RTS
*
:RDSEC      LDA   $40
            ASL
            STA   $53
            LDA   #0
            STA   $54
:STEPAGN    LDA   $53
            STA   $50
            SEC
            SBC   $51
            BEQ   :STEPDON
            BCS   :STEP1
            INC   $53
            BCC   :STEP2
:STEP1      DEC   $53
:STEP2      SEC
            JSR   :PHASE
            LDA   $50
            CLC
            JSR   :PHASE1
            BNE   :STEPAGN
:STEPDON    LDY   #$7F
            STY   $52
            PHP
:WAITAGN    PLP
            SEC
            DEC   $52
            BEQ   :OUT
            CLC
            PHP
            DEY
            BEQ   :WAITAGN
:RDWAIT     LDA   $C08C,X
            BPL   :RDWAIT
            DB    $0,$0,$0,$0,$0,$0,$0,$0,$0
*
            ORG

