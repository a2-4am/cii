***********************************
*            QUIT                 *
***********************************
*
*
QUIT        JSR   TOP1
*
            LDY   #0
            TYA
:QUITZZ     STA   $280,Y
            INY
            BPL   :QUITZZ
*
            LDA   #MQUITOPT
            JSR   PRINT
:QUIT00     INC   $3F4        ;Mess up vector so RESET will reboot
            JSR   GETKEY      ; on Autostart Apple II Plus.
            DEC   $3F4        ;Fix RESET vector again.
            CMP   #"M"
            BNE   :QUIT0
            JMP   $FF69
:ESC        JMP   FILER
*
:QUIT0      CMP   #"Q"
            BEQ   :QUIT1      ;QUIT TO PRODOS
            CMP   #$8D
            BEQ   :QUIT1
            CMP   #$9B
            BEQ   :ESC
            JSR   BELL
            JMP   :QUIT00
*
*
:QUIT1      LDA   ISAUX
            CMP   #$FF
            BNE   :QUIT2
*
* /RAM HAS BEEN DISCONNECTED, FORMAT IT
*
            LDA   #$B0
            JSR   UNTDEV
            LDA   GODEV+2     ;Did we actually find /RAM to format?
            BEQ   :QUIT2      ;No->don't call
            JSR   SPLFRM
:QUIT2      JSR   MOVPFX
            JSR   SETBUT
            INC   $3F4
            LDA   #0          ;Fix cursor position in Quit code(?).
            STA   CH
            JSR   MLI
            DB    $65
            DW    :QUTLST
:QUTLST     DB    $4
            DB    $0,$00,$00,$0,$00,$00
*
MOVPFX      LDY   #$40
:MLOOP      LDA   BTPFX-1,Y
            STA   PFX-1,Y
            DEY
            BNE   :MLOOP
            STY   $280
            RTS
