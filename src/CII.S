            TYP   SYS         ;Specify SYS-type object file
            DSK   ../build/UTIL.SYSTEM  ;Assemble directly into file
            TR    ON          ;Truncate object code printout
            PUT   REVS        ;revision info -- comments only
            PUT   VARS        ;assorted equates for everybody
            PUT   ../build/MM.VARS
            PUT   ../build/PHRWTS.VARS
            PUT   ../build/MESSAGES2.VARS
            PUT   ../build/MESSAGES.VARS
            PUT   ../build/MENU.VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/DISKLIB.VARS
            PUT   ../build/TREELIB.VARS
            PUT   ../build/CATLIB.VARS
            PUT   ../build/COPY.VARS
            PUT   ../build/CATALOG.VARS
            PUT   ../build/DELLIB.VARS
            PUT   ../build/VERIFY.VARS
            PUT   ../build/DISKMAP.VARS
            PUT   ../build/UNDELETE.VARS
            PUT   ../build/MISCLIB.VARS
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
            PUTBIN  ../build/FILER.X
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
            PUT   DISPATCH
            ERR   *#JPHRWTS
            PUTBIN ../build/PHRWTS.O.JMP
            ERR   *#JDELLIB
            PUTBIN ../build/DELLIB.O.JMP
            ERR   *#JMISCLIB
            PUTBIN ../build/MISCLIB.O.JMP
            ERR   *#JTREELIB
            PUTBIN ../build/TREELIB.O.JMP
            ORG
DZX0END
*
DISKLIBX7BEG
            ORG   DISKLIB
            PUTBIN ../build/DISKLIB.O.JMP
            JSR   ZXMODULE
            DA    :X7END-7
            DA    DISKLIBEND
            PUTBIN  ../build/DISKLIB.X7
:X7END
            ORG
DISKLIBX7END
*
TREELIBX7BEG
            ORG   TREELIB
            JSR   ZXMODULE
            DA    :X7END-7
            DA    TREELIBEND
            PUTBIN  ../build/TREELIB.X7
:X7END
            ORG
TREELIBX7END
*
CATLIBX7BEG
            ORG   CATLIB
            PUTBIN ../build/CATLIB.O.JMP
            JSR   ZXMODULE
            DA    :X7END-7
            DA    CATLIBEND
            PUTBIN  ../build/CATLIB.X7
:X7END
            ORG
CATLIBX7END
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
MISCLIBX7BEG
            ORG   MISCLIB
            JSR   ZXMODULE
            DA    :X7END-7
            DA    MISCLIBEND
            PUTBIN  ../build/MISCLIB.X7
:X7END
            ORG
MISCLIBX7END
*
            ERR   MISCLIBEND>$BEFF  ; can't clobber ProDOS global page
