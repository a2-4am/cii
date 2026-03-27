            TYP   BIN
            DSK   ../build/UILIB.O
            PUT   VARS
            PUT   ../build/PHRWTS.VARS
            PUT   ../build/PRODOS.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/LINEINPUT.VARS
            ORG   LINEINPUTEND
*
**********************************
*           UI LIBRARY           *
* TOP1 - clear screen and display function title
* DODEVP - print header, select device
* DODEV - select device
* PRVNM - print current slot+drive (if DOS)
*         or current prefix (if ProDOS)
* PRTBLK - print current block
* PRTFL1 - print current prefix
* PRTFIL - print current prefix + filename
* CFILE - print current filename
* SEEDEV - print slot and drive
**********************************
*
*
* CLEAR SCREEN AND DISPLAY FUNCTION TITLE
*
TOP1
            JSR   HOME
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
* takes DEVFLG value in A
*   FF=format, 00=not format
DODEVP
            STA   DEVFLG
            JSR   HOME
            JSR   PRHERE
            ASC   "Select device:"
            DB    $0
            LDA   CURDVA
            JSR   DODEV
            STX   CURDVA
            RTS
*
* alternate entry point called by COPY
* which prints its own headers for
* 'source device' and 'target device'
DODEV
            STA   CURDEV
            LDA   #0
            STA   VOLFLG
            LDA   #$FF
            STA   DOSNOW      ;ASSUME PRODOS
            JSR   LOHERE
            ASC   "Press [?] to display volume names"
            DB    $0
:DEVMNU     JSR   :SEEDEVS
:KEYORD     JSR   CHKKEY
            BNE   :NOTARO
            BCS   :DRIGHT
            BCC   :DLEFT
:NOTARO     CMP   #"?"
            BEQ   :GETVOLS
            CMP   #"/"
            BEQ   :GETVOLS
            CMP   #"1"
            BCC   :NOTNUM
            CMP   #":"
            BCC   :NUM
:NOTNUM     CMP   #$8D
            BNE   :KEYORD     ;BAD KEY
*
:CHOOSE     LDX   CURDEV
            LDA   DVICES,X
            CMP   #$BF
* AND #$F0
* CMP #$B0                ;CHOOSE /RAM?
            BNE   :CHOOS0     ;NO
            LDA   ISAUX       ;/RAM ACTIVE?
            BPL   :CHOOS0     ;YES
            LDA   DEVFLG      ;CMD=FORMAT?
            BMI   :CHOOS0     ;YES
            JSR   BELL
            JMP   :DEVMNU
*
:CHOOS0     LDA   #2
            STA   DIRBLK
            LDA   #0
            STA   PFX+5
            STA   PFX
            STA   DIRBLK+1
            LDX   CURDEV
            LDA   DVICES,X
            AND   #$F0
            STA   UNIT
            RTS
*
:DLEFT      LDX   CURDEV
            DEX
            BPL   :DRGTQ
            LDX   NUMDEV
            JMP   :DRGTQ
*
:DRIGHT     LDX   CURDEV
            INX
            CPX   NUMDEV
            BEQ   :DRGTQ
            BCC   :DRGTQ
            LDX   #0
:DRGTQ      STX   CURDEV
            JMP   :DEVMNU
*
*
*
* '?' REQUEST TO SEE VOLUME NAMES
* DO ONLINE CALLS FOR EACH DEVICE
* TO GET CURRENT VOLUME NAMES
*
:GETVOLS    LDX   NUMDEV
:GETVLP     TXA
            ASL
            ASL
            ASL
            ASL
            STA   :ONLINE+2
            LDA   DVICES,X
            STA   :ONLINE+1
            CMP   #$BF
* AND #$F0
* CMP #$B0
            BNE   :GETVL0
            LDA   ISAUX
            BMI   :GETSKIP
:GETVL0     JSR   MLI
            DB    $C5
            DW    :ONLINE
:GETSKIP    DEX
            BPL   :GETVLP
            STX   VOLFLG      ;FF
            JMP   :DEVMNU
:ONLINE     DB    $2
            DB    $0
            DW    VOLNMS
:NUM        AND   #$07        ;[4am] backport v9 behavior
            ASL               ;to intelligently select slot/drive
            ASL               ;based on digit pressed
            ASL
            ASL
            STA   :NUMTEMP
            CMP   #$30
            BCC   :NUM2SLT
:NUM2DRV    LDX   #0
]NUMLOOP    LDA   DVICES,X
            AND   #$F0
            CMP   :NUMTEMP
            BEQ   :GOODNUM
            INX
            CPX   NUMDEV
            BCC   ]NUMLOOP
            BEQ   ]NUMLOOP
            JMP   :KEYORD     ;no match
:GOODNUM    STX   CURDEV
            JMP   :DEVMNU
:NUM2SLT    LDX   #0
]NUMLOOP    LDA   DVICES,X
            AND   #$70
            CMP   #$30
            BCC   :NUM2DRV
            INX
            CPX   NUMDEV
            BCC   ]NUMLOOP
            BEQ   ]NUMLOOP
            LDA   :NUMTEMP
            CMP   #$10
            PHP
            LDX   CURDEV
            LDA   DVICES,X
            AND   #$70
            PLP
            BEQ   :NOORA
            ORA   #$80
:NOORA      STA   :NUMTEMP
            JMP   :NUM2DRV
*
*
:SEEDEVS    LDA   #2
            JSR   VLEFT
            LDX   #0
            STX   :SHODEV
:DEVLP      CPX   CURDEV
            BNE   :NOTDEV
            JSR   PINVRS
:NOTDEV     LDA   DVICES,X
            PHA
            JSR   SEEDEV
            PLA
            CMP   #$BF
* AND #$F0
* CMP #$B0
            BNE   :NOTDV0
            LDA   ISAUX
            BPL   :NOTDV0
            JSR   PRHERE
            ASC   ": /RAM disconnected"
            DB    $0
            JMP   :NOVOL
*
:NOTDV0     LDA   VOLFLG
            BEQ   :NOVOL
*
* DISPLAY VOLUME NAMES
*
            JSR   PRHERE
            ASC   ": "
            DB    $0
            LDA   :SHODEV
            JSR   :SEEVOL
            JSR   CLREOL
:NOVOL      JSR   PNORML
            JSR   CROUT
            INC   :SHODEV
            LDX   :SHODEV
            CPX   NUMDEV
            BEQ   :DEVLP
            BCC   :DEVLP
            RTS
:SHODEV     DB    $0
*
*
*
*
* DISPLAY VOLUME NAME
* A = INDEX INTO DEVICE LIST (0 - F)
*
:SEEVOL     ASL
            ASL
            ASL
            ASL
            TAX
            LDA   VOLNMS,X
            AND   #$0F
            BNE   :NAMEOK
            LDA   VOLNMS+$1,X
            CMP   #$52
            BNE   :SEEVOLQ
            LDX   :SHODEV
            JSR   DVTYPX
            BEQ   :SEEDII     ;DISK II
            JSR   PRHERE
            ASC   "non-ProDOS"
            DB    $0
            RTS
*
:SEEDII     JSR   PRHERE
            ASC   "DOS 3.3"
            DB    $0
            RTS
*
:NAMEOK     TAY
            LDA   #"/"
            JSR   PCOUT
:SEEVLP     LDA   VOLNMS+$1,X
            ORA   #$80
            JSR   PCOUT
            INX
            DEY
            BNE   :SEEVLP
:SEEVOLQ    RTS
:NUMTEMP    DB    $0
*
*
* SHOW CURRENT SLOT & DRIVE
* AND/OR CURRENT PREFIX. (*PFX<>0)
*
* RETURNS WITH CV = 3, CH = 0
*
PRVNM
            LDX   #PFX
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
PRTFL1
            SEC
            DB    $90
PRTFIL
            CLC
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
CFILE
            BIT   DOSNOW
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
*
PCFILE      EQU   *
            LDY   #0
            LDA   (POINT),Y
            AND   #$0F
            BNE   :PCFL1
            LDA   #$0F
:PCFL1      STA   :LENGTH
            LDY   #1
]PCFL2      LDA   (POINT),Y
            BEQ   :PCFLOUT
            ORA   #$80
            JSR   PCOUT
            INY
            CPY   :LENGTH
            BCC   ]PCFL2
            BEQ   ]PCFL2
:PCFLOUT    RTS
:LENGTH     DB    $0
*
PRTBLK
            JSR   PRHERE
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
SEEDEV
            PHA
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
