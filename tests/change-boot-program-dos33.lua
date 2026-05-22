--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests C2Reboot attempting to change the boot program on a DOS disk. The test should succeed, matching v8.4 behavior. The final disk image should be identical to one where the same operation was performed by v8.4.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'diskiing' -sl6 'diskiing'"
  DISKARGS="-flop1 'DOS 3.3 System Master-changed-boot-program-by-v84.do' -flop3 $FLOPIMG -flop4 'DOS 3.3 System Master.do'"

  ======================================== ENDCONFIG ]]

local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local reference_filename = s5d1.filename
s5d1:unload()

test.Step(
  "Change Boot Program on DOS disk matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("B") -- Change Boot Program
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("FILE: HELLO")
    cii.WaitForScreenContains("IS THE CURRENT BOOT PROGRAM%.") -- note different wording from v8.4
    cii.WaitForScreenContains("%[E]NTER FILENAME, %[G]O, %[ESC]%-EXIT") -- note different prompt wording from v8.4
    apple2.Type("E")
    cii.WaitForScreenContains("ENTER FILENAME %(ONE FILE%)")
    apple2.TypeLine("FID") -- will match FID
    cii.WaitForScreenContains("%[E]NTER FILENAME, %[G]O, %[ESC]%-EXIT") -- note different prompt wording from v8.4
    apple2.Type("G")
    cii.WaitForMainMenu()
    s6d2:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(reference_filename),
                            "Change Boot Program disk image differs from v8.4")
end)
