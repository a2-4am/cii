            TYP   $FF         ;Specify SYS-type object file
            DSK   ../build/UTIL.SYSTEM ;Assemble directly into file
            TR    ON          ;Truncate object code printout
            PUT   REVS        ;revision info -- comments only
            PUT   VARS        ;assorted equates for everybody
            PUT   ../build/MM.VARS
            PUT   ../build/FILER.VARS
            ORG   $2000
            PUT   LOADER      ;This relocates & gets everything started.
            PUT   DZX0        ;Unpack modules on startup
            PUT   BOOTSEC.33  ;Copied to LCRAM
            PUTBIN ../build/OBJ.MM.X
MMXEND
            PUTBIN ../build/OBJ.FILER.X
MAINXEND
