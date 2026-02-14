--[[ BEGINCONFIG ========================================

  MODEL="apple2gs"
  MODELARGS="-sl7 ''"
  DISKARGS="-flop1 $FLOPIMG -flop3 'System Disk v3.1 800K.po' -flop4 'blank 800K.po'"

  ======================================== ENDCONFIG ]]

local s5d1 = manager.machine.images[":fdc:2:35dd"]
local source_filename = s5d1.filename
local s5d2 = manager.machine.images[":fdc:3:35dd"]
local target_filename = s5d2.filename
s5d2:unload()

test.Step(
  "Copy Disk (800K) on 1.25MB IIgs copies in 1 pass, matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("X") -- Copy
    cii.WaitForSelection("COPYFILES") -- two items are selected, Copy and Files
    apple2.Type("D") -- Disk
    cii.WaitForScreenContains("SELECT SOURCE DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT TARGET DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("INSERT SOURCE DISK")
    apple2.ReturnKey()
    cii.WaitForScreenContains("READING BLOCK")
    -- increase timeout because it reads the entire disk in 1 pass,
    -- which takes longer than the default timeout
    cii.WaitForScreenContains("INSERT TARGET DISK",{timeout=120})
    s5d1:load(target_filename)
    apple2.ReturnKey()
    cii.WaitForScreenContains("WRITING BLOCK")
    cii.WaitForScreenContains("COPY SAME ONTO ANOTHER DISK",{timeout=240})
    apple2.Type("N")
    cii.WaitForMainMenu()
    s5d1:unload() -- eject disk (ensures disk image is updated)
    test.ExpectBinaryEquals(util.SlurpFile(source_filename),
                            util.SlurpFile(target_filename),
                            "Copy Disk target disk image differs from source")
end)
