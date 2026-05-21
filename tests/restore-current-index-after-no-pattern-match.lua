--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests that C2Reboot restores the current file index in the interactive catalog display after an entered pattern does not match anything. This is not a problem in v8.4, but at one point C2Reboot introduced a regression that caused the current index to be restored to a garbage value, leading to 8 lines of garbage at the head of the catalog display.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'filetypes.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "Restore current file index in catalog display after no pattern match",
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
    apple2.Type("FP") -- will not match any files
    apple2.ReturnKey()
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE MARKER, %[E]NTER")
    -- check 15th file in list (should be visible on screen if the file index was restored properly)
    test.ExpectIMatch(apple2.GrabTextScreen(), "COLORS%.STD", "Current file index was not restored after no-pattern match")
end)
