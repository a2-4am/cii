--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests that C2Reboot detects and displays bad sectors when attempting to verify a disk with bad sectors across several files, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'DOS 3.3 System Master-with-bad-sectors.woz'"

  ======================================== ENDCONFIG ]]

test.Step(
  "Verify disk (DOS 3.3) with bad sectors matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("Y") -- Verify
    cii.WaitForSelection("FILESVERIFY") -- two items are selected, Files and Verify
    apple2.Type("D") -- Disk
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("TOTAL:")
    local screen = apple2.GrabTextScreen()
    test.ExpectIMatch(screen, "ERROR TRACK %$0F", "Verify Disk did not find 2 bad sectors")
    test.ExpectIMatch(screen, "SECTOR %$B", "Verify Disk did not find 2 bad sectors")
    test.ExpectIMatch(screen, "ERROR TRACK %$1E", "Verify Disk did not find 2 bad sectors")
    test.ExpectIMatch(screen, "SECTOR %$3", "Verify Disk did not find 2 bad sectors")
    test.ExpectIMatch(screen, "2 ERRORS", "Verify Disk did not find 2 bad sectors")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)
