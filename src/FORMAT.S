********************************
*          FORMAT DISK         *
********************************
*
FORMAT      LDX   #UFORMAT
            JSR   CHOOZ1      ;DOS OR PRODOS
            CMP   #0
            BEQ   :FPRODOS
            LDA   #$FF
:FPRODOS    EOR   #$FF
            STA   :TEMP
            STA   DOSNOW
            JSR   DODEVF
            JSR   COMH00
            LDA   UNIT
            JSR   SETSD
            JSR   DEVTYP
            BEQ   :ISRMV      ;IT'S A DISK II
*
:NOTDII     BIT   :TEMP
            BMI   :PRO1
            JMP   FLONLY
*
* NON-DISK II: CHECK IF REMOVABLE
*
:PRO1       TXA
            BPL   :NOTRMV
*
:ISRMV      JSR   PRHERE
            DB    $8D,$8D
            ASC   "Insert disk to format",8D,8D,00
            JMP   :COMRMV
*
:NOTRMV     JSR   PRHERE
            DB    $8D,$8D,$8D,$8D,$8D,$0
:COMRMV     JSR   PRHERE
            ASC   "Ready to format (Y/N) ? ",00
            JSR   CASKEY
            CMP   #"Y"        ;YES
            BNE   :GOFOUT
            JSR   HOME
*
* CHECK IF ALREADY FORMATTED
*
            JSR   DOSTYP
            STX   :XTEMP
            BCS   :DOIT       ;UNREADABLE
            LDX   CURDEV
            LDY   DVICES,X
            CPY   #$BF
            BNE   :NOTRAM
            LDY   ISAUX
            BMI   :DOIT       ;DISCONNECTED
*
:NOTRAM     PHA
            JSR   PRHERE
            DB    $8D,$8D
            ASC   "Destroy "
            DB    $0
            PLA
            BMI   :CKIT1      ;PRODOS
:NONPRO     JSR   PRHERE
            ASC   "non-ProDOS volume? "
            DB    $0
            JMP   :CKIT2
*
:CKIT1      LDX   :XTEMP
            LDA   VOLNMS,X
            AND   #$0F        ;NAME LEN
            BEQ   :NONPRO
            TAY
            LDA   #"/"
            JSR   PCOUT
:CKITLP     INX
            LDA   VOLNMS,X
            ORA   #$80
            JSR   PCOUT
            DEY
            BNE   :CKITLP
            JSR   PRHERE
            ASC   " ? "
            DB    $0
:CKIT2      JSR   CASKEY
            CMP   #"Y"
            BEQ   :DOIT
:GOFOUT     RTS
*

:DOIT       JSR   HOME
            LDA   :TEMP
            STA   DOSNOW
            BPL   :DOITNOW    ;DOS 3.3
*
* PROMPT USER FOR VOLUME NAME, UNLESS
* THE DEVICE IS /RAM
*
            JSR   DEVTYP
            CMP   #1          ;/RAM?
            BEQ   :DOITNOW    ;YES
            JSR   GETVOL      ;GET VOL NAME
            BCS   :GOFOUT     ;ABORT
*
*
:DOITNOW    JSR   PRHERE
            DB    $8D,$8D,$8D
            ASC   "  Formatting disk",8D,8D,00
            JSR   DEVTYP
            BEQ   :DODSK2     ;DISK II
*
* NOT A DISK II DEVICE. DOES IT
* SUPPORT FORMATTING?
*
            TXA
            AND   #8          ;SUPPORT FMT?
            BEQ   :DVFMT1     ;NO: DONE
*
*
:DOSPCL     JSR   SPLFRM
            BCS   :DVFMTX     ;ERROR
            JSR   DEVTYP
            CMP   #1          ;/RAM?
            BNE   :DVFMT1     ;NOPE
            STA   ISAUX       ;1-->*ISAUX
            LDA   #0          ;Can't get MM anymore.
            STA   GOTMM
:DVFMT1     JMP   :FORMDN
*
:DVFMTX     JMP   ERROUT      ;FMT ERROR
*
*
:DODSK2     LDA   #$40        ;RATCHET!
            STA   RCMND       ;(SETS TRK 0)
            JSR   PHRWTS      ;DON'T CARE IF ERROR
            LDA   #$04        ;FORMAT COMMAND
            STA   RCMND
:FORMLP     JSR   PHRWTS      ;FORMAT TRK.
            BCC   :FORMOK     ;ERROR?
            LDA   RRTN        ;YES:
            CMP   #$2B        ;WP?
            BNE   :NOTWP
            JMP   OUCH
:NOTWP      LDA   #MERROR     ;NO:PRINT
            JSR   LOWMES      ;ERROR
            JSR   PRSPC
            JSR   PRTTRK
            JMP   PRESS       ;GO AWAY.
:TEMP       DB    $0
:XTEMP      DB    $0
*
:FORMOK     INC   RTRACK
            LDA   RTRACK      ;NEXT TRK
            CMP   #$23
            BCC   :FORMLP
*
:FORMDN     JSR   DDISK
:FORMDN1    JSR   PRHERE
            DB    $8D,$8D
            ASC   "Formatting complete",8D,00
            JMP   PRESS
*
*
*
SPLFRM      LDA   #3
SPLGO1      STA   $42
            LDA   UNIT
            STA   $43
            LDA   #0
            STA   $46
            STA   $47
            STA   $44
            LDA   #>FILBUF
            STA   $45
SPLGO       LDA   GODEV+2
            CMP   #$D0
            BCC   :SKIP1
            LDA   $C08B
            LDA   $C08B
:SKIP1      JSR   GODEV
            STA   RRTN        ;4/5/86
            LDA   $C082
            RTS

*
NEWVOL      JSR   PRHERE
            DB    $8D,$8D
            ASC   "New "
            DB    $0
            JMP   GVCOM
GETVOL      JSR   PRHERE
            DB    $8D,$8D,$0
GVCOM       JSR   PRHERE
            ASC   "Volume Name: /"
            DB    $0
GVCOM1      LDA   #$0F
            STA   LINLIM
            JSR   GETLN
            BCS   :GVOUT
            LDY   #0
            LDX   #0
:DOIT1      LDA   LINEIN,Y
            CMP   #$8D
            BNE   :DOIT2
            LDA   #0
            BEQ   :DOIT3
:DOIT2      INY
            AND   #$7F
:DOIT3      STA   VOLNAM,X
            INX
            CPX   #$10
            BCC   :DOIT1
            LDA   VOLNAM
            BEQ   :GVOUT      ;C IS SET
            LDA   #0
            STA   VOLNAM+$0F
            CLC
:GVOUT      RTS
*
*
*
*
*
DDISK       BIT   DOSNOW
            BPL   :DDDOS33
            JMP   PDDISK
*
:DDDOS33    LDA   #>CAT1
            JSR   CLRCAT
            LDA   #$00
            TAX
:BLAHLP     STA   VTOC1,X     ;ZERO VTOC
            INX
            BNE   :BLAHLP
            LDX   #$11        ;SET NEEDED
            STX   VTOC1+1     ;PARAMETERS
            STX   VTOC1+$30
            STX   RTRACK
            DEX               ;10
            STX   VTOC1+$35
            DEX               ;F
            STX   RSECTR
            STX   VTOC1+2
            LDA   #$FE
            STA   VTOC1+6
            LDA   #$7A
            STA   VTOC1+$27
            LDA   #$23
            STA   VTOC1+$34
            LDA   #$FF
            LDX   #$3C        ;START AT TRK 1
:FFLOOP     STA   VTOC1,X     ;WRITE PART
            STA   VTOC1+$1,X
            INX               ;OF BITMAPS
            INX
            INX
            INX
            CPX   #$C4
            BCC   :FFLOOP
            LDX   #$00
            STX   VTOC1+$7C   ;ZERO CATALOG
            STX   VTOC1+$7D   ;BITMAP
            INX               ;1
            STX   VTOC1+$31
            STX   VTOC1+$37
            INX               ;2
            STX   RCMND
            INX               ;3
            STX   VTOC1+3
            LDA   #>CAT1
            STA   RPAGE
:LOOP       JSR   DORWTS      ;WRITE ENTIRE
            INC   RPAGE       ;TRACK
            DEC   RSECTR
            BNE   :LOOP
            LDA   #>VTOC1
            STA   RPAGE
            JSR   DORWTS
*
ZIPDOS      LDY   #$00
            LDA   $C083
:BOOTLP     LDA   $D000,Y
            STA   DATA,Y
            INY
            BNE   :BOOTLP
            LDA   $C082
            STY   RTRACK      ;0
            STY   RSECTR
            INY
            STY   DATA        ;1
            LDA   #>DATA
            STA   RPAGE
            JMP   DORWTS

