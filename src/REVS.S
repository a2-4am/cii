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
*    sided 3.5-inch disk, and force the format of the target
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
*    source code. UTIL.SYSTEM is byte-for-byte identical
*    to v8.4 from 1989.
*
*  (in progress)  Copy ][ Reboot 1.0
*
*  Remove bitcopy launchers and associated text and menu items.
*    The utilities stand alone.
*  Don't format RAM disk on quit if we didn't actually find one.
*    This fixes a long-standing bug that could overwrite block 2
*    of the last used device before quitting to ProDOS.
*  PSPACE routine (used by all Catalog functions) and PUNDO0
*    (used by Undelete Files) calls READBM to read the entire
*    volume bitmap into a variable length buffer. On a large
*    enough hard drive, this buffer can grow to $2000 bytes and
*    clobber the sector interleave tables that are initialized
*    at startup at CODEADDR-$30. Clobbering the interleave
*    tables makes all Copy Disk operations of floppy disks fail
*    until the program is restarted and the interleave tables
*    are reinitialized. This has been fixed by moving the bitmap
*    buffer starting address down to $1C00, which is unused at
*    the time READBM is called.
*  Use lowercase for most strings, if available.
*  Add single-letter hotkeys to the main menu and submenus.
*    Most are back-ported from v9.
*  Support Pronto-DOS disks in Change Boot Program.
*    Sectors for startup program and filetype are offset by 2.
*  Add more recognized filetypes in catalog displays and
*    file lists, mostly IIgs-related, including 4 back-ported
*    from v9.
*      $16  PFS  PFS Document
*      $2E  P8C  ProDOS 8 Code Module
*      $42  FTD  File Type Definitions
*      $50  GWP  Apple IIgs Word Processing
*      $51  GSS  Apple IIgs Spreadsheet
*      $52  GDB  Apple IIgs Database
*      $53  DRW  Object Oriented Graphics
*      $54  GDP  Apple IIgs Desktop Publishing
*      $55  HMD  HyperMedia
*      $58  HLP  Help File
*      $5A  CFG  Configuration
*      $AD  BDF  Apple IIgs BASIC Data
*      $BC  LDF  Apple IIgs Generic Load File
*      $BD  FST  Apple IIgs File System Translator
*      $C2  ANI  PaintWorks Animation
*      $C3  PAL  PaintWorks Palette
*      $C5  OOG  Object-Oriented Graphics
*      $C7  CDV  Apple IIgs Control Panel
*      $D5  MUS  Music sequence
*      $D6  INS  Instrument
*      $D7  MDI  MIDI
*      $D8  SND  Apple IIgs Audio
*      $E0  LBR  Archive
*  Change "[D]elete" to "[U]nmark" in Copy File list.
*    [D] still works.
*  Change "[Q]" to "[Return]" in Quit options.
*    [Q] still works.
*  Add "[M] to enter monitor" in Quit options. This was
*    first implemented in v6.0 but never displayed.
*  If there were no prompts at program startup, the header
*    was briefly displayed then cleared then displayed again.
*    This has been fixed. Startup should be flicker-free in
*    all cases.
*  No longer ask on startup if you want 80-column catalog
*    displays. Catalog w/file lengths still uses 80 columns
*    if available. Other catalog displays now use 40 columns.
*  No longer warn on startup about ProDOS 1.3. You should
*    still upgrade ProDOS though. That is a very old version!
*  Fixed off-by-1 bug that ended up writing junk data at the
*    end of the boot sector code on DOS-formatted floppy disks.
*  Rebranded as Copy ][ Reboot.
*  Distributed on a self-booting disk image with
*    ProDOS 2.4.3 from <https://prodos8.com/>
*    and the universal ("jumbo") clock driver from
*    <https://github.com/a2stuff/prodos-drivers>
*
********************************
*

