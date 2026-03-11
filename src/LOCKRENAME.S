*
**********************************
*      FILE LOCK/UNLOCK          *
*          & RENAME              *
**********************************
*
            LDA   #$03
            STA   STATE
            LDA   CHOOZOPT
            BEQ   REN2        ;RENAME FILES
            JSR   COMHDR
            BIT   DOSNOW
            BMI   RENVOL
            JMP   NODOS3
*
_LOCK
            LDA   #$02
            STA   STATE
*
REN2        EQU   *
            JSR   COMTRE
            JSR   CATDIS
            LDA   FILNUM
            BNE   :GOTFILS
            JMP   NOSEL
:GOTFILS    JMP   FIXSUB
*
* RENAME VOLUME
*
RENVOL      EQU   *
            JSR   GETNVNM     ;GET NEW VOL NAME
            BCS   :RENVOLQ
            JSR   RDBLK2
            BCS   :RENERR
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
            JSR   WTBLK
            BCS   :RENERR
:RENVOLQ    RTS
:RENERR     JMP   OUCH
