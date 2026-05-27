--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests View Files as Text on a BAS file from a ProDOS formatted disk, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'beagle-compiler.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "View Files as Text on BAS file (ProDOS) matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("V") -- View Files
    cii.WaitForSelection("VALUESVIEW FILES") -- two items are selected, Values and View Files
    apple2.Type("T") -- Text
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
    test.ExpectIMatch(apple2.GrabTextScreen(), "550", "View Files as Text behavior does not match v8.4") -- visible byte offset
    test.ExpectIMatch(apple2.GrabTextScreen(), "XAPB%(48945HD%)", "View Files as Text behavior does not match v8.4")
    apple2.EscapeKey() -- back to file selection
    cii.WaitForScreenContains("%[E]NTER FILENAME, %[G]O, %[ESC]%-EXIT")
    apple2.EscapeKey() -- back to main menu
    cii.WaitForMainMenu()
end)
