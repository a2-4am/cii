*
* DOTREE
*
* INPUT:
* A = VALUE FOR *CURR
* (PFXADR) = OLD PREFIX
*
* OUTPUT:
* C = 1: I/O ERROR
*
* C=0:
*        A = SELECTION
* (PFXADR) = NEW PREFIX
*      PFX = NEW PREFIX
* DIRBLK,+1= BLK # OF SUBDIR
*
* CALLS SETPFX AND SETSD
*
*
*
DOTREE      PHA
            LDY   FLAG80      ;FF OR 0
            INY
            LDA   :CHMAX,Y
            STA   CHMAX
            LDA   :DSPNUM,Y
            STA   DSPNUM
            LDA   UNIT
            JSR   SETSD
            JSR   UNTPFX
            BIT   DOSNOW
            BMI   :DOTREE0
            LDY   #5
            LDA   PFX+5
            STA   (PFXADR),Y
            LDY   #0
            LDA   PFX
            STA   (PFXADR),Y
            SEC
            BCS   :FAKERR     ;ALWAYS
*
:DOTREE0    LDA   RRTN
            CMP   #$52
            BEQ   :FAKERR     ;C IS SET
            JSR   MKTREE
:FAKERR     PLA
            PHP
            STA   CURR
            LDA   #0
            STA   POINT
            STA   XPOS
            STA   YPOS
            STA   XSTART
            STA   YSTART
            LDX   CHOICE
            CPX   #1
            BNE   :DOT1       ;NOT CATALOG
            JSR   :HDR80
:DOT1       PLP
            LDA   #0
            BCS   :ERR
            LDA   CURMOM
            EOR   #1
            BEQ   :ONLY1
            LDX   CHOICE
            CPX   #1
            BEQ   :DOT2
            JSR   :HDR80
:DOT2       LDA   CURR        ;IS CURR LARGER
            CMP   CURMOM      ; THAN CURMOM?
            BCC   :DOT3       ;NO
:ZERCUR     LDA   #0          ;YES, ZERO CURR
            BEQ   :DOT4       ;ALWAYS
*
* CURR VALUE IS VALID, NOW CHECK
* IF PREFIX GENERATED FROM CURR IS
* SAME AS OLD PREFIX. IF NOT, SET CURR
* TO ZERO.
*
:DOT3       JSR   :MKPFX
            LDY   #0
            LDA   (PFXADR),Y
            AND   #$7F
            CMP   PFX
            BNE   :ZERCUR     ;LENS DIFFER
:CMPLOOP    INY
            LDA   (PFXADR),Y
            CMP   PFX,Y
            BNE   :ZERCUR
            CPY   PFX
            BCC   :CMPLOOP
            LDA   CURR
:DOT4       JMP   :COM00
*
*
:ONLY1      STA   CURR
            JSR   :MKPFX
*
:CHOOSE     JSR   SETPFX
            BCS   :ERR
            LDY   #$3F
:CHSLOOP    LDA   PFX,Y
            STA   (PFXADR),Y
            DEY
            BPL   :CHSLOOP
            LDX   CURR
            LDA   SDBLKL,X
            STA   DIRBLK
            LDA   SDBLKH,X
            STA   DIRBLK+1
            TXA
:ERR        PHP
            PHA
            LDA   CHOICE
            CMP   #1          ;CATALOG?
            BEQ   :SKIP40     ;YES
            JSR   COL40
:SKIP40     JSR   HOME
            PLA
            PLP
            RTS
*
*
*
:CAGN0      CPX   #0
            BEQ   :CAGN
            JSR   HOME
:CAGN       JSR   CTREE
            LDA   #$17
            JSR   VLEFT
            LDA   SDCH
            SEC
            SBC   #$19
            LSR
            JSR   SETCH
            JSR   PRHERE
            ASC   "Use arrows,A,Z and [Return] to select"
            DB    $0
:KEYAGN     JSR   KYESC
            CMP   #$8D
            BEQ   :CHOOSE
            LDX   #5
:KEY1       CMP   :KEYS,X
            BEQ   :GOTKEY
            DEX
            BPL   :KEY1
            BMI   :KEYAGN
*
:GOTKEY     CPX   #4
            BCC   :GOTKY1
            DEX
            DEX
:GOTKY1     TXA
            CLC
            ADC   #>MOM
            STA   POINT+1
            LDY   CURR
            LDA   (POINT),Y
            CMP   #$FF
            BEQ   :COMMON0
:COM00      STA   CURR
            PHA
            JSR   :MKPFX
            JSR   PRVNM
            PLA
            TAY
:COMMON0    LDX   #0
            LDA   XS,Y
            STA   XPOS
            SEC
            SBC   DSPNUM
            BCS   :COMX
            LDA   #0
:COMX       CMP   XSTART
            BEQ   :COMX1
            DEX
:COMX1      STA   XSTART
            LDA   YS,Y
            STA   YPOS
            SEC
            SBC   #$08
            BCS   :COMY
            LDA   #0
:COMY       CMP   YSTART
            BEQ   :COMY1
            DEX
:COMY1      STA   YSTART
            JMP   :CAGN0
*
*
*
:MKPFX      LDA   #0
            STA   :ERRFLG
*
:MK00       LDA   CURR
            STA   :TEMP
            LDX   #$3F
*
:MK0        LDA   #0
            STA   POINT2+1
            LDA   :TEMP
            LDY   #4
:MK1        ASL
            ROL   POINT2+1
            DEY
            BNE   :MK1
            STA   POINT2
            LDA   POINT2+1
            CLC
            ADC   #>SDNAME
            STA   POINT2+1
            LDA   (POINT2),Y  ;LEN
            TAY
:MK2        LDA   (POINT2),Y
            STA   PFX,X
            CPX   #0
            BEQ   :TOOLONG
            DEX
            DEY
            BPL   :MK2
            LDA   #$2F
            STA   PFX+$1,X
            LDY   :TEMP
            LDA   MOM,Y
            STA   :TEMP
            CMP   #$FF
            BNE   :MK0
:MK2A       LDY   #0
:MK3        LDA   PFX,X
            STA   PFX,Y
            INY
            INX
            CPX   #$40
            BCC   :MK3
            DEY
            STY   PFX
            LDA   :ERRFLG
            BNE   :TLERR
            RTS
*
* PREFIX TOO LONG. SET ERROR FLAG
* AND DECREMENT *CURR TO GENERATE
* A MEANINGFUL PREFIX.
*
:TOOLONG    DEC   :ERRFLG
            DEC   CURR
            JMP   :MK00
*
:TLERR      JSR   COL40
            JSR   COMH00
            LDA   #MTOOLONG
            JMP   PRTPRS
*
:HDR80
*COL80
            BIT   FLAG80
            BPL   :OUT80
            LDA   #$C3
            STA   CSWL+1
            LDA   #0
            STA   CSWL
            LDA   #$41
            STA   SDCH
            JSR   CROUT
:OUT80
            JMP   COMH00
*
:ERRFLG     DB    $0
:TEMP       DB    $0
:CHMAX      DB    $4F,$27
:DSPNUM     DB    $03,$01
:KEYS       DB    $88,$95,$8B,$8A,$C1,$DA

