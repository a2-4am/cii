--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests that C2Reboot displays an error message when attempting to create a subdirectory on a DOS 3.3 disk, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  MODEL="apple2p"
  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'beagle-graphics-subdirectory-created-by-v84.do' -flop3 $FLOPIMG -flop4 'beagle-graphics.do'"
  CHECKAUXMEMORY="false"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local reference_filename = s5d1.filename
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
s5d1:unload()

test.Step(
  "Create Subdirectory on ProDOS disk matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("/") -- Create Subdirectory
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("CREATE SUBDIRECTORY")
    cii.WaitForScreenContains("/BEAGLE%.GRAPHICS")
    cii.WaitForSelection("BEAGLE.GRAPHICS")
    apple2.RightArrowKey()
    cii.WaitForSelection("SUBDIRECTORY")
    apple2.ReturnKey() -- select subdirectory named SUBDIRECTORY
    cii.WaitForScreenContains("SUBDIRECTORY NAME:")
    apple2.TypeLine("TEST")
    cii.WaitForScreenContains("SUBDIRECTORY CREATED")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
    s6d2:unload()
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(reference_filename),
                            "Create Subdirectory on ProDOS disk does not match v8.4")
end)
