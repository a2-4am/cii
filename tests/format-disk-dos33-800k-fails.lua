--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests that C2Reboot displays an error message when attempting to format a 3.5-inch (800K) disk as DOS 3.3, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'superdrive' -sl6 'diskiing'"
  DISKARGS="-flop1 'System Disk v3.1 800K.po' -flop2 'System Disk v3.1 800K.po' -flop3 $FLOPIMG"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:superdrive:fdc:0:35hd"]
local source_filename = s5d1.filename
local s5d2 = manager.machine.images[":sl5:superdrive:fdc:1:35hd"]
local reference_filename = s5d2.filename
s5d2:unload()

test.Step(
  "Format Disk (DOS 3.3) of 800K disk fails, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("F") -- Format
    cii.WaitForSelection("PRODOSFORMAT DISK") -- two items are selected, ProDOS and Format Disk (technically ProDOS is 'first' linearly)
    apple2.Type("D") -- DOS 3.3
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("DISK II FUNCTION ONLY")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
    s5d1:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(reference_filename),
                            "Format Disk (DOS 3.3) 800K unexpectedly modified target disk")
end)
