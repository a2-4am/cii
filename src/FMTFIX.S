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
*
*
* Pass unit # in Acc.
* Returns CLC if it's a 3.5 drive
*         SEC if not.
*  If CLC, EQ if Unidisk 3.5
*          NE if Apple 3.5 drive
* Also sets up unit numbers in Smartport-call tables.
*
SET35       LSR               ;0dss s000
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

