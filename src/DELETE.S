            TYP   BIN
            DSK   ../build/DELETE.O
            PUT   VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/DDISK.VARS
            PUT   ../build/CATALOG.VARS
            ORG   CATALOGEND
DELETE      
            ORG   *+3

*******************************
*         DELETE              *
*******************************
*
            LDX   #UDELETE
            JSR   CHOOZ1      ;DOS, DISK,
            STA   :TEMP       ;OR FILES?
            CMP   #0
            BNE   :NOTFILZ
            JSR   COMTRE
            JMP   :DFILES
*
:NOTFILZ    JSR   COMHDR
            LDA   :TEMP
            CMP   #$02
            BEQ   :DDOS
*
***********  DELETE DISK  **********
*
*

:DELDSK     JSR   :READY?
            BNE   :DDOUT
            JSR   DOSTYP      ;SETUP VOLNAM
            BMI   :DELPRO     ;PRODOS
*
* READ VTOC JUST TO MAKE SURE THAT
* IT IS REALLY A DOS DISK
*
* These two lines added 2/1/89
*
            LDA   #1
            STA   RCMND
*
            LDX   #>VTOC1
            JSR   DOVTOC
*
:DELPRO     JSR   DEVTYP
            CMP   #1
            BNE   :GODDSK     ;NOT /RAM
*
*
* DISCONNECT /RAM
*
            LDA   #$FF
            STA   ISAUX
            BNE   :DDDONE     ;ALWAYS
*
:DDOUT      RTS
:GODDSK     JSR   DDISK
:DDDONE     JSR   PRHERE
            DB    $8D,$8D
            ASC   "Disk"
            DB    $0
            JMP   :COMDEL
*
*
***********  DELETE DOS  ***********
*
:DDOS       LDA   DOSNOW
            BPL   :DOS33
            JMP   NOPRO
*
:DOS33      JSR   :READY?
            BNE   :DDOUT
            JSR   DOS?
            JSR   STVTOC
            LDA   #>CVTOC
            STA   RPAGE
            LDA   #$01
            STA   RCMND
            JSR   DORWTS
            LDA   #$FF
            JSR   SET1A2
            JSR   ZIPDOS      ;WRITE NO-BOOT
            JSR   PRHERE
            DB    $8D,$8D
            ASC   "DOS"
            DB    $0
:COMDEL     JSR   PRHERE
            ASC   " deleted"
            DB    $8D,$0
            JMP   PRESS
*
*
*
:TEMP       DB    $0
*
*
:READY?     JSR   PRHERE
            DB    $8D,$8D
            ASC   "Ready to delete (Y/N) ? "
            DB    $0
            JSR   KEYESC
            JSR   PCOUT
            CMP   #"Y"
            BNE   :READY3
            JSR   SETA
            JSR   PRVNM
            JSR   HOME
            LDA   #0
:READY3     RTS
*
*
*********  DELETE FILES  ***********
:DFILES     LDA   #$01
            STA   STATE       ;STATE=1
            JSR   CATDIS      ;DISPLAY
            JSR   PATMOV
            LDA   FILNUM      ;ANY FILES?
            BNE   :GOTFILS
            JMP   NOSEL
:GOTFILS    JSR   SWPCHK      ;SAME DISK?
            JSR   HOME
            LDY   #$00        ;INIT COUNTER
            STY   SP
            STY   CURR
:DFILELP    JSR   FILEQ
            JSR   CURPNT
            BIT   DOSNOW
            BPL   :SKIPCK     ;DOS 3.3
            LDY   #0
            LDA   (POINT),Y
            AND   #$F0
            CMP   #$D0
            BNE   :SKIPCK     ;NOT SUBDIR
            JSR   DIVEIN
            CLC
            JSR   DIVECK
            JSR   PRVNM
            JSR   SETPFX
            LDX   #$FF
            STX   CURR
            BNE   :DFIL1      ;ALWAYS
*
:SKIPCK     JSR   CURPNT
            LDA   #>TOP10     ;2/16/87
            JSR   SETHIM      ;2/16/87
            LDA   #$00        ;SET CATALOG1
            JSR   JD1FILE     ;DELETE A FILE
            LDA   $C000
            CMP   #$9B
            BEQ   :ABORT
:DFIL1      INC   CURR
            LDA   CURR
            CMP   FILNUM
            BCC   :DFILELP
            BIT   DOSNOW
            BPL   :ABORT
            JSR   DIVOUT
            BCS   :ABORT
            LDA   SP
            BEQ   :DFIL2
            LDA   #0
            STA   CURR
:DFIL2      SEC
            JSR   DIVECK
            JSR   PRVNM
            JSR   SETPFX
            JSR   FILEQ
            JMP   :SKIPCK
*
:ABORT      BIT   DOSNOW
            BMI   :JDOWAIT    ;PRODOS
            JSR   WRCAT1      ;WRITE TRACK
:JDOWAIT    JMP   DOWAIT
*
DELETEEND
