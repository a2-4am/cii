* LOCK/UNLOCK
* RENAME
* VERIFY
* DISK MAP
* CHANGE BOOT PROGRAM
* UNDELETE
* ALPHABETIZE
* SET PRINTER SLOT
*
**********************************
*      FILE LOCK/UNLOCK          *
*          & RENAME              *
**********************************
*
RENAME      LDA   #$03
            STA   STATE
            LDX   #9
            JSR   CHOOZ1
            CMP   #0
            BEQ   REN2         ;RENAME FILES
            JSR   COMHDR
            BIT   DOSNOW
            BMI   RENVOL
            JMP   NODOS3
*
LOCK        LDA   #$02
            STA   STATE
*
REN2        JSR   COMTRE
            JSR   CATDIS
            LDA   FILNUM
            BNE   :GOTFILS
            JMP   NOSEL
:GOTFILS    JMP   FIXSUB
*
* RENAME VOLUME
*
RENVOL      JSR   NEWVOL       ;GET NEW NAME
            BCS   ALOUT
            JSR   RDBLK2
            LDY   #0
:RNLOOP     LDA   VOLNAM,Y
            BEQ   :RN2
            STA   VTOC1+$5,Y
            INY
            BNE   :RNLOOP
*
:RN2        TYA
            ORA   #$F0
            STA   VTOC1+4
            JMP   DOWBLK
*
*
*
*
ASKLOK      LDA   #$67
            JSR   PRINT
:TRY        JSR   CASKEY
            CMP   #$9B
            BEQ   ALOUT        ;C IS SET
            LDX   #$FF
            CMP   #"L"
            BEQ   :DO
            CMP   #"U"
            BNE   :TRY
            INX                ;FF --> 0
:DO         JSR   PCOUT
            CLC
ALOUT       RTS
*
*
*************************************
*           VERIFY OPTIONS          *
*************************************
*
VERIFY      LDX   #$03
            JSR   CHOOZ1       ;SELECT VERIFY
            STA   :TEMP        ;OPTION.
            CMP   #1
            BNE   :NOTFIL
            JSR   COMTRE
            JMP   :VFILES
*
:NOTFIL     JSR   COMHDR
            LDA   :TEMP        ;JUMP TO
            BEQ   :VDISK       ;OPTION
            JMP   SPEED1
*
*
**********  VERIFY DISK  **********
*
:VDISK      LDA   #>DATA
            STA   RPAGE
            JSR   LOHERE
            ASC   "Verifying "
            DB    $0
            LDA   #0
            STA   :VERRORS
            STA   :VERRORS+1
            JSR   DEVTYP
            BNE   :PRODOS      ;NOT FLOPPY
            JMP   :DOS33
*
:PRODOS     LDA   #0
            STA   BLKNUM
            STA   BLKNUM+1
            JSR   GTBLKS
            STX   :BLKSLO
            STY   :BLKSHI
:BLKLP      JSR   CKESC
            LDA   #$15
            JSR   TABV
            LDA   #$0A
            STA   CH
            JSR   PRTBLK
            JSR   RDBLK
            BCS   :BLKERR
:NXTBLK     INC   BLKNUM
            BNE   :BLK2
            INC   BLKNUM+1
:BLK2       LDA   BLKNUM+1
            CMP   :BLKSHI
            BCC   :BLKLP
            LDA   BLKNUM
            CMP   :BLKSLO
            BCC   :BLKLP
            JMP   :TOTAL       ;DONE!
:BLKERR     INC   :VERRORS
            BNE   :BLKER1
            INC   :VERRORS+1
:BLKER1     LDA   #3
            STA   WNDTOP
            LDA   #$14
            STA   WNDBTM
            LDA   #$13
            JSR   VLEFT
            JSR   PRHERE
            ASC   "Error: "
            DB    $0
            JSR   PRTBLK
            JSR   SETTXT
            JMP   :NXTBLK
*
*
:DOS33      LDA   #$33         ;'TRACK'
            JSR   PRINT
            LDA   #$40         ;RATCHET!
            STA   RCMND        ;(SETS TRK 0)
            JSR   DORWTS
            LDA   #$10         ;SET VERIFY
            STA   RCMND
:TRACKLP    JSR   CKESC
            LDA   #$15
            JSR   TABV
            LDA   #$11         ;PRINT TRACK
            STA   CH           ;BEING
            LDA   RTRACK       ;VERIFIED
            JSR   PHBYTE
            JSR   PHRWTS       ;GO VERIFY
            BCC   :OK          ;ANY ERRORS?
*
            LDA   #$03         ;SET WINDOW
            STA   WNDTOP
            LDA   #$14
            STA   WNDBTM
            LDA   #$13
            JSR   VLEFT        ;POSITION
            JSR   CROUT2
            LDA   #$3A         ;'ERROR'
            JSR   PRINT
            JSR   PRSPC
            JSR   PRTTRK       ;'TRACK'
            JSR   CROUT
            LDA   #$34         ;'SECTOR'
            JSR   PRINT
            LDY   #$00
:BADLP      LDA   SOFAR,Y      ;GET SECTOR
            BMI   :NEXTBAD     ;BAD?
            LDA   INTLV1,Y
            JSR   PHHEX        ;PRINT NUMBER
            JSR   PRSPC
            INC   :VERRORS     ;INC ERROR
            BNE   :NEXTBAD     ;COUNT
            INC   :VERRORS+1
:NEXTBAD    INY                ;NEXT SECTOR
            CPY   #$10
            BCC   :BADLP
            JSR   SETTXT
*
:OK         INC   RTRACK       ;NEXT TRACK
            LDA   RTRACK
            CMP   #$23
            BCC   :TRACKLP
            BCS   :TOTAL
*
:BLKSLO     DB    $0
:BLKSHI     DB    $0
*
************  VERIFY FILES  ********
:VFILES     LDA   #$01
            STA   STATE
            JSR   CATDIS       ;SELECT FILES
            JSR   PATMOV
            LDA   FILNUM
            BNE   :GOTFILS
            JMP   NOSEL
:GOTFILS    JSR   SWPCHK
            JSR   HOME
            LDA   #$00
            STA   :VERRORS
            STA   :VERRORS+1
            STA   CURR
:VFILELP    JSR   FILEQ
            JSR   :V1FILE
            JSR   CKESC
            INC   CURR
            LDA   CURR
            CMP   FILNUM
            BNE   :VFILELP
:TOTAL      JSR   LOHERE
            ASC   "Total: "
            DB    $0
            LDX   :VERRORS+1
            LDA   :VERRORS
            JSR   HEXDC2
            JSR   PRT5LJ
            JSR   PRSPC
            LDA   #$3A         ;'ERROR'
            JSR   PRINT
            LDA   :VERRORS+1   ; LDA :VERRORS+1 <- The old
            BNE   :NOTONE      ; ORA :VERRORS
            LDX   :VERRORS     ; CMP #$01           doesn't work
            DEX                ; It mistakenly takes $0101 same as $0001.
            BEQ   :ONE
:NOTONE     LDA   #"s"
            JSR   PCOUT
:ONE        JMP   PRESS
*
************************
*
:V1FILE     JSR   OPNFIL
            BCS   :VOUCH
*
:CKDOS      BIT   DOSNOW
            BPL   :GOTTSL
*
:NOERR      LDA   #>DATA
            STA   RPAGE
            JSR   RDBLK
            BCS   :VOUCH
            JSR   FNBLK1
            BCC   :NOERR
            CMP   #$FF
            BEQ   :VOUCH
            RTS
*
:MORETS     LDA   SRCTSL+1
            STA   RTRACK
            LDA   SRCTSL+2
            STA   RSECTR
            JSR   RDTSL1
:GOTTSL     LDA   #>DATA
            STA   RPAGE
:RDMORE     LDX   STSP
            LDA   SRCTSL,X
            STA   RTRACK
            ORA   SRCTSL+$1,X
            BEQ   :NEXTRD
            LDA   SRCTSL+$1,X
            STA   RSECTR
            JSR   :VRWTS
            BCS   :V1FOUT
:NEXTRD     INC   STSP
            INC   STSP
            BNE   :RDMORE
            LDA   SRCTSL+1
            ORA   SRCTSL+2
            BNE   :MORETS
:V1FOUT     RTS
*
:VRWTS      JSR   CKESC
            LDA   RTRACK
            CMP   #$23
            BCS   :VOUCH
            LDA   RSECTR
            CMP   #$10
            BCS   :VOUCH
            JSR   PHRWTS
            BCC   :V1FOUT
:VOUCH      INC   :VERRORS
            BNE   :NOCARI2
            INC   :VERRORS+1
:NOCARI2    JSR   LOHERE
            DB    $0
            LDA   #$27
            STA   RRTN
            JSR   ERRMSG
            LDA   #$35
            JSR   PRINT
            LDA   RPAGE
            CMP   #>SRCTSL
            BEQ   :KEY
            LDX   CURR
            INX
            CPX   FILNUM
            BCS   :KEY
            LDA   #$3C
            JSR   PRINT
:KEY        JSR   KYESC
            PHA
            LDA   #$16
            JSR   VLEFT        ;CLEAR PROMPT
            JSR   PRHERE       ;(LEAVE ERROR)
            DB    $2F,$8D,$2F,0
            PLA
            CMP   #" "
            BEQ   :SET         ;IF EQUAL, CARRY WILL BE SET
            CLC
:SET        RTS
*
:VERRORS    DB    $0,$0
:TEMP       DB    $0
*
*
**********  DISK SPEED  *************
*
SPEED1      JSR   CROUT
            JSR   DEVTYP
            BEQ   :DOSPEED
            JMP   FLONLY
*
:DOSPEED    LDA   #$68
            JSR   PRINT
            LDA   UNIT
            JSR   SEEDEV
            JSR   CROUT2
            LDA   #$35
            JSR   PRINT
            JSR   KYESC
            JSR   HOME
            LDA   #$40         ;RATCHET!
            STA   RCMND
            JSR   DORWTS       ;(This call will enforce UDC 5.25 mode)
            LDA   #$22
            STA   RTRACK
            LDA   #$00
            STA   RCMND        ;SEEK TRK $22
            JSR   DORWTS
*LDX RSLOT
            LDX   HSLOT
            LDA   $C089,X      ;MOTOR BACK ON
            LDA   $C08D,X
            LDA   $C08E,X      ;WP CHECK
            BPL   :OK2
            LDA   $C08C,X      ;FAILED:
            LDA   $C088,X      ;MOTOR OFF,
            LDA   #$2B
            STA   RRTN
            JMP   OUCH
*
:OK2        JSR   CRIT1        ;ELSE WRITE
            LDA   #$69
            JSR   PRINT

:TEST       JSR   CRIT2        ;TIME IT.
            ASL   HEXNUM
            ROL   HEXNUM+1     ; * 2.
            LDA   HEXNUM+1     ;TOO BIG?
            BMI   :TEST        ;TRY AGAIN.
            STA   :SHIFTER+1
            LDA   HEXNUM
            STA   :SHIFTER
            LDA   #$3E         ; / $1.053E
            STA   :DIVER       ;=/  1.020477
            LDA   #$05
            STA   :DIVER+1
            LDX   #$10
:DIVLP      LSR   :SHIFTER+1   ;SHIFT DIVDEND
            ROR   :SHIFTER     ;BIT SMALLER
            ASL   :DIVER       ;DIVISOR BIT
            ROL   :DIVER+1     ;TO KNOCK OFF?
            BCC   :DIVNEXT     ;NO.
            LDA   HEXNUM       ;YES:SUBTRACT.
            SBC   :SHIFTER
            STA   HEXNUM
            LDA   HEXNUM+1
            SBC   :SHIFTER+1
            STA   HEXNUM+1
:DIVNEXT    DEX
            BNE   :DIVLP
            JSR   HEXDEC       ;-> 20,000
            LDA   #$09
            JSR   TABV
            LDA   #$0F
            STA   CH
            LDY   #3
:HEXLP      LDA   DIGIT+1,Y
            JSR   PHHEX
            DEY
            BNE   :HEXLP
            LDA   #"."
            JSR   PCOUT
            LDA   DIGIT+1
            JSR   PHHEX
            LDA   $C000        ;ESC?
            CMP   #$9B
            BNE   :TEST        ;NOT YET...
            STA   $C010
*LDX RSLOT
            LDX   HSLOT
            LDA   $C088,X      ;MOTOR OFF.
            RTS
*
*
:SHIFTER    DB    $00,$00
:DIVER      DB    $3E,$05
*
*
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
*
*
************************************
*     CHANGE BOOTING PROGRAM       *
************************************
*
BOOTPG      JSR   COMHDR
            LDA   #$04
            STA   STATE
            BIT   DOSNOW
            BPL   :DOS33
            JMP   NOPRO
*
:DOS33      LDX   #9           ;CHECK T01S09
            JSR   CHKWRAPR     ;FOR DOS
            BCC   :GOTSECT
            LDX   #7           ;CHECK T01S07
            JSR   CHKWRAPR     ;FOR PRONTO-DOS
            BCS   :NODOS
:GOTSECT    LDA   RSECTR       ;REAL DOS:
            STA   :NAMESEC
            JSR   CATDIS       ;SELECT NEW
            JSR   SWPCHK
            JSR   CURPNT       ;BOOT PROGRAM
            LDY   #$20
            LDX   #$1D
:COPYNAM    LDA   (POINT),Y    ;COPY FILENAME
            STA   DATA+$75,X   ;INTO DOS
            DEY                ;SECTOR
            DEX
            BPL   :COPYNAM
            LDX   :NAMESEC     ;RESET DOS
            JSR   PUTSEC       ;SECTOR
            INC   RCMND
            JSR   DORWTS       ;WRITE
            LDA   #0           ;RUN CMND
            STA   RTRACK       ;TRACK &
            LDA   T0SECT       ;SECTOR
            STA   RSECTR
            DEC   RCMND
            JSR   DORWTS       ;READ IT
            LDY   #$02
            LDX   #$14
            LDA   (POINT),Y    ;CHECK FILETYPE
            AND   #$7F         ;STRIP LOCK BIT
            BEQ   :POKERUN     ;& SET PROPER
            LDX   #$34         ;RUN CODE:
            CMP   #$04         ;0 -> 14
            BEQ   :POKERUN     ;4 -> 34
            LDX   #$06         ;ELSE -> 6
:POKERUN    STX   DATA+$42
            INC   RCMND
            JMP   DORWTS       ;WRITE BACK
*
:NODOS      LDA   #$6C
            JMP   PRTPRS
*
:NAMESEC    DB    $0
T0SECT      DB    $0
*
PUTSEC      STX   RSECTR       ;SET SECTOR
            LDA   #>DATA
            STA   RPAGE        ;SET ADDR
            LDA   #$01
            STA   RTRACK       ;SET TRACK
            STA   RCMND        ;SET COMMAND
            RTS
*
CHKWRAPR    TXA
            CLC
            ADC   #4           ;9->D,7->B
            STA   T0SECT
            JSR   PUTSEC       ;SET & READ
            JSR   DORWTS       ;DOS SECTOR
            LDX   #0
            LDY   #$FD
CHKDOS      LDA   #2
            STA   TEMP
:CHECKLP    LDA   DATA,Y       ;MATCH PATTERN
            CMP   :DOSPAT,X    ;TO VERIFY
            SEC
            BNE   :NO          ;DOS IS THERE
            INX
            INY
            DEC   TEMP
            BPL   :CHECKLP
            CLC
:NO         RTS
*
:DOSPAT     DB    $E0,$00,$F0,$A6,$2B,$BD
*
************************************
*        UNDELETE FILES            *
************************************
*
UNDEL       JSR   COMTRE
            LDY   #0
            STY   DELFLG
            INY
            STY   STATE
            JSR   CATDIS
            LDA   #$80
            STA   DELFLG
            JSR   PATMOV
            LDA   FILNUM
            BNE   :GOTFILS
            JMP   NOSEL
:GOTFILS    JSR   SWPCHK
            JSR   COMH00
            LDA   #$00
            STA   BADNUM
            STA   MAYBE
            STA   CURR
*
* ATTEMPT REGULAR UNDELETE OF DOS
* AND PRODOS FILES
*
:UNLOOP     JSR   FILEQ
            JSR   :UNDO
            JSR   CKESC
            INC   CURR
            LDA   CURR
            CMP   FILNUM
            BNE   :UNLOOP
*
            JSR   PATMOV       ;SQUISH LIST
            STX   NACTIV
            LDA   MAYBE
            BEQ   :CKBAD
*
* ATTEMPT 'SMART' UNDELETE OF
* 'MAYBE' FILES.
*
*
            JSR   COMH00
            LDA   #0
            STA   CURR
:SMARTLP    JSR   FILEQ
            LDX   CURR
            LDA   STATUS,X
            CMP   #$FE
            BNE   :ISBAD       ;UNRECOVERABLE
*
* FIRST, RECREATE FILE NAME AND
* STORAGE TYPE AND UNDELETE
* BLOCKS LEFT IN INDEX BLOCKS
*
            JSR   PUNDO0
*
* NOW TRY TO FIGURE OUT WHERE THE REST
* OF THE BLOCKS ARE AND UNDELETE THEM.
*
            JSR   SMART
*
:ISBAD      JSR   CKESC
            INC   CURR
            LDA   CURR
            CMP   FILNUM
            BCC   :SMARTLP
*
:CKBAD      LDA   BADNUM       ;ANY LOST
            BEQ   :OUT         ;FILES?
            JSR   HOME
            JSR   PATMOV
            LDA   #$03
            JSR   VLEFT
            JSR   PRHERE
            ASC   "Lost files:"
            DB    $8D,$8D,$0
            LDA   #$00
            STA   CURR
:PAGELP     LDA   #$0E         ;14 LINES/PAGE
            STA   :COUNT
:BADLP      DEC   :COUNT
            JSR   CURPNT
            JSR   CFILE        ;SEE FILE
            JSR   CROUT
            INC   CURR
            LDA   CURR
            CMP   FILNUM       ;NO MORE?
            BCS   :PRESS
            LDA   :COUNT       ;LINE COUNT?
            BNE   :BADLP
            LDA   #$52         ;CRESC1
            JSR   PRINT
            JSR   KYESC
            JSR   CROUT2
            JMP   :PAGELP
:PRESS      JMP   PRESS
:OUT        RTS
*
*
:UNDO       BIT   DOSNOW
            BPL   :DOS33
            JMP   PUNDO
*
:DOS33      LDA   #>SRCTSL
            STA   RPAGE        ;SET RWTS ADDR
            LDA   #$01
            STA   RCMND        ;& COMMAND
            JSR   CURPNT
            LDY   #$20         ;FIX UP
            LDA   (POINT),Y    ;CATALOG
            STA   TRACK        ;ENTRY
            STA   RTRACK
            LDY   #$00
            STA   (POINT),Y
            INY
            LDA   (POINT),Y
            STA   SECTOR
            STA   RSECTR
            LDY   #$20
            LDA   #" "
            STA   (POINT),Y
:TSLLP      JSR   :USEIT       ;ALLOCATE
            BCS   :CANT        ;TSLIST
            JSR   DORWTS
            LDA   #$0C
            STA   STSP
:PAIRLP     LDX   STSP
            LDA   SRCTSL,X
            STA   TRACK        ;FOR VALID
            ORA   SRCTSL+$1,X  ;TSPAIRS:
            BEQ   :NXTPAIR
            LDA   SRCTSL+$1,X  ;ALLOCATE
            STA   SECTOR       ;SECTORS FROM
            JSR   :USEIT       ;LIST
            BCS   :CANT
:NXTPAIR    INC   STSP
            INC   STSP
            BNE   :PAIRLP
            LDA   SRCTSL+1
            STA   TRACK
            STA   RTRACK       ;POINTER TO
            ORA   SRCTSL+2     ;NEXT TSLIST?
            BEQ   :DID
            LDA   SRCTSL+2     ;YES: LOOP
            STA   SECTOR       ;BACK
            STA   RSECTR
            JMP   :TSLLP
:DID        JSR   WRCAT1       ;WRITE FREED
            LDA   #$00         ;CATALOG
            BEQ   :MARKIT      ;ALWAYS
:CANT       JSR   RDCAT1       ;RE-READ IF
            INC   BADNUM       ;NO GOOD
            LDA   #$FF
:MARKIT     LDX   CURR         ;MARK FILE
            STA   STATUS,X     ;GOOD OR BAD
            RTS
*
:USEIT      LDA   SECTOR
            JSR   DOMASK
            LDA   TRACK        ;INDEX INTO
            ASL                ;BITMAP
            ASL
            ADC   #$38
            TAX
            LDA   VTOC1,X
            AND   BITMSK
            STA   :TEMP
            LDA   VTOC1+$1,X
            AND   BITMSK+1
            ORA   :TEMP
            SEC
            BEQ   :USED
            LDA   BITMSK
            EOR   #$FF
            AND   VTOC1,X
            STA   VTOC1,X
            LDA   BITMSK+1
            EOR   #$FF
            AND   VTOC1+$1,X
            STA   VTOC1+$1,X
            CLC
:USED       RTS
*
:TEMP       DB    $0
:COUNT      DB    $0
BADNUM      DB    $0
MAYBE       DB    $0
*
*
************************************
*       ALPHABETIZE CATALOG        *
************************************
*
ALPHA       JSR   COMTRE
            LDA   #$01
            STA   DELFLG
            JSR   RDACNT       ;READ FILES
            LDA   NACTIV
            BEQ   :NOFILES
            LDX   #$FF
            STX   CURR
:ALPHA1     INC   CURR         ;NEXT POSN TO
            LDX   CURR         ;ALPHABETIZE
            CPX   NACTIV       ;GOT EM ALL?
            BCS   :DUNALFA
            LDA   CBYTE,X      ;MAKE THIS
            STA   POINT2       ;FILE CHOICE
            LDA   CSECTR,X     ;FOR NOW
            STA   POINT2+1
:SEARCH1    INX                ;LOOK AHEAD
            CPX   NACTIV       ;NO FILES TO
            BCS   :SWAPALF     ;COMPARE WITH?
            JSR   SETPNT       ;POINT AT IT.
            JSR   CKDEL
            BCS   :SEARCH1
            LDA   (POINT2),Y
            JSR   CKDEL1
            BCS   :CHOICE
            LDA   (POINT2),Y
            AND   #$0F
            STA   :LAST2       ;LENGTH OF POINT2 NAME
            LDA   (POINT),Y    ;ANTICIPATE PRODOS
            AND   #$0F
            STA   :LAST
            BIT   DOSNOW
            BMI   :COMP0       ;Y ALREADY 0
            LDA   #$20
            STA   :LAST2
            STA   :LAST
            LDY   #$02
:COMP0      INC   :LAST2
:COMPARE    CPY   :LAST        ;EXACT MATCH?
            BCS   :CHOICE      ;YES: SWAP (MIGHT BE F12 & F1)
            INY
            CPY   :LAST2       ;PAST LENGTH OF POINT2?
            BCS   :SEARCH1     ;YES: SKIP IT
            LDA   (POINT),Y    ;COMPARE CHARS
            CMP   (POINT2),Y
            BEQ   :COMPARE     ;UNTIL DIFF.
            BCS   :SEARCH1     ;FORGET IF HI.
:CHOICE     LDA   POINT        ;IF LOWER MAKE
            STA   POINT2       ;IT THE NEW
            LDA   POINT+1      ;CHOICE.
            STA   POINT2+1
            BNE   :SEARCH1     ;(ALWAYS)
*
:NOFILES    JMP   NOFIL0
*
* PUT CHOSEN ENTRY INTO POSITION
:SWAPALF    JSR   CURPNT       ;POINT AT POSN
            LDY   #$22
            BIT   DOSNOW
            BPL   :SWAPLP
            LDY   #$26
:SWAPLP     LDA   (POINT),Y    ;SWAP WITH
            TAX                ;CHOICE
            LDA   (POINT2),Y
            STA   (POINT),Y
            TXA
            STA   (POINT2),Y
            DEY
            BPL   :SWAPLP
            BMI   :ALPHA1      ;(ALWAYS)
*
*
* SEE ALPHABETIZED CATALOG
:DUNALFA    LDX   #$00
            STX   SHOW
:COUNTIT    LDA   #$14         ;20 FILES/SCRN
            STA   :COUNT
:SEEALFA    JSR   SETPNT
            JSR   CKDEL        ;DELETED?
            BCS   :NXTFILE     ;YES:DONT SHOW
            LDA   #$FF         ;SHORT DISPLAY
            JSR   CATLIN       ;NO:SHOW
            JSR   CROUT
            DEC   :COUNT       ;& COUNT
:NXTFILE    INC   SHOW         ;NEXT FILE
            LDX   SHOW
            CPX   NACTIV       ;SEEN EM ALL?
            BCS   :DUNSEE      ;YES.
            LDA   :COUNT       ;NO:PAGE FULL?
            BNE   :SEEALFA     ;NO.
            JSR   KYESC        ;YES:KEYPRESS.
            JMP   :COUNTIT     ;COUNT MORE.
*
* ASK TO SAVE IT
:DUNSEE     JSR   PRHERE
            DB    $8D
            ASC   "[G]-Go, [Esc]-Exit"
            DB    $0
            JSR   GETKEY
            CMP   #"G"
            BEQ   FIXSUB
:ALPHAQ     RTS
*
:ORDER      DB    $0
:COUNT      DB    $0
:LAST       DB    $0
:LAST2      DB    $0
*
*
*
* *FIXSUB IS CALLED BY LOCK/UNLOCK,
* RENAME AND ALPHABETIZE TO MAKE
* THE NEEDED CHANGES TO THE SUBDIR
* HEADER. HEADER NAME, ACCESS AND
* PARENT POINTERS ARE UPDATED.
*
FIXSUB      JSR   SWPCHK
            BIT   DOSNOW
            BPL   :FXSB1       ;NOT PRODOS
*
            LDA   #0
            STA   CURR
:FXLOOP     JSR   CURPNT
            JSR   :FIXSUB
            INC   CURR
            LDA   CURR
            CMP   NACTIV
            BNE   :FXLOOP
*
:FXSB1      JMP   WRCAT1
*
:OUT        RTS
:FIXSUB     JSR   DIR?
            BCS   :OUT         ;NOT SUBDIR
            LDA   #>DATA       ;TEMP BUFFER
            STA   POINT2+1
            STA   RPAGE
            LDA   #4
            STA   POINT2
*
* READ 1ST BLOCK OF SUBDIR
*
            LDY   #$11
            LDA   (POINT),Y
            STA   BLKNUM
            INY
            LDA   (POINT),Y
            STA   BLKNUM+1
            JSR   RDBLK
            BCS   :OUT
*
* COPY FILENAME TO HEADER NAME
*
            LDY   #$0F
:FSLP1      LDA   (POINT),Y
            STA   (POINT2),Y
            DEY
            BNE   :FSLP1
            LDA   (POINT),Y
            AND   #$0F
            ORA   #$E0
            STA   (POINT2),Y
*
* DON'T NEED TO CHANGE ACCESS BYTE
* BECAUSE PRODOS DOESN'T.
*
* LDY #$1E
* LDA (*POINT),Y
* STA (*POINT2),Y
*
* SET UP PARENT POINTERS
*
            LDA   POINT+1
            AND   #$FE
            CMP   #>SDIR       ;14
            BNE   :FS2         ;NOT 1ST
            LDA   DIRBLK
            LDX   DIRBLK+1
            JMP   :FS3
*
:FS2        SEC
            SBC   #$2
            STA   TEMP+1
            LDA   #0
            STA   TEMP
            LDY   #3
            LDA   (TEMP),Y     ;PARENT BLK HI
            TAX
            DEY
            LDA   (TEMP),Y     ;PARENT BLK LO
:FS3        LDY   #$23
            STA   (POINT2),Y
            INY
            TXA
            STA   (POINT2),Y
*
* FIGURE OUT PARENT ENTRY NUMBER
*
            LDY   #$26
            LDA   (POINT2),Y   ;ENTRY LENGTH
            STA   TEMP
*
            LDA   POINT
            LDX   #1
:FS4        CMP   #4
            BEQ   :FS5
            SEC
            SBC   TEMP
            INX
            BNE   :FS4         ;ALWAYS
*
:FS5        TXA
            DEY
            STA   (POINT2),Y
*
* WRITE SUBDIR BLOCK BACK
*
            JMP   WTBLK
*
*
COMTRE      JSR   DODEVP
            JSR   TREEA
            JSR   COMH00
CT1         BIT   DOSNOW
            BPL   CTOUT        ;DOS 3.3
            LDA   RRTN
            BEQ   CTOUT        ;NO ERROR
            CMP   #$52
            BEQ   CTERR1
            CMP   #$40
            BCC   CTERR        ;I/O ERROR
CTOUT       RTS
*
* BLOCK 2 ERROR
*
CTERR       JMP   BLK2ER
*
* NOT A DOS OR PRODOS DISK
*
CTERR1      JMP   WDERR
*
COMHDR      JSR   DODEVP
            JSR   SETA
            JSR   COMH00
            LDA   CHOICE
            CMP   #7           ;VERIFY DISK?
            BNE   CT1          ;NO
            RTS

COMH00      JSR   TOP1
            JMP   PRVNM
OPTCHS      DB    $0
*
*************************************
*        CHANGE PRINTER SLOT        *
*************************************
*
INFO        LDA   #$16
            JSR   TABV
            LDA   #$21
            STA   CH
            LDA   #$2A
            JSR   PRINT
            LDA   PSLOT
            JSR   PHHEX
*
            LDA   #$26
            STA   CH
:GETCHAR    JSR   KEYESC
            CMP   #$8D         ;CR?
            BEQ   :DEFAULT
            SEC
            SBC   #$B0         ;CONVERT TO #
            CMP   #8
            BCS   :ERR
            STA   PSLOT
            JMP   PHHEX        ;PRINT IT
*
:ERR        JSR   BELL         ;TRY AGAIN
            JMP   :GETCHAR
*
:DEFAULT    LDA   (BASL),Y     ;REMOVE FLASH
            AND   #$3F
            ORA   #$80         ;FROM EXISTING
            STA   (BASL),Y     ;CHAR
            RTS
