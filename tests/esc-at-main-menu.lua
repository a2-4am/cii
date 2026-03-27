--[[
  License:MIT
  Copyright (C) 2026 4am
]]

test.Step(
  "'Esc' at main menu does not crash",
  function()
    cii.WaitForMainMenu()
    apple2.EscapeKey() -- should be a no-op because no submenu is open
    test.ExpectEquals(cii.GetSelection(), "COPY", "'Esc' at main menu changed selection or crashed")
    apple2.Type("X") -- open Copy submenu
    cii.WaitForSelection("COPYFILES") -- two items are selected, Copy and Files
    apple2.EscapeKey()
    cii.WaitForSelection("COPY")
    apple2.EscapeKey() -- should again be a no-op because no submenu is open
    test.ExpectEquals(cii.GetSelection(), "COPY", "'Esc' at main menu changed selection or crashed")
end)
