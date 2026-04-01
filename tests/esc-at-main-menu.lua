--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
This tests that pressing Esc at the top level of the main menu does not crash. C2Reboot improves on v8.4's menu handling behavior. For example, v8.4 will flash and redisplay the entire menu if you press Esc at the top level of the main menu, while C2Reboot will simply do nothing. At one point C2Reboot would crash, which was not considered an improvement.
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
