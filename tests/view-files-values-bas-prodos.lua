--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests View Files as Values on a BAS file from a ProDOS formatted disk, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'beagle-compiler.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "View Files as Values on BAS file (ProDOS) matches v8.4 behavior",
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
    apple2.TypeLine("MENU.BASIC") -- will match that file
    cii.WaitForScreenContains("%[E]NTER FILENAME, %[G]O, %[ESC]%-EXIT")
    apple2.Type("G") -- enter view mode
    cii.WaitForScreenContains("%[RETURN]%-CONTINUE, %[ESC]%-EXIT")
    test.ExpectIMatch(apple2.GrabTextScreen(), "136", "View Files as Values behavior does not match v8.4") -- visible byte offset
    test.ExpectIMatch(apple2.GrabTextScreen(), "72 08 00 00 B2 08 08 08  R%.%.%.2%.%.%.", "View Files as Values behavior does not match v8.4")
    test.ExpectIMatch(apple2.GrabTextScreen(), "65 73 2F 63 6F 6C 75 6D  ES/COLUM", "View Files as Values behavior does not match v8.4")
    apple2.EscapeKey() -- back to file selection
    cii.WaitForScreenContains("%[E]NTER FILENAME, %[G]O, %[ESC]%-EXIT")
    apple2.EscapeKey() -- back to main menu
    cii.WaitForMainMenu()
end)
