--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests that C2Reboot displays an error message when attempting to change boot program on a ProDOS disk, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'beagle-graphics.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "Change Boot Program on ProDOS disk fails, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("B") -- Change Boot Program
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("NOT A PRODOS FUNCTION")
end)
