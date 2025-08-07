*
            XC
            XC
* OBJ $BFE0
            TYP   $FF         ;Specify SYS-type object file
            DSK   UTIL.SYSTEM ;Assemble directly into file
            TR    ON          ;Truncate object code printout
*
            PUT   REVS        ;revision info -- comments only
            PUT   VARS        ;assorted equates for everybody
*
            ORG   $2000
            PUT   LOADER      ;This relocates & gets everything started.
*
            DUM   *
BOOTBEG     DB    0           ;where image of boot sector begins
            DEND
            ORG   $800        ;Image of no-DOS boot sector
            PUT   BOOTSEC.33
            ORG
            DUM   *
BOOTEND     DB    0           ;where image of boot sector ends
            DEND
*
            DUM   *
MMBEG       DB    0           ;where image of MM begins
            DEND
            ORG   MMSPOT      ;Image of Memory Manager
            PUT   MM.CII
            ORG
            DUM   *
MMEND       DB    0           ;where image of MM ends
            DEND
*
            DUM   *
MAINBEG     DB    0           ;where image of main program begins
            DEND
            ORG   CODEADR     ;Image of main program!
            PUT   PHRWTS      ;<--Page-aligned start of disk code here.
            PUT   MORE.RWTS
            PUT   MAIN
            PUT   MORE.E000
            PUT   BANK2
            PUT   MORE.BANK2
            PUT   BANK1
            PUT   A000
            PUT   PRODOS
            PUT   MORE.A000
            DUM   *
PBOOT       DB    0           ;Marker for MAIN to move ProDOS bootsec.
            DEND
            ORG
PROBEG      ORG   $800
            PUT   BOOTSEC.PRO
            ORG
            DUM   *
MAINEND     DB    0           ;where image of main program ends
            DEND
*
* How to nicely relocate the main code with a backwards move:
*
* MoveSize = size of code to move, rounded UP to whole page
MOVESIZE    =     {{MAINEND-MAINBEG+$FF}/$100}*$100
*
* FromAddr = last page of source to transfer
FROM        =     MAINBEG+MOVESIZE-$100
*
* ToAddr = last page of destination range
TO          =     CODEADR+MOVESIZE-$100

*
*
            LST   ON
            DUM   PBOOT+MAINEND-PROBEG
CODEEND     DS    1           ;where relocated main program ends
            DEND
* PAU
*


