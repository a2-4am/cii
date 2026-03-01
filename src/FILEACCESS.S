*************************************
*       FILE ACCESS ROUTINES        *
*************************************
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
MLIERR      EQU   *
            LDA   RRTN
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
