--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests View Files as Values on an Integer BASIC file from a DOS 3.3 formatted disk, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'Pronto-DOS Master.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "View Files as Values on Integer BASIC file (DOS 3.3) matches v8.4 behavior",
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
    apple2.Type("E")
    cii.WaitForScreenContains("ENTER FILENAME %(ONE FILE%)")
    apple2.TypeLine("APPLESOFT") -- will match that file
    cii.WaitForScreenContains("%[E]NTER FILENAME, %[G]O, %[ESC]%-EXIT")
    apple2.Type("G") -- enter view mode
    cii.WaitForScreenContains("%[RETURN]%-CONTINUE, %[ESC]%-EXIT")
    test.ExpectIMatch(apple2.GrabTextScreen(), "136", "View Files as Values behavior does not match v8.4") -- visible byte offset
    test.ExpectIMatch(apple2.GrabTextScreen(), "24 02 6E 01 00 5D 88 88  %$%.N%.%.]%.%.", "View Files as Values behavior does not match v8.4")
    test.ExpectIMatch(apple2.GrabTextScreen(), "00 03 61 28 84 C2 CC CF  %.%.A%(%.BLO", "View Files as Values behavior does not match v8.4")
    apple2.EscapeKey() -- back to file selection
    cii.WaitForScreenContains("%[E]NTER FILENAME, %[G]O, %[ESC]%-EXIT")
    apple2.EscapeKey() -- back to main menu
    cii.WaitForMainMenu()
end)
