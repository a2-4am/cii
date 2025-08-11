************************************
*                                  *
*    MISCELLANEOUS ROUTINES        *
*                                  *
************************************
*
*   SEE DISK INFO
*
CINFO       LDA   #$15
            JSR   VLEFT
            LDA   #$21
            STA   CH
            JSR   PRHERE
            INV   "PRINTER"
            DB    $0
            LDA   #$16
            JSR   VLEFT
            LDA   DATE
            LDX   DATE+1
            JSR   SHODAT
            LDA   #$21
            STA   CH
            LDA   PSLOT
            BEQ   :OFF
            PHA
            LDA   #$2A         ;'SLOT'
            JSR   PRINT
            PLA
            JSR   PHHEX
            JMP   CROUT
*
:OFF        JSR   PRHERE
            ASC   "  Off "
            DB    $8D,0
            RTS
*
*
*
*************************************
*       FILE ACCESS ROUTINES        *
*************************************
*
*
*
****** NEW TRACK READ/WRITE STUFF ***
*
* *DELFLG=$80 FOR ACTIVE FILES
*        =$00 FOR DELETED
*
RDACNT      BIT   DOSNOW
            BPL   :ISDOS33     ;DOS 3.3 DISK
*
* IT'S A PRODOS DISK
*
            LDA   #>SDIR
            STA   DIRADR
            LDA   #$14
            STA   COUNT
            JMP   PRDCNT

*
:ISDOS33    LDA   #>DOSDAT     ;SET UP DATADR
            STA   DATADR
            LDA   #>CAT1
            JSR   CLRCAT       ;ZERO CATALOG
            LDX   #$00
            STX   NACTIV       ;NO FILES YET
            INX
            STX   RCMND        ;READ COMMAND
            LDX   #>VTOC1
            JSR   DOVTOC       ;READ VTOC.
*
:SECTLP     LDY   #$01         ;FIND PTR TO
            LDA   (POINT),Y    ;NEXT SECTOR
            BEQ   :OUT         ;NIL PTR?
            CMP   #$28
            BCS   WDERR
            STA   RTRACK       ;NO:SAVE TRACK
            INY
            LDA   (POINT),Y    ;& SECTOR
            CMP   #$10
            BCS   WDERR
            STA   RSECTR
            INC   RPAGE        ;NEXT PAGE
            INC   POINT+1
            JSR   PHRWTS       ;READ CATALOG
            BCS   :OUT         ;BAD SECTOR?
            LDY   #$0B
:POSNLP     LDA   (POINT),Y
            BEQ   :OUT         ;NO MORE FILES?
            AND   #$80
            EOR   DELFLG
            BEQ   :NOTWANT     ;WANTED FILE?
            TYA
            LDX   NACTIV
            STA   CBYTE,X      ;PUT INTO ARRAY
            LDA   RPAGE
            STA   CSECTR,X
            INC   NACTIV
:NOTWANT    TYA                ;NEXT FILE IN
            CLC                ;SECTOR
            ADC   #$23
            TAY
            BNE   :POSNLP      ;DONE SECTOR?
            DEC   COUNT        ;ROOM 4 MORE?
            BNE   :SECTLP
:OUT        RTS
*
*
RDVTOC      LDA   #1
            STA   RCMND
            JSR   DOVTOC
            LDA   #0
            STA   RTRACK
            RTS
*
RDCAT1      LDA   #>CAT1
            JSR   CLRCAT
            LDX   #>VTOC1
RDCT1A      LDA   #$01
            BNE   DOCAT
*
RDCAT2      LDA   #>CAT2
            JSR   CLRCAT
            LDX   #>VTOC2
            BNE   RDCT1A
*
WRCAT1      LDX   #>VTOC1
            BNE   WRCT2A
*
WDERR       LDA   #$52
            JMP   ERROU1
*
WRCAT2      BIT   DOSNOW
            BPL   :DOS33
            JMP   CLOSE
*
:DOS33      LDX   #>VTOC2
WRCT2A      LDA   #2
DOCAT       STA   RCMND
            BIT   DOSNOW
            BPL   :DOS33
            LDX   #>SDIR
            STX   DIRADR
            JMP   PDOCAT
*
:DOS33      JSR   DOVTOC       ;R/W VTOC.
:SECTLP     LDY   #$01         ;FIND PTR TO
            LDA   (POINT),Y    ;NEXT SECTOR
            BEQ   :OUT         ;NIL PTR?
            STA   RTRACK       ;NO:SAVE TRACK
            INY
            LDA   (POINT),Y    ;& SECTOR
            STA   RSECTR
            INC   RPAGE        ;NEXT PAGE
            INC   POINT+1
            JSR   PHRWTS       ;R/W CATALOG
            BCS   :OUT         ;ERROR?
            LDY   #$0B
:POSNLP     LDA   (POINT),Y
            BEQ   :OUT         ;NO MORE FILES?
            TYA
            CLC
            ADC   #$23         ;NEXT FILE
            TAY
            BNE   :POSNLP      ;DONE SECTOR?
            DEC   COUNT        ;ROOM 4 MORE?
            BNE   :SECTLP
:OUT        RTS
*
* READ/WRITE VTOC, READY FOR CATALOG
*
DOVTOC      STX   RPAGE        ;SET PAGE
            STX   POINT+1
            JSR   STVTOC       ;RETURNS A=0
            STA   POINT
            STA   RSECTR       ;SECTOR 0
            LDA   #$0F         ;UP TO 15
            STA   COUNT        ;CATALOG PAGES
            JSR   DORWTS       ;R/W VTOC.
            LDY   #$35
            LDA   (POINT),Y
            CMP   #$10
            BNE   WDERR
            LDY   #1
            LDA   (POINT),Y
            BEQ   WDERR
            RTS
*
* CLEAR CATALOG SECTORS
CLRCAT      STA   POINT+1
            LDA   #$00
            STA   POINT
            TAY
            LDX   #$0E
:NXTSECT    STA   (POINT),Y
            INY
            CPX   #$00
            BEQ   :NOLINK
            LDA   #$11
:NOLINK     STA   (POINT),Y    ;TRACK LINK
            INY
            TXA
            STA   (POINT),Y    ;SECTOR LINK
            INY
            LDA   #$00
:ZEROLP     STA   (POINT),Y    ;ZEROS
            INY
            BNE   :ZEROLP
            INC   POINT+1
            DEX
            BPL   :NXTSECT     ;BACK FOR MORE
            RTS
*
*
*
* FIND FREE & USED SPACE IN VTOC
* ACC=PAGE# OF VTOC ->
*
SPACE       BIT   DOSNOW
            BPL   :DOS33
            JMP   PSPACE       ;DO PRODOS
*
:DOS33      STA   POINT+1
            LDA   #$38         ;BITMAP START
            STA   POINT
            LDA   #$00         ;CLEAR BUFFER
            STA   FREEL
            STA   FREEH
            LDY   #$8B         ;BITMAP LENGTH
:NXTBYTE    LDA   (POINT),Y
            LDX   #$07
:NEXTBIT    LSR                ;SHIFT BITS TO
            BCC   :USED        ;FIND FREE
            INC   FREEL        ;SECTORS
            BNE   :USED
            INC   FREEH
:USED       DEX
            BPL   :NEXTBIT
            DEY
            BNE   :NXTBYTE
            SEC                ;SUBTRACT FROM
            LDA   #$30         ;TOTAL # OF
            SBC   FREEL        ;SECTORS TO
            STA   USEDL        ;GET # USED
            LDA   #2
            SBC   FREEH
            STA   USEDH
            RTS
*
* CONVERT FILENAME TO CR FORMAT
* CAN'T USE DOSNOW TO DETERMINE
* FILENAME FORMAT
*
FTOCR       LDY   #1
            LDA   (POINT),Y
            CMP   #$10
            BCS   :PRODOS
*
:DOS33      LDX   #$1E         ;(NAME LENGTH)
            LDY   #$00
            LDA   (POINT),Y    ;DELETED?
            CMP   #$FF
            BNE   :LONG
            DEX                ;DON'T USE
:LONG       TXA                ;LAST CHAR
            TAY
            INC   POINT        ;POINT TO
            INC   POINT        ;FILENAME
            INC   POINT
:SPACE      DEY
            LDA   (POINT),Y    ;LOOP TO IGNORE
            CMP   #" "         ;LAST SPACES
            BEQ   :SPACE
            STA   FILNAM,Y     ;SAVE LAST CHAR
            LDA   #$8D         ;END WITH CR
            STA   FILNAM+$1,Y
            DEY
:NEXTCHR    LDA   (POINT),Y    ;COPY THE REST
            STA   FILNAM,Y     ;OF THE CHARS
            DEY
            BPL   :NEXTCHR
            DEC   POINT
            DEC   POINT
            DEC   POINT
            RTS
*
:PRODOS     DEY                ;1 --> 0
            LDA   (POINT),Y
            AND   #$0F         ;NECESSARY?
            BNE   :PRO1
            LDA   #$0F
:PRO1       TAX
            INY                ;0 --> 1
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
*
*
* PLACE INPUT FILE INTO ENTRY
*   AT (*POINT)
*
PLACE       LDX   #0
:CRLP       INX
            LDA   LINEIN,X
            CMP   #$8D
            BNE   :CRLP
            BIT   DOSNOW
            BMI   :PRODOS
            LDA   #" "         ;MOVE LINE TO
            LDY   #$20         ;ENTRY:
:SPACELP    STA   (POINT),Y    ;COPY SPACES
            DEY                ;TO ENTRY
            CPY   #$03
            BPL   :SPACELP
            TXA
            TAY
            DEX                ;BEFORE CR
            INY                ;ENTRY OFFSET 3
            INY                ;MORE
            LDA   #$FF
:PUTLP0     STA   :MASK
:PUTLP      LDA   LINEIN,X     ;COPY CHARS
            AND   :MASK
            STA   (POINT),Y
            DEY
            DEX
            BPL   :PUTLP
            CLC
            RTS
:PRODOS     LDY   #0
            LDA   (POINT),Y
            AND   #$F0
            STA   (POINT),Y
            TXA
            AND   #$0F
            TAX
            ORA   (POINT),Y
            STA   (POINT),Y
            TXA
            TAY
            DEX
            LDA   #$7F
            BNE   :PUTLP0      ;ALWAYS
*
:MASK       DB    $0
*
* SET POINTER FROM CATALOG ARRAY
*
CURPNT      LDX   CURR
SETPNT      LDA   CBYTE,X
            STA   POINT
            LDA   CSECTR,X
            STA   POINT+1
            RTS
*
* PRINT FILENAME AT *POINT
*
CFILE       BIT   DOSNOW
            BPL   :CFL33
            JMP   PCFILE
*
:CFL33      LDY   #$00
            LDA   (POINT),Y
            TAX
            LDY   #$03
:NXTCHAR    LDA   (POINT),Y
            JSR   CTRL?
            BCS   :DONT
            CPY   #$20         ;LAST CHAR?
            BNE   :DO          ;NOPE
            CPX   #$FF         ;DELETED FILE?
            BNE   :DO          ;NO: JUST COUT
            LDA   #$A0         ;YES:USE SPACE
:DO         JSR   PCOUT
:DONT       INY
            CPY   #$21
            BCC   :NXTCHAR
:OUT        RTS
:LENGTH     DB    $21
*
*
* FREE A SECTOR ON *POINT - VTOC
* T&S IN *TRACK & *SECTOR
*
FREES       LDA   TRACK
            ASL
            ASL
            ADC   #$38
            TAY
            LDA   SECTOR
            JSR   DOMASK
            LDA   (POINT),Y
            ORA   BITMSK
            STA   (POINT),Y
            INY
            LDA   (POINT),Y
            ORA   BITMSK+1
            STA   (POINT),Y
            RTS
*
* MAKE A 1-BIT MASK FOR A BITMAP WORD
* SECTOR # IN ACC ->
*
DOMASK      TAX
            LDA   #$00
            STA   BITMSK+1
            STA   BITMSK
            SEC
:NEXT       ROL   BITMSK+1
            ROL   BITMSK
            DEX
            BPL   :NEXT
:OUT        RTS
*
*
STVTOC      LDA   #$11
            STA   RTRACK
            LDA   #$00
            STA   RSECTR
            RTS
*
*
DOS?        LDX   #0
            JSR   PUTSEC
            STX   RTRACK
            JSR   DORWTS
            LDX   #3
            LDY   #1
            JSR   CHKDOS
            BCC   :NODOS
            RTS
:NODOS      JSR   PRHERE
            DB    $8D,$8D
            ASC   "No DOS on disk"
            DB    $8D,$0
            JMP   PRESS
*
*
*
* FIND FILETYPE
*
FILTYP      LDX   #$08
            LDY   #$02
            LDA   (POINT),Y
            AND   #$7F
:LOOP       CMP   TYPBYT,X
            BEQ   :OUT
            DEX
            BNE   :LOOP
:OUT        RTS
TYPBYT      DB    $00,$40,$20,$10,$08,$04,$02,$01,$00
TYPCHR      ASC   "?BARSBAIT"
*
* INSERT SOURCE OR DESTINATION DISKS
*
*
INSS        LDA   PDOS
            STA   CURDOS
:INSS0      JSR   INSS1
            CMP   #1
            BNE   :NOSWS       ;DIDN'T SWITCH
            LDA   #>PPFX
            LDY   #PPFX
            LDX   #>VTOC1
            JSR   SWCK
            BCS   :INSS0
:NOSWS      JMP   SETP
*
INSS1       LDA   ONLY1        ;IF ONLY 1:
            BEQ   :SELECT
            LDA   SDFLG
            BPL   :SELECT
            LDA   #0
            STA   SDFLG
            LDA   #$57         ;INSERT SRC
            JSR   LOWMES
            JSR   INSCOM       ;WAIT FOR KEY
            STA   PDOS         ;1
:SELECT     RTS
*
INSD        LDA   SDOS
            STA   CURDOS
:INSD0      JSR   INSD1
            CMP   #1
            BNE   :NOSWP
            LDA   #>SPFX
            LDY   #SPFX
            LDX   #>VTOC2
            JSR   SWCK
            BCS   :INSD0
:NOSWP      JMP   SETS
*
INSD1       LDA   ONLY1
            BEQ   :SELECT
            LDA   SDFLG
            BMI   :SELECT
            LDA   #$FF
            STA   SDFLG
            LDA   #$58
            JSR   LOWMES
            JSR   INSCOM
            STA   SDOS         ;1
:SELECT     RTS
*
INSCOM      LDA   #$35         ;CRESC
            JSR   PRINT
            JSR   KYESC
            JSR   LOHERE
            DB    $0
            LDA   #1
            RTS
SDFLG       DB    $0
*
SWCK        STA   PFXADR+1
            STY   PFXADR
            STX   :VTOC
            JSR   DOSTYP
            LDA   CURDOS
            CMP   #1
            BEQ   :SWCK0
            EOR   DOSNOW
            BNE   :BADSWP      ;NOT SAME DOS
:SWCK0      LDA   DOSNOW
            BPL   :DOSCK
            LDY   #0
            LDA   (PFXADR),Y
            BEQ   :SWCKOUT     ;DON'T CHECK
            BMI   :SWCKOUT
            LDA   VOLNMS,X
            AND   #$0F
            CLC
            ADC   #2
            STA   :LEN
            LDY   #2
:SWCKLP     LDA   (PFXADR),Y
            CMP   VOLNMS+$1,X
            BNE   :BADSWP
            INY
            INX
            CPY   :LEN
            BCC   :SWCKLP
:SWCKOUT    CLC
            RTS
:BADSWP     JSR   LOHERE
            ASC   "Incorrect disk"
            DB    $8D,$87,$0
            JSR   INSCOM
            LDA   SDFLG
            EOR   #$FF
            STA   SDFLG
            SEC
            RTS
*
:DOSCK      LDA   :VTOC
            STA   MESPNT+1
            LDY   #0
            STY   MESPNT
            INY
            LDA   (MESPNT),Y
            BEQ   :SWCKOUT     ;DON'T CHECK
            JSR   STVTOC
            LDA   #$01
            STA   RCMND
            LDA   RPAGE
            PHA
            LDA   #>CVTOC
            STA   RPAGE
            JSR   DORWTS
            PLA
            STA   RPAGE
            LDY   #$00
:LOOPCHK    LDA   (MESPNT),Y
            CMP   CVTOC,Y
            BNE   :BADSWP
            DEY
            BNE   :LOOPCHK
            CLC
            RTS
:VTOC       DB    $0
:LEN        DB    $0
*
SWPCHK      LDA   DOSNOW
            STA   CURDOS
:SWPCHK0    LDA   #>PFX
            LDY   #PFX
            LDX   #>VTOC1
            JSR   SWCK
            BCS   :SWPCHK0
SWPRET      RTS
*
SET1A2      STA   CVTOC+$3C
            STA   CVTOC+$3D
            STA   CVTOC+$40
            STA   CVTOC+$41
            LDA   #2
            STA   RCMND
*
DORWTS      JSR   PHRWTS
            BCC   SWPRET
            JMP   ERROUT
*
ERRMSG      LDA   RRTN
            LDY   #$0C
:OUCHLP     CMP   :ERRNUM,Y
            BEQ   :OUCH0       ;FOUND ERROR # IN TABLE
            DEY
            BPL   :OUCHLP
*
:OUCH2      CMP   #$40
            BCS   :NOT27
            JSR   PRHERE
            ASC   "I/O "
            DB    $0
*
:NOT27      JSR   PRHERE
            ASC   "Error"
            DB    $0
            BIT   DOSNOW
            BPL   :DOS33
*
            LDA   RRTN
            CMP   #$29
            BCC   :SKIP
            JSR   PRHERE
            ASC   " $"
            DB    $0
            LDA   RRTN
            BNE   :SKIP1       ;ALWAYS (BECAUSE RRTN >= $29)
*
:ERRNUM     DB    $2B,$44,$45,$46,$48,$49,$4E,$3F,$52,$47
            DB    $40,$2F,$28
*
:OUCH0      JSR   CROUT2
            TYA
            CLC
            ADC   #$45
            JSR   PRINT
            JMP   CROUT2

*
:SKIP       JSR   PRHERE
            ASC   ": Block $"
            DB    $0
            LDA   BLKNUM+1
            JSR   PHBYTE
            LDA   BLKNUM
:SKIP1      JSR   PHBYTE
:SKIPBLK    JMP   :OUCH1
*
:DOS33      JSR   PRHERE
            ASC   ": "
            DB    $0
            JSR   TSVALS
:OUCH1      JMP   CROUT
*
CROUT2      JSR   CROUT
            JMP   CROUT
*
OUCH        JSR   HOME
            JSR   ERRMSG
            JSR   CROUT
*LDA LEVEL
*PHA
*LDA #1
*STA LEVEL
            JSR   CLOSE
*PLA
*STA LEVEL
            LDA   #$43         ;PRESS
            JSR   PRINT
            JMP   GETKEY
*
* PRINT TRACK & SECTOR #'S
*
TSVALS      JSR   PRTTRK
            JSR   PRHERE
            ASC   ", "
            DB    $0
            LDA   #$34
            JSR   PRINT        ;'SECTOR $'
            LDA   RSECTR       ;SECTOR MORE
            CMP   #$10         ;THAN 1 DIGIT?
            BCS   :BIGSEC
            JMP   PHHEX        ;NO:PRINTDIGIT
:BIGSEC     JMP   PHBYTE       ;YES:PRINTBYTE
*
PRTTRK      LDA   #$33
            JSR   PRINT        ;'TRACK $'
            LDA   RTRACK
            JMP   PHBYTE

*
*
*********************************
*     GENERAL I/O STUFF         *
*********************************
*
*
* IS CHAR IN ACC A CONTROL?
*
CTRL?       CMP   #$A0
            BCS   :OK
            CMP   #$80
            BCS   :BADOUT
:OK         CLC
:BADOUT     RTS
*
* PRINT DOLLAR SIGN, KEEP ACC
*
DOLLAR      PHA
            LDA   #"$"
            JSR   PCOUT
            PLA
            RTS
*
*
* NO FILES SELECTED
NOSEL       JSR   LOHERE
            ASC   "No files selected"
            DB    $0
            JMP   PRESS
*
* NO FILES TO WORK WITH
NOFIL0      LDA   #5
            JSR   VLEFT
NOFILS      LDA   #$36
PRTPRS      JSR   PRINT
*
* PRESS A KEY & PROGRAM RESTART
PRESS       LDA   #$43
            JSR   PRINT
            JSR   GETKEY
KYESX       JMP   FILER
*
*
* RDKEY WITH CASE CONVERT
*
CASKEY      JSR   PRDKEY
            JMP   LOW2UP
*
* READS KEYBOARD WITHOUT CURSOR GAMES
* -> CHARACTER IN AREG
*
GETKEY      BIT   KBDSTB
:LOOP       LDA   KBD
            BPL   :LOOP
            JSR   CHKALT
            BCS   GETKEY
            BIT   KBDSTB
LOW2UP      CMP   #$E0         ;CONVERT LOWER
            BCC   :LOWQ        ;TO UPPER CASE
            SBC   #$20
:LOWQ       RTS
*
*
CKESC       LDA   $C000
            JMP   KEYES1
*
* GET CHARACTER, CHECK ESC
*
KEYESC      JSR   CASKEY
KEYES1      CMP   #$9B
            BEQ   KYESX
            RTS
*
KYESC       JSR   GETKEY
            JMP   KEYES1
*
PRDKEY      BIT   $C010        ;NO TYPEAHEAD
            JSR   RDKEY
            JSR   CHKALT
            BCS   PRDKEY
            RTS
*
* FOR KEYPRESSES, CHECK FOR CTRL-@
* ALTCHARSET TOGGLE
*
CHKALT      CMP   #$80         ;CTRL-@?
            BNE   :CHKQ
*
* CARRY SET NOW
*
            BIT   A2E          ;ON A //E?
            BPL   :CHKQ        ;NO: CLC OUT.
            LDA   $C01E        ;YES: WHAT'S
            BPL   :ALTON       ;ALTCHARSET?
            STA   $C00E        ;-: GO +
            RTS
:ALTON      STA   $C00F        ;+: GO -
            RTS
:CHKQ       CLC
            RTS
*
*
* DO VTAB, & HTAB 0
*
VLEFT       JSR   TABV
            LDA   #$00
SETCH       STA   CH
* BIT *FLAG80
* BPL NOT80
* STA $57B                ;OURCH
:NOT80      RTS
*
* HEX TO DECIMAL CONVERTER
* PUT 2-BYTE HEX NUMBER IN HEXNUM  ->
* 5 DECIMAL NUMBERS LEFT IN DIGIT
*
HEXDC1      LDX   #0
HEXDC2      STX   HEXNUM+1
            STA   HEXNUM
HEXDEC      LDA   #0
            STA   HEXNUM+2
HEXDC3      LDA   #$00
            LDX   #$07
:CLRLOOP    STA   DIGIT,X
            DEX
            BNE   :CLRLOOP
            LDX   #$07
            BNE   :START
:MAKEIT     INC   DIGIT,X
:START      LDA   HEXNUM
            STA   :LAST
            LDA   HEXNUM+1
            STA   :LAST+1
            LDA   HEXNUM+2
            STA   :LAST+2
:DIGITLP    SEC
            LDA   :LAST
            SBC   :POWER0,X
            STA   HEXNUM
            LDA   :LAST+1
            SBC   :POWER1,X
            STA   HEXNUM+1
            LDA   :LAST+2
            SBC   :POWER2,X
            STA   HEXNUM+2
            BCS   :MAKEIT
            DEX
            BNE   :DIGITLP
            LDA   :LAST
            STA   DIGIT
            RTS
:POWER0     DB    $01,$0A,$64,$E8,$10,$A0,$40,$80
:POWER1     DB    $00,$00,$00,$03,$27,$86,$42,$96
:POWER2     DB    $00,$00,$00,$00,$00,$01,$0F,$98
:LAST       DB    $00,$00,$00
*
* PRINT 3 DECIMAL DIGITS IN *DIGIT
* LEADING ZEROS PRINTED
PRTLZ       LDX   #$02
:NEXTDIG    LDA   DIGIT,X      ;PRINT DECIMAL
            JSR   MYHEX        ;DIGITS
            DEX
            BPL   :NEXTDIG
            RTS
*
*
PRT8RJ      LDX   #7
            DB    $2C
PRT5RJ      LDX   #4
            DB    $2C
PRT3RJ      LDX   #2
            DB    $2C
PRT2RJ      LDX   #1
:PRTRJ      LDA   DIGIT,X
            BNE   PRTDIG
            LDA   #" "
            JSR   PCOUT
            DEX
            BNE   :PRTRJ
            BEQ   PRTDIG       ;ALWAYS
*
PRT8LJ      LDX   #7
            DB    $2C
PRT5LJ      LDX   #4
:PRTLJ      LDA   DIGIT,X
            BNE   PRTDIG
            DEX
            BNE   :PRTLJ
            BEQ   PRTDIG
PRT2DG      LDX   #1
PRTDIG      LDA   DIGIT,X
            JSR   MYHEX
            DEX
            BPL   PRTDIG
            RTS
*
*
MYHEX       ORA   #$B0
            CMP   #$BA
            BCC   :PRINT
            ADC   #$06
:PRINT      JMP   PCOUT
*
*
*
*
*
*
* CATALOG
* COPY
*
**********************************
*          CATALOG DISK          *
**********************************
*
CATLOG      LDX   #$01         ;SELECT OPTION
            JSR   CHOOZ1
            STA   :TYPE
            CMP   #$02
            BNE   :NOTDEL
            LDA   #$01
            STA   DELFLG
:NOTDEL     LDA   #$FF
            STA   OPTCHS
            JSR   DODEVP
            JSR   TREEA
            JSR   CT1
            JSR   PRVNM
            JSR   ASKPR?       ;PRINTER ON?
            LDA   PSLOT
            BEQ   :SKIP2
            JSR   HOME
:SKIP2      JSR   RDACNT       ;GET CATALOG
            LDA   #$80
            STA   DELFLG       ;RESET DELETE
            LDA   #0
            STA   :COUNT       ;CR COUNTER
            LDA   PRNTR?       ;YES PRINTER?
            BEQ   :CHOOSE
            JSR   HOME
            JSR   PRON         ;PRINTER ON
            JSR   :CROUNT
:CHOOSE     JSR   TOP1         ;3/6/87 (WAS TOP1A)
            JSR   PRVNM
            BIT   DOSNOW
            BPL   :VOL2
            JSR   :CROUNT
*
* NAME           TYPE  BLKS  MODIFIED
*
            LDA   #$59
            JSR   PRINT
            LDA   :TYPE
            CMP   #1
            BNE   :VOL1
            INC   :COUNT
*
*CREATED          ENDFILE SUBTYPE
*
            LDA   #$5A
            JSR   PRINT
:VOL1       JSR   :CROUNT
*
*
:VOL2       JSR   :CROUNT
            LDA   NACTIV       ;ANY FILES?
            BNE   :CONTINU
            LDA   #$36         ;'NO FILES'
            JSR   PRINT
            JSR   :CROUNT
            JMP   :ALLDONE
*
:CONTINU    LDA   #0
            STA   CH
            STA   SHOW
            LDA   :TYPE        ;CHOOSE OPTION
            BEQ   :NORMAL
            CMP   #$01
            BEQ   :LENGTHS
            CMP   #$02
            BEQ   :DELETED
*
* HIDDEN CHARACTERS
*
:HID1       LDX   SHOW
            JSR   SETPNT
            BIT   DOSNOW
            BMI   :SKIPHID     ;PRODOS
*
            LDY   #$03
:HID2       LDA   (POINT),Y    ;GET FILENAME
            BPL   :HID3        ;CHAR
            CMP   #$A0
            BCS   :HID3        ;IF CONTROL,
            BIT   PRNTR?
            BMI   :PRTHID
            AND   #$1F
* BIT *A2E
* BPL HIDPUT
* ORA #$40
* STA    $C00F            ;ALTCHARSET
            BPL   :HIDPUT      ;ALWAYS
*
:PRTHID     EOR   #$60         ;OR LOWERCASE
:HIDPUT     STA   (POINT),Y
:HID3       INY                ;NEXT...
            CPY   #$21
            BCC   :HID2
*
:SKIPHID    LDA   :TYPE
            JSR   CATLIN
            JSR   :NEXTFIL
            BCC   :HID1
            BCS   :GOALLD
*
* NORMAL CATALOG
:NORMAL     LDA   :TYPE
            JSR   CATLIN
            JSR   :NEXTFIL
            BCC   :NORMAL
:GOALLD     JMP   :ALLDONE
*
* SEE DELETED FILES
:DELETED    LDX   SHOW
            JSR   SETPNT
            LDY   #$00
            LDX   #" "
            BIT   DOSNOW
            BPL   :DELF33
*
            LDA   (POINT),Y
            AND   #$0F
            BNE   :NOTDEL1
            BEQ   :ISDEL1
*
:DELF33     LDA   (POINT),Y    ;CHECK DELETED
            BPL   :NOTDEL1     ;STATUS
:ISDEL1     LDX   #"D"         ;PRINT "D" OR
:NOTDEL1    TXA                ;SPACE
            JSR   PCOUT
            JSR   PRSPC
            JSR   CATLN1       ;SEE LINE
            JSR   :NEXTFIL
            BCC   :DELETED
            BCS   :GOALLD
*
* CATALOG W/ FILE LENGTHS
:LENGTHS    BIT   DOSNOW
            BMI   :NORMAL      ;PRODOS
*
            LDA   #$00
            STA   SHOW
            LDA   #>DATA
            STA   DATADR
            LDA   #>DATPAG
            STA   HIMEM
:FILELP4    JSR   CATLIN
            LDA   SHOW
            STA   CURR
            LDY   #$02
            LDA   (POINT),Y
            AND   #$07
            STA   :FILTYPE
            BEQ   :NEXT2
:SEEIT      JSR   OPNSRC
            JSR   RDDATA       ;READ 1 PAGE
            BIT   FLAG80
            BMI   :SEEIT0
            JSR   :CROUNT
:SEEIT0     LDX   #$07
            JSR   PRBL2
            LDY   #$00
            LDA   :FILTYPE
            CMP   #$04
            BNE   :LENGTH
            LDA   #"A"
            JSR   PCOUT
            LDA   DATA
            LDX   DATA+1
            JSR   :SEEADR
            JSR   :COMMA
:LENGTH     LDA   #"L"
            JSR   PCOUT
            LDA   DATA,Y
            LDX   DATA+$1,Y
            JSR   :SEEADR
            JSR   PRHERE
            ASC   "  ("
            DB    $0
            LDY   #$00
            LDA   :FILTYPE
            CMP   #$04
            BNE   :HLENGTH
            LDA   #"A"
            JSR   PCOUT
            JSR   DOLLAR
            LDA   DATA+1
            JSR   PHBYTE
            LDA   DATA
            JSR   PHBYTE
            JSR   :COMMA
:HLENGTH    LDA   #"L"
            JSR   PCOUT
            JSR   DOLLAR
            LDA   DATA+$1,Y
            JSR   PHBYTE
            LDA   DATA,Y
            JSR   PHBYTE
            LDA   #")"
            JSR   PCOUT
:NEXT2      JSR   :NEXTFIL
            BCS   :ALLDONE
            JMP   :FILELP4
:TYPE       DB    $0
:FILTYPE    DB    $0
*
:COMMA
            LDA   #$AC         ;","
            JSR   PCOUT
            JSR   PRSPC
            INY
            INY
            RTS
*
*
:NEXTFIL    JSR   :CROUNT
            BIT   DOSNOW
            BPL   :NF1
            LDA   :TYPE
            CMP   #1
            BNE   :NF1
            LDA   FLAG80
            BMI   :NF1         ;80-COL
            INC   :COUNT
:NF1        INC   SHOW
            LDA   PRNTR?
            BNE   :NEXTF
            LDA   :COUNT
            CMP   #$12
            BCC   :NEXTF
            LDA   #$00
            STA   :COUNT
            JSR   KYESC
:NEXTF      LDA   SHOW
            CMP   NACTIV
            RTS
*
:CROUNT     JSR   CROUT
            INC   :COUNT
            RTS
:COUNT      DB    $0
*
:SEEADR     STY   YSAV
            STA   HEXNUM
            STX   HEXNUM+1
            JSR   HEXDEC
            JSR   PRT5LJ
            LDY   YSAV
            RTS
*
:ALLDONE    JSR   CROUT
            JSR   CSPACE
            JSR   CROUT
            LDA   PRNTR?
            BEQ   :ALLDN1
            JSR   PROFF
:ALLDN1     JMP   PRESS
*
*
COL80       BIT   FLAG80
            BPL   :OUT80
            LDA   #$C3
            STA   CSWL+1
            LDA   #0
            STA   CSWL
            LDA   #$41
            STA   SDCH
            JSR   CROUT
:OUT80      RTS
*
*
COL40       LDA   #$19
            STA   SDCH
            BIT   FLAG80       ;(10/6/87)
            BPL   :OUT40
            LDA   #$15         ;
            JSR   $C300        ;
:OUT40      JMP   VDINIT
*
*
CSPACE      LDA   #>VTOC1
            JSR   SPACE
            BIT   DOSNOW
            BPL   :DOS33
            JSR   PRHERE
            ASC   "Block"
            DB    $0
            JMP   :COMMON
:DOS33      JSR   PRHERE
            ASC   "Sector"
            DB    $0
:COMMON     JSR   PRHERE
            ASC   "s free:"
            DB    $0
            LDA   FREEL
            LDX   FREEH
            JSR   HEXDC2
            JSR   PRT5LJ
            LDA   #$12
            STA   CH
            JSR   PRHERE
            ASC   "Used:"
            DB    $0
            LDA   USEDL
            LDX   USEDH
            JSR   HEXDC2
            JSR   PRT5LJ
            LDA   #$1D
            STA   CH
            JSR   PRHERE
            ASC   "Total:"
            DB    $0
            LDA   FREEL
            CLC
            ADC   USEDL
            PHA
            LDA   FREEH
            ADC   USEDH
            TAX
            PLA
            JSR   HEXDC2
            JMP   PRT5LJ
