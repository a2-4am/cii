            TYP   BIN
            DSK   ../build/PROPACK.O
            PUT   ../build/MAINPACK.VARS
            ORG   MAINEND
*
PROPACK
            ORG   *+3
            RTS
*
            PUTBIN ../build/PRODOS.O
            PUTBIN ../build/ERRORS.O
            PUTBIN ../build/QUIT.O
            PUTBIN ../build/LINEINPUT.O
            PUTBIN ../build/UILIB.O
            PUTBIN ../build/DISKLIB.O
            PUTBIN ../build/CATLIB.O
            PUTBIN ../build/TREELIB.O
*
PROPACKEND
