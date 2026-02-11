--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'superdrive'"
  DISKARGS="-flop1 'System Disk v3.1 800K.po' -flop2 'blank 800K.po' -flop3 $FLOPIMG"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:superdrive:fdc:0:35hd"]
local source_filename = s5d1.filename
local s5d2 = manager.machine.images[":sl5:superdrive:fdc:1:35hd"]
local target_filename = s5d2.filename

test.Step(
  "Copy Disk (800K) on 128K //e with 2 Superdrives matches v8.4 behavior",
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
    apple2.Type("52") -- Slot 5, Drive 2
    cii.WaitForSelection("SLOT 5  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("INSERT DISKS")
    apple2.ReturnKey()
    for i=1,11 do -- copy operation takes 12 passes (we only check 11 because last one goes by too quickly)
      cii.WaitForScreenContains("READING BLOCK")
      cii.WaitForScreenContains("WRITING BLOCK")
    end
    -- automatically returns to main menu after copy operation finishes
    cii.WaitForMainMenu()
    s5d2:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(target_filename),
                            "Copy Disk target disk image differs from source")
end)
