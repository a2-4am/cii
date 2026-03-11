*
************************************
*           MAKE DIRECTORY         *
************************************
*
            JSR   COMTRE
            BIT   DOSNOW
            BMI   :MK0
NODOS3      EQU   *
            JSR   DOSTYP
            BCS   :BLK2ER
            LDA   #MNODOS3
            JMP   PRTPRS
:BLK2ER     JMP   BLK2ER
*
:MK0        JSR   GETDNM      ;GET DIRECTORY NAME
            BCS   :OUT
            TYA
            STA   FILE
            LDA   #$0F
            STA   FTYPE
            LDA   #0
            STA   AUXTYP
            LDA   #$20
            STA   AUXTYP+1
            JSR   GETDAT
            JSR   MKDIR
            BCS   :ERROUT
            JSR   PRHERE
            DB    $8D,$8D
            ASC   "Subdirectory created",8D,00
            JMP   PRESS
:OUT        RTS
:ERROUT     JMP   OUCH
