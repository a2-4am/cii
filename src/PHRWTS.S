            TYP   BIN
            DSK   ../build/PHRWTS.O
            PUT   VARS
            ORG   PHRWTSADR
PHRWTSLIB
* ******** PHIL'S RWTS ***********
* PHRWTS - RWTS main entry point *
* FAKTRK - set RWTS track #      *
* UNTPFX - set prefix to unit    *
**********************************
PHRWTS      >>>   JMPMODULE,DECOMPRESS;_PHRWTS
FAKTRK      >>>   JMPMODULE,DECOMPRESS;_FAKTRK
UNTPFX      >>>   JMPMODULE,DECOMPRESS;_UNTPFX
DECOMPRESS  EQU   *
            ORG   *+3
            RTS

*
* [4am] Lots of timing-critical disk code in here,
* so there are tons of assembler directives to
* ensure that specific loops do not cross a page
* boundary (because branching across a page boundary
* adds 1 cycle). This module always starts on a page
* boundary close to CODEADR, so there shouldn't be
* too much churn even if you need to move other code
* in memory. But if any of the directives ever trip,
* do not ignore them! You will regret this!

*
* Time out from code for some LOCAL LABELS
*
            DUM   $80         ;zero page stuff
:PTR        DB    0,0,0,0
:TEMPZP     DB    0
:SLOTZP     DB    0
:ADRCNT     DB    0
:ODD        DB    0
:RPOINT     DB    0           ;2
:TEMP1      DB    0
:TEMP2      DB    0
:TEMP3      DB    0
:RUNNING    DB    0
:RECALS     DB    0
:SEEKS      DB    0
:TRIES      DB    0
            DEND
*
* This is a fake address, never used.
* :READ62 self-modifies the high byte
* of all instances of it to the desired
* target address.
*
            DUM   $FD00
:DEST       DB    0
            DEND
*
* These tables are now built dynamically on startup.
* Labels are defined in VARS
*
* READ 62 TRANSLATE TABLE, ORG=xx96
*
*            ERR   {*&$FF}-$96
*RDTR62      DB    $00,$04
*            DB    $FF,$FF,$08,$0C,$FF,$10,$14,$18
*            DB    $FF,$FF,$FF,$FF,$FF,$FF,$1C,$20
*            DB    $FF,$FF,$FF,$24,$28,$2C,$30,$34
*            DB    $FF,$FF,$38,$3C,$40,$44,$48,$4C
*            DB    $FF,$50,$54,$58,$5C,$60,$64,$68
*WAITBL2     DB    $70,$2C,$26,$22,$1F,$1E,$1D,$1C
*            DB    $FF,$FF,$FF,$6C,$FF,$70,$74,$78
*            DB    $FF,$FF,$FF,$7C,$FF,$FF,$80,$84
*            DB    $FF,$88,$8C,$90,$94,$98,$9C,$A0
*            DB    $FF,$FF,$FF,$FF,$FF,$A4,$A8,$AC
*            DB    $FF,$B0,$B4,$B8,$BC,$C0,$C4,$C8
*            DB    $FF,$FF,$CC,$D0,$D4,$D8,$DC,$E0
*            DB    $FF,$E4,$E8,$EC,$F0,$F4,$F8,$FC
*
*]SPOT       =     *
*MIX1ST      DB    0,2,1,3
*            DB    0,2,1,3
*            DB    0,2,1,3
*            DB    0,2,1,3
*            DB    0,2,1,3
*            DB    0,2,1,3
*            DB    0,2,1,3
*            DB    0,2,1,3
*            DB    0,2,1,3
*            DB    0,2,1,3
*            DB    0,2,1,3
*            DB    0,2,1,3
*            DB    0,2,1,3
*            DB    0,2,1,3
*            DB    0,2,1,3
*            DB    0,2,1,3
*            ERR   {*&$FF00}-{]SPOT&$FF00}
*
*]SPOT       =     *
*MIX2ND      DB    0,0,0,0,2,2,2,2,1,1,1,1,3,3,3,3
*            DB    0,0,0,0,2,2,2,2,1,1,1,1,3,3,3,3
*            DB    0,0,0,0,2,2,2,2,1,1,1,1,3,3,3,3
*            DB    0,0,0,0,2,2,2,2,1,1,1,1,3,3,3,3
*            ERR   {*&$FF00}-{]SPOT&$FF00}
*
*]SPOT       =     *
*MIX3RD      DS    16,0
*            DS    16,2
*            DS    16,1
*            DS    16,3
*            ERR   {*&$FF00}-{]SPOT&$FF00}
*
* WRITE TRANSLATE
*
*            ERR   {*&$FF}-$C0
*WRTRANS     DB    $96,$97,$9A,$9B,$9D,$9E,$9F,$A6
*            DB    $A7,$AB,$AC,$AD,$AE,$AF,$B2,$B3
*            DB    $B4,$B5,$B6,$B7,$B9,$BA,$BB,$BC
*            DB    $BD,$BE,$BF,$CB,$CD,$CE,$CF,$D3
*            DB    $D6,$D7,$D9,$DA,$DB,$DC,$DD,$DE
*            DB    $DF,$E5,$E6,$E7,$E9,$EA,$EB,$EC
*            DB    $ED,$EE,$EF,$F2,$F3,$F4,$F5,$F6
*            DB    $F7,$F9,$FA,$FB,$FC,$FD,$FE,$FF
*
*
*
* ***** READ & POST-NIBBLIZE DATA *****
* 16 SECTOR ONLY, DATA BUFFER MUST BE
* ON PAGE BOUNDARY.
*  PASS IN XREG=SLOT*16
*          YREG=PAGE # OF DATA BUFFER
*
* MODIFY-POKE THE DATA BUFFER ADDRESS
*
:READ62     STY   :RDPRM3B+2
            STY   :RDPRM3C+2
            DEY
            STY   :RDPRIM1+2
            STY   :RDPRM2B+2
*
* MODIFY-POKE DEVICE SELECT ADDRESSES
*
            TXA
            ORA   #$8C
            STA   :RDSEC2+1
            STA   :RDSEC2A+1
            STA   :RDPRM1A+1
            STA   :RDPRIM2+1
            STA   :RDPRM2A+1
            STA   :RDPRM3A+1
*
*
* READ DATA PROLOG
*
:RD62A      LDY   #$20        ;INIT ERROR count.
:RDDPRO     DEY               ;Too many?
            BNE   :RDDPRO1    ;->Not yet.
            JMP   :BADDTA     ;->Yep.
:RDDPRO1    LDA   $C08C,X     ;READ 1ST BYTE
            BPL   :RDDPRO1
:CKDPRO1    EOR   #$D5        ;MATCH WITH
            BNE   :RDDPRO     ;PROLOG1?
            NOP
:RDDPRO2    LDA   $C08C,X     ;READ 2ND BYTE
            BPL   :RDDPRO2
            CMP   #$AA        ;MATCH WITH
            BNE   :CKDPRO1    ;PROLOG2?
            NOP
:RDDPRO3    LDA   $C08C,X     ;READ 3RD BYTE
            BPL   :RDDPRO3
            CMP   #$AD        ;MATCH WITH
            BNE   :CKDPRO1    ;PROLOG3?
*
* READ SECONDARY BUFFER
*
            LDY   #$AB
            LDA   #0          ;CKSEED
]SPOT       =     *
:RDSEC2     LDX   $C0EC       ;GET BYTE
            BPL   :RDSEC2
            EOR   RDTR62-$96,X  ;TRANSLATE,XOR
            TAX
            LSR
            LSR
            STA   PRIM-1,Y    ;& SAVE
            TXA
            INY
            BNE   :RDSEC2
:RDSEC2A    LDX   $C0EC
            BPL   :RDSEC2A
            EOR   RDTR62-$96,X
            TAX
            LSR
            LSR
            STA   PRIM+$FF
            TXA
*
* READ 1ST THIRD OF PRIMARY
*
            LDY   #$AA
            BNE   :RDPRM1A    ;(ALWAYS)
:RDPRIM1    STA   :DEST-$AB,Y  ;SAVE BYTE
:RDPRM1A    LDX   $C0EC       ;GET BYTE
            BPL   :RDPRM1A
            EOR   RDTR62-$96,X  ;TRANSLATE&EOR
            LDX   PRIM,Y      ;GET 2ND BYTE
            AND   #$FC
            ORA   MIX1ST,X    ;MIX IN 2 BITS
            INY
            BNE   :RDPRIM1
            PHA
*
* READ 2ND THIRD OF PRIMARY
*
            LDY   #$AA
:RDPRIM2    LDX   $C0EC       ;GET BYTE
            BPL   :RDPRIM2
            EOR   RDTR62-$96,X  ;TRANSLATE&EOR
            LDX   PRIM,Y      ;GET 2ND BYTE
            AND   #$FC
            ORA   MIX2ND,X    ;MIX IN 2 BITS
:RDPRM2B    STA   :DEST-$54,Y  ;SAVE BYTE
            INY
            BNE   :RDPRIM2
:RDPRM2A    LDX   $C0EC
            BPL   :RDPRM2A
*
* READ 3RD THIRD OF PRIMARY
*
            LDY   #$AC
:RDPRIM3    EOR   RDTR62-$96,X  ;TRANSLATE&EOR
            LDX   PRIM-2,Y    ;GET 2ND BYTE
            AND   #$FC
            ORA   MIX3RD,X    ;MIX IN 2 BITS
:RDPRM3B    STA   :DEST,Y     ;SAVE BYTE
:RDPRM3A    LDX   $C0EC       ;GET BYTE
            BPL   :RDPRM3A
            INY
            BNE   :RDPRIM3
            AND   #$FC
            EOR   RDTR62-$96,X
            TAY               ;SAVE CKSM
            PLA
:RDPRM3C    STA   :DEST+$55
*
*
:RDDEPI     LDX   :SLOTZP
:RDDELP     LDA   $C08C,X     ;GET BYTE
            BPL   :RDDELP
            CMP   #$DE
            BNE   :BADDTA
            CPY   #0
            BNE   :BADDTA     ;BAD CKSM
:RDDEP2     LDA   $C08C,X
            BPL   :RDDEP2
            ERR   {*&$FF00}-{]SPOT&$FF00}
            CMP   #$AA
            CLC
            BEQ   :GOODAT
:BADDTA     LDA   #$27
            SEC
:GOODAT     RTS
*
*
_PHRWTS     EQU   *
            PHP
            SEI
            JSR   :RWTS
            BCC   :RWTSC
            PLP
            SEC
            RTS
:RWTSC      PLP
            CLC
            RTS
*
* WRITE BYTE(S) ROUTINE:
*
:WRITWO     PHA
            LSR
            ORA   #$AA
            STA   $C08D,X
            CMP   $C08C,X
            PLA
            ORA   #$AA
            NOP
            NOP
            NOP
:WRITE11    NOP
:WRITE9     NOP
:WRITE7     NOP
            NOP
:WRITE3     CMP   $00
:WRITE0     STA   $C08D,X
            CMP   $C08C,X
            RTS
:SLOTABS    DB    $0
*
*
* ********** WRITE TRACK ************
*
:ANRTS      RTS
*
* CHECK WRITE PROTECT
*
:WRTRAK     LDA   $C08D,X
            LDA   $C08E,X
            ASL               ;WP INTO CARRY
            LDA   #$2B        ;(WP ERROR)
            BCS   :ANRTS
            LDY   #$00        ;INIT SYNC CTR
            STY   :SECTOR     ;& SECTOR #
            STY   :PTR        ;& BUFFER PTR.
            LDA   RTRACK
            STA   :TRACK
*
* WRITE MODE
*
            LDA   #$FF
            STA   $C08F,X
            ORA   $C08C,X
            PHA
            PLA
            NOP
            NOP
*
* WRITE SYNC BYTES
*
]SPOT       =     *
:TRAKLP     NOP
            CMP   $00
            JSR   :WRITE9
            DEY
            BNE   :TRAKLP
            ERR   {*&$FF00}-{]SPOT&$FF00}
*
* WRITE A SYNC BYTE WHILE CALCULATING
* ADDR CHECKSUM
*
            JSR   :ANRTS
            JSR   :WRITE3
            LDA   ADRVOL
            EOR   :TRACK
            EOR   :SECTOR
            PHA               ;PUSH CKSM
            NOP
*
*
* WRITE ADDRESS PROLOG
*
            LDA   #$D5
            JSR   :WRITE0
            LDA   #$AA
            JSR   :WRITE9
            LDA   #$96
            JSR   :WRITE9
*
* ENCODE & WRITE 4-AND-4 SECTOR INFO
*
            LDA   ADRVOL
            JSR   :WRITWO
            LDA   :TRACK
            JSR   :WRITWO
            LDA   :SECTOR
            JSR   :WRITWO
            PLA               ;CKSM
            JSR   :WRITWO
*
* WRITE ADDRESS EPILOG
*
            LDA   #$DE
            JSR   :WRITE9
            LDA   #$AA
            JSR   :WRITE9
            LDA   #$EB
            JSR   :WRITE9
            JSR   :ANRTS
            CMP   $00
            LDA   #$FF
            STA   $C08D,X
            CMP   $C08C,X
*
* PASS PAGE # OF PRIMARY/SECONDARY
* BUFFERS & GO WRITE DATA FIELD
*
            LDA   :SECTOR
            ASL
            ADC   #>TRKBUF
            JSR   :WRDATA2
*
* ADVANCE TO NEXT SECTOR & LOOP
*
            INC   :SECTOR     ;NEXT SECTOR
            LDA   :SECTOR
            CMP   #$10        ;ALL DONE?
            NOP
            NOP               ;(IN CARRY)
            PHA
            PLA
            LDA   #$FF
            STA   $C08D,X     ;WRITE A SYNC
            ORA   $C08C,X
]SPOT       =     *
            BCS   :TRAKQ      ;QUIT IF DONE
            LDY   ASYNC       ;ELSE GET # OF
            NOP               ;SYNC
            JMP   :TRAKLP     ;BACK FOR MORE
*
:TRAKQ      LDA   $C08E,X     ;LEAVE WRITE
            LDA   $C08C,X     ;MODE
            LDA   ASYNC
            SEC
            SBC   #$04
            TAY
:WAITSNC    JSR   :ANRTS      ;WAIT FOR MOST
            JSR   :ANRTS      ;OF SYNC TO GO
            CMP   $00         ;BY...
            DEY
            BNE   :WAITSNC
            ERR   {*&$FF00}-{]SPOT&$FF00}
            JSR   RDADDR      ;LOOK FOR
            BCS   :WRTRKX     ;SECTOR 0
            LDA   ADRSEC      ;1ST
            BNE   :WRTRKX
            JMP   :VERTRK     ;VERIFY TRACK
:WRTRKX     LDA   #$27        ;(I/O ERROR)
            SEC
            RTS
:TRACK      DB    $0
:SECTOR     DB    $0
*
*
* *********** WRITE DATA ************
*
:WRDATA     SEC
            LDA   $C08D,X     ;CHECK WRITE-
            LDA   $C08E,X     ;PROTECT
            BMI   :WRDATAQ
            LDA   #$FF
            STA   $C08F,X     ;WRITE MODE
            ORA   $C08C,X
            NOP
            NOP
            NOP
            LDA   #>PRIM      ;PASS BUF PAGE
            JSR   :WRDATA2    ;WRITE DATA
            CLC               ;NO ERRORS
:WRDATAQ    LDA   $C08E,X     ;LEAVE WRITE
            LDA   $C08C,X     ;MODE
            RTS
*
* **** WRITE DATA (CORE ROUTINE) ****
* ASSUMES ALREADY IN WRITE MODE -
* TIMING CRITICAL ENTRY
*
* PASS PRIMARY PAGE # IN ACC,
* SECONDARY IS FOLLOWING PAGE.
* STAY IN SYNC WHILE DOING MODIFY-
* POKES FOR WRITING DATA
*
:WRDATA2    STA   :WRPRIM+2   ;POKE PRIMARY
            STA   :PPRIM+2
            STA   :WR2ND+2
            PHA               ;(WAIT!..)
            LDA   #$FF
            STA   $C08D,X     ;WRITE SYNC
            ORA   $C08C,X
            PLA               ;(...OKAY)
            CLC
            ADC   #$01
            STA   :LP2ND+2    ;POKE SECOND
            STA   :GET2ND+2
:GET2ND     LDA   SECOND      ;<-
            STA   :TEMPZP
            LDA   #$FF
            JSR   :WRITE0
            NOP
            NOP
*
* WRITE SYNC
*
            LDY   DSYNC       ;HOW MANY SYNC
]SPOT       =     *
:WRDSNC     NOP
            JSR   :WRITE9     ;WRITE SYNC
            CMP   $00
            DEY
            BNE   :WRDSNC
            ERR   {*&$FF00}-{]SPOT&$FF00}
*
* WRITE PROLOG
*
            CMP   $00
            LDA   #$D5
            JSR   :WRITE7
            LDA   #$AA
            JSR   :WRITE9
            LDA   #$AD
            JSR   :WRITE9
*
* WRITE SECONDARY BUFFER
*
            TYA
            LDY   #$56
]SPOT       =     *
            BNE   :WR2ND
*
:LP2ND      LDA   SECOND,Y    ;<-
:WR2ND      EOR   SECOND-1,Y  ;<-
            TAX
            LDA   WRTRANS,X
            LDX   :SLOTZP
            STA   $C08D,X
            LDA   $C08C,X
            DEY
            BNE   :LP2ND
*
* WRITE PRIMARY BUFFER
*
            LDA   :TEMPZP
            NOP
:WRPRIM     EOR   PRIM,Y      ;<-
            TAX
            LDA   WRTRANS,X
            LDX   :SLOTABS
            STA   $C08D,X
            LDA   $C08C,X
:PPRIM      LDA   PRIM,Y      ;<-
            INY
            BNE   :WRPRIM
            ERR   {*&$FF00}-{]SPOT&$FF00}
*
* WRITE CHECKSUM
*
            TAY
            LDA   WRTRANS,Y
            JSR   :WRITE3
*
* WRITE DATA EPILOG
*
            LDA   #$DE
            JSR   :WRITE9
            LDA   #$AA
            JSR   :WRITE9
            LDA   #$EB
            CMP   $00
            JMP   :WRITE9     ;MUST BE JMP, NOT JSR!
*
* ********* READ ADDRESS ***********
*
* READ PROLOG
*
RDADDR      EQU   *
            LDY   #$FC        ;INIT ERROR
            STY   :ADRCNT     ;COUNT (772)
:RDADPRO    INY
            BNE   :RDAPRO1    ;COUNT ERRORS
            INC   :ADRCNT
            BEQ   :BADADR     ;TOO MANY?
:RDAPRO1    LDA   $C08C,X     ;READ 1ST BYTE
            BPL   :RDAPRO1
:CKAPRO1    CMP   #$D5        ;MATCH WITH
            BNE   :RDADPRO    ;PROLOG1?
            NOP
:RDAPRO2    LDA   $C08C,X     ;READ 2ND BYTE
            BPL   :RDAPRO2
            CMP   #$AA        ;MATCH WITH
            BNE   :CKAPRO1    ;PROLOG2?
            NOP
:RDAPRO3    LDA   $C08C,X     ;READ 3RD BYTE
            BPL   :RDAPRO3
            CMP   #$96        ;MATCH WITH
            BNE   :CKAPRO1    ;PROLOG3?
*
* READ ADDRESS INFO
*
            LDY   #$03
            LDA   #$00        ;INIT CHKSUM
:RDAINFO    STA   :TEMPZP
:RDODD      LDA   $C08C,X     ;READ ODD BITS
            BPL   :RDODD
            ROL               ;SHIFT TO ODD
            STA   :ODD        ;& SET ASIDE.
:RDEVEN     LDA   $C08C,X     ;READ EVEN
            BPL   :RDEVEN
            AND   :ODD        ;MIX IN ODD
            STA   AINFO,Y     ;SAVE IN TABLE
            EOR   :TEMPZP
            DEY               ;NEXT..
            BPL   :RDAINFO
*
* CHECK CHECKSUM
*
            TAY
            JMP   :RDDELP
*
:BADADR     SEC
            RTS
*
:RUNL       DB    $0
:RUNH       DB    $0
*
:CURRTRK    DB    $00
:WANTRK     DB    $00
:SPEED      DB    $00
:LASTRK     DB    $00
*
*
*
* INIT SOFAR ARRAY FOR NO SECTORS
* READ SO FAR
*
:INITFAR    LDY   #$0F        ;ZERO OUT 16
            LDA   #$00        ;ITEMS
:INITF2     STA   SOFAR,Y
            DEY
            BPL   :INITF2
:INITFQ     RTS
*
*
*
* ********** VERIFY TRACK ***********
*
* (WILL NOT RESEEK OR RECAL)
*
* NEED SET-UP FOR MOTOR-ON&SET-TRACK,
* SET UP BUFFERS FOR READ, ERROR
* HANDLING FOR VERIFY OR FOR COPY
*
:VERBAD     JMP   :BADDTA
:VERTRK     JSR   :INITFAR    ;NO SECTORS
            LDA   #$60        ;READ SO FAR
            STA   :TRIES
:VERTRK4    DEC   :TRIES      ;TRY (AGAIN).
            BMI   :VERBAD     ;TOO LATE...
:VERTRK7    LDX   HSLOT
            JSR   RDADDR      ;READ ADDRESS
            BCS   :VERTRK4
            LDA   ADRTRK      ;RIGHT TRACK?
            EOR   RTRACK
*            AND   TRKFLG
            BNE   :VERTRK4
            LDY   ADRSEC      ;HAVE WE READ
            LDA   SOFAR,Y     ;THIS SECTOR
            BMI   :VERTRK4    ;ALREADY?
            LDY   #>TRKBUF
            JSR   :READ62     ;CORRECT SIZE
:VERTRK9    BCS   :VERTRK4
            LDY   ADRSEC      ;IF GOOD:
            LDA   #$FF        ;MARK SECTOR
            STA   SOFAR,Y     ;AS READ.
            LDY   #$0F
:VERALL     AND   SOFAR,Y     ;ANY SECTORS
            DEY               ;LEFT TO READ?
            BPL   :VERALL
            TAY               ;(TEST ACC)
            BEQ   :VERTRK4    ;YES, GO BACK.
            CLC
            RTS
*
*
*
*********** READ TRACK ************
*
:READTRK    JSR   :INITFAR    ;NO SECTORS
            LDA   #$01        ;READ SO FAR
            STA   :RECALS
:RDTRK2     LDA   #$60
            STA   :TRIES
            LDA   #$04
            STA   :SEEKS
:RDTRK4     DEC   :TRIES      ;TRY (AGAIN).
            BPL   :RDTRK7
:RDTRK5     DEC   :RECALS
            BMI   :VERBAD
            JSR   :RECAL
            JMP   :RDTRK2
*
:RDTRK6     DEC   :SEEKS
            BMI   :RDTRK5
            JSR   :RESEEK
:RDTRK7     LDX   HSLOT
            JSR   RDADDR      ;READ ADDRESS
            BCS   :RDTRK4
            LDA   ADRTRK      ;RIGHT TRACK?
            EOR   RTRACK
*            AND   TRKFLG
            BNE   :RDTRK4
            LDY   ADRSEC      ;HAVE WE READ
            LDA   SOFAR,Y     ;THIS SECTOR
            BMI   :RDTRK4     ;ALREADY?
            CLC               ;NO:FIND PAGE
            TYA               ;NUM FOR THIS
            ADC   RPAGE       ;SECTOR.
            TAY               ;(PASS PAGE #)
            JSR   :READ62     ;READ 6&2.
            BCS   :RDTRK4
:RDTRK9     LDY   ADRSEC      ;IF GOOD:
            LDA   #$FF        ;MARK SECTOR
            STA   SOFAR,Y     ;AS READ.
            LDY   #$0F
:RDALL      AND   SOFAR,Y     ;ANY SECTORS
            DEY               ;LEFT TO READ?
            BPL   :RDALL
            TAY               ;(TEST ACC)
            BEQ   :RDTRK4     ;YES, GO BACK.
            CLC
            RTS
*
*
:RESEEK     LDA   ADRTRK      ;SAY YOU'RE ON
            ASL               ;TRACK THE ADR
            JSR   _FAKTRK     ;FIELD THINKS,
            LDA   RTRACK      ;THEN SEEK TO
*
* FALL INTO SEEK
*
*
* ********* SEEK TO TRACK ***********
*
* PASS IN ACC=DESIRED TRACK
*
:SEEK       ASL               ;MAKE 1/2TRK
            PHA
            JSR   :ALLOFF     ;PHASES OFF
            JSR   :DRINDEX    ;GET DRIVE IDX
            LDA   $478,X      ;GET CURRENT
            STA   :CURRTRK    ;1/2TRK
            PLA
            STA   $478,X      ;SAVE NEW
            JSR   :STEPTO     ;STEP TO IT
:ALLOFF     CLC
            LDY   #$03        ;TURN ALL
:OFFLP      TYA               ;PHASES OFF.
            JSR   :KICKPH
            DEY
            BPL   :OFFLP
            RTS
*
* STEP TO TRACK
*
:STEPTO     STA   :WANTRK     ;SAVE WANTED.
            CMP   :CURRTRK    ;ALREADY THERE?
            BEQ   :KICKCUR    ;GO TICKLE IT.
            LDA   #$00
            STA   :SPEED      ;START SLOW...
:STEPLP     LDA   :CURRTRK    ;SAVE WHERE WE
            STA   :LASTRK     ;BEEN.
            SEC
            SBC   :WANTRK     ;HOW FAR TO GO?
            BEQ   :STEPQ      ;ZIP-OFF&QUIT.
            BCS   :STEPDN     ;DOWN...
            EOR   #$FF        ;UP:ABS VAL
            INC   :CURRTRK    ;MOVE CURR UP.
            BCC   :GRADUAL    ;(ALWAYS)
*
:STEPDN     ADC   #$FE
            DEC   :CURRTRK    ;MOVE CURR DOWN
:GRADUAL    CMP   :SPEED      ;DISTANCE >
            BCC   :SLOW       ; SPEED?
            LDA   :SPEED      ;TAKE SMALLER
:SLOW       CMP   #$08        ;& NO BIGGER
            BCS   :KICKON     ;THAN 8.
            TAY
            SEC
:KICKON     JSR   :KICKCUR    ;KICK NEW ON
            LDA   WAITBL1,Y   ;WAIT A BIT
            JSR   :DELAY
            LDA   :LASTRK
            CLC
            JSR   :KICKPH     ;KICK OLD OFF
            LDA   WAITBL2,Y   ;WAIT A BIT
            JSR   :DELAY
            INC   :SPEED      ;TRY FASTER!
            BNE   :STEPLP     ;(ALWAYS)
*
:STEPQ
            LDA   #100
            JSR   :DELAY
            CLC
            JSR   :KICKCUR
            LDA   #0
            JMP   :DELAY
*
:KICKCUR    LDA   :CURRTRK    ;KICK NEW OFF
:KICKPH     AND   #$03        ;PHASE NUMBER
            ROL               ;ON OR OFF
            ORA   HSLOT
            TAX
            LDA   $C080,X     ;KICK IT!
            LDX   HSLOT
            RTS
*
*
********************************
*
* **** WAIT FOR OLD DRIVE TO STOP ****
*
:WAITOLD    EOR   RPSLOT      ;EXIT IF SAME
            BEQ   :OLDQ       ;SLOT.
            LDA   #$E8        ;NO:SET
            STA   :COUNTH     ; COUNTER
:OLDLP      LDX   RPSLOT      ;GET OLD SLOT
            BEQ   :OLDQ       ;OLD SLOT = 0
            JSR   :RUNTST2    ;IS IT RUNNING?
            BEQ   :OLDQ       ;NO: EXIT.
            LDA   #$01        ;YES:WAIT A
            JSR   :DELAY      ;BIT & TRY
            LDA   :COUNTH     ;AGAIN UNTIL
            BNE   :OLDLP      ;VERY BORED.
:OLDQ       RTS
*
********************************
*
* *** IS DRIVE RUNNING (CONNECTED)? **
*
* RETURNS: EQ -> NOT RUNNING
*          NE -> RUNNING
*
:RUNTEST    LDX   HSLOT
:RUNTST2    TXA               ;SAVE SLOT
            PHA
            JSR   :DRINDEX
            LDA   $478,X      ;CURRENT HFTRK
            AND   #$03        ;CURRENT PHASE
            ASL
            ADC   HSLOT       ;GET OFFSET
            TAY
            LDA   #$FB        ;INIT COUNTUP
            STA   :RUNL
            STA   :RUNH
            PLA               ;RESTORE SLOT
            TAX
:TESTLP     LDA   $C08C,X     ;READ BYTE
            CMP   $C081,Y     ;KICK PHASE
            CMP   $C080,Y     ;ON & OFF!
            JSR   :ANRTS      ;WAIT MORE
            EOR   $C08C,X     ;CHANGED?
            BNE   :TESTQ      ;YES:EXIT
            INC   :RUNL       ;NO:TRY AGAIN
            BNE   :TESTLP
            INC   :RUNH
            BNE   :TESTLP     ;UNTIL BORED.
:TESTQ      TAY               ;SET Y:EQ-NE
            RTS
*
*
* NEED MODIFY-POKES FOR COPY DISK
* OR MOVE FROM PROPER PRIM & SECOND
* TO TRACK BUFFER FOR WRITING
*
:PRENIB     LDX   #$02
            LDY   #$00
:PRE6LP1    DEY
            LDA   (:RPOINT),Y
            LSR
            ROL   SECOND,X
            LSR
            ROL   SECOND,X
            STA   PRIM,Y
            INX
            CPX   #$56
            BCC   :PRE6LP1
            LDX   #$00
            TYA
            BNE   :PRE6LP1
            LDX   #$55
:PRE6LP2    LDA   SECOND,X
            AND   #$3F
            STA   SECOND,X
            DEX
            BPL   :PRE6LP2
            RTS
*
*
*
*
* ******* RWTS START CODE *********
*
* START CORRECT DRIVE & SEEK TO TRACK.
* EXITS NE -> DRIVE IS SPINNING
*       EQ -> SOMETHING'S WRONG
*
*
*
:START
            LDX   HSLOT
            LDA   $C08E,X     ;Change UDC mode to 5.25, in case it
            LDA   #0          ; was left in 3.5 mode.
            STA   $C08D,X     ; (shouldn't affect ordinary 5.25
            LDA   $C08C,X     ; controllers at all)
            STX   :SLOTZP     ;DIFFERENT
            STX   :SLOTABS
            CPX   RPSLOT      ;SLOT?
            BEQ   :SAMESL
            JSR   :WAITOLD    ;YES:LET IT
            LDA   HSLOT       ;TURN OFF,
            STA   RPSLOT      ;NEW->OLD.
:SAMESL     JSR   :RUNTEST    ;DRIVE SPINS?
            STY   :RUNNING
            LDX   HSLOT
            LDA   $C089,X     ;MOTOR ON.
            LDA   HDRIVE      ;DIFFERENT
            CMP   RPDRIV      ;DRIVE?
            BEQ   :SAMEDR
            STA   RPDRIV      ;YES:NEW->OLD,
            LDY   #$00        ;WRONG DRIVE
            STY   :RUNNING    ;WAS SPINNING.
:SAMEDR     CLC
            ADC   HSLOT       ;MAKE OFFSET &
            TAX
            LDA   $C089,X     ;SELECT DRIVE.
            LDA   #$E8        ;INIT DELAY CTR
            STA   :COUNTH     ;FOR .6 SEC.
            LDA   :RUNNING    ;IF DRIVE WAS
            BNE   :GOSEEK     ;NOT SPINNING:
            LDY   #$07        ;DELAY .17 SEC
:CAPWAIT    JSR   :DELAY      ;SO MOTOR CAN
            DEY               ;REALLY TURN
            BNE   :CAPWAIT    ;ON.
:GOSEEK     LDA   RTRACK      ;SEEK TO TRACK
            JSR   :SEEK
            LDA   :RUNNING    ;IF DRIVE WAS
            BNE   :STARTQ     ;NOT SPINNING:
:ACCELLP    LDA   #$01        ;DELAY UNTIL
            JSR   :DELAY      ;TOTAL DELAY
            LDA   :COUNTH     ;TIME=.6 SEC
            BMI   :ACCELLP
            JSR   :RUNTEST    ;CHECK IT.
:STARTQ     RTS
*
* ERROR HANDLING SEEK ROUTINES
*
:RECAL      LDA   RTRACK      ;SAY THAT
            PHA               ;YOU'RE ON A
            ASL               ;HIGHER TRACK,
            ADC   #$10
            JSR   _FAKTRK
            LDA   #$00        ;THEN SEEK 0
            JSR   :SEEK       ;TO RATCHET.
            PLA
            JMP   :SEEK       ;RESEEK TO TRK
*
*
*
* ******* FORMAT A TRACK **********
*
* FILL TRKBUF WITH ZEROS,
* THEN WRITE TRACK
*
:FORMAT     LDX   #$20
            LDA   #>TRKBUF
            STA   POINT+1
            LDA   #$00
            STA   POINT
            TAY
:ZIPLP      STA   (POINT),Y
            INY
            BNE   :ZIPLP
            INC   POINT+1
            DEX
            BNE   :ZIPLP
            LDA   DOSNOW
            EOR   #$FE
            STA   ADRVOL
            BNE   :GOTRAK     ;(ALWAYS)
*
* ****** WRITE (COPY) A TRACK ******
*
* PRENIBBLIZE INTO TRKBUF FROM MEMORY
* THEN WRITE TRACK
*
:COPY       LDA   RPAGE       ;RPOINT AT
            STA   :RPOINT+1   ;CURRENT PAGE
            LDA   #$00
            STA   COUNT       ;COUNT SECTORS
            STA   :RPOINT
            STA   POINT       ;POINT AT PRIM
            STA   POINT2      ;POINT2 SECOND
:PRECPLP    CLC
            ASL
            ADC   #>TRKBUF
            STA   POINT+1
            ADC   #$01
            STA   POINT2+1
:PRE1SEC    JSR   :PRENIB     ;DO PRENIB.
            LDY   #$00
:MOV2BUF    LDA   PRIM,Y      ;MOVE NIBBLIZED
            STA   (POINT),Y   ;DATE INTO
            LDA   SECOND,Y    ;TRKBUF
            STA   (POINT2),Y
            INY
            BNE   :MOV2BUF
            INC   :RPOINT+1   ;NEXT SECTOR
            INC   COUNT
            LDA   COUNT       ;GOT 'EM ALL?
            CMP   #$10
            BNE   :PRECPLP
:GOTRAK     LDX   HSLOT
            JMP   :WRTRAK
*
:OTHER      LSR               ;SELECT OTHER
            LSR               ;RWTS OPTIONS
            LSR
            BCS   :FORMAT     ;04
            LSR
            BCS   :COPY       ;08
            LSR
            BCC   :NOTVER
            JMP   :VERTRK     ;10
:NOTVER     LSR
            BCC   :RATCHET
            JMP   :READTRK    ;20
:RATCHET    CLC               ;40 NULL NOW.
            RTS
*
:RWTS       LDA   RCMND
            CMP   #$40        ;IF RATCHET:
            BNE   :GOSTART
            LDA   #$60
            JSR   _FAKTRK     ;SAY TRK 48
            LDA   #$00
            STA   RTRACK      ;SET TRK 0
:GOSTART    JSR   :START      ;START UP
*
            PHP
            LDA   #$28        ;(NO DEVICERR)
            PLP               ;DRIVE
            BNE   :ISTHERE
            LDA   RCMND
            CMP   #4          ;FORMAT COMMAND?
            BNE   :ERROR      ;NO: GIVE ERROR
*
:ISTHERE    LDA   #$00
            STA   :RPOINT
            LDA   RPAGE       ;ZP PTR AT
            STA   :RPOINT+1   ;RWTS PAGE.
            LDA   RCMND       ;GET COMMAND.
            BEQ   :GOODOUT    ;SEEK ONLY?
            CMP   #$02
            BCC   :DOSECTR    ;READ?
            BEQ   :DOWRITE    ;WRITE?
            JSR   :OTHER      ;NO:DO OTHER
            JMP   :OUT        ;THEN EXIT.
:DOWRITE    JSR   :PRENIB     ;WRITE PRENIB
:DOSECTR    LDA   #$01
            STA   :RECALS
:SETSEEK    LDA   #$04
            STA   :SEEKS
            LDY   #$30
            STY   :TRIES
:BADSEC     DEC   :TRIES      ;COUNT TRIES
            BPL   :LOOKADR    ;USED UP?
*
:DORECAL    LDA   #$27        ;(DRIVE ERROR)
            DEC   :RECALS     ;TRY 1 RECAL:
            BMI   :ERROR      ;BEEN DONE?
            JSR   :RECAL
            JMP   :SETSEEK    ;& COUNT.
*
:GOWRITE    JSR   :WRDATA     ;WRITE DATA
            LDA   #$2B        ;MAYBE WPROT?
            BCS   :ERROR      ;YES:ERROR OUT
:GOODOUT    CLC               ;EXIT NO ERROR
            LDA   #$00
            DB    $D0
:ERROR      SEC
:OUT        STA   RRTN
            LDX   HSLOT
            LDA   $C088,X     ;MOTOR OFF.
            RTS
*
:BADTRK     DEC   :SEEKS      ;COUNT SEEKS.
            BMI   :DORECAL    ;USED UP?
            JSR   :RESEEK
:LOOKADR    LDX   HSLOT
            JSR   RDADDR      ;READ ADDRESS.
            BCS   :BADSEC     ;BAD?
            LDA   ADRTRK      ;RIGHT TRACK?
            EOR   RTRACK
*            AND   TRKFLG
            BNE   :BADTRK     ;NO:RESEEK.
            LDY   RSECTR
            LDA   INTRLV,Y
:SECTCMP    CMP   ADRSEC      ;RIGHT SECTOR?
            BNE   :BADSEC
*
            LDA   RCMND       ;YES! WHAT
            CMP   #$02        ;COMMAND?
            BEQ   :GOWRITE
            LDY   RPAGE       ;PASS PAGE #
            JSR   :READ62     ;DO CORRECT
            BCS   :BADSEC     ;ROUTINE.
            BCC   :GOODOUT
*
*
*
* GENERAL PURPOSE DELAY ROUTINE
*
:DELAY      LDX   #$11
]SPOT       =     *
:DELAY2     DEX
            BNE   :DELAY2
            ERR   {*&$FF00}-{]SPOT&$FF00}
            INC   :COUNTL
            BNE   :DELAY3
            INC   :COUNTH
:DELAY3     SEC
            SBC   #$01
            BNE   :DELAY
            RTS
:COUNTL     DB    $00
:COUNTH     DB    $00
*
*
* TELL RWTS WHAT TRACK IT'S ON
*
_FAKTRK     EQU   *
            JSR   :DRINDEX
            STA   $478,X      ;STORE IN TABLE
            RTS
*
* CONVERT SLOT&DRIVE TO INDEX IN XREG
*
:DRINDEX    PHA
            LDA   HSLOT       ;0SSS0000
            LSR               ;00SSS000
            ORA   HDRIVE      ;00SSS021
            LSR               ;000SSS02->1
            LSR               ;0000SSS0->2
            ROR               ;20000SSS
            TAX
            PLA
            RTS
*
*
*
* SET PREFIX TO UNIT IN A REG
*
_UNTPFX     EQU   *
            LDA   UNIT
            STA   :UNIT
            JSR   MLI
            DB    $C5
            DW    :ONLST
            LDA   PFX+1
            AND   #$0F
            BNE   :PRODOS
:DOS33      LDA   #0
            STA   ADRVOL
            STA   PFX
            LDA   PFX+2
            CMP   #$28
            BEQ   :NOTDSK2    ;NO DRIVE
            BIT   DOSNOW
            BMI   :NOTDSK2
            LDA   HDRIVE
            CLC
            ADC   HSLOT
            TAX
            LDA   $C089,X     ;SELECT DRIVE (C08A,X or C08B,X)
            LDX   HSLOT
            LDA   $C089,X     ;MOTOR ON
            JSR   RDADDR
            LDA   $C088,X
:NOTDSK2    LDA   ADRVOL
            STA   PFX+5
            CLC
            RTS
*
:ONLST      DB    $2
:UNIT       DB    $0
            DW    PFX+1
*
:PRODOS     LDA   PFX+1
            AND   #$0F
            TAY
            INY
            STY   PFX
            LDA   #$2F        ;"/"
            STA   PFX+1
            JSR   MLI
            DB    $C6
            DW    :SPLST
            STA   RRTN
            RTS
*
:SPLST      DB    $1
            DW    PFX
*
INTRLV      EQU   *
            DB    $0,$D,$B,$9,$7,$5,$3,$1
            DB    $E,$C,$A,$8,$6,$4,$2,$F
]SPOT       =     *
WAITBL1     EQU   *
            DB    $01,$30,$28,$24,$20,$1E,$1D,$1C
            ERR   {*&$FF00}-{]SPOT&$FF00}
*
PHRWTSEND
