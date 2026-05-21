--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests that C2Reboot does not detect any bad sectors when attempting to verify files on a disk with no bad sectors, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'DOS 3.3 System Master.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "Verify files (DOS 3.3) with no bad sectors matches v8.4 behavior",
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
    cii.WaitForScreenContains("TOTAL:")
    test.ExpectIMatch(apple2.GrabTextScreen(), "0 ERRORS", "Verify Files found non-existent bad sectors")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)
