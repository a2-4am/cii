*
:LOCATE     CLD
            CLI
            JSR   SETNOR
            JSR   INIT
            JSR   HOME                ;Clear screen before SETVID might
            JSR   SETVID              ; change 80 screen to 40.
            JSR   SETKBD
            STA   KBDSTB
*
* FIGURE OUT SLOT NUMBER
*
            LDX   #1                  ;Mark the ProDOS global page as
            STX   MEMTABL+$17         ; busy in the global page bitmap.
            LDA   DEVNUM
            STA   BOOTDV
            BPL   :ISD1
            INX
:ISD1       STX   RPDRIV
* AND #$70
* STA *RPSLOT
*
* Move MAIN portion of program into place
*
            JSR   DECRUNCH            ;DECRUNCH->CODEADR
*
            LDA   $FBB3               ;FOR LATER
            PHA
*
* MOVE NOBOOT TO $D000
*
* Y ALREADY ZERO
*
            LDA   $C083
            LDA   $C083
            TYA                       ;FILL WITH 0'S
:NBLP1      STA   $D000,Y             ;BECAUSE WE COPY THE
            INY                       ;ENTIRE PAGE LATER
            BNE   :NBLP1
            JSR   DECRUNCH            ;DECRUNCH->$D000

*
* WHILE WE'RE IN THE LANGUAGE CARD,
* SAVE AUXMEM IRQ VECTOR.
*
            PLA                       ;FBB3 from ROM
            CMP   #6
            BNE   :SKIPIRQ            ;NOT //E
*
            STA   $C009               ;AUX LC
            LDA   $FFFE
            STA   IRQSAV
            LDA   $FFFF
            STA   IRQSAV+1
            STA   $C008
*
:SKIPIRQ    LDA   $C082
*
*
* MOVE INTERLEAVE TABLES
*
            LDY   #$30
:ILMOV      LDA   :INTRLV-1,Y
            STA   INTRLV-1,Y
            DEY
            BNE   :ILMOV
*
*
* CLEAR OUT PRODOS MEMORY BITMAP
*
            LDX   #$16
            TYA                       ;0
:CLRMAP     STA   MEMTABL,X
            DEX
            BNE   :CLRMAP
*
* (no more minimum version at $BFFC?
* ProDOS manual says it's a reserved location)
*
            STA   PINVFL              ;0
            STA   PFX
            STA   PPFX
            STA   SPFX
            STA   APFX
            STA   ACURR
            STA   PCURR
            STA   SCURR
            STA   RPSLOT
            STA   :RAMFLG
*
* PUT VERSION NUMBER AT $BFFD
*
            LDA   #CIIPVER
            STA   IVERSION
*
            LDY   DEVCNT
:GETDVLP    LDA   DEVLST,Y
            PHA
            AND   #$F0
            CMP   #$B0
            BNE   :GETDV2
            STA   :RAMFLG
:GETDV2     PLA
            STA   DVICES,X
            INX
            DEY
            BPL   :GETDVLP
            DEX
            STX   NUMDEV
:LOOP2      LDA   DEVNUM
            EOR   DVICES,X
            AND   #$F0
            BEQ   :GETDEVQ
            DEX
            BPL   :LOOP2
*
:GETDEVQ    STX   CURDEV
            STX   CURDVP
            STX   CURDVS
            STX   CURDVA
*
*
* LOOK AT $280 AND FIND OUT WHERE WE
* CAME FROM. IF NAME AT $280 HAS NO
* '/', DON'T CHANGE PREFIX. IF NAME
* '/', REMOVE FILENAME AT END OF PATH
* NAME AND SET PREFIX.
*
            LDY   $280
            BEQ   :NOCHNG
            BMI   :NOCHNG
:PFX0       LDA   $280,Y
            AND   #$7F
            CMP   #$2F                ;'/'
            BEQ   :GOTSLSH
            DEY
            BNE   :PFX0
*
*
* NO '/' IN NAME AT $280, SO DON'T
* CHANGE PREFIX.
*
            BEQ   :NOCHNG             ;ALWAYS
*
:GOTSLSH    DEY
            BMI   :NOCHNG
            STY   $280
*
* SET PREFIX
*
            JSR   MLI
            DB    $C6
            DW    :PFXLST
*
:NOCHNG     JSR   MLI                 ;GET BOOT PFX
            DB    $C7
            DW    :BTLST
*
*
* SETUP A2E, FLAG80, ISAUX
*
* A2E:
*  0 --> NOT AN APPLE //E OR //C
* FF --> //E OR //C
*
* FLAG80:
*  0 --> NO 80-COLUMN
* FF --> 80-COLUMN
*
* ISAUX:
*  0 --> No aux memory.
*  1 --> /RAM remains intact OR non-ProDOS volume is in S3,D2,
*        so aux memory is not available.
* FE --> Big /RAM is in S3,D2, so aux memory is available.
* FF --> /RAM marked disconnected, or there's no S3,D2 device
*        at all, so aux memory is available.
            LDX   #0
            STX   FLAG80              ;ASSUME 40 COL
            STX   A2E                 ;ASSUME NOT 2E
            STX   GOTMM               ;Assume MM not available
            STX   MMISOPEN            ; & of course not open.
            LDA   $FBB3
            CMP   #$06
            BNE   :NO80COL            ;->NOT //E, so not 80 col, either.
            DEC   A2E                 ;0-->FF
            LDY   MACHID
            TYA
            AND   #2
            BEQ   :NO80COL            ;NO 80-COL
            DEC   FLAG80              ;GOT 80-COL
:NO80COL    TYA
            AND   #$30
            CMP   #$30
            BNE   :DUNCHK             ;->NOT 128K
            INX
            LDA   :RAMFLG
            BMI   :DUNCHK             ;->/RAM ACTIVE
            LDX   #$FF
:DUNCHK     STX   ISAUX
*
* CHECK IF /RAM EXISTS, AND IF SO DOES
* IT HAVE ANY FILES
*
            CPX   #1
            BNE   :NORAM              ;NO /RAM
*
* READ /RAM DIRECTORY
*
            JSR   MLI                 ;Read /RAM directory
            DB    $80
            DW    :RBLST
            BCS   :NORAM
*
* IF /RAM > $FF BLOCKS, MARK *ISAUX
* AS USEABLE
*
            LDA   #$FE                ;(Value for big RAMdisk)
            LDY   SDIR+$2A
            BNE   :DISCON             ;> $FF BLKS
            LDA   SDIR+4              ;Is this a valid ProDOS device?
            AND   #$F0
            CMP   #$F0                ; (Is this a volume key block?)
            BNE   :NORAM              ;->No: don't give it up, whatever it is.
            LDA   SDIR+$25            ;Any files on this ProDOS device?
            ORA   SDIR+$26
            BNE   :NORAM              ;->Yes: can't use auxmem.
            LDA   #$FF
*
* /RAM EXISTS AND HAS NO FILES, SO
* MARK *ISAUX AS USEABLE
*
:DISCON     STA   ISAUX
*
:NORAM      LDA   ISAUX               ;After all that, do we have usable auxmem?
            BPL   :SETMISC            ;->Nope.
*
* Auxiliary memory is available now at startup.
* Locate Memory Manager code into safe haven in aux memory.
*
            JSR   DECRUNCH            ;DECRUNCH->MMBEG
            LDA   #MMBEG              ;source start.
            STA   A1L
            LDA   #>MMBEG
            STA   A1H
            LDA   #MMEND              ;source end (+1, but oh well)
            STA   A2L
            LDA   #>MMEND
            STA   A2H
            LDA   #AUXMM              ;destination
            STA   A4L
            LDA   #>AUXMM
            STA   A4H
            SEC                       ;transfer from main to aux
            JSR   AUXMOVE
            DEC   GOTMM               ;Mark that we got Memory Manager.
*
* Continue with miscellaneous initialization stuff.
*
:SETMISC    LDY   #0
            STY   DOSNOW
            STY   AUXFLG
            STY   PSLOT               ;NO PRINTER.
            STY   FMT400K
            DEY                       ;FF
            STY   TRKFLG
            LDA   #$0A
            STA   ASYNC
            LSR                       ;A-->5
            STA   DSYNC
*
* Turn off 80 cols.
            BIT   FLAG80
            BPL   :AFTER80
            LDA   #$15                ;(ProDOS Tech. Ref., 5.3.1.3, page 99)
            JSR   $C300
*
:AFTER80    LDA   #FILER
            STA   $3F2
            LDA   #>FILER
            STA   $3F3
            EOR   #$A5
            STA   $3F4
            JSR   INIT
            LDA   #0
            JSR   VLEFT
            LDA   #QHEADR
            JSR   PRINT
*
            LDA   KVERSION            ;ProDOS version # is 1.3?
            CMP   #$03
            BNE   :CHKCLK
            JSR   PRHERE              ;Yes: warn 'em.
            DB    $8D,$8D
            ASC   "ProDOS 1.3 has problems. We suggest you update. "
            DB    0
            JSR   RDKEY
:CHKCLK     LDA   MACHID
            LSR
            BCC   :NOCLK
            JMP   :SKIPDAT
*
:NOCLK      JSR   PRHERE
            DB    $8D,$8D
            ASC   "Enter date or press [Esc] to skip"
            DB    $8D,$8D,$0
            LDA   DATE
            BEQ   :NODAT
            LDX   DATE+1
            JSR   SHODAT
            JMP   :NXTIN0
*
:NODAT      JSR   PRHERE
            ASC   "DD-MMM-YY"
            DB    $0
:NXTIN0     LDX   #0
:NXTINX     STX   CH
:NXTIN      JSR   CASKEY
            CMP   #$9B
            BNE   :NOTESC
            JMP   :SKIPDAT
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
            BEQ   :BADDAY             ;DAY=0
            CMP   :DAYS,Y
:GBDDAY     BCS   :BADDAY             ;DAY TOO BIG
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
            BNE   :LEAP               ;NOT FEB.
            LDA   :DAY
            CMP   #$1D                ;29TH?
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
:GOSKIP     JMP   :SKIPDAT

:BADDAY     LDX   #0
            DB    $2C
:BADMON     LDX   #3
            LDA   #$87
            JSR   PCOUT
            JMP   :NXTINX
*
:SKIPDAT    LDA   FLAG80
            BMI   :GOT80
            JMP   :NO80               ;NO 80-COL PRES
*
* FIND OUT IF USER WANTS TO USE
* 80-COLUMN CATALOG DISPLAYS
*
* FIRST, FIND OUT IF ON //GS
*
:GOT80
            SEC
            JSR   $FE1F
            BCS   :NOTGS
*
* WE ARE ON AN APPLE //GS. MAKE A TOOL CALL TO READ
* THE 40/80 COLUMN SETTING FROM BRAM.
*
            CLC
            XCE
            REP   $30
            MX    %00
            PEA   $0000               ; -wordspace for result
            PEA   $0019               ; -get 40/80 setting
            LDX   #$0C03              ;_ReadBParam
            DB    $22,0,0,$E1         ;JSL $E10000
            PLA
            SEP   $30
            MX    %11
            SEC
            XCE
            LDX   #$FF
            CMP   #1
            BNE   :ASK80
            BEQ   :USER80

*
:NOTGS
            LDA   MACHID
            AND   #$C8
            CMP   #$88                ;//C?
            BEQ   :IS2C
*
* NOT A //C, SO CHECK IF LASER BY
* READING CASSETTE PORT ($C060). ON AN
* APPLE THIS LOCATION ALWAYS HAS MSB=1
* (IF NO CASSETTE PLUGGED IN).
*
* AT THIS POINT, IF WE ARE ON A LASER
* THE MSB MUST BE ZERO (80 COL) BECAUSE
* IF IT WERE 1 (40 COL) *FLAG80 WOULD
* HAVE HAD MSB OFF.
*
            LDA   $C060
            BPL   :IS2C               ;ON LASER
*
:ASK80      JSR   PRHERE
            DB    $8D,$8D
            ASC   "Do you want 80-column catalog"
            DB    $8D
            ASC   "displays (Y/N) ? Y"
            DB    $0
            DEC   CH
:AGN80      JSR   CASKEY
            CMP   #$9B
            BEQ   :NO80
            CMP   #"Y"
            BEQ   :NO80
            CMP   #$8D
            BEQ   :NO80
            EOR   #"N"
            BNE   :AGN80
            STA   FLAG80
            BEQ   :NO80               ;ALWAYS
*
:IS2C       LDX   #$FF
            LDA   $C060
            BPL   :USER80             ;USERS SAYS 80
            INX
:USER80     STX   FLAG80
*
*
*
*
:NO80       JMP   FILER               ;GO START
*
:PFXLST     DB    $1
            DW    $280
*
:BTLST      DB    $1
            DW    BTPFX
*
:RBLST      DB    $3
            DB    $B0
            DW    SDIR
            DB    $2,$0
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
:TEMP       DB    $0
:DAY        DB    $0
:MONTH      DB    $0
:YEAR       DB    $0
:DAYS       DB    $20,$1E,$20,$1F,$20,$1F,$20,$20,$1F,$20
            DB    $1F,$20
:RAMFLG     DB    $0
*
:INTRLV     DB    $0,$D,$B,$9,$7,$5,$3,$1
            DB    $E,$C,$A,$8,$6,$4,$2,$F
*
            DB    $0,$7,$E,$6,$D,$5,$C,$4
            DB    $B,$3,$A,$2,$9,$1,$8,$F
*
            DB    $0,$E,$D,$C,$B,$A,$9,$8
            DB    $7,$6,$5,$4,$3,$2,$1,$F
*


