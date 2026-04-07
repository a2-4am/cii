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

function cii.ReadPartialFile(pathname, seek_in_bytes, size_in_bytes)
  local f = assert(io.open(pathname, "rb"))
  f:seek("set", seek_in_bytes)
  local bytes = f:read(size_in_bytes)
  assert(f:close())
  return bytes
end

function cii.DisableRTC()
  cii.WaitForMainMenu()
  apple2.WriteRAMDevice(0xBF06, 0x60) -- disable clock
  apple2.WriteRAMDevice(0xBF90, 0x00) -- set date/time to 0
  apple2.WriteRAMDevice(0xBF91, 0x00)
  apple2.WriteRAMDevice(0xBF92, 0x00)
  apple2.WriteRAMDevice(0xBF93, 0x00)
  local machid = apple2.ReadRAMDevice(0xBF98)
  machid = machid&0xFE -- strip clock bit of ProDOS MACHID global
  apple2.WriteRAMDevice(0xBF98, machid)
  apple2.Type("E") -- Enter Date
  apple2.EscapeKey() -- refreshes main menu, which refreshes CRTDAT and MODDAT globals
end

return cii
