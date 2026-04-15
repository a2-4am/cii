--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  At one point a label confusion introduced a regression where entering a filename then canceling with Esc would corrupt the screen. This tests that regression.
]]

test.Step(
  "Cancel 'Enter Filename' restores selection",
  function()
    cii.WaitForMainMenu()
    apple2.Type("X") -- Copy
    cii.WaitForSelection("COPYFILES") -- two items are selected, Copy and Files
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT SOURCE DEVICE:")
    apple2.Type("6") -- Slot 6, Drive 1
    cii.WaitForSelection("SLOT 6  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT TARGET DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("COPY FILES")
    cii.WaitForScreenContains("%[RETURN]%-MARK FILE, %[U]NMARK, %[E]NTER")
    local selection1 = cii.GetSelection()
    apple2.Type("E") -- Enter Filename (pattern)
    cii.WaitForScreenContains("ENTER FILENAME %(,OPT%. FILETYPES%)")
    apple2.EscapeKey() -- cancel
    cii.WaitForScreenContains("%[RETURN]%-MARK FILE, %[U]NMARK, %[E]NTER")
    local selection2 = cii.GetSelection()
    test.ExpectEquals(selection2, selection1,
                      "Cancel 'Enter Filename' does not restore selection")
end)
