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
* Move unpacker (and menu dispatch table) into place
*
            >>>   MEMCPY,DZX0BEG;DZX0END;ZXMODULE
*
* Move self-decompressing modules into place
*
            >>>   MEMCPY,DDISKX7BEG;DDISKX7END;DDISK
            >>>   MEMCPY,D1FILEX7BEG;D1FILEX7END;D1FILE
            >>>   MEMCPY,DOTREEX7BEG;DOTREEX7END;DOTREE
            >>>   MEMCPY,COPYX7BEG;COPYX7END;COPY
            >>>   MEMCPY,CATALOGX7BEG;CATALOGX7END;CATALOG
            >>>   MEMCPY,DELETEX7BEG;DELETEX7END;DELETE
            >>>   MEMCPY,ALPHABETIZEX7BEG;ALPHABETIZEX7END;ALPHA
            >>>   MEMCPY,FORMATX7BEG;FORMATX7END;FORMAT
            >>>   MEMCPY,VERIFYX7BEG;VERIFYX7END;VERIFY
            >>>   MEMCPY,VIEWX7BEG;VIEWX7END;VIEW
            >>>   MEMCPY,TSMAPX7BEG;TSMAPX7END;TSMAP
            >>>   MEMCPY,CHANGEBOOTX7BEG;CHANGEBOOTX7END;BOOTPG
            >>>   MEMCPY,UNDELETEX7BEG;UNDELETEX7END;UNDEL
            >>>   MEMCPY,MAKESUBX7BEG;MAKESUBX7END;MAKESUB
            >>>   MEMCPY,QUITX7BEG;QUITX7END;QUIT
*
            LDX   $FBB3       ;FOR LATER
*
* MOVE NOBOOT TO $D000
*
            LDA   $C083
            LDA   $C083
            LDY   #0
:NBLP       LDA   BOOTBEG,Y
            CPY   #BOOTEND-BOOTBEG+1
            BCC   :NBLP1
            LDA   #0          ;FILL WITH 0'S FROM $A2(?) TO $FF
:NBLP1      STA   $D000,Y
            INY
            BNE   :NBLP
*
* WHILE WE'RE IN THE LANGUAGE CARD,
* SAVE AUXMEM IRQ VECTOR.
*
            CPX   #6
            BNE   :SKIPIRQ    ;NOT //E
*
            STA   $C009       ;AUX LC
            LDA   $FFFE
            STA   IRQSAV
            LDA   $FFFF
            STA   IRQSAV+1
            STA   $C008
*
:SKIPIRQ    LDA   $C082
*
* FIGURE OUT SLOT NUMBER
*
            LDX   #1          ;Mark the ProDOS global page as
            STX   MEMTABL+$17  ; busy in the global page bitmap.
            LDA   DEVNUM
            STA   BOOTDV
            BPL   :ISD1
            INX
:ISD1       STX   RPDRIV
* AND #$70
* STA *RPSLOT
*
* CLEAR OUT PRODOS MEMORY BITMAP
*
            LDX   #$16
            TYA               ;0
:CLRMAP     STA   MEMTABL,X
            DEX
            BNE   :CLRMAP
*
* (no more minimum version at $BFFC?
* ProDOS manual says it's a reserved location)
*
            STA   PINVFL      ;0
            STA   PFX
            STA   PPFX
            STA   SPFX
            STA   APFX
            STA   ACURR
            STA   PCURR
            STA   SCURR
            STA   RPSLOT
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
            STX   FLAG80      ;ASSUME 40 COL
            STX   A2E         ;ASSUME NOT 2E
            STX   GOTMM       ;Assume MM not available
            STX   MMISOPEN    ; & of course not open.
            LDA   $FBB3
            CMP   #$06
            BNE   :NO80COL    ;->NOT //E, so not 80 col, either.
            DEC   A2E         ;0-->FF
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
            BPL   :SETMISC    ;->Nope.
*
* Auxiliary memory is available now at startup.
* Locate Memory Manager code into safe haven in aux memory.
*
            STA   $C005       ;transfer from main to aux
            >>>   MEMCPY,MMXBEG;MMXEND;AUXMM
            STA   $C004
            DEC   GOTMM       ;Mark that we got Memory Manager.
*
* Continue with miscellaneous initialization stuff.
*
:SETMISC
            JSR   SETNOR
            JSR   INIT
            JSR   HOME        ;Clear screen before SETVID might
            JSR   SETVID      ; change 80 screen to 40.
            JSR   SETKBD
            STA   KBDSTB
            LDY   #0
            STY   DOSNOW
            STY   AUXFLG
            STY   PSLOT       ;NO PRINTER.
            STY   FMT400K
            DEY               ;FF
            STY   TRKFLG
            LDA   #$0A
            STA   ASYNC
            LSR               ;A-->5
            STA   DSYNC
*
* Turn off 80 cols.
            BIT   FLAG80
            BPL   :AFTER80
            LDA   #$15        ;(ProDOS Tech. Ref., 5.3.1.3, page 99)
            JSR   $C300
*
:AFTER80
*
* Unpack MAIN portion of program into place
*
            >>>   UNPACK,MAINXEND;MAINEND
*
* Set reset vector now that we have somewhere to point to
*
            LDA   #FILER
            STA   $3F2
            LDA   #>FILER
            STA   $3F3
            EOR   #$A5
            STA   $3F4
*
            LDA   MACHID
            LSR
            BCS   :SKIPDAT
*
            >>>   UNPACK,CLKXEND;$800+CLKEND-CLKBEG
            JSR   $800
*
:SKIPDAT
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
            RTS
