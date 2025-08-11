            TYP   $06
            DSK   ../build/OBJ.BOOTSEC
            PUT   VARS
            DUM   *
BOOTBEG     DB    0
            DEND
            ORG   $800
*
* NO-BOOT CODE FOR FORMATTED
* & 'DELETED' DISK (WATCH CODE IN
* FORMAT ROUTINE)
*
            DB    $01
            LDX   $2B         ;MOTOR OFF
            LDA   $C088,X
            TXA               ;GET SLOT #
            LSR
            LSR
            LSR
            LSR
            ORA   #$C0        ;POKE SLOT ADDR
            STA   $11
            LDA   #$00
            STA   $10
            JSR   SETKBD
            JSR   SETVID
            JSR   INIT
            JSR   SETNOR
            JSR   HOME        ;PRINT MESSAGE
            LDX   #$00
:NEXTCHR    LDA   :TEXT,X
            BEQ   :ONWARD
            JSR   COUT
            INX
            BNE   :NEXTCHR
:ONWARD     JSR   RDKEY
            JMP   ($10)       ;REBOOT
*
:TEXT       DB    $8D,$8D,$8D,$8D,$8D
            ASC   "     THIS DISK HAS NO DOS TO BOOT."
            DB    $8D,$8D,$8D,$8D
            ASC   "        INSERT ANOTHER DISK AND"
            DB    $8D,$8D
            ASC   "        PRESS A KEY TO REBOOT.  "
            DB    0
*
            ORG
            DUM   *
BOOTEND     DB    0           ;where image of boot sector ends
            DEND
