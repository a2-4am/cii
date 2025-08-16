*
* ZX0 turbo data decompressor for Apple II
* (c) 2024-5 by qkumba, ported to Merlin by 4am
*
* This version assumes and requires that src<dst
* and data has been packed backwards using -b flag.
* See below for example.
*
* More on ZX0 format: https://github.com/einar-saukas/ZX0
*
            DUM   $F0
ZXSRC       DS    2
ZXDST       DS    2
:OFFSET     DS    2
:HL         DS    2
:TMPA       DS    1
:TMPB       DS    1
:SAVEACC    DS    1
            DEND
*label in VARS
*ZXMODULE
            STA   :SAVEACC
            SEC
            PLA
            SBC   #2
            STA   :TMPA
            PLA
            SBC   #0
            STA   :TMPB
            LDY   #3
]PARMLOOP
            LDA   (:TMPA), Y
            STA   ZXSRC-3, Y
            INY
            CPY   #7
            BNE   ]PARMLOOP
            DEY
]B7LOOP
            LDA   (ZXSRC), Y
            STA   (:TMPA), Y
            DEY
            BPL   ]B7LOOP
            JSR   ZXUNPACK
            LDY   #2
            LDA   #$EA
]NOPLOOP
            STA   (ZXSRC),Y
            DEY
            BPL   ]NOPLOOP
            LDA   :SAVEACC
            JMP   (ZXSRC)
            ERR   *-ZXMODULE-ZXMODSZ
*
* ZXUNPACK - entry point for ZX0 turbo unpacker
* in:  ZXSRC [2 bytes] address following packed data
*      ZXDST [2 bytes] address following unpacked data
* out: all registers and flags clobbered
*
* In most cases you will be using PUTBIN to include the
* packed data, so just put a label immediately after that
* and use that label address as src. You will need to
* calculate dst yourself so the unpacked data ends up
* starting at the correct address. ZX0 has no way to
* calculate this for you, and the packed data does not
* include any addresses (unlike some other formats).
*
* Example: if packed data is in 0804..0F75 and you want it
* unpacked into 0800..1FFF, then ZXSRC=0F76 and ZXDST=2000.
* Note the packed and unpacked regions overlap almost
* entirely, which is fine because this unpacker works
* backwards. There only needs to be a small offset between
* the first byte of the packed data and the first byte of
* the unpacked data. This varies but is usually single-
* digit bytes. The ZX0 packer will tell you how much offset
* is required. (In the example above, the offset is 4 bytes
* because 800+4=804).
*
*label in VARS
*ZXUNPACK
            LDX   #0
            STX   :TMPB
            STX   :OFFSET+1
            INX
            STX   :OFFSET
            LDA   #$80
            STA   :TMPA
            LDY   #0
            BEQ   :DZX0T_LITERALS  ; ALWAYS
:DEC1_SRC
            DEC   ZXSRC+1
            BNE   :BRANCH2    ; ALWAYS
:INC1_OFFSET
            INC   :OFFSET+1
            BNE   :BRANCH3    ; ALWAYS
:INC_TMPB
            INC   :TMPB
            BNE   :DZX0T_COPY  ; ALWAYS
:DEC_HL
            DEC   :HL+1
            BNE   :BRANCH4    ; ALWAYS
:DEC1_DST
            DEC   ZXDST+1
            BNE   :BRANCH5    ; ALWAYS
:DEC1_TMPB
            DEC   :TMPB
            DEX
            BNE   :COP1       ; ALWAYS
:EXIT
            RTS
:DZX0T_NEW_OFFSET
            ASL   :TMPA
            BCC   :SKIP_ELIAS
            JSR   :DZX0T_ELIAS
:SKIP_ELIAS
            DEC   :TMPB
            BEQ   :EXIT
            DEX
            TXA
            LSR
            STA   :OFFSET+1
            LDA   ZXSRC
            BEQ   :DEC1_SRC
:BRANCH2
            DEC   ZXSRC
            LDA   (ZXSRC),Y
            ROR
            STA   :OFFSET
            INC   :OFFSET
            BEQ   :INC1_OFFSET
:BRANCH3
            LDX   #0
            STX   :TMPB
            INX
            BCC   :SKIP_LOOP
            JSR   :DZX0T_ELIAS_LOOP
:SKIP_LOOP
            INX
            BEQ   :INC_TMPB
:DZX0T_COPY
            LDA   ZXDST
            ADC   :OFFSET     ; C=0 FROM GET_ELIAS
            STA   :HL
            LDA   ZXDST+1
            ADC   :OFFSET+1
            STA   :HL+1
:COP1
            LDA   :HL
            BEQ   :DEC_HL
:BRANCH4
            DEC   :HL
            LDA   (:HL),Y
            LDY   ZXDST
            BEQ   :DEC1_DST
:BRANCH5
            DEC   ZXDST
            LDY   #0
            STA   (ZXDST),Y
            TXA
            BEQ   :DEC1_TMPB
            DEX
            BNE   :COP1
            LDA   :TMPB
            BNE   :COP1
            INX
            ASL   :TMPA
:LINK_NEW_OFFSET
            BCS   :DZX0T_NEW_OFFSET
:DZX0T_LITERALS
            ASL   :TMPA
            BCC   :COP0
            JSR   :DZX0T_ELIAS
:COP0
            LDA   ZXSRC
            BEQ   :DEC2_SRC
]LOOP1
            DEC   ZXSRC
            LDA   (ZXSRC),Y
            LDY   ZXDST
            BEQ   :DEC2_DST
]LOOP2
            DEC   ZXDST
            LDY   #0
            STA   (ZXDST),Y
            TXA
            BEQ   :DEC2_TMPB
            DEX
            BNE   :COP0
            LDA   :TMPB
            BNE   :COP0
            INX
            ASL   :TMPA
            BCS   :LINK_NEW_OFFSET
            ASL   :TMPA
            BCC   :DZX0T_COPY
            JSR   :DZX0T_ELIAS
            BCC   :DZX0T_COPY  ; ALWAYS
:DEC2_SRC
            DEC   ZXSRC+1
            BNE   ]LOOP1      ; ALWAYS
:DEC2_DST
            DEC   ZXDST+1
            BNE   ]LOOP2      ; ALWAYS
:DEC2_TMPB
            DEC   :TMPB
            DEX
            BNE   :COP0       ; ALWAYS
:DZX0T_ELIAS_LOOP
            ASL   :TMPA
            TXA
            ROL
            TAX
            ASL   :TMPA
            BCS   :DZX0T_ELIAS
            RTS
:DEC3_SRC
            DEC   ZXSRC+1
            BNE   :UNROLL0    ; ALWAYS
:DZX0T_ELIAS
            BNE   :DZX0T_ELIAS_LOOP
            LDA   ZXSRC
            BEQ   :DEC3_SRC
:UNROLL0
            DEC   ZXSRC
            LDA   (ZXSRC),Y
            ROL
            BCS   :UNROLL1
            STA   :TMPA
            RTS
:UNROLL1
            ASL
            STA   :TMPA
            TXA
            ROL
            ASL   :TMPA
            BCS   :UNROLL2
            TAX
            RTS
:UNROLL2
            ASL   :TMPA
            ROL
            ASL   :TMPA
            BCS   :UNROLL3
            TAX
            RTS
:UNROLL3
            ASL   :TMPA
            ROL
            ASL   :TMPA
            BCS   :DZX0T_ELIAS_RELOAD
            TAX
            RTS
:DEC4_SRC
            DEC   ZXSRC+1
            BNE   :UNROLL4    ; ALWAYS
:DZX0T_ELIAS_RELOAD
            ASL   :TMPA
            ROL
            TAX
            ROL   :TMPB
            ASL   :TMPA
            LDA   ZXSRC
            BEQ   :DEC4_SRC
:UNROLL4
            DEC   ZXSRC
            LDA   (ZXSRC),Y
            ROL
            BCS   :UNROLL5
            STA   :TMPA
            RTS
:UNROLL5
            ASL
            STA   :TMPA
            TXA
            ROL
            ROL   :TMPB
            ASL   :TMPA
            BCS   :UNROLL6
            TAX
            RTS
:UNROLL6
            ASL   :TMPA
            ROL
            TAX
            ROL   :TMPB
            ASL   :TMPA
            BCS   :UNROLL7
            TAX
            RTS
:UNROLL7
            ASL   :TMPA
            ROL
            ROL   :TMPB
            ASL   :TMPA
            BCS   :DZX0T_ELIAS_RELOAD
            TAX
            RTS
            ERR   *-ZXUNPACK-ZXUNPSZ
