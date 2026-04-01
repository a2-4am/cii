--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
This tests copying a file from a ProDOS disk to a ProDOS disk that does not have enough free space to store it. The operation should fail and delete the partial file, leaving behind remnants of the file's data on disk, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  MODEL="apple2p"
  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'beagle-graphics-ProDOS.do' -flop2 'beagle-graphics-after-failed-filecopy.do' -flop3 $FLOPIMG -flop4 'beagle-graphics-filecopied-by-v84.do'"
  CHECKAUXMEMORY="false"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local target_filename = s5d1.filename
local s5d2 = manager.machine.images[":sl5:diskiing:1:525"]
local reference_filename = s5d2.filename
local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
s5d1:unload()
s5d2:unload()

test.Step(
  "Copy files from ProDOS disk to full ProDOS disk fails, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    s6d1:load(target_filename)
    apple2.Type("X") -- Copy
    cii.WaitForSelection("COPYFILES") -- two items are selected, Copy and Files
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT SOURCE DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT TARGET DEVICE:")
    apple2.Type("6") -- Slot 6, Drive 1
    cii.WaitForSelection("SLOT 6  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("COPY FILES")
    cii.WaitForScreenContains("%[RETURN]%-MARK FILE, %[U]NMARK, %[E]NTER")
    apple2.ReturnKey() -- select PRODOS file
    apple2.Type("G") -- Go
    cii.WaitForSelection("BEAGLE.GRAPHICS")
    apple2.RightArrowKey() -- select SUBDIRECTORY
    cii.WaitForSelection("SUBDIRECTORY")
    apple2.ReturnKey() -- select SUBDIRECTORY
    cii.WaitForScreenContains("DISK FULL")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
    s6d1:unload()
    test.ExpectBinaryEquals(util.SlurpFile(target_filename),
                            util.SlurpFile(reference_filename),
                            "Copy files from ProDOS disk to full ProDOS disk does not match v8.4")
end)
