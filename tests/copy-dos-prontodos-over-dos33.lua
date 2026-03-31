--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
This tests that Copy DOS works without complaint when copying Pronto-DOS onto a disk that already has DOS 3.3, matching v8.4 behavior. C2Reboot performs some spot-checks to ensure that the source disk is actually DOS-shaped, but these checks also pass on Pronto-DOS.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'DOS 3.3 System Master.do' -flop2 'DOS 3.3 System Master-prontodos-copied-by-v84.do' -flop3 $FLOPIMG -flop4 'Pronto-DOS Master.do'"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local target_filename = s5d1.filename
local s5d2 = manager.machine.images[":sl5:diskiing:1:525"]
local reference_filename = s5d2.filename
local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
s5d1:unload()
s5d2:unload()

test.Step(
  "Copy DOS ProntoDOS over DOS 3.3 matches v8.4 behavior",
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
    cii.WaitForScreenContains("READING TRACK")
    cii.WaitForScreenContains("WRITING TRACK")
    cii.WaitForMainMenu()
    s6d1:unload()
    test.ExpectBinaryEquals(util.SlurpFile(target_filename),
                            util.SlurpFile(reference_filename),
                            "Copy DOS ProntoDOS over DOS 3.3 does not match v8.4")
end)
