            TYP   REL
            DSK   ../build/FILER.O
            PUT   VARS
            PUT   ../build/MM.VARS
*
            ORG   CODEADR
            PUT   DISKACCESS  ;Page-aligned, timing-critical disk code
            PUT   FILEACCESS
            PUT   FILELIST
            PUT   DIRTREE
            PUT   FMTFIX
            PUT   LINEINPUT
            PUT   IO
            PUT   MESSAGES
            PUT   PRODOS
            PUT   BOOTSEC.PRO
            PUT   COPY
            PUT   CATALOG
            PUT   DELETE
            PUT   LOCKRENAME
            PUT   ALPHABETIZE
            PUT   FORMAT
            PUT   VERIFY
            PUT   VIEW
            PUT   DISKMAP
            PUT   CHANGEBOOT
            PUT   UNDELETE
            PUT   MKDIR
            PUT   PRINTER
            PUT   QUIT
            PUT   MENU
            DUM   *
MAINEND     DB    0           ;where image of main program ends
            DEND

