            TYP   REL
            DSK   ../build/FILER.O
            PUT   VARS
            PUT   ../build/MM.VARS
*
            ORG   PHRWTSADR
            PUT   PHRWTS      ;First! Page-aligned, timing-critical disk code
            PUT   FILEACCESS
            PUT   FILELIST
            PUT   FMTFIX
            PUT   LINEINPUT
            PUT   IO
            PUT   MESSAGES
            PUT   PRODOS
            PUT   BOOTSEC.PRO
            PUT   LOCKRENAME
            PUT   PRINTER
            PUT   MENU
MAINEND                       ;where image of main program ends
