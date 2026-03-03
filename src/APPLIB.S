            TYP   BIN
            DSK   ../build/APPLIB.O
            PUT   VARS
            PUT   ../build/PHRWTS.VARS
            PUT   ../build/PRODOS.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/ERRORS.VARS
            PUT   ../build/UILIB.VARS
            PUT   ../build/DISKLIB.VARS
            PUT   ../build/CATLIB.VARS
            PUT   ../build/TREELIB.VARS
            PUT   ../build/CATALOG.VARS
            ORG   CATALOGEND
APPLIB
*
VERIFY      >>>   JMPMODULE,DECOMPRESS;_VERIFY
TSMAP       >>>   JMPMODULE,DECOMPRESS;_TSMAP
UNDEL       >>>   JMPMODULE,DECOMPRESS;_UNDEL
DECOMPRESS  EQU   *
            ORG   *+3
            RTS

_VERIFY     EQU   *
            PUT   VERIFY
_TSMAP      EQU   *
            PUT   DISKMAP
_UNDEL      EQU   *
            PUT   UNDELETE
*
APPLIBEND
