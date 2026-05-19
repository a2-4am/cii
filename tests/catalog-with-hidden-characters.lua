--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests 'Catalog - w/Hidden Characters' on a DOS 3.3 disk where some files have hidden characters designed to present a custom catalog. C2Reboot should display the hidden characters in inverse instead of treating them as control characters, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'beagle-bag.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "Catalog Disk Normal (DOS 3.3) displays hidden characters in inverse, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("C") -- Catalog
    cii.WaitForSelection("CATALOG DISKNORMAL") -- two items are selected, Catalog Disk and Normal
    apple2.Type("H") -- Hidden Chars
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("T 001")
    test.ExpectIMatch(apple2.GrabTextScreen(), "T 001 AHHHHHHHHBEAGLE BROS", "Catalog Disk w/Hidden Characters does not display hidden characters")
    test.ExpectIMatch(cii.GetSelection(), "HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH", "Catalog Disk w/Hidden Characters does not display hidden characters properly")
end)
