            TYP   SYS         ;Specify SYS-type object file
            DSK   ../build/UTIL.SYSTEM  ;Assemble directly into file
            TR    ON          ;Truncate object code printout
            PUT   REVS        ;revision info -- comments only
            PUT   VARS        ;assorted equates for everybody
            PUT   ../build/MM.VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/RDDATA.VARS
            PUT   ../build/CATLIB.VARS
            PUT   ../build/DODEV.VARS
            PUT   ../build/DOTREE.VARS
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
            ERR   MAINXEND>BTPFX  ;BTPFX clobbered before FILER is unpacked
*
RDDATAX7BEG
            ORG   RDDATA
            JSR   ZXMODULE
            DA    :X7END-7
            DA    RDDATAEND
            PUTBIN  ../build/RDDATA.X7
:X7END
            ORG
RDDATAX7END
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
DODEVX7BEG
            ORG   DODEV
            JSR   ZXMODULE
            DA    :X7END-7
            DA    DODEVEND
            PUTBIN  ../build/DODEV.X7
:X7END
            ORG
DODEVX7END
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
            ERR   MISCLIBX7END>$BEFF  ; can't clobber ProDOS global page
*
DZX0BEG
            ORG   ZXMODULE
            PUT   DZX0TURBO
            PUT   DISPATCH
            ORG
DZX0END
*
