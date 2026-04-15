--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests renaming a file on a DOS 3.3 disk. The new filename is only valid under DOS 3.3 (contains spaces and is too long to be a PrODOS filename). The operation should succeed, matching v8.4 behavior. The final disk image should be identical to one where the same operation was performed by v8.4.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'DOS 3.3 System Master-renamed-by-v84.do' -flop3 $FLOPIMG -flop4 'DOS 3.3 System Master.do'"

  ======================================== ENDCONFIG ]]

local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local reference_filename = s5d1.filename
s5d1:unload()

test.Step(
  "Rename Files (DOS 3.3) matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("R") -- Rename
    cii.WaitForSelection("RENAMEFILES") -- two items are selected, Rename and Files
    apple2.Type("F") -- Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("RENAME FILES")
    cii.WaitForScreenContains("%[RETURN]%-SELECT TO RENAME")
    apple2.Type("E") -- Enter Filename (one file)
    cii.WaitForScreenContains("ENTER FILENAME %(ONE FILE%)")
    apple2.TypeLine("FID") -- will match FID
    cii.WaitForScreenContains("%[RETURN]%-SELECT TO RENAME")
    apple2.ReturnKey()
    cii.WaitForScreenContains("RENAME FID")
    apple2.TypeLine("FID THE NEXT GENERATION")
    apple2.Type("G") -- Go
    cii.WaitForMainMenu()
    s6d2:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(reference_filename),
                            "Rename Files (DOS 3.3) disk image differs from v8.4")
end)
