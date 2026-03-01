            TYP   REL
            DSK   ../build/FILER.O
            PUT   VARS
            PUT   ../build/PHRWTS.VARS
            PUT   ../build/MESSAGES2.VARS
            PUT   ../build/MESSAGES.VARS
            PUT   ../build/DRIVE35.VARS
            PUT   ../build/PRODOS.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/MENU.VARS
            PUT   ../build/LINEINPUT.VARS
            PUT   ../build/ERRORS.VARS
            PUT   ../build/UILIB.VARS
            PUT   ../build/READLIB.VARS
            PUT   ../build/DISKLIB.VARS
*
            ORG   MESSAGES2END
*
            PUTBIN ../build/MESSAGES.O
            PUTBIN ../build/DRIVE35.O
            PUTBIN ../build/PRODOS.O
            PUTBIN ../build/IO.O
            PUTBIN ../build/MENU.O
            PUTBIN ../build/LINEINPUT.O
            PUTBIN ../build/ERRORS.O
            PUTBIN ../build/UILIB.O
            PUTBIN ../build/READLIB.O
            PUTBIN ../build/DISKLIB.O
MAINEND                       ;where image of main program ends
