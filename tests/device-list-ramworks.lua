--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
This tests displaying the list of available devices on a //e with an 8MB RAMWorks card. The device list should be identical to the one offered by v8.4 under the same configuration.
]]

--[[ BEGINCONFIG ========================================

  MODELARGS="-aux 'rw3'"
  DISKARGS="-flop1 'RAMWorks driver.do' -flop2 $FLOPIMG"

  ======================================== ENDCONFIG ]]

test.Step(
  "Device list on 8MB //e with RAMWorks RAM disk appears as Slot 3 Drive 1, matches v8.4 behavior",
  function()
    apple2.WaitForBitsy()
    apple2.TabKey() -- switch to slot 6 drive 2 containing Copy ][ Reboot
    cii.WaitForScreenContains("UTIL.SYSTEM")
    apple2.Type("U") -- select UTIL.SYSTEM
    cii.WaitForSelection("UTIL.SYSTEM")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
    apple2.Type("C") -- Catalog Disk
    cii.WaitForSelection("CATALOG DISKNORMAL") -- two items are selected, Catalog Disk and Normal
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT DEVICE:")
    cii.WaitForScreenContains("PRESS %[%?] TO DISPLAY VOLUME NAMES")
    test.Expect(cii.ScreenContains("SLOT 6  DRIVE 1"), "Device list does not include expected device s6d1")
    test.Expect(cii.ScreenContains("SLOT 6  DRIVE 2"), "Device list does not include expected device s6d2")
    test.Expect(cii.ScreenContains("SLOT 3  DRIVE 1"), "Device list does not include expected device s3d1")
    test.Expect(not cii.ScreenContains("SLOT 0"), "Device list includes unexpected device in slot 0")
    test.Expect(not cii.ScreenContains("SLOT 1"), "Device list includes unexpected device in slot 1")
    test.Expect(not cii.ScreenContains("SLOT 2"), "Device list includes unexpected device in slot 2")
    test.Expect(not cii.ScreenContains("SLOT 4"), "Device list includes unexpected device in slot 4")
    test.Expect(not cii.ScreenContains("SLOT 5"), "Device list includes unexpected device in slot 5")
    test.Expect(not cii.ScreenContains("SLOT 7"), "Device list includes unexpected device in slot 7")
    test.Expect(not cii.ScreenContains("SLOT 3  DRIVE 2"), "Device list includes unexpected device s3d2")
end)
