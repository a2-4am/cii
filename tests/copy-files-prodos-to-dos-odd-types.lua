--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests copying several binary files from a ProDOS disk to a DOS 3.3 disk. The operation should succeed, matching v8.4 behavior. C2Reboot matches v8.4 with the exact order of files in the disk catalog, the exact placement of sectors for each file on disk, the contents of each sector, and the filetype of each file. All of these files are odd filetypes, some of which are supported by C2Reboot in catalog displays. (Copy II Plus simply displays their 1-byte hex code in lieu of a filetype.) However, catalog display logic and 'is this a binary file' logic are entirely separate, and all of these files should be treated as binary ('B' type in DOS), despite being 'recognized' in catalog displays.
]]

--[[ BEGINCONFIG ========================================

  MODEL="apple2p"
  MODELARGS="-sl5 'diskiing'"
  DISKARGS="-flop1 'formatted-dos33-by-v84.do' -flop2 'filetypes-filecopied-to-DOS-by-v84.do' -flop3 $FLOPIMG -flop4 'filetypes.do'"
  CHECKAUXMEMORY="false"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":sl5:diskiing:0:525"]
local target_filename = s5d1.filename
local s5d2 = manager.machine.images[":sl5:diskiing:1:525"]
local reference_filename = s5d2.filename
local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local source_filename = s6d2.filename
s5d1:unload()
s5d2:unload()

test.Step(
  "Copy oddly typed files from ProDOS disk to DOS 3.3 disk matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    s6d1:load(target_filename)
    apple2.Type("X") -- Copy
    cii.WaitForSelection("COPYFILES") -- two items are selected, Copy and Files
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT SOURCE DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT TARGET DEVICE:")
    apple2.Type("6") -- Slot 6, Drive 1
    cii.WaitForSelection("SLOT 6  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("COPY FILES")
    cii.WaitForScreenContains("%[RETURN]%-MARK FILE, %[U]NMARK, %[E]NTER")
    apple2.Type("E") -- Enter Filename (pattern)
    cii.WaitForScreenContains("ENTER FILENAME %(,OPT%. FILETYPES%)")
    apple2.TypeLine("=B=") -- will match several oddly typed files
    cii.WaitForScreenContains("%[RETURN]%-MARK FILE, %[U]NMARK, %[E]NTER")
    apple2.Type("G") -- Go
    cii.WaitForMainMenu()
    s6d1:unload()
    test.ExpectBinaryEquals(util.SlurpFile(target_filename),
                            util.SlurpFile(reference_filename),
                            "Copy oddly typed files from ProDOS disk to DOS 3.3 disk does not match v8.4")
end)
