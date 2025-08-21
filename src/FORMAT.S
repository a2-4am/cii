            TYP   BIN
            DSK   ../build/FORMAT.O
            PUT   VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/DDISK.VARS
            PUT   ../build/ALPHABETIZE.VARS
            ORG   ALPHAEND
FORMAT      
            ORG   *+3

********************************
*          FORMAT DISK         *
********************************
*
            LDX   #UFORMAT
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
*GETVOL     
            JSR   PRHERE
            ASC   8D,8D,"V",00
            JSR   GVCOM       ;GET VOL NAME
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
FORMATEND
