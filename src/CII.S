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
            PUT   ../build/FILER.VARS
            PUT   ../build/LINEINPUT.VARS
            PUT   ../build/UILIB.VARS
            PUT   ../build/DISKLIB.VARS
            PUT   ../build/TREELIB.VARS
            PUT   ../build/CATLIB.VARS
            PUT   ../build/COPY.VARS
            PUT   ../build/CATALOG.VARS
            PUT   ../build/DELLIB.VARS
            PUT   ../build/APPLIB.VARS
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
            ERR   *#MENUTBL
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
LINEINPUTX7BEG
            ORG   LINEINPUT
            PUTBIN ../build/LINEINPUT.O.JMP
            JSR   ZXMODULE
            DA    :X7END-7
            DA    LINEINPUTEND
            PUTBIN  ../build/LINEINPUT.X7
:X7END
            ORG
LINEINPUTX7END
*
UILIBX7BEG
            ORG   UILIB
            PUTBIN ../build/UILIB.O.JMP
            JSR   ZXMODULE
            DA    :X7END-7
            DA    UILIBEND
            PUTBIN  ../build/UILIB.X7
:X7END
            ORG
UILIBX7END
*
DISKLIBX7BEG
            ORG   DISKLIB
            JSR   ZXMODULE
            DA    :X7END-7
            DA    DISKLIBEND
            PUTBIN  ../build/DISKLIB.X7
:X7END
            ORG
DISKLIBX7END
*
CATLIBX7BEG
            ORG   CATLIB
            JSR   ZXMODULE
            DA    :X7END-7
            DA    CATLIBEND
            PUTBIN  ../build/CATLIB.X7
:X7END
            ORG
CATLIBX7END
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
APPLIBX7BEG
            ORG   APPLIB
            PUTBIN ../build/APPLIB.O.JMP
            JSR   ZXMODULE
            DA    :X7END-7
            DA    APPLIBEND
            PUTBIN  ../build/APPLIB.X7
:X7END
            ORG
APPLIBX7END
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
