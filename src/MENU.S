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
            JSR   VDINIT      ;[4am] also sets ALTCHARSET
            JSR   GETDAT
            JSR   CLOSEMM     ;Close MM in case of Reset.
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
            JSR   HOME        ;Clear screen before switching to 40 cols
            JSR   COL40       ; so you don't see 80 switch in and out.
            LDA   #0          ;But now CV is at bottom of screen.
            JSR   VLEFT       ; Put it back at the top before printing the...
            LDA   #MHEADER
            JSR   PRINT
            JSR   :CINFO      ;DISK INFO LINE
            LDX   #$00        ;MAIN MENU
*            STX   PRNTR?
            STX   RADR
            STX   TOPDIF
CHOOZ0
            JSR   CHOPOS
            JSR   PRHERE
            ASC   "Use hotkey or",2F,8D
            ASC   "arrows & [Return]"
            ASC   "to select",2F,8D,2F,8D,2F,8D,2F,8D,2F,8D,2F,00
            JSR   INIT
            LDX   #$00
            JSR   CHOOZ
            LDX   #$FF
            STX   OPTCHS
*
            ASL
            TAY
            LDA   MENUTBL,Y
            STA   :JUMP+1
            LDA   MENUTBL+1,Y
            STA   :JUMP+2
:JUMP       JSR   $1000
            JMP   FILER
*
CHOOZ1      JSR   CHOPOS
            JSR   PRHERE
            DB    $2F,$8D,$2F,$8D
            ASC   "Select option:",2F,8D,00
*
CHOOZ       JSR   MENU
:LOOP1      JSR   GETKEY
            CMP   #$9B
            BNE   :NOTESC
            JMP   CHOOZ0
:NOTESC     JSR   CHKKEY0
            BNE   :NOTARO
            BCS   :RIGHTA
            BCC   :LEFTA      ;ALWAYS
*
:NOTARO     CMP   #$8D        ;CR?
            BEQ   :CR
            STA   :LASTKEY
            LDY   FIRST,X
:HKLOOP     LDA   :LASTKEY
            CMP   HOTKEYS,Y
            BEQ   :HK
            INY
            TYA
            CMP   LAST,X
            BNE   :HKLOOP
            BEQ   :LOOP1      ;ALWAYS
*
:HK         TYA
            STA   CHOICE,X
            JSR   MENU
* fall through to :CR
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
* DISPLAY MENU
MENU        LDA   #4          ;assume VTAB 4
            CPX   #0          ;is main menu (X=0)?
            BEQ   :USE4       ;Y->VTAB 4
            ASL               ;N->VTAB 8
:USE4       JSR   VLEFT
            LDA   FIRST,X     ;START AT ITS
            STA   :OPTNUM     ;1ST OPTION
:LOOP       PHA
            TAY
            LDA   HOTKEYS,Y
            JSR   PCOUT
            LDA   #"-"
            JSR   PCOUT
            PLA
            CMP   CHOICE,X    ;CHOSEN ONE?
            BNE   :SEEOPT
            JSR   PINVRS      ; INVERSE IT
:SEEOPT     JSR   PRINT       ;PRINT IT
            JSR   PNORML
            JSR   CROUT
            INC   :OPTNUM     ;NEXT OPTION
            LDA   :OPTNUM
            CMP   LAST,X      ;LOOP BACK TIL
            BNE   :LOOP       ;END OF MENU
            RTS
:OPTNUM     DB    $0
:LASTKEY    DB    $0
*
* Menus: (USE THE NAMED IDS LISTED IN MESSAGES)
*  0 Main
*  1 Catalog
*  2 Delete
*  3 Verify
*  4 View
*  5 Format
*  6 Copy
*  7 Rename
*
*  Menu:          0       1          2         3        4       5        6         7
LAST        DB    MQUIT+1,MWHIDDEN+1,MDELDOS+1,MSPEED+1,MTEXT+1,MDOS33+1,MCOPDOS+1,MVOLUME+1
FIRST       DB    MCOPY,MNORMAL,MDELFILE,MVERFILE,MVALUES,MPRODOS,MCOPFILE,MFILES
CHOICE      DB    MCOPY,MNORMAL,MDELFILE,MVERFILE,MVALUES,MPRODOS,MCOPFILE,MFILES
*
*   SEE DISK INFO
*
:CINFO
*            LDA   #$15
*            JSR   VLEFT
*            LDA   #$21
*            STA   CH
*            JSR   PRHERE
*            INV   "PRINTER"
*            DB    $0
            LDA   #$16
            JSR   VLEFT
            LDA   DATE
            LDX   DATE+1
            JSR   SHODAT
*            LDA   #$21
*            STA   CH
*            LDA   PSLOT
*            BEQ   :OFF
*            PHA
*            LDA   #MSLOT
*            JSR   PRINT
*            PLA
*            JSR   PHHEX
*            JMP   CROUT
*
*:OFF        JSR   PRHERE
*            ASC   "  Off "
*            DB    $8D,0
            RTS
*
* CLEAR SCREEN AND DISPLAY FUNCTION TITLE
TOP1        JSR   HOME
            LDA   #0
            STA   WNDTOP
            JSR   TABV
            LDA   CHOICE      ;FUNCTION NAME
            JSR   PRINT
            JSR   PRSPC
            LDA   OPTCHS
            BMI   :TOP1A
            JSR   PRINT
:TOP1A      RTS
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
CLOSE       JSR   MLI
            DB    $CC
            DW    :CLSLST
            RTS
:CLSLST     DB    $1,$0
