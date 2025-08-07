*
MONTH1      ASC   "JFMAMJJASOND"
MONTH2      ASC   "AEAPAUUUECOE"
MONTH3      ASC   "NBRRYNLGPTVC"
*
*
*************************************
*                                   *
*           MENU STUFF              *
*                                   *
*************************************
*
*
FILER       LDX   #$FF
            TXS
            CLD
            JSR   PNORML
            JSR   VDINIT
            JSR   DOC00F         ;ALTCHARSET ON
            JSR   GETDAT
            JSR   CLOSEMM        ;Close MM in case of Reset.
*
            JSR   FMTFIX
            LDA   #0
            STA   FMT400K
*
            JSR   CLOSE
*
* IF WE'RE ON A //E,
* RESTORE AUX MEM IRQ VECTOR JUST
* IN CASE IT'S BEEN CLOBBERED BY
* 'COPY DISK'
*
            BIT   A2E
            BPL   :IIPLUS
*
            STA   $C009
            LDA   $C083
            LDA   $C083
            LDA   IRQSAV
            STA   $FFFE
            LDA   IRQSAV+1
            STA   $FFFF
            LDA   $C082
            STA   $C008
*
:IIPLUS     LDA   #$23
            STA   LINLIM
            LDA   #>TOP11
            STA   HIMEM
            LDA   #$80
            STA   DELFLG
            JSR   HOME           ;Clear screen before switching to 40 cols
            JSR   COL40          ; so you don't see 80 switch in and out.
            LDA   #0             ;But now CV is at bottom of screen.
            JSR   VLEFT          ; Put it back at the top before printing the...
            LDA   #$3E           ;HEADER
            JSR   PRINT
            JSR   CINFO          ;DISK INFO LINE
            LDX   #$00           ;MAIN MENU
            STX   PRNTR?
            STX   RADR
            STX   TOPDIF
            JSR   CHOOZ0         ;SELECT
            ASL
            TAY
            LDA   :MENUTBL,Y
            STA   :JUMP+1
            LDA   :MENUTBL+$1,Y
            STA   :JUMP+2
:JUMP       JSR   $1000
            JMP   FILER
*
*
:MENUTBL    DW    COPY
            DW    CATLOG
            DW    DELETE
            DW    LOCK
            DW    RENAME
            DW    ALPHA
            DW    FORMAT
            DW    VERIFY
*
            DW    VIEW
            DW    TSMAP
            DW    BOOTPG
            DW    UNDEL
            DW    MAKEDR
            DW    INFO
            DW    QUIT
*
*
* Close MM if it appears to be open.
*
CLOSEMM     BIT   MMISOPEN
            BPL   :CLOSMMQ
            LDA   #MMCLOSE
            STA   MMCMD
            JSR   MM
            LDA   #0
            STA   MMISOPEN
:CLOSMMQ    RTS
*
*
* MORE MENU STUFF
*
* DISPLAY MENU & SELECT DESIRED OPTION
* XREG=# OF DESIRED MENU  ->
* CARRY SET IF ESC OUT, ELSE
* ACC HAS TRUE CHOICE #
*
CHOOZ0      JSR   CHOPOS
            LDA   #$55
            JSR   PRINT
            JSR   INIT
            LDX   #$00
            JSR   CHOOZ
            LDX   #$FF
            STX   OPTCHS
            RTS
*
CHOOZ1      JSR   CHOPOS
            LDA   #$56           ;OPTION
            JSR   PRINT
*
CHOOZ       JSR   MENU
:LOOP1      JSR   CHKKEY
            BNE   :NOTARO
            BCS   :RIGHTA
            BCC   :LEFTA
*
:NOTARO     CMP   #$8D           ;CR?
            BNE   :LOOP1
*
:CR         SEC
            LDA   CHOICE,X
            STA   OPTCHS
            SBC   FIRST,X
            LDX   #$00
            STX   WNDLFT
            LDX   #$28
            STX   WNDWTH
            CLC
            RTS
*
:LEFTA      DEC   CHOICE,X
            LDA   CHOICE,X
            CMP   FIRST,X
            BPL   CHOOZ
            LDA   LAST,X
            STA   CHOICE,X
            DEC   CHOICE,X
            JMP   CHOOZ
*
:RIGHTA     INC   CHOICE,X
            LDA   CHOICE,X
            CMP   LAST,X
            BMI   CHOOZ
            LDA   FIRST,X
            STA   CHOICE,X
            JMP   CHOOZ
*
CHKKEY      EQU   *
            JSR   KYESC
            CMP   #$88           ;LEFT ARROW
            BEQ   :RETCLR
            CMP   #$8B           ;UP ARROW
            BEQ   :RETCLR
            CMP   #$95           ;RIGHT ARROW
            BEQ   :RETSET
            CMP   #$8A
            RTS
:RETCLR     CLC
:RETSET     RTS
*
*
* DISPLAY MENU
MENU        LDA   #4
            CPX   #0
            BEQ   :USE4
            ASL
:USE4       JSR   VLEFT
            LDA   FIRST,X        ;START AT ITS
            STA   :OPTNUM        ;1ST OPTION
:LOOP       CMP   CHOICE,X       ;CHOSEN ONE?
            BNE   :SEEOPT
            JSR   PINVRS         ; INVERSE IT
:SEEOPT     JSR   PRINT          ;PRINT IT
            JSR   PNORML
            JSR   CROUT
            INC   :OPTNUM        ;NEXT OPTION
            LDA   :OPTNUM
            CMP   LAST,X         ;LOOP BACK TIL
            BNE   :LOOP          ;END OF MENU
            RTS
:OPTNUM     DB    $0
*
* Menus:
*  0 Main
*  1 Catalog
*  2 Delete
*  3 Verify
*  4 View
*  5 (unused)
*  6 (unused)
*  7 Format
*  8 Copy
*  9 Rename
*
*  Menu:        0   1   2   3   4   5   6   7   8   9
LAST        DB    $0F,$19,$21,$1C,$1E,$00,$00,$24,$15,$42
FIRST       DB    $00,$15,$1E,$19,$1C,$00,$00,$22,$11,$40
CHOICE      DB    $00,$15,$1E,$19,$1C,$00,$00,$22,$11,$40
*
* POSITION FOR MAIN SCREEN CHOOSES
*
CHOPOS      LDA   #$12
            STA   WNDWTH
            LDA   #$16
            STA   WNDLFT
            LDA   #$04
            JMP   VLEFT
*
VDINIT      JSR   INIT
            JSR   SETNOR
VDINT1      JSR   SETVID
            JSR   DOC00F         ; [4am] set ALTCHARSET
            JMP   SETKBD
*
*


