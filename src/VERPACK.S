            TYP   BIN
            DSK   ../build/VERPACK.O
            PUT   VARS
            PUT   ../build/VERIFY.VARS
            PUT   ../build/DISKMAP.VARS
            PUT   ../build/UNDELETE.VARS
            PUT   ../build/CATALOG.VARS
            ORG   JVERPACK
VERIFY      >>>   JMPMODULE,DECOMPRESS;_VERIFY
TSMAP       >>>   JMPMODULE,DECOMPRESS;_TSMAP
UNDEL       >>>   JMPMODULE,DECOMPRESS;_UNDEL
            ORG   CATALOGEND
VERPACK
DECOMPRESS  EQU   *
            ORG   *+3
            RTS

_VERIFY     EQU   *
            PUTBIN ../build/VERIFY.O
_TSMAP      EQU   *
            PUTBIN ../build/DISKMAP.O
_UNDEL      EQU   *
            PUTBIN ../build/UNDELETE.O
*
VERPACKEND
