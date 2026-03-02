            TYP   BIN
            DSK   ../build/LINEINPUT.O
            PUT   VARS
            PUT   ../build/IO.VARS
            PUT   ../build/QUIT.VARS
            ORG   QUITEND
LINEINPUT
**********************************
*       LINE INPUT LIBRARY       *
* GETDNM - prompt for directory name
* GETPAT - prompt for filename pattern
* GET1FNM - prompt for 1 filename
* GETNFNM - prompt for new filename
* GETVNM - prompt for volume name
* GETNVNM - promtp for new volume name
**********************************
GETDNM      >>>   JMPMODULE,DECOMPRESS;_GETDNM
GETPAT      >>>   JMPMODULE,DECOMPRESS;_GETPAT
GET1FNM     >>>   JMPMODULE,DECOMPRESS;_GET1FNM
GETNFNM     >>>   JMPMODULE,DECOMPRESS;_GETNFNM
GETVNM      >>>   JMPMODULE,DECOMPRESS;_GETVNM
GETNVNM     >>>   JMPMODULE,DECOMPRESS;_GETNVNM
DECOMPRESS  EQU   *
            ORG   *+3
            RTS

*
*
* PROMPT FOR DIRECTORY NAME
*
* RETURNS: BCC --> |FILE| CONTAINS DIRECTORY NAME
*          BCS --> USER CANCELED (ESC) OR NO INPUT
_GETDNM     EQU   *
            JSR   PRHERE
            ASC   8D,"Subdirectory name: ",00
            JSR   GVCOM1
            BCS   :MK2        ;ESC ABORT
            LDY   #0
:MKLOOP     LDA   VOLNAM,Y
            BEQ   :MK2
            STA   FILE+$1,Y
            INY
            BNE   :MKLOOP
:MK2        RTS
*
* PROMPT FOR FILENAME PATTERN
*
* RETURNS: BCC --> |LINEIN| CONTAINS FILENAME PATTERN
*          BCS --> USER CANCELED (ESC) OR NO INPUT
_GETPAT     EQU   *
            JSR   LOHERE
            ASC   "Enter filename (,opt. filetypes)",8D,"? ",00
            LDA   #$24        ;PATTERN LIMIT
            BNE   GETLN0      ;ALWAYS
*
* PROMPT FOR 1 FILENAME
*
* RETURNS: BCC --> |LINEIN| CONTAINS FILENAME
*          BCS --> USER CANCELED (ESC) OR NO INPUT
_GET1FNM    EQU   *
            JSR   LOHERE
            ASC   "Enter filename (one file)",8D,"? ",00
            LDA   #$1E        ;DOS FILENAME LIMIT
            BIT   DOSNOW
            BPL   GETLN0
            LDA   #$0F        ;PRODOS FILENAME LIMIT
GETLN0      EQU   *
            STA   LINLIM
            JMP   GETLN
*
* PROMPT FOR NEW FILENAME
*
* RETURNS: BCC --> |FILE| CONTAINS NEW FILENAME
*          BCS --> USER CANCELED
_GETNFNM    EQU   *
            JSR   PRHERE
            ASC   8D,"New name?",FF,8D,FF,00
            LDA   #$16
            JSR   VLEFT
            LDA   #$0A
            STA   CH
            LDA   #$0F
            BIT   DOSNOW
            BMI   :NEWPRO
            LDA   #$1E
:NEWPRO     STA   LINLIM
            JSR   GETLN       ;GET IT
            BCS   :NEWX       ;ESC ABORT
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
            BNE   :NEWLP1     ;ALWAYS
:NEWOUT     CLC
:NEWX       RTS
*
* PROMPT FOR VOLUME NAME
*
* RETURNS: BCC --> |VOLNAM| CONTAINS VOLUME NAME
*          BCS --> USER CANCELED (ESC) OR NO INPUT
_GETVNM     EQU   *
            JSR   PRHERE
            ASC   8D,8D,"V",00
            JMP   GVCOM       ;GET VOL NAME
*
* PROMPT FOR NEW VOLUME NAME
*
* RETURNS: BCC --> |VOLNAM| CONTAINS VOLUME NAME
*          BCS --> USER CANCELED (ESC) OR NO INPUT
_GETNVNM    EQU   *
            JSR   PRHERE
            ASC   8D,8D,"New v",00
*            JMP   GVCOM       ;GET VOL NAME
* fall through to GVCOM
*
* Prompt for volume name
* [4am] caller now displays first letter 'v' or 'V'
GVCOM       EQU   *
            JSR   PRHERE
            ASC   "olume name: /",00
GVCOM1      EQU   *
            LDA   #$0F
            STA   LINLIM
            JSR   GETLN
            BCS   :GVOUT
            LDY   #0
            LDX   #0
:DOIT1      LDA   LINEIN,Y
            CMP   #$8D
            BNE   :DOIT2
            LDA   #0
            BEQ   :DOIT3
:DOIT2      INY
            AND   #$7F
:DOIT3      STA   VOLNAM,X
            INX
            CPX   #$10
            BCC   :DOIT1
            LDA   VOLNAM
            BEQ   :GVOUT      ;C IS SET
            LDA   #0
            STA   VOLNAM+$0F
            CLC
:GVOUT      RTS
*
* LINE INPUT
*
* RETURNS: BCC --> |LINEIN| CONTAINS INPUT
*          BCS --> USER CANCELED (ESC) OR NO INPUT
GETLN       EQU   *
            LDX   #$00
            BEQ   :GETLN1     ;ALWAYS
:BEEP       JSR   BELL
:GETLN1     JSR   CASKEY
            CMP   #$88
            BEQ   :LEFT
            CMP   #$95
            BEQ   :RIGHT
            CMP   #$8D
            BEQ   :CR
            CMP   #$9B
            BEQ   :ESC
            CMP   #$A0
            BCC   :GETLN1     ;CTRL CHAR
:GETLN2     CPX   LINLIM
            BCS   :GETLN1
            JSR   :CKLEGAL
            BCS   :BEEP
            STA   LINEIN,X
            JSR   PCOUT
            INX
            BNE   :GETLN1     ;ALWAYS
*
:RIGHT      LDY   CH
            LDA   (BASL),Y
            JMP   :GETLN2
*
:LEFT       DEX
            BMI   GETLN
            JSR   PCOUT
            JMP   :GETLN1
*
:CR         STA   LINEIN,X
            STX   :TEMP
            PHA
            JSR   CLREOL
            PLA
            LDX   :TEMP       ;LENGTH
            BEQ   :ESC        ;CR ONLY, NO INPUT
            CLC
            RTS
:ESC        SEC
            RTS
*
:CKLEGAL    CMP   #$C1
            BCC   :CKLEG1
            CMP   #$DB
            BCS   :CKLEG1
:ISLEGAL    CLC
            RTS
*
:CKLEG1
            CMP   #$AC        ;","
            BNE   :NOTCOMA
            LDA   LINLIM
            CMP   #$24
            BNE   :NOTLEGL
            LDA   #$AC        ;","
            BNE   :ISLEGAL    ;ALWAYS
*
:NOTCOMA
            CMP   #$BD        ;"="
            BNE   :NOTEQL
            LDA   LINLIM
            CMP   #$24
            BNE   :NOTLEGL
            LDA   #$BD        ;"="
            BNE   :ISLEGAL    ;ALWAYS
*
:NOTEQL     BIT   DOSNOW
            BMI   :LIPRODOS
            CPX   #0          ;1ST CHAR?
            BEQ   :NOTLEGL    ;YES
            BNE   :ISLEGAL
*
:LIPRODOS   CPX   #0
            BNE   :NOT1ST
            CMP   #"/"
            BEQ   :ISLEGAL
:NOTLEGL    SEC
            RTS
*
:NOT1ST     CPX   #1
            BNE   :NOT2ND
            STA   :TEMP
            LDA   LINEIN
            CMP   #"/"
            BEQ   :NOTLEGL
            LDA   :TEMP
:NOT2ND     CMP   #"."
            BEQ   :ISLEGAL
            CMP   #$B0
            BCC   :CKLEG2
            CMP   #$BA
            BCC   :ISLEGAL    ;DIGIT
:CKLEG2     CMP   #"/"
            BNE   :NOTLEGL
            LDA   LINLIM
            CMP   #$40
            BNE   :NOTLEGL
            DEX
            LDA   LINEIN,X
            INX
            CMP   #"/"
            BEQ   :NOTLEGL    ;TWO /'S
            LDA   #"/"
            BNE   :ISLEGAL    ;ALWAYS
:TEMP       DB    $0
*
LINEINPUTEND
