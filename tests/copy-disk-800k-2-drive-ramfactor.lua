--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests whole-disk copy of a 3.5-inch (800K) disk on a //e with a 1MB Ramfactor memory card. RAMFactor presents as a large RAM disk, which C2Reboot uses to read the entire disk in 1 pass, matching v8.4 behavior. After the copy is complete, C2Reboot prompts to make another copy. If selected, it writes out the second copy to the same drive entirely from memory (without re-reading the original disk), matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl1 'ramfactor' -sl2 'superdrive' -sl4 'superdrive' -sl5 'superdrive'"
  DISKARGS="-flop1 'blank 800K.po' -flop3 'blank 800K.po' -flop5 'System Disk v3.1 800K.po' -flop7 $FLOPIMG"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:superdrive:fdc:0:35hd"]
local source_filename = s5d1.filename
local s4d1 = manager.machine.images[":sl4:superdrive:fdc:0:35hd"]
local target1_filename = s4d1.filename
local s2d1 = manager.machine.images[":sl2:superdrive:fdc:0:35hd"]
local target2_filename = s2d1.filename
s2d1:unload()

test.Step(
  "Copy Disk (800K) on 8MB //e with RAMFactor RAM disk copies in 1 pass, can write multiple times without re-reading, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("X") -- Copy
    cii.WaitForSelection("COPYFILES") -- two items are selected, Copy and Files
    apple2.Type("D") -- Disk
    cii.WaitForScreenContains("SELECT SOURCE DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT TARGET DEVICE:")
    apple2.Type("4") -- Slot 4, Drive 1
    cii.WaitForSelection("SLOT 4  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("INSERT DISKS")
    apple2.ReturnKey()
    cii.WaitForScreenContains("READING BLOCK")
    -- increase timeout because it reads the entire disk in 1 pass,
    -- which takes longer than the default timeout
    cii.WaitForScreenContains("WRITING BLOCK", {timeout=120})
    -- With a large enough RAM disk initialized before launching Copy ][ Reboot,
    -- Copy Disk operation should take only 1 pass then offer to copy to another disk.
    -- Increase the timeout even more because writing the entire disk in 1 pass
    -- is even slower than reading it.
    cii.WaitForScreenContains("COPY SAME ONTO ANOTHER DISK", {timeout=240})
    s5d1:unload() -- to ensure second copy is coming from memory
    s4d1:load(target2_filename)
    apple2.Type("Y")
    cii.WaitForScreenContains("INSERT TARGET DISK")
    apple2.ReturnKey()
    cii.WaitForScreenContains("WRITING BLOCK")
    cii.WaitForScreenContains("COPY SAME ONTO ANOTHER DISK", {timeout=240})
    apple2.Type("N")
    cii.WaitForMainMenu()
    s4d1:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(target1_filename),
                            "Copy Disk target 1 disk image differs from source")
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(target2_filename),
                            "Copy Disk target 2 disk image differs from source")
end)
