***********************************
*                                 *
*       CATALOG DISPLAY           *
*                                 *
***********************************
*
* 'DO' THE CATALOG DISPLAY &
* EVERYTHING THAT IT INVOLVES
*
CATDIS      JSR   INITCD
            LDA   #0
            STA   SP
            JSR   RDACNT
            LDA   NACTIV
            BNE   CATDS2
            JSR   CROUT
            LDA   #MNOFILES
            JMP   PRTPRS
*
CATDS1      LDA   CURR
            PHA
            JSR   INITCD
            PLA
            STA   CURR
            JSR   RDACNT
CATDS2      LDA   NACTIV
            BEQ   :NOFILES
            LDA   STATE
            CMP   #$04
            BEQ   :BOOTMES
            JSR   ST8MSG
            JMP   CDDOKEY
*
:BOOTMES    LDA   #MFILE
            JSR   LOWMES
            JSR   PRHERE
            ASC   ": "
            DB    $0
            LDX   #$00
:SEEFILE    LDA   DATA+$75,X
            JSR   PCOUT
            INX
            CPX   #$1E
            BCC   :SEEFILE
            JSR   PRHERE
            DB    $8D
            ASC   "is the current boot program."
            DB    $8D,$0
            LDA   #MPSTAT45
            JSR   PRINT
            JMP   CDDOKEY
*
:NOFILES    JSR   CROUT
            LDA   #MNOFILES
            JSR   PRINT
            LDA   #MPRESS
            JSR   PRINT
            JSR   GETKEY
            CMP   #"<"
            BEQ   :GO1
            CMP   #$AC        ;","
            BEQ   :GO1
            JMP   FILER
:GO1        JSR   DO1
            JMP   CATDS1
*
*
* SCROLL CATALOG DISPLAY FORWARD
* CARRY CLEAR IF SUCCESS
*  SET IF FAIL
SCROLF      LDX   CURR        ;IF BEFORE
            INX               ;END OF
            CPX   NACTIV      ;CATALOG:
            BCS   :OUTBAD
            STX   CURR
:OUTBAD     RTS
*
*        CATALOG DISPLAY
*   KEYPRESS FUNCTION HANDLER
*
CDDOKEY     JSR   SEECAT
            JSR   CHKKEY      ;GET CHARACTER
            STA   :TEMP
            BNE   :NOTARO
            BCS   :FSCROL     ;DOWN OR RIGHT ARROW
            BCC   :BSCROL     ;UP OR LEFT ARROW
*
:NOTARO     SEC
            SBC   #$B0        ;IS IT A #?
            CMP   #$0A
            BCS   :LOOKUP
            STA   CPYDIG      ;YES: SAVE IT
            LDA   #$23        ;& SET # FLAG
            BNE   :DOLOOK     ;ALWAYS
*
:BSCROL     LDX   CURR        ;BACKWARD
            BEQ   CDDOKEY     ;SCROLL
            DEX
            STX   CURR
            JMP   CDDOKEY
*
:FSCROL     JSR   SCROLF      ;FORWARD
            JMP   CDDOKEY     ;SCROLL
*
:LOOKUP     LDA   :TEMP
            CMP   #"G"
            BNE   :DOLOOK
*
* SET PREFIX IN CASE WE CHANGED DIR'S
*
:DOGO       JSR   SETPFX
            SEC
            LDA   #0
            RTS
*
:DOLOOK     LDX   #7
:NXTCHAR    CMP   :CHARS,X    ;CONVERT CHAR
            BEQ   :INDEX      ;TO INDEX #
            DEX
            BPL   :NXTCHAR
            CMP   #"D"
            BNE   CDDOKEY     ;NOT FOUND
            LDX   #3          ;ALLOW D=U
*
:INDEX      CPX   #6
            BCC   :INDEX1
            DEX               ;7-->5,6-->4
            DEX
:INDEX1     STX   :TEMP       ;INDEX INTO
            LDA   STATE       ;STATE TABLE:
            ASL               ;TIMES 2
            ADC   STATE       ;TIMES 3
            ASL               ;TIMES 6
            CLC
            ADC   :TEMP       ; + CHAR INDEX
            ASL               ; * 2
            ADC   #:TABLE     ; + TABLE ADDR
            STA   POINT       ;PUT ADDR IN
            LDA   #>:TABLE    ;POINTER
            ADC   #$00
            STA   POINT+1
            LDY   #$00
            LDA   (POINT),Y   ;LOAD VALUE
            STA   :JUMP+1     ;FROM ADDR TO
            INY               ;JUMP BUFFER
            LDA   (POINT),Y
            STA   :JUMP+2
:JUMP       JSR   $1000
            BCC   CDDOKEY
            CMP   #$FF
            BNE   :OUT
            JMP   CATDS1      ;DIR CHANGE
:OUT        RTS
*
:TEMP       DB    $00
:CHARS      DB    $8D,$23
            ASC   "EU<>,."
*
* STATE TABLE FOR CATALOG DISPLAY
* STATE 0
* COPY
:TABLE      DW    CPYADD
            DW    CPYNUM
            DW    CPYENT
            DW    CPYDEL
            DW    DO1
            DW    DO2
* STATE 1
* DELETE, UNDELETE, VIEW
            DW    TOGGLE
            DW    NIL
            DW    PATTRN
            DW    NIL
            DW    DO1
            DW    DO2
* STATE 2
* LOCK/UNLOCK
            DW    LOKAST
            DW    NIL
            DW    LOKPAT
            DW    NIL
            DW    DO1
            DW    DO2
* STATE 3
* RENAME
            DW    NEWNAM
            DW    NIL
            DW    NOPATT
            DW    NIL
            DW    DO1
            DW    DO2
* STATE 4
* CHANGE BOOT PROGRAM
            DW    CDDOKEY
            DW    NIL
            DW    NOPATT
            DW    NIL
            DW    NIL
            DW    NIL
* STATE 6
* IDENTICAL FILES - DIFFERENT DISKS
            DW    NIL
            DW    NIL
            DW    NOPATT
            DW    NIL
            DW    DO1
            DW    DO2
*
CPYADD      EQU   *
            LDX   CURR        ;IS IT NOW
            LDA   STATUS,X    ;EMPTY?
            BNE   :NOPE
            INC   FILNUM      ;YES:INC TOTAL
            LDA   FILNUM      ;& PUT # INTO
            STA   STATUS,X    ;STATUS
:NOPE       CLC
            RTS
*
CPYTAB      EQU   *
            JSR   LOHERE
            ASC   "Insert copy number: [Return]-Complete"
            DB    $8D
            ASC   "insertion, [Esc]-Back out"
            DB    $0
            LDA   CURRV       ;TAB TO
            JSR   VLEFT       ;CURRENT LINE
            LDA   #$00        ;CLEAR HIGH
            STA   CPYDIG+1    ;DIGIT
            STA   CPYDIG+2
            JMP   PINVRS
*
*
CPYNUM      EQU   *
            JSR   CPYTAB
            LDA   CPYDIG      ;PRINT DIGIT
            JSR   PHHEX
            JSR   PNORML
            LDA   #2
            STA   :TEMP
:CHAR2      JSR   PRDKEY
            CMP   #$8D        ;INPUT CR?
            BEQ   :CPYCR      ; INSERT #
            CMP   #$9B        ;ESCAPE OR
            BEQ   :GOOUT1
            CMP   #$88        ;LEFT ARROW?
            BEQ   :GOOUT1     ; BACK OUT
            LDX   :TEMP
            BEQ   :CHAR2      ;NO MORE DIGS
            SEC
            SBC   #$B0        ;ANOTHER DIGIT?
            CMP   #$0A
            BCS   :CHAR2      ;NO:TRY AGAIN
            LDX   CPYDIG+1
            STX   CPYDIG+2
            LDX   CPYDIG      ;YES:SAVE IT
            STX   CPYDIG+1
            STA   CPYDIG
            JSR   PINVRS      ; & PRINT IT
            JSR   PHHEX
            JSR   PNORML
            DEC   :TEMP
            JMP   :CHAR2
:GOOUT1     JMP   :OUT
*
:CPYCR      LDA   CPYDIG+2
            CMP   #3
            BCS   :OUT1       ;>=300
            ASL
            ASL
            ASL
            STA   :TEMP
            ASL
            ADC   :TEMP
            ADC   CPYDIG+2
            ASL
            ASL
            STA   :TEMP
            LDA   CPYDIG+1    ;CONVERT
            ASL               ;DECIMAL DIGITS
            ASL               ;TO HEX BYTE
            ADC   CPYDIG+1
            ASL
            ADC   CPYDIG
            ADC   :TEMP
            BCS   :OUT1       ;>255
            BEQ   :OUT1       ;# = 0
            STA   :INSERT     ;SAVE IT
            LDX   #$FF        ;SET UP
            LDY   CURR
            LDA   STATUS,Y    ;IS A # ALREADY
            BEQ   :LOOP2      ;THERE?
            CMP   :INSERT     ;YES:EXIT IF =
            BEQ   :OUT1       ;TO INSERT
            BCC   :LOOP3
*
*  INSERT < CURRENT STATUS #
:LOOP1      LDA   STATUS,X    ;INC ALL #'S
            CMP   :INSERT     ;THAT ARE
            BCC   :NOT1       ;>= INSERT
            CMP   STATUS,Y    ;& < CURRENT
            BCS   :NOT1       ;STATUS #
            INC   STATUS,X
:NOT1       DEX
            CPX   #$FF
            BNE   :LOOP1
            LDA   :INSERT     ;PUT INSERT
            STA   STATUS,Y    ;INTO STATUS
:OUT1       JMP   :OUT
*
*  NO # IN CURRENT STATUS YET
:LOOP2      LDA   STATUS,X    ;INC ALL #'S
            CMP   :INSERT     ;THAT ARE
            BCC   :NOT2       ;>= INSERT
            INC   STATUS,X
:NOT2       DEX
            CPX   #$FF
            BNE   :LOOP2
            INC   FILNUM      ;BUMP UP COUNT
            JMP   :FINISH     ;FINISH BELOW
*
*  INSERT > CURRENT STATUS #
:LOOP3      LDA   :INSERT     ;DEC ALL #'S
            CMP   STATUS,X    ;THAT ARE
            BCC   :NOT3       ;> CURRENT
            LDA   STATUS,Y    ;STATUS #
            CMP   STATUS,X    ;& <= INSERT
            BCS   :NOT3
            DEC   STATUS,X
:NOT3       DEX
            CPX   #$FF
            BNE   :LOOP3
:FINISH     LDA   FILNUM      ;PUT LOWER OF
            CMP   :INSERT     ;FILENUM &
            BCC   :PUTIT      ;INSERT INTO
            LDA   :INSERT     ;STATUS
:PUTIT      STA   STATUS,Y
:OUT        LDA   #MPSTATE0
            JMP   LOWMES
:INSERT     DB    $0
:TEMP       DB    $0
*
CPYENT      EQU   *
            JSR   GETPAT
            BCS   :OUT
            LDA   #$00
            STA   CURR
:LOOP       JSR   JMATCH
            BCS   :NEXT
            LDX   CURR
            LDA   STATUS,X
            BNE   :NEXT
            INC   FILNUM
            LDA   FILNUM
            STA   STATUS,X
:NEXT       JSR   SEECAT
            JSR   SCROLF
            BCC   :LOOP
:OUT        LDA   LASTM
            STA   CURR
            LDA   #MPSTATE0
            JMP   LOWMES
*
CPYDEL      EQU   *
            JSR   DODEL
            BEQ   :CPYDEL0    ;NOTHING THERE
            DEC   FILNUM
:CPYDEL0    JSR   SEECAT
            CLC
            RTS
*
DODEL       LDY   CURR        ;IS SOMETHING
            LDA   STATUS,Y    ;THERE?
            BEQ   :NOPE
            LDX   #$FF        ;YES: LOOP
:LOOP       CMP   STATUS,X    ;THROUGH TO
            BCS   :SMALLER    ;DECREMENT ALL
            DEC   STATUS,X    ;HIGHER #'ED
:SMALLER    DEX               ;FILES
            CPX   #$FF
            BNE   :LOOP
            LDA   #$00        ;THEN DELETE
            STA   STATUS,Y    ;SELECTED ONE
            DEX               ;SET Z = 0
:NOPE       RTS
*
* 'DIVE OUT' of subdirectory
*
* entry point called by COPY, DELETE, and
* DISKMAP to return to parent directory
* after operating on all the relevant files
* in a subdirectory
*
DIVOUT      LDA   #0
            DB    $2C         ;HIDE LDA #$FF
*
* 'DIVE OUT' of subdirectory
*
* entry point called when user presses [<]
* to return to parent directory during the
* interactive catalog display
* 
DIVOT0      LDA   #$FF
            STA   :DIVFLAG
            LDA   #0
            STA   POINT       ;POINT TO
            LDA   #>SDIR      ; DIR HEADER
            STA   POINT+1
            LDY   #4
            LDA   (POINT),Y
            AND   #$F0        ;STOR TYPE
            CMP   #$F0
            BNE   :NOTROOT
:ISROOT     LDA   #MINROOT    ;ALREADY IN ROOT
            SEC
            RTS
*
:DIVFLAG    DB    $0
*
:NOTROOT    LDA   :DIVFLAG
            BNE   :SKIPCK
            LDA   SP
            BEQ   :ISROOT
:SKIPCK     LDY   #$27
            LDA   (POINT),Y   ;PARENT BLK
            STA   DIRBLK
            INY
            LDA   (POINT),Y
            STA   DIRBLK+1
            LDY   PFX
            LDA   PFX,Y
            CMP   #$2F
            BNE   :LOOP1
:LOOP       DEY
:LOOP1      LDA   PFX,Y
            CMP   #$2F
            BNE   :LOOP
            DEY
            STY   PFX
            LDA   SP
            BEQ   SP0
            DEC   SP
            LDX   SP
            LDA   CURSTK,X
SP0         STA   CURR
COM><       JSR   PRVNM
*
* IF WE'RE DOING 'COPY FILES', COPY
* PFX TO PPFX
*
            LDA   CHOICE
            BNE   :NOTCOPY
            LDY   #$3F
:MVLOOP     LDA   PFX,Y
            STA   PPFX,Y
            DEY
            BPL   :MVLOOP
:NOTCOPY    LDA   #$FF
NIL0        CLC
            RTS
*
DO1         BIT   DOSNOW
            BPL   NIL0
            JSR   DIVOT0
            JMP   DO1A
*
DO2         BIT   DOSNOW
            BPL   NIL0
            JSR   DIVEIN
DO1A        BCS   :ERR2
            SEC
            RTS
*
:ERR2       JSR   LOWMES
            JSR   KYESC
ST8MSG      LDA   STATE
            CLC
            ADC   #MPSTATE0
            JMP   LOWMES
*
* 'DIVE IN' to subdirectory
* called when user presses [>]
* to enter a subdirectory during the
* interactive catalog display
*
* also called from COPY after creating
* a subdirectory, from DELETE while
* deleting a subdirectory, and from
* DISKMAP while entering a subdirectory
*
DIVEIN      JSR   CURPNT
            JSR   DIR?
            BCS   :NOTDIR
            LDY   #$11
            LDA   (POINT),Y
            STA   DIRBLK
            INY
            LDA   (POINT),Y
            STA   DIRBLK+1
*
* APPEND FILENAME TO PREFIX
*
            LDY   #0
            LDA   (POINT),Y
            AND   #$0F
            STA   :NAMELEN    ;FILE NAME LEN
            LDX   PFX
            LDA   #$2F
            CMP   PFX,X       ;ENDING '/'?
            BEQ   :LOOP       ;YES: DON'T ADD
            STA   PFX+$1,X
            INX
:LOOP       INY
            INX
            CPX   #$40
            BCS   :TOOLONG
            LDA   (POINT),Y
            STA   PFX,X
            CPY   :NAMELEN
            BCC   :LOOP
            STX   PFX
            LDX   SP
            LDA   CURR
            STA   CURSTK,X
            INC   SP
            LDA   #0
            JMP   SP0
:NAMELEN    DB    $0
*
:NOTDIR     LDA   #MNOTSUB    ;C ALREADY SET
            RTS
:TOOLONG    LDA   #MTOOLNG0
            RTS
*
DIR?        LDY   #0
            LDA   (POINT),Y
            AND   #$F0
            CMP   #$D0
            BNE   :NOTDIR
            LDY   #$10
            LDA   (POINT),Y
            CMP   #$0F
            CLC
            BEQ   :OUT
:NOTDIR     SEC
:OUT        RTS
*
*
*
TOGGLE      EQU   *
            LDX   CURR        ;GET CURRENT
            LDA   STATUS,X    ;FILE STATUS
            EOR   #$FF        ;TOGGLE IT
            STA   STATUS,X    ;REPLACE IT
NIL         CLC
            RTS
*
PATTRN      EQU   *
            JSR   GETPAT      ;READ PATTERN
            BCS   :OUT
            LDA   #$00        ;INITIALIZE
            STA   CURR
:LOOP       JSR   JMATCH      ;TRY A MATCH
            BCS   :NEXT       ;IF SUCCESS:
            LDX   CURR
            LDA   #$FF        ; MARK THE
            STA   STATUS,X    ; ENTRY
:NEXT       JSR   SEECAT      ;DISPLAY &
            JSR   SCROLF      ;SCROLL
            BCC   :LOOP       ;TIL END
:OUT        LDA   LASTM
            STA   CURR
            JMP   ST8MSG
*
NOPATT      EQU   *
            LDA   CURR
            STA   LASTM
            JSR   LOHERE
            ASC   "Enter filename (one file)"
            DB    $8D
            ASC   "?"
            DB    $0
*
            JSR   GETFNM      ;GET FILENAME
            BCS   :OUT
            LDA   #$00
            STA   CURR
:LOOP       JSR   JMATCH      ;MATCH:ALL DONE
            BCC   :OUT
            JSR   SEECAT
            JSR   SCROLF      ;NO MATCH:
            BCC   :LOOP       ;TRY NEXT FILE
            LDA   LASTM       ;NONE:RESTORE
            STA   CURR        ;CURRENT FILE
:OUT        JMP   ST8MSG
*
LOKAST      JSR   CURPNT
            LDA   #$80        ;TOGGLE LOCK
            JSR   SETLOK
            LDA   #$01
            STA   FILNUM      ;FLAG IT
            CLC
            RTS
*
LOKPAT      EQU   *
            JSR   GETPAT      ;GET PATTERN
            BCS   :OUT
*           JSR   ASKLOK
*ASKLOK
            JSR   PRHERE
            DB    $8D
            ASC   "[L]ock or [U]nlock? ",00
:ALTRY      JSR   CASKEY
            CMP   #$9B
            BEQ   :ALOUT      ;C IS SET
            LDX   #$FF
            CMP   #"L"
            BEQ   :ALDO
            CMP   #"U"
            BNE   :ALTRY
            INX               ;FF --> 0
:ALDO       JSR   PCOUT
            CLC
:ALOUT
            BCS   :OUT
            STX   :LOCK
            LDA   #$00
            STA   CURR
:LOOP       JSR   JMATCH
            BCS   :NEXT       ;IF MATCH, GET
            LDA   :LOCK
            JSR   SETLOK
            LDA   #$01
            STA   FILNUM      ;FLAG IT
:NEXT       JSR   SEECAT
            JSR   SCROLF
            BCC   :LOOP
:OUT        LDA   LASTM
            STA   CURR
            LDA   #MPSTATE2
            JMP   LOWMES
:LOCK       DB    $0
*
NEWNAM      EQU   *
            JSR   LOHERE
            ASC   "Rename "
            DB    $0
            JSR   CURPNT
            JSR   CFILE       ;PRINT FILENAME
:ASKNAME    JSR   PRHERE
            DB    #$8D
            ASC   "as? "
            DB    $0
            JSR   GETFNM      ;GET NEW NAME
            BCS   :OUT
            JSR   PLACE       ;CHECK & PLACE
            LDX   CURR
            LDA   #$FF        ;MARK AS
            STA   STATUS,X    ;RENAMED
            LDA   #$01
            STA   FILNUM      ;FLAG IT
:OUT        LDA   #MPSTATE3
            JMP   LOWMES
*
* GET FILE NAME
*
GETFNM      EQU   *
            LDA   #$1E        ;DOS FILENAME LIMIT
            BIT   DOSNOW
            BPL   GETLN0
            LDA   #$0F        ;PRODOS FILENAME LIMIT
GETLN0      EQU   *
            STA   LINLIM
            JMP   GETLN
*
GETPAT      EQU   *
            LDA   CURR
            STA   LASTM
            JSR   LOHERE
            ASC   "Enter filename (,opt. filetypes)",8D,"? ",00
            LDA   #$24        ;PATTERN LIMIT
            BNE   GETLN0      ;ALWAYS
*
* INITIALIZES CATALOG DISPLAY
* called from catalog display, but also
* from DIVECK after diving into or out of
* a subdirectory, also from VIEW
*
INITCD      LDA   #$00
            STA   CURR
            STA   FILNUM
            STA   GO
            TAX               ;SET STATUSES
:LOOP       STA   STATUS,X    ;TO ZERO
            DEX
            BNE   :LOOP
            LDA   WNDTOP
            PHA
            LDA   WNDBTM
            PHA
            LDA   #4
            STA   WNDTOP
            LDA   #$13
            STA   WNDBTM
            JSR   HOME
            PLA
            STA   WNDBTM
            PLA
            STA   WNDTOP
            RTS
*
* SEE FILE QUEUE
*
* Entry point called by COPY, DELETE,
* UNDELETE, and VERIFY during their
* actual operation to show progress
* by displaying a non-interactive
* catalog display. '--MORE--' headers
* and footers are disabled, and the
* number of active files is controlled
* by the operation rather than by
* user interaction.
*
FILEQ       LDA   FILNUM
            STA   NACTIV
            LDA   #$FF
            DB    $2C         ;HIDE LDA #0
* FALL THRU
*
* SHOW A PAGE OF CATALOG
* CURR, NACTIV MUST BE
* INITIALIZED  ->
* Entry point called by the interactive
* catalog display to refresh the visible
* file list after user scrolls, marks,
* unmarks, renumbers, or enters a pattern.
*
SEECAT      EQU   *
            LDA   #0
            STA   CFLAG
            LDA   NACTIV      ;IF ANY
            BEQ   :OUT        ;ACTIVE FILES:
            LDX   #$00        ;FIND CAT. TOP
            LDA   NACTIV
            CMP   #$10
            BCC   :GOTTOP
            LDA   CURR
            CMP   #$08
            BCC   :GOTTOP
            LDA   NACTIV
            SBC   CURR
            CMP   #$08
            BCS   :ELSE
            SEC
            LDA   NACTIV
            SBC   #$0F
            TAX
            BNE   :GOTTOP
:ELSE       LDA   CURR
            SBC   #$07
            TAX
:GOTTOP     STX   SHOW        ;& PUT IN SHOW
            LDA   #$0F        ;START COUNTER
            STA   :COUNTER    ;AT 15
            LDA   #$03
            STA   :VCOUNT
            JSR   VLEFT
            LDA   #MDASHES    ;PRINT DASHES
            CPX   #$00        ;IF AT TOP OF
            BEQ   :TOPLINE    ;CATALOG, ELSE
            BIT   CFLAG
            BMI   :TOPLINE
            LDA   #MMORE      ;'--MORE--'
:TOPLINE    JSR   PRINT
:NEXT       INC   :VCOUNT     ;NEXT LINE
            LDA   :VCOUNT
            JSR   VLEFT
            LDA   SHOW        ;AT CURRENT
            CMP   CURR        ;FILE?
            BNE   :NOTCURR
            JSR   PINVRS      ;SET INVERSE
            LDA   CV          ;SAVE VTAB
            STA   CURRV
:NOTCURR    JSR   CSTAT
            LDA   #$FF
            JSR   JCATLN1     ;DISPLAY LINE
            JSR   PNORML      ;SET NORMAL
            JSR   CROUT
            INC   SHOW        ;NEXT ENTRY
            LDA   SHOW
            CMP   NACTIV      ;END OF
            BEQ   :OUT        ;CATALOG?
            DEC   :COUNTER    ;ENOUGH FILES?
            BNE   :NEXT
            BIT   CFLAG
            BMI   :OUT        ;SKIP 'MORE'
            LDA   #MMORE
            DB    $2C
:OUT        LDA   #MDASHES
            PHA
            LDA   #$13
            JSR   VLEFT
            PLA
            JMP   PRINT
:COUNTER    DB    $0
:VCOUNT     DB    $0
CFLAG       EQU   *
            DB    $0
*
* DISPLAY CATALOG STATUS
* SHOW POINTS TO ENTRY  ->
*
CSTAT       EQU   *
            LDA   #$00
            STA   CH
            LDX   SHOW        ;GET SELECT
            LDA   STATUS,X    ;STATUS
            BNE   :SELECT     ;IF ZERO:
:DOSPC      JSR   PRHERE      ;PRINT SPACES
            ASC   "   "
            DB    $0
            RTS
*
:SELECT     CMP   #$FE
            BCC   :NUMBER     ;IF $FF OR $FE
            BIT   CFLAG
            BMI   :DOSPC
            BIT   A2E
            BVS   :FANCYCHK
            JSR   PRHERE
            ASC   "-> "
            DB    $0
            RTS
:FANCYCHK
            JSR   PRSPC
            BIT   PINVFL
            BMI   :SELCHK
            JSR   PRHERE
            DB    $44         ;MouseText checkmark
            ASC   " "
            DB    $0
            RTS
:SELCHK
            JSR   PNORML
            JSR   PRHERE
            DB    $45         ;MouseText inverse checkmark
            DB    $0
            JSR   PINVRS
            JMP   PRSPC
*
:NUMBER     STA   HEXNUM      ;PRINT NUMBER
            LDA   #$00
            STA   HEXNUM+1
            JSR   HEXDEC      ;CVRT TO DEC
            JMP   PRT3RJ
*
* SHOW A LINE OF CATALOG
CATLIN      PHA
            JSR   PRSPC
            JSR   PRSPC
            PLA
            JMP   JCATLN1
