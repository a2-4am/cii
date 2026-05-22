--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests C2Reboot attempting to change the boot program on a Pronto-DOS disk. The test should succeed, unlike v8.4 which does not support Pronto-DOS. The resulting disk image was verified manually. This test ensures no regressions.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'diskiing' -sl6 'diskiing'"
  DISKARGS="-flop1 'Pronto-DOS Master-changed-boot-program.do' -flop3 $FLOPIMG -flop4 'Pronto-DOS Master.do'"

  ======================================== ENDCONFIG ]]

local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local reference_filename = s5d1.filename
s5d1:unload()

test.Step(
  "Change Boot Program on Pronto-DOS disk",
  function()
    cii.WaitForMainMenu()
    apple2.Type("B") -- Change Boot Program
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("FILE: HELLO")
    cii.WaitForScreenContains("IS THE CURRENT BOOT PROGRAM%.")
    cii.WaitForScreenContains("%[E]NTER FILENAME, %[G]O, %[ESC]%-EXIT")
    apple2.Type("E")
    cii.WaitForScreenContains("ENTER FILENAME %(ONE FILE%)")
    apple2.TypeLine("DOS-UP") -- will match DOS-UP
    cii.WaitForScreenContains("%[E]NTER FILENAME, %[G]O, %[ESC]%-EXIT")
    apple2.Type("G")
    cii.WaitForMainMenu()
    s6d2:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(reference_filename),
                            "Change Boot Program on Pronto-DOS disk does not match manually verified result")
end)
