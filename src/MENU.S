            TYP   BIN
            DSK   ../build/MENU.O
            PUT   VARS
            PUT   ../build/MM.VARS
            PUT   ../build/DRIVE35.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/ERRORS.VARS
            ORG   ERRORSEND

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
*
* Close MM if it appears to be open.
* [4am] This is now the only place that checks this,
* so it is inlined. If COPY used Memory Manager, it
* will still be 'open' (MMISOPEN) and decompressed in
* main memory (at MMSPOT) -- even if the operation
* completed normally. In previous versions, COPY tried
* to ensure MM was always closed before returning, only
* to immediately jump to FILER, which had to check MM
* again anyway because the user could have pressed
* [Ctrl-Reset] during a COPY operation and bypassed the
* cleanup.
*
*CLOSEMM
            BIT   MMISOPEN
            BPL   :CLOSMMQ
            LDA   #MMCLOSE
            STA   MMCMD
            JSR   MM
            LDA   #0
            STA   MMISOPEN
:CLOSMMQ
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
            LDA   #$16
            JSR   VLEFT
            LDA   DATE
            LDX   DATE+1
            JSR   SHODAT
            LDX   #$00        ;MAIN MENU
            STX   RADR
            STX   TOPDIF
* falls through to CHOOZ0
*
CHOOZ0      EQU   *
            JSR   CHOPOS
            JSR   PRHERE
            ASC   "Use hotkey or",FF,8D
            ASC   "arrows & [Return]"
            ASC   "to select",FF,8D,FF,8D,FF,8D,FF,8D,FF,8D,FF,00
            JSR   INIT
            LDX   #:UMAIN
            JSR   CHOOZ
            LDX   #$FF
            STX   OPTCHS
            TAX
            ASL
            TAY
            LDA   MENUTBL,Y
            STA   :JUMP+1
            LDA   MENUTBL+1,Y
            STA   :JUMP+2
            LDA   SUBMNIDX,X  ; check for submenu
            BMI   :JUMP       ; no submenu
            TAX
            JSR   :CHOOZ1     ; yes display submenu
            BCS   CHOOZ0      ; no selection from submenu
:JUMP       JSR   $1000       ; fake address, modified above
            JMP   ($3F2)
*
:CHOOZ1     JSR   CHOPOS
            JSR   PRHERE
            DB    $FF,$8D,$FF,$8D
            ASC   "Select option:",FF,8D,00
* falls through to CHOOZ
*
CHOOZ       EQU   *
            JSR   MENU
:LOOP1      JSR   GETKEY
            CMP   #$9B
            BNE   :NOTESC
            RTS               ;C=1 on exit
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
            STA   CHOOZOPT
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
MENU        EQU   *
            LDA   #4          ;assume VTAB 4
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
HOTKEYS     EQU   *
            ASC   "XCDLRAFYVMBU/EQ"  ; main menu
            ASC   "PD"        ; FORMAT submenu
            ASC   "FDWO"      ; COPY submenu
            ASC   "NFDH"      ; CATALOG submenu
            ASC   "FDS"       ; VERIFY submenu
            ASC   "VT"        ; VIEW submenu
            ASC   "FDO"       ; DELETE submenu
            ASC   "FV"        ; RENAME submenu
            ASC   "QMR"       ; QUIT submenu

*
* Menu/submenu IDs for CHOOZ
*
            DUM   0
:UMAIN      DS    1
:UCATALOG   DS    1
:UDELETE    DS    1
:UVERIFY    DS    1
:UVIEW      DS    1
:UFORMAT    DS    1
:UCOPY      DS    1
:URENAME    DS    1
:UQUIT      DS    1
            DEND
*
SUBMNIDX    EQU   *
            DB    :UCOPY      ; COPY
            DB    :UCATALOG   ; CATALOG
            DB    :UDELETE    ; DELETE
            DB    $FF         ; LOCK (no submenu)
            DB    :URENAME    ; RENAME
            DB    $FF         ; ALPHA (no submenu)
            DB    :UFORMAT    ; FORMAT
            DB    :UVERIFY    ; VERIFY
            DB    :UVIEW      ; VIEW
            DB    $FF         ; TSMAP (no submenu)
            DB    $FF         ; BOOTPG (no submenu)
            DB    $FF         ; UNDEL (no submenu)
            DB    $FF         ; MAKESUB (no submenu)
            DB    $FF         ; SETCLOCK (no submenu)
            DB    :UQUIT      ; QUIT
*
MENUEND
