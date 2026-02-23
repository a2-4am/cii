            TYP   REL
            DSK   ../build/FILER.O
            PUT   VARS
            PUT   ../build/MM.VARS
            PUT   ../build/PHRWTS.VARS
            PUT   ../build/MESSAGES2.VARS
            PUT   ../build/MESSAGES.VARS
            PUT   ../build/DRIVE35.VARS
            PUT   ../build/PRODOS.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/READLIB.VARS
            PUT   ../build/DISKLIB.VARS
*
            ORG   MESSAGES2END
*
            PUTBIN ../build/MESSAGES.O
            PUTBIN ../build/DRIVE35.O
            PUTBIN ../build/PRODOS.O
            PUTBIN ../build/IO.O
            PUTBIN ../build/READLIB.O
            PUTBIN ../build/DISKLIB.O
            PUT   FILEACCESS
            PUT   LINEINPUT
            PUT   MENU
MAINEND                       ;where image of main program ends
