--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests copying a file to a disk where the file already exists. The operation should be interrupted by a prompt saying the file already exists and asking what to do. Selecting "New Name" should prompt for a new filename then continue the copy operation. However, in this test, there is not enough disk space for making a duplicate of the given file with a new name, so the operation should ultimately fail with a DISK FULL error message, and the partial file should be deleted. The final disk image should be identical to one where the same operation was performed by v8.4.
]]

--[[ BEGINCONFIG ========================================

  MODEL="apple2p"
  MODELARGS="-sl5 'diskiing' -sl6 'diskiing'"
  DISKARGS="-flop1 'beagle-graphics-filecopied-new-name-disk-full-by-v84.do' -flop3 $FLOPIMG -flop4 'beagle-graphics.do'"
  CHECKAUXMEMORY="false"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local reference_filename = s5d1.filename
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename

test.Step(
  "Copy files when file exists prompts for action, selecting \"New Name\" without enough space for both files fails, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("X") -- Copy
    cii.WaitForSelection("COPYFILES") -- two items are selected, Copy and Files
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT SOURCE DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT TARGET DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForSelection("BEAGLE.GRAPHICS")
    apple2.ReturnKey() -- select root directory
    cii.WaitForScreenContains("COPY FILES")
    cii.WaitForScreenContains("%[RETURN]%-MARK FILE, %[U]NMARK, %[E]NTER")
    apple2.Type("E") -- Enter Filename (pattern)
    cii.WaitForScreenContains("ENTER FILENAME %(,OPT%. FILETYPES%)")
    apple2.TypeLine("PRODOS") -- will match PRODOS file only
    cii.WaitForScreenContains("%[RETURN]%-MARK FILE, %[U]NMARK, %[E]NTER")
    apple2.Type("G") -- Go
    cii.WaitForScreenContains("INSERT TARGET DISK")
    apple2.ReturnKey() -- do not switch disks
    cii.WaitForSelection("BEAGLE.GRAPHICS")
    apple2.ReturnKey() -- select root directory
    cii.WaitForScreenContains("FILE: PRODOS")
    cii.WaitForScreenContains("ALREADY EXISTS & IS LOCKED%.  NOW WHAT%?")
    cii.WaitForScreenContains("%[C]OPY ANYWAY, %[N]EW NAME, %[D]ON'T COPY")
    apple2.Type("N") -- new name
    cii.WaitForScreenContains("NEW NAME%?")
    apple2.TypeLine("PRODOS2")
    cii.WaitForScreenContains("DISK FULL")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
    s6d2:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(
      util.SlurpFile(reference_filename),
      util.SlurpFile(source_filename),
      "Copy files with file exists, user said New Name, copy failed from lack of space, but disk did not match v8.4 behavior")
end)
