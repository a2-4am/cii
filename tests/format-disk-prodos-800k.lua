--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests formatting a 3.5-inch (800K) disk in ProDOS format, on a //e with a Superdrive. The operation should succeed, and the final disk image should be identical to one where the same operation was performed by v8.4. Note: for reproducibility, the test disables the real-time clock because C2Reboot (and Copy II Plus) would otherwise write the creation date to the root directory.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-sl5 'superdrive' -sl6 'diskiing'"
  DISKARGS="-flop1 'System Disk v3.1 800K.po' -flop2 'formatted-800k-prodos-by-v84.po' -flop3 $FLOPIMG"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:superdrive:fdc:0:35hd"]
local source_filename = s5d1.filename
local s5d2 = manager.machine.images[":sl5:superdrive:fdc:1:35hd"]
local reference_filename = s5d2.filename
s5d2:unload()

test.Step(
  "Format Disk (ProDOS) of ProDOS 800K disk matches v8.4 behavior",
  function()
    cii.DisableRTC()
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
    cii.WaitForScreenContains("DESTROY /UTILITIES %?") -- volume name read from already-formatted disk
    apple2.Type("Y")
    cii.WaitForScreenContains("VOLUME NAME: /")
    apple2.Type("BLANK800")
    apple2.ReturnKey()
    cii.WaitForScreenContains("FORMATTING DISK")
    cii.WaitForScreenContains("FORMATTING COMPLETE")
    cii.WaitForScreenContains("PRESS %[RETURN]")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
    s5d1:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(reference_filename),
                            "Format Disk (ProDOS) 800K disk image does not match v8.4")
end)
