*
* This source code is altered and is not the original version found on
* the Exomizer homepage.
*
* Original copyright statement follows:
*
* Copyright (c) 2002 - 2018 Magnus Lind.
*
* This software is provided 'as-is', without any express or implied warranty.
* In no event will the authors be held liable for any damages arising from
* the use of this software.
*
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
*
*   1. The origin of this software must not be misrepresented; you must not
*   claim that you wrote the original software. If you use this software in a
*   product, an acknowledgment in the product documentation would be
*   appreciated but is not required.
*
*   2. Altered source versions must be plainly marked as such, and must not
*   be misrepresented as being the original software.
*
*   3. This notice may not be removed or altered from any distribution.
*
*   4. The names of this software and/or it's copyright holders may not be
*   used to endorse or promote products derived from this software without
*   specific prior written permission.
*
* -------------------------------------------------------------------
* zero page addresses used
* -------------------------------------------------------------------
zplenlo     =     $f8
zplenhi     =     zplenlo+1

zpsrclo     =     $fa
zpsrchi     =     zpsrclo+1

zpbitshi    =     $fc

zpbitbuf    =     $fd
zpdestlo    =     zpbitbuf+1           ; dest addr lo
zpdesthi    =     zpbitbuf+2           ; dest addr hi

encent      =     68

* -------------------------------------------------------------------
* this 156 (204) byte table area may be relocated. It may also be
* clobbered by other data between decrunches.
* -------------------------------------------------------------------
dectable    =     $1800                ; unused during LOADER

tablbi      =     dectable
tabllo      =     dectable+encent
tablhi      =     dectable+{encent*2}

getbits     MAC
            adc   #$80                 ; needs c=0, affects v
            asl
            bpl   gbskip
gbnext
            asl   zpbitbuf
            bne   gbok
            pha
            jsr   getcbyte
            rol
            sta   zpbitbuf
            pla
gbok
            rol
            bmi   gbnext
gbskip
            bvc   skip
gbgethi
            sec
            sta   zpbitshi
            jsr   getcbyte
skip
            <<<

* -------------------------------------------------------------------
* jsr this label to decrunch, it will in turn init the tables and
* call the decruncher
* no constraints on register content, however the
* decimal flag has to be #0 (it almost always is, otherwise do a cld)
DECRUNCH

* -------------------------------------------------------------------
* init zeropage, x and y regs. (12 bytes)
*
            ldy   #0
            ldx   #3
initzp
            jsr   getcbyte
            sta   zpbitbuf-1,x
            dex
            bne   initzp
* -------------------------------------------------------------------
* calculate tables (62 bytes) + getbits macro
* x and y must be #0 when entering
*
            clc
tablegen
            tax
            tya
            and   #$0f
            sta   tabllo,y
            beq   shortcut             ; start a new sequence
* -------------------------------------------------------------------
            txa
            adc   tabllo-1,y
            sta   tabllo,y
            lda   zplenhi
            adc   tablhi-1,y
shortcut
            sta   tablhi,y
* -------------------------------------------------------------------
            lda   #$01
            sta   <zplenhi
            lda   #$78                 ; %01111000
            getbits
* -------------------------------------------------------------------
            lsr
            tax
            beq   rolled
            php
rolle
            asl   zplenhi
            sec
            ror
            dex
            bne   rolle
            plp
rolled
            ror
            sta   tablbi,y
            bmi   nofixup
            lda   zplenhi
            stx   zplenhi
            DB    $24
nofixup
            txa
* -------------------------------------------------------------------
            iny
            cpy   #encent
            bne   tablegen
* -------------------------------------------------------------------
* prepare for main decruncher
            ldy   zpdestlo
            stx   zpdestlo
            stx   zpbitshi
* -------------------------------------------------------------------
* copy one literal byte to destination (11(10) bytes)
*
lstart1
            tya
            bne   nohidecr
            dec   zpdesthi
nohidecr
            dey
            jsr   getcbyte
            sta   (zpdestlo),y
* -------------------------------------------------------------------
* fetch sequence length index (15 bytes)
* x must be #0 when entering and contains the length index + 1
* when exiting or 0 for literal byte
nextrnd
            dex
            lda   zpbitbuf
nolit1
            asl
            bne   nofetch8
            jsr   getcbyte
            rol
nofetch8
            inx
            bcc   nolit1
            sta   zpbitbuf
* -------------------------------------------------------------------
* check for literal byte (2 bytes)
*
            beq   lstart1
* -------------------------------------------------------------------
* check for decrunch done and literal sequences (4 bytes)
*
            cpx   #$11
            bcc   skipjmp
            jmp   exitlseq
skipjmp
* -------------------------------------------------------------------
* calulate length of sequence (zplen) (18(11) bytes) + getbits macro
*
            lda   tablbi-1,x
            getbits
            adc   tabllo-1,x           ; we have now calculated zplenlo
            sta   zplenlo
            lda   zpbitshi
            adc   tablhi-1,x           ; c = 0 after this.
            sta   zplenhi
* -------------------------------------------------------------------
* here we decide what offset table to use (27(26) bytes) + getbitsnc macro
* z-flag reflects zplenhi here
*
            ldx   zplenlo
            lda   #$e1
            cpx   #$04
            bcs   gbnc2nxt
            lda   tablbit-1,x
gbnc2nxt
            asl   zpbitbuf
            bne   gbnc2ok
            tax
            jsr   getcbyte
            rol
            sta   zpbitbuf
            txa
gbnc2ok
            rol
            bcs   gbnc2nxt
            tax
* -------------------------------------------------------------------
* calulate absolute offset (zpsrc) (21(23) bytes) + getbits macro
*
            lda   #0
            sta   zpbitshi
            lda   tablbi,x
            getbits
            adc   tabllo,x
            sta   zpsrclo
            lda   zpbitshi
            adc   tablhi,x
            adc   zpdesthi
            sta   zpsrchi
* -------------------------------------------------------------------
* prepare for copy loop (2 bytes)
*
precopy
            ldx   zplenlo
* -------------------------------------------------------------------
* main copy loop (30 bytes)
*
copynext
            tya
            bne   skiphi
            dec   zpdesthi
            dec   zpsrchi
skiphi
            dey
            bcs   getlbyte
            lda   (zpsrclo),y
lbgotten
            sta   (zpdestlo),y
            dex
            bne   copynext
            lda   zplenhi
            bne   nexthi
beginstx
            stx   zpbitshi
            jmp   nextrnd
nexthi
            dec   zplenhi
            jmp   copynext
getlbyte
            jsr   getcbyte
            bcs   lbgotten
* -------------------------------------------------------------------
* exit or literal sequence handling (16(12) bytes)
*
exitlseq
            beq   decrexit
            jsr   getcbyte
            sta   zplenhi
            jsr   getcbyte
            tax
            bcs   copynext
decrexit
            rts
* -------------------------------------------------------------------
* the static stable used for bits+offset for lengths 1, 2 and 3 (3 bytes)
* bits 2, 4, 4 and offsets 64, 48, 32 corresponding to
* %10010000, %11100011, %11100010
tablbit
            DB    $90,$E3,$E2
* -------------------------------------------------------------------
* end of decruncher
* -------------------------------------------------------------------

getcbyte
            lda   bytelo
            bne   gcbdeclo
            dec   bytehi
gcbdeclo
            dec   bytelo
bytelo      =     *+1
bytehi      =     *+2
            lda   XDATAEND    ; must be defined elsewhere
            rts
