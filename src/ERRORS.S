            TYP   BIN
            DSK   ../build/ERRORS.O
            PUT   VARS
            PUT   ../build/IO.VARS
            PUT   ../build/LINEINPUT.VARS
            ORG   LINEINPUTEND

* TSVALS    print current track and sector
* PRTTRK    print current track
* NOFIL0
* NOFILS
* NOSEL
* NOPRO
* FLONLY
* PRTPRS
* PRESS
* ERRMSG
* OUCH
* WDERR
* ERROU1
* ERROUT
* BLK2ER

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
ERRORSEND
