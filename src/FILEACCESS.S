*************************************
*       FILE ACCESS ROUTINES        *
*************************************
*
WRCAT1      LDX   #>VTOC1
            LDA   #$02
            JMP   DOCAT
*
WRCAT2      BIT   DOSNOW
            BPL   :DOS33
            JMP   CLOSE       ;NO JUST CLEAN UP
:DOS33      LDX   #>VTOC2     ;YES WRITE CATALOG
            LDA   #$02
            JMP   DOCAT
*
*
*
* *FIXSUB IS CALLED BY LOCK/UNLOCK,
* RENAME AND ALPHABETIZE TO MAKE
* THE NEEDED CHANGES TO THE SUBDIR
* HEADER. HEADER NAME, ACCESS AND
* PARENT POINTERS ARE UPDATED.
*
FIXSUB      JSR   SWPCHK
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
* SHOW A LINE OF CATALOG
CATLIN      PHA
            JSR   PRSPC
            JSR   PRSPC
            PLA
            JMP   CATLN1
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
*
*
* CHECK IF WE ARE DIVING IN TO OR OUT
* OF THE STARTING DIRECTORY. IF SO,
* RESTORE OR SAVE *STATUS, *CBYTE,
* *CSECTR,*FILNUM
*
* called by COPY FILES and DELETE FILES(DELLIB)
DIVECK      BCS   :GOOUT
            LDA   SP
            CMP   #1
            BNE   :DVCK00
            LDX   #>STATUS
            LDY   HIMEM
            DEY
            DEY
            DEY
            STY   :MYHI
            LDA   FILNUM
            STA   :SAVE1
            LDA   #4
            STA   TOPDIF
            JSR   :DVCK0
            LDA   HIMEM       ;8/27/86
            JSR   SETHIM      ;8/27/86
:DVCK00     JMP   :DVINIT
*
:GOOUT      LDA   SP
            BNE   :DVINIT
            JSR   :DVINIT
            LDX   :MYHI
            LDY   #>STATUS
            LDA   :SAVE1
            STA   FILNUM
            LDA   #0
            STA   TOPDIF
*
:DVCK0      STX   POINT+1
            STY   MESPNT+1
            LDY   #0
            STY   MESPNT
            STY   POINT
            LDX   #3
:DCKLP      LDA   (POINT),Y
            STA   (MESPNT),Y
            INY
            BNE   :DCKLP
            INC   POINT+1
            INC   MESPNT+1
            DEX
            BNE   :DCKLP
            RTS
:SAVE1      DB    $0
:MYHI       DB    $0
*
*
* INITIALIZE THINGS AFTER DIVING IN TO
* OR OUT OF A SUBDIRECTORY
*
:DVINIT     LDA   CURR
            PHA
            JSR   INITCD
            PLA
            STA   CURR
            JSR   RDACNT
            LDA   NACTIV
            STA   FILNUM
            SEC
            BEQ   :DVINT1     ;NO FILES
            LDX   #0
:CFLP2      INX
            TXA
            STA   STATUS-1,X
            CPX   NACTIV
            BCC   :CFLP2
            CLC
:DVINT1     RTS
*
* called by COPY DISK, COPY FILE, DELETE FILE
SETHIM      SEC
            SBC   DATADR
            AND   #$FE
            CLC
            ADC   DATADR
            SEC
            SBC   TOPDIF      ;0 OR 3
            STA   HIMEM
            RTS
*
PDSTRY      JSR   PUNLOK
            JSR   DOMLI
            DB    $C1
            DW    :DESLST
            RTS
:DESLST     DB    $1
            DW    FILE
*
PLOK        LDA   #$1
            DB    $2C
PUNLOK      LDA   #$C3
            STA   :TEMP+1
            JSR   GTINFO
:TEMP       LDA   #1
            STA   INFLST+3
*
* FALL INTO STINFO
*
*
STINFO      LDA   #7
            STA   INFLST
            JSR   DOMLI
            DB    $C3
            DW    INFLST
            RTS
*
GTINFO      LDA   #$0A
            STA   INFLST
            JSR   DOMLI
            DB    $C4
            DW    INFLST
            RTS

INFLST      DB    $A
            DW    FILE
            DB    $0
            DB    $0
            DB    $0,$0
            DB    $0
            DB    $0,$0
            DB    $0,$0
            DB    $0,$0
            DB    $0,$0
            DB    $0,$0
*
*
DOMLI       PLA
            STA   :ADDR+1
            PLA
            STA   :ADDR+2
            LDY   #3
:ADDR       LDA   $1000,Y
            STA   :LIST-1,Y
            DEY
            BNE   :ADDR
            LDA   :LIST
            STA   LASTOP
            JSR   MLI
:LIST       DB    $0,$0,$0
            STA   RRTN
            BCS   MLIERR
            LDA   :ADDR+1
            CLC
            ADC   #4
            STA   :ADDR+1
            BCC   :SKIP
            INC   :ADDR+2
:SKIP       JMP   (:ADDR+$1)
LASTOP      DB    $0
*
*
MLIERR      LDA   RRTN
            CMP   #$48        ;DISK FULL?
            BNE   :ERROU2     ;NOPE
*
* DELETE INCOMPLETELY COPIED FILE
*
            JSR   CLOSE       ;CLOSE IT
            LDA   #>FILE
            STA   POINT+1
            LDA   #FILE
            STA   POINT
            LDA   #1
            JSR   D1FILE
            JSR   WRCAT2
            LDA   #$48
            JMP   ERROU1
:ERROU2     JMP   ERROUT
*
*
* called by COPY FILE and DELETE FILE(DELLIB)
DOWAIT      LDX   #$03
:WAITLP     LDA   #$C4
            JSR   WAIT
            DEX
            BNE   :WAITLP
            RTS
*
