            TYP   BIN
            DSK   ../build/MAKESUB.O
            PUT   VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/UNDELETE.VARS
            ORG   UNDELEND
MAKESUB
            ORG   *+3

************************************
*           MAKE DIRECTORY         *
************************************
*
            JSR   COMTRE
            BIT   DOSNOW
            BMI   :MK0
            JMP   NODOS3
*
:MK0        JSR   PRHERE
            DB    $8D
            ASC   "Subdirectory name: "
            DB    $0
            JSR   GVCOM1
            BCS   :OUT
            LDY   #0
:MKLOOP     LDA   VOLNAM,Y
            BEQ   :MK2
            STA   FILE+$1,Y
            INY
            BNE   :MKLOOP
:MK2        TYA
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
:ERROUT     JMP   ERROUT
*
MAKESUBEND
