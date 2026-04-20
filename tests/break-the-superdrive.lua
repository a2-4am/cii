--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests putting an Apple Superdrive device into a 'permanently busy' state where the drive firmware fast-fails in a way that breaks callers entering through the SmartPort API. Copy II Plus v8.4 crashes when running this test.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'superdrive' -sl6 'diskiing'"
  DISKARGS="-flop1 'blank 800K.po' -flop3 $FLOPIMG"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:superdrive:fdc:0:35hd"]
local source_filename = s5d1.filename

test.Step(
  "Copy Disk (800K) after interrupting a format operation does not crash",
  function()
    cii.WaitForMainMenu()
    apple2.Type("F") -- Format
    cii.WaitForSelection("PRODOSFORMAT DISK") -- two items are selected, ProDOS and Format Disk (technically ProDOS is 'first' linearly)
    apple2.ReturnKey() -- ProDOS
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("FORMAT DISK PRODOS")
    cii.WaitForScreenContains("SLOT 5  DRIVE 1")
    cii.WaitForScreenContains("INSERT DISK TO FORMAT")
    cii.WaitForScreenContains("READY TO FORMAT %(Y/N%) %?")
    apple2.Type("Y")
    cii.WaitForScreenContains("DESTROY NON%-PRODOS VOLUME%?")
    apple2.Type("Y")
    cii.WaitForScreenContains("VOLUME NAME: /")
    apple2.Type("BLANK800")
    apple2.ReturnKey()
    cii.WaitForScreenContains("FORMATTING DISK")
    apple2.ControlReset()
    cii.WaitForMainMenu()
    apple2.Type("X") -- Copy
    cii.WaitForSelection("COPYFILES") -- two items are selected, Copy and Files
    apple2.Type("D") -- Disk
    cii.WaitForScreenContains("SELECT SOURCE DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT TARGET DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("INSERT SOURCE DISK")
    apple2.ReturnKey()
    cii.WaitForScreenContains("READING BLOCK")
    test.Expect(cii.ScreenContains("READING BLOCK"), "Copy Disk (800K) after interrupting format operation crashes")
end)
