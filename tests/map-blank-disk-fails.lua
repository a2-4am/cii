--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests that C2Reboot displays an error message when attempting to map a blank (formatted but all-0s) disk, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'blank.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "Map Disk of blank disk fails, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("M") -- Map Disk
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("NOT A PRODOS OR DOS 3%.3 DISK")
end)
