--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests undeleting files from a ProDOS disk, one in the root directory and one in a subdirectory. There are actually two deleted files in the subdirectory, both named FP, because the disk was shipped with a deleted file named FP and a recreated file also named FP. Only one of them can be undeleted. C2Reboot will list the other as 'lost', matching v8.4 behavior. The final disk image should be identical to one where the same operation was performed by v8.4.
]]

--[[ BEGINCONFIG ========================================

  MODEL="apple2p"
  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'beagle-graphics-undeleted-files-by-v84.do' -flop3 $FLOPIMG -flop4 'beagle-graphics-deleted-files-by-v84.do'"
  CHECKAUXMEMORY="false"

  ======================================== ENDCONFIG ]]

local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local reference_filename = s5d1.filename
s5d1:unload()

test.Step(
  "Undelete Files (ProDOS) matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    -- undelete file in root directory first
    apple2.Type("U") -- Undelete Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("UNDELETE FILES")
    cii.WaitForSelection("BEAGLE.GRAPHICS")
    apple2.ReturnKey() -- select root directory
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE MARKER, %[E]NTER")
    apple2.Type("E")
    cii.WaitForScreenContains("ENTER FILENAME %(,OPT%. FILETYPES%)")
    apple2.TypeLine("STARTUP") -- will match deleted file STARTUP
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE MARKER, %[E]NTER")
    apple2.Type("G") -- Go
    cii.WaitForMainMenu()

    -- now undelete file in subdirectory
    apple2.Type("U") -- Undelete Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("UNDELETE FILES")
    cii.WaitForSelection("BEAGLE.GRAPHICS")
    apple2.RightArrowKey() -- select subdirectory
    cii.WaitForSelection("SUBDIRECTORY")
    apple2.ReturnKey()
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE MARKER, %[E]NTER")
    apple2.Type("E")
    cii.WaitForScreenContains("ENTER FILENAME %(,OPT%. FILETYPES%)")
    apple2.Type("FP") -- will match two deleted files, both named FP
    apple2.ReturnKey()
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE MARKER, %[E]NTER")
    apple2.Type("G") -- Go
    -- The disk already had deleted a file named FP once (and created a new file called FP)
    -- in the subdirectory named SUBDIRECTORY. Undelete Files will find both deleted files,
    -- but it will only be able to rescue one of them. The other will be listed as 'lost'.
    cii.WaitForScreenContains("LOST FILES:")
    cii.WaitForScreenContains("FP")
    cii.WaitForScreenContains("PRESS %[RETURN]")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
    s6d2:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(reference_filename),
                            "Undelete Files (ProDOS) disk image differs from v8.4")
end)
