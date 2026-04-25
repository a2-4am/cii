--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests that C2Reboot displays an error message when attempting to Alphbetize Catalog on an unformatted disk, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'unformatted.woz'"

  ======================================== ENDCONFIG ]]

test.Step(
  "Alphabetize Catalog of unformatted disk fails, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("A") -- Alphabetize Catalog
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("I/O ERROR: TRACK %$11, SECTOR %$0")
end)
