            TYP   BIN
            DSK   ../build/CATLIB.O
            PUT   VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/RDDATA.VARS
            ORG   RDDATAEND
CATLIB
            ORG   *+3

**********************************
*        CATALOG LIBRARY         *
* CATLN1 - display 1 catalog line*
* CATDIS - display file list     *
* CDDOKEY - file list key handler*
* FILEQ - file queue during ops  *
* UNMARK - unmark file           *
* DIVEIN - enter subdirectory    *
* DIVOUT - leave subdirectory    *
* INITCD - (re)init list display *
* RDACNT - read catalog from disk*
*private:                        *
* MATCH - pattern matcher        *
* TYPES - recognized filetypes   *
* PLACE - input file into entry  *
**********************************
*
            RTS
*
* ENTRY POINT TO DISPLAY 1 CATALOG LINE
*
CATLN1INTERNAL
            PHA
            LDX   SHOW        ;SET *POINT
            JSR   SETPNT
            PLA
            BIT   DOSNOW
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
FILTYP      EQU   *
            LDX   #$08
            LDY   #$02
            LDA   (POINT),Y
            AND   #$7F
:LOOP       CMP   TYPBYT,X
            BEQ   :OUT
            DEX
            BNE   :LOOP
:OUT        RTS
*
PCATLN      EQU   *
            STA   :TYPE       ;CAT DPLY TYPE
            LDY   #$1E        ;ACCESS
            LDA   (POINT),Y
            LDX   #"?"
            CMP   #$81
            BEQ   :ISLOKD     ;'MAYBE' STATUS
            LDX   #"*"
            AND   #$C2
            BEQ   :ISLOKD     ;SAY LOCKED ONLY IF 3 BITS OFF
            LDX   #" "
:ISLOKD     TXA
            JSR   PCOUT
            JSR   PCFILE
*
* DISPLAY FILE TYPE
*
            LDA   #" "
:TABLP1     JSR   PCOUT
            INY
            CPY   #$11
            BCC   :TABLP1
            LDY   #$10
            LDA   (POINT),Y
*PRTYPE (now inline)
            LDX   #TYPE1-TYPES-1
:PRTY1      CMP   TYPES,X
            BEQ   :GOTTYPE
            DEX
            BPL   :PRTY1
*
* UNRECOGNIZED, PRINT FILE TYPE IN HEX
*
            JSR   DOLLAR
            JSR   PHBYTE
            JMP   :NOTYPE
*
:GOTTYPE    LDA   TYPE1,X
            JSR   PCOUT
            LDA   TYPE2,X
            JSR   PCOUT
            LDA   TYPE3,X
            JSR   PCOUT
:NOTYPE
*
* DISPLAY # OF BLOCKS
*
            JSR   PRSPC
            LDY   #$13
            LDA   (POINT),Y
            STA   HEXNUM
            INY
            LDA   (POINT),Y
            STA   HEXNUM+1
            JSR   HEXDEC
            JSR   PRT5RJ
            JSR   PRSPC
*
* MODIFIED DATE
*
            LDY   #$22
            JSR   SHDAT0
            LDA   :TYPE
            CMP   #1
            BEQ   :MODTIM
:GODUN      RTS
*
* MODIFIED TIME
*
:MODTIM     LDY   #$24
            JSR   SHTIM0
*
* CREATION DATE
*
            JSR   PRSPC
            LDY   #$19
            JSR   SHDAT0
*
* CREATION TIME
*
            LDY   #$1B
            JSR   SHTIM0
*
* ENDFILE
*
            JSR   PRSPC
            LDY   #$17
            LDX   #2
:EFLP       LDA   (POINT),Y
            STA   HEXNUM,X
            DEY
            DEX
            BPL   :EFLP
            JSR   HEXDC3
            JSR   PRT8RJ
*
* SUBTYPE
*
            JSR   PRSPC
            LDY   #$10
            LDA   (POINT),Y
            LDX   #:SUBS1-:SUBS-1
:SBTPLP     CMP   :SUBS,X
            BEQ   :GOTSUB
            DEX
            BPL   :SBTPLP
            RTS
*
:GOTSUB     LDA   :SUBS1,X
            PHA
            JSR   PCOUT
            LDA   #"="
            JSR   PCOUT
            PLA
            CMP   #"A"
            BNE   :RSUB
            LDA   #"$"
            JSR   PCOUT
            LDY   #$20
            LDA   (POINT),Y
            JSR   PHBYTE
            LDY   #$1F
            LDA   (POINT),Y
            JMP   PHBYTE
*
:RSUB       LDY   #$20
            LDA   (POINT),Y
            TAX
            DEY
            LDA   (POINT),Y
            JSR   HEXDC2
            JMP   PRT5RJ
*
*
* THE PATTERN MATCHER ENTRY POINT
*
MATCH       EQU   *
            JSR   CURPNT
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
FTOCR       EQU   *
            LDY   #1
            LDA   (POINT),Y
            CMP   #$10
            BCS   :FTPRODOS
*
:FTDOS33    LDX   #$1E        ;(NAME LENGTH)
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
:FTPRODOS   DEY               ;1 --> 0
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
TYPCHR      EQU   *
            ASC   "?BARSBAIT"
TYPBYT      EQU   *
            DB    $00,$40,$20,$10,$08,$04,$02,$01,$00
:TYPE       DB    $0
:SUBS       DB    $04,$06,$FC,$FD,$FB,$FA,$B4,$B5,$B6
:SUBS1      ASC   "RAAAAAAAA"
*
* [4am] backported types from v9
* $5A  CFG  Configuration
* $AD  BDF  Apple IIgs BASIC Data
* $BD  FST  Apple IIgs File System Translator
* $E0  LBR  Archive (format in auxtype)
*
* and added new types based on online sources
* https://www.kreativekorp.com/miscpages/a2info/filetypes.shtml
* http://www.apple-iigs.info/techfiletype.php
* https://public.websites.umich.edu/~archive/apple2/misc/programmers/filetypes.txt
* $16  PFS  PFS Document
* $2E  P8C  ProDOS 8 Code Module
* $42  FTD  File Type Definitions
* $50  GWP  Apple IIgs Word Processing
* $51  GSS  Apple IIgs Spreadsheet
* $52  GDB  Apple IIgs Database
* $53  DRW  Object Oriented Graphics
* $54  GDP  Apple IIgs Desktop Publishing
* $55  HMD  HyperMedia
* $58  HLP  Help File
* $BC  LDF  Apple IIgs Generic Load File
* $C2  ANI  PaintWorks Animation
* $C3  PAL  PaintWorks Palette
* $C5  OOG  Object-Oriented Graphics
* $C7  CDV  Apple IIgs Control Panel
* $D5  MUS  Music sequence
* $D6  INS  Instrument
* $D7  MDI  MIDI
* $D8  SND  Apple IIgs Audio
*
TYPES       EQU   *
            DB    $01,$02,$03,$04,$05,$06,$07,$08  ;00-07
            DB    $09,$0A,$0B,$0C,$0F,$10,$11,$16  ;08-0F
            DB    $19,$1A,$1B,$2E,$42,$50,$51,$52  ;10-17
            DB    $53,$54,$55,$58,$5A,$AB,$AC,$AD  ;18-1F
            DB    $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7  ;20-27
            DB    $B8,$B9,$BA,$BB,$BC,$BD,$BF,$C0  ;28-2F
            DB    $C1,$C2,$C3,$C5,$C7,$C8,$C9,$CA  ;30-37
            DB    $D5,$D6,$D7,$D8,$E0,$E2,$EF,$F0  ;38-3F
            DB    $F9,$FA,$FB,$FC,$FD,$FE,$FF  ;40-46
*
*                               1               2               3               4
* Index #          0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456
*
*                  00000000000001111112455555555AAABBBBBBBBBBBBBBBCCCCCCCCCDDDDEEEFFFFFFFF
* Filetype         123456789ABCF0169ABE20123458ABCD0123456789ABCDF01235789A567802F09ABCDEF
*
TYPE1       EQU   *
            ASC   "BPPTPBFFBDWSDRRPAAAPFGGGDGHHCGTBSOLSRESTNCTDLFDPPAPOCFFIMIMSLDPCPIIBVRS"
TYPE2       EQU   *
            ASC   "ACTXDINOAAPOIPPFDWS8TWSDRDMLFSDDRBI1TXTSDDORDSONINAODONCUNDNBTAM1NVAAEY"
TYPE3       EQU   *
            ASC   "DDXTANTT33FSRDISBPPCDPSBWPDPGBFFCJB6LERFAALVFTCTCILGVNDNSSIDRSSD6TRSRLS"
*
* 'DO' THE CATALOG DISPLAY &
* EVERYTHING THAT IT INVOLVES
*
CATDISINTERNAL
            JSR   INITCDINTERNAL
            LDA   #0
            STA   SP
            JSR   RDACNTINTERNAL
            LDA   NACTIV
            BNE   CATDS2
            JSR   CROUT
            LDA   #MNOFILES
            JMP   PRTPRS
*
CATDS1      EQU   *
            LDA   CURR
            PHA
            JSR   INITCDINTERNAL
            PLA
            STA   CURR
            JSR   RDACNTINTERNAL
CATDS2      EQU   *
            LDA   NACTIV
            BEQ   :NOFILES
            LDA   STATE
            CMP   #$04
            BEQ   :BOOTMES
            JSR   ST8MSG
            JMP   CDDOKEYINTERNAL
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
            JMP   CDDOKEYINTERNAL
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
SCROLF      EQU   *
            LDX   CURR        ;IF BEFORE
            INX               ;END OF
            CPX   NACTIV      ;CATALOG:
            BCS   :OUTBAD
            STX   CURR
:OUTBAD     RTS
*
*        CATALOG DISPLAY
*   KEYPRESS FUNCTION HANDLER
* entry point called by this module
* and VIEW
*
CDDOKEYINTERNAL
            JSR   SEECAT
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
            BEQ   CDDOKEYINTERNAL ;SCROLL
            DEX
            STX   CURR
            JMP   CDDOKEYINTERNAL
*
:FSCROL     JSR   SCROLF      ;FORWARD
            JMP   CDDOKEYINTERNAL ;SCROLL
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
            BNE   CDDOKEYINTERNAL ;NOT FOUND
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
            BCC   CDDOKEYINTERNAL
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
            DW    CDDOKEYINTERNAL
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
CPYDEL      EQU   *
            JSR   UNMARKINTERNAL
            BEQ   :CPYDEL0    ;NOTHING THERE
            DEC   FILNUM
:CPYDEL0    JSR   SEECAT
            CLC
            RTS
*
TOGGLE      EQU   *
            LDX   CURR        ;GET CURRENT
            LDA   STATUS,X    ;FILE STATUS
            EOR   #$FF        ;TOGGLE IT
            STA   STATUS,X    ;REPLACE IT
NIL         EQU   *
            CLC
            RTS
*
PATTRN      EQU   *
            JSR   GETPAT      ;READ PATTERN
            BCS   :OUT
            LDA   #$00        ;INITIALIZE
            STA   CURR
:LOOP       JSR   MATCH ;TRY A MATCH
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
:LOOP       JSR   MATCH ;MATCH:ALL DONE
            BCC   :OUT
            JSR   SEECAT
            JSR   SCROLF      ;NO MATCH:
            BCC   :LOOP       ;TRY NEXT FILE
            LDA   LASTM       ;NONE:RESTORE
            STA   CURR        ;CURRENT FILE
:OUT        JMP   ST8MSG
*
LOKAST      EQU   *
            JSR   CURPNT
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
FILEQINTERNAL
            LDA   FILNUM
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
            JSR   CATLN1INTERNAL ;DISPLAY LINE
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
UNMARKINTERNAL
            LDY   CURR        ;IS SOMETHING
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
* 'DIVE OUT' of subdirectory (non-interactive)
*
* entry point called by COPY, DELETE, and
* DISKMAP to return to parent directory
* after operating on all the relevant files
* in a subdirectory
*
DIVOUTINTERNAL
            LDA   #0
            DB    $2C         ;HIDE LDA #$FF
*
* 'DIVE OUT' of subdirectory (interactive)
*
* entry point called when user presses [<]
* to return to parent directory during the
* interactive catalog display
* 
DIVOT0      EQU   *
            LDA   #$FF
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
SP0         EQU   *
            STA   CURR
            JSR   PRVNM
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
NIL0        EQU   *
            CLC
            RTS
*
DO1         EQU   *
            BIT   DOSNOW
            BPL   NIL0
            JSR   DIVOT0
            JMP   DO1A
*
DO2         EQU   *
            BIT   DOSNOW
            BPL   NIL0
            JSR   DIVEININTERNAL
DO1A        EQU   *
            BCS   :ERR2
            SEC
            RTS
*
:ERR2       JSR   LOWMES
            JSR   KYESC
ST8MSG      EQU   *
            LDA   STATE
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
DIVEININTERNAL
            JSR   CURPNT
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
*
* INITIALIZES CATALOG DISPLAY
* called from catalog display, but also
* from DIVECK after diving into or out of
* a subdirectory, also from VIEW
*
INITCDINTERNAL
            LDA   #$00
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
****** NEW TRACK READ/WRITE STUFF ***
*
* *DELFLG=$80 FOR ACTIVE FILES
*        =$00 FOR DELETED
*
RDACNTINTERNAL
            BIT   DOSNOW
            BPL   :ISDOS33    ;DOS 3.3 DISK
*
* IT'S A PRODOS DISK
*
            LDA   #>SDIR
            STA   DIRADR
            LDA   #$14
            STA   COUNT
            JMP   PRDCNT

*
:ISDOS33    LDA   #>DOSDAT    ;SET UP DATADR
            STA   DATADR
            LDA   #>CAT1
            JSR   CLRCAT      ;ZERO CATALOG
            LDX   #$00
            STX   NACTIV      ;NO FILES YET
            INX
            STX   RCMND       ;READ COMMAND
            LDX   #>VTOC1
            JSR   DOVTOC      ;READ VTOC.
*
:SECTLP     LDY   #$01        ;FIND PTR TO
            LDA   (POINT),Y   ;NEXT SECTOR
            BEQ   :OUT        ;NIL PTR?
            CMP   #$28
            BCS   CATERR
            STA   RTRACK      ;NO:SAVE TRACK
            INY
            LDA   (POINT),Y   ;& SECTOR
            CMP   #$10
            BCS   CATERR
            STA   RSECTR
            INC   RPAGE       ;NEXT PAGE
            INC   POINT+1
            JSR   PHRWTS      ;READ CATALOG
            BCS   :OUT        ;BAD SECTOR?
            LDY   #$0B
:POSNLP     LDA   (POINT),Y
            BEQ   :OUT        ;NO MORE FILES?
            AND   #$80
            EOR   DELFLG
            BEQ   :NOTWANT    ;WANTED FILE?
            TYA
            LDX   NACTIV
            STA   CBYTE,X     ;PUT INTO ARRAY
            LDA   RPAGE
            STA   CSECTR,X
            INC   NACTIV
:NOTWANT    TYA               ;NEXT FILE IN
            CLC               ;SECTOR
            ADC   #$23
            TAY
            BNE   :POSNLP     ;DONE SECTOR?
            DEC   COUNT       ;ROOM 4 MORE?
            BNE   :SECTLP
:OUT        RTS
CATERR      EQU   *
            LDA   #$52
            JMP   ERROU1
*
* PRDCNT
*
* INPUT
*       DIRBLK,+1 = 1ST BLK OF DIR
*       DIRADR    = BUFFER ADDR
*       COUNT     = MAX. # OF DIR BLKS
*                   ALLOWED
*
* OUTPUT
*       RPAGE = NEXT AVAILABLE PAGE
*
PRDCNT      EQU   *
            LDA   DIRBLK
            STA   BLKNUM
            LDA   DIRBLK+1
            STA   BLKNUM+1
            LDA   DIRADR
            STA   RPAGE
            STA   POINT+1
            LDA   #0
            STA   POINT
            STA   NACTIV
            JSR   RDBLK
            BCS   :RDRERR
*
* MAKE SURE THIS IS REALLY THE FIRST
* BLOCK OF THE DIRECTORY
*
            LDY   #0
            LDA   (POINT),Y
            INY
            ORA   (POINT),Y
            BEQ   :REALLY
*
* NOT THE FIRST BLOCK, SO BACK UP
* TO PREVIOUS BLOCK AND CHECK AGAIN
*
            LDA   (POINT),Y
            STA   DIRBLK+1
            DEY
            LDA   (POINT),Y
            STA   DIRBLK
            JMP   PRDCNT

:RDDR2      JSR   RDBLK
            BCS   :RDRERR
*
* SET UP BLKNUM FOR NEXT BLOCK OF DIR
*
:REALLY     LDY   #2
            LDA   (POINT),Y
            STA   BLKNUM
            INY
            LDA   (POINT),Y
            STA   BLKNUM+1
*
* ADD FILE NAME ADDRESSES TO ARRAY
*
            LDY   #4
:RDRLP      INY
            BEQ   :NEXT
            LDA   (POINT),Y
            DEY
            CMP   #0
            BEQ   :SKIP       ;NEVER USED ENTRY
            LDX   DELFLG
            LDA   (POINT),Y
            AND   #$0F
            BNE   :ACTIVE
*
* INACTIVE (DELETED) ENTRY, USE IT?
*
            CPX   #$80
            BEQ   :SKIP       ;WANT ACTIVE
            BNE   :USEIT      ;ALWAYS
*
* ACTIVE ENTRY, USE IT?
*
:ACTIVE     CPX   #0
            BEQ   :SKIP       ;WANT INACTIVE
            LDA   (POINT),Y
            AND   #$F0
            CMP   #$E0
            BCS   :SKIP       ;SUB HEADER
*
:USEIT      TYA
            LDX   NACTIV
            STA   CBYTE,X
            LDA   POINT+1
            STA   CSECTR,X
            INC   NACTIV
            BEQ   :UHOH       ;OVERFLOW
:SKIP       TYA
            CLC
            ADC   #$27
            TAY
            BCC   :RDRLP
            INC   POINT+1
            INC   RPAGE
            BNE   :RDRLP      ;ALWAYS
*
:NEXT       INC   POINT+1
            INC   RPAGE
            LDA   BLKNUM
            ORA   BLKNUM+1
            BEQ   :RDRDON     ;NO MORE BLOCKS
            DEC   COUNT
            BNE   :RDDR2      ;READ NEXT BLK
*
*
*
:RDRDON     LDA   RPAGE
            STA   DATADR
            CLC
:RDRERR     RTS
*
*
* MORE THAN 255 FILE NAMES FOUND
*
:UHOH       DEC   NACTIV
            INC   RPAGE
            BNE   :RDRDON     ;ALWAYS
*
* PLACE INPUT FILE INTO ENTRY
*   AT (*POINT)
*
PLACE       EQU   *
            LDX   #0
:CRLP       INX
            LDA   LINEIN,X
            CMP   #$8D
            BNE   :CRLP
            BIT   DOSNOW
            BMI   :PIPRODOS
            LDA   #" "        ;MOVE LINE TO
            LDY   #$20        ;ENTRY:
:SPACELP    STA   (POINT),Y   ;COPY SPACES
            DEY               ;TO ENTRY
            CPY   #$03
            BPL   :SPACELP
            TXA
            TAY
            DEX               ;BEFORE CR
            INY               ;ENTRY OFFSET 3
            INY               ;MORE
            LDA   #$FF
:PUTLP0     STA   :MASK
:PUTLP      LDA   LINEIN,X    ;COPY CHARS
            AND   :MASK
            STA   (POINT),Y
            DEY
            DEX
            BPL   :PUTLP
            CLC
            RTS
:PIPRODOS   LDY   #0
            LDA   (POINT),Y
            AND   #$F0
            STA   (POINT),Y
            TXA
            AND   #$0F
            TAX
            ORA   (POINT),Y
            STA   (POINT),Y
            TXA
            TAY
            DEX
            LDA   #$7F
            BNE   :PUTLP0     ;ALWAYS
*
:MASK       DB    $0
*
SETLOK      EQU   *
            BIT   DOSNOW
            BPL   :DOS33
            LDY   #$1E
            LDX   #1          ;ANTICIPATE LOCKING
            CMP   #$FF
            BEQ   :SLK3       ;LOCK IT
            CMP   #$80
            BNE   :SLK2       ;UNLOCK IT
            LDA   (POINT),Y
            AND   #$C2
            BNE   :SLK3       ;TOGGLE UNLOCKED --> LOCKED
:SLK2       LDX   #$C3
:SLK3       LDA   (POINT),Y
            AND   #$20        ;ISOLATE BACKUP BIT
            STA   (POINT),Y
            TXA
            ORA   (POINT),Y
:SLK4       STA   (POINT),Y
            RTS
*
:DOS33      LDY   #2
            CMP   #$80
            BNE   :DS1
            LDA   (POINT),Y
            EOR   #$80
            JMP   :SLK4
:DS1        AND   #$80
            PHA
            LDA   (POINT),Y
            AND   #$7F
            STA   (POINT),Y
            PLA
            ORA   (POINT),Y
            JMP   :SLK4
*
CATLIBEND
