            TYP   BIN
            DSK   ../build/MAINPACK.O
            PUT   ../build/MESSAGES2.VARS
            PUT   ../build/BOOTSEC.33.VARS
*
            ORG   MESSAGES2END-BOOTSECEND+BOOTSEC
*
BOOTBEG
            PUTBIN  ../build/BOOTSEC.33.O
BOOTEND
            PUTBIN ../build/MESSAGES.O
            PUTBIN ../build/DRIVE35.O
            PUTBIN ../build/IO.O
            PUTBIN ../build/MENU.O
*
MAINEND
