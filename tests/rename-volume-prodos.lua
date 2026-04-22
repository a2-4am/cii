--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests renaming a ProDOS volume. The operation should succeed, matching v8.4 behavior. The final disk image should be identical to one where the same operation was performed by v8.4.
]]

--[[ BEGINCONFIG ========================================

  MODEL="apple2p"
  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'beagle-graphics-renamed-volume-by-v84.do' -flop3 $FLOPIMG -flop4 'beagle-graphics.do'"
  CHECKAUXMEMORY="false"

  ======================================== ENDCONFIG ]]

local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local reference_filename = s5d1.filename
s5d1:unload()

test.Step(
  "Rename Volume (ProDOS) matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("R") -- Rename
    cii.WaitForSelection("RENAMEFILES") -- two items are selected, Rename and Files
    apple2.Type("V") -- Volume
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("RENAME VOLUME")
    cii.WaitForScreenContains("/BEAGLE%.GRAPHICS")
    cii.WaitForScreenContains("NEW VOLUME NAME: /")
    apple2.TypeLine("BG")
    apple2.Type("G") -- Go
    cii.WaitForMainMenu() -- returns to main menu automatically
    s6d2:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(reference_filename),
                            "Rename Volume (ProDOS) disk image differs from v8.4")
end)
