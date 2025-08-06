*
* REVISION HISTORY:
*
*-------------------------------
*
*  2/16/87   7.3
*
*   MADE CHANGE TO DISK COPY SO THAT AUX MEM IS NOT USED
*      IF DOING A TWO-DRIVE COPY; USING AUX MEM IN THIS
*      CASE ACTUALLY SLOWS THINGS DOWN. AUX MEM IS NOW
*      USED ONLY IF DOING A SINGLE-DRIVE DISK COPY.
*   MADE CHANGE TO PREVENT FALSE ERROR $28
*      IF FORMATTING BLANK DISK
*   MADE CHANGE TO SHOW PRODOS FILE AS BEING
*      LOCKED ONLY IF ALL THREE ACCESS BITS
*      ARE OFF
*   MADE CHANGE TO ALLOW [RETURN] IN RESPONSE
*      TO 'DATE' QUESTION
*   FIXED BUG WITH DELETING MULTIPLE SUBDIRS
*   FIXED BUG WITH COPYING DOS 3.3 RANDOM ACCESS
*      TEXT FILES
*   MADE CHANGE TO FIX CURSOR DISPLAY PROBLEM ON //GS
*   FIXED PROBLEM WHERE DATE WASN'T DISPLAYED ON SCREEN
*      WHEN USING //C SYSTEM CLOCK
*   FIXED PROBLEM WHERE IT SAID 'PRINTER SLOT 0' ON
*      ENHANCED //C AFTER RESET KEY WAS PRESSED
*   ADDED ROUTINE TO PATCH BUG IN PRODOS 1.3
*      DISK II DRIVER
*   FIXED BUG WHERE COPYING FROM /ABC/XYZ --> /ABC
*      DIDN'T DETECT 'DUPLICATE VOLUME ONLINE'
*   MADE CHANGE TO HANDLE UNDELETING OF FILES DELETED
*      BY PRODOS 1.3
*   MADE CHANGE TO CHECK IF RUNNING ON //GS. IF SO,
*      MAKE TOOL CALL TO READ 40/80 COLUMN SETTING
*      FROM BRAM. IF SET TO 80, DON'T ASK 80-COL
*      QUESTION.
*
*  3/06/87   7.3
*
*   FIXED BUG WHERE LETTERS "CATA" SHOWED UP IN
*      FRONT OF "SLOT s DRIVE d" WHEN CATALOGING
*      A DOS 3.3 DISK IN 80-COLUMN MODE.
*
*  5/27/87   7.4
*
*   MADE CHANGE SO THAT ONLY 15 CHARS ALLOWED ON INPUT
*      FOR SUBDIR NAME (USED TO BE 16).
*   MADE CHANGE TO LOOK AT ONLY LOWER NIBBLE OF 1ST
*      BYTE IN DIRECTORY ENTRY TO DETERMINE IF FILE
*      IS DELETED (INSTEAD OF WHOLE BYTE).
*   MADE CHANGE SO THAT AUXMEM IS NOW USED WHEN
*      DOING A 2-DRIVE DISK COPY.
*   FIXED BUG WHERE NUMERIC INPUT WAS NOT ALLOWED IN
*      COPY FILE SUB-MENU.
*   FIXED BUG WHERE '*' TOGGLE IN LOCK/UNLOCK DIDN'T
*      WORK CORRECTLY WITH NEWLY CREATED SUBDIR'S.
*   FIXED BUG WHERE INTERRUPTS WERE NOT DISABLED
*      IN RWTS AND VERIFY DISK SPEED ROUTINES.
*
*  8/18/87   7.4
*
*  FIXED BUG IN ALPHABETIZE ROUTINE.
*  MADE CHANGE TO SUBDIR CREATE AND LOCK/UNLOCK ROUTINES
*      SO THAT I RETURN SAME RESULTS AS PRODOS.
*
*  10/9/87   8.0 (beta)
*
*  Rearranged code internally to get a little additional free
*    space, to make the entire Utilities 1 assembly, & to let
*    the assembler do the relocating work.
*  Added Memory Manager routines to COPY DISK, can use GS memory
*    & 1 big RAMdisk to reduce # of passes, if 1-pass copy will
*    allow multiple target copies without rereading source.
*  Fixed 80-col TURN-OFF routines so GS doesn't show wrong
*    cursor.
*  Removed reference to $BFFC in loader cuz ProDOS Tech Ref
*    Manual says it's "reserved".
*  Removed patching for ProDOS 1.3, but
*  Added check for ProDOS 1.3, displays warning message.
*  Fixed problem where file copy DOS 3.3 -> ProDOS followed by
*    ProDOS -> ProDOS would put bad data in target file if it
*    took multiple passes. (DOS 3.3 -> ProDOS changed a count
*    value which ProDOS -> ProDOS never put back.)
*  Fixed horizontal positioning at ProDOS QUIT code on GS.
*  Added additional filetypes to CATALOG displays.
*
*  11/24/87  8.1
*
*  Fixed beta bug: MM error #$80 when no memory was available.
*  Added code to COPY DISK W/ FORMAT to check for a single-
*    sided  3.5" disk, and force the format of the target
*    disk to be single-sided.
*  (Mike plans to ship Copy II Plus as a single-sided disk.)
*  Moved program start from $5D00 to $5C00, reducing file
*    buffer space slightly, to accomodate single-sided code.
*  Added a few more filetypes to CATALOG displays.
*  On startup, it now clears screen before SETVID, in case
*    80-cols was active, it won't show the switchover.
*  The 8.0 beta version recognized an 80-col card even in a
*    II Plus (incidental).  Tree display can't handle that,
*    so I removed it again.
*  Fixed 2 bugs: 1600 errors in VERIFY DISK would show as 60.
*  Fixed minor bug: exactly $0101 errors would say 257 ERROR
*    instead of 257 ERRORS.
*
*  1/8/88   8.2
*
*  Fixed bug: Memory Manager didn't correctly recognize
*    big auxmem /RAM RAMdisks.
*  Fixed bug: Enter Filename Pattern wasn't recognizing all
*    ProDOS filetypes. (The list had grown. It now takes that
*    into account.)
*  Changed VOLUME NAME: prompt to VOLUME NAME :/  to remove
*    ambiguity over whether to type a /.
*
*  xx/xx/xx  8.3
*
*  This version is exactly the same as for version 8.2.
*  The version number was changed because of some bugs that were
*  fixed in the 3.5 bitcopy program.
*  Date unknown.
*
*  02/03/89  8.4
*
*  Made changes so that code works with stand-alone
*    UDC card with new UDC G/A.
*
*  2025-08-05  8.4 again
*
*  Rebuilt utilities with modern assembler, from recovered
*    source code. UTIL.SYSTEM is identical to v8.4 from 1989.
*
*  (in progress)  8.5
*
*  Remove bitcopy launchers and associated text and menu items.
*    The utilities stand alone.
*  Use lowercase for most strings, if available.
*  Support Pronto-DOS disks in Change Boot Program.
*    Sectors for startup program and filetype are offset by 2.
*  Add more recognized filetypes, mostly IIgs-related.
*
********************************
*
