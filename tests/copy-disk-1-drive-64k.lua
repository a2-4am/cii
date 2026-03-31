--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
This tests whole-disk copy on a 64K //e, without an extended 80-column card. C2Reboot takes 9 passes to copy the whole disk, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'diskiing' -aux ''"
  DISKARGS="-flop1 'blank.do' -flop3 $FLOPIMG -flop4 'DOS 3.3 System Master.do'"
  CHECKAUXMEMORY="false"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local target_filename = s5d1.filename
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
s5d1:unload()

test.Step(
  "[FLAKY] Copy Disk on 64K //e with 1 drive copies in 9 passes, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("X") -- Copy
    cii.WaitForSelection("COPYFILES") -- two items are selected, Copy and Files
    apple2.Type("D") -- Disk
    cii.WaitForScreenContains("SELECT SOURCE DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT TARGET DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    for i=1,9 do -- copy operation takes 9 passes
      cii.WaitForScreenContains("INSERT SOURCE DISK")
      s6d2:load(source_filename)
      cii.Beat()
      apple2.ReturnKey()
      cii.WaitForScreenContains("INSERT TARGET DISK")
      s6d2:load(target_filename)
      cii.Beat()
      apple2.ReturnKey()
    end
    -- automatically returns to main menu after copy operation finishes
    cii.WaitForMainMenu()
    s6d2:unload() -- eject disk (ensures disk image is updated)
    -- test sometimes fails due to https://github.com/mamedev/mame/issues/14474
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(target_filename),
                            "Copy Disk target disk image differs from source")
end)
