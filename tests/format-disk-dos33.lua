--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests formatting a blank (formatted but all-0s) 5.25-inch disk in DOS 3.3 format, with Central Point's 'no-boot' boot sector on T00S00 and no DOS on tracks 1 and 2. The operation should succeed, however the final disk image may not be identical to one where the same operation was performed by v8.4, because v8.4 had an off-by-1 bug in its no-boot memory copy loop that ended up storing garbage in byte $A2 of T00S00 of DOS 3.3-formatted disks. C2Reboot fixes this bug, hence the disk images may differ on that one specific byte. Any other differences are a regression.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'formatted-dos33-by-v84.do' -flop3 $FLOPIMG -flop4 'blank.do'"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local reference_filename = s5d1.filename
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
s5d1:unload()

test.Step(
  "Format Disk (DOS 3.3) of blank disk matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("F") -- Format
    cii.WaitForSelection("PRODOSFORMAT DISK") -- two items are selected, ProDOS and Format Disk (technically ProDOS is 'first' linearly)
    apple2.Type("D") -- DOS 3.3
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("FORMAT DISK DOS 3.3")
    cii.WaitForScreenContains("SLOT 6  DRIVE 2")
    cii.WaitForScreenContains("INSERT DISK TO FORMAT")
    cii.WaitForScreenContains("READY TO FORMAT %(Y/N%) %?")
    apple2.Type("Y")
    cii.WaitForScreenContains("DESTROY NON%-PRODOS VOLUME%?")
    apple2.Type("Y")
    cii.WaitForScreenContains("FORMATTING DISK")
    cii.WaitForScreenContains("FORMATTING COMPLETE")
    cii.WaitForScreenContains("PRESS %[RETURN]")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
    s6d2:unload() -- eject disk (ensures disk image is updated)
    local source1 = cii.ReadPartialFile(source_filename, 0, 0xA1)
    local reference1 = cii.ReadPartialFile(reference_filename, 0, 0xA1)
    test.ExpectBinaryEquals(source1, reference1,
                            "Format Disk (DOS 3.3) disk image does not match v8.4")
    local source2 = cii.ReadPartialFile(source_filename, 0xA3, "*all")
    local reference2 = cii.ReadPartialFile(reference_filename, 0xA3, "*all")
    test.ExpectBinaryEquals(source2, reference2,
                            "Format Disk (DOS 3.3) disk image does not match v8.4")
end)
