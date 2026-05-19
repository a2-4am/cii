--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests 'Catalog - Normal' on a DOS 3.3 disk where some files have hidden characters designed to present a custom catalog. C2Reboot should ignore the hidden characters, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'beagle-bag.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "Catalog Disk Normal (DOS 3.3) strips hidden characters, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("C") -- Catalog
    cii.WaitForSelection("CATALOG DISKNORMAL") -- two items are selected, Catalog Disk and Normal
    apple2.Type("N") -- Normal
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("T 001")
    test.ExpectIMatch(apple2.GrabTextScreen(), "T 001 ABEAGLE BROS", "Catalog Disk - Normal does not strip hidden characters")
end)
