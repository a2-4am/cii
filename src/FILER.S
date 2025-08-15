            TYP   REL
            DSK   ../build/FILER.O
            PUT   VARS
            PUT   ../build/MM.VARS
*
            ORG   CODEADR-$30
* $30 bytes of interleave tables
            DB    $0,$D,$B,$9,$7,$5,$3,$1
            DB    $E,$C,$A,$8,$6,$4,$2,$F
            DB    $0,$7,$E,$6,$D,$5,$C,$4
            DB    $B,$3,$A,$2,$9,$1,$8,$F
            DB    $0,$E,$D,$C,$B,$A,$9,$8
            DB    $7,$6,$5,$4,$3,$2,$1,$F
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

