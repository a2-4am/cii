--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests undeleting several files from a DOS 3.3 disk. The operation should succeed, matching v8.4 behavior. The final disk image should be identical to one where the same operation was performed by v8.4.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'DOS 3.3 System Master.do' -flop3 $FLOPIMG -flop4 'DOS 3.3 System Master-deleted-files-by-v84.do'"

  ======================================== ENDCONFIG ]]

local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local reference_filename = s5d1.filename
s5d1:unload()

test.Step(
  "Undelete Files (DOS 3.3) matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("U") -- Undelete Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("UNDELETE FILES")
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE MARKER, %[E]NTER")
    apple2.Type("E") -- Enter Filename (pattern)
    cii.WaitForScreenContains("ENTER FILENAME %(,OPT%. FILETYPES%)")
    apple2.TypeLine("=") -- will match all deleted files
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE MARKER, %[E]NTER")
    apple2.Type("G") -- Go
    cii.WaitForMainMenu()
    s6d2:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(reference_filename),
                            "Undelete Files (DOS 3.3) disk image differs from v8.4")
end)
