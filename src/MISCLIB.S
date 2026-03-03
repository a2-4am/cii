            TYP   BIN
            DSK   ../build/MISCLIB.O
            PUT   VARS
            PUT   ../build/PRODOS.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/LINEINPUT.VARS
            PUT   ../build/ERRORS.VARS
            PUT   ../build/UILIB.VARS
            PUT   ../build/DISKLIB.VARS
            PUT   ../build/CATLIB.VARS
            PUT   ../build/TREELIB.VARS
            PUT   ../build/APPLIB.VARS
************************************
*      MISCELLANEOUS LIBRARY       *
* MAKESUB - Create Subdirectory    *
* SETCLOCK - Enter Date            *
* BOOTPG - Change Boot Program     *
* VIEW - View Files                *
* ALPHA - Alphabetize Catalog      *
* RENAME - Rename Files/Volume     *
* LOCK - Lock/Unlock Files         *
* private:                         *
* FIXSUB - LOCK/REN/ALPHA cleanup  *
************************************
            ORG   JMISCLIB
MAKESUB     >>>   JMPMODULE,DECOMPRESS;_MAKESUB
SETCLOCK    >>>   JMPMODULE,DECOMPRESS;_SETCLOCK
BOOTPG      >>>   JMPMODULE,DECOMPRESS;_BOOTPG
VIEW        >>>   JMPMODULE,DECOMPRESS;_VIEW
ALPHA       >>>   JMPMODULE,DECOMPRESS;_ALPHA
RENAME      >>>   JMPMODULE,DECOMPRESS;_RENAME
LOCK        >>>   JMPMODULE,DECOMPRESS;_LOCK
            ORG   APPLIBEND
MISCLIB
DECOMPRESS  EQU   *
            ORG   *+3
            RTS

_MAKESUB    EQU   *
            PUT   MAKESUB
_SETCLOCK   EQU   *
            PUT   SETCLOCK
_BOOTPG     EQU   *
            PUT   BOOTPG
_VIEW       EQU   *
            PUT   VIEW
_ALPHA      EQU   *
            PUT   ALPHA
_RENAME     EQU   *
            PUT   LOCKRENAME  ;also contains _LOCK
*
* *FIXSUB IS CALLED BY LOCK/UNLOCK,
* RENAME AND ALPHABETIZE TO MAKE
* THE NEEDED CHANGES TO THE SUBDIR
* HEADER. HEADER NAME, ACCESS AND
* PARENT POINTERS ARE UPDATED.
*
FIXSUB      EQU   *
            JSR   SWPCHK
            BIT   DOSNOW
            BPL   :FXSB1      ;NOT PRODOS
*
            LDA   #0
            STA   CURR
:FXLOOP     JSR   CURPNT
            JSR   :FIXSUB
            INC   CURR
            LDA   CURR
            CMP   NACTIV
            BNE   :FXLOOP
*
:FXSB1      JMP   WRCAT1
*
:OUT        RTS
:FIXSUB     JSR   DIR?
            BCS   :OUT        ;NOT SUBDIR
            LDA   #>DATA      ;TEMP BUFFER
            STA   POINT2+1
            STA   RPAGE
            LDA   #4
            STA   POINT2
*
* READ 1ST BLOCK OF SUBDIR
*
            LDY   #$11
            LDA   (POINT),Y
            STA   BLKNUM
            INY
            LDA   (POINT),Y
            STA   BLKNUM+1
            JSR   RDBLK
            BCS   :OUT
*
* COPY FILENAME TO HEADER NAME
*
            LDY   #$0F
:FSLP1      LDA   (POINT),Y
            STA   (POINT2),Y
            DEY
            BNE   :FSLP1
            LDA   (POINT),Y
            AND   #$0F
            ORA   #$E0
            STA   (POINT2),Y
*
* DON'T NEED TO CHANGE ACCESS BYTE
* BECAUSE PRODOS DOESN'T.
*
* LDY #$1E
* LDA (*POINT),Y
* STA (*POINT2),Y
*
* SET UP PARENT POINTERS
*
            LDA   POINT+1
            AND   #$FE        ;/!\ assumes SDIR is aligned to even page boundary
            CMP   #>SDIR      ;14
            BNE   :FS2        ;NOT 1ST
            LDA   DIRBLK
            LDX   DIRBLK+1
            JMP   :FS3
*
:FS2        SEC
            SBC   #$2
            STA   TEMP+1
            LDA   #0
            STA   TEMP
            LDY   #3
            LDA   (TEMP),Y    ;PARENT BLK HI
            TAX
            DEY
            LDA   (TEMP),Y    ;PARENT BLK LO
:FS3        LDY   #$23
            STA   (POINT2),Y
            INY
            TXA
            STA   (POINT2),Y
*
* FIGURE OUT PARENT ENTRY NUMBER
*
            LDY   #$26
            LDA   (POINT2),Y  ;ENTRY LENGTH
            STA   TEMP
*
            LDA   POINT
            LDX   #1
:FS4        CMP   #4
            BEQ   :FS5
            SEC
            SBC   TEMP
            INX
            BNE   :FS4        ;ALWAYS
*
:FS5        TXA
            DEY
            STA   (POINT2),Y
*
* WRITE SUBDIR BLOCK BACK
*
            JMP   WTBLK
*
MISCLIBEND
