--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests copying a file to a disk where the file already exists. The operation should be interrupted by a prompt saying the file already exists and asking what to do. Selecting "Don't Copy" should skip the file and continue the copy operation, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'diskiing' -sl6 'diskiing'"
  DISKARGS="-flop1 'beagle-graphics.do' -flop3 $FLOPIMG -flop4 'beagle-graphics.do'"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local reference_filename = s5d1.filename
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename

test.Step(
  "Copy Files when file exists prompts for action, selecting \"Don't Copy\" matches v8.4 behavior",
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
    apple2.TypeLine("=") -- will match all files
    cii.WaitForScreenContains("%[RETURN]%-MARK FILE, %[U]NMARK, %[E]NTER")
    apple2.Type("G") -- Go
    cii.WaitForScreenContains("INSERT TARGET DISK")
    apple2.ReturnKey() -- do not switch disks
    cii.WaitForSelection("BEAGLE.GRAPHICS")
    apple2.ReturnKey() -- select root directory
    cii.WaitForScreenContains("FILE: PRODOS")
    cii.WaitForScreenContains("%[C]OPY ANYWAY, %[N]EW NAME, %[D]ON'T COPY")
    apple2.Type("D") -- don't copy (1 file)
    cii.WaitForScreenContains("FILE: BASIC%.SYSTEM")
    cii.WaitForScreenContains("%[C]OPY ANYWAY, %[N]EW NAME, %[D]ON'T COPY")
    apple2.Type("D") -- don't copy (1 file)
    cii.WaitForScreenContains("FILE: STARTUP")
    cii.WaitForScreenContains("%[C]OPY ANYWAY, %[N]EW NAME, %[D]ON'T COPY")
    apple2.Type("D") -- don't copy (1 file)
    cii.WaitForScreenContains("FILE: SUBDIRECTORY")
    cii.WaitForScreenContains("%[N]EW NAME, %[D]ON'T COPY") -- note: slightly different prompt for directories (matches v8.4)
    apple2.Type("D") -- don't copy (1 file)
    cii.WaitForMainMenu()
    test.ExpectBinaryEquals(
      util.SlurpFile(reference_filename),
      util.SlurpFile(source_filename),
      "Copy Files with file exists, user said don't copy on each file, but disk was unexpectedly modified")
end)
