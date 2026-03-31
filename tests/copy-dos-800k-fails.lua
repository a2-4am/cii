--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
This tests that C2Reboot displays an error message when attempting to Copy DOS on a 3.5-inch (800K) disk, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'superdrive'"
  DISKARGS="-flop1 'System Disk v3.1 800K.po' -flop2 'System Disk v3.1 800K.po' -flop3 $FLOPIMG"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:superdrive:fdc:0:35hd"]
local source_target_filename = s5d1.filename
local s5d2 = manager.machine.images[":sl5:superdrive:fdc:1:35hd"]
local untouched_filename = s5d2.filename
s5d2:unload()

test.Step(
  "Copy DOS from/to 800K disk fails, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("X") -- Copy
    cii.WaitForSelection("COPYFILES") -- two items are selected, Copy and Files
    apple2.Type("O") -- DOS
    cii.WaitForScreenContains("SELECT SOURCE DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT TARGET DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("COPY DOS         SOURCE: SLOT 5  DRIVE 1")
    cii.WaitForScreenContains("DISK II FUNCTION ONLY")
    s5d1:unload()
    test.ExpectBinaryEquals(util.SlurpFile(source_target_filename),
                            util.SlurpFile(untouched_filename),
                            "Copy DOS from/to 800K disk unexpectedly modified disk")
end)
