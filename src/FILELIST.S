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
            JMP   DOKEY
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
            ASC   "is the current booting program."
            DB    $8D,$0
            LDA   #MPSTAT45
            JSR   PRINT
            JMP   DOKEY
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
DOKEY       JSR   SEECAT
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
            BEQ   DOKEY       ;SCROLL
            DEX
            STX   CURR
            JMP   DOKEY
*
:FSCROL     JSR   SCROLF      ;FORWARD
            JMP   DOKEY       ;SCROLL
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
            BNE   DOKEY       ;NOT FOUND
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
            BCC   DOKEY
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
            DW    DOKEY
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
CPYADD      LDX   CURR        ;IS IT NOW
            LDA   STATUS,X    ;EMPTY?
            BNE   :NOPE
            INC   FILNUM      ;YES:INC TOTAL
            LDA   FILNUM      ;& PUT # INTO
            STA   STATUS,X    ;STATUS
:NOPE       CLC
            RTS
*
CPYTAB      JSR   LOHERE
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
CPYNUM      JSR   CPYTAB
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
CPYENT      JSR   GETPAT
            BCS   :OUT
            LDA   #$00
            STA   CURR
:LOOP       JSR   MATCH
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
CPYDEL      JSR   DODEL
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
*
*
DIVOUT      LDA   #0
            DB    $2C
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
TOGGLE      LDX   CURR        ;GET CURRENT
            LDA   STATUS,X    ;FILE STATUS
            EOR   #$FF        ;TOGGLE IT
            STA   STATUS,X    ;REPLACE IT
NIL         CLC
            RTS
*
PATTRN      JSR   GETPAT      ;READ PATTERN
            BCS   :OUT
            LDA   #$00        ;INITIALIZE
            STA   CURR
:LOOP       JSR   MATCH       ;TRY A MATCH
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
NOPATT      LDA   CURR
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
:LOOP       JSR   MATCH       ;MATCH:ALL DONE
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
LOKPAT      JSR   GETPAT      ;GET PATTERN
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
:LOOP       JSR   MATCH
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
NEWNAM      JSR   LOHERE
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
GETFNM      LDA   #$1E        ;DOS FILENAME LIMIT
            BIT   DOSNOW
            BPL   GETLN0
            LDA   #$0F        ;PRODOS FILENAME LIMIT
GETLN0      STA   LINLIM
            JMP   GETLN
*
GETPAT      LDA   CURR
            STA   LASTM
            JSR   LOHERE
            ASC   "Enter filename (,opt. filetypes)",8D,"? ",00
            LDA   #$24        ;PATTERN LIMIT
            BNE   GETLN0      ;ALWAYS
*
* INITIALIZES CATALOG DISPLAY
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
FILEQ       LDA   FILNUM
            STA   NACTIV
*
* FALL THRU TO SEECT1
*
*
*
* SHOW A PAGE OF CATALOG
* CURR, NACTIV MUST BE
* INITIALIZED  ->
*
SEECT1      LDA   #$FF
            DB    $2C
SEECAT      LDA   #0
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
            JSR   CATLN1      ;DISPLAY LINE
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
CFLAG       DB    $0
*
* DISPLAY CATALOG STATUS
* SHOW POINTS TO ENTRY  ->
*
CSTAT       LDA   #$00
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
            JSR   PRHERE
            ASC   "-> "
            DB    $0
            RTS
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
CATLN1      PHA
            LDX   SHOW        ;SET *POINT
            JSR   SETPNT
            PLA
CATLN2      BIT   DOSNOW
            BPL   :CAT33
            JMP   PCATLN
*
:CAT33      LDY   #$02
            LDA   (POINT),Y   ;GET LOCKED
            BMI   :LOCKED     ;STATUS
            LDA   #" "        ;PRINT SPACE
            BNE   :SEELOCK
:LOCKED     LDA   #"*"        ;OR *
:SEELOCK    JSR   PCOUT
            JSR   FILTYP      ;FIND FILETYPE
            LDA   TYPCHR,X    ;PRINT FILTYP
            JSR   PCOUT       ;CHARACTER
            JSR   PRSPC       ;PRINT SPACE
            LDY   #$21        ;INDEX TO
            LDA   (POINT),Y   ;FILE SIZE
            STA   HEXNUM      ;PUT IN
            INY               ;CONVERT
            LDA   (POINT),Y   ;BUFFERS
            STA   HEXNUM+1
            JSR   HEXDEC      ;HEX->DECIMAL
            JSR   PRTLZ       ;PRINT DIGITS
            JSR   PRSPC       ;PRINT SPACE
            JSR   CFILE       ;SEE FILENAME
:OUT        RTS
:LENGTH     DB    $0
*
*
* FIND FILETYPE
*
FILTYP      LDX   #$08
            LDY   #$02
            LDA   (POINT),Y
            AND   #$7F
:LOOP       CMP   TYPBYT,X
            BEQ   :OUT
            DEX
            BNE   :LOOP
:OUT        RTS
TYPBYT      DB    $00,$40,$20,$10,$08,$04,$02,$01,$00
TYPCHR      ASC   "?BARSBAIT"
*
*
* CALL THE PATTERN MATCHER HERE
*
MATCH       JSR   CURPNT
            JSR   GETTYP
            STA   :FILTYPE    ;SAVE IT
            JSR   FTOCR       ;CONVERT FNAME
            LDX   #$00        ;SET POINTERS
            STX   :SP
            LDY   #$00
            JSR   :RECURSE
            BCS   :MOUT
            LDA   CURR
            STA   LASTM
:MOUT       RTS
*
* THE PATTERN MATCHER ITSELF
:RECURSE    TXA               ;STACK THE
            PHA               ;POINTERS
            TYA
            LDX   :SP
            STA   STACKY,X
            PLA
            STA   STACKX,X
            TAX
            INC   :SP
            LDA   LINEIN,X    ;READ PATTERN
            CMP   #"="        ;CHARACTER
            BEQ   :EQUALS
            CMP   #$AC        ;","
            BEQ   :COMMA
            CMP   #$8D
            BEQ   :CR
            CMP   FILNAM,Y    ;MATCHES FILE-
            BEQ   :CHMATCH    ;NAME CHAR?
            SEC               ;MATCH FAILS
:OUT        DEC   :SP         ;POP STACK
            LDX   :SP
            LDA   STACKX,X
            LDY   STACKY,X
            TAX
            RTS
*
:EQUALS     INX               ;MATCH ON NEXT
:TRYNEXT    JSR   :RECURSE    ;PATTERN CHAR?
            BCC   :OUT        ;NO:
            LDA   FILNAM,Y    ;AT END OF
            CMP   #$8D        ;FILENAME?
            BEQ   :FAILOUT    ;YES: FAILS
            INY               ;ELSE TRY NEXT
            BNE   :TRYNEXT    ;FILE CHAR
*
:COMMA      LDA   #$FF        ;FLAG COMMA
            BMI   :SAVCAMA
*
:CR         LDA   #$00        ;FLAG NO COMMA
:SAVCAMA    STA   :CAMAFLG
            LDA   FILNAM,Y    ;END OF
            CMP   #$8D        ;FILENAME?
            BNE   :FAILOUT
:ENDNAME    LDA   :CAMAFLG    ;ELSE CHECK
            BMI   :DOCAMA     ;COMMA
            CLC               ;SUCCEEDS
            BCC   :OUT
*
:CHMATCH    INX               ;MATCH NEXT
            INY               ;CHAR OF BOTH
            JSR   :RECURSE    ;STRINGS
            JMP   :OUT
*
:PROTYP3    LDA   TYPES,Y     ;FILETYPE
            CMP   :FILTYPE
            BEQ   :SUCCOUT
:DOCAMA     INX               ;NEXT PAT CHAR
            LDA   LINEIN,X
            CMP   #$8D        ;CR?
            BEQ   :FAILOUT    ;YES: FAIL
            CMP   #$AC        ;","
            BEQ   :DOCAMA     ;SKIP COMMAS
            BIT   DOSNOW
            BMI   :PROTYP
*
            LDY   #$08
:TRYTYPE    CMP   TYPCHR,Y    ;MATCH FILTYP?
            BEQ   :GOTTYPE
            DEY               ;NO:TRY NEXT
            BNE   :TRYTYPE
            BEQ   :DOCAMA     ;(NO BAD STOP)
:GOTTYPE    LDA   TYPBYT,Y    ;GET TYPE BYTE
            CMP   :FILTYPE    ;FILTYPE MATCH?
            BNE   :DOCAMA     ;NO:TRY NEXT
:SUCCOUT    CLC               ;YES:SUCCEED
            BCC   :GOOUT
:FAILOUT    SEC
:GOOUT      JMP   :OUT
*
:PROTYP     LDY   #TYPE1-TYPES-1  ;# of filetypes - 1
:PROTYP0    LDA   LINEIN,X
            CMP   TYPE1,Y
            BEQ   :PROTYP1
:PROAGN     DEY
            BPL   :PROTYP0
            BMI   :DOCAMA     ;NO MATCH
:PROTYP1    STX   :XSAVE
            INX
            LDA   LINEIN,X
            CMP   #$8D
            BEQ   :FAILOUT
            CMP   TYPE2,Y
            BNE   :PROTYP2
            INX
            LDA   LINEIN,X
            CMP   #$8D
            BEQ   :FAILOUT
            CMP   TYPE3,Y
            BEQ   :PROTYP3    ;MATCH!
:PROTYP2    LDX   :XSAVE
            JMP   :PROAGN     ;CK NEXT TYPE
*

*
:FILTYPE    DB    $0
:CAMAFLG    DB    $0
:SP         DB    $0
:XSAVE      DB    $0
*
* CONVERT FILENAME TO CR FORMAT
* CAN'T USE DOSNOW TO DETERMINE
* FILENAME FORMAT
*
FTOCR       LDY   #1
            LDA   (POINT),Y
            CMP   #$10
            BCS   :PRODOS
*
:DOS33      LDX   #$1E        ;(NAME LENGTH)
            LDY   #$00
            LDA   (POINT),Y   ;DELETED?
            CMP   #$FF
            BNE   :LONG
            DEX               ;DON'T USE
:LONG       TXA               ;LAST CHAR
            TAY
            INC   POINT       ;POINT TO
            INC   POINT       ;FILENAME
            INC   POINT
:SPACE      DEY
            LDA   (POINT),Y   ;LOOP TO IGNORE
            CMP   #" "        ;LAST SPACES
            BEQ   :SPACE
            STA   FILNAM,Y    ;SAVE LAST CHAR
            LDA   #$8D        ;END WITH CR
            STA   FILNAM+$1,Y
            DEY
:NEXTCHR    LDA   (POINT),Y   ;COPY THE REST
            STA   FILNAM,Y    ;OF THE CHARS
            DEY
            BPL   :NEXTCHR
            DEC   POINT
            DEC   POINT
            DEC   POINT
            RTS
*
:PRODOS     DEY               ;1 --> 0
            LDA   (POINT),Y
            AND   #$0F        ;NECESSARY?
            BNE   :PRO1
            LDA   #$0F
:PRO1       TAX
            INY               ;0 --> 1
:PRO2       LDA   (POINT),Y
            BEQ   :PRO3
            ORA   #$80
            STA   FILNAM-1,Y
            INY
            DEX
            BNE   :PRO2
:PRO3       LDA   #$8D
            STA   FILNAM-1,Y
            RTS
*
* SLIDE SELECTED FILES TO TOP OF
* STATUS ARRAY (ARROW FLAGGED)
*
PATMOV      LDX   #$00
            LDY   #$00
:LOOP       LDA   STATUS,Y
            BEQ   :NEXT
            STA   STATUS,X
            LDA   CBYTE,Y
            STA   CBYTE,X
            LDA   CSECTR,Y
            STA   CSECTR,X
            INX
:NEXT       INY
            CPY   NACTIV
            BCC   :LOOP
            STX   FILNUM
            RTS

