            TYP   BIN
            DSK   ../build/CATLN1.O
            PUT   VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/RDDATA.VARS
            ORG   RDDATAEND
CATLN1      
            ORG   *+3
*
            PHA
            LDX   SHOW        ;SET *POINT
            JSR   SETPNT
            PLA
            BIT   DOSNOW
            BPL   :CAT33
            JMP   PCATLN
*
:CAT33      LDY   #$02
            LDA   (POINT),Y   ;GET LOCKED
            BMI   :LOCKED     ;STATUS
            LDA   #" "        ;PRINT SPACE
            BNE   :SEELOCK
:LOCKED     LDA   #"*"        ;OR *
:SEELOCK    JSR   PCOUT
            JSR   FILTYP      ;FIND FILETYPE
            LDA   TYPCHR,X    ;PRINT FILTYP
            JSR   PCOUT       ;CHARACTER
            JSR   PRSPC       ;PRINT SPACE
            LDY   #$21        ;INDEX TO
            LDA   (POINT),Y   ;FILE SIZE
            STA   HEXNUM      ;PUT IN
            INY               ;CONVERT
            LDA   (POINT),Y   ;BUFFERS
            STA   HEXNUM+1
            JSR   HEXDEC      ;HEX->DECIMAL
            JSR   PRTLZ       ;PRINT DIGITS
            JSR   PRSPC       ;PRINT SPACE
            JSR   CFILE       ;SEE FILENAME
:OUT        RTS
:LENGTH     DB    $0
*
*
* FIND FILETYPE
*
FILTYP      EQU   *
            LDX   #$08
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
*
PCATLN      STA   :TYPE       ;CAT DPLY TYPE
            LDY   #$1E        ;ACCESS
            LDA   (POINT),Y
            LDX   #"?"
            CMP   #$81
            BEQ   :ISLOKD     ;'MAYBE' STATUS
            LDX   #"*"
            AND   #$C2
            BEQ   :ISLOKD     ;SAY LOCKED ONLY IF 3 BITS OFF
            LDX   #" "
:ISLOKD     TXA
            JSR   PCOUT
            JSR   PCFILE
*
* DISPLAY FILE TYPE
*
            LDA   #" "
:TABLP1     JSR   PCOUT
            INY
            CPY   #$11
            BCC   :TABLP1
            LDY   #$10
            LDA   (POINT),Y
            JSR   PRTYPE
*
* DISPLAY # OF BLOCKS
*
            JSR   PRSPC
            LDY   #$13
            LDA   (POINT),Y
            STA   HEXNUM
            INY
            LDA   (POINT),Y
            STA   HEXNUM+1
            JSR   HEXDEC
            JSR   PRT5RJ
            JSR   PRSPC
*
* MODIFIED DATE
*
            LDY   #$22
            JSR   SHDAT0
            LDA   :TYPE
            CMP   #1
            BEQ   :MODTIM
:GODUN      RTS
*
* MODIFIED TIME
*
:MODTIM     LDY   #$24
            JSR   SHTIM0
*
* CREATION DATE
*
            JSR   PRSPC
            LDY   #$19
            JSR   SHDAT0
*
* CREATION TIME
*
            LDY   #$1B
            JSR   SHTIM0
*
* ENDFILE
*
            JSR   PRSPC
            LDY   #$17
            LDX   #2
:EFLP       LDA   (POINT),Y
            STA   HEXNUM,X
            DEY
            DEX
            BPL   :EFLP
            JSR   HEXDC3
            JSR   PRT8RJ
*
* SUBTYPE
*
            JSR   PRSPC
            LDY   #$10
            LDA   (POINT),Y
            LDX   #:SUBS1-:SUBS-1
:SBTPLP     CMP   :SUBS,X
            BEQ   :GOTSUB
            DEX
            BPL   :SBTPLP
            RTS
*
:GOTSUB     LDA   :SUBS1,X
            PHA
            JSR   PCOUT
            LDA   #"="
            JSR   PCOUT
            PLA
            CMP   #"A"
            BNE   :RSUB
            LDA   #"$"
            JSR   PCOUT
            LDY   #$20
            LDA   (POINT),Y
            JSR   PHBYTE
            LDY   #$1F
            LDA   (POINT),Y
            JMP   PHBYTE
*
:RSUB       LDY   #$20
            LDA   (POINT),Y
            TAX
            DEY
            LDA   (POINT),Y
            JSR   HEXDC2
            JMP   PRT5RJ
*
:TYPE       DB    $0
:SUBS       DB    $04,$06,$FC,$FD,$FB,$FA,$B4,$B5,$B6
:SUBS1      ASC   "RAAAAAAAA"
*
CATLN1END
