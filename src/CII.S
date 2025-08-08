*
            TYP   $FF         ;Specify SYS-type object file
            DSK   ../build/UTIL.SYSTEM ;Assemble directly into file
            TR    ON          ;Truncate object code printout
            PUT   REVS        ;revision info -- comments only
            PUT   VARS        ;assorted equates for everybody
            PUT   ../build/MM.VARS
            PUT   ../build/BOOTSEC.VARS
            PUT   ../build/FILER.VARS
            ORG   $2000
            PUT   LOADER      ;This relocates & gets everything started.
            PUT   EXODECRUNCH ;Decrunch modules on startup
            PUTBIN ../build/OBJ.MM.X
            PUTBIN ../build/OBJ.BOOTSEC.X
            PUTBIN ../build/OBJ.FILER.X
            DUM   *
XDATAEND    DB    0
            DEND
