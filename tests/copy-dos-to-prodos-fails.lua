--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
This tests that Copy DOS displays an error message when attempting to Copy DOS onto a ProDOS disk, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'formatted-prodos-by-v84.do' -flop2 'formatted-prodos-by-v84.do' -flop3 $FLOPIMG -flop4 'DOS 3.3 System Master.do'"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local target_filename = s5d1.filename
local s5d2 = manager.machine.images[":sl5:diskiing:1:525"]
local untouched_filename = s5d1.filename
local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
s5d1:unload()
s5d2:unload()

test.Step(
  "Copy DOS to disk formatted as ProDOS fails, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    s6d1:load(target_filename)
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
    cii.WaitForScreenContains("NOT A PRODOS FUNCTION")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
    s6d1:unload()
    test.ExpectBinaryEquals(util.SlurpFile(target_filename),
                            util.SlurpFile(untouched_filename),
                            "Copy DOS to disk formatted as ProDOS unexpectedly modified target disk")
end)
