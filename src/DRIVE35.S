            TYP   BIN
            DSK   ../build/DRIVE35.O
            PUT   VARS
            PUT   ../build/MESSAGES.VARS
            ORG   MESSAGESEND

*
*
* Called after the format, and at Reset time.
FMTFIX      LDA   FMT400K     ;Need to fix back to 800K format?
            BPL   :SETSIDQ
            LDA   SUNIT       ;Yes: 3.5-inch drive?
            JSR   SET35
            BCS   :SETSIDQ    ;->No: RTS.
            SEC               ;Yes:
* fall through to SETSIDS to reset 800K format.
*
*
* Pass in EQ = Unidisk 3.5
*         NE = Apple 3.5 drive
*         CC = set 400K format
*         CS = restore 800K format
SETSIDS     BEQ   :UNISIDE
            LDA   #0          ;Apple 3.5: Convert carry to 00 or 80
            ROR
            STA   :ASIDES     ;Save in sides value in table
            JSR   :JMPSLOT    ;Make the SetSides control call.
            DB    $04
            DW    :ASIDLST
            RTS
:UNISIDE    LDA   #0          ;Unidisk: Convert carry to 00 or 80
            ROR
            STA   :USIDES
            JSR   :JMPSLOT    ;Make the SetAddress control call.
            DB    $04
            DW    :SADRLST
            BCS   :SETSIDQ
            JSR   :JMPSLOT    ;Make the Download control call.
            DB    $04
            DW    :DNLDLST
:SETSIDQ    RTS
*
:JMPSLOT    JMP   (SLOTPTR)
*
:ASIDLST    DB    3
:AUNIT      DS    1
            DW    :SIDECTL
            DB    9           ;SetSides command
*
:SIDECTL    DB    1           ;<-not 4 as manual says....
            DB    00
:ASIDES     DS    1
*
:SADRLST    DB    3
:U1UNIT     DS    1
            DW    :SADRCTL
            DB    6           ;SetAddress command
*
:SADRCTL    DW    $0002
            DW    $0063
*
:DNLDLST    DB    3
:U2UNIT     DS    1
            DW    :DNLDCTL
            DB    7           ;Download command
*
:DNLDCTL    DW    $0001
:USIDES     DS    1
*
UNIFLG      DS    1
*
*[4am] Certain SmartPort devices (e.g. Superdrive)
* set an internal 'busy' status on entry and
* clear it on exit to avoid re-entry, but if
* the user presses Ctrl-Reset during a disk
* operation (such as format) then the 'busy'
* status is never reset and the device thinks
* it is 'busy' forever. This condition is checked
* inside a ROM subroutine which manipulates the
* stack to return immediately to the non-ROM
* caller with an error. As long as the ROM was
* initially called via a JSR to the ProDOS block
* driver entry point, this works, in the sense
* that it returns to the non-ROM caller with C=1
* lets the caller handle that. But if the ROM
* was called via the SmartPort entry point, the
* error handler returns without skipping the
* SmartPort parameters after the JSR, and
* execution continues (incorrectly) at the first
* SmartPort parameter.
* In other words, it is not actually safe to issue
* any SmartPort call on a Superdrive without first
* detecting if it is perma-'busy', because even
* doing a SmartPort RESET Control call might fail
* in a way that leads execution to non-code and
* crashes.
* To detect this perma-'busy' state, we issue an
* ONLINE MLI command on the unit. If it succeeds
* (C=0) then we're OK. If it fails, we check if
* the failure code is 0x01, which technically means
* 'you passed an invalid MLI command' but we know
* that's not true (ONLINE is a valid MLI command)
* so it must mean that we hit the broken fallback
* in the ROM which sets A=01 on exit.
*
BROKEN35    JSR   MLI
            DB    $C5
            DW    FFONLINE
            BCC   :CCQ
            CMP   #$01
            BEQ   :CSQ
:CCQ        CLC
            RTS
:CSQ        SEC
            RTS
FFONLINE    DB    $2
FFUNIT      DB    $0
            DW    VOLNMS
*
*
*
* Pass unit # in Acc.
* Returns CLC if it's a 3.5 drive
*         SEC if not.
*  If CLC, EQ if Unidisk 3.5
*          NE if Apple 3.5 drive
* Also sets up unit numbers in Smartport-call tables.
*
SET35       STA   FFUNIT
            LSR               ;0dss s000
            LSR               ;00ds ss00
            LSR               ;000d sss0
            TAX
            LDA   DEVADR+1,X  ;Get driver address.
            CMP   #$C1        ;Is it in ROM?
            BCC   :SET35NO
            CMP   #$C8
            BCS   :SET35NO
            STA   SLOTPTR+1   ;Yes: Pt to ROM.
            LDA   #0
            STA   SLOTPTR
            LDY   #$07
            LDA   (SLOTPTR),Y  ;Is it a Smartport card?
            BNE   :SET35NO    ;->No.
            LDY   #1          ;Yes: Convert the ProDOS unitnum (index)
            TXA               ; into a Smartport unitnum.
            CMP   #$10        ; (check drive 1/drive 2)
            BCC   :MKUNIT1
            INY
:MKUNIT1    LSR
            EOR   SLOTPTR+1   ; (ProDOS unitnum match real slot #?)
            AND   #$07
            BEQ   :MKUNIT2
            INY               ; (No: inc Smartport unitnum by 2.)
            INY
:MKUNIT2    STY   :UNITNUM    ;Set up unitnum for all Smartport calls.
            STY   :AUNIT
            STY   :U1UNIT
            STY   :U2UNIT
            LDA   DEVADR,X    ;Get the Smartport entry pt.
            CLC
            ADC   #3
            STA   SLOTPTR
            JSR   BROKEN35
            BCS   :SET35NO
            JSR   :JMPSLOT    ;Call to get the status for this device.
            DB    $00
            DW    :UNITLST
            BCS   :SET35NO
            LDA   :STATLST+$15  ;Is it a 3.5 drive?
            CMP   #1
            BNE   :SET35NO    ;->No.
            LDA   :STATLST+$16  ;Yes: Unidisk 3.5 or Apple 3.5?
            CLC               ;(returns EQ/NE)
            RTS
:SET35NO    SEC
            RTS
*
:UNITLST    DB    3
:UNITNUM    DS    1
            DW    :STATLST
            DB    3           ;return Device info block command
*
            DUM   $800        ;(not used during copy)
:STATLST    DS    $19
            DEND
*
DRIVE35END
