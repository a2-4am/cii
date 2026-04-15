--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests whole-disk copy on a //e with a 1MB Ramfactor memory card. RAMFactor presents as a large RAM disk, which C2Reboot uses to read the entire disk in 1 pass, matching v8.4 behavior. After the copy is complete, C2Reboot prompts to make another copy. If selected, it writes out the second copy to the same drive entirely from memory (without re-reading the original disk), matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl1 'ramfactor' -sl5 'diskiing'"
  DISKARGS="-flop1 'blank.do' -flop2 'blank.do' -flop3 $FLOPIMG -flop4 'DOS 3.3 System Master.do'"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local target1_filename = s5d1.filename
local s5d2 = manager.machine.images[":sl5:diskiing:1:525"]
local target2_filename = s5d2.filename
local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
s5d1:unload()
s5d2:unload()
s6d2:unload()

test.Step(
  "[FLAKY] Copy Disk on 8MB //e with RAMFactor RAM disk copies in 1 pass, can write multiple times without re-reading, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("X") -- Copy
    cii.WaitForSelection("COPYFILES") -- two items are selected, Copy and Files
    apple2.Type("D") -- Disk
    cii.WaitForScreenContains("SELECT SOURCE DEVICE:")
    apple2.Type("6") -- Slot 6, Drive 1
    cii.WaitForSelection("SLOT 6  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT TARGET DEVICE:")
    apple2.Type("6") -- Slot 6, Drive 1
    cii.WaitForSelection("SLOT 6  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("INSERT SOURCE DISK")
    s6d1:load(source_filename)
    apple2.ReturnKey()
    cii.WaitForScreenContains("INSERT TARGET DISK")
    s6d1:load(target1_filename)
    apple2.ReturnKey()
    cii.WaitForScreenContains("COPY SAME ONTO ANOTHER DISK")
    apple2.Type("Y")
    cii.WaitForScreenContains("INSERT TARGET DISK")
    apple2.ReturnKey()
    cii.WaitForScreenContains("WRITING TRACK")
    cii.WaitForScreenContains("COPY SAME ONTO ANOTHER DISK")
    apple2.Type("N")
    cii.WaitForMainMenu()
    s6d1:unload() -- eject disk (ensures disk image is updated)
    -- test sometimes fails due to https://github.com/mamedev/mame/issues/14474
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(target1_filename),
                            "Copy Disk target disk image 1 differs from source")
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(target2_filename),
                            "Copy Disk target disk image 2 differs from source")
end)
