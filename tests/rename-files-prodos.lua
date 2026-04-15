--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests renaming a file on a ProDOS disk. The operation should succeed, matching v8.4 behavior. The final disk image should be identical to one where the same operation was performed by v8.4.
]]

--[[ BEGINCONFIG ========================================

  MODEL="apple2p"
  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'beagle-graphics-renamed-files-by-v84.do' -flop3 $FLOPIMG -flop4 'beagle-graphics.do'"
  CHECKAUXMEMORY="false"

  ======================================== ENDCONFIG ]]

local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local reference_filename = s5d1.filename
s5d1:unload()

test.Step(
  "Rename Files (ProDOS) matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    -- rename file in root directory first
    apple2.Type("R") -- Rename
    cii.WaitForSelection("RENAMEFILES") -- two items are selected, Rename and Files
    apple2.Type("F") -- Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("RENAME FILES")
    cii.WaitForSelection("BEAGLE.GRAPHICS")
    apple2.ReturnKey() -- select root directory
    cii.WaitForScreenContains("%[RETURN]%-SELECT TO RENAME")
    apple2.Type("E")
    cii.WaitForScreenContains("ENTER FILENAME %(ONE FILE%)")
    apple2.TypeLine("STARTUP") -- will match STARTUP
    cii.WaitForScreenContains("%[RETURN]%-SELECT TO RENAME")
    apple2.ReturnKey()
    cii.WaitForScreenContains("RENAME STARTUP")
    apple2.TypeLine("STARTUP.RENAMED")
    cii.WaitForScreenContains("%[RETURN]%-SELECT TO RENAME")
    apple2.Type("G") -- Go
    cii.WaitForMainMenu()

    -- now delete file in subdirectory
    apple2.Type("R") -- Rename
    cii.WaitForSelection("RENAMEFILES") -- two items are selected, Rename and Files
    apple2.Type("F") -- Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("RENAME FILES")
    cii.WaitForSelection("BEAGLE.GRAPHICS")
    apple2.RightArrowKey() -- select subdirectory
    cii.WaitForSelection("SUBDIRECTORY")
    apple2.ReturnKey()
    cii.WaitForScreenContains("%[RETURN]%-SELECT TO RENAME")
    apple2.Type("E")
    cii.WaitForScreenContains("ENTER FILENAME %(ONE FILE%)")
    apple2.TypeLine("FP") -- will match FP
    cii.WaitForScreenContains("%[RETURN]%-SELECT TO RENAME")
    apple2.ReturnKey()
    cii.WaitForScreenContains("RENAME FP")
    apple2.TypeLine("FP.RENAMED")
    cii.WaitForScreenContains("%[RETURN]%-SELECT TO RENAME")
    cii.Beat()
    cii.Beat()
    apple2.Type("G") -- Go
    cii.WaitForMainMenu()
    s6d2:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(reference_filename),
                            "Rename Files (ProDOS) disk image differs from v8.4")
end)
