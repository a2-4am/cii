--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests that Copy DOS displays an error message when attempting to Copy DOS onto a drive with no disk in it, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'DOS 3.3 System Master.do'"

  ======================================== ENDCONFIG ]]

local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename

test.Step(
  "Copy DOS to drive with no disk fails, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    s6d1:unload()
    apple2.Type("X") -- Copy
    cii.WaitForSelection("COPYFILES") -- two items are selected, Copy and Files
    apple2.Type("O") -- DOS
    cii.WaitForScreenContains("SELECT SOURCE DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT TARGET DEVICE:")
    apple2.Type("6") -- Slot 6, Drive 1
    cii.WaitForSelection("SLOT 6  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("INSERT DISKS")
    apple2.ReturnKey()
    cii.WaitForScreenContains("COPY DOS         TARGET: SLOT 6  DRIVE 1")
    cii.WaitForScreenContains("I/O ERROR: TRACK $11, SECTOR $0")
end)
