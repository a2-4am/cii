            TYP   BIN
            DSK   ../build/CATALOG.O
            PUT   VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/COPY.VARS
            ORG   COPYEND
CATALOG
            ORG   *+3

**********************************
*          CATALOG DISK          *
**********************************
*
            LDX   #UCATALOG   ;SELECT OPTION
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
            JSR   ASKPR?      ;PRINTER ON?
            LDA   PSLOT
            BEQ   :SKIP2
            JSR   HOME
:SKIP2      JSR   RDACNT      ;GET CATALOG
            LDA   #$80
            STA   DELFLG      ;RESET DELETE
            LDA   #0
            STA   :COUNT      ;CR COUNTER
            LDA   PRNTR?      ;YES PRINTER?
            BEQ   :CHOOSE
            JSR   HOME
            JSR   PRON        ;PRINTER ON
            JSR   :CROUNT
:CHOOSE     JSR   TOP1        ;3/6/87 (WAS TOP1A)
            JSR   PRVNM
            BIT   DOSNOW
            BPL   :VOL2
            JSR   :CROUNT
            JSR   PRHERE
            ASC   "   NAME           TYPE  BLKS  MODIFIED",00
            LDA   :TYPE
            CMP   #1
            BNE   :VOL1
            INC   :COUNT
            JSR   PRHERE
            ASC   "         CREATED          ENDFILE SUBTYPE",00
:VOL1       JSR   :CROUNT
*
*
:VOL2       JSR   :CROUNT
            LDA   NACTIV      ;ANY FILES?
            BNE   :CONTINU
            LDA   #MNOFILES   ;'NO FILES'
            JSR   PRINT
            JSR   :CROUNT
            JMP   :ALLDONE
*
:CONTINU    LDA   #0
            STA   CH
            STA   SHOW
            LDA   :TYPE       ;CHOOSE OPTION
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
            BMI   :SKIPHID    ;PRODOS
*
            LDY   #$03
:HID2       LDA   (POINT),Y   ;GET FILENAME
            BPL   :HID3       ;CHAR
            CMP   #$A0
            BCS   :HID3       ;IF CONTROL,
            BIT   PRNTR?
            BMI   :PRTHID
            AND   #$1F
* BIT *A2E
* BPL HIDPUT
* ORA #$40
* STA    $C00F            ;ALTCHARSET
            BPL   :HIDPUT     ;ALWAYS
*
:PRTHID     EOR   #$60        ;OR LOWERCASE
:HIDPUT     STA   (POINT),Y
:HID3       INY               ;NEXT...
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
:DELF33     LDA   (POINT),Y   ;CHECK DELETED
            BPL   :NOTDEL1    ;STATUS
:ISDEL1     LDX   #"D"        ;PRINT "D" OR
:NOTDEL1    TXA               ;SPACE
            JSR   PCOUT
            JSR   PRSPC
            JSR   CATLN1      ;SEE LINE
            JSR   :NEXTFIL
            BCC   :DELETED
            BCS   :GOALLD
*
* CATALOG W/ FILE LENGTHS
:LENGTHS    BIT   DOSNOW
            BMI   :NORMAL     ;PRODOS
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
            JSR   RDDATA      ;READ 1 PAGE
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
            LDA   #$AC        ;","
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
            BMI   :NF1        ;80-COL
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
            JSR   :CSPACE
            JSR   CROUT
            LDA   PRNTR?
            BEQ   :ALLDN1
            JSR   PROFF
:ALLDN1     JMP   PRESS
*
:CSPACE     LDA   #>VTOC1
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
CATALOGEND
