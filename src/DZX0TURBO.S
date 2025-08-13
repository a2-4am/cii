* ZX0 data decompressor for Apple II
* (c) 2024-5 by qkumba, ported to Merlin by 4am
*
* This version assumes and requires that src<dst
* and data has been packed backwards using -b flag.
* See below for example.
*
* More on ZX0 format: https://github.com/einar-saukas/ZX0
*
            TYP   $06
            DSK   ../build/DZX0TURBO.O

            DUM   $F0
ZXSRC       DS    2
ZXDST       DS    2
:OFFSET     DS    2
:HL         DS    2
:TMPA       DS    1
:TMPB       DS    1
            DEND
*
*
* ZXUNPACK - entry point for ZX0 unpacker
* in: ZXSRC -> address following packed data
*     ZXDST -> address following unpacked data
* out: all flags and registers clobbered
*
* In most cases you will be using PUTBIN to include the
* packed data, so just put a label immediately after that
* and copy that label address to ZXSRC. You will need to
* calculate ZXDST yourself so the unpacked data ends up
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
ZXUNPACK
            LDX   #0
            STX   :TMPB
            STX   :OFFSET+1
            INX
            STX   :OFFSET
            LDA   #$80
            STA   :TMPA
            LDY   #0
            BEQ   :LITERALS ; ALWAYS

:DEC1_SRC
            DEC   ZXSRC+1
            BNE   :NEW1_SRC ; ALWAYS

:INC1_OFFSET
            INC   :OFFSET+1
            BNE   :NEW1_OFFSET ; ALWAYS

:INC_TMPB
            INC   :TMPB
            BNE   :COPY ; ALWAYS

:DEC_HL
            DEC   :HL+1
            BNE   :COP1A ; ALWAYS

:DEC1_DST
            DEC   ZXDST+1
            BNE   :COP1B ; ALWAYS

:DEC1_TMPB
            DEC   :TMPB
            BNE   :COP1C ; ALWAYS

:EXIT
            RTS

:NEW_OFFSET
            ASL   :TMPA
            BCC   :SKIPELIAS
            JSR   :ELIAS
:SKIPELIAS
            DEC   :TMPB
            BEQ   :EXIT
            DEX
            TXA
            LSR
            STA   :OFFSET+1
            LDA   ZXSRC
            BEQ   :DEC1_SRC
:NEW1_SRC
            DEC   ZXSRC
            LDA   (ZXSRC),Y
            ROR
            STA   :OFFSET
            INC   :OFFSET
            BEQ   :INC1_OFFSET
:NEW1_OFFSET
            LDX   #0
            STX   :TMPB
            INX
            BCC   :SKIPLOOP
            JSR   :ELIAS_LOOP
:SKIPLOOP
            INX
            BEQ   :INC_TMPB

:COPY
            LDA   ZXDST
            ADC   :OFFSET  ; C=0 FROM GET_ELIAS
            STA   :HL
            LDA   ZXDST+1
            ADC   :OFFSET+1
            STA   :HL+1
:COP1
            LDA   :HL
            BEQ   :DEC_HL
:COP1A
            DEC   :HL
            LDA   (:HL),Y
            LDY   ZXDST
            BEQ   :DEC1_DST
:COP1B
            DEC   ZXDST
            LDY   #0
            STA   (ZXDST),Y
            TXA
            BEQ   :DEC1_TMPB
:COP1C
            DEX
            TXA
            ORA   :TMPB
            BNE   :COP1
            INX
            ASL   :TMPA
            BCS   :NEW_OFFSET

:LITERALS
            ASL   :TMPA
            BCC   :COP0
            JSR   :ELIAS
:COP0
            LDA   ZXSRC
            BEQ   :DEC2_SRC
:COP0A
            DEC   ZXSRC
            LDA   (ZXSRC),Y
            LDY   ZXDST
            BEQ   :DEC2_DST
:COP0B
            DEC   ZXDST
            LDY   #0
            STA   (ZXDST),Y
            TXA
            BEQ   :DEC2_TMPB
:COP0C
            DEX
            TXA
            ORA   :TMPB
            BNE   :COP0
            INX
            ASL   :TMPA
            BCS   :NEW_OFFSET
            ASL   :TMPA
            BCC   :COPY
            JSR   :ELIAS
            BCC   :COPY ; ALWAYS

:DEC2_SRC
            DEC   ZXSRC+1
            BNE   :COP0A ; ALWAYS

:DEC2_DST
            DEC   ZXDST+1
            BNE   :COP0B ; ALWAYS

:DEC2_TMPB
            DEC   :TMPB
            BNE   :COP0C ; ALWAYS

:ELIAS_LOOP
            ASL   :TMPA
            TXA
            ROL
            TAX
            ASL   :TMPA
            BCS   :ELIAS
            RTS

:ELIAS
            BNE   :ELIAS_LOOP
            LDA   ZXSRC
            BEQ   :DEC3_SRC
:ELIAS1
            DEC   ZXSRC
            LDA   (ZXSRC),Y
            ROL
            STA   :TMPA
            BCS   :ELIAS2
            RTS
:DEC3_SRC
            DEC   ZXSRC+1
            BNE   :ELIAS1 ; ALWAYS

:ELIAS2
            ASL   :TMPA
            TXA
            ROL
            TAX
            ASL   :TMPA
            BCS   :ELIAS3
            RTS
:ELIAS3
            ASL   :TMPA
            TXA
            ROL
            TAX
            ASL   :TMPA
            BCS   :ELIAS4
            RTS
:ELIAS4
            ASL   :TMPA
            TXA
            ROL
            TAX
            ASL   :TMPA
            BCS   :ELIAS_RELOAD
            RTS
:ELIAS_RELOAD
            ASL   :TMPA
            TXA
            ROL
            TAX
            ROL   :TMPB
            ASL   :TMPA
            LDA   ZXSRC
            BEQ   :DEC4_SRC
:ELIAS5
            DEC   ZXSRC
            LDA   (ZXSRC),Y
            ROL
            STA   :TMPA
            BCS   :ELIAS6
            RTS
:DEC4_SRC
            DEC   ZXSRC+1
            BNE   :ELIAS5 ; ALWAYS

:ELIAS6
            ASL   :TMPA
            TXA
            ROL
            TAX
            ROL   :TMPB
            ASL   :TMPA
            BCS   :ELIAS7
            RTS
:ELIAS7
            ASL   :TMPA
            TXA
            ROL
            TAX
            ROL   :TMPB
            ASL   :TMPA
            BCS   :ELIAS8
            RTS
:ELIAS8
            ASL   :TMPA
            TXA
            ROL
            TAX
            ROL   :TMPB
            ASL   :TMPA
            BCS   :ELIAS_RELOAD
            RTS
