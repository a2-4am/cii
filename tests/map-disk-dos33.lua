--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests mapping a 5.25-inch disk in DOS 3.3 format with a variety of files. The operation should display a disk map and allow the user to move between file visualizations, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'DOS 3.3 System Master.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "Map disk (DOS) matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("M") -- Map Disk
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("0123456789ABCDEF0123456789ABCDEF012")
    cii.WaitForScreenContains("%[RETURN]%-CONTINUE, %[ESC]%-EXIT")
    apple2.RightArrowKey()
    cii.WaitForScreenContains("FILE: HELLO")
    test.ExpectEquals(cii.GetSelection(), "***", "Map Disk (DOS) failed")
    apple2.RightArrowKey()
    cii.WaitForScreenContains("FILE: APPLESOFT")
    apple2.RightArrowKey()
    cii.WaitForScreenContains("FILE: LOADER%.OBJ0")
    test.ExpectEquals(cii.GetSelection(), "******", "Map Disk (DOS) failed")
    apple2.EscapeKey()
    cii.WaitForMainMenu()
end)
