**********************************
*      FILE LOCK/UNLOCK          *
*          & RENAME              *
**********************************
*
RENAME      LDA   #$03
            STA   STATE
            LDA   CHOOZOPT
            BEQ   REN2        ;RENAME FILES
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
RENVOL      EQU   *
*NEWVOL
            JSR   PRHERE
            ASC   8D,8D,"New v",00
            JSR   GVCOM
            BCS   :RENVOLQ
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
:RENVOLQ    RTS
*
