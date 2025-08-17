            TYP   SYS         ;Specify SYS-type object file
            DSK   ../build/UTIL.SYSTEM  ;Assemble directly into file
            TR    ON          ;Truncate object code printout
            PUT   REVS        ;revision info -- comments only
            PUT   VARS        ;assorted equates for everybody
            PUT   ../build/SETCLOCK.VARS
            PUT   ../build/MM.VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/COPY.VARS
            PUT   ../build/CATALOG.VARS
            PUT   ../build/DISKMAP.VARS
            PUT   ../build/QUIT.VARS
            ORG   $2000
*
            PUT   LOADER      ;This relocates & gets everything started.
            PUT   BOOTSEC.33
*
            PUTBIN  ../build/SETCLOCK.X
CLKXEND
*
MMXBEG
            ORG   MMSPOT
            JSR   ZXMODULE
            DA    :X7END-7
            DA    MMEND
            PUTBIN  ../build/MM.X7
:X7END
            ORG
MMXEND
*
            PUTBIN  ../build/FILER.X
MAINXEND
*
COPYX7BEG
            ORG   COPY
            JSR   ZXMODULE
            DA    :X7END-7
            DA    COPYEND
            PUTBIN  ../build/COPY.X7
:X7END
            ORG
COPYX7END
*
CATALOGX7BEG
            ORG   CATALOG
            JSR   ZXMODULE
            DA    :X7END-7
            DA    CATALOGEND
            PUTBIN  ../build/CATALOG.X7
:X7END
            ORG
CATALOGX7END
*
TSMAPX7BEG
            ORG   TSMAP
            JSR   ZXMODULE
            DA    :X7END-7
            DA    TSMAPEND
            PUTBIN  ../build/DISKMAP.X7
:X7END
            ORG
TSMAPX7END
*
QUITX7BEG
            ORG   QUIT
            JSR   ZXMODULE
            DA    :X7END-7
            DA    QUITEND
            PUTBIN  ../build/QUIT.X7
:X7END
            ORG
QUITX7END
*
DZX0BEG
            ORG   ZXMODULE
            PUT   DZX0TURBO
            PUT   MENUTBL
            ERR   *-$BF00
            ORG
DZX0END
*
