--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests Lock Files on a ProDOS disk. The operation should succeed, matching v8.4 behavior. The final disk image should be identical to one where the same operation was performed by v8.4.
]]

--[[ BEGINCONFIG ========================================

  MODEL="apple2p"
  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'beagle-graphics.do' -flop3 $FLOPIMG -flop4 'beagle-graphics-unlocked-by-v84.do'"
  CHECKAUXMEMORY="false"

  ======================================== ENDCONFIG ]]

local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local actual_filename = s6d2.filename
local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local reference_filename = s5d1.filename
s5d1:unload()

test.Step(
  "Lock Files (ProDOS) matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("L") -- Lock/Unlock
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("LOCK/UNLOCK FILES")
    cii.WaitForSelection("BEAGLE.GRAPHICS")
    apple2.ReturnKey() -- select root directory
    cii.WaitForScreenContains("LOCK/UNLOCK FILES")
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE ASTERISK")
    apple2.Type("E") -- Enter Filename (pattern)
    cii.WaitForScreenContains("ENTER FILENAME %(,OPT%. FILETYPES%)")
    apple2.TypeLine("=,SYS") -- will match PRODOS, BASIC.SYSTEM
    cii.WaitForScreenContains("%[L]%OCK OR %[U]NLOCK")
    apple2.Type("L") -- Lock
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE ASTERISK")
    apple2.Type("G") -- Go
    cii.WaitForMainMenu()
    s6d2:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(actual_filename),
                            util.SlurpFile(reference_filename),
                            "Lock Files (ProDOS) disk image differs from v8.4")
end)
