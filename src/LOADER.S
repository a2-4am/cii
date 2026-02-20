COPYADDR    MAC
            LDA   #]1
            STA   ]2
            LDA   #>]1
            STA   ]2+1
            <<<
UNPACK      MAC
            >>>   COPYADDR,]1;ZXSRC
            >>>   COPYADDR,]2;ZXDST
            JSR   ZXUNPACK
            <<<
MEMCPY      MAC
            JSR   DOMEMCPY
            DB    $100-{{]2-]1}&$FF}
            DB    {]2-]1+$FF}/$100
            DA    ]1-{$100-{{]2-]1}&$FF}}
            DA    ]3-{$100-{{]2-]1}&$FF}}
            <<<
*
:LOCATE     CLD
            CLI
*
* Move self-decompressing modules into place
*
            >>>   MEMCPY,MISCLIBX7BEG;MISCLIBX7END;MISCLIB
            >>>   MEMCPY,UNDELETEX7BEG;UNDELETEX7END;UNDEL
            >>>   MEMCPY,TSMAPX7BEG;TSMAPX7END;TSMAP
            >>>   MEMCPY,VERIFYX7BEG;VERIFYX7END;VERIFY
            >>>   MEMCPY,DELLIBX7BEG;DELLIBX7END;DELLIB
            >>>   MEMCPY,CATALOGX7BEG;CATALOGX7END;CATALOG
            >>>   MEMCPY,COPYX7BEG;COPYX7END;COPY
            >>>   MEMCPY,DOTREEX7BEG;DOTREEX7END;DOTREE
            >>>   MEMCPY,DODEVX7BEG;DODEVX7END;DODEV
            >>>   MEMCPY,CATLIBX7BEG;CATLIBX7END;CATLIB
            >>>   MEMCPY,RDDATAX7BEG;RDDATAX7END;RDDATA
*
* Move interleave tables, unpacker, menu dispatch table,
* and other global jump vectors into place
*
            >>>   MEMCPY,DZX0BEG;DZX0END;ZXMODULE
* Y=0 on exit from MEMCPY
            TYA               ;0
*
* CLEAR OUT PRODOS MEMORY BITMAP
*
            LDX   #$16
:CLRMAP     STA   MEMTABL,X
            STA   ACURR,X
            DEX
            BNE   :CLRMAP
* A=0, X=0, Y=0
*
* (no more minimum version at $BFFC?
* ProDOS manual says it's a reserved location)
*
            STA   PINVFL      ;0
            STA   PFX
            STA   PPFX
            STA   SPFX
            STA   APFX
*            STA   ACURR      ;handled in-loop
*            STA   PCURR      ;handled in-loop
*            STA   SCURR      ;handled in-loop
*            STA   RPSLOT      ;handled in-loop
*
* FIGURE OUT SLOT NUMBER
*
            INX               ;1 Mark the ProDOS global page as
            STX   MEMTABL+$17 ;  busy in the global page bitmap.
            LDA   DEVNUM
            STA   BOOTDV
            BPL   :ISD1
            INX               ;2
:ISD1       STX   RPDRIV
*
* PUT VERSION NUMBER AT $BFFD
*
            LDA   #CIIRVER
            STA   IVERSION
*
* BUILD OUR DEVICE LIST
*
            LDY   DEVCNT
            LDX   #$00
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
            CMP   #$2F        ;'/'
            BEQ   :GOTSLSH
            DEY
            BNE   :PFX0
*
*
* NO '/' IN NAME AT $280, SO DON'T
* CHANGE PREFIX.
*
            BEQ   :NOCHNG     ;ALWAYS
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
:NOCHNG     JSR   MLI         ;GET BOOT PFX
            DB    $C7
            DW    :BTLST
*
*
* SETUP A2E, FLAG80, ISAUX
*
* A2E:
*  0 --> NOT AN APPLE //E OR //C
* 80 --> UNENHANCED //E
* C0 --> ENHANCED //E OR //C
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
            STX   FLAG80      ;ASSUME 40 COL
            STX   A2E         ;ASSUME NOT 2E
            STX   GOTMM       ;Assume MM not available
            STX   MMISOPEN    ; & of course not open.
            LDA   $FBB3
            CMP   #$06
            BNE   :NO80COL    ;->NOT //E, so not 80 col, either.
            LDA   #$00
            DB    $1A         ;check for 65c02 using INC opcode
            BEQ   :UNENH      ;if A is still 0, 65c02 was not found
            LDA   #$C0        ;enhanced //e
            DB    $2C
:UNENH
            LDA   #$80        ;unenhanced //e
            STA   A2E
            LDY   MACHID
            TYA
            AND   #2
            BEQ   :NO80COL    ;NO 80-COL
            DEC   FLAG80      ;GOT 80-COL
:NO80COL    TYA
            AND   #$30
            CMP   #$30
            BNE   :DUNCHK     ;->NOT 128K
            INX
            LDA   :RAMFLG
            BMI   :DUNCHK     ;->/RAM ACTIVE
            LDX   #$FF
:DUNCHK     STX   ISAUX
*
* CHECK IF /RAM EXISTS, AND IF SO DOES
* IT HAVE ANY FILES
*
            CPX   #1
            BNE   :NORAM      ;NO /RAM
*
* READ /RAM DIRECTORY
*
            JSR   MLI         ;Read /RAM directory
            DB    $80
            DW    :RBLST
            BCS   :NORAM
*
* IF /RAM > $FF BLOCKS, MARK *ISAUX
* AS USEABLE
*
            LDA   #$FE        ;(Value for big RAMdisk)
            LDY   SDIR+$2A
            BNE   :DISCON     ;> $FF BLKS
            LDA   SDIR+4      ;Is this a valid ProDOS device?
            AND   #$F0
            CMP   #$F0        ; (Is this a volume key block?)
            BNE   :NORAM      ;->No: don't give it up, whatever it is.
            LDA   SDIR+$25    ;Any files on this ProDOS device?
            ORA   SDIR+$26
            BNE   :NORAM      ;->Yes: can't use auxmem.
            LDA   #$FF
*
* /RAM EXISTS AND HAS NO FILES, SO
* MARK *ISAUX AS USEABLE
*
:DISCON     STA   ISAUX
*
:NORAM      LDA   ISAUX       ;After all that, do we have usable auxmem?
            BPL   :SKIPMM     ;->Nope.
*
* Auxiliary memory is available now at startup.
* Locate Memory Manager code into safe haven in aux memory.
*
            STA   $C005       ;transfer from main to aux
            >>>   MEMCPY,MMXBEG;MMXEND;AUXMM
            STA   $C004
            DEC   GOTMM       ;Mark that we got Memory Manager.
:SKIPMM
*
* Unpack MAIN portion of program into place
*
            >>>   UNPACK,MAINXEND;MAINEND
*
            BIT   A2E
            BPL   :SKIPIRQ    ;NOT //E
            BVC   :SAVEIRQ    ;//e but unenhanced
*
* enhanced //e or later, so convert dashes to pretty MouseText dashes
*
            LDY   #$41        ;enough to cover DASHES and :MORE
:DASHLOOP
            LDA   DASHES,Y
            CMP   #"-"
            BNE   :NEXTDASH
            LDA   #$53
            STA   DASHES,Y
:NEXTDASH
            DEY
            BPL   :DASHLOOP
*
* SAVE AUXMEM IRQ VECTOR.
*
:SAVEIRQ
            LDA   $C083
            LDA   $C083
            STA   $C009       ;AUX LC
            LDA   $FFFE
            STA   IRQSAV
            LDA   $FFFF
            STA   IRQSAV+1
            STA   $C008
*
:SKIPIRQ    
            LDA   #$0A
            STA   ASYNC
            LSR               ;A-->5
            STA   DSYNC
            LDY   #$00
            STY   DOSNOW
            STY   FMT400K
*
* MOVE DOS 3.3 NO-BOOT SECTOR TO LC RAM BANK 2
* (this was part of the code we just unpacked,
* in a region we're about to reuse for the PHRWTS
* data tables)
*
* Y IS ALREADY 0
*           LDY   #0
:NBLP       LDA   BOOTBEG,Y
            CPY   #BOOTEND-BOOTBEG
            BCC   :NBLP1
            LDA   #0          ;FILL WITH 0'S FROM $A2(?) TO $FF
:NBLP1      STA   D3NOBOOT,Y
            INY
            BNE   :NBLP
            LDA   $C082
*
* Build data tables for PHRWTS
*
* Y IS ALREADY 0
*           LDY   #0
            LDX   #$16
]BLOOP1
            STX   $3C
            TXA
            ASL
            BIT   $3C
            BEQ   :BRANCH1
            ORA   $3C
            EOR   #$FF
            AND   #$7E
]BLOOP2
            BCS   :BRANCH1
            LSR
            BNE   ]BLOOP2
            TXA
            ORA   #$80
            STA   WRTRANS,Y
            TYA
            ASL
            ASL
            INY
            DB    $CD
:BRANCH1
            LDA   #$FF
            STA   RDTR62-$16,X
            INX
            BPL   ]BLOOP1
            LDX   #8
]BLOOP3
            LDA   :SEEKTBL-1,X
            STA   RDTR62+$2A-1,X
            DEX
            BNE   ]BLOOP3
]BLOOP4
            LDA   :BITTBL,X
            STA   MIX1ST-$40,Y
            INY
            TYA
:SMC        AND   #0
            BNE   ]BLOOP4
            INX
            TXA
            AND   #3
            BNE   ]BLOOP4
            TAX
            TYA
            BEQ   :BUILDERQ
            ASL
            ASL
            BNE   ]BLOOP4
            ROL
            TAX
            LDA   :MASKTBL,X
            STA   :SMC+1
            LDX   #0
            BEQ   ]BLOOP4     ; always
:BUILDERQ
*
* Set reset vector now that we have somewhere to point to.
*
            LDA   #FILER
            STA   $3F2
            LDA   #>FILER
            STA   $3F3
            EOR   #$A5
            STA   $3F4
            JMP   FILER       ;GO START
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
:RAMFLG     DB    $0
*
:SEEKTBL    DB    $70,$2C,$26,$22,$1F,$1E,$1D,$1C
:BITTBL     DB    $00,$02,$01
:MASKTBL    DB    $03,$0F
*
DOMEMCPY
            DUM   $F0
:STACK      DS    2
:PAGES      DS    1
:SRC        DS    2
:DST        DS    2
            DEND
            PLA
            STA   :STACK
            CLC
            ADC   #6
            TAY
            PLA
            STA   :STACK+1
            ADC   #0
            PHA
            TYA
            PHA
            LDY   #6
]PARMLOOP   LDA   (:STACK),Y
            STA   :STACK,Y
            DEY
            BNE   ]PARMLOOP
            TAY
]COPYLOOP   LDA   (:SRC),Y
            STA   (:DST),Y
            INY
            BNE   ]COPYLOOP
            INC   :SRC+1
            INC   :DST+1
            DEC   :PAGES
            BNE   ]COPYLOOP
* Y=0 on exit
* Z=1 on exit
            RTS
