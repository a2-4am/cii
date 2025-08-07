*
*
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
            LDA   #$36            ;NO FILES
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
:BOOTMES    LDA   #$2C            ;QFILE
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
            LDA   #$31            ;QSTAT4
            JSR   PRINT
            JMP   DOKEY
*
:NOFILES    JSR   CROUT
            LDA   #$36
            JSR   PRINT
            LDA   #$43
            JSR   PRINT
            JSR   GETKEY
            CMP   #"<"
            BEQ   :GO1
            CMP   #$AC            ;","
            BEQ   :GO1
            JMP   FILER
:GO1        JSR   DO1
            JMP   CATDS1
*
*
* SCROLL CATALOG DISPLAY FORWARD
* CARRY CLEAR IF SUCCESS
*  SET IF FAIL
SCROLF      LDX   CURR            ;IF BEFORE
            INX                   ;END OF
            CPX   NACTIV          ;CATALOG:
            BCS   :OUTBAD
            STX   CURR
:OUTBAD     RTS
*
*        CATALOG DISPLAY
*   KEYPRESS FUNCTION HANDLER
*
DOKEY       JSR   SEECAT
            JSR   CHKKEY          ;GET CHARACTER
            STA   :TEMP
            BNE   :NOTARO
            BCS   :FSCROL         ;DOWN OR RIGHT ARROW
            BCC   :BSCROL         ;UP OR LEFT ARROW
*
:NOTARO     SEC
            SBC   #$B0            ;IS IT A #?
            CMP   #$0A
            BCS   :LOOKUP
            STA   CPYDIG          ;YES: SAVE IT
            LDA   #$23            ;& SET # FLAG
            BNE   :DOLOOK         ;ALWAYS
*
:BSCROL     LDX   CURR            ;BACKWARD
            BEQ   DOKEY           ;SCROLL
            DEX
            STX   CURR
            JMP   DOKEY
*
:FSCROL     JSR   SCROLF          ;FORWARD
            JMP   DOKEY           ;SCROLL
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
:NXTCHAR    CMP   :CHARS,X        ;CONVERT CHAR
            BEQ   :INDEX          ;TO INDEX #
            DEX
            BPL   :NXTCHAR
            BMI   DOKEY           ;NOT FOUND
*
:INDEX      CPX   #6
            BCC   :INDEX1
            DEX                   ;7-->5,6-->4
            DEX
:INDEX1     STX   :TEMP           ;INDEX INTO
            LDA   STATE           ;STATE TABLE:
            ASL                   ;TIMES 2
            ADC   STATE           ;TIMES 3
            ASL                   ;TIMES 6
            CLC
            ADC   :TEMP           ; + CHAR INDEX
            ASL                   ; * 2
            ADC   #:TABLE         ; + TABLE ADDR
            STA   POINT           ;PUT ADDR IN
            LDA   #>:TABLE        ;POINTER
            ADC   #$00
            STA   POINT+1
            LDY   #$00
            LDA   (POINT),Y       ;LOAD VALUE
            STA   :JUMP+1         ;FROM ADDR TO
            INY                   ;JUMP BUFFER
            LDA   (POINT),Y
            STA   :JUMP+2
:JUMP       JSR   $1000
            BCC   DOKEY
            CMP   #$FF
            BNE   :OUT
            JMP   CATDS1          ;DIR CHANGE
:OUT        RTS
*
:TEMP       DB    $00
:CHARS      DB    $8D,$23
            ASC   "ED<>,."
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
CPYADD      LDX   CURR            ;IS IT NOW
            LDA   STATUS,X        ;EMPTY?
            BNE   :NOPE
            INC   FILNUM          ;YES:INC TOTAL
            LDA   FILNUM          ;& PUT # INTO
            STA   STATUS,X        ;STATUS
:NOPE       CLC
            RTS
*
CPYTAB      JSR   LOHERE
            ASC   "Insert copy number: [Return]-Complete"
            DB    $8D
            ASC   "insertion, [Esc]-Back out"
            DB    $0
            LDA   CURRV           ;TAB TO
            JSR   VLEFT           ;CURRENT LINE
            LDA   #$00            ;CLEAR HIGH
            STA   CPYDIG+1        ;DIGIT
            STA   CPYDIG+2
            JMP   PINVRS
*
*
CPYNUM      JSR   CPYTAB
            LDA   CPYDIG          ;PRINT DIGIT
            JSR   PHHEX
            JSR   PNORML
            LDA   #2
            STA   :TEMP
:CHAR2      JSR   PRDKEY
            CMP   #$8D            ;INPUT CR?
            BEQ   :CPYCR          ; INSERT #
            CMP   #$9B            ;ESCAPE OR
            BEQ   :GOOUT1
            CMP   #$88            ;LEFT ARROW?
            BEQ   :GOOUT1         ; BACK OUT
            LDX   :TEMP
            BEQ   :CHAR2          ;NO MORE DIGS
            SEC
            SBC   #$B0            ;ANOTHER DIGIT?
            CMP   #$0A
            BCS   :CHAR2          ;NO:TRY AGAIN
            LDX   CPYDIG+1
            STX   CPYDIG+2
            LDX   CPYDIG          ;YES:SAVE IT
            STX   CPYDIG+1
            STA   CPYDIG
            JSR   PINVRS          ; & PRINT IT
            JSR   PHHEX
            JSR   PNORML
            DEC   :TEMP
            JMP   :CHAR2
:GOOUT1     JMP   :OUT
*
:CPYCR      LDA   CPYDIG+2
            CMP   #3
            BCS   :OUT1           ;>=300
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
            LDA   CPYDIG+1        ;CONVERT
            ASL                   ;DECIMAL DIGITS
            ASL                   ;TO HEX BYTE
            ADC   CPYDIG+1
            ASL
            ADC   CPYDIG
            ADC   :TEMP
            BCS   :OUT1           ;>255
            BEQ   :OUT1           ;# = 0
            STA   :INSERT         ;SAVE IT
            LDX   #$FF            ;SET UP
            LDY   CURR
            LDA   STATUS,Y        ;IS A # ALREADY
            BEQ   :LOOP2          ;THERE?
            CMP   :INSERT         ;YES:EXIT IF =
            BEQ   :OUT1           ;TO INSERT
            BCC   :LOOP3
*
*  INSERT < CURRENT STATUS #
:LOOP1      LDA   STATUS,X        ;INC ALL #'S
            CMP   :INSERT         ;THAT ARE
            BCC   :NOT1           ;>= INSERT
            CMP   STATUS,Y        ;& < CURRENT
            BCS   :NOT1           ;STATUS #
            INC   STATUS,X
:NOT1       DEX
            CPX   #$FF
            BNE   :LOOP1
            LDA   :INSERT         ;PUT INSERT
            STA   STATUS,Y        ;INTO STATUS
:OUT1       JMP   :OUT
*
*  NO # IN CURRENT STATUS YET
:LOOP2      LDA   STATUS,X        ;INC ALL #'S
            CMP   :INSERT         ;THAT ARE
            BCC   :NOT2           ;>= INSERT
            INC   STATUS,X
:NOT2       DEX
            CPX   #$FF
            BNE   :LOOP2
            INC   FILNUM          ;BUMP UP COUNT
            JMP   :FINISH         ;FINISH BELOW
*
*  INSERT > CURRENT STATUS #
:LOOP3      LDA   :INSERT         ;DEC ALL #'S
            CMP   STATUS,X        ;THAT ARE
            BCC   :NOT3           ;> CURRENT
            LDA   STATUS,Y        ;STATUS #
            CMP   STATUS,X        ;& <= INSERT
            BCS   :NOT3
            DEC   STATUS,X
:NOT3       DEX
            CPX   #$FF
            BNE   :LOOP3
:FINISH     LDA   FILNUM          ;PUT LOWER OF
            CMP   :INSERT         ;FILENUM &
            BCC   :PUTIT          ;INSERT INTO
            LDA   :INSERT         ;STATUS
:PUTIT      STA   STATUS,Y
:OUT        LDA   #$2D            ;QSTAT0
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
            LDA   #$2D            ;QSTAT0
            JMP   LOWMES
*
CPYDEL      JSR   DODEL
            BEQ   :CPYDEL0        ;NOTHING THERE
            DEC   FILNUM
:CPYDEL0    JSR   SEECAT
            CLC
            RTS
*
DODEL       LDY   CURR            ;IS SOMETHING
            LDA   STATUS,Y        ;THERE?
            BEQ   :NOPE
            LDX   #$FF            ;YES: LOOP
:LOOP       CMP   STATUS,X        ;THROUGH TO
            BCS   :SMALLER        ;DECREMENT ALL
            DEC   STATUS,X        ;HIGHER #'ED
:SMALLER    DEX                   ;FILES
            CPX   #$FF
            BNE   :LOOP
            LDA   #$00            ;THEN DELETE
            STA   STATUS,Y        ;SELECTED ONE
            DEX                   ;SET Z = 0
:NOPE       RTS
*
*
*
DIVOUT      LDA   #0
            DB    $2C
DIVOT0      LDA   #$FF
            STA   :DIVFLAG
            LDA   #0
            STA   POINT           ;POINT TO
            LDA   #>SDIR          ; DIR HEADER
            STA   POINT+1
            LDY   #4
            LDA   (POINT),Y
            AND   #$F0            ;STOR TYPE
            CMP   #$F0
            BNE   :NOTROOT
:ISROOT     LDA   #$38            ;IN ROOT
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
            LDA   (POINT),Y       ;PARENT BLK
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
DO1A        BCS   ERR2
            SEC
            RTS
*
ERR2        JSR   LOWMES
            JSR   KYESC
ST8MSG      LDA   STATE
            CLC
            ADC   #$2D            ;QSTAT0
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
            STA   :NAMELEN        ;FILE NAME LEN
            LDX   PFX
            LDA   #$2F
            CMP   PFX,X           ;ENDING '/'?
            BEQ   :LOOP           ;YES: DON'T ADD
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
:NOTDIR     LDA   #$24            ;C ALREADY SET
            RTS
:TOOLONG    LDA   #$54
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
TOGGLE      LDX   CURR            ;GET CURRENT
            LDA   STATUS,X        ;FILE STATUS
            EOR   #$FF            ;TOGGLE IT
            STA   STATUS,X        ;REPLACE IT
NIL         CLC
            RTS
*
PATTRN      JSR   GETPAT          ;READ PATTERN
            BCS   :OUT
            LDA   #$00            ;INITIALIZE
            STA   CURR
:LOOP       JSR   MATCH           ;TRY A MATCH
            BCS   :NEXT           ;IF SUCCESS:
            LDX   CURR
            LDA   #$FF            ; MARK THE
            STA   STATUS,X        ; ENTRY
:NEXT       JSR   SEECAT          ;DISPLAY &
            JSR   SCROLF          ;SCROLL
            BCC   :LOOP           ;TIL END
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
            JSR   GETFNM          ;GET FILENAME
            BCS   :OUT
            LDA   #$00
            STA   CURR
:LOOP       JSR   MATCH           ;MATCH:ALL DONE
            BCC   :OUT
            JSR   SEECAT
            JSR   SCROLF          ;NO MATCH:
            BCC   :LOOP           ;TRY NEXT FILE
            LDA   LASTM           ;NONE:RESTORE
            STA   CURR            ;CURRENT FILE
:OUT        JMP   ST8MSG
*
LOKAST      JSR   CURPNT
            LDA   #$80            ;TOGGLE LOCK
            JSR   SETLOK
            LDA   #$01
            STA   FILNUM          ;FLAG IT
            CLC
            RTS
*
LOKPAT      JSR   GETPAT          ;GET PATTERN
            BCS   :OUT
            JSR   ASKLOK
            BCS   :OUT
            STX   :LOCK
            LDA   #$00
            STA   CURR
:LOOP       JSR   MATCH
            BCS   :NEXT           ;IF MATCH, GET
            LDA   :LOCK
            JSR   SETLOK
            LDA   #$01
            STA   FILNUM          ;FLAG IT
:NEXT       JSR   SEECAT
            JSR   SCROLF
            BCC   :LOOP
:OUT        LDA   LASTM
            STA   CURR
            LDA   #$2F            ;STAT2
            JMP   LOWMES
:LOCK       DB    $0
*
NEWNAM      JSR   LOHERE
            ASC   "Rename "
            DB    $0
            JSR   CURPNT
            JSR   CFILE           ;PRINT FILENAME
:ASKNAME    JSR   PRHERE
            DB    #$8D
            ASC   "as? "
            DB    $0
            JSR   GETFNM          ;GET NEW NAME
            BCS   :OUT
            JSR   PLACE           ;CHECK & PLACE
            LDX   CURR
            LDA   #$FF            ;MARK AS
            STA   STATUS,X        ;RENAMED
            LDA   #$01
            STA   FILNUM          ;FLAG IT
:OUT        LDA   #$30            ;QSTAT3
            JMP   LOWMES
*
* GET FILE NAME
*
GETFNM      LDA   #$1E
            BIT   DOSNOW
            BPL   GETLN0
            LDA   #$0F
GETLN0      STA   LINLIM
            JMP   GETLN
*
GETPAT      LDA   CURR
            STA   LASTM
            LDA   #$29
            JSR   LOWMES
            LDA   #$24
            BNE   GETLN0
*
* INITIALIZES CATALOG DISPLAY
*
INITCD      LDA   #$00
            STA   CURR
            STA   FILNUM
            STA   GO
            TAX                   ;SET STATUSES
:LOOP       STA   STATUS,X        ;TO ZERO
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
            LDA   NACTIV          ;IF ANY
            BEQ   :OUT            ;ACTIVE FILES:
            LDX   #$00            ;FIND CAT. TOP
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
:GOTTOP     STX   SHOW            ;& PUT IN SHOW
            LDA   #$0F            ;START COUNTER
            STA   :COUNTER        ;AT 15
            LDA   #$03
            STA   :VCOUNT
            JSR   VLEFT
            LDA   #$42            ;PRINT DASHES
            CPX   #$00            ;IF AT TOP OF
            BEQ   :TOPLINE        ;CATALOG, ELSE
            BIT   CFLAG
            BMI   :TOPLINE
            LDA   #$44            ;PRINT MORE
:TOPLINE    JSR   PRINT
:NEXT       INC   :VCOUNT         ;NEXT LINE
            LDA   :VCOUNT
            JSR   VLEFT
            LDA   SHOW            ;AT CURRENT
            CMP   CURR            ;FILE?
            BNE   :NOTCURR
            JSR   PINVRS          ;SET INVERSE
            LDA   CV              ;SAVE VTAB
            STA   CURRV
:NOTCURR    JSR   CSTAT
            LDA   #$FF
            JSR   CATLN1          ;DISPLAY LINE
            JSR   PNORML          ;SET NORMAL
            JSR   CROUT
            INC   SHOW            ;NEXT ENTRY
            LDA   SHOW
            CMP   NACTIV          ;END OF
            BEQ   :OUT            ;CATALOG?
            DEC   :COUNTER        ;ENOUGH FILES?
            BNE   :NEXT
            BIT   CFLAG
            BMI   :OUT            ;SKIP 'MORE'
            LDA   #$44
            DB    $2C
:OUT        LDA   #$42
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
            LDX   SHOW            ;GET SELECT
            LDA   STATUS,X        ;STATUS
            BNE   :SELECT         ;IF ZERO:
:DOSPC      JSR   PRHERE          ;PRINT SPACES
            ASC   "   "
            DB    $0
            RTS
*
:SELECT     CMP   #$FE
            BCC   :NUMBER         ;IF $FF OR $FE
            BIT   CFLAG
            BMI   :DOSPC
            JSR   PRHERE
            ASC   "-> "
            DB    $0
            RTS
*
:NUMBER     STA   HEXNUM          ;PRINT NUMBER
            LDA   #$00
            STA   HEXNUM+1
            JSR   HEXDEC          ;CVRT TO DEC
            JMP   PRT3RJ
*
* SHOW A LINE OF CATALOG
CATLIN      PHA
            JSR   PRSPC
            JSR   PRSPC
            PLA
CATLN1      PHA
            LDX   SHOW            ;SET *POINT
            JSR   SETPNT
            PLA
CATLN2      BIT   DOSNOW
            BPL   :CAT33
            JMP   PCATLN
*
:CAT33      LDY   #$02
            LDA   (POINT),Y       ;GET LOCKED
            BMI   :LOCKED         ;STATUS
            LDA   #" "            ;PRINT SPACE
            BNE   :SEELOCK
:LOCKED     LDA   #"*"            ;OR *
:SEELOCK    JSR   PCOUT
            JSR   FILTYP          ;FIND FILETYPE
            LDA   TYPCHR,X        ;PRINT FILTYP
            JSR   PCOUT           ;CHARACTER
            JSR   PRSPC           ;PRINT SPACE
            LDY   #$21            ;INDEX TO
            LDA   (POINT),Y       ;FILE SIZE
            STA   HEXNUM          ;PUT IN
            INY                   ;CONVERT
            LDA   (POINT),Y       ;BUFFERS
            STA   HEXNUM+1
            JSR   HEXDEC          ;HEX->DECIMAL
            JSR   PRTLZ           ;PRINT DIGITS
            JSR   PRSPC           ;PRINT SPACE
            JSR   CFILE           ;SEE FILENAME
:OUT        RTS
:LENGTH     DB    $0
*
*
* CALL THE PATTERN MATCHER HERE
*
MATCH       JSR   CURPNT
            JSR   GETTYP
            STA   :FILTYPE        ;SAVE IT
            JSR   FTOCR           ;CONVERT FNAME
            LDX   #$00            ;SET POINTERS
            STX   :SP
            LDY   #$00
            JSR   :RECURSE
            BCS   :MOUT
            LDA   CURR
            STA   LASTM
:MOUT       RTS
*
* THE PATTERN MATCHER ITSELF
:RECURSE    TXA                   ;STACK THE
            PHA                   ;POINTERS
            TYA
            LDX   :SP
            STA   STACKY,X
            PLA
            STA   STACKX,X
            TAX
            INC   :SP
            LDA   LINEIN,X        ;READ PATTERN
            CMP   #"="            ;CHARACTER
            BEQ   :EQUALS
            CMP   #$AC            ;","
            BEQ   :COMMA
            CMP   #$8D
            BEQ   :CR
            CMP   FILNAM,Y        ;MATCHES FILE-
            BEQ   :CHMATCH        ;NAME CHAR?
            SEC                   ;MATCH FAILS
:OUT        DEC   :SP             ;POP STACK
            LDX   :SP
            LDA   STACKX,X
            LDY   STACKY,X
            TAX
            RTS
*
:EQUALS     INX                   ;MATCH ON NEXT
:TRYNEXT    JSR   :RECURSE        ;PATTERN CHAR?
            BCC   :OUT            ;NO:
            LDA   FILNAM,Y        ;AT END OF
            CMP   #$8D            ;FILENAME?
            BEQ   :FAILOUT        ;YES: FAILS
            INY                   ;ELSE TRY NEXT
            BNE   :TRYNEXT        ;FILE CHAR
*
:COMMA      LDA   #$FF            ;FLAG COMMA
            BMI   :SAVCAMA
*
:CR         LDA   #$00            ;FLAG NO COMMA
:SAVCAMA    STA   :CAMAFLG
            LDA   FILNAM,Y        ;END OF
            CMP   #$8D            ;FILENAME?
            BNE   :FAILOUT
:ENDNAME    LDA   :CAMAFLG        ;ELSE CHECK
            BMI   :DOCAMA         ;COMMA
            CLC                   ;SUCCEEDS
            BCC   :OUT
*
:CHMATCH    INX                   ;MATCH NEXT
            INY                   ;CHAR OF BOTH
            JSR   :RECURSE        ;STRINGS
            JMP   :OUT
*
:PROTYP3    LDA   TYPES,Y         ;FILETYPE
            CMP   :FILTYPE
            BEQ   :SUCCOUT
:DOCAMA     INX                   ;NEXT PAT CHAR
            LDA   LINEIN,X
            CMP   #$8D            ;CR?
            BEQ   :FAILOUT        ;YES: FAIL
            CMP   #$AC            ;","
            BEQ   :DOCAMA         ;SKIP COMMAS
            BIT   DOSNOW
            BMI   :PROTYP
*
            LDY   #$08
:TRYTYPE    CMP   TYPCHR,Y        ;MATCH FILTYP?
            BEQ   :GOTTYPE
            DEY                   ;NO:TRY NEXT
            BNE   :TRYTYPE
            BEQ   :DOCAMA         ;(NO BAD STOP)
:GOTTYPE    LDA   TYPBYT,Y        ;GET TYPE BYTE
            CMP   :FILTYPE        ;FILTYPE MATCH?
            BNE   :DOCAMA         ;NO:TRY NEXT
:SUCCOUT    CLC                   ;YES:SUCCEED
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
            BMI   :DOCAMA         ;NO MATCH
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
            BEQ   :PROTYP3        ;MATCH!
:PROTYP2    LDX   :XSAVE
            JMP   :PROAGN         ;CK NEXT TYPE
*

*
:FILTYPE    DB    $0
:CAMAFLG    DB    $0
:SP         DB    $0
:XSAVE      DB    $0
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
*
*
***********************************
*
* ASK  PRINTER OPTION QUESTION
ASKPR?      LDX   PSLOT           ;PRINTER SLOT
            BEQ   :OUT            ;NONZERO?
            JSR   PRHERE
            DB    $8D,$8D,$8D,$8D
            ASC   "Do you want a printout (Y/N) ? "
            DB    $0
            JSR   KYESC
            LDX   #$FF
            CMP   #"Y"            ;YES?
            BEQ   :SETIT
            LDX   #$00
            LDA   #"N"
:SETIT      JSR   PCOUT
            STX   PRNTR?
            JMP   HOME
:OUT        STX   PRNTR?          ;SET FLAG
            RTS
*
* TURN ON PRINTER
PRON        LDA   CSWL
            STA   CSWSAV
            LDA   CSWL+1
            STA   CSWSAV+1
            LDA   #$00
            STA   CSWL
            LDA   PSLOT
            ORA   #$C0
            STA   CSWL+1
            RTS
CSWSAV      DB    $0,$0
*
PROFF       LDA   CSWSAV+1
            STA   CSWL+1
            LDA   CSWSAV
            STA   CSWL
            JMP   SETKBD
*
PRSPC       LDA   #" "
            JMP   PCOUT
*
* MY PRINT BYTE & HEX ROUTINE
PHBYTE      PHA
            LSR
            LSR
            LSR
            LSR
            JSR   MYHEX           ;HIGH DIGIT
            PLA
PHHEX       AND   #$0F            ;LOW DIGIT
            JMP   MYHEX
*
*
* MY OWN INVERSE FLAG...
PINVRS      LDY   #$C0
            DB    $2C
PFLASH      LDY   #$80
            DB    $2C
PNORML      LDY   #$00
            STY   PINVFL
            RTS
*
DOC00E      BIT   A2E
            BPL   :C00EQ
            STA   $C00E
:C00EQ      RTS
*
DOC00F      BIT   A2E
            BPL   :C00FQ
            STA   $C00F
:C00FQ      RTS
*
***********************************
*                                 *
*          MESSAGES               *
*                                 *
***********************************
*
* GIVE CATALOG DISPLAY FUNCTION TITLE
*
TOP1        JSR   HOME
TOP1A       LDA   #0
            STA   WNDTOP
            JSR   TABV
            LDA   CHOICE          ;FUNCTION NAME
            JSR   PRINT
            JSR   PRSPC
            LDA   OPTCHS
            BMI   :TOP1A
            JSR   PRINT
:TOP1A      RTS
*
*
SEEDEV      PHA
            JSR   PRHERE
            ASC   "Slot "
            DB    $0
            PLA
            PHA
            AND   #$70
            LSR
            LSR
            LSR
            LSR
            JSR   PHHEX
            JSR   PRHERE
            ASC   "  Drive "
            DB    $0
            PLA
            ASL
            LDA   #1
            ADC   #0
            JMP   PHHEX
*
*
* BOTTOM OF SCREEN MESSAGE
*
LOWMES      JSR   LOWSET
            JSR   PRINT
            CLC
            RTS
*
LOHERE      JSR   LOWSET
            JMP   PRHERE
*
LOWSET      PHA
            LDA   #$14
            JSR   VLEFT
            LDA   #$27            ;QBLNK4
            JSR   PRINT
            LDA   #$15
            JSR   TABV
            PLA
            RTS
*
LINE24      PHA
            LDA   #$17
            JSR   VLEFT
            LDA   #3
            STA   CH
            JSR   CLREOL
            PLA
            JMP   PRINT
*
*
*
*
*
* DOTREE
*
* INPUT:
* A = VALUE FOR *CURR
* (PFXADR) = OLD PREFIX
*
* OUTPUT:
* C = 1: I/O ERROR
*
* C=0:
*        A = SELECTION
* (PFXADR) = NEW PREFIX
*      PFX = NEW PREFIX
* DIRBLK,+1= BLK # OF SUBDIR
*
* CALLS SETPFX AND SETSD
*
*
*
DOTREE      PHA
            LDY   FLAG80          ;FF OR 0
            INY
            LDA   :CHMAX,Y
            STA   CHMAX
            LDA   :DSPNUM,Y
            STA   DSPNUM
            LDA   UNIT
            JSR   SETSD
            JSR   UNTPFX
            BIT   DOSNOW
            BMI   :DOTREE0
            LDY   #5
            LDA   PFX+5
            STA   (PFXADR),Y
            LDY   #0
            LDA   PFX
            STA   (PFXADR),Y
            SEC
            BCS   :FAKERR         ;ALWAYS
*
:DOTREE0    LDA   RRTN
            CMP   #$52
            BEQ   :FAKERR         ;C IS SET
            JSR   MKTREE
:FAKERR     PLA
            PHP
            STA   CURR
            LDA   #0
            STA   POINT
            STA   XPOS
            STA   YPOS
            STA   XSTART
            STA   YSTART
            LDX   CHOICE
            CPX   #1
            BNE   :DOT1           ;NOT CATALOG
            JSR   :HDR80
:DOT1       PLP
            LDA   #0
            BCS   :ERR
            LDA   CURMOM
            EOR   #1
            BEQ   :ONLY1
            LDX   CHOICE
            CPX   #1
            BEQ   :DOT2
            JSR   :HDR80
:DOT2       LDA   CURR            ;IS CURR LARGER
            CMP   CURMOM          ; THAN CURMOM?
            BCC   :DOT3           ;NO
:ZERCUR     LDA   #0              ;YES, ZERO CURR
            BEQ   :DOT4           ;ALWAYS
*
* CURR VALUE IS VALID, NOW CHECK
* IF PREFIX GENERATED FROM CURR IS
* SAME AS OLD PREFIX. IF NOT, SET CURR
* TO ZERO.
*
:DOT3       JSR   :MKPFX
            LDY   #0
            LDA   (PFXADR),Y
            AND   #$7F
            CMP   PFX
            BNE   :ZERCUR         ;LENS DIFFER
:CMPLOOP    INY
            LDA   (PFXADR),Y
            CMP   PFX,Y
            BNE   :ZERCUR
            CPY   PFX
            BCC   :CMPLOOP
            LDA   CURR
:DOT4       JMP   :COM00
*
*
:ONLY1      STA   CURR
            JSR   :MKPFX
*
:CHOOSE     JSR   SETPFX
            BCS   :ERR
            LDY   #$3F
:CHSLOOP    LDA   PFX,Y
            STA   (PFXADR),Y
            DEY
            BPL   :CHSLOOP
            LDX   CURR
            LDA   SDBLKL,X
            STA   DIRBLK
            LDA   SDBLKH,X
            STA   DIRBLK+1
            TXA
:ERR        PHP
            PHA
            LDA   CHOICE
            CMP   #1              ;CATALOG?
            BEQ   :SKIP40         ;YES
            JSR   COL40
:SKIP40     JSR   HOME
            PLA
            PLP
            RTS
*
*
*
:CAGN0      CPX   #0
            BEQ   :CAGN
            JSR   HOME
:CAGN       JSR   CTREE
            LDA   #$17
            JSR   VLEFT
            LDA   SDCH
            SEC
            SBC   #$19
            LSR
            JSR   SETCH
            JSR   PRHERE
            ASC   "Use arrows,A,Z and [Return] to select"
            DB    $0
:KEYAGN     JSR   KYESC
            CMP   #$8D
            BEQ   :CHOOSE
            LDX   #5
:KEY1       CMP   :KEYS,X
            BEQ   :GOTKEY
            DEX
            BPL   :KEY1
            BMI   :KEYAGN
*
:GOTKEY     CPX   #4
            BCC   :GOTKY1
            DEX
            DEX
:GOTKY1     TXA
            CLC
            ADC   #>MOM
            STA   POINT+1
            LDY   CURR
            LDA   (POINT),Y
            CMP   #$FF
            BEQ   :COMMON0
:COM00      STA   CURR
            PHA
            JSR   :MKPFX
            JSR   PRVNM
            PLA
            TAY
:COMMON0    LDX   #0
            LDA   XS,Y
            STA   XPOS
            SEC
            SBC   DSPNUM
            BCS   :COMX
            LDA   #0
:COMX       CMP   XSTART
            BEQ   :COMX1
            DEX
:COMX1      STA   XSTART
            LDA   YS,Y
            STA   YPOS
            SEC
            SBC   #$08
            BCS   :COMY
            LDA   #0
:COMY       CMP   YSTART
            BEQ   :COMY1
            DEX
:COMY1      STA   YSTART
            JMP   :CAGN0
*
*
*
:MKPFX      LDA   #0
            STA   :ERRFLG
*
:MK00       LDA   CURR
            STA   :TEMP
            LDX   #$3F
*
:MK0        LDA   #0
            STA   POINT2+1
            LDA   :TEMP
            LDY   #4
:MK1        ASL
            ROL   POINT2+1
            DEY
            BNE   :MK1
            STA   POINT2
            LDA   POINT2+1
            CLC
            ADC   #>SDNAME
            STA   POINT2+1
            LDA   (POINT2),Y      ;LEN
            TAY
:MK2        LDA   (POINT2),Y
            STA   PFX,X
            CPX   #0
            BEQ   :TOOLONG
            DEX
            DEY
            BPL   :MK2
            LDA   #$2F
            STA   PFX+$1,X
            LDY   :TEMP
            LDA   MOM,Y
            STA   :TEMP
            CMP   #$FF
            BNE   :MK0
:MK2A       LDY   #0
:MK3        LDA   PFX,X
            STA   PFX,Y
            INY
            INX
            CPX   #$40
            BCC   :MK3
            DEY
            STY   PFX
            LDA   :ERRFLG
            BNE   :TLERR
            RTS
*
* PREFIX TOO LONG. SET ERROR FLAG
* AND DECREMENT *CURR TO GENERATE
* A MEANINGFUL PREFIX.
*
:TOOLONG    DEC   :ERRFLG
            DEC   CURR
            JMP   :MK00
*
:TLERR      JSR   COL40
            JSR   COMH00
            LDA   #$21
            JMP   PRTPRS
*
:HDR80      JSR   COL80
            JMP   COMH00
*
*
*
:ERRFLG     DB    $0
:TEMP       DB    $0
:CHMAX      DB    $4F,$27
:DSPNUM     DB    $03,$01
:KEYS       DB    $88,$95,$8B,$8A,$C1,$DA


