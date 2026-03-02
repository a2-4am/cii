            TYP   REL
            DSK   ../build/FILER.O
            PUT   VARS
            PUT   ../build/PHRWTS.VARS
            PUT   ../build/MESSAGES2.VARS
            PUT   ../build/MESSAGES.VARS
            PUT   ../build/DRIVE35.VARS
            PUT   ../build/PRODOS.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/ERRORS.VARS
            PUT   ../build/MENU.VARS
*
            ORG   MESSAGES2END
*
            PUTBIN ../build/MESSAGES.O
            PUTBIN ../build/DRIVE35.O
            PUTBIN ../build/PRODOS.O
            PUTBIN ../build/IO.O
            PUTBIN ../build/ERRORS.O
            PUTBIN ../build/MENU.O
MAINEND                       ;where image of main program ends
