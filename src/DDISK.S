            TYP   BIN
            DSK   ../build/DDISK.O
            PUT   VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/DODEV.VARS
            ORG   DODEVEND
DDISK       
            ORG   *+3
*
* DELETE DISK
* shared routines
*
            BIT   DOSNOW
            BPL   :DDDOS33
            JMP   :PDDISK
*
:DDDOS33    LDA   #>CAT1
            JSR   CLRCAT
            LDA   #$00
            TAX
:BLAHLP     STA   VTOC1,X     ;ZERO VTOC
            INX
            BNE   :BLAHLP
            LDX   #$11        ;SET NEEDED
            STX   VTOC1+1     ;PARAMETERS
            STX   VTOC1+$30
            STX   RTRACK
            DEX               ;10
            STX   VTOC1+$35
            DEX               ;F
            STX   RSECTR
            STX   VTOC1+2
            LDA   #$FE
            STA   VTOC1+6
            LDA   #$7A
            STA   VTOC1+$27
            LDA   #$23
            STA   VTOC1+$34
            LDA   #$FF
            LDX   #$3C        ;START AT TRK 1
:FFLOOP     STA   VTOC1,X     ;WRITE PART
            STA   VTOC1+$1,X
            INX               ;OF BITMAPS
            INX
            INX
            INX
            CPX   #$C4
            BCC   :FFLOOP
            LDX   #$00
            STX   VTOC1+$7C   ;ZERO CATALOG
            STX   VTOC1+$7D   ;BITMAP
            INX               ;1
            STX   VTOC1+$31
            STX   VTOC1+$37
            INX               ;2
            STX   RCMND
            INX               ;3
            STX   VTOC1+3
            LDA   #>CAT1
            STA   RPAGE
:LOOP       JSR   DORWTS      ;WRITE ENTIRE
            INC   RPAGE       ;TRACK
            DEC   RSECTR
            BNE   :LOOP
            LDA   #>VTOC1
            STA   RPAGE
            JSR   DORWTS
            JMP   ZIPDOS
*
* DELETE PRODOS DISK
*
* USED TO CREATE NEW DIRECTORY FOR
* FORMAT COMMAND AND FOR DELETE DISK
* COMMAND
*
:PDDISK     JSR   GTBLKS
            BCC   :PDD0
*
* IT'S SOME SORT OF /RAM. IF IT'S
* A LARGE ONE, FORMAT IT.
*
            CPY   #0
            BEQ   :NADA
            JMP   SPLFRM      ;FORMAT IT
:NADA       RTS
*
:PDD0       STX   :TOTBLK
            STY   :TOTBLK+1
*
* WRITE OUT BOOT BLOCK
*
            LDY   #0
            STY   BLKNUM
            STY   BLKNUM+1
:BOOTLP     LDA   PBOOT,Y
            STA   VTOC1,Y
            LDA   PBOOT+$100,Y
            STA   VTOC1+$100,Y
            INY
            BNE   :BOOTLP
            LDA   #>VTOC1
            STA   RPAGE
            STA   POINT+1
            JSR   DOWBLK
*
            LDA   #0
            STA   POINT
            JSR   PNTFIL
*
            LDA   #3
            STA   VTOC1+2
            LDA   #$C3
            STA   VTOC1+$22
            LDA   #$27
            STA   VTOC1+$23
            LDA   #$0D
            STA   VTOC1+$24
            LDA   #6
            STA   VTOC1+$27
            LDA   :TOTBLK+1
            STA   VTOC1+$2A
            LDA   :TOTBLK
            STA   VTOC1+$29
*
* STORE CREATION DATE AND TIME
*
            JSR   GETDAT
            LDY   #4
:CDTLP      LDA   CRTDAT-1,Y
            STA   VTOC1+$1B,Y
            DEY
            BNE   :CDTLP
*
:DLP2       LDA   VOLNAM,Y
            BEQ   :DLP2OUT
            STA   VTOC1+$5,Y
            INY
            BNE   :DLP2
*
:DLP2OUT    TYA
            ORA   #$F0
            STA   VTOC1+4
            LDA   #2
            STA   BLKNUM
            JSR   DOWBLK
*
            JSR   PNTFIL0
*
*
* WRITE OUT REST OF DIRECTORY
*
            LDA   #2
            STA   VTOC1
            ASL               ;2 --> 4
            STA   VTOC1+2
:D4LP       LDY   VTOC1
            INY
            STY   BLKNUM
            JSR   DOWBLK
            INC   VTOC1
            LDY   VTOC1+2
            BEQ   :D4OUT
            INY
            CPY   #6
            BNE   :D4LPA
            LDY   #0
:D4LPA      STY   VTOC1+2
            JMP   :D4LP
*
*
* WRITE OUT BITMAP
*
:D4OUT      LDA   #6
            STA   BLKNUM
:BMLP1      LDA   :TOTBLK+1
            SEC
            SBC   #$10
            BCC   :BM2
            STA   :TOTBLK+1
*
* WRITE A BLOCK OF FF'S
*
            LDA   #$FF
            JSR   PNTFIL
            JSR   :BMWBLK
            INC   BLKNUM
            BNE   :BMLP1
*
* WRITE OUT LAST BLOCK OF BITMAP
*
:BM2        JSR   PNTFIL0     ;RETURNS WITH Y=0
*LDY #0
:BM2LP      LDA   :TOTBLK+1
            BEQ   :BM3
            DEC   :TOTBLK+1
            LDX   #$20
            LDA   #$FF
:BM2LPB     STA   (POINT),Y
            INY
            BNE   :BM2Z
            INC   POINT+1
:BM2Z       DEX
            BNE   :BM2LPB
            BEQ   :BM2LP
*
:BM3        LDA   :TOTBLK
            SEC
            SBC   #8
            BCC   :BM4
            STA   :TOTBLK
            LDA   #$FF
            STA   (POINT),Y
            INY
            BNE   :BM3
            INC   POINT+1
            BNE   :BM3
*
:BM4        LDX   :TOTBLK
            LDA   :BITS,X
            STA   (POINT),Y
            JSR   :BMWBLK
*
* MARK USED BLOCKS IN BITMAP
*
            LDA   BLKNUM
            CMP   #6
            BEQ   :MARKDN     ;ONE BLK BM
            STA   :TEMP
            LDA   #6
            STA   BLKNUM
            LDA   #>VTOC1
            STA   BM
            JSR   DORBLK
:MARKIT     LDX   :TEMP       ;BLK LO
            LDA   #0          ;BLK HI
            JSR   MRKBLK
            DEC   :TEMP
            LDA   :TEMP
            CMP   #7
            BCS   :MARKIT
            JSR   DOWBLK
:MARKDN     RTS
*
:BMWBLK     LDA   BLKNUM
            CMP   #6
            BNE   :BMW1
*
* MARK BLOCKS 0 - 6 AS USED
*
            LDA   #$01
            STA   VTOC1
:BMW1       JMP   DOWBLK

*
:TOTBLK     DB    $0,$0
:TEMP       DB    $0
:BITS       DB    $00,$80,$C0,$E0,$F0,$F8,$FC,$FE
*
PBOOT       PUTBIN  ../build/BOOTSEC.PRO.O
*
DDISKEND
