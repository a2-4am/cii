            TYP   BIN
            DSK   ../build/UILIB.O
            PUT   VARS
            PUT   ../build/PHRWTS.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/ERRORS.VARS
            ORG   ERRORSEND

* TOP1      clear screen and display function title
* DODEVF
* DODEVP
* PRVNM     print current slot+drive (if DOS)
*           or current prefix (if ProDOS)
* PRTTRK    print current track
* PRTBLK    print current block
* PRTFL1    print current prefix
* PRTFIL    print current prefix + filename
* CFILE     print current filename
* PCFILE    print current filename (ProDOS)
* SEEDEV    print slot and drive

*
* CLEAR SCREEN AND DISPLAY FUNCTION TITLE
*
TOP1        JSR   HOME
            LDA   #0
            STA   WNDTOP
            JSR   TABV
            LDA   CHOICE      ;FUNCTION NAME
            JSR   PRINT
            JSR   PRSPC
            LDA   OPTCHS
            BMI   :TOP1A
            JSR   PRINT
:TOP1A      RTS
*
* SHOW 'SELECT DEVICE' LIST
*
DEVFLG      DB    $0
DODEVF      LDA   #$FF
            DB    $2C
DODEVP      LDA   #0
            STA   DEVFLG
            JSR   HOME
            JSR   PRHERE
            ASC   "Select device:"
            DB    $0
            LDA   CURDVA
            JSR   JDODEV
            STX   CURDVA
            RTS
*
*
* SHOW CURRENT SLOT & DRIVE
* AND/OR CURRENT PREFIX. (*PFX<>0)
*
* RETURNS WITH CV = 3, CH = 0
*
PRVNM       LDX   #PFX
            LDY   #>PFX
            LDA   UNIT
PRVCOM      STA   UNIT
            STX   TMPPTR
            STY   TMPPTR+1
            LDA   #0
            JSR   TABV
            LDA   CHOICE
            BNE   :CONTIN     ;CMD NOT COPY
            LDA   SDCH
            SEC
            SBC   #8
            STA   CH
            LDA   SRCTAR
            BNE   :NOTSRC
            JSR   PRHERE
            ASC   "Source:"
            DB    $0
            JMP   :CONTIN
*
:NOTSRC     CMP   #$FF
            BNE   :CONTIN
            JSR   PRHERE
            ASC   "Target:"
            DB    $0
*
:CONTIN     LDA   SDCH
            STA   CH
            LDA   UNIT
            JSR   SEEDEV
:SKIPCR     LDA   #1
            JSR   VLEFT
            LDY   #0
            STY   HEXNUM+1
            LDA   (TMPPTR),Y
            STA   :PFXLEN
            BMI   :BLNKLP     ;NO PFX
            BIT   DOSNOW
            BPL   :SDDOS33
            CMP   #0
            BEQ   :BLNKLP
            BNE   :SDPRODOS
*
:SDDOS33    LDY   #5
            LDA   (TMPPTR),Y
            BEQ   :BLNKLP
            STA   HEXNUM
            JSR   PRHERE
            ASC   "Disk Volume "
            DB    $0
            JSR   HEXDEC
            JSR   PRTLZ
            LDY   #$14
            BNE   :BLNKLP     ;ALWAYS
*
:SDPRODOS   INY
            LDA   (TMPPTR),Y
            ORA   #$80
            JSR   PCOUT
            CPY   :PFXLEN
            BCC   :SDPRODOS
:BLNKLP     INY
            LDA   #$A0
            JSR   PCOUT
            CPY   #$42
            BCC   :BLNKLP
:NOPFX      LDA   #3
            STA   WNDTOP
            JMP   VLEFT
:PFXLEN     DB    $0
*
SRCTAR      DB    $0
*
*
*
PRTFL1      SEC
            DB    $90
PRTFIL      CLC
            PHP
            BIT   DOSNOW
            BPL   :DOS33
            LDA   #1
            JSR   VLEFT
            LDY   #0
:PRO0       LDA   PFX+$1,Y
            ORA   #$80
            PHA
            JSR   PCOUT
            PLA
            INY
            CPY   PFX
            BCC   :PRO0
            CMP   #"/"
            BEQ   :PRO00
            LDA   #"/"
            JSR   PCOUT
:PRO00      PLP
            BCS   :PRO1       ;NO FILE NAME
            JSR   CFILE
:PRO1
*            LDA   PRNTR?
*            BNE   :CFILEQ     ;DON'T CLREOL
            JMP   CLREOL
*
:DOS33      LDA   #2
            JSR   VLEFT
            JSR   PRHERE
            ASC   "File: "
            DB    $FF,0
            PLP
            BCS   :CFILEQ
* fall through to CFILE
*
* PRINT FILENAME AT *POINT
*
CFILE       BIT   DOSNOW
            BMI   PCFILE
            LDY   #$00
            LDA   (POINT),Y
            TAX
            LDY   #$03
:NXTCHAR    LDA   (POINT),Y
            JSR   CTRL?
            BCS   :DONT
            CPY   #$20        ;LAST CHAR?
            BNE   :DO         ;NOPE
            CPX   #$FF        ;DELETED FILE?
            BNE   :DO         ;NO: JUST COUT
            LDA   #$A0        ;YES:USE SPACE
:DO         JSR   PCOUT
:DONT       INY
            CPY   #$21
            BCC   :NXTCHAR
:CFILEQ     RTS
:LENGTH     DB    $21
*
PCFILE      LDY   #0
            LDA   (POINT),Y
            AND   #$0F
            BNE   :PCFL1
            LDA   #$0F
:PCFL1      STA   :LENGTH
            LDY   #1
:PCFL2      LDA   (POINT),Y
            BEQ   :PCFL3
            ORA   #$80
            JSR   PCOUT
            INY
            CPY   :LENGTH
            BCC   :PCFL2
            BEQ   :PCFL2
:PCFL3      RTS
:LENGTH     DB    $0
*
PRTBLK      JSR   PRHERE
            ASC   "Block $"
            DB    $0
            LDA   BLKNUM+1
            JSR   PHBYTE
            LDA   BLKNUM
            JSR   PHBYTE
            JMP   CROUT
*
*
* DISPLAY SLOT AND DRIVE
SEEDEV      PHA
            JSR   PRHERE
            ASC   "Slot "
            DB    $0
            PLA
            PHA
            AND   #$70
            LSR
            LSR
            LSR
            LSR
            JSR   PHHEX
            JSR   PRHERE
            ASC   "  Drive "
            DB    $0
            PLA
            ASL
            LDA   #1
            ADC   #0
            JMP   PHHEX
*
UILIBEND
