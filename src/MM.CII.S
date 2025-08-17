            TYP   BIN
            DSK   ../build/MM.O
            PUT   VARS
            ORG   MMSPOT
MMBEG
RAMDCHK
            ORG   *+3
*
JSLOP       EQU   $22         ;JSL opcode
BCSOP       EQU   $B0         ;BCS opcode
*
* Equates now made in VARS file:
*SLOTPTR EQU   $04        ;2 bytes - temp ptr location
*TEMPCNT EQU   $04        ;2 bytes - same location, different use
*HANDLE EQU    $06        ;4 bytes - MUST NOT get clobbered!
*
* Copy II Plus Memory Manager
*
* Provides access to additional memory, if available, for fewer
* passes during copying, etc.  It uses any free GS memory, &
* any one on-line RAMdisk with the largest amount of free space.
* Behaves like a fast pseudo-file: It can read/write from any
* memory address, but always accesses multiples of 256 bytes.
*
* Open: MMCMD = 0, Call MM.  Returns size in pages in MMSIZE.
* Read or Write: MMCND = 1 or 2.  MMREQCNT = # of pages to
*  read/write, MMBUFFER = memory buffer address, MMMARK = page
*  offset within pseudo-file to do read/write, Call MM.
*  MMBUFFER & MMREQCNT are unchanged after the call.  MMMARK is
*  updated to point to the next page.  (Caller should make sure
*  that MMARK + MMREQCNT is not > MMSIZE.)
* Close: MMCMD = 3, Call MM.  Frees memory, closes RAMdisk
*  file, etc.
* Check size: Set up for Read or Write, MMCMD = 4, Call MM.
*  Returns error if request won't fit, no error if it will.
*
* C2+ MM entry points & parameters:
*
            JMP   RAMDCHK2    ;Jump to RAMdisk check
MM          JMP   MM2         ;Jump to memory manager
*
MMCMD       DS    1           ;0Open,1Read,2Write,3Close,4Check
MMREQCNT    DS    1           ;# of PAGES requested to read or write
MMBUFFER    DS    2           ;buffer ADDRESS (can start at any byte)
MMMARK      DS    2           ;current position in pseudo-file, in PAGES
MMSIZE      DS    2           ;size of pseudo-file, in PAGES (info only)
MMERRNUM    DS    1           ;error number if carry set
MMFNUM      DS    1           ;ProDOS unitnum of memory RAMdisk.
* Commands for MMCMD: (now in VARS file)
*MMOPEN      EQU   0
*MMREAD      EQU   1
*MMWRITE     EQU   2
*MMCLOSE     EQU   3
*MMCHECK     EQU   4
*
* Additional error numbers for MMERRNUM: (now in VARS file)
*OPENERR     EQU   $80           ;MM already open.
*SIZEERR     EQU   $81           ;Request exceeds end of memory.
*TRANSERR    EQU   $82           ;Not all requested bytes were transferred.
*HNDERR      EQU   $83           ;Handle in zero page invalid (overwritten!)
*NOMEMERR    EQU   $84           ;No memory found in OPEN call.
*
* Private stuff starts here:
*
MM2         PHA               ;Save regs
            STX   :XTEMP1
            STY   :YTEMP1
            STA   $CFFF       ;(<-UDC in a GS likes this)
            LDA   #0
            STA   MMERRNUM
            LDA   MMCMD       ;Get command
            CMP   #5
            BCS   :MMQ        ;(->bad command #)
            ASL
            TAX
            JSR   :MMJMP      ;Go do that command
            LDY   :YTEMP1     ;Restore regs
            LDX   :XTEMP1
            PLA
:MMQ        RTS
:MMJMP      LDA   :JMPTBL+1,X
            PHA
            LDA   :JMPTBL,X
            PHA
            RTS
:JMPTBL     DW    :OPEN-1
            DW    :RW-1
            DW    :RW-1
            DW    :CLOSE-1
            DW    :CHECK-1
*
:XTEMP1     DS    1
:YTEMP1     DS    1
*
* Check: Is the MM open?  Returns Acc nonzero=open, zero=closed.
:CHKOPEN    LDA   :HSIZE
            ORA   :HSIZE+1
            ORA   :FSIZE
            ORA   :FSIZE+1
            RTS
*
* OPEN the memory manager, getting RAMdisk space & free GS space
*
:OPEN       JSR   :CHKOPEN    ;Check for file already open.
            BEQ   :OPENOK     ;->It's not:you may proceed.
            LDA   #OPENERR    ;MM already open error.
            STA   MMERRNUM    ; (Original open info still intact.)
            SEC
            RTS
:OPENOK     LDA   #0
            STA   MMMARK
            STA   MMMARK+1
            STA   MMFNUM
            STA   :BIGFREE    ;(Assume no RAMdisk on-line for tests..)
            STA   :BIGFREE+1
            STA   :BIGDEV
* Look for the RAMdisk on-line with most free space:
*  Check each device in turn, go see if it's a RAMdisk,
*  delete any already existing scratchfile on it,
*  do GetFileInfo to find amount of total & used space,
*  figure amount of free space,
*  find the one with the most...
            LDA   #$00        ;Start with ProDOS unitnum 00 (silly)
:LOOKLP     STA   :DOSNUM     ;Set up this ProDOS unitnum
            CMP   #$B0        ;Is is slot 3 drive 2?
            BNE   :LOOKRAM    ;->No: Go see it's it's a RAMdisk.
            LDX   ISAUX       ;Yes: Check /RAM status:
            CPX   #$FE        ; Is it a BIG /RAM?
            BNE   :LOOKNXT    ;->No, so skip it.
:LOOKRAM    JSR   RAMDCHK2    ;See if this device is a RAMdisk.
            BCC   :LOOKNXT    ;->It's not.
            PHA               ;It is:Save GS fuddyduddy RAM status a moment.
            JSR   :MKNAME     ;Make a scratchfile pathname
            BCS   :LOOKNXT    ;(->error)
            JSR   MLI         ;Delete the file in case it's there.
            DB    $C1         ;DESTROY call
            DW    :DSTRLST    ;(Don't worry about delete errors!)
            LDA   :LENVOLN    ;Make the path just for the volumename.
            STA   :PATHBUF
            JSR   MLI         ;With that volume pathname, do a ProDOS
            DB    $C4         ;GET_FILE_INFO call
            DW    :GFILST     ; to get total & used space
            PLA               ;(Retrieve GS fuddyduddy status)
            BCS   :LOOKNXT    ;(->error)
            BEQ   :GETFUD     ;->Fuddyduddy: get realistic RAMdisk size.
            LDA   :AUXTYPE    ;Not GS fuddyduddy: Trust the total size
            LDX   :AUXTYPE+1  ; told by ProDOS.
            JMP   :FINDFRE    ;& go find free space.
:GETFUD     CLC               ;GS fuddyduddy RAMdisk. ProDOS's total
            XCE               ; space on disk can't be trusted, so
            REP   $30         ; get GS minimum RAMdisk size from
            MX    %00         ; battery RAM instead...
            PEA   $0000       ; -resultspace
            PEA   $0036       ; -parameter for min RAMdisk size
            LDX   #$0C03      ;_ReadBParam
            DB    JSLOP,$00,$00,$E1
            PLA               ;Get # of 32K bytes.
            LDX   #6          ;Shift #-of-32K-bytes value left 6 times
:FUDLP      ASL               ; to get # of ProDOS blocks that
            DEX               ; represents.
            BNE   :FUDLP
            XBA               ;Xreg gets high byte.
            TAX
            XBA               ;Acc keeps low byte.
            SEP   $30         ;Back to emulation.
            MX    %11
            SEC
            XCE
:FINDFRE    SEC               ;Now Then...
            SBC   :USED       ;Subtract amount of used space from "total"
            STA   :FREE       ; to find amount of free space
            TXA
            SBC   :USED+1
            STA   :FREE+1
            BCC   :LOOKNXT    ;(->"trusted" total already < amount used)
            LDA   :BIGFREE    ;How does that compare with the
            CMP   :FREE       ; biggest free space so far?
            LDA   :BIGFREE+1
            SBC   :FREE+1
            BCS   :LOOKNXT    ;->not bigger.
            LDA   :FREE       ;Bigger!:
            STA   :BIGFREE    ; Save new biggest free value
            LDA   :FREE+1
            STA   :BIGFREE+1
            LDA   :DOSNUM     ; & its ProDOS unitnum
            STA   :BIGDEV
:LOOKNXT    LDA   :DOSNUM     ;Continue on to next device to search
            CLC
            ADC   #$10
            BEQ   :CHKDEV
            JMP   :LOOKLP
*
:CHKDEV     LDA   :BIGDEV     ;Did we get a RAMdisk?
            BEQ   :LOOKGS     ;->No:go look for GS memory.
:GOTRAM     STA   :DOSNUM     ;Yes:
            LDA   :BIGFREE    ;If this RAMdisk doesn't have at
            CMP   #40         ; least 40 blocks (20K) free,
            LDA   :BIGFREE+1
            SBC   #0
            BCC   :LOOKGS     ;->then forget it & go look for GS memory.
            JSR   :MKNAME     ;Make the scratchfile pathname again
            BCS   :LOOKGS     ;(->error)
            JSR   MLI
            DB    $C0         ;CREATE the file
            DW    :CREALST
            BCS   :LOOKGS
            JSR   MLI
            DB    $C8         ;OPEN the file
            DW    :OPENLST
            BCS   :LOOKGS     ;(->Gotta destroy the file, too)
            LDA   :OPENREF
            STA   :SMREF      ;Copy the file refnum to the other
            STA   :FRWREF     ; paramblks that need it.
            STA   :CLOSREF
            SEC               ;Determine maximum size of RAMdisk file:
            LDA   :BIGFREE    ; High byte of volume free blocks is CLOSE TO
            SBC   :BIGFREE+1  ;   number of index blocks needed by a file
            STA   :FSIZE      ;   that will fill those free blocks,
            LDA   :BIGFREE+1  ; so subtract hibyte from total free blocks
            SBC   #0          ;   because those are needed as index blocks
            STA   :FSIZE+1
            SEC               ; Subtract a few more blocks for a little
            LDA   :FSIZE      ;  extra margin
            SBC   #5
            STA   :FSIZE
            BCS   :SETFSIZ
            DEC   :FSIZE+1
:SETFSIZ    ASL   :FSIZE      ; Number of pages := number of blocks times 2
            ROL   :FSIZE+1
            LDA   :DOSNUM     ;Tell the customer which ProDOS device
            STA   MMFNUM      ; this is.
*
* Now look for GS memory
*
:LOOKGS     SEC               ;Is this a GS?
            JSR   $FE1F       ;Go check.
            BCS   :OPENQ      ;->No, it's not. Go on empty-handed.
            CLC
            XCE               ;Go into native GS mode.
            REP   $30
            MX    %00
            PEA   $0000       ; -wordspace
            PEA   $1000       ; -IDTag specifies "application"
            LDX   #$2003      ;_GetNewID
            DB    JSLOP,$00,$00,$E1
            PLX
            BCS   :HOPNERR
            STX   :GSID       ;Save the ID value.
            LDX   #$1F02      ;_CompactMem to make big contigous space
            DB    JSLOP,$00,$00,$E1
            BCS   :HOPNERR
            PEA   $0000       ; -longspace
            PEA   $0000
            LDX   #$1C02      ;_MaxBlock to find size of that space
            DB    JSLOP,$00,$00,$E1
            PLA               ;Get result size
            PLX
            BCS   :HOPNERR
            BNE   :SIZEOK     ;(->high word (Xreg) nonzero)
            CMP   #$8000      ;Is size >= $008000?
            BCC   :HOPNERR    ;->No: not enough free memory.
:SIZEOK     AND   #$FF00      ;Make a page multiple.
            SEC
            SBC   #$3000      ;Leave 12K for your GS friends....
            BCC   :SAVESIZ
            DEX
:SAVESIZ    STA   :HSIZEQ     ;& keep the rest for yourself (tentatively).
            STX   :HSIZEQ+2   ;(Damned 2-byte mode!)
            PEA   $0000       ; -longspace
            PEA   $0000
            PHX               ; -BlockSize
            PHA
            LDA   :GSID       ; -UserID
            PHA
            PEA   $0008       ; -attributes (no special memory)
            PEA   $0000       ; -locationPtr (not used)
            PEA   $0000
            LDX   #$0902      ;_NewHandle to allocate the memory
            DB    JSLOP,$00,$00,$E1
            PLA               ;Get result handle
            PLX
            BCS   :HOPNERR    ;->Oops, error!
            STA   HANDLE      ;No error: save handle.
            STX   HANDLE+2
            BRA   :HOK
:HOPNERR    STZ   :HSIZE      ;(word) Error, so size of GS memory is zero!
:HOK        SEP   $30         ;Come home to your safe 8-bit world.
            MX    %11
            SEC
            XCE
*
* Figure total memory manager size & exit.
:OPENQ      JSR   :OPENSIZ    ;Fill MMSIZE field from FSIZE & HSIZE
            JSR   :CHKOPEN    ;Did we really get any memory?
            CLC
            BNE   :OPENQQ     ;->Yes: so it's okay.
            LDA   #NOMEMERR   ;No: Flag a no-memory error.
            STA   MMERRNUM
            SEC
:OPENQQ     RTS

*  (also called as a subroutine by :CHECK routine)
:OPENSIZ    CLC
            LDA   :FSIZE
            ADC   :HSIZE
            STA   MMSIZE
            LDA   :FSIZE+1
            ADC   :HSIZE+1
            STA   MMSIZE+1
            LDA   #0
            STA   MMERRNUM
            CLC
            RTS
*
*
* Make a pathname for the memory manager scratchfile
*  on the specified ProDOS device.
* Put ProDOS unitnum in :DOSNUM.
* Call :MKNAME. CS=error.
* :PATHBUF gets pathname (with length set for entire file path)
* :LENVOLN gets length of just volume path.
* :LENFILN gets length of entire file path. You can substitute!
* (All regs destroyed)
:MKNAME     JSR   MLI         ;Get RAMdisk's volume name into :ONLNBUF.
            DB    $C5         ;ON_LINE (again, since we may have
            DW    :ONLNLST    ; lost the name looking for other RAMdisks)
            BCS   :MKNAMEQ
            LDA   :ONLNBUF    ;Get rid of hi nibble to leave
            AND   #$0F        ; just length of volume name.
            STA   :ONLNBUF
            LDX   #1          ;Append that name onto a slash
            LDY   #1          ; that's in PATHBUF
:SLSH2LP    LDA   :ONLNBUF,Y
            STA   :PATHBUF+1,X
            INX
            INY
            CPY   :ONLNBUF
            BEQ   :SLSH2LP
            BCC   :SLSH2LP
            STX   :LENVOLN    ;Save length of path so far (volume)
            LDY   #1          ;Append the scratch filename
:FPATHLP    LDA   :JUSTNAM,Y  ; onto this pathname to make a complete
            STA   :PATHBUF+1,X  ; file pathname.
            INX
            INY
            CPY   :JUSTNAM
            BEQ   :FPATHLP
            BCC   :FPATHLP
            STX   :LENFILN    ;Save length of full file path.
            STX   :PATHBUF    ;& that's length of :PATHBUF for now.
            CLC
:MKNAMEQ    RTS
*
:ONLNLST    DB    2           ;ON_LINE command list for :MKNAME
:DOSNUM     DS    1           ;requested ProDOS unit num
            DW    :ONLNBUF    ;address of info buffer
:ONLNBUF    DS    16
*
:GFILST     DB    $A          ;GET_FILE_INFO command list
            DW    :PATHBUF    ;address of pathname
            DS    1           ;access
            DS    1           ;file type
:AUXTYPE    DS    2           ;aux type = total space on disk
            DS    1           ;storage type
:USED       DS    2           ;blocks used
            DS    2           ;mod date
            DS    2           ;mod time
            DS    2           ;create date
            DS    2           ;create time
*
:CREALST    DB    7           ;CREATE command list
            DW    :PATHBUF    ;address of pathname
            DB    $C3         ;access (normal)
            DB    $06         ;file type (BIN)
            DW    $0800       ;aux type (start address = $0800?)
            DB    $01         ;storage type (standard)
            DW    0           ;create date
            DW    0           ;create time
*
:OPENLST    DB    3           ;OPEN command list
            DW    :PATHBUF    ;address of pathname
            DW    MMIOBUF     ;<--where?
:OPENREF    DS    1           ;file refnum
*
* other vars for MM:OPEN, etc.
:DEVIDX     DS    1           ;Temp counter for devices to check
:FREE       DS    2           ;# of free blocks on a volume
:BIGFREE    DS    2           ;biggest # of free blocks found so far
:BIGDEV     DS    1           ;ProDOS unitnum of BIGFREE device
:PATHBUF    DS    1           ;space for string length
            DB    '/'         ;slash in front of volume name
            DS    32          ;space for rest of path
:LENVOLN    DS    1
:LENFILN    DS    1
:JUSTNAM    STR   '/MMSCRATCH'  ;slash & filename follow volume name
:HSIZEQ     DS    1           ;low BYTE of size, for GS word-nasties
:HSIZE      DS    2           ;in PAGES
            DS    1           ;4th byte of size, for GS
:HCOUNT     DS    1
:HBUF       DS    2
:HOFFSET    DS    2
:GSID       DS    2
:FSIZE      DS    2
*
*
* Read or Write command handling:
*
:RW         JSR   :CHKOPEN    ;MM had better be open already.
            BNE   :RW2        ;->It is, go ahead.
            LDA   #OPENERR    ;It's not!  Return error
            STA   MMERRNUM
            SEC               ; & exit.
            RTS
:RW2        LDA   MMMARK      ;Is our starting mark either AT or
            CMP   :HSIZE      ; AFTER the end of the GS memory?
            LDA   MMMARK+1
            SBC   :HSIZE+1
            BCS   :RWDISK     ;->Yes: do RAMdisk only.
            LDA   MMBUFFER    ;No: will include GS memory.
            STA   :HBUF       ;Set buffer address for GS transfer.
            LDA   MMBUFFER+1
            STA   :HBUF+1
            LDA   MMMARK      ;Set the starting GS page offset from
            STA   :HOFFSET    ; the mark
            CLC
            ADC   MMREQCNT    ;& find the ending page offset from
            STA   TEMPCNT     ; the request count
            LDA   MMMARK+1
            STA   :HOFFSET+1
            ADC   #0
            STA   TEMPCNT+1
            LDA   :HSIZE      ;Is end of GS memory >= this offset?
            CMP   TEMPCNT     ; (offset is NOT > end of GS memory?)
            LDA   :HSIZE+1
            SBC   TEMPCNT+1
            BCC   :RWMIXED    ;->No:this is a mixed GS/RAMdisk access.
* GS access only:
            LDA   MMREQCNT
            STA   :HCOUNT     ;Set the # of pages for GS access.
            JSR   :HRW        ;Go do the GS access now.
            BCS   :RWERRCS
            BCC   :RWOKBRA    ;->always.
*
* RAMdisk-only access (mark starts after end of GS memory):
:RWDISK     LDA   MMBUFFER    ;Set buffer address for RAMdisk transfer.
            STA   :FBUF
            LDA   MMBUFFER+1
            STA   :FBUF+1
            SEC
            LDA   MMMARK      ;Set starting page offset for RAMdisk
            SBC   :HSIZE      ; transfer (mark - size of GS space)
            STA   :FOFFSET
            LDA   MMMARK+1
            SBC   :HSIZE+1
            STA   :FOFFSET+1
            LDA   :FOFFSET    ;Find ending page offset from the
            ADC   MMREQCNT    ; request count
            STA   TEMPCNT
            LDA   :FOFFSET+1
            ADC   #0
            STA   TEMPCNT+1
            LDA   :FSIZE      ;Is filesize >= this offset?
            CMP   TEMPCNT     ; (is offset NOT > filesize?)
            LDA   :FSIZE+1
            SBC   TEMPCNT+1
            LDA   #SIZEERR
            BCC   :RWERRQ     ;->No:you blew it, too big a request.
            LDA   MMREQCNT    ;Yes:OK. Set # of pages for RAMdisk access.
            STA   :FCOUNT
            JSR   :FRW        ;Go do the RAMdisk access.
:RWERRCS    BCS   :RWERRQ
:RWOKBRA    JMP   :RWOKQ
*
* Mixed GS & RAMdisk access (:HBUF, :HOFFSET already set up)
:RWMIXED    SEC
            LDA   :HSIZE      ;Set page count for GS portion: starting
            SBC   :HOFFSET    ; GS offset up to end of GS space
            STA   :HCOUNT
            LDA   MMBUFFER    ;Set starting buffer address for RAMdisk
            STA   :FBUF       ; portion of transfer
            CLC
            LDA   MMBUFFER+1  ; which is past the real buffer by as
            ADC   :HCOUNT     ; many pages as the GS.
            STA   :FBUF+1
            LDA   #0
            STA   :FOFFSET    ;Set starting offset for RAMdisk portion at
            STA   :FOFFSET+1  ; BEGINNING of RAMdisk
            SEC
            LDA   MMREQCNT    ;Set page count for RAMdisk portion
            SBC   :HCOUNT     ; as whatever portion of request count that
            STA   :FCOUNT     ; GS portion hasn't taken
            LDA   :FSIZE      ;Is file size >= count?
            CMP   :FCOUNT     ; (is count NOT > file size?)
            LDA   :FSIZE+1
            SBC   #0
            LDA   #SIZEERR
            BCC   :RWERRQ     ;->No:choke, gag.
            JSR   :HRW        ;Go do the GS access
            BCS   :RWERRQ
            JSR   :FRW        ;Go do the RAMdisk access
            BCS   :RWERRQ
*
:RWOKQ      CLC
            LDA   MMMARK      ;Update the user mark.
            ADC   MMREQCNT
            STA   MMMARK
            BCC   :QNOERR
            INC   MMMARK+1
:QNOERR     LDA   #0
            CLC
            DB    BCSOP       ;(BCS opcode)
:RWERRQ     SEC
            STA   MMERRNUM
            RTS
*
*
* RAMdisk access
:FRW        JSR   MLI
            DB    $CE         ;SET_MARK to starting offset for access
            DW    :SMLIST
            BCS   :FRWQ
            LDA   MMCMD       ;Read or Write?
            CMP   #MMWRITE
            BEQ   :FW         ;->Write.
            JSR   MLI         ;Read: do the
            DB    $CA         ;READ
            DW    :FRWLIST
            JMP   :FRWCHK
:FW         JSR   MLI         ;Do the
            DB    $CB         ;WRITE
            DW    :FRWLIST
:FRWCHK     BCS   :FRWQ
            LDA   :FCOUNT     ;Did actual count match file reqcount?
            EOR   :FTRANS
            CLC
            BEQ   :FRWQ
            LDA   #TRANSERR   ;(<-) No! my error number.
            SEC
:FRWQ       RTS
*
:SMLIST     DB    2           ;SET_MARK command list
:SMREF      DS    1           ;space for refnum
            DB    0           ;mark position on page boundary
:FOFFSET    DS    2           ;space for offset in pages

:FRWLIST    DB    4           ;READ & WRITE command list
:FRWREF     DS    1           ;space for refnum
:FBUF       DS    2           ;space for buffer addr
            DB    0           ;ReqCount low byte always zero
:FCOUNT     DS    1           ;space for ReqCount hi byte
            DS    1           ;Trans Count
:FTRANS     DS    1           ;returned hi byte trans count
*
*
* GS Read/write access:
*
:HRW        CLC               ;Go into native GS mode.
            XCE
            REP   $30
            MX    %00
            PEA   $0000       ; -longspace
            PEA   $0000
            LDA   HANDLE+2    ; -TheHandle
            PHA
            LDA   HANDLE
            PHA
            LDX   #$1802      ;_GetHandleSize just to see if the
            DB    JSLOP,$00,$00,$E1  ; handle is still valid!
            PLX               ;(discard result)
            PLX
            LDA   #HNDERR     ;Assume Handle-Invalid error.
            BCS   :HRWQ       ;->Carry set: there WAS an error.
            CLC               ;No error, handle good:
            LDA   :HOFFSET    ;To find where in GS memory to access
            XBA               ; add page offset * 256
            AND   #$FF00
            ADC   [HANDLE]    ; to where the handle points to.
            TAX
            LDA   :HOFFSET+1
            AND   #$00FF
            LDY   #2
            ADC   [HANDLE],Y
            TAY               ;Leave in Yreg & Xreg.
            LDA   MMCMD       ;Now then, is this a read or write?
            AND   #$00FF
            CMP   #MMWRITE
            BEQ   :HWRITE     ;->Write.
            PHY               ;Read: -SourcePtr is GS address from Xreg,Yreg.
            PHX
            PEA   $0000       ; -DestPtr (high word zero)
            LDA   :HBUF       ;   is buffer address.
            PHA
            BRA   :HMOVE      ;Go continue.
:HWRITE     PEA   $0000       ;Write: -SourcePtr (high word zero)
            LDA   :HBUF       ;   is buffer address.
            PHA
            PHY               ; -DestPtr is GS address from Xreg,Yreg.
            PHX
:HMOVE      PEA   $0000       ; -Count (high word zero)
            LDA   :HCOUNT
            XBA               ;   in pages * 256
            AND   #$FF00
            PHA
            LDX   #$2B02      ;_BlockMove
            DB    JSLOP,$00,$00,$E1
            LDA   #0          ;no error.
:HRWQ       SEP   $30         ;Back to emulation mode.
            MX    %11
            SEC
            XCE
            CLC
            TAX               ;Was there an error?
            BEQ   :HRWQQ      ;->No, return carry clear.
            SEC               ;Yes: Set carry.
:HRWQQ      RTS
*
*
* Close command handling:
*  (How to handle errors here?)
*
:CLOSE      JSR   :CHKOPEN    ;MM should be open if we're to close it.
            BNE   :CLOSE2     ;->Yes, it's open.
            LDA   #OPENERR    ;No, it's not.  Return error
            STA   MMERRNUM
            SEC               ; & exit.
            RTS
:CLOSE2     LDA   #0
            STA   :TEMPERR    ;(Assume no error,
            STA   :TEMPERR+1  ; 2-byte clear for GS)
            LDA   :FSIZE      ;Is there a RAMdisk file to close?
            ORA   :FSIZE+1
            BEQ   :CLOSGS     ;->No: go try closing GS memory.
            JSR   MLI         ;Yes:
            DB    $CC         ;CLOSE the file.
            DW    :CLOSLST
            BCC   :CLOSDEL    ;->no error.
            STA   :TEMPERR    ;Error: save this error number.
:CLOSDEL    JSR   MLI
            DB    $C1         ;DESTROY the closed file.
            DW    :DSTRLST
            BCC   :CLOSGS     ;->no error
            LDX   :TEMPERR    ;Error: was there already an error?
            BNE   :CLOSGS     ;->Yes: keep its number.
            STA   :TEMPERR    ;No: save this error number.
:CLOSGS     NOP
            LDA   :HSIZE      ;Is there any GS memory to close?
            ORA   :HSIZE+1
            BEQ   :CLOSQ      ;->No, all done.
            CLC               ;Yes: go to native mode.
            XCE
            REP   $30
            MX    %00
            LDA   HANDLE+2    ; -handle
            PHA
            LDA   HANDLE
            PHA
            LDX   #$1002      ;_DisposeHandle disposes the memory.
            DB    JSLOP,$00,$00,$E1
            BCC   :CLOSID     ;->no error.
            LDX   :TEMPERR    ;Error: was there already an error?
            BNE   :CLOSID     ;->Yes: keep its number.
            STA   :TEMPERR    ;No: Save this error number.
:CLOSID     LDA   :GSID       ; -IDTag
            PHA
            LDX   #$2103      ;_DeleteID
            DB    JSLOP,$00,$00,$E1
            BCC   :CLOSEMU    ;->no error
            LDX   :TEMPERR    ;Error: was there already an error?
            BNE   :CLOSEMU    ;->Yes: keep its number
            STA   :TEMPERR    ;No: Save this error number
:CLOSEMU    SEP   $30         ;Get back to emulation mode.
            MX    %11
            SEC
            XCE
:CLOSQ      LDA   #0
            STA   :FSIZE      ;Mark this baby as closed!
            STA   :FSIZE+1
            STA   :HSIZE
            STA   :HSIZE+1
            STA   MMSIZE
            STA   MMSIZE+1
            CLC
            LDA   :TEMPERR    ;Now set real (public) error flag
            BEQ   :CLOSQQ
            STA   MMERRNUM
            SEC
:CLOSQQ     RTS               ;& exit.
*
:CLOSLST    DB    1           ;CLOSE command list
:CLOSREF    DS    1           ;refnum of file to close
*
:DSTRLST    DB    1           ;DESTROY command list
            DW    :PATHBUF    ;path of file to destroy
*
:TEMPERR    DS    2           ;(2 bytes for GS native mode)
*
*
* Check command handler:
*
:CHECK      CLC               ;Find ending page offset for
            LDA   MMMARK      ; this hopeful request.
            ADC   MMREQCNT
            STA   TEMPCNT
            LDA   MMMARK+1
            ADC   #0
            STA   TEMPCNT+1
            JSR   :OPENSIZ    ;Go remake the MMSIZE field.
            LDA   MMSIZE      ;Is the MMSIZE >= page offset?
            CMP   TEMPCNT     ; (is page offset NOT > MMSIZE?)
            LDA   MMSIZE+1
            SBC   TEMPCNT+1
            BCC   :CHKERR     ;->No:the request won't fit.
            CLC               ;Yes it will: no error.
            RTS
:CHKERR     LDA   #SIZEERR    ;Error.
            STA   MMERRNUM
            SEC
            RTS
*
*-----------------------------------------------------
*
* RAMdisk check: Is the specified ProDOS device a RAMdisk?
* Pass ProDOS unitnum in Acc.  Returns CS=yes, CC=no.
* If a RAMdisk, EQ=GS fuddyduddy RAMdisk, NE=other RAMdisk.
* (Destroys Acc, preserves Xreg,Yreg)
*
RAMDCHK2    STX   :XTEMP2
            STY   :YTEMP2
            LSR               ;Convert ProDOS unitnum into index
            LSR               ; into globalpage device table.
            LSR
            TAX
            LDA   DEVADR+1,X  ;get hibyte of driver address
            CMP   #$FF        ;Is it in place for auxram RAMdisks?
            BEQ   :YESRAMD    ;->Yes: this is an auxram RAMdisk.(Acc)
            CMP   #$C1        ;No: Is it in the slot space?
            BCC   :NORAMD
            CMP   #$C8
            BCS   :NORAMD
            STA   SLOTPTR+1   ;Yes:Pt at it.
            LDA   #0
            STA   SLOTPTR
            LDY   #$07        ;Is this a Smartport device?
            LDA   (SLOTPTR),Y  ; (Is Cn07=0?)
            BNE   :NORAMD     ;->Nope.
            LDY   #$12        ;Yep: But is this a UDC card?
            LDA   (SLOTPTR),Y  ; (Cn12=4C?)
            CMP   #$4C
            BNE   :MKUNIT     ;->No.
            LDY   #0
            LDA   (SLOTPTR),Y  ; (Cn00=E5?)
            CMP   #$E5
            BEQ   :NORAMD     ;->Yes: It's not a RAMdisk.
:MKUNIT     LDY   #1          ;No, it might be: Convert the ProDOS
            TXA               ; unitnum (index) to a Smartport unitnum.
            CMP   #$10        ; (check drive 1/drive 2)
            BCC   :MKUNIT1
            INY
:MKUNIT1    AND   #$0F        ; (check slot)
            LSR
            EOR   SLOTPTR+1   ; (ProDOS unitnum match real slot #?)
            AND   #$0F
            BEQ   :MKUNIT2
            INY               ; (No: inc Smartport unitnum by 2.)
            INY
:MKUNIT2    STY   :UNITNUM
            LDY   #$FF        ;Now get the Smartport entry pt.
            LDA   (SLOTPTR),Y
            CLC
            ADC   #3
            STA   SLOTPTR
*
* RAMFactor incorrectly uses location $19 instead of #$19.
*  Here's the workaround. Make sure $19 isn't used for permanent
*  storage in an application.
*
            LDA   #$19
            STA   $19
*
            JSR   :JMPSLOT    ;Now get the status for this device
            DB    $00
            DW    :UNITLST
            BCS   :NORAMD
            LDA   :STATLST+$15  ; to see if it's a RAMdisk (TYPE=0)
            BNE   :NORAMD     ;->It's not.
            LDA   :STATLST+$01  ;It is, but does it have any size?!
            ORA   :STATLST+$02  ; (# of blocks > 0?)
            ORA   :STATLST+$03
            BEQ   :NORAMD     ;->No, so don't say it's a RAMdisk.
            LDA   :STATLST+$16  ;It has size. Is it a GS fuddyduddy RAMdisk?
            EOR   #$C0        ;(GS subtype ID) Acc=0 if so.
:YESRAMD    SEC               ;Set the carry to say it's a RAMdisk.
            BCS   :CHKRAMQ    ;->always.
:NORAMD     CLC               ;Not a RAMdisk. Clear the carry.
:CHKRAMQ    LDY   :YTEMP2     ;Go home.
            LDX   :XTEMP2
            ORA   #0          ;Set EQ/NE from Acc for GS RAMdisk test.
            RTS
*
:JMPSLOT    JMP   (SLOTPTR)
*
:UNITLST    DB    3           ;Smartport unit status command list
:UNITNUM    DS    1           ;requested unit number for status
            DW    :STATLST    ;address of status list
            DB    3           ;statcode = 3: return Device Info Block
*
:STATLST    DS    $19         ;Status list for Smartport status call
*
:XTEMP2     DS    1
:YTEMP2     DS    1
*
MMEND
            ORG
