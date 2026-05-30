--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests View Files as Values on a SYS file from a ProDOS formatted disk, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'beagle-compiler.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "View Files as Values on SYS file (ProDOS) matches v8.4 behavior except $FF character",
  function()
    cii.WaitForMainMenu()
    apple2.Type("V") -- View Files
    cii.WaitForSelection("VALUESVIEW FILES") -- two items are selected, Values and View Files
    apple2.Type("V") -- Values
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("%[E]NTER FILENAME, %[G]O, %[ESC]%-EXIT")
    apple2.Type("E") -- Enter Filename
    cii.WaitForScreenContains("ENTER FILENAME %(ONE FILE%)")
    apple2.TypeLine("COMPILER.SYSTEM") -- will match that file
    cii.WaitForScreenContains("%[E]NTER FILENAME, %[G]O, %[ESC]%-EXIT")
    apple2.Type("G") -- enter view mode
    cii.WaitForScreenContains("%[RETURN]%-CONTINUE, %[ESC]%-EXIT")
    test.ExpectIMatch(apple2.GrabTextScreen(), "136", "View Files as Values behavior does not match v8.4") -- visible byte offset
    test.ExpectIMatch(apple2.GrabTextScreen(), "4C 47 20 EE EE 41 07 53  LG NNA%.S", "View Files as Values behavior does not match v8.4")
    -- Note: following output is different than v8.4 because we are no longer changing $FF characters to $DF in PCOUT.
    -- This is not a bug. Arguably the original behavior was a bug. According to source code comments, v8.4 only meant
    -- to do that when outputting to a printer, but PCOUT logic did it unconditionally without taking the output device
    -- into account.
    test.ExpectIMatch(apple2.GrabTextScreen(), "BF A9 3F 8D 6B BF A9 FF  %?%)%?%.K%?%)\127", "View Files as Values behavior does not match v8.4")
    apple2.EscapeKey() -- back to file selection
    cii.WaitForScreenContains("%[E]NTER FILENAME, %[G]O, %[ESC]%-EXIT")
    apple2.EscapeKey() -- back to main menu
    cii.WaitForMainMenu()
end)
