--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests mapping a 5.25-inch disk in ProDOS format with an empty subdirectory. The operation should display a disk map with only the subdirectory. Attempting to dive into the subdirectory should display a modeless error message that the subdirectory is empty, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'formatted-prodos-by-v84.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "Map disk (ProDOS) with empty subdirectory matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("/") -- Create Subdirectory
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SUBDIRECTORY NAME:")
    apple2.TypeLine("TEST")
    cii.WaitForScreenContains("SUBDIRECTORY CREATED")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
    apple2.Type("M") -- Map Disk
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("0123456789ABCDEF0123456789ABCDEF012")
    cii.WaitForScreenContains("%[RETURN]%-CONTINUE, %[ESC]%-EXIT")
    apple2.RightArrowKey()
    cii.WaitForScreenContains("/TEST")
    test.ExpectEquals(cii.GetSelection(), "DD", "Map Disk (ProDOS) failed")
    apple2.Type(">")
    cii.WaitForScreenContains("EMPTY SUBDIRECTORY")
    apple2.EscapeKey()
    cii.WaitForScreenContains("USE ARROW KEYS TO MAP OTHER FILES")
    apple2.EscapeKey()
    cii.WaitForMainMenu()
end)
