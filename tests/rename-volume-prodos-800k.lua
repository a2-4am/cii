--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests renaming a 3.5-inch disk formatted as ProDOS. The operation should succeed, matching v8.4 behavior. The final disk image should be identical to one where the same operation was performed by v8.4.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'superdrive'"
  DISKARGS="-flop1 'System Disk v3.1 800K-renamed-volume-by-v84.po' -flop2 'System Disk v3.1 800K.po' -flop3 $FLOPIMG"

  ======================================== ENDCONFIG ]]

local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
local s5d1 = manager.machine.images[":sl5:superdrive:fdc:0:35hd"]
local source_filename = s5d1.filename
local s5d2 = manager.machine.images[":sl5:superdrive:fdc:1:35hd"]
local reference_filename = s5d2.filename
s5d1:unload()

test.Step(
  "Rename Volume (800K) matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    -- rename file in root directory first
    apple2.Type("R") -- Rename
    cii.WaitForSelection("RENAMEFILES") -- two items are selected, Rename and Files
    apple2.Type("V") -- Volume
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("52") -- Slot 5, Drive 2
    cii.WaitForSelection("SLOT 5  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("RENAME VOLUME")
    cii.WaitForScreenContains("/UTILITIES")
    cii.WaitForScreenContains("NEW VOLUME NAME: /")
    apple2.TypeLine("Z")
    apple2.Type("G") -- Go
    cii.WaitForMainMenu() -- returns to main menu automatically
    s5d2:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(reference_filename),
                            "Rename Volume (800K) disk image differs from v8.4")
end)
