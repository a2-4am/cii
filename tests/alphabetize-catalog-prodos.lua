--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'beagle-graphics-ProDOS-sorted-by-v84.do' -flop3 $FLOPIMG -flop4 'beagle-graphics-ProDOS.do'"

  ======================================== ENDCONFIG ]]

local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local actual_filename = s6d2.filename
local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local expected_filename = s5d1.filename
s5d1:unload()

test.Step(
  "Alphabetize Catalog (ProDOS) matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    -- alphabetize root directory first
    apple2.Type("A") -- Alphabetize Catalog
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitFor80Column()
    cii.WaitForScreenContains("ALPHABETIZE CATALOG")
    cii.WaitForSelection("BEAGLE.GRAPHICS")
    apple2.ReturnKey() -- select root directory
    cii.WaitFor40Column()
    cii.WaitForScreenContains("GO,")
    apple2.Type("G") -- Go
    cii.WaitForMainMenu()
    -- alphabetize subdirectory
    apple2.Type("A") -- Alphabetize Catalog
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- select Slot 6, Drive 2
    apple2.ReturnKey()
    cii.WaitFor80Column()
    cii.WaitForScreenContains("ALPHABETIZE CATALOG")
    cii.WaitForSelection("BEAGLE.GRAPHICS")
    apple2.RightArrowKey() -- select subdirectory
    cii.WaitForSelection("SUBDIRECTORY")
    cii.Beat()
    apple2.ReturnKey()
    cii.WaitFor40Column()
    cii.WaitForScreenContains("ALPHABETIZE CATALOG")
    cii.WaitForScreenContains("%*DP.OBJ1")
    apple2.Type(" ") -- page
    cii.WaitForScreenContains("%*PATTERNS")
    apple2.Type(" ") -- page
    cii.WaitForScreenContains("GO,")
    apple2.Type("G") -- Go
    cii.WaitForMainMenu()
    s6d2:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(actual_filename),
                            util.SlurpFile(expected_filename),
                            "Alphabetize Catalog (ProDOS) disk image differs from v8.4")
end)
