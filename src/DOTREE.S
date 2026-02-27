            TYP   BIN
            DSK   ../build/DOTREE.O
            PUT   VARS
            PUT   ../build/PHRWTS.VARS
            PUT   ../build/PRODOS.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/UILIB.VARS
            PUT   ../build/DISKLIB.VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/DODEV.VARS
            ORG   DODEVEND
DOTREE      
            ORG   *+3
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
            PHA
            LDY   FLAG80      ;FF OR 0
            INY
            LDA   :CHMAX,Y
            STA   CHMAX
            LDA   :DSPNUM,Y
            STA   DSPNUM
            LDA   UNIT
            JSR   SETSD
            >>>   JSRMODULE,PHRWTSLIB;UNTPFX
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
            JSR   :MKTREE
:FAKERR     PLA
            PHP
            STA   CURR
            LDA   #0
            STA   POINT
            STA   XPOS
            STA   YPOS
            STA   XSTART
            STA   YSTART
*
* Previously this checked if we were called while doing
* a catalog and switched to 80-column mode if available.
* Now only some catalogs are displayed in 80-column mode,
* others in 40-column. We don't want to switch to 80-column
* unconditionally here, because if (1) we don't need to
* display a directory tree and (2) the catalog type won't
* need 80-column mode, then then we can skip the switch
* altogether.
*            LDX   CHOICE
*            CPX   #1
*            BNE   :DOT1       ;NOT CATALOG
*            JSR   :HDR80
*:DOT1
            PLP
            LDA   #0
            BCS   :ERR
            LDA   CURMOM
            EOR   #1
            BEQ   :ONLY1
*
* There's a directory tree to display, so get in
* 80-column mode if available. Previously this had to
* work around the earlier logic.
*            LDX   CHOICE
*            CPX   #1
*            BEQ   :DOT2
            JSR   :HDR80
*:DOT2
            LDA   CURR        ;IS CURR LARGER
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
:CAGN       JSR   :CTREE
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
:HDR80      JSR   COL80
            JMP   COMH00
*
:ERRFLG     DB    $0
:TEMP       DB    $0
:CHMAX      DB    $4F,$27
:DSPNUM     DB    $03,$01
:KEYS       DB    $88,$95,$8B,$8A,$C1,$DA
*
*
*
:CTREE      LDA   #>SDNAME
            STA   POINT2+1
            LDY   #0
            STY   POINT2
            STY   :CURR
:TREELP     LDA   XS,Y
            SEC
            SBC   XSTART
            BCC   :GOSKIP
            CMP   DSPNUM
            BEQ   :TREELP0
            BCS   :GOSKIP
:TREELP0    STA   :CHINDX
            TAX
            LDA   :CH,X
            STA   CH
            LDA   YS,Y
            SEC
            SBC   YSTART
            BCC   :GOSKIP
            CMP   #$09
            BCC   :NOSKIP0
:GOSKIP     JMP   :SKIP
*
:NOSKIP0    ASL
            CLC
            ADC   #4
            JSR   TABV
            CPY   #0
            BEQ   :SPCS
*
            LDA   #"-"
            LDX   PREV,Y
            CPX   #$FF
            BEQ   :NOPRE1
            LDA   #"!"
:NOPRE1     PHA
            LDY   :CURR
            LDA   SIS,Y
            CMP   #$FF
            BEQ   :NOPRE2
            LDA   #$8A
            JSR   PCOUT
            LDA   #"!"
            JSR   PCOUT
            LDA   #$88
            JSR   PCOUT
            DEC   CV
            JSR   $FC22
:NOPRE2     PLA
            JSR   PCOUT
            LDA   #"-"
            JSR   PCOUT
            LDA   #">"
            BNE   :NOARO
*
:SPCS       LDA   #" "
            JSR   PCOUT
            JSR   PCOUT
:NOARO      JSR   PCOUT
            LDA   YS,Y
            CMP   YPOS
            BNE   :NOTINVS
            LDA   XS,Y
            CMP   XPOS
            BNE   :NOTINVS
            LDY   #$C0        ;INVERSE
            STY   PINVFL
:NOTINVS    LDY   #0
            LDA   (POINT2),Y
            STA   :LEN
:CLP        INY
            LDA   (POINT2),Y
            ORA   #$80
            JSR   PCOUT
            CPY   :LEN
            BCC   :CLP
            STY   :LEN
            LDY   #0          ;NORMAL
            STY   PINVFL
            LDY   :CURR
            LDA   KITTEN,Y
            CMP   #$FF
            BEQ   :SKIP
            LDY   :LEN
:DASHLP     LDA   #"-"
            JSR   PCOUT
            LDA   CH
            CMP   CHMAX
            BCS   :SKIP
            INY
            CPY   #$11
            BCC   :DASHLP
            LDA   #">"
            JSR   PCOUT
*
:SKIP       JSR   INCPT2
            INC   :CURR
            LDY   :CURR
            CPY   END
            BCS   :FIN
            JMP   :TREELP
*
:FIN        LDX   #5
:FIN0       LDA   :CHL,X
            TAY
            LDA   #$15
            STA   CV
:FIN1       JSR   $FC22
            LDA   (BASL),Y
            CMP   #"!"
            BEQ   :FIN2A
:FIN1A      DEC   CV
            LDA   CV
            CMP   #4
            BCS   :FIN1
:FIN2       DEX
            BPL   :FIN0
:OUT        RTS
*
:FIN2A      INY
            LDA   (BASL),Y
            DEY
            CMP   #" "
            BNE   :FIN3
            LDA   CV
            PHA
:FIN2B      INC   CV
            JSR   $FC22
            LDA   CV
            CMP   #$16
            BCS   :FIN2C
            LDA   #"!"
            STA   (BASL),Y
            BNE   :FIN2B      ;ALWAYS
*
:FIN2C      PLA
            STA   CV

:FIN3       DEC   CV
            LDA   CV
            CMP   #4
            BCC   :FIN2
            JSR   $FC22
            LDA   (BASL),Y
            CMP   #"-"
            BEQ   :FIN1A
            LDA   #"!"
            STA   (BASL),Y
            BNE   :FIN3       ;ALWAYS

:LEN        DB    $0
:CURR       DB    $0
:CH         DB    $1,$13,$25,$37
:CHINDX     DB    $0
:TEMP       DB    $0
:CHL        DB    $0,$1,$9,$12,$13,$1B
*
*
:MKTREE      LDA   #>FILBUF
            STA   RPAGE
            LDA   #>SDNAME
            STA   POINT2+1
            LDY   #$FF
            STY   CURMOM
            INY
            STY   YCUR
            STY   CURR
            STY   BLKNUM+1
            STY   SDBLKH
            STY   POINT2
            STY   XS
            STY   XCUR
            INY
            INY
            STY   BLKNUM
            STY   SDBLKL
:SBDR00     LDA   #0
            STA   SISPTR
:SBDR0      JSR   RDBLK
            BCC   :SBDR01
            RTS               ;READ ERR
:SBDR01     LDA   RPAGE
            STA   POINT+1
            LDA   FILBUF+2
            STA   BLKNUM
            LDA   FILBUF+3
            STA   BLKNUM+1
            LDA   #4
            STA   POINT
:SBDR1      LDY   #0
            LDX   CURR
            BEQ   :ISROOT
            LDA   (POINT),Y
            AND   #$F0
            CMP   #$D0
            BNE   :NOTDIR
            LDY   #$11
            LDA   (POINT),Y
            STA   SDBLKL,X
            INY
            LDA   (POINT),Y
            STA   SDBLKH,X
:ISROOT     LDA   #0
            STA   SDBLKL+$1,X
            STA   SDBLKH+$1,X
            LDA   CURMOM
            STA   MOM,X
            LDA   #$FF
            STA   KITTEN,X
            STA   SIS,X
            STA   PREV,X
            LDA   SISPTR
            BEQ   :SBDR2
            LDA   CURR
            STA   SIS-1,X
            SEC
            SBC   #1
            STA   PREV,X
:SBDR2      INC   SISPTR
*
* MOVE NAME INTO SDNAME
*
            LDY   #$0F
:MVNAME     LDA   (POINT),Y
            STA   (POINT2),Y
            DEY
            BNE   :MVNAME
            LDA   (POINT),Y
            AND   #$0F
            STA   (POINT2),Y
            JSR   INCPT2
*
            INC   CURR
            BEQ   :DONE       ;3/29/86
            LDA   CURR
            CMP   #1
            BEQ   :DIRDNE
:NOTDIR     LDA   POINT
            CLC
            ADC   #$27
            STA   POINT
:GOSBDR1    BCC   :SBDR1
            INC   POINT+1
            LDA   POINT+1
            CMP   #$0E        ;<--
            BCC   :GOSBDR1
            LDA   BLKNUM
            ORA   BLKNUM+1
            BEQ   :DIRDNE
            JMP   :SBDR0
*
* DONE WITH CURRENT SUBDIR
*
:DIRDNE     INC   CURMOM
            LDX   CURMOM
            LDA   SDBLKL,X
            STA   BLKNUM
            LDA   SDBLKH,X
            STA   BLKNUM+1
            ORA   BLKNUM
            BEQ   :DONE
            LDA   CURR
            STA   KITTEN,X
            CMP   KITTEN-1,X
            BNE   :DIRDN1
            LDA   #$FF
            STA   KITTEN-1,X
:DIRDN1     JMP   :SBDR00
*
:DONE       LDA   #$FF
            STA   KITTEN-1,X
            STX   END
            LDA   #0
            STA   CURR
            STA   YS
:TREE0      LDY   CURR
            LDA   KITTEN,Y
            CMP   #$FF
            BEQ   :NODAUG
            INC   XCUR
            LDX   XCUR
            STX   XMAX
            JMP   :TREE1
*
:NOSIS      LDA   MOM,Y
            CMP   #$FF
            BEQ   :ATROOT
            DEC   XCUR
            STA   CURR
            TAY
:NODAUG     LDA   SIS,Y
            CMP   #$FF
            BEQ   :NOSIS
            INC   YCUR
:TREE1      STA   CURR
            TAY
            LDA   XCUR
            STA   XS,Y
            LDA   YCUR
            STA   YS,Y
            JMP   :TREE0
*
:ATROOT     CLC
            RTS
*
INCPT2      EQU   *
            LDA   POINT2
            CLC
            ADC   #$10
            STA   POINT2
            BCC   IP3
            INC   POINT2+1
IP3         RTS
*
DOTREEEND
