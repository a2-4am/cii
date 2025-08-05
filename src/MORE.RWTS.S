*-----------------------------------
*
* MISC. ROUTINES
*
*-----------------------------------
*
*
SETPX    JSR   MLI
         DB    $C6
         DW    SPLST
         STA   RRTN
         RTS
*
*
SPLST    DB    $1
         DW    PFX
*
*
*
* PUT LIST OF FILES IN COPY ORDER
*
FILMOV   LDX   #$01
         STX   :ORDER     ;START WITH #1
:NXTFIL2 DEX              ;POSITION -1
         CPX   FILNUM     ;DONE ALL
         BEQ   :MOUT      ;FILES?
         LDX   #$FF
:NXTLOOK INX
         LDA   STATUS,X   ;LOOK FOR #
         CMP   :ORDER
         BNE   :NXTLOOK
         LDY   :ORDER     ;FOUND IT:
         DEY
         PHA
         LDA   STATUS,Y   ;SWAP ENTRIES
         STA   STATUS,X   ;WITH CORRECT
         PLA              ;POSITION
         STA   STATUS,Y
         LDA   CBYTE,X
         PHA
         LDA   CBYTE,Y
         STA   CBYTE,X
         PLA
         STA   CBYTE,Y
         LDA   CSECTR,X
         PHA
         LDA   CSECTR,Y
         STA   CSECTR,X
         PLA
         STA   CSECTR,Y
         INC   :ORDER     ;NEXT #
         LDX   :ORDER
         BNE   :NXTFIL2
:MOUT    RTS
*
:ORDER   DB    $0
*
*
CNVNAM   LDA   DOSNOW
         EOR   PDOS
         BPL   :NOCNV     ;NO CONVERT
         BIT   DOSNOW
         BPL   :DOS33
*
* DOS --> PRODOS
*
         LDY   FILE
         CPY   #$10
         BCC   :CNVLP
         LDY   #$0F
:CNVLP   LDA   FILE,Y
         DEY
         CMP   #" "
         BEQ   :CNVLP
         INY
         STY   FILE
:CNVLP1  LDA   FILE,Y
         CMP   #$B0
         BCC   :MAKEDOT
         CMP   #$BA
         BCC   :USEIT
         CMP   #$C1
         BCC   :MAKEDOT
         CMP   #$DB
         BCC   :USEIT
:MAKEDOT LDA   #"."
:USEIT   AND   #$7F
         STA   FILE,Y
         DEY
         BNE   :CNVLP1
         LDA   FILE+1     ;1ST CHAR
         CMP   #$2E       ;IS IT A DOT?
         BNE   :NOCNV     ;NO
         LDA   #$41       ;YES: CHANGE
         STA   FILE+1     ; TO 'A'
:NOCNV   RTS
*
* PRODOS --> DOS
*
:DOS33   LDY   #0
:DSLP    INY
         LDA   FILE,Y
         ORA   #$80
         STA   FILE,Y
         CPY   FILE
         BCC   :DSLP
:DSLP1   INY
         LDA   #$A0       ;BLANK FILL
         STA   FILE,Y
         CPY   #$1E
         BCC   :DSLP1
         RTS
*
*
*
*-------------------------------------
*
* READ SOURCE DATA
*
RDDATA   LDY   RELCNT
         BEQ   :RDD1
         LDA   RBLKL-1,Y
         STA   RBLKL-1
         LDA   RBLKH-1,Y
         STA   RBLKH-1
:RDD1    LDA   #$00
         STA   RELCNT
         STA   EOF
         BIT   DOSNOW
         BPL   :DOS33
         JMP   :PRODOS
*
:DOS33   LDA   #$01
         STA   RCMND
         LDA   DATADR
         STA   RPAGE
         LDA   STSP       ;TSLIST EMPTY?
         BNE   :RDMORE
:NXTTSL  LDA   SRCTSL+1   ;POINT TO IT
         STA   RTRACK
         LDA   SRCTSL+2
         STA   RSECTR
         JSR   RDTSL      ;READ IT
*
:RDMORE  LDX   STSP
         LDA   SRCTSL,X   ;NONZERO TS
         STA   RTRACK     ;PAIR?
         ORA   SRCTSL+$1,X
         BEQ   :NEXTRD
         LDA   SRCTSL+$1,X ;SET TRACK
         STA   RSECTR     ;& SECTOR
*
* SET RBLKH = $7A*TSLCTR+(STSP-$C)/2
*
         LDA   #0
         STA   :SUM
         STA   :SUM+1
         LDX   #7
         LDA   #$7A
         STA   :TEMP2
         LDA   TSLCTR
         STA   :TEMP0
         LDA   TSLCTR+1
         STA   :TEMP1
:MULTLP  LSR   :TEMP2
         BCC   :SKIPADD
         LDA   :SUM
         CLC
         ADC   :TEMP0
         STA   :SUM
         LDA   :SUM+1
         ADC   :TEMP1
         STA   :SUM+1
:SKIPADD ASL   :TEMP0
         ROL   :TEMP1
         DEX
         BPL   :MULTLP
         LDA   STSP
         SEC
         SBC   #$0C
         LSR
         CLC
         ADC   :SUM
         LDY   RELCNT
         STA   RBLKL,Y
         LDA   :SUM+1
         ADC   #0
         STA   RBLKH,Y
*
         INC   RELCNT
         JSR   PHRWTS     ;READ DATA
         BCS   :ERROUT
         INC   RPAGE      ;NEXT PAGE
:NEXTRD  INC   STSP       ;NEXT TS PAIR
         INC   STSP
         BEQ   :EOTSL     ;END OF LIST?
         LDA   RPAGE
         CMP   HIMEM      ;OUT OF MEMORY?
         BCC   :RDMORE
         RTS
:EOTSL   LDA   SRCTSL+1   ;A NEXT TSLIST?
         ORA   SRCTSL+2
         BEQ   :OUT
         JMP   :NXTTSL
:OUT     DEC   EOF        ;NO: EOF
         RTS
:TEMP0   DB    $0
:TEMP1   DB    $0
:TEMP2   DB    $0
:SUM     DB    $0,$0
:ERROUT  JMP   ERROUT
*
:PRODOS  LDA   DATADR
         STA   :TEMP
         LDA   BLKNUM
         ORA   BLKNUM+1
         BEQ   :READ2
         LDA   :TEMP
:READLP  STA   RPAGE
         JSR   :RDBLOK
         JSR   CURPNT
         LDY   #$15
         LDA   (POINT),Y
         INY
         ORA   (POINT),Y
         INY
         ORA   (POINT),Y
         BEQ   :GTEOF1
         LDY   RELCNT
         LDA   IBPTR
         STA   RBLKL,Y
         LDA   MIBPTR
         STA   RBLKH,Y
         INC   RELCNT
         INC   :TEMP
         INC   :TEMP
:READ2   JSR   FNDBLK
         BCS   :GOTEOF
         LDA   :TEMP
         CMP   HIMEM
         BCC   :READLP
         STA   RPAGE
         RTS
*
:GOTEOF  LDA   :TEMP
         STA   RPAGE
         LDA   :BUFF
         BEQ   :GTEOF1
         LDY   RELCNT
         LDA   RBLKL-1,Y
         CLC
         ADC   #1
         STA   RBLKL,Y
         LDA   RBLKH-1,Y
         ADC   #0
         STA   RBLKH,Y
         INC   RELCNT
         INC   RPAGE
:GTEOF1  DEC   EOF
         RTS
:TEMP    DB    $0
*
:RDBLOK  LDA   UNIT
         STA   :UNIT
         LDA   BLKNUM
         STA   :BLKNUM
         LDA   BLKNUM+1
         STA   :BLKNUM+1
         LDA   RPAGE
         STA   :BUFF+1
         LDA   RADR
         STA   :BUFF
         JSR   MLI
         DB    $80
         DW    :RBLST
         STA   RRTN
         BCS   ERR1
         RTS
:RBLST   DB    $3
:UNIT    DB    $0
:BUFF    DB    $0,$0
:BLKNUM  DB    $0,$0
*
* READ TSLIST & UPDATE SECTOR POINTER
RDTSL    JSR   RDTSL1
         BCS   ERR1
         RTS
*
FNDBLK   JSR   FNBLK1
         BCC   :FND1
:ERR?    CMP   #$FF
         BEQ   ERR1
         SEC
:FND1    RTS
ERR1     JMP   ERROUT
*
FNBLK1   LDA   STRTYP     ;IF SAPLING,
         CMP   #$10       ; RETURN EOF
         BEQ   :FNDEOF
         CMP   #$D0
         BEQ   :SUBDIR
:CKINDX  INC   IBPTR
         BEQ   :CKTREE
:LOOKDAT LDX   IBPTR
         LDA   SIB,X
         STA   BLKNUM
         ORA   SIB+$100,X
         BEQ   :CKINDX    ;NO ENTRY
         LDA   SIB+$100,X
         STA   BLKNUM+1
         CLC
         RTS
*
* INDEX BLOCK USED UP
*
:CKTREE  LDA   STRTYP
         CMP   #$30
         BNE   :FNDEOF    ;NOT TREE
:CKMSTR  INC   MIBPTR
         LDX   MIBPTR
         BMI   :FNDEOF
         LDA   SMIB,X
         STA   BLKNUM
         ORA   SMIB+$100,X
         BEQ   :CKMSTR
         LDA   SMIB+$100,X
         STA   BLKNUM+1
         LDA   #>SIB
         STA   RPAGE
         JSR   RDBLK
         BCC   :LOOKDAT
         LDA   #$FF
         DB    $CD
:FNDEOF  LDA   #0
:ERR     SEC
         RTS
*
:SUBDIR  LDA   #0
         STA   RADR
         JSR   RDBLK
         LDA   #$FF
         BCS   :ERR
         LDY   #2
         LDA   (RADR),Y
         STA   BLKNUM
         INY
         LDA   (RADR),Y
         STA   BLKNUM+1
         ORA   BLKNUM
         BEQ   :FNDEOF    ;END OF SUBDIR
*
* CARRY ALREADY CLEAR
*
*CLC
         RTS
*
*
*-------------------------------------
*
* OPEN SOURCE FILE
*
OPNSRC   JSR   OPNFIL
         BCS   ERR1
         RTS
*
OPNFIL   JSR   CURPNT     ;POINT TO FILE
         BIT   DOSNOW
         BPL   :DOS33
*
:PRODOS  LDY   #$11
         LDA   (POINT),Y  ;KEY BLK LO
         STA   BLKNUM
         INY
         LDA   (POINT),Y  ;KEY BLK HI
         STA   BLKNUM+1
         LDY   #$0F
:NAMELP  LDA   (POINT),Y
         STA   FILE,Y
         DEY
         BPL   :NAMELP
         LDA   FILE
         PHA
         AND   #$0F
         STA   FILE
         PLA
         AND   #$F0
         STA   STRTYP
         CMP   #$10
         BEQ   :OPENDAT
         CMP   #$20
         BEQ   :OPENIB
         CMP   #$30
         BNE   :OPENDAT   ;SUBDIRECTORY
*
:OPENMIB LDA   #>SMIB
         STA   RPAGE
         JSR   RDBLK
         BCS   :ERR
         LDA   SMIB
         STA   BLKNUM
         LDA   SMIB+$100
         STA   BLKNUM+1
:OPENIB  LDA   #>SIB
         STA   RPAGE
         JSR   RDBLK
         BCS   :ERR
         LDA   SIB
         STA   BLKNUM
         LDA   SIB+$100
         STA   BLKNUM+1
:OPENDAT LDA   #0
         STA   MIBPTR
         STA   IBPTR
         STA   RELCNT
         CLC
:ERR     RTS
*
:DOS33   LDA   #$10
         STA   STRTYP
         LDY   #$FF
         STY   TSLCTR
         STY   TSLCTR+1
         LDY   #0
         LDA   (POINT),Y
         STA   RTRACK
         INY
         LDA   (POINT),Y
         STA   RSECTR
         INY
:DNMLP   LDA   (POINT),Y
         STA   FILE-2,Y
         INY
         CPY   #$21
         BCC   :DNMLP
         LDA   #$1E
         STA   FILE       ;LENGTH
         LDA   #$01
         STA   RCMND      ;FALL THRU...
*
*
RDTSL1   LDA   RPAGE
         PHA
         LDA   #>SRCTSL   ;READ INTO
         STA   RPAGE      ;TSLIST AREA
         INC   TSLCTR
         BNE   :RDTS1
         INC   TSLCTR+1
:RDTS1   JSR   PHRWTS     ;GET TSLIST
         LDA   #$0C       ;RESET SOURCE
         STA   STSP       ;TS POINTER
         PLA
         STA   RPAGE
         RTS
*
*
*
CTREE    LDA   #>SDNAME
         STA   POINT2+1
         LDY   #0
         STY   POINT2
         STY   :CURR
:TREELP  LDA   XS,Y
         SEC
         SBC   XSTART
         BCC   :GOSKIP
         CMP   DSPNUM
         BEQ   :TREELP0
         BCS   :GOSKIP
:TREELP0 STA   :CHINDX
         TAX
         LDA   :CH,X
         STA   CH
         LDA   YS,Y
         SEC
         SBC   YSTART
         BCC   :GOSKIP
         CMP   #$09
         BCC   :NOSKIP0
:GOSKIP  JMP   :SKIP
*
:NOSKIP0 ASL
         CLC
         ADC   #4
         JSR   TABV
         CPY   #0
         BEQ   :SPCS
*
         LDA   #"-"
         LDX   PREV,Y
         CPX   #$FF
         BEQ   :NOPRE1
         LDA   #"!"
:NOPRE1  PHA
         LDY   :CURR
         LDA   SIS,Y
         CMP   #$FF
         BEQ   :NOPRE2
         LDA   #$8A
         JSR   PCOUT
         LDA   #"!"
         JSR   PCOUT
         LDA   #$88
         JSR   PCOUT
         DEC   CV
         JSR   $FC22
:NOPRE2  PLA
         JSR   PCOUT
         LDA   #"-"
         JSR   PCOUT
         LDA   #">"
         BNE   :NOARO
*
:SPCS    LDA   #" "
         JSR   PCOUT
         JSR   PCOUT
:NOARO   JSR   PCOUT
         LDA   YS,Y
         CMP   YPOS
         BNE   :NOTINVS
         LDA   XS,Y
         CMP   XPOS
         BNE   :NOTINVS
         LDY   #$C0       ;INVERSE
         STY   PINVFL
:NOTINVS LDY   #0
         LDA   (POINT2),Y
         STA   :LEN
:CLP     INY
         LDA   (POINT2),Y
         ORA   #$80
         JSR   PCOUT
         CPY   :LEN
         BCC   :CLP
         STY   :LEN
         LDY   #0         ;NORMAL
         STY   PINVFL
         LDY   :CURR
         LDA   KITTEN,Y
         CMP   #$FF
         BEQ   :SKIP
         LDY   :LEN
:DASHLP  LDA   #"-"
         JSR   PCOUT
         LDA   CH
         CMP   CHMAX
         BCS   :SKIP
         INY
         CPY   #$11
         BCC   :DASHLP
         LDA   #">"
         JSR   PCOUT
*
:SKIP    JSR   INCPT2
         INC   :CURR
         LDY   :CURR
         CPY   END
         BCS   :FIN
         JMP   :TREELP
*
:FIN     LDX   #5
:FIN0    LDA   :CHL,X
         TAY
         LDA   #$15
         STA   CV
:FIN1    JSR   $FC22
         LDA   (BASL),Y
         CMP   #"!"
         BEQ   :FIN2A
:FIN1A   DEC   CV
         LDA   CV
         CMP   #4
         BCS   :FIN1
:FIN2    DEX
         BPL   :FIN0
:OUT     RTS
*
:FIN2A   INY
         LDA   (BASL),Y
         DEY
         CMP   #" "
         BNE   :FIN3
         LDA   CV
         PHA
:FIN2B   INC   CV
         JSR   $FC22
         LDA   CV
         CMP   #$16
         BCS   :FIN2C
         LDA   #"!"
         STA (BASL),Y
         BNE   :FIN2B     ;ALWAYS
*
:FIN2C   PLA
         STA   CV

:FIN3    DEC   CV
         LDA   CV
         CMP   #4
         BCC   :FIN2
         JSR   $FC22
         LDA   (BASL),Y
         CMP   #"-"
         BEQ   :FIN1A
         LDA   #"!"
         STA (BASL),Y
         BNE   :FIN3      ;ALWAYS

:LEN     DB    $0
:CURR    DB    $0
:CH      DB    $1,$13,$25,$37
:CHINDX  DB    $0
:TEMP    DB    $0
:CHL     DB    $0,$1,$9,$12,$13,$1B
*
*
*
INCPT2   LDA   POINT2
         CLC
         ADC   #$10
         STA   POINT2
         BCC   IP3
         INC   POINT2+1
IP3      RTS
*
MKTREE   LDA   #>FILBUF
         STA   RPAGE
         LDA   #>SDNAME
         STA   POINT2+1
         LDY   #$FF
         STY   CURMOM
         INY
         STY   YCUR
         STY   CURR
         STY   BLKNUM+1
         STY   SDBLKH
         STY   POINT2
         STY   XS
         STY   XCUR
         INY
         INY
         STY   BLKNUM
         STY   SDBLKL
:SBDR00  LDA   #0
         STA   SISPTR
:SBDR0   JSR   RDBLK
         BCS   IP3        ;READ ERR
:SBDR01  LDA   RPAGE
         STA   POINT+1
         LDA   FILBUF+2
         STA   BLKNUM
         LDA   FILBUF+3
         STA   BLKNUM+1
         LDA   #4
         STA   POINT
:SBDR1   LDY   #0
         LDX   CURR
         BEQ   :ISROOT
         LDA   (POINT),Y
         AND   #$F0
         CMP   #$D0
         BNE   :NOTDIR
         LDY   #$11
         LDA   (POINT),Y
         STA   SDBLKL,X
         INY
         LDA   (POINT),Y
         STA   SDBLKH,X
:ISROOT  LDA   #0
         STA   SDBLKL+$1,X
         STA   SDBLKH+$1,X
         LDA   CURMOM
         STA   MOM,X
         LDA   #$FF
         STA   KITTEN,X
         STA   SIS,X
         STA   PREV,X
         LDA   SISPTR
         BEQ   :SBDR2
         LDA   CURR
         STA   SIS-1,X
         SEC
         SBC   #1
         STA   PREV,X
:SBDR2   INC   SISPTR
*
* MOVE NAME INTO SDNAME
*
         LDY   #$0F
:MVNAME  LDA   (POINT),Y
         STA   (POINT2),Y
         DEY
         BNE   :MVNAME
         LDA   (POINT),Y
         AND   #$0F
         STA   (POINT2),Y
         JSR   INCPT2
*
         INC   CURR
         BEQ   :DONE      ;3/29/86
         LDA   CURR
         CMP   #1
         BEQ   :DIRDNE
:NOTDIR  LDA   POINT
         CLC
         ADC   #$27
         STA   POINT
:GOSBDR1 BCC   :SBDR1
         INC   POINT+1
         LDA   POINT+1
         CMP   #$0E       ;<--
         BCC   :GOSBDR1
         LDA   BLKNUM
         ORA   BLKNUM+1
         BEQ   :DIRDNE
         JMP   :SBDR0
*
* DONE WITH CURRENT SUBDIR
*
:DIRDNE  INC   CURMOM
         LDX   CURMOM
         LDA   SDBLKL,X
         STA   BLKNUM
         LDA   SDBLKH,X
         STA   BLKNUM+1
         ORA   BLKNUM
         BEQ   :DONE
         LDA   CURR
         STA   KITTEN,X
         CMP   KITTEN-1,X
         BNE   :DIRDN1
         LDA   #$FF
         STA   KITTEN-1,X
:DIRDN1  JMP   :SBDR00
*
:DONE    LDA   #$FF
         STA   KITTEN-1,X
         STX   END
         LDA   #0
         STA   CURR
         STA   YS
:TREE0   LDY   CURR
         LDA   KITTEN,Y
         CMP   #$FF
         BEQ   :NODAUG
         INC   XCUR
         LDX   XCUR
         STX   XMAX
         JMP   :TREE1
*
:NOSIS   LDA   MOM,Y
         CMP   #$FF
         BEQ   :ATROOT
         DEC   XCUR
         STA   CURR
         TAY
:NODAUG  LDA   SIS,Y
         CMP   #$FF
         BEQ   :NOSIS
         INC   YCUR
:TREE1   STA   CURR
         TAY
         LDA   XCUR
         STA   XS,Y
         LDA   YCUR
         STA   YS,Y
         JMP   :TREE0
*
*
:ATROOT  CLC
         RTS
*
*
*
***********************************
*                                 *
*     MISC. I/O ROUTINES          *
*                                 *
***********************************
*
*
* LINE INPUT - LINE AT LOC $200
*
GETLN    LDX   #$00
         BEQ   :GETLN1    ;ALWAYS
:BEEP    JSR   BELL
:GETLN1  JSR   CASKEY
         CMP   #$88
         BEQ   :LEFT
         CMP   #$95
         BEQ   :RIGHT
         CMP   #$8D
         BEQ   :CR
         CMP   #$9B
         BEQ   :ESC
         CMP   #$A0
         BCC   :GETLN1    ;CTRL CHAR
:GETLN2  CPX   LINLIM
         BCS   :GETLN1
         JSR   :CKLEGAL
         BCS   :BEEP
         STA   LINEIN,X
         JSR   PCOUT
         INX
         JMP   :GETLN1
*
:RIGHT   LDY   CH
         LDA   (BASL),Y
         JMP   :GETLN2
*
:LEFT    DEX
         BMI   GETLN
         JSR   PCOUT
         JMP   :GETLN1
*
:CR      STA   LINEIN,X
         STX   :TEMP
         PHA
         JSR   CLREOL
         PLA
         LDX   :TEMP
         SEC
         BEQ   :ESC       ;CR ONLY
         CLC
:ESC     RTS
*
:CKLEGAL CMP   #$C1
         BCC   :CKLEG1
         CMP   #$DB
         BCS   :CKLEG1
:ISLEGAL CLC
         RTS
*
:CKLEG1
         CMP   #$AC                ;","
         BNE   :NOTCOMA
         LDA   LINLIM
         CMP   #$24
         BNE   :NOTLEGL
         LDA   #$AC                ;","
         BNE   :ISLEGAL   ;ALWAYS
*
:NOTCOMA
         CMP   #$BD                ;"="
         BNE   :NOTEQL
         LDA   LINLIM
         CMP   #$24
         BNE   :NOTLEGL
         LDA   #$BD                ;"="
         BNE   :ISLEGAL   ;ALWAYS
*
:NOTEQL  BIT   DOSNOW
         BMI   :PRODOS
         CPX   #0         ;1ST CHAR?
         BEQ   :NOTLEGL   ;YES
         BNE   :ISLEGAL
*
:PRODOS  CPX   #0
         BNE   :NOT1ST
         CMP   #"/"
         BEQ   :ISLEGAL
:NOTLEGL SEC
         RTS
*
:NOT1ST  CPX   #1
         BNE   :NOT2ND
         STA   :TEMP
         LDA   LINEIN
         CMP   #"/"
         BEQ   :NOTLEGL
         LDA   :TEMP
:NOT2ND  CMP   #"."
         BEQ   :ISLEGAL
         CMP   #$B0
         BCC   :CKLEG2
         CMP   #$BA
         BCC   :ISLEGAL   ;DIGIT
:CKLEG2  CMP   #"/"
         BNE   :NOTLEGL
         LDA   LINLIM
         CMP   #$40
         BNE   :NOTLEGL
         DEX
         LDA   LINEIN,X
         INX
         CMP   #"/"
         BEQ   :NOTLEGL   ;TWO /'S
         LDA   #"/"
         BNE   :ISLEGAL   ;ALWAYS
:TEMP DB $0
*

* MY COUT ROUTINE
*
PCOUT    BIT   A2E
         BMI   :CHKMASK   ;ON //E
*
* ON A II PLUS: CONVERT LOWERCASE
*
         CMP   #$E0       ;LOWERCASE?
         BCC   :NO80A     ;NO
         SBC   #$20       ;MAKE UPPER.
         BNE   :NO80A     ;ALWAYS
*
:CHKMASK BIT   $C01F      ;80-COL?
         BPL   :NO80A     ;NO
*
         CMP   #$20
         BCC   :FLASH     ;MAKE $40-$5F
:NO80A   BIT   PINVFL
         BPL   :CHKPRTR   ;IF MASKED,
         BVC   :FLASH     ;IF INVERSE,
*
* IF II+: NO SPECIAL CHECK
* IF //E: CHECK FOR ALTCHARSET
*
         BIT   A2E        ;//E OR II+?
         BPL   :N2EALTL   ;II+
*
*//E:
*IF ALTSET: ALLOW INVERSE LOWER CASE
*
         BIT   $C01F      ;80-COL?
         BPL   :NO80      ;NO
*
* MUST DO SPECIAL CRAP FOR 80-COL
* BECAUSE 80-COL FIRMWARE INTERPRETS
* $00-$1F AS CONTROL CHARS. MUST
* CONVERT TO $40-$5F.
*
         CMP   #$20
         BCS   :Y2EALTL   ;AND $7F
         BCC   :FLASH     ;MAKE $40-$5F
*
:NO80    BIT   $C01E      ;ALTCHARSET?
         BPL   :N2EALTL   ;NO
         CMP   #$E0       ;IF NOT
         BCS   :Y2EALTL   ;LOWERCASE
:N2EALTL AND   #$3F       ;MASK INVERSE
:Y2EALTL AND   #$7F       ;MASKALTINVLOW
         BPL   :CHKPRTR
*
:FLASH   AND   #$3F       ;MAKE FLASH
         ORA   #$40
*
:CHKPRTR CMP   #$80       ;IF FLASH OR
         BCS   :GOCOUT    ;INVERSE:
         PHA              ;SAVE CHAR...
         LDA   PSLOT
         ORA   #$C0
         CMP   CSWL+1     ;PRINTING?
         BNE   :NOTPRTR   ;NO
         PLA              ;YES:
         BIT   A2E        ;WATCHING OUT
         BPL   :NLOWINV   ;FOR ALTCHR,
         BIT   $C01E
         BMI   :MAKNORM
:NLOWINV AND   #$3F
:MAKNORM ORA   #$80       ;CONVERT BACK
         CMP   #$A0       ;TO PRINTING
         BCS   :GOCOUT
         ORA   #$40
         BNE   :GOCOUT    ;(ALWAYS)
*
:NOTPRTR PLA
:GOCOUT  CMP   #$FF       ;SOME PRINTERS
         BNE   :GOCOUT2   ;DELETE WITH
         LDA   #$DF       ;FF'S
:GOCOUT2 JMP   COUT
*
*
*
*
***********************************
*                                 *
*          MESSAGES               *
*                                 *
***********************************
*
* PRINT TEXT THAT FOLLOWS THE JSR
* TO HERE
*
PRHERE   PLA              ;GET RETURN
         CLC              ;ADDRESS
         ADC   #$01
         STA   MESPNT     ;POINT AT
         PLA              ;FOLLOWING
         ADC   #$00       ;BYTE
         STA   MESPNT+1
         JSR   PRINT2     ;PRINT MESS.
         LDA   MESPNT+1   ;RESTORE
         PHA              ;RETURN ADDR.
         LDA   MESPNT
         PHA
         RTS              ;RETURN!
*
* MESSAGE PRINTER
* MESSAGE # IN ACC ->
*
PRINT    ASL              ;LOOK-UP &
         TAY
         LDA   MESSAG,Y   ;POINT AT
         STA   MESPNT     ;MESSAGE
         LDA   MESSAG+$1,Y
         STA   MESPNT+1
PRINT2   LDY   #$00
         LDA   (MESPNT),Y ;GET CHAR
         BEQ   :OUT
         CMP   #$2F
         BEQ   :CLEAR
         JSR   PCOUT      ;PRINT CHAR
:NEXT    INC   MESPNT     ;2-BYTE INC.
         BNE   PRINT2
         INC   MESPNT+1
         BNE   PRINT2     ;(ALWAYS)
:OUT     RTS
*
:CLEAR   JSR   CLREOL
         JMP   :NEXT
*
* (Menus 5 & 6 unused)
*
MESSAG   DW    :COPY      ;0 MENU 0
         DW    :CATALOG
         DW    :DELETE
         DW    :LOCK
         DW    :RENAME
         DW    :ALPHA
         DW    :FORMAT
         DW    :VERIFY
         DW    :VIEW      ;8
         DW    :TSMAP
         DW    :NEWBOOT
         DW    :UNDEL
         DW    :MKDIR
         DW    :NEWINFO
         DW    :QUIT
*
         DW    0          ;[4am] unused, previously :BCPY525
         DW    0          ;[4am] unused, previously :BCPY35
         DW    :FILES     ;11 MENU 0
         DW    :DISK
         DW    :DSKWFMT
         DW    :DOS
*
         DW    :NORMAL    ;15 MENU 1
         DW    :WLENGTH
         DW    :WDELETE
         DW    :WHIDDEN
*
         DW    :DISK      ;19 MENU 3
         DW    :FILES
         DW    :SPEED
*
         DW    :VALUES    ;1C MENU 4
         DW    :TEXT
*
         DW    :FILES     ;1E MENU 2
         DW    :DISK
         DW    :DOS
*
         DW    :TOOLONG   ;21
*
         DW    :PRODOS    ;22 MENU 7
         DW    :DOS33
*
         DW    :NOTSUB    ;24
         DW    :READ      ;25
         DW    :WRITE
         DW    :BLANK4    ;27
         DW    :BLANK3    ;28
         DW    :CPYENT
         DW    :SLOT      ;2A
         DW    :PRESS1    ;2B
         DW    :FILE
         DW    :PSTATE0
         DW    :PSTATE1
         DW    :PSTATE2
         DW    :PSTATE3   ;30
         DW    :PSTAT45

         DW    :PSTAT45
         DW    :TRACK
         DW    :SECTOR
         DW    :CRESC
         DW    :NOFILES
         DW    :INIT
         DW    :INROOT    ;38
         DW    :IO
         DW    :ERROR
         DW    :QUITOPT   ;3B
         DW    :SPACE
         DW    0          ;[4am] unused, previously :COPYTP
         DW    :HEADER
         DW    :DRIVE
         DW    :FILES     ;40 MENU 9
         DW    :VOLUME
         DW    :DASHES    ;42
         DW    :PRESS
         DW    :MORE
         DW    :ERR2B
         DW    :ERR44
         DW    :ERR45
         DW    :ERR44     ;48
         DW    :ERR48
         DW    :ERR49
         DW    :ERR4E
         DW    :ERR3F
         DW    :ERR52
         DW    :ERR47
         DW    :ERR52     ;4F
         DW    :ERR2F     ;50
         DW    :ERR2F     ;51
         DW    :CRESC1
         DW    :MTSUB     ;now 53
         DW    :TOOLNG0   ;now 54
         DW    :MSG55
         DW    :MSG56
         DW    :MSG57
         DW    :MSG58
         DW    :MSG59
         DW    :MSG5A
         DW    :MSG5B
         DW    :MSG5C
         DW    :MSG5D
         DW    :MSG5E
         DW    :MSG5F
         DW    :MSG60
         DW    :MSG61
         DW    :MSG62
         DW    :MSG63
         DW    :MSG64
         DW    :MSG65
         DW    :MSG66
         DW    :MSG67
         DW    :MSG68
         DW    :MSG69
         DW    :MSG6A
         DW    :MSG6B
         DW    :MSG6C
         DW    :MSG6D
         DW    :MSG6E
         DW    :MSG6F
*
*
*
:ERR2B   ASC   "Disk is write-protected"
         DB    $0
*
:ERR44   ASC   "Path not found"
         DB    $0
*
:ERR45   ASC   "Volume not online"
         DB    $0
*
:ERR48   ASC   "Disk full"
         DB    $0
*
:ERR49   ASC   "Directory full"
         DB    $0
*
:ERR4E   ASC   "Can not delete non-empty subdirectory"
         DB    $0
*
:ERR3F   ASC   "Subdirectory not found"
         DB    $0
*
:ERR52   ASC   "Not a ProDOS or DOS 3.3 disk"
         DB    $0
:ERR47   ASC   "Subdirectory already exists"
         DB    $0
*
:ERR2F   ASC   "No disk in drive"
         DB    $0
*
:INROOT  ASC   "Already in root directory"
         DB    $0
*
:NOTSUB  ASC   "Not a subdirectory"
         DB    $0
*
:MTSUB   ASC   "Empty subdirectory"
         DB    $0
*
:TOOLONG DB    $8D,$8D
:TOOLNG0 ASC   "Prefix too long"
         DB    $8D,$0
*
*
:COPY    ASC   "Copy"
         DB    $0
:CATALOG ASC   "Catalog Disk"
         DB    $0
:DELETE  ASC   "Delete"
         DB    $0
:LOCK    ASC   "Lock/Unlock Files"
         DB    $0
:RENAME  ASC   "Rename"
         DB    $0
:ALPHA   ASC   "Alphabetize Catalog"
         DB    $0
:FORMAT  ASC   "Format Disk"
         DB    $0
:VERIFY  ASC   "Verify"
         DB    $0
:VIEW    ASC   "View Files"
         DB    $0
:TSMAP   ASC   "Disk Map"
         DB    $0
:NEWBOOT ASC   "Change Boot Program"
         DB    $0
:UNDEL   ASC   "Undelete Files"
         DB    $0
:MKDIR   ASC   "Create Subdirectory"
         DB    $0
:NEWINFO ASC   "Set Printer Slot"
         DB    $0
:QUIT    ASC   "Quit"
         DB    $0
*
:FILES   ASC   "Files"
         DB    $0
:DISK    ASC   "Disk"
         DB    $0
:DSKWFMT ASC   "Disk w/ Format"
         DB    $0
:DOS ASC   "DOS"
         DB    $0
*
:VOLUME  ASC   "Volume"
         DB    $0
:DOS33   ASC   "DOS 3.3"
         DB    $0
:PRODOS  ASC   "ProDOS"
         DB    $0
*
:NORMAL  ASC   "Normal"
         DB    $0
:WLENGTH ASC   "W/ File Lengths"
         DB    $0
:WDELETE ASC   "W/ Deleted Files"
         DB    $0
:WHIDDEN ASC   "W/ Hidden Chars"
         DB    $0
*
:SPEED   ASC   "Drive Speed"
         DB    $0
*
:VALUES  ASC   "Values"
         DB    $0
:TEXT    ASC   "Text"
         DB    $0
*
*
:BLANK4  DB    $2F,$8D
:BLANK3  DB    $2F,$8D,$2F,$8D,$2F
         DB    $0
:CPYENT
         ASC   "Enter filename (,opt. filetypes)"
         DB    $8D
         ASC   "? "
         DB    $0
:SLOT    ASC   "Slot "
         DB    $0
:FILE    ASC   "File"
         DB    $0
:PSTATE0
         ASC   "[Return]-Mark File, [D]elete, [E]nter"
         DB    $8D
         ASC   "Filename, Number-Insert, [G]o,"
         DB    $8D
         ASC   "[ESC]-EXIT"
         DB    $0
:PSTATE1
         ASC   "[Return]-Toggle marker, [E]nter"
         DB    $8D
         ASC   "Filename, [G]o, [Esc]-Exit"
         DB    $0
:PSTATE2
         ASC   "[Return]-Toggle Asterisk, [E]nter"
         DB    $8D
         ASC   " Filename, [G]o, [ESC]-Exit"
         DB    $0
:PSTATE3
         ASC   "[Return]-Select to rename, [E]nter"
         DB    $8D
         ASC   "Filename, [G]o, [ESC]-Exit"
         DB    $8D
         ASC   "(Renamed files are marked)"
         DB    $0
:PSTAT45
         ASC   "[G]o, [E]nter Filename, [Esc] to exit"
         DB    $0
:TRACK   ASC   "Track $"
         DB    $0
:SECTOR  ASC   "Sector $"
         DB    $0
:CRESC1  DB    $8D
:CRESC   ASC   "[Return]-Continue, [Esc]-Exit "
         DB    $0
:NOFILES DB    $8D
         ASC   "No files"
         DB    $8D
:INIT    DB    $0
:IO      ASC   "I/O"
         DB    $0
:ERROR   ASC   "Error"
         DB    $0
:SPACE   DB    $8D
         ASC   "[Space]-Next File "
         DB    $0
:QUITOPT DB    $8D,$8D
         ASC   " Press [Esc] to re-enter utilities"
         DB    $8D,$8D
         ASC   " Press [Q] to quit to ProDOS"
         DB    $8D,$8D
         ASC   " Press [Reset] to reboot"
         DB    $0
*
*
:HEADER
         ASC   "           Copy ][ Plus  8.5"
         DB    $8D
         ASC   "(C) 1982-9 Central Point Software, Inc."
         DB    $8D
:DASHES  ASC   "----------------------------------------"
         DB    $0
:DRIVE   ASC   "Drive "
         DB    $0
:READ    ASC   "Read"
         DB    $0
:WRITE   ASC   "Write"
         DB    $0
:PRESS   DB    $8D
:PRESS1  ASC   "Press [Return] "
         DB    $0
:MORE    ASC   "----------------- MORE -----------------"
         DB    $0
*
:MSG55   ASC   "Use arrow keys"
         DB    $2F,$8D
         ASC   "& [Return] to"
         DB    $2F,$8D
         ASC   "select function"
         DB    $2F,$8D,0
*
:MSG56   DB    $2F,$8D,$2F,$8D
         ASC   "Select option:"
         DB    $2F,$8D,0
*
:MSG57   ASC   "Insert source disk"
         DB    $8D,$0
*
:MSG58   ASC   "Insert target disk"
         DB    $8D,$0
*
:MSG59   ASC   "   NAME           TYPE  BLKS  MODIFIED"
         DB    $0
*
:MSG5A   ASC   "         CREATED          ENDFILE SUBTYPE"
         DB    $0
*
:MSG5B   ASC   "Can't find file: "
         DB    $0
*
:MSG5C   ASC   "Copy same onto another disk (Y/N) ? "
         DB    $0
*
:MSG5D   DB    $8D,$8D
         ASC   "Target file name: "
         DB    $0
*
:MSG5E   DB    $8D,$8D
         ASC   "Device size mismatch"
         DB    $8D,$8D,$0
*
:MSG5F   DB    $8D,$8D,$8D
         ASC   "Insert disks"
         DB    $8D,$8D,$0
*
:MSG60   DB    $8D,$8D
         ASC   "Duplicate volume online"
         DB    $8D,$0
*
:MSG61   DB    $0
*
:MSG62   DB    $8D,$8D
         ASC   "Insert disk to format"
         DB    $8D,$8D,$0
*
:MSG63   ASC   "Ready to format (Y/N) ? "
         DB    $0
*
:MSG64   DB    $8D,$8D,$8D
         ASC   "  Formatting disk"
         DB    $8D,$8D,$0
*
:MSG65   DB    $8D,$8D
         ASC   "Formatting complete"
         DB    $8D,$0
*
:MSG66   DB    $8D,$8D
         ASC   "Subdirectory created"
         DB    $8D,$0
*
:MSG67   DB    $8D
         ASC   "[L]ock or [U]nlock? "
         DB    $0
*
:MSG68   DB    $8D,$8D,$8D
         ASC   "Insert a blank disk in "
         DB    $0
*
:MSG69   DB    $8D,$8D,$8D
         ASC   "Drive speed should be between 198.0 ms."
         DB    $8D
         ASC   "and 202.0 ms."
         DB    $8D,$8D
         ASC   "Drive speed is       ms."
         DB    $8D,$8D
         ASC   "([Esc]-Exit)"
         DB    $0
*
:MSG6A
         ASC   "   TRACK           1               2"
         DB    $8D
         ASC   "   0123456789ABCDEF0123456789ABCDEF012"
         DB    $8D,$8D
         ASC   "S"
         DB    $8D
         ASC   "E"
         DB    $8D
         ASC   "C"
         DB    $8D
         ASC   "T"
         DB    $8D
         ASC   "O"
         DB    $8D
         ASC   "R"
         DB    $0
*
:MSG6B   ASC   "   Use arrow keys to map other files  "
         DB    $0
*
:MSG6C   DB    $8D,$8D,$8D,$8D
         ASC   "No boot program to change"
         DB    $0
*
:MSG6D   DB    $8D,$8D,$8D
         ASC   "Disk II function only"
         DB    $8D,$0
*
:MSG6E   DB    $8D,$8D,$8D
         ASC   "Not a ProDOS function"
         DB    $8D,$0
*
:MSG6F   DB    $8D,$8D,$8D
         ASC   "Not a DOS 3.3 function"
         DB    $8D,$0
*
