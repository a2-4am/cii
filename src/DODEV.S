            TYP   BIN
            DSK   ../build/DODEV.O
            PUT   VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/MATCH.VARS
            ORG   MATCHEND
DODEV
            ORG   *+3

            STA   CURDEV
            LDA   #0
            STA   VOLFLG
            LDA   #$FF
            STA   DOSNOW      ;ASSUME PRODOS
            JSR   LOHERE
            ASC   "Press [?] to display volume names"
            DB    $0
:DEVMNU     JSR   :SEEDEVS
:KEYORD     JSR   CHKKEY
            BNE   :NOTARO
            BCS   :DRIGHT
            BCC   :DLEFT
:NOTARO     CMP   #"?"
            BEQ   :GETVOLS
            CMP   #"/"
            BEQ   :GETVOLS
            CMP   #$8D
            BNE   :KEYORD     ;BAD KEY
*
:CHOOSE     LDX   CURDEV
            LDA   DVICES,X
            CMP   #$BF
* AND #$F0
* CMP #$B0                ;CHOOSE /RAM?
            BNE   :CHOOS0     ;NO
            LDA   ISAUX       ;/RAM ACTIVE?
            BPL   :CHOOS0     ;YES
            LDA   DEVFLG      ;CMD=FORMAT?
            BMI   :CHOOS0     ;YES
            JSR   BELL
            JMP   :DEVMNU
*
:CHOOS0     LDA   #2
            STA   DIRBLK
            LDA   #0
            STA   PFX+5
            STA   PFX
            STA   DIRBLK+1
            LDX   CURDEV
            LDA   DVICES,X
            AND   #$F0
            STA   UNIT
            RTS
*
:DLEFT      LDX   CURDEV
            DEX
            BPL   :DRGTQ
            LDX   NUMDEV
            JMP   :DRGTQ
*
:DRIGHT     LDX   CURDEV
            INX
            CPX   NUMDEV
            BEQ   :DRGTQ
            BCC   :DRGTQ
            LDX   #0
:DRGTQ      STX   CURDEV
            JMP   :DEVMNU
*
*
*
* '?' REQUEST TO SEE VOLUME NAMES
* DO ONLINE CALLS FOR EACH DEVICE
* TO GET CURRENT VOLUME NAMES
*
:GETVOLS    LDX   NUMDEV
:GETVLP     TXA
            ASL
            ASL
            ASL
            ASL
            STA   :ONLINE+2
            LDA   DVICES,X
            STA   :ONLINE+1
            CMP   #$BF
* AND #$F0
* CMP #$B0
            BNE   :GETVL0
            LDA   ISAUX
            BMI   :GETSKIP
:GETVL0     JSR   MLI
            DB    $C5
            DW    :ONLINE
:GETSKIP    DEX
            BPL   :GETVLP
            STX   VOLFLG      ;FF
            JMP   :DEVMNU
:ONLINE     DB    $2
            DB    $0
            DW    VOLNMS
*
*
:SEEDEVS    LDA   #2
            JSR   VLEFT
            LDX   #0
            STX   :SHODEV
:DEVLP      CPX   CURDEV
            BNE   :NOTDEV
            JSR   PINVRS
:NOTDEV     LDA   DVICES,X
            PHA
            JSR   SEEDEV
            PLA
            CMP   #$BF
* AND #$F0
* CMP #$B0
            BNE   :NOTDV0
            LDA   ISAUX
            BPL   :NOTDV0
            JSR   PRHERE
            ASC   ": /RAM disconnected"
            DB    $0
            JMP   :NOVOL
*
:NOTDV0     LDA   VOLFLG
            BEQ   :NOVOL
*
* DISPLAY VOLUME NAMES
*
            JSR   PRHERE
            ASC   ": "
            DB    $0
            LDA   :SHODEV
            JSR   :SEEVOL
            JSR   CLREOL
:NOVOL      JSR   PNORML
            JSR   CROUT
            INC   :SHODEV
            LDX   :SHODEV
            CPX   NUMDEV
            BEQ   :DEVLP
            BCC   :DEVLP
            RTS
:SHODEV     DB    $0
*
*
*
*
* DISPLAY VOLUME NAME
* A = INDEX INTO DEVICE LIST (0 - F)
*
:SEEVOL     ASL
            ASL
            ASL
            ASL
            TAX
            LDA   VOLNMS,X
            AND   #$0F
            BNE   :NAMEOK
            LDA   VOLNMS+$1,X
            CMP   #$52
            BNE   :SEEVOLQ
            LDX   :SHODEV
            JSR   DVTYPX
            BEQ   :SEEDII     ;DISK II
            JSR   PRHERE
            ASC   "non-ProDOS"
            DB    $0
            RTS
*
:SEEDII     JSR   PRHERE
            ASC   "DOS 3.3"
            DB    $0
            RTS
*
:NAMEOK     TAY
            LDA   #"/"
            JSR   PCOUT
:SEEVLP     LDA   VOLNMS+$1,X
            ORA   #$80
            JSR   PCOUT
            INX
            DEY
            BNE   :SEEVLP
:SEEVOLQ    RTS
*
DODEVEND
