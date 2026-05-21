--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests that C2Reboot detects and displays bad sectors when attempting to verify files on a disk with bad sectors across several files, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'DOS 3.3 System Master-with-bad-sectors.woz'"

  ======================================== ENDCONFIG ]]

test.Step(
  "Verify files (DOS 3.3) with bad sectors matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("Y") -- Verify
    cii.WaitForSelection("FILESVERIFY") -- two items are selected, Files and Verify
    apple2.Type("F") -- Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE MARKER, %[E]NTER")
    apple2.Type("E")
    cii.WaitForScreenContains("ENTER FILENAME %(,OPT%. FILETYPES%)")
    apple2.Type("=") -- will match all files
    apple2.ReturnKey()
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE MARKER, %[E]NTER")
    apple2.Type("G") -- Go
    cii.WaitForScreenContains("I/O ERROR: TRACK %$1E, SECTOR %$3")
    test.ExpectMatch(cii.GetSelection(), "RENUMBER", "Verify Files did not find bad sector in RENUMBER")
    apple2.ReturnKey()
    cii.WaitForScreenContains("I/O ERROR: TRACK %$0F, SECTOR %$B")
    test.ExpectMatch(cii.GetSelection(), "BOOT13", "Verify Files did not find bad sector in BOOT13")
    apple2.ReturnKey()
    cii.WaitForScreenContains("TOTAL:")
    test.ExpectIMatch(apple2.GrabTextScreen(), "2 ERRORS", "Verify Files did not find 2 bad sectors")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)
