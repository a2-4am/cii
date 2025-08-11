* ZX0 data decompressor for Apple II
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
:OFF        DS    2
:HL         DS    2
:TMPA       DS    1
:TMPB       DS    1
            DEND
*
ZGETBYTE    MAC
            LDA   ZXSRC
            BNE   *+4
            DEC   ZXSRC+1
            DEC   ZXSRC
            LDA   (ZXSRC),Y
            <<<
*
ZPUTBYTE    MAC
            LDY   ZXDST
            BNE   *+4
            DEC   ZXDST+1
            DEC   ZXDST
            LDY   #0
            STA   (ZXDST),Y
            <<<
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
ZXUNPACK    LDX   #0
            STX   :TMPA
            STX   :TMPB
            STX   :OFF+1
            INX
            STX   :OFF
            LDY   #0
:LITERALS   JSR   :ELIAS
:COP0       ZGETBYTE
            ZPUTBYTE
            JSR   :DECBC
            BNE   :COP0
            INX
            ASL   :TMPA
            BCS   :NEWOFF
            JSR   :ELIAS
:COPY       LDA   ZXDST
            ADC   :OFF        ; C=0 FROM :ELIAS
            STA   :HL
            LDA   ZXDST+1
            ADC   :OFF+1
            STA   :HL+1
:COP1       LDA   :HL
            BNE   :NODEC1
            DEC   :HL+1
:NODEC1     DEC   :HL
            LDA   (:HL),Y
            ZPUTBYTE
            JSR   :DECBC
            BNE   :COP1
            INX
            ASL   :TMPA
            BCC   :LITERALS
:NEWOFF     JSR   :ELIAS
            DEC   :TMPB
            BEQ   :EXIT
            DEX
            TXA
            LSR
            STA   :OFF+1
            ZGETBYTE
            ROR
            STA   :OFF
            INC   :OFF
            BNE   :NODEC2
            INC   :OFF+1
:NODEC2     LDX   #0
            STX   :TMPB
            INX
            BCC   :NOBACK
            JSR   :BACKTRK
:NOBACK     INX
            BNE   :COPY
            INC   :TMPB
            BNE   :COPY       ;ALWAYS
*
:BACKTRK    ASL   :TMPA
            TXA
            ROL
            TAX
            ROL   :TMPB
:ELIAS      ASL   :TMPA
            BNE   :NOELIAS
            ZGETBYTE
            SEC
            ROL
            STA   :TMPA
:NOELIAS    BCS   :BACKTRK
            RTS
:DECBC      TXA
            BNE   :NODEC3
            DEC   :TMPB
:NODEC3     DEX
            TXA
            ORA   :TMPB
:EXIT       RTS
