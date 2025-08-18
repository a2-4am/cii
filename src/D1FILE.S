            TYP   BIN
            DSK   ../build/D1FILE.O
            PUT   VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/DDISK.VARS
            ORG   DDISKEND
D1FILE
            ORG   *+3
*
* DELETE 1 FILE
* called by Delete operation
* and after failed Copy File operation
*
            STA   :TEMP
            LDY   #$00
            LDA   (POINT),Y   ;MOVE TRACK #
            BIT   DOSNOW
            BMI   :DPRODOS
            JMP   :DDOS33
:D1FILEQ    RTS
*
:DPRODOS    PHA
            AND   #$F0
            STA   :TEMP
            PLA
            AND   #$0F        ;NAME LEN
            BEQ   :D1FILEQ    ;ALREADY DEL'D
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
            BCS   :D1ERR
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
:D1ERR      RTS

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
:DDOS33     STA   TRACK       ;TO END OF
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
*
D1FILEEND
