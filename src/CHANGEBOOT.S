            TYP   BIN
            DSK   ../build/CHANGEBOOT.O
            PUT   VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/DISKMAP.VARS
            ORG   TSMAPEND
BOOTPG      
            ORG   *+3

***********************************
*     CHANGE BOOTING PROGRAM       *
************************************
*
            JSR   COMHDR
            LDA   #$04
            STA   STATE
            BIT   DOSNOW
            BPL   :DOS33
            JMP   NOPRO
*
:DOS33      LDX   #9          ;CHECK T01S09
            JSR   :CHKWRAPR   ;FOR DOS
            BCC   :GOTSECT
            LDX   #7          ;CHECK T01S07
            JSR   :CHKWRAPR   ;FOR PRONTO-DOS
            BCS   :NODOS
:GOTSECT    LDA   RSECTR      ;REAL DOS:
            STA   :NAMESEC
            JSR   CATDIS      ;SELECT NEW
            JSR   SWPCHK
            JSR   CURPNT      ;BOOT PROGRAM
            LDY   #$20
            LDX   #$1D
:COPYNAM    LDA   (POINT),Y   ;COPY FILENAME
            STA   DATA+$75,X  ;INTO DOS
            DEY               ;SECTOR
            DEX
            BPL   :COPYNAM
            LDX   :NAMESEC    ;RESET DOS
            JSR   PUTSEC      ;SECTOR
            INC   RCMND
            JSR   DORWTS      ;WRITE
            LDA   #0          ;RUN CMND
            STA   RTRACK      ;TRACK &
            LDA   :T0SECT     ;SECTOR
            STA   RSECTR
            DEC   RCMND
            JSR   DORWTS      ;READ IT
            LDY   #$02
            LDX   #$14
            LDA   (POINT),Y   ;CHECK FILETYPE
            AND   #$7F        ;STRIP LOCK BIT
            BEQ   :POKERUN    ;& SET PROPER
            LDX   #$34        ;RUN CODE:
            CMP   #$04        ;0 -> 14
            BEQ   :POKERUN    ;4 -> 34
            LDX   #$06        ;ELSE -> 6
:POKERUN    STX   DATA+$42
            INC   RCMND
            JMP   DORWTS      ;WRITE BACK
*
:NODOS      JSR   PRHERE
            DB    $8D,$8D,$8D,$8D
            ASC   "No boot program to change",00
            JMP   PRESS
*
:CHKWRAPR   TXA
            CLC
            ADC   #4          ;9->D,7->B
            STA   :T0SECT
            JSR   PUTSEC      ;SET & READ
            JSR   DORWTS      ;DOS SECTOR
            LDX   #0
            LDY   #$FD
            JMP   CHKDOS
*
:NAMESEC    DB    $0
:T0SECT     DB    $0
*
BOOTPGEND
