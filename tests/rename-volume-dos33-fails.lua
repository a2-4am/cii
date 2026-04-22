--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests that C2Reboot displays an error message when attempting to rename a DOS volume, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'formatted-dos33-by-v84.do' -flop3 $FLOPIMG -flop4 'formatted-dos33-by-v84.do'"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local reference_filename = s5d1.filename
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
s5d1:unload()

test.Step(
  "Rename Volume on DOS disk fails, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("R") -- Rename
    cii.WaitForSelection("RENAMEFILES") -- two items are selected, Rename and Files
    apple2.Type("V") -- Volume
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("NOT A DOS 3%.3 FUNCTION")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
    s6d2:unload()
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(reference_filename),
                            "Failing to rename DOS volume unexpectedly modified disk")
end)
