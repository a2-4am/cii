--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests copying a file to a disk where the file already exists. The operation should be interrupted by a prompt saying the file already exists and asking what to do, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'beagle-graphics.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "Copy Files when file exists prompts for action, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("X") -- Copy
    cii.WaitForSelection("COPYFILES") -- two items are selected, Copy and Files
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT SOURCE DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT TARGET DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForSelection("BEAGLE.GRAPHICS")
    apple2.ReturnKey() -- select root directory
    cii.WaitForScreenContains("COPY FILES")
    cii.WaitForScreenContains("%[RETURN]%-MARK FILE, %[U]NMARK, %[E]NTER")
    apple2.Type("E") -- Enter Filename (pattern)
    cii.WaitForScreenContains("ENTER FILENAME %(,OPT%. FILETYPES%)")
    apple2.TypeLine("=,.BAS") -- will match all BASIC files
    cii.WaitForScreenContains("%[RETURN]%-MARK FILE, %[U]NMARK, %[E]NTER")
    apple2.Type("G") -- Go
    cii.WaitForScreenContains("INSERT TARGET DISK")
    apple2.ReturnKey() -- do not switch disks
    cii.WaitForSelection("BEAGLE.GRAPHICS")
    apple2.ReturnKey() -- select root directory
    cii.WaitForScreenContains("%[C]OPY ANYWAY, %[N]EW NAME, %[D]ON'T COPY")
    cii.WaitForScreenContains("%[ESC]%-EXIT COPY")
    local screen = apple2.GrabTextScreen()
    test.ExpectIMatch(screen, "FILE: STARTUP", "Copy Files did not prompt correctly")
    test.ExpectIMatch(screen, "ALREADY EXISTS & IS LOCKED%.  NOW WHAT%?", "Copy Files did not prompt correctly")
end)
