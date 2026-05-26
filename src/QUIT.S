            TYP   BIN
            DSK   ../build/QUIT.O
            PUT   VARS
            PUT   ../build/PRODOS.VARS
            PUT   ../build/ERRORS.VARS
            ORG   ERRORSEND

QUIT        LDX   CHOOZOPT
            BEQ   :QUIT1
            DEX
            BEQ   :MONITOR
            ;JMP   $FAA6      ;fails on Laser 128 (uses F9C8),
                              ;Laser 128EX (uses F9CD),
                              ;Franklin Ace (uses FB11),
                              ;Apple II non-autostart ROM (no
                              ;reboot routine at all), so the
                              ;most compatible solution is to
            INC   $03F4       ;mess up page 3 reset checksum
            JMP   ($FFFC)     ;and jump to ROM reset vector
:MONITOR    JMP   $FF59
*
:QUIT1      LDY   #0
            TYA
:QUITZZ     STA   $280,Y
            INY
            BPL   :QUITZZ
*
            LDA   ISAUX
            CMP   #$FF
            BNE   :QUIT2
*
* /RAM HAS BEEN DISCONNECTED, FORMAT IT
*
            LDA   #$B0
            JSR   UNTDEV
            LDA   GODEV+2     ;Did we actually find /RAM to format?
            BEQ   :QUIT2      ;No->don't call
            JSR   SPLFRM      ;Yes->format it
:QUIT2
            INC   $3F4
            LDA   #0          ;Fix cursor position in Quit code(?).
            STA   CH
            JSR   MLI
            DB    $65
            DW    :QUTLST
:QUTLST     DB    $4
*
QUITEND
