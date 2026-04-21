--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests that C2Reboot displays an error message when attempting to map a 3.5-inch (800K) disk, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'superdrive' -sl6 'diskiing'"
  DISKARGS="-flop1 'System Disk v3.1 800K.po' -flop2 'System Disk v3.1 800K.po' -flop3 $FLOPIMG"

  ======================================== ENDCONFIG ]]

test.Step(
  "Map Disk of 800K disk fails, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("M") -- Map Disk
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("DISK II FUNCTION ONLY")
end)
