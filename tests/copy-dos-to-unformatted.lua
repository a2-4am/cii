--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'blank.do' -flop2 'blank.do' -flop3 $FLOPIMG -flop4 'DOS 3.3 System Master.do'"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local target_filename = s5d1.filename
local s5d2 = manager.machine.images[":sl5:diskiing:1:525"]
local blank_filename = s5d1.filename
local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
s5d1:unload()
s5d2:unload()
s6d2:unload()

test.Step(
  "Copy DOS to unformatted disk matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    s6d1:load(source_filename)
    s6d2:load(target_filename)
    apple2.Type("X") -- Copy
    cii.WaitForSelection("COPYFILES") -- two items are selected, Copy and Files
    apple2.Type("O") -- DOS
    cii.WaitForScreenContains("SELECT SOURCE DEVICE:")
    apple2.Type("6") -- Slot 6, Drive 1
    cii.WaitForSelection("SLOT 6  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT TARGET DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("INSERT DISKS")
    apple2.ReturnKey()
    cii.WaitForScreenContains("COPY DOS         TARGET: SLOT 6  DRIVE 2")
    cii.WaitForScreenContains("NOT A PRODOS OR DOS 3.3 DISK")
    apple2.ReturnKey()
    s6d2:unload()
    cii.WaitForMainMenu()
    -- target disk should not be modified
    test.ExpectBinaryEquals(util.SlurpFile(target_filename),
                            util.SlurpFile(blank_filename),
                            "Copy DOS to unformatted disk unexpectedly modified target disk")
end)
