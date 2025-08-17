            TYP   SYS         ;Specify SYS-type object file
            DSK   ../build/UTIL.SYSTEM  ;Assemble directly into file
            TR    ON          ;Truncate object code printout
            PUT   REVS        ;revision info -- comments only
            PUT   VARS        ;assorted equates for everybody
            PUT   ../build/SETCLOCK.VARS
            PUT   ../build/MM.VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/DOTREE.VARS
            PUT   ../build/COPY.VARS
            PUT   ../build/CATALOG.VARS
            PUT   ../build/DELETE.VARS
            PUT   ../build/ALPHABETIZE.VARS
            PUT   ../build/FORMAT.VARS
            PUT   ../build/VERIFY.VARS
            PUT   ../build/VIEW.VARS
            PUT   ../build/DISKMAP.VARS
            PUT   ../build/CHANGEBOOT.VARS
            PUT   ../build/UNDELETE.VARS
            PUT   ../build/MAKESUB.VARS
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
DOTREEX7BEG
            ORG   DOTREE
            JSR   ZXMODULE
            DA    :X7END-7
            DA    DOTREEEND
            PUTBIN  ../build/DOTREE.X7
:X7END
            ORG
DOTREEX7END
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
DELETEX7BEG
            ORG   DELETE
            JSR   ZXMODULE
            DA    :X7END-7
            DA    DELETEEND
            PUTBIN  ../build/DELETE.X7
:X7END
            ORG
DELETEX7END
*
ALPHABETIZEX7BEG
            ORG   ALPHA
            JSR   ZXMODULE
            DA    :X7END-7
            DA    ALPHAEND
            PUTBIN  ../build/ALPHABETIZE.X7
:X7END
            ORG
ALPHABETIZEX7END
*
FORMATX7BEG
            ORG   FORMAT
            JSR   ZXMODULE
            DA    :X7END-7
            DA    FORMATEND
            PUTBIN  ../build/FORMAT.X7
:X7END
            ORG
FORMATX7END
*
VERIFYX7BEG
            ORG   VERIFY
            JSR   ZXMODULE
            DA    :X7END-7
            DA    VERIFYEND
            PUTBIN  ../build/VERIFY.X7
:X7END
            ORG
VERIFYX7END
*
VIEWX7BEG
            ORG   VIEW
            JSR   ZXMODULE
            DA    :X7END-7
            DA    VIEWEND
            PUTBIN  ../build/VIEW.X7
:X7END
            ORG
VIEWX7END
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
CHANGEBOOTX7BEG
            ORG   BOOTPG
            JSR   ZXMODULE
            DA    :X7END-7
            DA    BOOTPGEND
            PUTBIN  ../build/CHANGEBOOT.X7
:X7END
            ORG
CHANGEBOOTX7END
*
UNDELETEX7BEG
            ORG   UNDEL
            JSR   ZXMODULE
            DA    :X7END-7
            DA    UNDELEND
            PUTBIN  ../build/UNDELETE.X7
:X7END
            ORG
UNDELETEX7END
*
MAKESUBX7BEG
            ORG   MAKESUB
            JSR   ZXMODULE
            DA    :X7END-7
            DA    MAKESUBEND
            PUTBIN  ../build/MAKESUB.X7
:X7END
            ORG
MAKESUBX7END
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
            PUT   DISPATCH
            ERR   *-$BF00
            ORG
DZX0END
*
