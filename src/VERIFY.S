            TYP   BIN
            DSK   ../build/VERIFY.O
            PUT   VARS
            PUT   ../build/PHRWTS.VARS
            PUT   ../build/PRODOS.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/UILIB.VARS
            PUT   ../build/READLIB.VARS
            PUT   ../build/DISKLIB.VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/DELLIB.VARS
            ORG   DELLIBEND
VERIFY
            ORG   *+3

*************************************
*           VERIFY OPTIONS          *
*************************************
*
            LDA   CHOOZOPT
            BNE   :NOTFIL
            JSR   COMTRE
            JMP   :VFILES
*
:NOTFIL     JSR   COMHDR
            DEC   CHOOZOPT    ;JUMP TO
            BEQ   :VDISK      ;OPTION
            JMP   :SPEED1
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
            BNE   :VPRODOS    ;NOT FLOPPY
            JMP   :VDOS33
*
:VPRODOS    LDA   #0
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
            JMP   :TOTAL      ;DONE!
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
:VDOS33     LDA   #MTRACK     ;'TRACK'
            JSR   PRINT
            LDA   #$40        ;RATCHET!
            STA   RCMND       ;(SETS TRK 0)
            JSR   DORWTS
            LDA   #$10        ;SET VERIFY
            STA   RCMND
:TRACKLP    JSR   CKESC
            LDA   #$15
            JSR   TABV
            LDA   #$11        ;PRINT TRACK
            STA   CH          ;BEING
            LDA   RTRACK      ;VERIFIED
            JSR   PHBYTE
                              ;GO VERIFY
            >>>   JSRMODULE,PHRWTSLIB;PHRWTSINTERNAL
            BCC   :OK         ;ANY ERRORS?
*
            LDA   #$03        ;SET WINDOW
            STA   WNDTOP
            LDA   #$14
            STA   WNDBTM
            LDA   #$13
            JSR   VLEFT       ;POSITION
            JSR   CROUT2
            LDA   #MERROR     ;'ERROR'
            JSR   PRINT
            JSR   PRSPC
            JSR   PRTTRK      ;'TRACK'
            JSR   CROUT
            LDA   #MSECTOR    ;'SECTOR'
            JSR   PRINT
            LDY   #$00
:BADLP      LDA   SOFAR,Y     ;GET SECTOR
            BMI   :NEXTBAD    ;BAD?
            LDA   INTLV1,Y
            JSR   PHHEX       ;PRINT NUMBER
            JSR   PRSPC
            INC   :VERRORS    ;INC ERROR
            BNE   :NEXTBAD    ;COUNT
            INC   :VERRORS+1
:NEXTBAD    INY               ;NEXT SECTOR
            CPY   #$10
            BCC   :BADLP
            JSR   SETTXT
*
:OK         INC   RTRACK      ;NEXT TRACK
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
            JSR   CATDIS      ;SELECT FILES
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
            LDA   #MERROR     ;'ERROR'
            JSR   PRINT
            LDA   :VERRORS+1  ; LDA :VERRORS+1 <- The old
            BNE   :NOTONE     ; ORA :VERRORS
            LDX   :VERRORS    ; CMP #$01           doesn't work
            DEX               ; It mistakenly takes $0101 same as $0001.
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
            JSR   RDTSL
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
            >>>   JSRMODULE,PHRWTSLIB;PHRWTSINTERNAL
            BCC   :V1FOUT
:VOUCH      INC   :VERRORS
            BNE   :NOCARI2
            INC   :VERRORS+1
:NOCARI2    JSR   LOHERE
            DB    $0
            LDA   #$27
            STA   RRTN
            JSR   ERRMSG
            LDA   #MCRESC
            JSR   PRINT
            LDA   RPAGE
            CMP   #>SRCTSL
            BEQ   :KEY
            LDX   CURR
            INX
            CPX   FILNUM
            BCS   :KEY
            JSR   PRHERE
            DB    $8D
            ASC   "[Space]-Next File ",00
:KEY        JSR   KYESC
            PHA
            LDA   #$16
            JSR   VLEFT       ;CLEAR PROMPT
            JSR   PRHERE      ;(LEAVE ERROR)
            DB    $FF,$8D,$FF,0
            PLA
            CMP   #" "
            BEQ   :SET        ;IF EQUAL, CARRY WILL BE SET
            CLC
:SET        RTS
*
:VERRORS    DB    $0,$0
*
*
*
************************************
*    DISK SPEED CRITICAL CODE      *
************************************
*
CRIT1       EQU   *
            PHP
            SEI
            LDA   #$1D        ;INIT HIBYTE
            STA   TEMP        ;OF COUNTER.
            LDA   #$FF        ;WP CHECK DONE
            STA   $C08F,X     ;WRITE MODE.
            CMP   $C08C,X
            PHA
            PLA
            NOP
            LDA   #$FF
]SPOT       =     *
:NOPAGE     PHA
            PLA
:LOOP       JSR   :WRITE7
            DEY
            BNE   :NOPAGE
            DEC   TEMP
            BNE   :LOOP
            CMP   $00
            JSR   :WRITE5
            PHA
            PLA
            NOP
            NOP
            LDY   #5
:D5LOOP     LDA   #$D5
            NOP
            NOP
            JSR   :WRITE0
            DEY
            BNE   :D5LOOP
            ERR   {*&$FF00}-{]SPOT&$FF00}
            LDA   #$FF
            JSR   :WRITE5
            LDA   $C08E,X
            LDA   $C08C,X
            PLP
:WRTS       RTS
*
:WRITE7     NOP
:WRITE5     NOP
            CMP   $00
:WRITE0     STA   $C08D,X
            CMP   $C08C,X
            RTS
*
CRIT2       EQU   *
            PHP
            SEI
            LDY   #$00        ;INIT COUNT
            STY   HEXNUM+1
            LDX   HSLOT
]SPOT       =     *
:LOOPD5     LDA   $C08C,X     ;WAIT FOR 'D5'
            BPL   :LOOPD5
            CMP   #$D5
            BNE   :LOOPD5
:NOTD5      LDA   $C08C,X     ;WAIT FOR NOND5
            BPL   :NOTD5
            CMP   #$D5
            BEQ   :NOTD5
:LOOP1      PHA               ;20 U-SEC LOOP
            PLA
:LOOP2      LDA   $C08C,X     ;20 U-SEC LOOP
            CMP   #$D5        ;DONE COUNTING?
            BEQ   :DONE
            INY
            BNE   :LOOP1
            INC   HEXNUM+1
            BNE   :LOOP2
            ERR   {*&$FF00}-{]SPOT&$FF00}
:DONE       STY   HEXNUM
            PLP
            RTS
*
*
**********  DISK SPEED  *************
*
:SPEED1     JSR   CROUT
            JSR   DEVTYP
            BEQ   :DOSPEED
            JMP   FLONLY
*
:DOSPEED    JSR   PRHERE
            DB    $8D,$8D,$8D
            ASC   "Insert a blank disk in ",00
            LDA   UNIT
            JSR   SEEDEV
            JSR   CROUT2
            LDA   #MCRESC
            JSR   PRINT
            JSR   KYESC
            JSR   HOME
            LDA   #$40        ;RATCHET!
            STA   RCMND
            JSR   DORWTS      ;(This call will enforce UDC 5.25 mode)
            LDA   #$22
            STA   RTRACK
            LDA   #$00
            STA   RCMND       ;SEEK TRK $22
            JSR   DORWTS
*LDX RSLOT
            LDX   HSLOT
            LDA   $C089,X     ;MOTOR BACK ON
            LDA   $C08D,X
            LDA   $C08E,X     ;WP CHECK
            BPL   :OK2
            LDA   $C08C,X     ;FAILED:
            LDA   $C088,X     ;MOTOR OFF,
            LDA   #$2B
            STA   RRTN
            JMP   OUCH
*
:OK2        JSR   CRIT1       ;ELSE WRITE
            JSR   PRHERE
            DB    $8D,$8D,$8D
            ASC   "Drive speed should be between 198.0 ms.",8D
            ASC   "and 202.0 ms.",8D,8D
            ASC   "Drive speed is       ms.",8D,8D
            ASC   "([Esc]-Exit)",00
:TEST       JSR   CRIT2       ;TIME IT.
            ASL   HEXNUM
            ROL   HEXNUM+1    ; * 2.
            LDA   HEXNUM+1    ;TOO BIG?
            BMI   :TEST       ;TRY AGAIN.
            STA   :SHIFTER+1
            LDA   HEXNUM
            STA   :SHIFTER
            LDA   #$3E        ; / $1.053E
            STA   :DIVER      ;=/  1.020477
            LDA   #$05
            STA   :DIVER+1
            LDX   #$10
:DIVLP      LSR   :SHIFTER+1  ;SHIFT DIVDEND
            ROR   :SHIFTER    ;BIT SMALLER
            ASL   :DIVER      ;DIVISOR BIT
            ROL   :DIVER+1    ;TO KNOCK OFF?
            BCC   :DIVNEXT    ;NO.
            LDA   HEXNUM      ;YES:SUBTRACT.
            SBC   :SHIFTER
            STA   HEXNUM
            LDA   HEXNUM+1
            SBC   :SHIFTER+1
            STA   HEXNUM+1
:DIVNEXT    DEX
            BNE   :DIVLP
            JSR   HEXDEC      ;-> 20,000
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
            LDA   $C000       ;ESC?
            CMP   #$9B
            BNE   :TEST       ;NOT YET...
            STA   $C010
*LDX RSLOT
            LDX   HSLOT
            LDA   $C088,X     ;MOTOR OFF.
            RTS
*
*
:SHIFTER    DB    $00,$00
:DIVER      DB    $3E,$05
*
INTLV1      EQU   *
            DB    $0,$7,$E,$6,$D,$5,$C,$4
            DB    $B,$3,$A,$2,$9,$1,$8,$F
VERIFYEND
