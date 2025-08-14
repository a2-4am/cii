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
RENVOL      JSR   NEWVOL      ;GET NEW NAME
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
