*******************************
*         DELETE              *
*******************************
*
DELETE      LDX   #$02
            JSR   CHOOZ1      ;DOS, DISK,
            STA   :TEMP       ;OR FILES?
            CMP   #0
            BNE   :NOTFILZ
            JSR   COMTRE
            JMP   :DFILES
*
:NOTFILZ    JSR   COMHDR
            LDA   :TEMP
            CMP   #$02
            BEQ   :DDOS
*
***********  DELETE DISK  **********
*
*

:DELDSK     JSR   :READY?
            BNE   :DDOUT
            JSR   DOSTYP      ;SETUP VOLNAM
            BMI   :DELPRO     ;PRODOS
*
* READ VTOC JUST TO MAKE SURE THAT
* IT IS REALLY A DOS DISK
*
* These two lines added 2/1/89
*
            LDA   #1
            STA   RCMND
*
            LDX   #>VTOC1
            JSR   DOVTOC
*
:DELPRO     JSR   DEVTYP
            CMP   #1
            BNE   :GODDSK     ;NOT /RAM
*
*
* DISCONNECT /RAM
*
            LDA   #$FF
            STA   ISAUX
            BNE   :DDDONE     ;ALWAYS
*
:DDOUT      RTS
:GODDSK     JSR   DDISK
:DDDONE     JSR   PRHERE
            DB    $8D,$8D
            ASC   "Disk"
            DB    $0
            JMP   :COMDEL
*
*
***********  DELETE DOS  ***********
*
:DDOS       LDA   DOSNOW
            BPL   :DOS33
            JMP   NOPRO
*
:DOS33      JSR   :READY?
            BNE   :DDOUT
            JSR   DOS?
            JSR   STVTOC
            LDA   #>CVTOC
            STA   RPAGE
            LDA   #$01
            STA   RCMND
            JSR   DORWTS
            LDA   #$FF
            JSR   SET1A2
            JSR   ZIPDOS      ;WRITE NO-BOOT
            JSR   PRHERE
            DB    $8D,$8D
            ASC   "DOS"
            DB    $0
:COMDEL     JSR   PRHERE
            ASC   " deleted"
            DB    $8D,$0
            JMP   PRESS
*
*
*
:TEMP       DB    $0
*
*
:READY?     JSR   PRHERE
            DB    $8D,$8D
            ASC   "Ready to delete (Y/N) ? "
            DB    $0
            JSR   KEYESC
            JSR   PCOUT
            CMP   #"Y"
            BNE   :READY3
            JSR   SETA
            JSR   PRVNM
            JSR   HOME
            LDA   #0
:READY3     RTS
*
*
*********  DELETE FILES  ***********
:DFILES     LDA   #$01
            STA   STATE       ;STATE=1
            JSR   CATDIS      ;DISPLAY
            JSR   PATMOV
            LDA   FILNUM      ;ANY FILES?
            BNE   :GOTFILS
            JMP   NOSEL
:GOTFILS    JSR   SWPCHK      ;SAME DISK?
            JSR   HOME
            LDY   #$00        ;INIT COUNTER
            STY   SP
            STY   CURR
:DFILELP    JSR   FILEQ
            JSR   CURPNT
            BIT   DOSNOW
            BPL   :SKIPCK     ;DOS 3.3
            LDY   #0
            LDA   (POINT),Y
            AND   #$F0
            CMP   #$D0
            BNE   :SKIPCK     ;NOT SUBDIR
            JSR   DIVEIN
            CLC
            JSR   DIVECK
            JSR   PRVNM
            JSR   SETPFX
            LDX   #$FF
            STX   CURR
            BNE   :DFIL1      ;ALWAYS
*
:SKIPCK     JSR   CURPNT
            LDA   #>TOP10     ;2/16/87
            JSR   SETHIM      ;2/16/87
            LDA   #$00        ;SET CATALOG1
            JSR   D1FILE      ;DELETE A FILE
            LDA   $C000
            CMP   #$9B
            BEQ   :ABORT
:DFIL1      INC   CURR
            LDA   CURR
            CMP   FILNUM
            BCC   :DFILELP
            BIT   DOSNOW
            BPL   :ABORT
            JSR   DIVOUT
            BCS   :ABORT
            LDA   SP
            BEQ   :DFIL2
            LDA   #0
            STA   CURR
:DFIL2      SEC
            JSR   DIVECK
            JSR   PRVNM
            JSR   SETPFX
            JSR   FILEQ
            JMP   :SKIPCK
*
:ABORT      BIT   DOSNOW
            BMI   DOWAIT      ;PRODOS
            JSR   WRCAT1      ;WRITE TRACK
DOWAIT      LDX   #$03
:WAITLP     LDA   #$C4
            JSR   WAIT
            DEX
            BNE   :WAITLP
D1OUT       RTS
*
*
* DELETE A FILE
*
D1FILE      STA   :TEMP
            LDY   #$00
            LDA   (POINT),Y   ;MOVE TRACK #
            BIT   DOSNOW
            BMI   :PRODOS
            JMP   :DOS33
*
:PRODOS     PHA
            AND   #$F0
            STA   :TEMP
            PLA
            AND   #$0F        ;NAME LEN
            BEQ   D1OUT       ;ALREADY DEL'D
            STA   (POINT),Y
            LDY   #$0F
:D1LOOP     LDA   (POINT),Y
            STA   FILE,Y
            DEY
            BPL   :D1LOOP
*
* SAVE INDEX BLOCK (IF SAPLING) AND
* MASTER INDEX BLOCK (IF TREE)
*
            LDY   #$11
            LDA   (POINT),Y
            STA   BLKNUM
            STA   :MIBNUM
            INY
            LDA   (POINT),Y
            STA   BLKNUM+1
            STA   :MIBNUM+1
            LDA   :TEMP
            CMP   #$20
            BEQ   :SAVSAP
            CMP   #$30
            BNE   :DODSTRY
            LDA   #>FILBUF
            STA   RPAGE
            JSR   RDBLK
            BCS   :SAVERR
            LDA   FILBUF
            STA   BLKNUM
            LDA   FILBUF+$100
            STA   BLKNUM+1
:SAVSAP     LDA   #>DESBUF
            STA   RPAGE
            JSR   RDBLK
            BCC   :DODSTRY
:SAVERR     LDA   #$10
            STA   :TEMP
:DODSTRY    JSR   PDSTRY
            LDA   :TEMP
            AND   #$EF
            CMP   #$20
            BNE   :RESOUT     ;NOT SAPLING OR TREE FILE
*
* COMPARE SAVED INDEX BLOCK TO INDEX BLOCK ON  DISK
* TO SEE HOW IT CHANGED. IF THE HIGH PART AND LOW
* PART HAVE BEEN SWITCHED, THEN  WE ARE RUNNING UNDER
* PRODOS 1.3 (OR ABOVE) AND WE ARE DONE.
*
* WE DON'T HAVE AN EXTRA BUFFER TO READ BLOCK FROM DISK
* INTO SO WE CAN COMPARE TO OLD BLOCK SITTING IN DESBUF.
* SO WE WILL JUST WRITE OLD BLOCK BACK (BACKWARDS) THEN,
* IF TREE FILE, DETERMINE THINGS.
*
* BLKNUM,+1 & RPAGE ARE STILL SET UP FOR INDEX BLOCK
*
            LDY   #>DESBUF
            JSR   SWAPIB      ;REVERSE IT
            JSR   WTBLK       ;WRITE FIRST INDEX BLOCK
            LDA   :TEMP
            CMP   #$30
            BNE   :RESOUT     ;NOT TREE FILE
*
* FIGURE OUT IF WE NEED TO REVERSE REST OF BLOCKS IN
* TREE FILE
*
* READ MIB OF DISK INTO DESBUF (NOW THAT DESBUF IS FREE)
* AND COMPARE TO OLD MIB IN FILBUF
*
            LDA   :MIBNUM
            STA   BLKNUM
            LDA   :MIBNUM+1
            STA   BLKNUM+1
            JSR   RDBLK
            BCS   :ERR
            LDY   #0
:TREELP     LDA   FILBUF+$100,Y
            CMP   DESBUF,Y
            BNE   :DOMORE
            INY
            BPL   :TREELP
*
* MUST BE RUNNING UNDER PRODOS 1.3 OR ABOVE, BECAUSE MIB WAS
* WRITTEN BACK BACKWARDS BY PRODOS.
*
:ERR        RTS

*
* WE MUST NOW REVERSE ALL OF THE FILES INDEX BLOCKS
*
:DOMORE     LDY   #>FILBUF
            STY   RPAGE
            JSR   SWAPIB      ;REVERSE MIB
            JSR   WTBLK       ;WRITE OUT REVERSED MIB
            LDY   #1          ;START AT 1 SINCE WE ALREADY
                              ;REVERSED FIRST INDEX BLOCK
            STY   :TEMP
:DOMORE1    LDY   :TEMP
            LDA   FILBUF+$100,Y
            STA   BLKNUM
            LDA   FILBUF,Y
            STA   BLKNUM+1
            ORA   BLKNUM
            BEQ   :DOMORE2    ;NULL ENTRY
            LDA   #>DESBUF
            STA   RPAGE
            JSR   RDBLK
            BCS   :RESOUT
            LDY   #>DESBUF
            JSR   SWAPIB
            JSR   WTBLK
            BCS   :RESOUT
:DOMORE2    INC   :TEMP
            BPL   :DOMORE1
:RESOUT     RTS
*
*
*
:DOS33      STA   TRACK       ;TO END OF
            STA   RTRACK      ;FILENAME BUF
            LDY   #$20
            STA   (POINT),Y
            LDY   #$00
            LDA   #$FF        ;WRITE $FF AS
            STA   (POINT),Y   ;TRACK #
            INY
            LDA   (POINT),Y
            STA   SECTOR
            STA   RSECTR
            LDX   :TEMP
            LDA   :VTOCPAG,X  ;SET POINTERS
            STA   POINT+1     ;TO PROPER
            LDA   :TSLPAG,X   ;VTOC & TSLIST
            STA   POINT2+1
            STA   RPAGE
            LDY   #$00
            STY   POINT
            STY   POINT2
            INY
            STY   RCMND       ;1
            JSR   FREES       ;FREE TSLIST
:NXTSECT    JSR   DORWTS      ;READ TSLIST
            LDY   #$0C
            STY   :COUNT
:NXTPAIR    LDY   :COUNT      ;LOOP THROUGH
            LDA   (POINT2),Y  ;NONZERO TS
            STA   TRACK       ;PAIRS FREEING
            INY
            ORA   (POINT2),Y  ;SECTORS
            BEQ   :NEXT
            LDA   (POINT2),Y
            STA   SECTOR
            JSR   FREES
:NEXT       INC   :COUNT
            INC   :COUNT
            BNE   :NXTPAIR
            LDY   #$01
            LDA   (POINT2),Y  ;GET POINTER
            STA   TRACK       ;TO NEXT TSLIST
            STA   RTRACK
            INY
            ORA   (POINT2),Y
            BEQ   :TSOUT      ;OUT IF ZERO
            LDA   (POINT2),Y
            STA   SECTOR
            STA   RSECTR
            JSR   FREES       ;FREE NEXT LIST
            JMP   :NXTSECT    ;BACK FOR MORE.
:TSOUT      RTS
:COUNT      DB    $0
:TEMP       DB    $0
:MIBNUM     DB    $0,$0
*
*  KEEP AN EYE ON THESE! <--
*VTOCPAG DB    $13,$4A    ;VTOC1,VTOC2
*TSLPAG  DB    $12,$0C    ;SRCTSL,DSTTSL
:VTOCPAG    DB    #>VTOC1
            DB    #>VTOC2
:TSLPAG     DB    #>SRCTSL
            DB    #>DSTTSL

