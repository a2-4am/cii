            TYP   BIN
            DSK   ../build/UNDELETE.O
            PUT   VARS
            PUT   ../build/FILER.VARS
            PUT   ../build/DISKMAP.VARS
            ORG   TSMAPEND
UNDEL       
            ORG   *+3

************************************
*        UNDELETE FILES            *
************************************
*
            JSR   COMTRE
            LDY   #0
            STY   DELFLG
            INY
            STY   STATE
            JSR   CATDIS
            LDA   #$80
            STA   DELFLG
            JSR   PATMOV
            LDA   FILNUM
            BNE   :GOTFILS
            JMP   NOSEL
:GOTFILS    JSR   SWPCHK
            JSR   COMH00
            LDA   #$00
            STA   BADNUM
            STA   MAYBE
            STA   CURR
*
* ATTEMPT REGULAR UNDELETE OF DOS
* AND PRODOS FILES
*
:UNLOOP     JSR   FILEQ
            JSR   :UNDO
            JSR   CKESC
            INC   CURR
            LDA   CURR
            CMP   FILNUM
            BNE   :UNLOOP
*
            JSR   PATMOV      ;SQUISH LIST
            STX   NACTIV
            LDA   MAYBE
            BEQ   :CKBAD
*
* ATTEMPT 'SMART' UNDELETE OF
* 'MAYBE' FILES.
*
*
            JSR   COMH00
            LDA   #0
            STA   CURR
:SMARTLP    JSR   FILEQ
            LDX   CURR
            LDA   STATUS,X
            CMP   #$FE
            BNE   :ISBAD      ;UNRECOVERABLE
*
* FIRST, RECREATE FILE NAME AND
* STORAGE TYPE AND UNDELETE
* BLOCKS LEFT IN INDEX BLOCKS
*
            JSR   PUNDO0
*
* NOW TRY TO FIGURE OUT WHERE THE REST
* OF THE BLOCKS ARE AND UNDELETE THEM.
*
            JSR   SMART
*
:ISBAD      JSR   CKESC
            INC   CURR
            LDA   CURR
            CMP   FILNUM
            BCC   :SMARTLP
*
:CKBAD      LDA   BADNUM      ;ANY LOST
            BEQ   :OUT        ;FILES?
            JSR   HOME
            JSR   PATMOV
            LDA   #$03
            JSR   VLEFT
            JSR   PRHERE
            ASC   "Lost files:"
            DB    $8D,$8D,$0
            LDA   #$00
            STA   CURR
:PAGELP     LDA   #$0E        ;14 LINES/PAGE
            STA   :COUNT
:BADLP      DEC   :COUNT
            JSR   CURPNT
            JSR   CFILE       ;SEE FILE
            JSR   CROUT
            INC   CURR
            LDA   CURR
            CMP   FILNUM      ;NO MORE?
            BCS   :PRESS
            LDA   :COUNT      ;LINE COUNT?
            BNE   :BADLP
            LDA   #MCRESC1
            JSR   PRINT
            JSR   KYESC
            JSR   CROUT2
            JMP   :PAGELP
:PRESS      JMP   PRESS
:OUT        RTS
*
*
:UNDO       BIT   DOSNOW
            BPL   :DOS33
            JMP   PUNDO
*
:DOS33      LDA   #>SRCTSL
            STA   RPAGE       ;SET RWTS ADDR
            LDA   #$01
            STA   RCMND       ;& COMMAND
            JSR   CURPNT
            LDY   #$20        ;FIX UP
            LDA   (POINT),Y   ;CATALOG
            STA   TRACK       ;ENTRY
            STA   RTRACK
            LDY   #$00
            STA   (POINT),Y
            INY
            LDA   (POINT),Y
            STA   SECTOR
            STA   RSECTR
            LDY   #$20
            LDA   #" "
            STA   (POINT),Y
:TSLLP      JSR   :USEIT      ;ALLOCATE
            BCS   :CANT       ;TSLIST
            JSR   DORWTS
            LDA   #$0C
            STA   STSP
:PAIRLP     LDX   STSP
            LDA   SRCTSL,X
            STA   TRACK       ;FOR VALID
            ORA   SRCTSL+$1,X  ;TSPAIRS:
            BEQ   :NXTPAIR
            LDA   SRCTSL+$1,X  ;ALLOCATE
            STA   SECTOR      ;SECTORS FROM
            JSR   :USEIT      ;LIST
            BCS   :CANT
:NXTPAIR    INC   STSP
            INC   STSP
            BNE   :PAIRLP
            LDA   SRCTSL+1
            STA   TRACK
            STA   RTRACK      ;POINTER TO
            ORA   SRCTSL+2    ;NEXT TSLIST?
            BEQ   :DID
            LDA   SRCTSL+2    ;YES: LOOP
            STA   SECTOR      ;BACK
            STA   RSECTR
            JMP   :TSLLP
:DID        JSR   WRCAT1      ;WRITE FREED
            LDA   #$00        ;CATALOG
            BEQ   :MARKIT     ;ALWAYS
:CANT       JSR   RDCAT1      ;RE-READ IF
            INC   BADNUM      ;NO GOOD
            LDA   #$FF
:MARKIT     LDX   CURR        ;MARK FILE
            STA   STATUS,X    ;GOOD OR BAD
            RTS
*
:USEIT      LDA   SECTOR
            JSR   DOMASK
            LDA   TRACK       ;INDEX INTO
            ASL               ;BITMAP
            ASL
            ADC   #$38
            TAX
            LDA   VTOC1,X
            AND   BITMSK
            STA   :TEMP
            LDA   VTOC1+$1,X
            AND   BITMSK+1
            ORA   :TEMP
            SEC
            BEQ   :USED
            LDA   BITMSK
            EOR   #$FF
            AND   VTOC1,X
            STA   VTOC1,X
            LDA   BITMSK+1
            EOR   #$FF
            AND   VTOC1+$1,X
            STA   VTOC1+$1,X
            CLC
:USED       RTS
*
:TEMP       DB    $0
:COUNT      DB    $0
*
UNDELEND
