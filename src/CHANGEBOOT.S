************************************
*     CHANGE BOOTING PROGRAM       *
************************************
*
BOOTPG      JSR   COMHDR
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
:NAMESEC    DB    $0
:T0SECT     DB    $0
*
PUTSEC      STX   RSECTR      ;SET SECTOR
            LDA   #>DATA
            STA   RPAGE       ;SET ADDR
            LDA   #$01
            STA   RTRACK      ;SET TRACK
            STA   RCMND       ;SET COMMAND
            RTS
*
:CHKWRAPR   TXA
            CLC
            ADC   #4          ;9->D,7->B
            STA   :T0SECT
            JSR   PUTSEC      ;SET & READ
            JSR   DORWTS      ;DOS SECTOR
            LDX   #0
            LDY   #$FD
CHKDOS      LDA   #2
            STA   TEMP
:CHECKLP    LDA   DATA,Y      ;MATCH PATTERN
            CMP   :DOSPAT,X   ;TO VERIFY
            SEC
            BNE   :NO         ;DOS IS THERE
            INX
            INY
            DEC   TEMP
            BPL   :CHECKLP
            CLC
:NO         RTS
*
:DOSPAT     DB    $E0,$00,$F0,$A6,$2B,$BD
*

