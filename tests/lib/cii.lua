local cii = {}

local util = require("util")
local apple2 = require("apple2")

local machine = manager.machine
-- System class is one of: "apple2", "apple2e", "apple2c", "apple2gs"
local system_class = manager.machine.system.parent
if system_class == 0 then
  system_class = manager.machine.system.name
end

function cii.GetSelection()
  return apple2.GrabInverseText():upper()
end

function cii.ScreenContains(s)
  return apple2.GrabTextScreen():upper():find(s)
end

function cii.Is80Column()
  return system_class ~= "apple2" and apple2.ReadSSW("RD80VID") > 127
end

function cii.Is40Column()
  return not cii.Is80Column()
end

function cii.WaitFor80Column(options)
  util.WaitFor(
    "80-column mode",
    function()
      return cii.Is80Column()
    end,
    options)
end

function cii.WaitFor40Column(options)
  util.WaitFor(
    "40-column mode",
    function()
      return cii.Is40Column()
    end,
    options)
end

function cii.WaitForScreenContains(s, options)
  util.WaitFor(
    s,
    function()
      return cii.ScreenContains(s)
    end,
    options)
end

function cii.WaitForSelection(s, options)
  util.WaitFor(
    s,
    function()
      return cii.GetSelection() == s
    end,
    options)
end

function cii.WaitForMainMenu(options)
  cii.WaitForScreenContains("COPY ]%[ REBOOT", options)
end

function cii.Beat()
  emu.wait(1/60)
end

return cii
