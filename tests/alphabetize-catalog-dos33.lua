--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
This tests Alphabetize Catalog on a DOS 3.3 disk. The operation should succeed, matching v8.4 behavior. C2Reboot matches v8.4 with the exact contents of the VTOC and all directory sectors.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'DOS 3.3 System Master-sorted-by-v84.do' -flop3 $FLOPIMG -flop4 'DOS 3.3 System Master.do'"

  ======================================== ENDCONFIG ]]

local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local actual_filename = s6d2.filename
local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local expected_filename = s5d1.filename
s5d1:unload()

test.Step(
  "Alphabetize Catalog (DOS 3.3) matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("A") -- Alphabetize Catalog
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("ALPHABETIZE CATALOG")
    cii.WaitForScreenContains("%[G]%-GO, %[ESC]%-EXIT")
    apple2.Type("G") -- Go
    cii.WaitForMainMenu()
    s6d2:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(actual_filename),
                            util.SlurpFile(expected_filename),
                            "Alphabetize Catalog (DOS 3.3) disk image differs from v8.4")
end)
