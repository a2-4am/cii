            TYP   SYS         ;Specify SYS-type object file
            DSK   ../build/UTIL.SYSTEM  ;Assemble directly into file
            TR    ON          ;Truncate object code printout
            PUT   REVS        ;revision info -- comments only
            PUT   VARS        ;assorted equates for everybody
            PUT   ../build/MM.VARS
            PUT   ../build/PHRWTS.VARS
            PUT   ../build/MESSAGES2.VARS
            PUT   ../build/MESSAGES.VARS
            PUT   ../build/QUIT.VARS
            PUT   ../build/MENU.VARS
            PUT   ../build/MAINPACK.VARS
            PUT   ../build/PROPACK.VARS
            PUT   ../build/COPY.VARS
            PUT   ../build/CATALOG.VARS
            PUT   ../build/DELLIB.VARS
            PUT   ../build/VERPACK.VARS
            PUT   ../build/ALPHAPACK.VARS
            ORG   $2000
*
            PUT   LOADER      ;This relocates & gets everything started.
*
BOOTBEG
            PUTBIN  ../build/BOOTSEC.33.O
BOOTEND
*
PHRWTSX7BEG
            ORG   PHRWTSADR
            JSR   ZXMODULE
            DA    :X7END-7
            DA    PHRWTSEND
            PUTBIN  ../build/PHRWTS.X7
:X7END
            ORG
PHRWTSX7END
*
MESSAGES2X7BEG
            ORG   MESSAGES2
            JSR   ZXMODULE
            DA    :X7END-7
            DA    MESSAGES2END
            PUTBIN  ../build/MESSAGES2.X7
:X7END
            ORG
MESSAGES2X7END
*
            PUTBIN  ../build/MAINPACK.X
MAINXEND
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
DZX0BEG
            ORG   ZXMODULE
            PUT   DZX0TURBO
            ERR   *#MENUTBL
            PUT   DISPATCH
            ERR   *#JPHRWTS
            PUTBIN ../build/PHRWTS.O.JMP
            ERR   *#JDELLIB
            PUTBIN ../build/DELLIB.O.JMP
            ERR   *#JALPHAPACK
            PUTBIN ../build/ALPHAPACK.O.JMP
            ERR   *#JVERPACK
            PUTBIN ../build/VERPACK.O.JMP
            ORG
DZX0END
*
PROPACKX7BEG
            ORG   PROPACK
            JSR   ZXMODULE
            DA    :X7END-7
            DA    PROPACKEND
            PUTBIN  ../build/PROPACK.X7
:X7END
            ORG
PROPACKX7END
*
DELLIBX7BEG
            ORG   DELLIB
            JSR   ZXMODULE
            DA    :X7END-7
            DA    DELLIBEND
            PUTBIN  ../build/DELLIB.X7
:X7END
            ORG
DELLIBX7END
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
VERPACKX7BEG
            ORG   VERPACK
            JSR   ZXMODULE
            DA    :X7END-7
            DA    VERPACKEND
            PUTBIN  ../build/VERPACK.X7
:X7END
            ORG
VERPACKX7END
*
ALPHAPACKX7BEG
            ORG   ALPHAPACK
            JSR   ZXMODULE
            DA    :X7END-7
            DA    ALPHAPACKEND
            PUTBIN  ../build/ALPHAPACK.X7
:X7END
            ORG
ALPHAPACKX7END
*
            ERR   ALPHAPACKEND>$BEFF ; can't clobber ProDOS global page
