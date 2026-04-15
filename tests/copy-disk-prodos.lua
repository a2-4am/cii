--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
This tests that C2Reboot displays the volume name while performing a whole-disk copy of a ProDOS disk, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'beagle-graphics.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "Copy Disk with ProDOS source disk shows volume name, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("X") -- Copy
    cii.WaitForSelection("COPYFILES") -- two items are selected, Copy and Files
    apple2.Type("D") -- Disk
    cii.WaitForScreenContains("SELECT SOURCE DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 1
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT TARGET DEVICE:")
    apple2.Type("6") -- Slot 6, Drive 1
    cii.WaitForSelection("SLOT 6  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("INSERT DISKS")
    apple2.ReturnKey()
    cii.WaitForScreenContains("READING TRACK")
    test.Expect(cii.ScreenContains("/BEAGLE.GRAPHICS"), "Copy Disk does not display source disk volume name")
end)
