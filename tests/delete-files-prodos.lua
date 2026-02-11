--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[ BEGINCONFIG ========================================

  MODEL="apple2p"
  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'beagle-graphics-ProDOS-deleted-files-by-v84.do' -flop3 $FLOPIMG -flop4 'beagle-graphics-ProDOS.do'"
  CHECKAUXMEMORY="false"

  ======================================== ENDCONFIG ]]

-- note: using apple2p for this because it has no clock (I don't know how to disable
-- the No-Slot Clock that is installed and active by default in apple2e models)

local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local actual_filename = s6d2.filename
local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local expected_filename = s5d1.filename
s5d1:unload()

test.Step(
  "Delete Files (ProDOS) matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    -- delete file in root directory first
    apple2.Type("D") -- Delete
    cii.WaitForSelection("DELETEFILES") -- two items are selected, Delete and Files
    apple2.Type("F") -- Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("DELETE FILES")
    cii.WaitForSelection("BEAGLE.GRAPHICS")
    apple2.ReturnKey() -- select root directory
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE MARKER, %[E]NTER")
    apple2.Type("E")
    cii.WaitForScreenContains("ENTER FILENAME %(,OPT%. FILETYPES%)")
    apple2.TypeLine("=,BAS") -- will match STARTUP
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE MARKER, %[E]NTER")
    apple2.Type("G") -- Go
    cii.WaitForMainMenu()

    -- now delete file in subdirectory
    apple2.Type("D") -- Delete
    cii.WaitForSelection("DELETEFILES") -- two items are selected, Delete and Files
    apple2.Type("F") -- Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("DELETE FILES")
    cii.WaitForSelection("BEAGLE.GRAPHICS")
    apple2.RightArrowKey() -- select subdirectory
    cii.WaitForSelection("SUBDIRECTORY")
    apple2.ReturnKey()
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE MARKER, %[E]NTER")
    apple2.Type("E")
    cii.WaitForScreenContains("ENTER FILENAME %(,OPT%. FILETYPES%)")
    apple2.Type("FP") -- will match FP
    apple2.ReturnKey()
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE MARKER, %[E]NTER")
    apple2.Type("G") -- Go
    cii.WaitForMainMenu()
    s6d2:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(actual_filename),
                            util.SlurpFile(expected_filename),
                            "Delete Files (ProDOS) disk image differs from v8.4")
end)
