--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
This tests whole-disk copy of a 3.5-inch (800K) disk on a //e with an 8MB RAMWorks memory card. C2Reboot can only use this memory if it is formatted as a RAM disk, which neither C2Reboot nor ProDOS can do by themselves. This test pre-boots a driver disk that sets up all available RAMWorks memory as a RAM disk, then launches C2Reboot. C2Reboot uses the vendor-formatted RAM disk to read the entire disk in 1 pass, matching v8.4 behavior. After the copy is complete, C2Reboot prompts to make another copy. If selected, it writes out the second copy to the same drive entirely from memory (without re-reading the original disk), matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl4 'superdrive' -sl5 'superdrive' -sl6 'diskiing' -aux 'rw3'"
  DISKARGS="-flop1 'blank 800K.po' -flop2 'blank 800K.po' -flop3 'System Disk v3.1 800K.po' -flop5 'RAMWorks driver.do' -flop6 $FLOPIMG"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:superdrive:fdc:0:35hd"]
local source_filename = s5d1.filename
local s4d1 = manager.machine.images[":sl4:superdrive:fdc:0:35hd"]
local target1_filename = s4d1.filename
local s4d2 = manager.machine.images[":sl4:superdrive:fdc:1:35hd"]
local target2_filename = s4d2.filename
local s5d2 = manager.machine.images[":sl5:superdrive:fdc:1:35hd"]
s4d1:unload()
s4d2:unload()

test.Step(
  "Copy Disk (800K) on 8MB //e with RAMWorks RAM disk copies in 1 pass, can write multiple times without re-reading, matches v8.4 behavior",
  function()
    apple2.WaitForBitsy()
    apple2.TabKey() -- switch to slot 6 drive 2 containing Copy ][ Reboot
    cii.WaitForScreenContains("UTIL.SYSTEM")
    apple2.Type("U") -- select UTIL.SYSTEM
    cii.WaitForSelection("UTIL.SYSTEM")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
    s5d2:load(target1_filename)
    apple2.Type("X") -- Copy
    cii.WaitForSelection("COPYFILES") -- two items are selected, Copy and Files
    apple2.Type("D") -- Disk
    cii.WaitForScreenContains("SELECT SOURCE DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT TARGET DEVICE:")
    apple2.Type("52") -- Slot 5, Drive 2
    cii.WaitForSelection("SLOT 5  DRIVE 2")
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
    s5d2:load(target2_filename)
    apple2.Type("Y")
    cii.WaitForScreenContains("INSERT TARGET DISK")
    apple2.ReturnKey()
    cii.WaitForScreenContains("WRITING BLOCK")
    cii.WaitForScreenContains("COPY SAME ONTO ANOTHER DISK", {timeout=240})
    apple2.Type("N")
    cii.WaitForMainMenu()
    s5d2:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(target1_filename),
                            "Copy Disk target 1 disk image differs from source")
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(target2_filename),
                            "Copy Disk target 2 disk image differs from source")
end)
