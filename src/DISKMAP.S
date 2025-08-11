************************************
*            DISK MAP              *
************************************
*
TSMAP       JSR   COMHDR
            JSR   DOC00E
            JSR   DEVTYP
            BEQ   :DISKII
            JMP   FLONLY       ;NOT DISK II
*
:DISKII     JSR   CROUT2
            JSR   RDACNT       ;READ CATALOG
            LDA   NACTIV       ;ANY FILES?
            BNE   :GOTFILS
            LDA   #$36         ;'NO FILES'
            JSR   PRINT
            LDA   #$52         ;CRESC1
            JSR   PRINT        ;CR OR ESC
            JSR   KYESC
            JMP   :CBITMAP
*
:GOTFILS    JSR   ASKPR?
*
:CBITMAP    BIT   DOSNOW
            BPL   :CBIT33
            LDA   #>DATA
            STA   HIMEM
            JSR   READBM
:CBIT33     JSR   HOME
            LDA   #$6A
            JSR   PRINT
            JSR   :CLEAR
            LDA   #0
            STA   SP
            STA   TEMP
:SECLP      LDA   TEMP
            CLC
            ADC   #6
            JSR   VLEFT
            LDA   #1
            STA   CH
            LDY   TEMP
            LDA   SECS,Y
            BIT   DOSNOW
            BMI   :ISPRO
            TYA
:ISPRO      JSR   PHHEX
            INC   TEMP
            LDA   TEMP
            CMP   #$10
            BCC   :SECLP
*
:DOS3       LDA   #$03
            STA   CH
            LDY   #$00         ;TRACK INDEX
:TRKLP      LDA   #$06         ;POSITION EACH
            JSR   TABV         ;TRACK
            LDA   #$00
            STA   SECTOR       ;SECTOR INDEX
:SECTLP     BIT   DOSNOW
            BPL   :BM33
*
            TYA
            LSR
            LSR
            TAX
            LDA   DATA,X
            PHA
            LDA   SECTOR
            LSR
            TAX
            PLA
            AND   BITS,X
            JMP   :CKUSE
*
:BM33       JSR   DOMASK
            LDA   VTOC1+$38,Y  ;IS SECTOR
            AND   BITMSK       ;FREE?
            STA   :TEMP
            LDA   VTOC1+$39,Y
            AND   BITMSK+1
            ORA   :TEMP
:CKUSE      BNE   :NOTUSE
:INUSE      LDA   #$2A         ;INVERSE *
            JSR   PCOUT
            DEC   CH
:NOTUSE     LDA   #$8A
            JSR   PCOUT
            INC   SECTOR       ;NEXT SECTOR
            LDA   SECTOR
            CMP   #$10
            BCC   :SECTLP
            INC   CH           ;NEXT TRACK
            INY
            INY
            INY
            INY
            CPY   #$8C
            BCC   :TRKLP       ;DONE BITMAP
            JSR   :PRSCRN      ;PRINT SCREEN?
            LDA   #$35         ;PROMPT TO
            JSR   LINE24       ;CONTINUE
            JSR   KYESC
            LDA   NACTIV
            BNE   :CONTIN
            JMP   FILER
*
*
* DISPLAY MAP FOR EACH FILE
*
:CONTIN     LDA   #$00
            STA   CURR
:CONTIN1    JSR   SWPCHK
:FILELP     LDA   #0
            STA   SIB
            STA   SIB+$100
            STA   SMIB
            STA   SMIB+$100
            JSR   OPNSRC
            JSR   :CLEAR
            BIT   DOSNOW
            BMI   :PROMAP
*
* DOS 3.3 FILE MAPPING
*
            LDX   #$2A
            STX   :CHAR
            JSR   PRTFIL
:DOLIST     LDA   RSECTR
            JSR   :PLOPSEC     ;T&S LIST
            BCC   :PAIRIT
            JMP   :NXTFILE
*
* PLOP ENTIRE T & S LIST
*
:PAIRIT     LDX   #$0C
:PAIRLP     LDA   SRCTSL,X
            STA   RTRACK
            LDA   SRCTSL+$1,X  ;& MARKING
            JSR   :PLOPSEC     ;SECTORS ON
            INX                ;USE MAP
            INX
            BNE   :PAIRLP
*
            LDA   SRCTSL+1
            STA   RTRACK
            ORA   SRCTSL+2     ;(MORE TSLIST?)
            BEQ   :NXTFILE     ;NO
            LDA   SRCTSL+2
            STA   RSECTR
            LDA   #>SRCTSL
            STA   RPAGE
            JSR   DORWTS
            JMP   :DOLIST
*
*
* PRODOS FILE MAPPING
*
:PROMAP     JSR   PRTFIL
            JSR   CLREOL
*
            LDX   #$2A         ;INVERSE *
            JSR   DIR?
            BCS   :NOT
            LDX   #$04         ;INVERSE D
:NOT        STX   :CHAR
            LDY   #$11
            LDA   (POINT),Y    ;KEY LO
            PHA
            INY
            LDA   (POINT),Y    ;KEY HI
            TAY
            PLA
            JSR   :PLOPBLK
:PRO1       LDX   MIBPTR
            LDA   SMIB,X
            LDY   SMIB+$100,X
            JSR   :PLOPBLK
            LDA   BLKNUM
            LDY   BLKNUM+1
            JSR   :PLOPBLK
            JSR   FNDBLK
            BCC   :PRO1
            BCS   :NXTFILE
*
*
:PREV       DEC   CURR
            BPL   :GOFILP
            LDA   #0
            STA   CURR
*
:NXTFILE    LDA   #$17
            JSR   VLEFT
            LDA   #$6B
            JSR   PRINT
            JSR   CHKKEY
            BNE   :NOTARO
            BCS   :NEXT
            BCC   :PREV
*
:NOTARO     CMP   #"P"
            BEQ   :PRINT
            BIT   DOSNOW
            BPL   :NXTFILE
            AND   #$EF
            CMP   #"."
            BEQ   :DO1
            CMP   #$AC         ;","
            BNE   :NXTFILE
:DO2        JSR   DIVOUT
            BCS   :ERR1
:COM1       JSR   RDACNT
            LDA   NACTIV
            BEQ   :MTSUB
            JMP   :CONTIN1
*
:GOFILP     JMP   :FILELP
*
:DO1        JSR   DIVEIN
            BCC   :COM1
:ERR1       JSR   LINE24
            JSR   GETKEY
            JMP   :NXTFILE
*
:NEXT       INC   CURR
            LDA   CURR
            CMP   NACTIV
            BCC   :GOFILP
            DEC   CURR
            BCS   :NXTFILE     ;ALWAYS
*
:PRINT      JSR   :PRSCRN
            JMP   :NXTFILE
*
:MTSUB      LDA   #$53         ;EMPTY SUBDIR
            JSR   LINE24
            JSR   GETKEY
            JMP   :DO2
*
:CLEAR      LDA   #5
            JSR   VLEFT
:CLRLP      JSR   CROUT
            LDA   #3
            STA   CH
            LDY   #$22
:BLOCKLP    LDA   #"."
            JSR   PCOUT
            DEY
            BPL   :BLOCKLP
            JSR   CLREOL
            LDA   CV
            CMP   #$15
            BCC   :CLRLP
            RTS
*
*
*
:BLKOUT     PLA
            RTS
:PLOPBLK    PHA
            STY   RTRACK
            ORA   RTRACK
            BEQ   :BLKOUT
            PLA
            PHA
            LSR   RTRACK
            ROR
            LSR   RTRACK
            ROR
            LSR   RTRACK
            ROR
            STA   RTRACK
            PLA
            AND   #$07
            ASL
            PHA
            JSR   :PLOPSEC
            PLA
            CLC
            ADC   #1
*
* PLOP FILE LETTER INTO SECTOR ON MAP
:PLOPSEC    STX   :TEMPX       ;SAVE XREG
            STA   RSECTR
            ORA   RTRACK
            BEQ   :NOPLOP0
            LDA   RSECTR
            CMP   #$10
            BCS   :INVALID
            ADC   #$06
            JSR   TABV         ;FIND VTAB
            LDA   RTRACK
            CMP   #$23
            BCS   :INVALID
            ADC   #$03         ;& HTAB
            STA   CH
            TAY
:PLOP       LDA   :CHAR
            STA   (BASL),Y     ;PUT ON SCREEN
:NOPLOP0    CLC
:NOPLOP1    LDX   :TEMPX       ;RESTORE XREG
:NOPLOP     RTS
:CHAR       DB    $0
*
* INVALID TRACK OR SECTOR NUMBER
:INVALID    LDA   #$17
            JSR   VLEFT
            INC   WNDBTM
            JSR   PRHERE
            ASC   "Invalid: "
            DB    $2F,0
            BIT   DOSNOW
            BMI   :INVPRO
            JSR   TSVALS       ;PRINT T&S
            SEC
            BCS   :INVCOM
:INVPRO     JSR   PRTBLK
:INVCOM     DEC   WNDBTM
            JSR   KYESC
            SEC
            BCS   :NOPLOP1
*
*
* PRINTER SCREEN DUMP FOR T/S MAP
:PRSCRNQ    RTS
:PRSCRN     LDA   PRNTR?
            BEQ   :PRSCRNQ
* COPY SCREEN UP
            LDA   #$16         ;STARTLASTLINE
            STA   :VCOUNT
:UP         LDA   :VCOUNT
            JSR   :PRTAB
            LDY   #$27         ;LAST CHAR
:UP2        LDA   (BASL),Y     ;COPY UP
            STA   (POINT),Y
            DEY                ;BACK UP
            BPL   :UP2
            DEC   :VCOUNT      ;BACK UP
            BPL   :UP
* PRINT SCREEN IMAGE
            JSR   PRON         ;PRINTER ON
            JSR   CROUT
            LDA   #$00
            STA   :VCOUNT
:PR         JSR   :PRTAB       ;DATA VTAB
            LDY   #$00
:PR2        LDA   (POINT),Y    ;GET CHAR
            CMP   #$20         ;INVERSE SPACE
            BNE   :PR3
            LDA   #"*"         ;-> '*'
:PR3        JSR   PCOUT        ;PRINT CHAR
            INY
            CPY   #$28         ;NEXT
            BCC   :PR2
            JSR   CROUT        ;PRINT CR
            INC   :VCOUNT      ;NEXT LINE
            LDA   :VCOUNT
            CMP   #$16
            BCC   :PR
            JSR   PROFF
* PUT SCREEN BACK (GENTLY)
            DEC   :VCOUNT
:DOWN       LDA   :VCOUNT
            JSR   :PRTAB
            LDY   #$27
:DOWN2      LDA   (POINT),Y
            STA   (BASL),Y
            DEY
            BPL   :DOWN2
            DEC   :VCOUNT
            BPL   :DOWN
            RTS
*
:PRTAB      JSR   TABV
            LDA   BASL
            STA   POINT
            CLC
            LDA   BASL+1
            ADC   #$38         ;<-
            STA   POINT+1
            RTS
*
:COUNT      DB    $0
:TEMPX      DB    $0
:LETTER     DB    $0
:TEMPH      DB    $0
:TEMPV      DB    $0
:TEMP       DB    $0
:VCOUNT     DB    $0
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
            BCS   :PRO1        ;NO FILE NAME
            JSR   CFILE
:PRO1       LDA   PRNTR?
            BNE   :DOS33A      ;DON'T CLREOL
            JMP   CLREOL
*
:DOS33      LDA   #2
            JSR   VLEFT
            JSR   PRHERE
            ASC   "File: "
            DB    $2F,0
            PLP
            BCS   :DOS33A
            JMP   CFILE
:DOS33A     RTS
*
PRTBLK      JSR   PRHERE
            ASC   "Block $"
            DB    $0
            LDA   BLKNUM+1
            JSR   PHBYTE
            LDA   BLKNUM
            JSR   PHBYTE
            JMP   CROUT
