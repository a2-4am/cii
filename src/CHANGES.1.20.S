*
*
* ******* RWTS START CODE *********
*
* START CORRECT DRIVE & SEEK TO TRACK.
* EXITS NE -> DRIVE IS SPINNING
*       EQ -> SOMETHING'S WRONG
*
* 1/20/89: For new UDC stand-alone card
*         If slot = 2 and there is no disk controller
*         in slot 2, then change slot to 5
*
:START      LDX   RSLOT
            CPX   #$20
            BNE   :START1
            LDA   $C201
            CMP   #$20
            BNE   :CHGSLOT
            LDA   $C203
            BNE   :CHGSLOT
            LDA   $C205
            CMP   #3
            BEQ   :START1
:CHGSLOT    LDX   #$50
            STX   RSLOT
:START1
*:START  LDX RSLOT        ;(Assuming drive isn't enabled yet,)
            LDA   $C08E,X     ;Change UDC mode to 5.25, in case it
            LDA   #0          ; was left in 3.5 mode.
            STA   $C08D,X     ; (shouldn't affect ordinary 5.25
            LDA   $C08C,X     ; controllers at all)


