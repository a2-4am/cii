--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests reformatting a 5.25-inch disk in ProDOS format that has already been formatted as ProDOS. The operation should succeed (after confirming destruction of the old disk by volume name) and write ProDOS boot blocks and a blank ProDOS root directory with the new volume name no files. The final disk image should be identical to one where the same operation was performed by v8.4.
]]

--[[ BEGINCONFIG ========================================

  MODEL="apple2p"
  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'formatted-prodos-by-v84.do' -flop3 $FLOPIMG -flop4 'beagle-graphics.do'"
  CHECKAUXMEMORY="false"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local reference_filename = s5d1.filename
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
s5d1:unload()

test.Step(
  "Format Disk (ProDOS) of ProDOS disk matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("F") -- Format
    cii.WaitForSelection("PRODOSFORMAT DISK") -- two items are selected, ProDOS and Format Disk (technically ProDOS is 'first' linearly)
    apple2.ReturnKey() -- ProDOS
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("FORMAT DISK PRODOS")
    cii.WaitForScreenContains("SLOT 6  DRIVE 2")
    cii.WaitForScreenContains("INSERT DISK TO FORMAT")
    cii.WaitForScreenContains("READY TO FORMAT %(Y/N%) %?")
    apple2.Type("Y")
    cii.WaitForScreenContains("DESTROY /BEAGLE.GRAPHICS %?") -- volume name read from already-formatted disk
    apple2.Type("Y")
    cii.WaitForScreenContains("VOLUME NAME: /")
    apple2.Type("BLANK")
    apple2.ReturnKey()
    cii.WaitForScreenContains("FORMATTING DISK")
    cii.WaitForScreenContains("FORMATTING COMPLETE")
    cii.WaitForScreenContains("PRESS %[RETURN]")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
    s6d2:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(reference_filename),
                            "Format Disk (ProDOS) of ProDOS disk does not match v8.4")
end)
