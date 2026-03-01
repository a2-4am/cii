            TYP   BIN
            DSK   ../build/TREELIB.O
            PUT   VARS
            PUT   ../build/PHRWTS.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/ERRORS.VARS
            PUT   ../build/UILIB.VARS
            PUT   ../build/DISKLIB.VARS
            ORG   DISKLIBEND

**********************************
*          TREE LIBRARY          *
* COMTRE
* CT1
* COMHDR
* COMH00
* TREEA
* SETA
**********************************

*
*
* COMMON TREE
* Choose ProDOS device then choose directory
* called by ALPHABETIZE, DELETE(DELLIB),
* RENAME FILES, MAKESUB, UNDELETE, VERIFY, and VIEW
COMTRE      JSR   DODEVP
            JSR   TREEA
            JSR   COMH00
CT1         BIT   DOSNOW
            BPL   :CTOUT      ;DOS 3.3
            LDA   RRTN
            BEQ   :CTOUT      ;NO ERROR
            CMP   #$52
            BEQ   :CTERR1
            CMP   #$40
            BCC   :CTERR      ;I/O ERROR
:CTOUT      RTS
*
* BLOCK 2 ERROR
*
:CTERR      JMP   BLK2ER
*
* NOT A DOS OR PRODOS DISK
*
:CTERR1     JMP   WDERR
*
COMHDR      JSR   DODEVP
            JSR   SETA
            JSR   COMH00
            LDA   CHOICE
            CMP   #MVERIFY    ;VERIFY DISK?
            BNE   CT1         ;NO
            RTS

COMH00      JSR   TOP1
            JMP   PRVNM
*
*
*
TREEA       JSR   DOSTYP
            LDA   #APFX
            STA   PFXADR
            LDA   #>APFX
            STA   PFXADR+1
            LDA   ACURR
            JSR   JDOTREE
            BCS   SETA        ;I/O ERROR
            STA   ACURR
            RTS
SETA        JSR   DOSTYP
            LDA   UNIT
            >>>   JMPMODULE,PHRWTSLIB;UNTPFX
*
TREELIBEND
