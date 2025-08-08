*
            TYP   $06
            DSK   ../build/OBJ.FILER
            PUT   VARS
            PUT   ../build/MM.VARS
            PUT   ../build/BOOTSEC.VARS
*
            DUM   *
MAINBEG     DB    0           ;where image of main program begins
            DEND
*
            ORG   CODEADR     ;Image of main program!
            PUT   PHRWTS      ;<--Page-aligned start of disk code here.
            PUT   MORE.RWTS
            PUT   MAIN
            PUT   MORE.E000
            PUT   BANK2
            PUT   MORE.BANK2
            PUT   BANK1
            PUT   A000
            PUT   PRODOS
            PUT   MORE.A000
*
            DUM   *
PBOOT       DB    0           ;Marker for MAIN to move ProDOS bootsec.
            DEND
PROBEG      ORG   $800
            PUT   BOOTSEC.PRO
            ORG
*
            DUM   *
MAINEND     DB    0           ;where image of main program ends
            DEND
