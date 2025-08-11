********************************
*             COPY             *
********************************
*
COPY        EQU   *+3                  ;COPY starts after JMP :FMTFIX.
FMTFIX      JMP   :FMTFIX
            LDX   #$08                 ;Which COPY option?
            JSR   CHOOZ1
            STA   :COPYOPT
            LDA   #>TOPMEM
            STA   HIMEM
            LDY   #0
            STY   TOPDIF
            STY   VTOC2+1
            DEY
            STY   SDFLG                ;FF
            JSR   DODVP1
            JSR   DODVS1
            LDA   PUNIT
            BEQ   :NOT1DRV
            CMP   SUNIT
            BNE   :NOT1DRV
*
* SRC UNIT = TAR UNIT. CHECK IF
* REMOVABLE MEDIA
*
            JSR   DEVTYP
            TXA
            BMI   :ONEDRV              ;REMOVABLE
:NOT1DRV    LDX   #0
            DB    $2C
:ONEDRV     LDX   #$FF
            STX   ONLY1
*
            LDA   #1
            STA   PDOS
            STA   SDOS
            LDA   :COPYOPT             ;Chose option 0 - FILES?
            BNE   :NOTFILZ             ;->No: it's DISK or DOS
            JMP   :CPYFILS
*
*
* ********* COPY DISK & DOS *********
*
*
:NOTFILZ    LDA   #0
            STA   :BLKHI
            LDA   #$18
            STA   :BLKLO
            LDA   #$19                 ;Fix for Smartport calls with
            STA   $19                  ; AST Sprintdisk.
            LDA   :COPYOPT             ;[4am] adjust -2 this and following COPYOPTs
            CMP   #3                   ;Is it COPY DOS?
            BNE   :ITSDISK             ;->No, it's DISK or DISK W/ FORMAT.
            JMP   :ITSDOS              ;->It's COPY DOS.
*
*
:MISMAT     LDA   #$5E
            JMP   PRTPRS
*
* *** COPY DISK ***
*
:ITSDISK    LDA   #$12                 ;Set to say DISK (item $12), not DISK W/FORMAT
            STA   OPTCHS               ; cuz DISK W/ FORMAT doesn't fit on screen.
            JSR   COMH00               ;Say it.
            JSR   :INSDSK
            LDA   #0
            STA   :PASSNUM
            STA   RTRACK
            STA   BLKNUM
            STA   BLKNUM+1
*
* GET SOURCE DEVICE TYPE
*
            LDA   PUNIT
            JSR   UNTDEV
            STA   :PTYPE
*
* GET SOURCE BLOCK SIZE
*
            JSR   GTBLKS
            STX   :PBLKSL
            STX   :BLKLO
            STY   :PBLKSH
            STY   :BLKHI
*
* GET TARGET DEVICE TYPE
*
            JSR   TARHDR               ;S&D ONLY
            LDA   SUNIT
            JSR   UNTDEV
            STA   :STYPE
*
* GET TARGET BLOCK SIZE
*
            JSR   GTBLKS
            STX   :SBLKSL
            STY   :SBLKSH
            CPX   :PBLKSL              ;Are SOURCE and TARGET same size?
            BNE   :CHK35               ; (according to last status call)
            CPY   :PBLKSH
            BEQ   :CHKMM
:CHK35      LDA   PUNIT                ;No: But are they both 3.5-inch drives?
            JSR   :SET35               ; (to allow for a single-sided disk in
            BCS   :MISMAT              ; a double-sided drive; this does not
            LDA   SUNIT                ; correctly check for a single-sided
            JSR   :SET35               ; drive: no good way to check!)
            BCS   :MISMAT              ;->No they're not, so VOLUME SIZE MISMATCH.
*
* Check for & set up MM for copy
*
:CHKMM      BIT   GOTMM                ;Do we have the MM to use?
            BPL   :STRTCPY             ;->No: just go copy
*
            LDA   #0                   ;Yes: Move MM into main memory.
            STA   A1L
            STA   A4L
            LDA   #>AUXMM              ;src
            STA   A1H
            LDA   #>MMSPOT             ;dest
            STA   A4H
            LDA   #AUXMM+MMEND-MMBEG   ;src end
            STA   A2L
            LDA   #>AUXMM+MMEND-MMBEG
            STA   A2H
            CLC                        ;aux -> main
            JSR   AUXMOVE              ;Move it!
            LDA   PUNIT                ;Is either the source disk
            JSR   RAMDCHK
            BCS   :STRTCPY             ;->
            LDA   SUNIT                ; or the target disk a RAMdisk?
            JSR   RAMDCHK
            BCS   :STRTCPY             ;->Yes: Don't use MM.
            LDA   #0                   ;Neither disk is a RAMdisk:
            STA   MMCMD                ;(OPEN command is a 0)
            STA   MMBUFFER             ;(..while Acc=0....)
            JSR   MM                   ;OPEN the MM.
            BCS   :STRTCPY             ;->Error or no memory: don't use MM.
            DEC   MMISOPEN             ;No error: Flag the MM as OPEN.
            LDA   #>MMIOBUF            ;Store only 3 tracks in main memory, to
            STA   HIMEM                ; protect MM and its ProDOS buffer.
            LDA   #$10
            STA   MMREQCNT
*
:STRTCPY    LDA   PUNIT
            JSR   SETSD
            JSR   DOSTYP
            JMP   :DSKPS0
*
:DISKPAS    JSR   SRCHDR
            JSR   INSS1
:DSKPS0     LDA   PUNIT
            JSR   SETSD
            LDA   DOSNOW
            STA   PDOS
            JSR   SRCHDR
            INC   :PASSNUM
            JSR   :RDPASS
*
* DO SOME WRITIN'
*
:DSKWRT     JSR   TARHDR
            JSR   INSD1
            LDA   SUNIT
            JSR   SETSD
            JSR   :WRPASS
*
* CHECK IF DONE
*
            LDA   :PTYPE
            STA   :TYPE
            JSR   :CKDONE
            BCC   :DISKPAS
*
            LDA   :PASSNUM             ;How many passes were needed?
            CMP   #1                   ;Only 1?
            BNE   :COPYQ               ;->No: all done.
            LDA   #$5C                 ;Yes!: Ask 'COPY SAME ONTO ANOTHER
            JSR   LOWMES               ; DISK (Y/N) ? '
            JSR   CASKEY
            JSR   PCOUT                ;(Show the character typed)
            CMP   #"Y"
            BNE   :COPYQ               ;->Not Y.
            LDA   #$58                 ;Y: Prompt to insert target disk
            JSR   LOWMES
            JSR   INSCOM               ;Wait for keypress & clear message.
            JSR   :ERRWND
            JSR   CROUT
            JSR   INIT
            JMP   :DSKWRT              ;Go do another write pass.
*
:COPYQ      LDA   #0
            STA   FMT400K
            JMP   CLOSEMM
*
*
*
:BLKLO      DB    $0
:BLKHI      DB    $0
:TYPE       DB    $0
:PTYPE      DB    $0
:STYPE      DB    $0
:PBLKSL     DB    $0
:PBLKSH     DB    $0
:SBLKSL     DB    $0
:SBLKSH     DB    $0
:PASSNUM    DB    $0                   ;Number of passes used
*
*
* *** COPY DOS ***
*
*
:GOFONLY    JMP   FLONLY
:NOPRO      JSR   HOME
            JMP   NOPRO
*
:ITSDOS     JSR   COMH00               ;COPY DOS  SLOT: s DRIVE: d
            JSR   SRCHDR
            LDA   PUNIT
            JSR   UNTDEV
            BNE   :GOFONLY
            STA   BLKNUM
            STA   BLKNUM+1
            STA   :TYPE
            STA   :PTYPE
            STA   :STYPE
            JSR   TARHDR
            LDA   SUNIT
            JSR   UNTDEV
            BNE   :GOFONLY
            JSR   :INSDSK
            BIT   DOSNOW
            BMI   :NOPRO               ;SRC=PRODOS
*
* VERIFY SOURCE DISK IS REALLY DOS
*
            LDX   #>VTOC1
            JSR   RDVTOC
            JSR   DOS?
            JSR   :RDPASS
            JSR   TARHDR
            JSR   INSD
*
* VERIFY TARGET DISK IS REALLY DOS
*
            BIT   DOSNOW
            BMI   :NOPRO
            LDX   #>CVTOC
            JSR   RDVTOC
            JSR   :WRPASS
*
* MARK TRACKS 1 & 2 AS USED IN BITMAP
*
            LDA   #>CVTOC
            STA   RPAGE
            JSR   STVTOC               ;RETURNS A=0
            JSR   SET1A2
            JMP   FILER
*
*
*
:INSDSK     LDA   #0
            STA   PPFX
            STA   PPFX+5
            JSR   SRCHDR
            LDA   ONLY1                ;1 OR 2 DRIVES?
            BNE   :ONEDISK
            LDA   #$5F
            JSR   PRINT
            LDA   #$35
            JSR   PRINT                ;CRESC
            JSR   KYESC
*
:ONEDISK    JSR   HOME
            JSR   SRCHDR
            JSR   INSS1
            LDA   PUNIT
            STA   UNIT
            JSR   DOSTYP
            STA   PDOS
            JSR   UNTPFX               ;SETUP PFX
            LDY   #$3F
:IDLP       LDA   PFX,Y
            STA   PPFX,Y
            DEY
            BPL   :IDLP
            JSR   SRCHDR
            LDA   #0
            STA   RTRACK
            RTS
*
*
:RDPASS     LDA   #$15
            JSR   VLEFT
            JSR   PRHERE
            ASC   "Reading"
            DB    $2F,$0
            LDA   :PTYPE
            STA   :TYPE
            LDA   #$20                 ;READ TRACK
            STA   RCMND                ;COMMAND.
            LDA   RTRACK               ;SAVE THIS TRK
            STA   :SVTRK
            LDA   BLKNUM
            STA   :SVBLK
            LDA   BLKNUM+1
            STA   :SVBLK+1
            JSR   :DOPASS              ;READ.
*
            LDA   :COPYOPT             ;COPY DISK W/FORMAT?
            CMP   #2
            BNE   :RDPASSQ             ;->No.
            LDA   :PASSNUM             ;Yes: first time through?
            CMP   #1
            BNE   :RDPASSQ
            LDA   PUNIT                ;Yes: Is source disk a 3.5-inch disk?
            JSR   :SET35
            BCS   :RDPASSQ             ;->No.
            LDA   :PBLKSH              ;Yes: 400K or 800K?
            CMP   #$06
            BCS   :RDPASSQ             ;->800K.
            DEC   FMT400K
*
:RDPASSQ    RTS


*
:WRPASS     LDA   #$15
            JSR   VLEFT
            LDA   :COPYOPT             ;Is user's choice
            CMP   #2                   ; COPY DISK W/ FORMAT?
            BNE   :WRPASS1             ;->No.
            LDA   :PASSNUM             ;Yes: 1st write pass?
            CMP   #1
            BNE   :WRPASS1             ;->No.
            JSR   DEVTYP               ;Yes: What device have we here?
            BEQ   :WRPASS1             ;->Disk II, don't format ahead of time.
            TXA                        ;Does it support formatting?
            AND   #$08
            BEQ   :WRPASS1             ;->No!
            JSR   PRHERE               ;Yup:  Announce yourself
            ASC   "Formatting"
            DB    $2F,0                ; (cleol)
*
            LDA   FMT400K              ;Was source disk a 400K 3.5-inch disk?
            BPL   :WRFMT               ;->No, just format.
            LDA   SUNIT                ;Yes: Is this disk a 3.5-inch disk?
            JSR   :SET35
            STA   :UNIFLG
            BCS   :WRFMT               ;->No.
            JSR   :SETSIDS             ;Yes: (CLC) set it for 400K format
:WRFMT      JSR   SPLFRM               ; & format the sucker. (ignore errors)
            LDA   #0
            STA   CH
            JSR   :FMTFIX              ;Fix it back to 800K format.
*
:WRPASS1    JSR   PRHERE
            ASC   "Writing"
            DB    $2F,$0
            LDA   :STYPE
            STA   :TYPE
            LDA   :SVBLK
            STA   BLKNUM
            LDA   :SVBLK+1
            STA   BLKNUM+1
            LDA   :SVTRK               ;RESTORE TRK
            STA   RTRACK               ;IF 1ST TIME:
            BNE   :WRPASS2
            LDA   :COPYOPT
            CMP   #3                   ;COPY DOS?
            BEQ   :WRPASS2             ;->Yes.
            LDA   :TYPE
            BNE   :WRPASS2             ;NOT DISK II
            LDA   #$40                 ;RATCHET
            STA   RCMND                ;DEST.
            JSR   DORWTS
:WRPASS2    LDA   #$08                 ;COPY TRACK
            STA   RCMND                ;COMMAND.
*
* FALL INTO DOPASS
*
* If MM is open, we have hopes of multiple target copies.
* Don't use 1st mainmem buffer; leave it free for
* memory transfers of other tracks.
*
:DOPASS     BIT   MMISOPEN
            BMI   :DOLCPAS             ;->MM open: don't access 1st buffer.
            LDA   #>TOP40              ;Else (1B00-2AFF)
            STA   RPAGE
            JSR   :PASSINC             ; do 1 track in main mem.
            BCS   :PASSOUT
:DOLCPAS    JSR   :LCPASS              ;Do aux mem.
            BCS   :PASSOUT
            JSR   :MMPASS              ;Do MM.
            BCS   :PASSOUT
            LDA   #>TOP30              ;2B00-5AFF
            STA   RPAGE
:DPLOOP     JSR   :PASSINC             ;Do remaining main mem...
            BCS   :PASSOUT
            LDA   RPAGE
            ADC   #$10
            STA   RPAGE
            ADC   #$0F
            CMP   HIMEM
            BCC   :DPLOOP
:PASSOUT    RTS
*
:PASSINC    JSR   :GORWTS
            INC   RTRACK
*
* FALL INTO CKDONE
*
*
:CKDONE     LDA   BLKNUM+1
            CMP   :BLKHI
            BNE   :CHKBK0
            LDA   BLKNUM
            CMP   :BLKLO
:CHKBK0     RTS
*
*
* Pass unit # in Acc.
* Returns CLC if it's a 3.5 drive
*         SEC if not.
*  If CLC, EQ if Unidisk 3.5
*          NE if Apple 3.5 drive
* Also sets up unit numbers in Smartport-call tables.
*
:SET35      LSR                        ;0dss s000
            LSR                        ;00ds ss00
            LSR                        ;000d sss0
            TAX
            LDA   DEVADR+1,X           ;Get driver address.
            CMP   #$C1                 ;Is it in ROM?
            BCC   :SET35NO
            CMP   #$C8
            BCS   :SET35NO
            STA   SLOTPTR+1            ;Yes: Pt to ROM.
            LDA   #0
            STA   SLOTPTR
            LDY   #$07
            LDA   (SLOTPTR),Y          ;Is it a Smartport card?
            BNE   :SET35NO             ;->No.
            LDY   #1                   ;Yes: Convert the ProDOS unitnum (index)
            TXA                        ; into a Smartport unitnum.
            CMP   #$10                 ; (check drive 1/drive 2)
            BCC   :MKUNIT1
            INY
:MKUNIT1    LSR
            EOR   SLOTPTR+1            ; (ProDOS unitnum match real slot #?)
            AND   #$07
            BEQ   :MKUNIT2
            INY                        ; (No: inc Smartport unitnum by 2.)
            INY
:MKUNIT2    STY   :UNITNUM             ;Set up unitnum for all Smartport calls.
            STY   :AUNIT
            STY   :U1UNIT
            STY   :U2UNIT
            LDA   DEVADR,X             ;Get the Smartport entry pt.
            CLC
            ADC   #3
            STA   SLOTPTR
            JSR   :JMPSLOT             ;Call to get the status for this device.
            DB    $00
            DW    :UNITLST
            BCS   :SET35NO
            LDA   :STATLST+$15         ;Is it a 3.5 drive?
            CMP   #1
            BNE   :SET35NO             ;->No.
            LDA   :STATLST+$16         ;Yes: Unidisk 3.5 or Apple 3.5?
            CLC                        ;(returns EQ/NE)
            RTS
:SET35NO    SEC
            RTS
*
:UNITLST    DB    3
:UNITNUM    DS    1
            DW    :STATLST
            DB    3                    ;return Device info block command
*
            DUM   $800                 ;(not used during copy)
:STATLST    DS    $19
            DEND
*
*
* Called after the format, and at Reset time.
:FMTFIX     LDA   FMT400K              ;Need to fix back to 800K format?
            BPL   :SETSIDQ
            LDA   SUNIT                ;Yes: 3.5-inch drive?
            JSR   :SET35
            BCS   :SETSIDQ             ;->No: RTS.
            SEC                        ;Yes:
* fall through to :SETSIDS to reset 800K format.
*
*
* Pass in EQ = Unidisk 3.5
*         NE = Apple 3.5 drive
*         CC = set 400K format
*         CS = restore 800K format
:SETSIDS    BEQ   :UNISIDE
            LDA   #0                   ;Apple 3.5: Convert carry to 00 or 80
            ROR
            STA   :ASIDES              ;Save in sides value in table
            JSR   :JMPSLOT             ;Make the SetSides control call.
            DB    $04
            DW    :ASIDLST
            RTS
:UNISIDE    LDA   #0                   ;Unidisk: Convert carry to 00 or 80
            ROR
            STA   :USIDES
            JSR   :JMPSLOT             ;Make the SetAddress control call.
            DB    $04
            DW    :SADRLST
            BCS   :SETSIDQ
            JSR   :JMPSLOT             ;Make the Download control call.
            DB    $04
            DW    :DNLDLST
:SETSIDQ    RTS
*
:JMPSLOT    JMP   (SLOTPTR)
*
:ASIDLST    DB    3
:AUNIT      DS    1
            DW    :SIDECTL
            DB    9                    ;SetSides command
*
:SIDECTL    DB    1                    ;<-not 4 as manual says....
            DB    00
:ASIDES     DS    1
*
:SADRLST    DB    3
:U1UNIT     DS    1
            DW    :SADRCTL
            DB    6                    ;SetAddress command
*
:SADRCTL    DW    $0002
            DW    $0063
*
:DNLDLST    DB    3
:U2UNIT     DS    1
            DW    :DNLDCTL
            DB    7                    ;Download command
*
:DNLDCTL    DW    $0001
:USIDES     DS    1
*
:UNIFLG     DS    1
*
*
:LCPASS     LDA   :COPYOPT
            CMP   #3                   ;Option 5 - COPY DOS?
            BEQ   :LCOUT               ;->Yes: Don't use auxmem.
            LDA   ISAUX                ;No: Is there auxmem to use?
            BPL   :LCOUT               ;->No: Don't try to use it!
*
* THE FOLLOWING TWO LINES COMMENTED OUT ON  3/21/87
*
*LDA ONLY1
*BEQ :LCOUT               ;DUAL DRV COPY
*
            LDA   RCMND
            CMP   #8
            BEQ   :LCWRIT
            LDA   #>TOP30
            STA   :A1L+1
            STA   RPAGE
            LDA   #$0F
            STA   :A4L+1
:LCLP1      JSR   :PASSINC
            PHP
            SEC
            JSR   :AUXMOV
            STA   :A4L+1
            PLP
            BCS   :LCOUT0
            LDA   :A4L+1
            JSR   :CKA
            STA   :A4L+1
            BCC   :LCLP1
:LCOUT      CLC
:LCOUT0     RTS
*
:LCWRIT     LDA   #$0F
            STA   :A1L+1
            LDA   #>TOP40
            STA   :A4L+1
            STA   RPAGE
:LCLP2      CLC
            JSR   :AUXMOV
            STX   :A1L+1
            JSR   :PASSINC
            BCS   :LCOUT0
            LDA   :A1L+1
            JSR   :CKA
            STA   :A1L+1
            BCC   :LCLP2
            CLC
            RTS
*
:CKA        SEC
            BEQ   :CKA4OUT
            CMP   #$D0
            BCS   :CKA4A
            CMP   #$B0
            BCC   :CKA4A
            LDA   #$D0
:CKA4A      CLC
:CKA4OUT    RTS
*
:AUXMOV     PHP
            SEI
            PHP
            LDA   :A1L+1
            CLC
            ADC   #$0F
            STA   :A2L+1
            PLP
            STA   $C009                ;AUX ZP
            LDX   #7
:AUXLP      LDA   :A1L,X
            STA   A1L,X
            DEX
            BPL   :AUXLP
            LDA   $C08B
            LDA   $C08B
            JSR   $C311
            LDA   A4L+1
            LDX   A1L+1
            STA   $C008                ;MAIN ZP
            CMP   $C082                ;ROM
            PLP
            RTS
*
:A1L        DB    $0
            DB    $0
:A2L        DB    $FF
            DB    $0
            DB    $0,$0
:A4L        DB    $0
            DB    $0
*
* Memory Manager pass
*
:MMPASS     LDA   MMISOPEN             ;Is it open?
            BPL   :MMPASSQ             ;->Nah, forget this.
            LDA   #0                   ;Yes: reset the mark.
            STA   MMMARK
            STA   MMMARK+1
            LDA   RCMND                ;Is this read or write pass?
            CMP   #8                   ; (Command = copy (write) track?)
            BEQ   :MMWRIT              ;->Write Pass.
            LDA   #>TOP30              ;Read Pass:
            STA   MMBUFFER+1           ;Set to access thru 2nd mainmem buffer.
:MMRDLP     LDA   #MMCHECK             ;Check if there's room.
            STA   MMCMD
            JSR   MM
            BCS   :MMPASSQ             ;->There is not. Done with this pass.
            JSR   :PASSINC             ;There is. Read a track from disk.
            LDA   #MMWRITE             ;Write it into MM memory.
            STA   MMCMD
            ROR                        ;(Put carry from :PASSINC into Acc)
            JSR   MM
            BCS   :BADMM               ;->MM error! Gag and exit.
            ASL                        ;(:PASSINC result back into carry)
            BCC   :MMRDLP              ;->Not done with disk: go back for more.
            RTS                        ;Done with disk. Exit carry set.
*
:MMWRIT     LDA   #>TOP40              ;Set to access thru 1st mainmem buffer.
            STA   MMBUFFER+1
            LDA   #MMREAD              ;Set to do reads from MM memory.
            STA   MMCMD
:MMWRLP     JSR   MM                   ;Read a track's worth from MM.
            BCS   :MMWRQ               ;->Either no room left or terrible error.
            JSR   :PASSINC             ;Write that track to disk.
            BCC   :MMWRLP              ;->Not done with disk: go back for more.
            RTS                        ;Done with disk. Exit carry set.
:MMWRQ      LDA   MMERRNUM             ;Is there error for "just out of room"?
            CMP   #SIZEERR
            BNE   :BADMM               ;->No! Yecch. Go scream.
:MMPASSQ    CLC                        ;Yes:Exit carry clear.
            RTS
*
:BADMM      LDA   #0                   ;Nasty MM error! let's say that MM
            STA   GOTMM                ; is no longer available.
            JSR   LOHERE               ;Print a silly message for me
            ASC   "Internal memory handling error #"
            DB    0
            LDA   MMERRNUM             ; with the error number!
            JSR   PHBYTE
            JSR   PRHERE               ;Next copy (without MM) should work.
            DB    $8D
            ASC   "Try copying again..."
            DB    0
            JSR   RDKEY
            JSR   CLOSEMM              ;(Close the MM)
            JMP   FILER                ;& abandon ship.
*
*
*
:GORWTS     LDA   #8
            STA   :COUNT
            LDA   RPAGE
            STA   :RPSAVE
:BLKLOOP    LDA   #$15
            JSR   TABV
            LDA   #8
            STA   CH
            JSR   :TRKBLK
            JSR   CKESC
*
*
:GORWTS0    LDA   RCMND                ;Write Track command?
            CMP   #$08
            BNE   :NOTWRT              ;->No.
            LDA   :TYPE                ;Yes: track (floppy) or block device?
            BEQ   :GTRKIO              ;->track (FLOPPY)
*
* Write to a block device:
* SPECIAL CHECK FOR /RAM!!!!!!!!
* MUST NOT WRITE BLOCK 7 ON /RAM,
* IT HANGS THE SYSTEM!!!!
*
            LDA   UNIT
            CMP   #$B0
            BNE   :NOTRAM
            LDA   BLKNUM
            AND   #$FC
            CMP   #4
            BEQ   :BLKLP0A             ;BLKS4-7
:NOTRAM     JSR   WTBLK
:ISRAM7     JMP   :BLKLP0
*
:NOTWRT     LDA   :TYPE
:GTRKIO     BEQ   :TRKIO               ;FLOPPY
            JSR   RDBLK
*
* READ/WRITE UP TO 8 BLOCKS, WHICH
* TAKE UP THE SAME SPACE AS 1 TRACK
*
:BLKLP0     BCC   :BLKLP0A
            JSR   :RWERR
:BLKLP0A    INC   RPAGE
            INC   RPAGE
            INC   BLKNUM
            BNE   :BLKLP1
            INC   BLKNUM+1
:BLKLP1     DEC   :COUNT
            BEQ   :BLKLP3              ;WE'VE DONE 8
            JSR   :CKDONE
            BCC   :BLKLOOP
:BLKLP3     LDA   :RPSAVE
            STA   RPAGE
:GORWTSQ    RTS
*
*
*
:TRKIO      LDA   BLKNUM
            CLC
            ADC   #8
            STA   BLKNUM
            BCC   :GORWTS1
            INC   BLKNUM+1
*
:GORWTS1    JSR   PHRWTS               ;GO RWTS.
            BCC   :GORWTSQ             ;ERROR?
:RWERR      LDA   RRTN                 ;YES: WRITE-
            CMP   #$2B                 ;PROTECTED?
            BNE   :NOTWP
            JMP   ERROUT
*
:NOTWP      JSR   :ERRWND              ;Set scrolling window area
            LDX   #$25                 ;SET 'READ'
            LDA   RCMND
            CMP   #$20
            BEQ   :SEERR
            INX                        ;OR 'WRITE'
:SEERR      TXA
            JSR   PRINT
            JSR   PRSPC
            LDA   #$3A                 ;'ERROR'
            JSR   PRINT
            JSR   PRSPC
            JSR   :TRKBLK
            JMP   INIT                 ;RESET WINDOW
*
:SVTRK      DB    $0
:SVBLK      DB    $0,$0
:RPSAVE     DB    $0
:COUNT      DB    $0
*
:ERRWND     LDA   #$03
            STA   WNDTOP               ;SET WINDOW
            LDA   #$14
            STA   WNDBTM
            LDA   #$13                 ;& VTAB.
            JMP   VLEFT
*
:TRKBLK     LDX   :STYPE
            LDA   RCMND
            EOR   #8
            BEQ   :TB3
            LDX   :PTYPE
:TB3        TXA
            BEQ   :PRTTRK
            JMP   PRTBLK               ;Print BLOCK then the block #.
:PRTTRK     JSR   PRTTRK               ;Print TRACK then the track #.
            JMP   CROUT
*
*
***********  COPY FILES  **********
*
:NONE       JMP   NOSEL
*
:CPYFILS    LDA   #$00
            STA   STATE                ;STATE=0
            STA   SDFLG
            JSR   TREEP
            JSR   TOP1
            JSR   SRCHDR
            JSR   CT1
            JSR   CATDIS               ;SELECT FILES
            LDA   FILNUM
            BEQ   :NONE
*
            JSR   TARHDR
            JSR   INSD
            JSR   SETS
            JSR   CT1
            JSR   UNTPFX
            JSR   TARHDR
            JSR   PRVNM
*
* CHECK IF DUPLICATE VOLUME ONLINE
*
            LDA   PDOS
            AND   SDOS
            CMP   #$FF
            BNE   :NOTDUPV             ;NOT BOTH PRO
*
*
            LDY   PFX                  ;WAS *PPFX
:DVCK       LDA   PFX,Y
            CMP   PPFX,Y
            BNE   :NOTDUPV
            DEY
            BNE   :DVCK
*
* THE FIRST 'PFX' CHARS OF BOTH VOLUME NAMES ARE THE SAME.
* NOW CHECK TO MAKE SURE THAT WE DON'T HAVE '/ABC' AND
* '/ABCDE'.
*
            LDY   PFX
            CPY   PPFX
            BEQ   :ISDUPV
            BCS   :NOTDUPV
            LDA   PPFX+1,Y
            CMP   #'/'
            BNE   :NOTDUPV             ;/ABC & /ABCD
*
* WE HAVE /ABC & /ABC/DE IF CODE FALLS THRU TO HERE
*
* VOLUME NAMES ARE THE SAME. IF TWO
* DRIVE COPY, GIVE ERROR. IF SINGLE
* DRIVE COPY, ASSUME USER IS COPYING
* FROM ONE FILE TO ANOTHER ON THE SAME
* DISKETTE AND PRETEND LIKE MEDIA
* IS NON-REMOVABLE.
*
:ISDUPV     LDA   PUNIT                ;SINGLE DRIVE
            EOR   SUNIT                ; COPY?
            BEQ   :NOTDUP
*
:DUPERR     JSR   HOME
            LDA   #$60
            JMP   PRTPRS
*
:NOTDUP     STA   ONLY1
:NOTDUPV    JSR   TREES
            LDA   #0
            STA   SP
            JSR   TOP1
            JSR   SRCHDR
            JSR   INSS
*
* BEGIN THE COPY CYCLE
*
:GOTFILS    JSR   SWPCHK
            JSR   FILMOV               ;ARRANGE 'EM
            LDA   #$00
            STA   CURR
            JSR   PATMOV               ;SQUISH LIST
            JSR   HOME
*
* ANTICIPATE PRODOS --> DOS COPY
*
            LDA   #>TOP11
            JSR   SETHIM
*
:CPYFILE    LDA   KBD                  ;CHECK FOR ESC
            CMP   #$9B
            BEQ   :LPOUT
            JSR   SRCHDR
            JSR   INSS
            JSR   SRCHDR
            JSR   FILEQ                ;UPDATE FILEQ
            JSR   OPNSRC               ;OPEN & READ
            BIT   PDOS
            BPL   :CPF0                ;SRC = DOS
            BIT   SDOS
            BMI   :CPF0                ;TAR = PRODOS
*
* *RADR IS SET TO 2 FOR BASIC FILES OR
* 4 FOR BINARY FILES IF COPYING
* PRODOS --> DOS
*
            JSR   CURPNT
            LDY   #$10
            LDA   (POINT),Y            ;FILE TYPE
            LDY   #0
            CMP   #4
            BEQ   :CPF00               ;SRC = TXT
            CMP   #$FE
            BEQ   :CPF00               ;SRC = REL
            LDY   #2
            CMP   #$FA
            BEQ   :CPF00               ;SRC = INT
            CMP   #$FC
            BEQ   :CPF00               ;SRC = BAS
            LDY   #4
:CPF00      STY   RADR
:CPF0       JSR   :GOREAD
            JSR   TXTCNV
            JSR   TARHDR
            JSR   INSD
            JSR   TARHDR
            JSR   :OPNDEST             ;OPEN & WRITE
            BCS   :FINIS1              ;DON'T COPY
            JSR   :PRFILE
            LDA   STRTYP
            CMP   #$D0
            BEQ   :FINISH
            BNE   :CPYF1
*
:LPOUT      RTS
*
:CPYLOOP    LDA   ONLY1
            BPL   :NOCLS               ;2 DRIVES
            JSR   GOCLS                ;CLOSE DEST
:NOCLS      JSR   SRCHDR
            JSR   INSS
            JSR   SRCHDR
            JSR   :GOREAD              ;NO:READ MORE
            JSR   TXTCNV
            JSR   TARHDR
            JSR   INSD
            JSR   TARHDR
            LDA   ONLY1
            BPL   :CPYF1               ;2 DRIVES
            JSR   REOPEN
:CPYF1      JSR   :WRITDAT             ;WRITE MORE
            LDA   EOF                  ;ALL DONE?
            BEQ   :CPYLOOP
:FINISH     JSR   WRCAT2               ;WRITE CATALOG
:FINIS1     JSR   LOHERE
            DB    $0
            LDA   STRTYP
            CMP   #$D0
            BNE   :FIN2                ;NOT SUBDIR
            LDX   CURR
            LDA   STATUS,X
            BEQ   :FIN2                ;DIDN'T COPY
*
* JUST CREATED SUBDIRECTORY
*
            JSR   SRCHDR
            JSR   INSS
            JSR   DIVEIN
            CLC
            JSR   DIVECK
            JSR   SRCHDR
            JSR   :TARDIN
            LDX   #$FF
            STX   CURR
*
:FIN2       INC   CURR                 ;NEXT FILE
            LDA   CURR
            CMP   FILNUM               ;NO MORE?
            BCS   :FIN3
            JMP   :CPYFILE
*
* FINISHED WITH CURRENT SUBDIRECTORY.
* NOW DIVE OUT AND CONTINUE WITH NEXT
* HIGHER DIRECTORY
*
:FIN3       BIT   PDOS
            BPL   :INROOT              ;DOS 3.3
            JSR   SRCHDR
            JSR   INSS
            JSR   DIVOUT
            BCS   :INROOT              ;IN ROOT
            SEC
            JSR   DIVECK
            JSR   SRCHDR
            JSR   :TARDOUT
            JMP   :FIN2
*
:INROOT     JMP   :LPOUT
*
:TARDIN     BIT   SDOS
            BPL   :TAROUT
:TDIN1      LDX   SPFX
            LDY   #0
            LDA   #$2F
            CMP   SPFX,X
            BEQ   :TLPB
            STA   SPFX+$1,X
            INX
:TLPB       INY
            INX
            LDA   FILE,Y
            STA   SPFX,X
            CPY   FILE
            BCC   :TLPB
            STX   SPFX
:TAROUT     RTS
*
:TARDOUT    BIT   SDOS
            BPL   :TAROUT
            LDY   SPFX
            LDA   SPFX,Y
            CMP   #$2F
            BNE   :TLPD
:TLPC       DEY
:TLPD       LDA   SPFX,Y
            CMP   #$2F
            BNE   :TLPC
            DEY
            STY   SPFX
            RTS
*
*
:GOREAD     LDA   UNIT
            JSR   UNTDEV
            BNE   :NOTDII
            LDA   RSLOT
            STA   RPSLOT
            LDA   RDRIVE
            STA   RPDRIV
:NOTDII     JMP   RDDATA
*
*
:PRFILE     JSR   LOHERE
            DB    $0
            JSR   PRHERE
            ASC   "Target: "
            DB    $0
            JMP   PRFILE
*
*
*
*-------------------------------------
*
* HANDLE DUPLICATE FILE FOUND
*
*
* RETURNS: C=0 --> NEW NAME
*          C=1:
*          A=00 --> DON'T COPY
*          A=FF --> COPY ANYWAY
*
:DUP        PHA
            STX   :TARSTR
            JSR   LOHERE
            DB    $0
            LDA   #$14
            JSR   VLEFT
            JSR   PRHERE
            ASC   "File: "
            DB    $0
            JSR   PRFILE
            JSR   PRHERE
            DB    $8D
            ASC   "already exists"
            DB    $0
            PLA
            BPL   :DUP1                ;NOT LOCKED
:DUPLOK     JSR   PRHERE
            ASC   " & is locked."
            DB    $0
:DUP1       JSR   PRHERE
            ASC   "  Now what? "
            DB    $0
            LDA   CH
            STA   :CH
*
:DUP2       LDA   #$16
            JSR   VLEFT
            LDA   :TARSTR
            CMP   #$0D
            BEQ   :DUP3
            JSR   PRHERE
            ASC   "[C]opy anyway, "
            DB    $0
:DUP3       JSR   PRHERE
            ASC   "[N]ew name, [D]on't copy"
            DB    $8D
            ASC   "[Esc]-Exit copy"
            DB    $0
*
            LDA   #$15
            JSR   VLEFT
            LDA   :CH
            STA   CH
            JSR   KEYESC
            LDX   :TARSTR
            CPX   #$0D
            BEQ   :DUP4
            CMP   #"C"                 ;COPY OVER
            BEQ   :ANYWAY
:DUP4       CMP   #"N"                 ;RENAME IT
            BEQ   :NEWNAME
            CMP   #"D"                 ;DON'T COPY
            BEQ   :DONT
            JSR   BELL
:GODUP2     JMP   :DUP2
*
:NEWNAME    JSR   PCOUT
            JSR   PRHERE
            DB    $8D
            ASC   "New name?"
            INV   "/"
            DB    $8D
            INV   "/"
            DB    $0
            LDA   #$16
            JSR   VLEFT
            LDA   #$0A
            STA   CH
            LDA   #$0F
            BIT   DOSNOW
            BMI   :NEWPRO
            LDA   #$1E
:NEWPRO     STA   LINLIM
            JSR   GETLN                ;GET IT
            BCS   :GODUP2              ;ESC ABORT
            STX   FILE
            LDY   #0
:NEWLOOP    LDA   LINEIN,Y
            BIT   DOSNOW
            BPL   :NEW33
            AND   #$7F
:NEW33      STA   FILE+$1,Y
            INY
            CPY   FILE
            BCC   :NEWLOOP
:NEWLP1     CPY   #$1E
            BCS   :NEWOUT
            LDA   #$A0
            STA   FILE+$1,Y
            INY
            BNE   :NEWLP1              ;ALWAYS
:NEWOUT     CLC
            BCC   :COMOUT
*
*
:ANYWAY     JSR   PCOUT
            LDA   #$FF
            BNE   :COMOUT0
*
:DONT       JSR   PCOUT
            JSR   DODEL                ;UNMARK
:COMOUT0    SEC
:COMOUT     PHA
            PHP
            JSR   LOHERE               ;CLEAR BOTTOM
            DB    $0
            JSR   INIT
            PLP
            PLA
            RTS
:CH         DB    $0
:TARSTR     DB    $0
*
*
*
************************************
*
* OPEN DEST. FILE FOR WRITING
* (FIND 1ST DELETED CATALOG ENTRY )
*
:OPNDEST    JSR   CNVNAM               ;CNVT FILE NAME
            LDA   DATADR
            STA   RPAGE
            LDY   #$FF
            STY   RBLKL-1
            STY   RBLKH-1
            INY
            STY   :FSIZE
            STY   :FSIZE+1
            BIT   DOSNOW
            BMI   :PRODOS
            JMP   :DOS33
*
:PRODOS     LDA   #>TOPMEM
            JSR   SETHIM
*
            JSR   CURPNT
            LDA   #0
            STA   :WLEN                ;10/9/87, needs to be initialized!
            STA   :WBUFF
            BIT   PDOS
            BPL   :D2P                 ;DOS-->PRODOS
*
* PRODOS --> PRODOS COPY
*
* A ALREADY ZERO
*
            LDY   RADR
            STY   :WBUFF
            STA   RADR
            LDY   #$10
            LDA   (POINT),Y
            STA   FTYPE
            LDY   #$1E
            LDA   (POINT),Y
            STA   ACCESS
            INY
            LDA   (POINT),Y
            STA   AUXTYP
            INY
            LDA   (POINT),Y
            STA   AUXTYP+1
            LDY   #$15
:DLNLP      LDA   (POINT),Y
            STA   FILELN-$15,Y
            INY
            CPY   #$18
            BCC   :DLNLP
            LDY   #$21
:P2PLPM     LDA   (POINT),Y
            STA   MODDAT-$21,Y
            INY
            CPY   #$25
            BCC   :P2PLPM
            BCS   :DOCREAT
*
* DOS --> PRODOS COPY
*
:D2P        LDA   #1                   ;ANTICIPATE
            STA   AUXTYP               ; BASIC
            LDA   #8
            STA   AUXTYP+1
            JSR   GETDAT               ;DATE & TIME
            LDY   #2
            LDX   #1
            LDA   (POINT),Y
            BMI   :D2PLOK
            LDX   #$C3
:D2PLOK     STX   ACCESS
            AND   #$7F
            PHA
            LDX   #4
:D2PLP1     CMP   :DTYPES,X
            BEQ   :D2P1
            DEX
            BPL   :D2PLP1
            LDX   #5
:D2P1       LDA   :PTYPES,X
            STA   FTYPE
*
            PLA
            LDY   #0
            STY   RADR
            CMP   #1
            BEQ   :DBAS
            CMP   #2
            BEQ   :DBAS
            CMP   #4
            BNE   :NOTDBIN
            LDA   (RADR),Y             ;Y=0
            STA   AUXTYP
            INY
            LDA   (RADR),Y
            STA   AUXTYP+1
            INY
:DBAS       LDA   (RADR),Y
            STA   FILELN
            INY
            LDA   (RADR),Y
            STA   FILELN+1
            LDA   #0
            STA   FILELN+2
            INY
            STY   :WBUFF
            BNE   :DOCREAT
*
* FOR T,S, NEW A, & NEW B FILES WE
* DON'T KNOW THE LENGTH.
*
* Y IS ALREDY ZERO
*
:NOTDBIN    STY   AUXTYP
            STY   AUXTYP+1
            STY   FILELN
            STY   FILELN+1
            STY   FILELN+2
*
:DOCREAT    LDA   STRTYP
            CMP   #$D0
            BNE   :NOTDIR
            JSR   MKDIR
            JMP   :DOCRT1
*
:NOTDIR     JSR   PCREAT
:DOCRT1     BCC   :OPNDES1
            CMP   #$47
            BNE   :ERR
            JSR   GTINFO
            LDA   INFLST+3
            AND   #$C2
            EOR   #$C2
            BEQ   :CRTERR1
            LDA   #$80
:CRTERR1    LDX   INFLST+7             ;STORAGE TYPE
            JSR   :DUP
            BCC   :DOCREAT             ;CHANGED NAME
            BEQ   :NODO
            JSR   PDSTRY               ;COPY ANYWAY
            JMP   :DOCREAT
*
:OPNDES1    JSR   DOMLI                ;OPEN FILE
            DB    $C8
            DW    :OPNLST
            LDA   :OPNLST+5
            STA   REF
            CLC
:NODO       RTS
*
*
:ERR        JMP   ERROUT
*
:DTYPES     DB    $00,$01,$02,$04,$10,$04
:PTYPES     DB    $04,$FA,$FC,$06,$FE,$06
*
:OPNLST     DB    $03
            DW    FILE
            DW    FILBUF
            DB    $0
*
:DOS33      LDA   #>TOP10
            JSR   SETHIM
            BIT   PDOS
            BPL   :DOS2DOS             ;DOS --> DOS
            DEC   HIMEM                ;PRODOS -> DOS
            DEC   HIMEM
:DOS2DOS    JSR   RDCAT2
*
            JSR   CURPNT
            BIT   PDOS
            BMI   :P2D
*
* DOS --> DOS COPY
*
            LDY   #2
            LDA   (POINT),Y
            STA   FTYPE
            LDY   #0
            BEQ   :TODOS               ;ALWAYS
*
* PRODOS --> DOS COPY
*
:P2D        LDY   #$15
            LDA   STRTYP
            CMP   #$D0
            BNE   :P2DLPF
            SEC                        ;SUBDIR
            RTS
*
:P2DLPF     LDA   (POINT),Y
            STA   FILELN-$15,Y
            INY
            CPY   #$18
            BCC   :P2DLPF
            LDA   DATADR
            STA   POINT2+1
            LDA   #0
            STA   POINT2
            LDY   #$10
            LDA   (POINT),Y
            LDX   #4
:P2DLP      CMP   :PTYPES,X
            BEQ   :P2D1
            DEX
            BPL   :P2DLP
            LDX   #5
:P2D1       LDA   :DTYPES,X
            STA   FTYPE
            LDY   #$1E
            LDA   (POINT),Y
            AND   #$C2
            EOR   #$C2
            BEQ   :P2D2
            LDA   #$80
:P2D2       ORA   FTYPE
            STA   FTYPE
            LDY   #0
            AND   #$7F
            BEQ   :TODOS               ;TEXT FILE
            CMP   #$10
            BEQ   :TODOS               ;RTYPE
            CMP   #3
            BCC   :ISBAS               ;BASIC
*
* BINARY FILE
*
            LDY   #$1F
            LDA   (POINT),Y            ;AUXTYPE LO
            LDY   #0
            STA   (POINT2),Y
            LDY   #$20
            LDA   (POINT),Y            ;AUXTYPE HI
            LDY   #1
            STA   (POINT2),Y
            INY
*
* HIGH BYTE OF FILE EOF IS IGNORED
* IT SHOULD ALWAYS BE ZERO FOR BASIC
* OR BINARY FILES
*
:ISBAS      LDA   FILELN
            STA   (POINT2),Y
            LDA   FILELN+1
            INY
            STA   (POINT2),Y
            INY
*
* ROUND UP *FILELN TO NEXT HIGHEST
* MULTIPLE OF 256
*
:TODOS      STY   :LASTFLG
            TYA
            CLC
            ADC   FILELN
            BEQ   :TODOS0
            LDA   #1
:TODOS0     ADC   FILELN+1
            STA   FILELN+1
            BCC   :TODOS1
            INC   FILELN+2
:TODOS1     LDA   #0
            STA   :FNDFLG
            STA   FILELN
:TODOS2     LDA   #>CAT2
            STA   POINT2+1
*
:NXTSCT2    LDY   #$01                 ;SAVE LINK TO
            STY   POINT2               ;NEXT CATALOG
            DEY                        ;SECTOR
            LDA   (POINT2),Y
            STA   :ENDCAT
            LDA   #$0B                 ;1ST ENTRY IN
            STA   POINT2               ;SECTOR
:DOPNT2     LDY   #0
            LDA   (POINT2),Y           ;GET TRACK
            BEQ   :FOUND               ;END OF CAT?
            CMP   #$FF
            BEQ   :FOUND               ;DELETED FILE?
*
* CHECK FOR DUPLICATE ENTRY
*
            LDY   #3
:DUPCHK     LDA   FILE-2,Y
            CMP   (POINT2),Y
            BNE   :NXTNAM
            INY
            CPY   #$21
            BCC   :DUPCHK
            LDY   #2
            LDA   (POINT2),Y
            AND   #$80
            LDX   #0
            JSR   :DUP
            BCS   :DUPCHK1
            BCC   :TODOS2              ;NEW NAME
*
:NXTNAM     CLC                        ;NO: GO TO
            LDA   POINT2               ;NEXT ENTRY
            ADC   #$23
            STA   POINT2
            BNE   :DOPNT2              ;END SECTOR?
            INC   POINT2+1             ;NEXT ONE
            LDA   :ENDCAT              ;END CATALOG?
            BNE   :NXTSCT2
            LDA   :FNDFLG
            BNE   :FOUNDOK             ;THERE'S ROOM
            LDA   #$49                 ;CATALOG FULL
            JMP   :FULLERR
*
:DUPCHK1    CMP   #0
            BEQ   :GOAWAY              ;DON'T COPY
*
* COPY ANYWAY: DELETE FILE
*
            LDA   POINT2
            PHA
            STA   POINT
            LDA   POINT2+1
            PHA
            STA   POINT+1
            LDA   #1
            JSR   D1FILE
            JSR   WRCAT2
            PLA
            STA   POINT2+1
            PLA
            STA   POINT2
            JMP   :FOUND0
*
:GOAWAY     SEC
            RTS
*
:FOUND      BIT   :FNDFLG
            BMI   :NXTNAM
:FOUND0     LDA   POINT2
            STA   :POINT2
            LDA   POINT2+1
            STA   :POINT2+1
            LDA   #$FF
            STA   :FNDFLG
            BNE   :NXTNAM              ;ALWAYS
*
:FOUNDOK    LDA   :POINT2
            STA   POINT2
            LDA   :POINT2+1
            STA   POINT2+1
            JSR   CURPNT               ;FOUND DELETED
            LDY   #2
            LDA   FTYPE
            STA   (POINT2),Y
            INY                        ;ENTRY:
:ENTRYLP    LDA   FILE-2,Y             ;COPY SOURCE
            STA   (POINT2),Y           ;ENTRY TO DEST.
            INY
            CPY   #$23
            BCC   :ENTRYLP
            LDA   NSECTS               ;SET NEXT
            STA   SECTOR               ;AVAILABLE
            LDA   VTRACK               ;T&S
            STA   TRACK
            STA   :TRK1ST              ;DISK FULL TEST
            LDX   #$FF                 ;SET DIRECTION
            CMP   #$11                 ;BY CURRENT
            BCC   :PUTDIR              ;TRACK
            LDX   #$01                 ;ALLOCATED
:PUTDIR     STX   VDIR
            JSR   :ALLOC               ;ALLOCATE
            LDY   #$00                 ;TSLIST & PUT
            LDA   TRACK                ;INTO ENTRY &
            STA   :TSTRK               ;SAVE FOR
            STA   (POINT2),Y           ;EVENTUAL
            INY                        ;DISK WRITE
            LDA   SECTOR
            STA   :TSSECT
            STA   (POINT2),Y
            LDA   #$00                 ;(1ST TSLIST)
            STA   :OFFSET
            STA   :OFFSET+1
            JSR   :NEWTSL              ;CLEAR TSLIST
            LDA   #$0C                 ;RESET T/S
            STA   :DTSP                ;POINTER
            CLC
            RTS
:POINT2     DB    $0,$0
:FNDFLG     DB    $0
*
**********************************
*
* WRITE DATA TO DEST. DISK
*
:WRITDAT    LDA   REF
            STA   :WRTLST+1
            STA   :MRKLST+1
            STA   :EOFLST+1
            STA   :CLSLST+1
            LDA   DATADR
            STA   RPAGE                ;SET ADDRESS
            STA   :WBUFF+1
            JSR   CURPNT
            LDX   #0
            STX   :INDEX
            BIT   DOSNOW
            BMI   :WTPRO
            JMP   :WDOS33
*
:WTPRO      LDA   RELCNT
            BNE   :D2P2A
*
* NOTHING TO WRITE
*
            JMP   :SKIPEOF
*
:D2P2A      LDA   #0
:D2P2B      STA   :WLEN+1
            LDX   :INDEX
:D2PWLP     CPX   RELCNT
            BCS   :D2P3
            LDA   RBLKL,X
            SEC
            SBC   RBLKL-1,X
            TAY
            LDA   RBLKH,X
            SBC   RBLKH-1,X
            BNE   :D2P3                ;RANDOM
            CPY   #2
            BCS   :D2P3                ;RANDOM
            INC   :WLEN+1
            INX
            JMP   :D2PWLP
*
*
:D2P3       STX   :INDEX
            LDA   :WLEN+1
            BNE   :NOTSPRS
            JMP   :DOSPRSE             ;SPARSE
*
:NOTSPRS    BIT   PDOS
            BPL   :D2P4                ;DOS 3.3
*
* PRODOS --> PRODOS
*
            ASL   :WLEN+1
            JSR   :WRTPRO
            LDX   :INDEX               ;3/10
            CPX   RELCNT               ;3/10
            BCC   :D2P5C               ;3/10
            LDA   #0                   ;3/10
            STA   :WBUFF               ;3/10
            BEQ   :D2P5C               ;3/10
*
*
* DOS --> PRODOS
*
:D2P4       LDA   #0
            SEC
            SBC   :WBUFF
            STA   :WLEN
            BCS   :D2P5                ;IF WBUFF = 0
            DEC   :WLEN+1
:D2P5       JSR   :WRTPRO
:D2P5C      LDA   :WBUFF
            CLC                        ;3/10
            ADC   :WLEN
            STA   :WBUFF
            LDA   :WBUFF+1
            ADC   :WLEN+1
            STA   :WBUFF+1
            LDX   :INDEX
            CPX   RELCNT
            BCC   :D2P2A

*
* WRITTEN EVERYTHING UP TO RELCNT
*
:NOMOWT     LDA   EOF                  ;ALL DONE?
            BNE   :NOMO1               ;YES
            JMP   :D2P6                ;NO
*
:NOMO1      LDA   FTYPE
            CMP   #4                   ;TEXT FILE?
            BNE   :NOTTEXT             ;NO
            LDA   PDOS
            BMI   :NOTTEXT             ;P-->P
*
* IF COPYING DOS --> PRODOS,
* FOR TEXT FILES, MUST FIGURE OUT
* EXACT EOF FROM LAST BIT OF FILE
* WRITTEN
*
            JSR   DOMLI                ;GET EOF
            DB    $D1
            DW    :EOFLST
            LDY   :WBUFF+1
            DEY
            STY   MESPNT+1             ;LAST PG
            LDA   #0
            STA   MESPNT
            LDY   #$FF
:TEXTLP     LDA   (MESPNT),Y
            BNE   :TEXTLP1
            DEY
            CPY   #$FF
            BNE   :TEXTLP
            DEC   MESPNT+1
            DEC   :FILELN+1            ;DEC BY 256
:TEXTLP0    LDA   (MESPNT),Y
            BNE   :TEXTLP1
            DEY
            CPY   #$FF
            BNE   :TEXTLP0
:TEXTLP1    INY
            BEQ   :TEXTLP2
            DEC   :FILELN+1
:TEXTLP2    STY   :FILELN
            JMP   :SETIT
*
* SET EOF IN FILE
*
:NOTTEXT    LDA   FILELN
            ORA   FILELN+1
            ORA   FILELN+2
            BEQ   :SKIPEOF             ;SKIP SET EOF
            LDA   FILELN
            STA   :FILELN
            LDA   FILELN+1
            STA   :FILELN+1
            LDA   FILELN+2
            STA   :FILELN+2
:SETIT      JSR   DOMLI
            DB    $D0
            DW    :EOFLST
*
* SET FILE INFO: ACCESS & MOD D&T
*
:SKIPEOF    JSR   DOMLI
            DB    $CC
            DW    :CLSLST
            JSR   GTINFO
            LDA   ACCESS
            STA   INFLST+3
            LDY   #3
:MDTLP      LDA   MODDAT,Y
            STA   INFLST+$0A,Y
            DEY
            BPL   :MDTLP
            JSR   STINFO
:D2P6       RTS
*
*
* COMPUTE SIZE OF SPARSE AREA.
* NOTE: COULD BE > 64K!
*
:DOSPRSE    LDA   RBLKL,X
            SEC
            SBC   RBLKL-1,X
            STA   :SPARSE
            LDA   RBLKH,X
            SBC   RBLKH-1,X
            STA   :SPARSE+1
            LDA   :SPARSE
            BNE   :DOSPRS1
            DEC   :SPARSE+1
:DOSPRS1    DEC   :SPARSE
            BIT   PDOS
            BPL   :DOSPRS2
            ASL   :SPARSE
            ROL   :SPARSE+1
*
:DOSPRS2    JSR   DOMLI
            DB    $CF
            DW    :MRKLST
            LDA   :WPOS+1
            CLC
            ADC   :SPARSE
            STA   :WPOS+1
            LDA   :WPOS+2
            ADC   :SPARSE+1
            STA   :WPOS+2
            JSR   DOMLI                ;SET EOF
            DB    $D0
            DW    :MRKLST
            JSR   DOMLI                ;SET MARK
            DB    $CE
            DW    :MRKLST
            INC   :INDEX
            LDA   #1
            JMP   :D2P2B
*
:MRKLST     DB    $2
            DB    $0
:WPOS       DB    $0,$0,$0
:SPARSE     DB    $0,$0
:INDEX      DB    $0
:EOFLST     DB    $2
            DB    $0
:FILELN     DB    $0,$0,$0
:CLSLST     DB    $1
            DB    $0
*
*
*
*
:WRTPRO     JSR   DOMLI
            DB    $CB
            DW    :WRTLST
            RTS
*
:WRTLST     DB    $4
            DB    $0
:WBUFF      DB    $0,$0
:WLEN       DB    $0,$0
            DB    $0,$0
*
* WRITING TO DOS 3.3 FILE
*
:WDOS33     LDA   #$02
            STA   RCMND                ;CMD = WRITE
            LDA   DATADR
            STA   RPAGE
            LDA   RELCNT
            BNE   :WRMORE
            JMP   :WDNOMO
*
:WRMORE     LDA   :DTSP                ;NEED NEW
            BNE   :WRITE               ;TSLIST?
            JSR   :DOTSL
*
:WRITE      LDA   :INDEX
            BIT   PDOS
            BPL   :NOSHFT              ;SRC = DOS
            LSR
:NOSHFT     TAX
            LDA   RBLKL,X
            SEC
            SBC   RBLKL-1,X
            TAY
            LDA   RBLKH,X
            SBC   RBLKH-1,X
            BNE   :RANDOM              ;RANDOM
            CPY   #2
            BCC   :NOTRND
:RANDOM     DEY
            CPY   #$FF
            BNE   :RAND00
            SEC
            SBC   #1
:RAND00     STY   :RANDL
            BIT   PDOS
            BPL   :RAND0               ;SRC = DOS
            ASL   :RANDL
            ROL
:RAND0      STA   :RANDL+1
            LDA   #0
            STA   :RANDL+2
            BIT   PDOS                 ;2/16/87
            BPL   :RAND1               ;SRC = DOS  2/16/87
            LDA   :INDEX
            AND   #1
            BNE   :NOTRND
:RAND1      LDA   FILELN+1
            SEC
            SBC   :RANDL
            STA   FILELN+1
            LDA   FILELN+2
            SBC   :RANDL+1
            STA   FILELN+2
            ASL   :RANDL
            ROL   :RANDL+1
            ROL   :RANDL+2
            LDA   :RANDL
            CLC
            ADC   :DTSP
            STA   :RANDL
            BCC   :RAND2
            INC   :RANDL+1
            BNE   :RAND2
            INC   :RANDL+2
:RAND2      LDA   :RANDL+1
            SEC
            SBC   #1
            BCS   :RAND4
            DEC   :RANDL+2
            BMI   :RAND5
:RAND4      STA   :RANDL+1
            LDA   :RANDL
            CLC
            ADC   #$0C
            STA   :RANDL
            BCC   :RAND3
            INC   :RANDL+1
:RAND3      JSR   :DOTSL
            JMP   :RAND2
:RAND5      LDA   :RANDL
            STA   :DTSP
*
:NOTRND     JSR   :ALLOC
            LDX   :DTSP
            LDA   TRACK
            STA   DSTTSL,X             ;POKE TRACK
            STA   RTRACK               ;& SECTOR INTO
            LDA   SECTOR               ;TSLIST & RWTS
            STA   DSTTSL+1,X           ;INFO
            STA   RSECTR
            JSR   DORWTS               ;WRITE IT
            INC   RPAGE
:NEXTWR     INC   :DTSP                ;NEXT TS PAIR
            INC   :DTSP
:NXTWR2     LDA   FILELN+1
            BNE   :NXTWR0
            DEC   FILELN+2
:NXTWR0     DEC   FILELN+1             ;DEC BY 256
            INC   :INDEX
            LDA   :INDEX
            BIT   PDOS                 ;SRC = DOS
            BPL   :NEXTWR1
            LSR
:NEXTWR1    CMP   RELCNT
            BCS   :WDNOMO
            BIT   PDOS
            BPL   :NXTWR3
            LDA   FILELN+1
            ORA   FILELN+2
            BEQ   :WDNOMO
:NXTWR3     JMP   :WRMORE
*
* WRITTEN EVERTHING UP TO RELCNT
*
:WDNOMO     LDA   EOF                  ;END OF FILE?
            BEQ   :WROUT
:WREND      LDA   :TSTRK               ;WRITE FINAL
            STA   RTRACK               ;T/S LIST
            LDA   :TSSECT              ;SECTOR TO
            STA   RSECTR               ;DISK
            LDA   #>DSTTSL
            STA   RPAGE
            JSR   DORWTS
*
* MOVE LAST 2 OR 4 BYTES OF BUFFER
* TO START OF BUFFER IN CASE THEY
* DIDN'T GET WRITTEN OUT
* (BASIC OR BINARY FILES)
* THESE BYTES ARE ACTUALLY RIGHT ABOVE
* HIMEM
*
:WROUT      LDA   :LASTFLG
            BEQ   :SKIP4
            LDY   RPAGE
            STY   POINT2+1
            LDY   #0
            STY   POINT2
:LAST4LP    LDA   (POINT2),Y
            PHA
            INY
            CPY   :LASTFLG
            BCC   :LAST4LP
            LDY   DATADR
            STY   POINT2+1
            LDY   :LASTFLG
            DEY
:LPLAST4    PLA
            STA   (POINT2),Y
            DEY
            BPL   :LPLAST4
:SKIP4      LDA   :POINT2
            STA   POINT2
            LDA   :POINT2+1
            STA   POINT2+1
            LDA   :FSIZE
            LDY   #$21
            STA   (POINT2),Y
            INY
            LDA   :FSIZE+1
            STA   (POINT2),Y
            RTS
*
:LASTFLG    DB    $0
:FSIZE      DB    $0,$0
:RANDL      DB    $0,$0,$0
*
:DOTSL      LDA   :TSTRK               ;SET T&S TO
            STA   RTRACK               ;WRITE OLD
            LDA   :TSSECT              ;LIST
            STA   RSECTR
            JSR   :ALLOC               ;ALLOCATE NEW
            LDA   TRACK                ;& PUT INTO
            STA   DSTTSL+1             ;LINK TO NEXT
            STA   :TSTRK               ;LIST & SAVE
            LDA   SECTOR
            STA   DSTTSL+2
            STA   :TSSECT
            LDA   RPAGE
            PHA
            LDA   #>DSTTSL             ;SET ADDR
            STA   RPAGE
            JSR   DORWTS               ;WRITE TSLIST
            PLA
            STA   RPAGE                ;RESTORE RPAGE
            JSR   :NEWTSL              ;ZERO TSLIST
            LDA   #$0C                 ;RESET TS
            STA   :DTSP                ;POINTER
            RTS
*
* PREPARE NEW TSLIST SECTOR
:NEWTSL     LDA   #$00
            TAX
:ZERO       STA   DSTTSL,X
            INX
            BNE   :ZERO
            CLC
            LDA   :OFFSET
            STA   DSTTSL+5
            ADC   #$7A
            STA   :OFFSET
            LDA   :OFFSET+1
            STA   DSTTSL+6
            ADC   #$00
            STA   :OFFSET+1
            RTS
*
* ALLOCATE A SECTOR ON DEST. DISK
* SECTOR IN *TRACK, *SECTOR
:ALLOC      DEC   SECTOR
            BPL   :OK
            JSR   :NEWTRK
:OK         LDA   SECTOR               ;MAKE BITMASK
            JSR   DOMASK
            LDA   TRACK                ;FIND TRACK
            ASL                        ;BITMAP
            ASL
            ADC   #$38                 ;OFFSET IT?
            TAX
            LDA   VTOC2,X              ;MASK BITMAP
            AND   BITMSK
            STA   :TEMP
            LDA   VTOC2+$1,X
            AND   BITMSK+1
            ORA   :TEMP                ;SECTOR FREE?
            BEQ   :ALLOC
            LDA   BITMSK               ;REVERSE MASK
            EOR   #$FF                 ;FOR USED
            AND   VTOC2,X              ;SECTOR AND
            STA   VTOC2,X              ;WRITE INTO
            LDA   BITMSK+1             ;VTOC TO
            EOR   #$FF                 ;ALLOCATE IT
            AND   VTOC2+$1,X
            STA   VTOC2+$1,X
            INC   :FSIZE
            BNE   :ALCDNE
            INC   :FSIZE+1
:ALCDNE     RTS
*
* ALLOCATE NEW TRACK FOR ALLOC
:NEWTRK     CLC
            LDA   VTRACK               ;NEXT TRACK TO
            ADC   VDIR                 ;ALLOCATE.
            BNE   :TRYOVER             ;AT TRACK 0?
            LDA   #$01                 ;GO TRACK $12,
            STA   VDIR                 ;FORWARD
            LDA   #$11
            BNE   :FULLCHK
:TRYOVER    CMP   #$23                 ;AT TRACK $23?
            BCC   :FULLCHK
            LDA   #$FF                 ;GO TRACK $10,
            STA   VDIR                 ;BACKWARD
            LDA   #$10
:FULLCHK    CMP   :TRK1ST
            BEQ   :DISKFUL
            STA   VTRACK               ;SAVE TRACK
            STA   TRACK
            ASL                        ;FIND BITMAP
            ASL
            ADC   #$38
            TAX
            LDA   VTOC2,X              ;ANY FREE
            ORA   VTOC2+$1,X           ;SECTORS?
            BEQ   :NEWTRK
            LDA   NSECTS               ;RESET # OF
            STA   SECTOR               ;SECTORS TO GO
            RTS
*
:DISKFUL    LDA   #$48
:FULLERR    JMP   ERROU1
*
*
:ENDCAT     DB    $0
:TEMP       DB    $0
:OFFSET     DB    $0,$0
:DTSP       DB    $0
:TSTRK      DB    $0
:TSSECT     DB    $0
:TRK1ST     DB    $0
:COPYOPT    DB    $0
*
*
*
* CHECK IF WE ARE DIVING IN TO OR OUT
* OF THE STARTING DIRECTORY. IF SO,
* RESTORE OR SAVE *STATUS, *CBYTE,
* *CSECTR,*FILNUM
*
DIVECK      BCS   :GOOUT
            LDA   SP
            CMP   #1
            BNE   :DVCK00
            LDX   #>STATUS
            LDY   HIMEM
            DEY
            DEY
            DEY
            STY   :MYHI
            LDA   FILNUM
            STA   :SAVE1
            LDA   #4
            STA   TOPDIF
            JSR   :DVCK0
            LDA   HIMEM                ;8/27/86
            JSR   SETHIM               ;8/27/86
:DVCK00     JMP   :DVINIT
*
:GOOUT      LDA   SP
            BNE   :DVINIT
            JSR   :DVINIT
            LDX   :MYHI
            LDY   #>STATUS
            LDA   :SAVE1
            STA   FILNUM
            LDA   #0
            STA   TOPDIF
*
:DVCK0      STX   POINT+1
            STY   MESPNT+1
            LDY   #0
            STY   MESPNT
            STY   POINT
            LDX   #3
:DCKLP      LDA   (POINT),Y
            STA   (MESPNT),Y
            INY
            BNE   :DCKLP
            INC   POINT+1
            INC   MESPNT+1
            DEX
            BNE   :DCKLP
            RTS
:SAVE1      DB    $0
:MYHI       DB    $0
*
*
* INITIALIZE THINGS AFTER DIVING IN TO
* OR OUT OF A SUBDIRECTORY
*
:DVINIT     LDA   CURR
            PHA
            JSR   INITCD
            PLA
            STA   CURR
            JSR   RDACNT
            LDA   NACTIV
            STA   FILNUM
            SEC
            BEQ   :DVINT1              ;NO FILES
            LDX   #0
:CFLP2      INX
            TXA
            STA   STATUS-1,X
            CPX   NACTIV
            BCC   :CFLP2
            CLC
:DVINT1     RTS
*
*
*
*
* DOING DISK SWAPPING: CLOSE TARGET
* FILE
*
GOCLS       BIT   DOSNOW
            BPL   :DOS33
            LDA   REF
            STA   GCLST+1
            JSR   DOMLI                ;GET MARK
            DB    $CF
            DW    GCLST
            JMP   CLOSE
*
:DOS33      JMP   WRCAT2
*
GCLST       DB    $2,$0,$0,$0,$0

*
REOPEN      BIT   DOSNOW
            BPL   :OUT                 ;DOS 3.3
            JSR   DOMLI                ;OPEN
            DB    $C8
            DW    :ROLST
            LDA   :ROLST+5
            STA   REF
            STA   GCLST+1
            JSR   DOMLI                ;SET MARK
            DB    $CE
            DW    GCLST
:OUT        RTS
:ROLST      DB    $3
            DW    FILE
            DW    FILBUF
            DB    $0
*
REF         DB    $0
*
*
SETHIM      SEC
            SBC   DATADR
            AND   #$FE
            CLC
            ADC   DATADR
            SEC
            SBC   TOPDIF               ;0 OR 3
            STA   HIMEM
            RTS
*
PRFILE      LDY   #0
            LDA   FILE+$1,Y
            ORA   #$80
            JSR   PCOUT
            INY
            CPY   FILE
            BCC   PRFILE+2
            RTS
*
*
* CONVERT TEXT FILE: DOS <--> PRODOS
*
* IF PDOS <> SDOS, THE TOGGLE MSB OF
* NON-ZERO BYTES IN READ BUFFER
*
TXTCNV      LDA   SDOS
            EOR   PDOS
            BEQ   :NOTTXT              ;SAME DOS
            JSR   CURPNT
            BIT   PDOS
            BPL   :DOS33
            LDY   #$10
            LDA   (POINT),Y
            CMP   #$04
            JMP   :CKTXT
*
:DOS33      LDY   #2
            LDA   (POINT),Y
            AND   #$7F
:CKTXT      BNE   :NOTTXT
            LDA   RPAGE
            STA   :RPG
            LDA   RADR
            PHA
            LDA   DATADR
            STA   RPAGE
            LDY   #0
            STY   RADR
:LOOP       LDA   (RADR),Y
            BEQ   :SKIP
            AND   #$7F
            BIT   PDOS
            BPL   :SKIP0
            ORA   #$80
:SKIP0      STA   (RADR),Y
:SKIP       INY
            BNE   :LOOP
            INC   RPAGE
            LDA   RPAGE
            CMP   :RPG
            BCC   :LOOP
            PLA
            STA   RADR
:NOTTXT     RTS
:RPG        DB    $0
