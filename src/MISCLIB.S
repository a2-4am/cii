            TYP   BIN
            DSK   ../build/MISCLIB.O
            PUT   VARS
            PUT   ../build/PRODOS.VARS
            PUT   ../build/IO.VARS
            PUT   ../build/LINEINPUT.VARS
            PUT   ../build/ERRORS.VARS
            PUT   ../build/UILIB.VARS
            PUT   ../build/READLIB.VARS
            PUT   ../build/DISKLIB.VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/UNDELETE.VARS
            ORG   UNDELEND
MISCLIB
            ORG   *+3
            RTS

************************************
*      MISCELLANEOUS LIBRARY       *
* MAKESUB - Create Subdirectory    *
* SETCLOCK - Enter Date            *
* BOOTPG - Change Boot Program     *
* VIEW - View Files                *
* ALPHA - Alphabetize Catalog      *
* RENAME - Rename Files/Volume     *
* LOCK - Lock/Unlock Files         *
* private:                         *
* FIXSUB - LOCK/REN/ALPHA cleanup  *
************************************
*
************************************
*           MAKE DIRECTORY         *
************************************
*
MAKESUBINTERNAL
            JSR   COMTRE
            BIT   DOSNOW
            BMI   :MK0
            JMP   NODOS3
*
:MK0        JSR   GETDNM      ;GET DIRECTORY NAME
            BCS   :OUT
            TYA
            STA   FILE
            LDA   #$0F
            STA   FTYPE
            LDA   #0
            STA   AUXTYP
            LDA   #$20
            STA   AUXTYP+1
            JSR   GETDAT
            JSR   MKDIR
            BCS   :ERROUT
            JSR   PRHERE
            DB    $8D,$8D
            ASC   "Subdirectory created",8D,00
            JMP   PRESS
:OUT        RTS
:ERROUT     JMP   ERROUT
*
*
* SET CLOCK (interactively)
*
SETCLOCKINTERNAL
            LDA   #$16
            JSR   VLEFT
            LDA   DATE
            BEQ   :NODAT
            LDX   DATE+1
            JSR   SHODAT
            JMP   :NXTIN0
*
:CNVT       AND   #$0F
            STA   :TEMP
            ASL
            ASL
            CLC
            ADC   :TEMP
            ASL
            STA   :TEMP
            TXA
            AND   #$0F
            CLC
            ADC   :TEMP
            RTS
*
:TEMP       DB    $0
:DAY        DB    $0
:MONTH      DB    $0
:YEAR       DB    $0
:DAYS       DB    $20,$1E,$20,$1F,$20,$1F,$20,$20,$1F,$20
            DB    $1F,$20
*
:NODAT      JSR   PRHERE
            ASC   "DD-MMM-YY"
            DB    $0
:NXTIN0     LDX   #0
:NXTINX     STX   CH
:NXTIN      JSR   CASKEY
            CMP   #$9B
            BNE   :NOTESC
            RTS
:NOTESC     CMP   #$8D
            BNE   :NOTCR
            JMP   :CR
:NOTCR      CMP   #$88
            BNE   :NOTLFT
            DEX
            BMI   :NXTIN0
            DEC   CH
            CPX   #2
            BEQ   :DECAGN
            CPX   #6
            BNE   :NXTIN
:DECAGN     DEX
            DEC   CH
            JMP   :NXTIN
*
:NOTLFT     CPX   #9
            BCS   :BEEP
            CMP   #$95
            BNE   :NXTIN1
            LDY   CH
            LDA   (BASL),Y
:NXTIN1     CPX   #2
            BCC   :SBDIG
            CPX   #7
            BCS   :SBDIG
            CMP   #$C1
            BCC   :BEEP
            CMP   #$DB
            BCC   :GOODIN
:BEEP       LDA   #$87
            JSR   PCOUT
            JMP   :NXTIN
:GOODIN     STA   LINEIN,X
            JSR   PCOUT
            INX
            CPX   #2
            BEQ   :INCAGN
            CPX   #6
            BNE   :NXTIN
:INCAGN     INC   CH
            INX
            BNE   :NXTIN
*
:SBDIG      CMP   #$B0
            BCC   :BEEP
            CMP   #$BA
            BCC   :GOODIN
            CPX   #1
            BNE   :BEEP
            CMP   #$C1
            BCC   :BEEP
            CMP   #$DB
            BCS   :BEEP
            PHA
            LDA   LINEIN
            STA   LINEIN+1
            LDA   #0
            STA   CH
            LDA   #$B0
            STA   LINEIN
            JSR   PCOUT
            LDA   LINEIN+1
            JSR   PCOUT
            INC   CH
            LDX   #3
            PLA
            JMP   :NXTIN1
:GOSKIP     RTS
*
:CR         CPX   #9
            BCS   :CROK
            CPX   #0
            BEQ   :GOSKIP
            JMP   :BEEP
:CROK       LDA   LINEIN
            LDX   LINEIN+1
            JSR   :CNVT
            STA   :DAY
            CMP   #$20
            BCS   :GBDDAY
            LDY   #$0B
:GETDT1     LDA   LINEIN+3
            CMP   MONTH1,Y
            BEQ   :GETDT3
:GETDT2     DEY
            BPL   :GETDT1
            JMP   :BADMON
:GETDT3     LDA   LINEIN+4
            CMP   MONTH2,Y
            BNE   :GETDT2
            LDA   LINEIN+5
            CMP   MONTH3,Y
            BNE   :GETDT2
            LDA   :DAY
            BEQ   :BADDAY     ;DAY=0
            CMP   :DAYS,Y
:GBDDAY     BCS   :BADDAY     ;DAY TOO BIG
            INY
            STY   :MONTH
            LDA   LINEIN+7
            LDX   LINEIN+8
            JSR   :CNVT
            STA   :YEAR
            AND   #3
            BEQ   :LEAP
            LDA   :MONTH
            CMP   #2
            BNE   :LEAP       ;NOT FEB.
            LDA   :DAY
            CMP   #$1D        ;29TH?
            BEQ   :BADDAY
:LEAP       LDA   :MONTH
            ASL
            ASL
            ASL
            ASL
            ASL
            ORA   :DAY
            STA   DATE
            LDA   :YEAR
            ROL
            STA   DATE+1
*
* set time to 0
            LDA   #0
            STA   TIME
            STA   TIME+1
*
* disable clock driver after setting date
* and update ProDOS machine byte to say there's no clock
            LDA   #$60
            STA   JCLOCK
            LDA   MACHID
            AND   #$FE
            STA   MACHID
            RTS

:BADDAY     LDX   #0
            DB    $2C
:BADMON     LDX   #3
            LDA   #$87
            JSR   PCOUT
            JMP   :NXTINX
*
************************************
*     CHANGE BOOTING PROGRAM       *
************************************
*
BOOTPGINTERNAL
            JSR   COMHDR
            LDA   #$04
            STA   STATE
            BIT   DOSNOW
            BPL   :DOS33
            JMP   NOPRO
*
:DOS33      LDX   #9          ;CHECK T01S09
            JSR   :CHKWRAPR   ;FOR DOS
            BCC   :GOTSECT
            LDX   #7          ;CHECK T01S07
            JSR   :CHKWRAPR   ;FOR PRONTO-DOS
            BCS   :NODOS
:GOTSECT    LDA   RSECTR      ;REAL DOS:
            STA   :NAMESEC
            JSR   CATDIS      ;SELECT NEW
            JSR   SWPCHK
            JSR   CURPNT      ;BOOT PROGRAM
            LDY   #$20
            LDX   #$1D
:COPYNAM    LDA   (POINT),Y   ;COPY FILENAME
            STA   DATA+$75,X  ;INTO DOS
            DEY               ;SECTOR
            DEX
            BPL   :COPYNAM
            LDX   :NAMESEC    ;RESET DOS
            JSR   PUTSEC      ;SECTOR
            INC   RCMND
            JSR   DORWTS      ;WRITE
            LDA   #0          ;RUN CMND
            STA   RTRACK      ;TRACK &
            LDA   :T0SECT     ;SECTOR
            STA   RSECTR
            DEC   RCMND
            JSR   DORWTS      ;READ IT
            LDY   #$02
            LDX   #$14
            LDA   (POINT),Y   ;CHECK FILETYPE
            AND   #$7F        ;STRIP LOCK BIT
            BEQ   :POKERUN    ;& SET PROPER
            LDX   #$34        ;RUN CODE:
            CMP   #$04        ;0 -> 14
            BEQ   :POKERUN    ;4 -> 34
            LDX   #$06        ;ELSE -> 6
:POKERUN    STX   DATA+$42
            INC   RCMND
            JMP   DORWTS      ;WRITE BACK
*
:NODOS      JSR   PRHERE
            DB    $8D,$8D,$8D,$8D
            ASC   "No boot program to change",00
            JMP   PRESS
*
:CHKWRAPR   TXA
            CLC
            ADC   #4          ;9->D,7->B
            STA   :T0SECT
            JSR   PUTSEC      ;SET & READ
            JSR   DORWTS      ;DOS SECTOR
            LDX   #0
            LDY   #$FD
            JMP   CHKDOS
*
:NAMESEC    DB    $0
:T0SECT     DB    $0
*
************************************
*           VIEW FILES             *
************************************
*
VIEWINTERNAL
            JSR   COMTRE
            LDA   #$05
            STA   STATE
            JSR   INITCD
            JSR   RDACNT
            LDA   NACTIV
            BNE   :NEXTFIL
            JMP   NOFIL0
*
:NEXTFIL    LDA   #3
            STA   WNDTOP
            JSR   PRTFL1      ;CLEAR FILENAME
            JSR   HOME
            LDA   #MPSTAT45
            JSR   LOWMES
            JSR   CDDOKEY     ;CAT DISPLAY
            JSR   HOME        ;VIEW FILES
*
            LDA   #4
            JSR   VLEFT
            LDA   #MDASHES
            JSR   PRINT
            LDA   #5
            STA   WNDTOP
            JSR   :SEEFILE    ;FILENAME
            JSR   SWPCHK      ;CHECK DISK
            JSR   OPNSRC      ;OPEN FILE
            LDA   #$FF
            STA   :RDFLAG
:NOASK      LDA   #$05
            STA   WNDTOP
:PAGELP     JSR   :PAGE       ;SEE PAGE
            BCS   :NEXTFIL
            JSR   :PROMPT     ;MORE?
            BCS   :NEXTFIL
            LDA   :DONE       ;MORE TO DO?
            BEQ   :PAGELP
            BNE   :NEXTFIL
*
* PRINT FILENAME
:SEEFILE    LDA   #$05        ;RESET
            STA   :TEMPV      ;VIEW CHAR
            LDA   #$00        ;POSITION
            STA   :TEMPH
            STA   :DONE       ;& END OF VIEW
            JSR   CURPNT
            JMP   PRTFIL
*
:PROMPT     LDA   #$03
            JSR   VLEFT       ;VTAB
            LDA   :DONE
            BMI   :PROMPT2
            LDA   #MCRESC
            JSR   PRINT
:PROMPT3    JSR   GETKEY
            CMP   #$9B
            BEQ   :SECOUT     ;(BEQ->CS)
            CLC
:SECOUT     RTS
*
:PROMPT2    LDA   #MPRESS1
            JSR   PRINT
            LDA   #$1E        ;CLEAR LINE
            STA   WNDWTH      ;UP TO BYTE
            JSR   CLREOL      ;COUNT
            LDA   #$28
            STA   WNDWTH
            BNE   :PROMPT3    ;ALWAYS
*
* PRINT PAGE OF VIEW DATA
:PAGE       LDA   :RDFLAG     ;NEED TO READ
            BEQ   :GOTDATA    ;DATA?
            JSR   SWPCHK
            JSR   RDDATA      ;READ IT
            LDA   #$00
            STA   :RDFLAG     ;CLEAR FLAG
            STA   POINT       ;POINT AT DATA
            LDA   DATADR
            STA   POINT+1
:GOTDATA    LDA   :TEMPV      ;RESTORE HTAB
            JSR   TABV        ;& VTAB
            LDA   :TEMPH
            STA   CH
            LDA   CHOOZOPT    ;TEXT OR
            BNE   :TEXT       ;VALUES?
            LDA   #$11
            STA   :NCRS       ;LINE COUNTER
:LINELP     LDA   $C000
            CMP   #$9B
            BEQ   :PGABORT
            LDY   #$00        ;VALUES HERE<-
            JSR   CROUT
:HEXLP      JSR   :COUNTER
            LDA   (POINT),Y   ;GET BYTE
            JSR   PHBYTE      ;PRINT IT
            JSR   PRSPC
            INY
            CPY   #$08        ;8 BYTES
            BNE   :HEXLP
            JSR   PRSPC
            LDY   #$00        ;REWIND FOR
:CHRLP      LDA   (POINT),Y   ;ASCII OUT
            ORA   #$80
            JSR   CTRL?       ;NO CTRLS
            BCC   :SEECHR
            LDA   #"."
:SEECHR     JSR   PCOUT       ;PRINT CHAR
            INY
            CPY   #$08        ;8 BYTES
            BNE   :CHRLP
            TYA               ;8
            CLC
            ADC   POINT       ;UPDATE DATA
            STA   POINT
            LDA   POINT+1
            ADC   #0
            STA   POINT+1
            CMP   RPAGE       ;OUT OF DATA
            BCC   :VTEST      ;IN MEMORY?
            DEC   :RDFLAG
            LDA   EOF         ;END OF FILE?
            BNE   :SAYDONE
            BEQ   :POUT
:VTEST      DEC   :NCRS       ;ENOUGH LINES?
            BNE   :LINELP
            BEQ   :POUT
*
:PGABORT    SEC
            RTS
*
:TEXT       LDA   #$28        ;SET 40-CHAR
            STA   :NCHARS     ;LINES
            LDA   #$10        ;16 LINES
            STA   :NCRS
            LDY   #$00
:TEXTLP     LDA   $C000
            CMP   #$9B
            BEQ   :PGABORT
            JSR   :COUNTER
            LDA   (POINT),Y   ;GET CHAR
            ORA   #$80
            CMP   #$8D
            BEQ   :DOCR
            JSR   CTRL?       ;NO CTRLS
            BCS   :NXTCHR     ;(EXCEPT CR)
            JSR   PCOUT       ;PRINT CHAR
            DEC   :NCHARS     ;DEC CHAR COUNT
            BNE   :NXTCHR     ;TO ZERO?
*            LDA   PRNTR?
            BEQ   :DECNCRS
:DOCR       JSR   CROUT
:DECNCRS    DEC   :NCRS
            LDA   #$28
            STA   :NCHARS
:NXTCHR     INC   POINT
            BNE   :NXTCHR0
            INC   POINT+1
:NXTCHR0    LDA   POINT+1
            CMP   RPAGE       ;OUT OF DATA
            BCC   :TTEST      ;IN MEMORY?
            DEC   :RDFLAG
            LDA   EOF
            BNE   :SAYDONE    ;END OF FILE?
            BEQ   :POUT
:TTEST      LDA   :NCRS       ;ENOUGH LINES?
            BEQ   :POUT
            BNE   :TEXTLP
*
:SAYDONE    DEC   :DONE
:POUT       LDA   CV          ;SAVE HTAB &
            STA   :TEMPV      ;VTAB
            LDA   CH
            STA   :TEMPH
            CLC
            RTS
*
*
:COUNTER    LDX   #$05
:COUNTIT    LDA   SCREEN,X
            CMP   #" "
            BEQ   :SPACE
            CMP   #"9"
            BEQ   :NINE
            CLC
            ADC   #$01
            DB    $CD
:SPACE      LDA   #"1"
            STA   SCREEN,X
:CNTOUT     RTS
:NINE       LDA   #"0"
            STA   SCREEN,X
            DEX
            BPL   :COUNTIT
            RTS
*
*
:TEMPY      DB    $0
:NCHARS     DB    $0
:NCRS       DB    $0
:TEMPH      DB    $0
:TEMPV      DB    $0
:DONE       DB    $0
:RDFLAG     DB    $0
*
************************************
*       ALPHABETIZE CATALOG        *
************************************
*
ALPHAINTERNAL
            JSR   COMTRE
            LDA   #$01
            STA   DELFLG
            JSR   RDACNT      ;READ FILES
            LDA   NACTIV
            BEQ   :NOFILES
            LDX   #$FF
            STX   CURR
:ALPHA1     INC   CURR        ;NEXT POSN TO
            LDX   CURR        ;ALPHABETIZE
            CPX   NACTIV      ;GOT EM ALL?
            BCS   :DUNALFA
            LDA   CBYTE,X     ;MAKE THIS
            STA   POINT2      ;FILE CHOICE
            LDA   CSECTR,X    ;FOR NOW
            STA   POINT2+1
:SEARCH1    INX               ;LOOK AHEAD
            CPX   NACTIV      ;NO FILES TO
            BCS   :SWAPALF    ;COMPARE WITH?
            JSR   SETPNT      ;POINT AT IT.
            JSR   CKDEL
            BCS   :SEARCH1
            LDA   (POINT2),Y
            JSR   CKDEL1
            BCS   :CHOICE
            LDA   (POINT2),Y
            AND   #$0F
            STA   :LAST2      ;LENGTH OF POINT2 NAME
            LDA   (POINT),Y   ;ANTICIPATE PRODOS
            AND   #$0F
            STA   :LAST
            BIT   DOSNOW
            BMI   :COMP0      ;Y ALREADY 0
            LDA   #$20
            STA   :LAST2
            STA   :LAST
            LDY   #$02
:COMP0      INC   :LAST2
:COMPARE    CPY   :LAST       ;EXACT MATCH?
            BCS   :CHOICE     ;YES: SWAP (MIGHT BE F12 & F1)
            INY
            CPY   :LAST2      ;PAST LENGTH OF POINT2?
            BCS   :SEARCH1    ;YES: SKIP IT
            LDA   (POINT),Y   ;COMPARE CHARS
            CMP   (POINT2),Y
            BEQ   :COMPARE    ;UNTIL DIFF.
            BCS   :SEARCH1    ;FORGET IF HI.
:CHOICE     LDA   POINT       ;IF LOWER MAKE
            STA   POINT2      ;IT THE NEW
            LDA   POINT+1     ;CHOICE.
            STA   POINT2+1
            BNE   :SEARCH1    ;(ALWAYS)
*
:NOFILES    JMP   NOFIL0
*
* PUT CHOSEN ENTRY INTO POSITION
:SWAPALF    JSR   CURPNT      ;POINT AT POSN
            LDY   #$22
            BIT   DOSNOW
            BPL   :SWAPLP
            LDY   #$26
:SWAPLP     LDA   (POINT),Y   ;SWAP WITH
            TAX               ;CHOICE
            LDA   (POINT2),Y
            STA   (POINT),Y
            TXA
            STA   (POINT2),Y
            DEY
            BPL   :SWAPLP
            BMI   :ALPHA1     ;(ALWAYS)
*
*
* SEE ALPHABETIZED CATALOG
:DUNALFA    LDX   #$00
            STX   SHOW
:COUNTIT    LDA   #$14        ;20 FILES/SCRN
            STA   :COUNT
:SEEALFA    JSR   SETPNT
            JSR   CKDEL       ;DELETED?
            BCS   :NXTFILE    ;YES:DONT SHOW
            LDA   #$FF        ;SHORT DISPLAY
            JSR   CATLIN      ;NO:SHOW
            JSR   CROUT
            DEC   :COUNT      ;& COUNT
:NXTFILE    INC   SHOW        ;NEXT FILE
            LDX   SHOW
            CPX   NACTIV      ;SEEN EM ALL?
            BCS   :DUNSEE     ;YES.
            LDA   :COUNT      ;NO:PAGE FULL?
            BNE   :SEEALFA    ;NO.
            JSR   KYESC       ;YES:KEYPRESS.
            JMP   :COUNTIT    ;COUNT MORE.
*
:COUNT      DB    $0
:LAST       DB    $0
:LAST2      DB    $0
*
* ASK TO SAVE IT
:DUNSEE     JSR   PRHERE
            DB    $8D
            ASC   "[G]-Go, [Esc]-Exit"
            DB    $0
            JSR   GETKEY
            CMP   #"G"
            BNE   :ALPHAQ
            JMP   FIXSUB
:ALPHAQ     RTS
*
CKDEL       EQU   *
            LDY   #0
            LDA   (POINT),Y
CKDEL1      EQU   *
            BIT   DOSNOW
            BMI   :PRODOS
            ASL
            RTS
:PRODOS     CLC
            AND   #$0F
            BNE   :OUT
            SEC
:OUT        RTS
*
**********************************
*      FILE LOCK/UNLOCK          *
*          & RENAME              *
**********************************
*
RENAMEINTERNAL
            LDA   #$03
            STA   STATE
            LDA   CHOOZOPT
            BEQ   REN2        ;RENAME FILES
            JSR   COMHDR
            BIT   DOSNOW
            BMI   RENVOL
            JMP   NODOS3
*
LOCKINTERNAL
            LDA   #$02
            STA   STATE
*
REN2        EQU   *
            JSR   COMTRE
            JSR   CATDIS
            LDA   FILNUM
            BNE   :GOTFILS
            JMP   NOSEL
:GOTFILS    JMP   FIXSUB
*
* RENAME VOLUME
*
RENVOL      EQU   *
            JSR   GETNVNM     ;GET NEW VOL NAME
            BCS   :RENVOLQ
            JSR   RDBLK2
            BCS   :RENERR
            LDY   #0
:RNLOOP     LDA   VOLNAM,Y
            BEQ   :RN2
            STA   VTOC1+$5,Y
            INY
            BNE   :RNLOOP
*
:RN2        TYA
            ORA   #$F0
            STA   VTOC1+4
            JMP   DOWBLK
:RENVOLQ    RTS
:RENERR     JMP   ERROUT
*
*
* *FIXSUB IS CALLED BY LOCK/UNLOCK,
* RENAME AND ALPHABETIZE TO MAKE
* THE NEEDED CHANGES TO THE SUBDIR
* HEADER. HEADER NAME, ACCESS AND
* PARENT POINTERS ARE UPDATED.
*
FIXSUB      EQU   *
            JSR   SWPCHK
            BIT   DOSNOW
            BPL   :FXSB1      ;NOT PRODOS
*
            LDA   #0
            STA   CURR
:FXLOOP     JSR   CURPNT
            JSR   :FIXSUB
            INC   CURR
            LDA   CURR
            CMP   NACTIV
            BNE   :FXLOOP
*
:FXSB1      JMP   WRCAT1
*
:OUT        RTS
:FIXSUB     JSR   DIR?
            BCS   :OUT        ;NOT SUBDIR
            LDA   #>DATA      ;TEMP BUFFER
            STA   POINT2+1
            STA   RPAGE
            LDA   #4
            STA   POINT2
*
* READ 1ST BLOCK OF SUBDIR
*
            LDY   #$11
            LDA   (POINT),Y
            STA   BLKNUM
            INY
            LDA   (POINT),Y
            STA   BLKNUM+1
            JSR   RDBLK
            BCS   :OUT
*
* COPY FILENAME TO HEADER NAME
*
            LDY   #$0F
:FSLP1      LDA   (POINT),Y
            STA   (POINT2),Y
            DEY
            BNE   :FSLP1
            LDA   (POINT),Y
            AND   #$0F
            ORA   #$E0
            STA   (POINT2),Y
*
* DON'T NEED TO CHANGE ACCESS BYTE
* BECAUSE PRODOS DOESN'T.
*
* LDY #$1E
* LDA (*POINT),Y
* STA (*POINT2),Y
*
* SET UP PARENT POINTERS
*
            LDA   POINT+1
            AND   #$FE        ;/!\ assumes SDIR is aligned to even page boundary
            CMP   #>SDIR      ;14
            BNE   :FS2        ;NOT 1ST
            LDA   DIRBLK
            LDX   DIRBLK+1
            JMP   :FS3
*
:FS2        SEC
            SBC   #$2
            STA   TEMP+1
            LDA   #0
            STA   TEMP
            LDY   #3
            LDA   (TEMP),Y    ;PARENT BLK HI
            TAX
            DEY
            LDA   (TEMP),Y    ;PARENT BLK LO
:FS3        LDY   #$23
            STA   (POINT2),Y
            INY
            TXA
            STA   (POINT2),Y
*
* FIGURE OUT PARENT ENTRY NUMBER
*
            LDY   #$26
            LDA   (POINT2),Y  ;ENTRY LENGTH
            STA   TEMP
*
            LDA   POINT
            LDX   #1
:FS4        CMP   #4
            BEQ   :FS5
            SEC
            SBC   TEMP
            INX
            BNE   :FS4        ;ALWAYS
*
:FS5        TXA
            DEY
            STA   (POINT2),Y
*
* WRITE SUBDIR BLOCK BACK
*
            JMP   WTBLK
*
MISCLIBEND
