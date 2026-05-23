--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests mapping a 5.25-inch disk in ProDOS format with no files. The operation should display a "NO FILES" warning but allow the user to continue, then display an empty disk map with only the ProDOS-occupied sectors used, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'formatted-prodos-by-v84.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "Map disk (ProDOS) with no files matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("M") -- Map Disk
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("%[RETURN]%-CONTINUE, %[ESC]%-EXIT")
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "Map disk (ProDOS) failed")
    apple2.ReturnKey()
    cii.WaitForScreenContains("0123456789ABCDEF0123456789ABCDEF012")
    cii.WaitForScreenContains("%[RETURN]%-CONTINUE, %[ESC]%-EXIT")
    test.ExpectEquals(cii.GetSelection(), "**************", "Map disk (ProDOS) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)
