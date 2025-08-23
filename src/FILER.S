            TYP   REL
            DSK   ../build/FILER.O
            PUT   VARS
            PUT   ../build/MM.VARS
            PUT   ../build/BOOTSEC.33.VARS
*
            ORG   PHRWTSADR+BOOTSEC-BOOTSECEND
BOOTBEG
            PUTBIN  ../build/BOOTSEC.33.O
BOOTEND
            PUT   PHRWTS      ;Page-aligned, timing-critical disk code
            PUT   FILEACCESS
            PUT   FILELIST
            PUT   FMTFIX
            PUT   LINEINPUT
            PUT   IO
            PUT   MESSAGES
            PUT   PRODOS
            PUT   LOCKRENAME
*            PUT   PRINTER
            PUT   MENU
MAINEND                       ;where image of main program ends
