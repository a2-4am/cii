--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests that C2Reboot does not detect bad sectors when attempting to verify a disk with no bad sectors, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'filetypes.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "Verify disk (ProDOS) with no bad sectors matches v8.4 behavior",
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
    test.ExpectIMatch(screen, "0 ERRORS", "Verify Disk unexpectedly found bad sectors")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)
