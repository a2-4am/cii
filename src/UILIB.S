            TYP   BIN
            DSK   ../build/UILIB.O
            PUT   VARS
            PUT   ../build/PHRWTS.VARS
            PUT   ../build/MESSAGES.VARS
            PUT   ../build/IO.VARS
            ORG   IOEND

* TOP1      clear screen and display function title
* DODEVF
* DODEVP
* PRVNM     print current slot+drive (if DOS)
*           or current prefix (if ProDOS)
* TSVALS    print current track and sector
* PRTTRK    print current track
* PRTBLK    print current block
* PRTFL1    print current prefix
* PRTFIL    print current prefix + filename
* CFILE     print current filename
* PCFILE    print current filename (ProDOS)
* SEEDEV    print slot and drive
* NOSEL
* NOFIL0
* NOFILS
* PRTPRS
* PRESS
* ERRMSG
* OUCH

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
* PRINT TRACK & SECTOR #'S
TSVALS      JSR   PRTTRK
            JSR   PRHERE
            ASC   ", "
            DB    $0
            LDA   #MSECTOR
            JSR   PRINT       ;'SECTOR $'
            LDA   RSECTR      ;SECTOR MORE
            CMP   #$10        ;THAN 1 DIGIT?
            BCS   JPHBYTE     ;YES:PRINTBYTE
            BCC   JPHHEX      ;NO:PRINTDIGIT
*
PRTTRK      LDA   #MTRACK
            JSR   PRINT       ;'TRACK $'
            LDA   RTRACK
JPHBYTE     EQU   *
            JMP   PHBYTE
JPHHEX      EQU   *
            JMP   PHHEX
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
* NO FILES TO WORK WITH
NOFIL0      LDA   #5
            JSR   VLEFT
* falls through to NOFILS
NOFILS      LDA   #MNOFILES
            BNE   PRTPRS      ;(ALWAYS)
*
* NO FILES SELECTED
NOSEL       JSR   LOWSET
            LDA   #MNOSEL
            DB    $2C
* NOT A PRODOS FUNCTION
NOPRO       LDA   #MNOPRO
            DB    $2C
* NOT A DISK II
FLONLY      LDA   #MFLONLY
* falls through to PRTPRS
*
* PRINT MESSAGE BY ID THEN RESTART PROGRAM
*
PRTPRS      JSR   PRINT
* falls through to PRESS
*
* PRESS A KEY THEN RESTART PROGRAM
*
PRESS       LDA   #MPRESS
            JSR   PRINT
            JSR   GETKEY
            JMP   ($3F2)
*
* PRINT BEST ERROR MESSAGE
* FOR ERROR CODE IN RRTN
*
ERRMSG      LDA   RRTN
            LDY   #$0C
:OUCHLP     CMP   :ERRNUM,Y
            BEQ   :OUCH0      ;FOUND ERROR # IN TABLE
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
            BNE   :SKIP1      ;ALWAYS (BECAUSE RRTN >= $29)
*
* These are CII-specific error codes, some
* of which happen to match ProDOS error codes.
* We search for the value of RRTN, and the
* match index is used to calculate the message ID
* to PRINT (simple +offset, see :OUCH0 below)
:ERRNUM     DB    $2B,$44,$45,$46,$48,$49,$4E,$3F,$52,$47
            DB    $40,$2F,$28
*
:OUCH0      JSR   CROUT2
            TYA
            CLC
            ADC   #MERRENUM
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
*
WDERR       LDA   #$52
ERROU1      STA   RRTN
ERROUT      JSR   CROUT
            JSR   OUCH
            JMP   ($3F2)
*
BLK2ER      LDY   #0
            STY   BLKNUM+1
            DEY
            STY   DOSNOW
            LDA   #2
            STA   BLKNUM
            JMP   ERROUT
*
OUCH        JSR   HOME
            JSR   ERRMSG
            JSR   CROUT
            JSR   CLOSE
            LDA   #MPRESS
            JSR   PRINT
            JMP   GETKEY
*
UILIBEND
