--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests that various operations continue to work after cataloging a 32MB disk. v8.4 fails this test because cataloging such a large disk overwrites important application data in memory, leading to I/O errors on any subsequent floppy operation.
]]

--[[ BEGINCONFIG ========================================

  MODEL="apple2p"
  MODELARGS="-sl4 'cffa202' -sl5 'diskiing' -sl6 'diskiing'"
  DISKARGS="-hard1 'bootable-32.2mg' -flop1 'formatted-dos33-by-v84.do' -flop2 'formatted-prodos-by-v84.do' -flop3 $FLOPIMG -flop4 'DOS 3.3 System Master-with-bad-sectors.woz'"
  CHECKAUXMEMORY="false"

  ======================================== ENDCONFIG ]]

test.Step(
  "Catalog 32MB volume",
  function()
    cii.WaitForMainMenu()
    apple2.Type("C") -- Catalog
    cii.WaitForSelection("CATALOG DISKNORMAL") -- two items are selected, Catalog Disk and Normal
    apple2.Type("N") -- Normal
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("4") -- Slot 4, Drive 1
    cii.WaitForSelection("SLOT 4  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    test.ExpectIMatch(apple2.GrabTextScreen(), "BLOCKS FREE:65479 USED:56    TOTAL:65535", "32MB catalog failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then catalog floppy (DOS 3.3)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("C") -- Catalog
    cii.WaitForSelection("CATALOG DISKNORMAL") -- two items are selected, Catalog Disk and Normal
    apple2.Type("N") -- Normal
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    test.ExpectIMatch(apple2.GrabTextScreen(), "SECTORS FREE:528  USED:32    TOTAL:560", "After 32MB catalog, catalog floppy (DOS 3.3) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then catalog floppy (ProDOS)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("C") -- Catalog
    cii.WaitForSelection("CATALOG DISKNORMAL") -- two items are selected, Catalog Disk and Normal
    apple2.Type("N") -- Normal
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("52") -- Slot 5, Drive 2
    cii.WaitForSelection("SLOT 5  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    test.ExpectIMatch(apple2.GrabTextScreen(), "BLOCKS FREE:273   USED:7     TOTAL:280", "After 32MB catalog, catalog floppy (ProDOS) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then delete files (DOS 3.3)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("D") -- Delete
    cii.WaitForSelection("DELETEFILES") -- two items are selected, Delete and Files
    apple2.Type("F") -- Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, delete files (DOS 3.3) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then delete files (ProDOS)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("D") -- Delete
    cii.WaitForSelection("DELETEFILES") -- two items are selected, Delete and Files
    apple2.Type("F") -- Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("52") -- Slot 5, Drive 2
    cii.WaitForSelection("SLOT 5  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, delete files (ProDOS) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then delete disk (DOS 3.3)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("D") -- Delete
    cii.WaitForSelection("DELETEFILES") -- two items are selected, Delete and Files
    apple2.Type("D") -- Disk
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("READY TO DELETE %(Y/N%) %?")
    test.ExpectIMatch(apple2.GrabTextScreen(), "DISK VOLUME 254", "After 32MB catalog, delete disk (DOS 3.3) failed")
    apple2.EscapeKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then delete disk (ProDOS)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("D") -- Delete
    cii.WaitForSelection("DELETEDISK") -- two items are selected, Delete and Disk (from previous step)
    apple2.Type("D") -- Disk
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("52") -- Slot 5, Drive 2
    cii.WaitForSelection("SLOT 5  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("READY TO DELETE %(Y/N%) %?")
    test.ExpectIMatch(apple2.GrabTextScreen(), "/BLANK", "After 32MB catalog, delete disk (ProDOS) failed")
    apple2.EscapeKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then delete DOS",
  function()
    cii.WaitForMainMenu()
    apple2.Type("D") -- Delete
    cii.WaitForSelection("DELETEDISK") -- two items are selected, Delete and Disk (from previous step)
    apple2.Type("O") -- DOS
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("READY TO DELETE %(Y/N%) %?")
    test.ExpectIMatch(apple2.GrabTextScreen(), "DISK VOLUME 254", "After 32MB catalog, delete DOS failed")
    apple2.EscapeKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then lock/unlock files (DOS 3.3)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("L") -- Lock/Unlock
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, lock/unlock files (DOS 3.3) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then lock/unlock files (ProDOS)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("L") -- Lock/Unlock
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("52") -- Slot 5, Drive 2
    cii.WaitForSelection("SLOT 5  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, lock/unlock files (ProDOS) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then rename files (DOS 3.3)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("R") -- Rename
    cii.WaitForSelection("RENAMEFILES") -- two items are selected, Rename and Files
    apple2.Type("F") -- Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, rename files (DOS 3.3) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then rename files (ProDOS)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("R") -- Rename
    cii.WaitForSelection("RENAMEFILES") -- two items are selected, Rename and Files
    apple2.Type("F") -- Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("52") -- Slot 5, Drive 2
    cii.WaitForSelection("SLOT 5  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, rename files (ProDOS) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then rename volume",
  function()
    cii.WaitForMainMenu()
    apple2.Type("R") -- Rename
    cii.WaitForSelection("RENAMEFILES") -- two items are selected, Rename and Files
    apple2.Type("V") -- Volume
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("52") -- Slot 5, Drive 2
    cii.WaitForSelection("SLOT 5  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("NEW VOLUME NAME: /")
    test.ExpectIMatch(apple2.GrabTextScreen(), "/BLANK", "After 32MB catalog, rename volume (ProDOS) failed")
    apple2.EscapeKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then alphabetize catalog (DOS 3.3)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("A") -- Alphabetize Catalog
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, alphabetize catalog (DOS 3.3) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then alphabetize catalog (ProDOS)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("A") -- Alphabetize Catalog
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("52") -- Slot 5, Drive 2
    cii.WaitForSelection("SLOT 5  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, alphabetize catalog (ProDOS) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then verify files (DOS 3.3)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("Y") -- Verify
    cii.WaitForSelection("FILESVERIFY") -- two items are selected, Files and Verify
    apple2.Type("F") -- Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE MARKER, %[E]NTER")
    apple2.Type("E")
    cii.WaitForScreenContains("ENTER FILENAME %(,OPT%. FILETYPES%)")
    apple2.TypeLine("RENUMBER") -- will match RENUMBER file
    cii.WaitForScreenContains("%[RETURN]%-TOGGLE MARKER, %[E]NTER")
    apple2.Type("G") -- Go
    cii.WaitForScreenContains("I/O ERROR: TRACK %$1E, SECTOR %$3")
    test.ExpectMatch(cii.GetSelection(), "RENUMBER", "After 32MB catalog, verify files (DOS 3.3) failed")
    apple2.EscapeKey() -- Return here would show the total errors, but we don't care
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then verify files (ProDOS)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("Y") -- Verify
    cii.WaitForSelection("FILESVERIFY") -- two items are selected, Files and Verify
    apple2.Type("F") -- Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("52") -- Slot 5, Drive 2
    cii.WaitForSelection("SLOT 5  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, verify files (ProDOS) failed")
    apple2.EscapeKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then verify disk",
  function()
    cii.WaitForMainMenu()
    apple2.Type("Y") -- Verify
    cii.WaitForSelection("FILESVERIFY") -- two items are selected, Files and Verify
    apple2.Type("D") -- Disk
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    test.ExpectIMatch(apple2.GrabTextScreen(), "SECTOR %$B", "After 32MB catalog, verify disk failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then view files as values (DOS 3.3)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("V") -- View Files
    cii.WaitForSelection("VALUESVIEW FILES") -- two items are selected, Values and View Files
    apple2.Type("V") -- Values
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, view files as values (DOS 3.3) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then view files as values (ProDOS)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("V") -- View Files
    cii.WaitForSelection("VALUESVIEW FILES") -- two items are selected, Values and View Files
    apple2.Type("V") -- Values
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("52") -- Slot 5, Drive 2
    cii.WaitForSelection("SLOT 5  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, view files as values (ProDOS) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then view files as text (DOS 3.3)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("V") -- View Files
    cii.WaitForSelection("VALUESVIEW FILES") -- two items are selected, Values and View Files
    apple2.Type("T") -- Text
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, view files as text (DOS 3.3) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then view files as text (ProDOS)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("V") -- View Files
    cii.WaitForSelection("TEXTVIEW FILES") -- two items are selected, Text and View Files (from previous step)
    apple2.Type("T") -- Text
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("52") -- Slot 5, Drive 2
    cii.WaitForSelection("SLOT 5  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, view files as text (ProDOS) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then map disk (DOS 3.3)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("M") -- Map Disk
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("%[RETURN]%-CONTINUE, %[ESC]%-EXIT")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, map disk (DOS 3.3) failed")
    apple2.ReturnKey()
    cii.WaitForScreenContains("0123456789ABCDEF0123456789ABCDEF012")
    cii.WaitForScreenContains("%[RETURN]%-CONTINUE, %[ESC]%-EXIT")
    test.ExpectEquals(cii.GetSelection(), "********************************", "After 32MB catalog, map disk (DOS 3.3) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then map disk (ProDOS)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("M") -- Map Disk
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("52") -- Slot 5, Drive 2
    cii.WaitForSelection("SLOT 5  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("%[RETURN]%-CONTINUE, %[ESC]%-EXIT")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, map disk (ProDOS) failed")
    apple2.ReturnKey()
    cii.WaitForScreenContains("0123456789ABCDEF0123456789ABCDEF012")
    cii.WaitForScreenContains("%[RETURN]%-CONTINUE, %[ESC]%-EXIT")
    test.ExpectEquals(cii.GetSelection(), "**************", "After 32MB catalog, map disk (DOS 3.3) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then change boot program",
  function()
    cii.WaitForMainMenu()
    apple2.Type("B") -- Change Boot Program
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("%[E]NTER FILENAME, %[G]O, %[ESC]%-EXIT") -- note different prompt wording from v8.4
    test.ExpectIMatch(apple2.GrabTextScreen(), "FILE: HELLO", "After 32MB catalog, change boot program (DOS 3.3) failed")
    apple2.EscapeKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then undelete files (DOS 3.3)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("U") -- Undelete Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("5") -- Slot 5, Drive 1
    cii.WaitForSelection("SLOT 5  DRIVE 1")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, undelete files (DOS 3.3) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then undelete files (ProDOS)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("U") -- Undelete Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("52") -- Slot 5, Drive 2
    cii.WaitForSelection("SLOT 5  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("PRESS %[RETURN]")
    -- valid test even though it finds no files because v8.4 wouldn't even be able to read the disk catalog
    test.ExpectIMatch(apple2.GrabTextScreen(), "NO FILES", "After 32MB catalog, undelete files (ProDOS) failed")
    apple2.ReturnKey()
    cii.WaitForMainMenu()
end)

test.Step(
  "Catalog 32MB volume then create subdirectory (ProDOS)",
  function()
    cii.WaitForMainMenu()
    apple2.Type("/") -- Create Subdirectory
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("52") -- Slot 5, Drive 2
    cii.WaitForSelection("SLOT 5  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("SUBDIRECTORY NAME:")
    test.ExpectIMatch(apple2.GrabTextScreen(), "/BLANK", "After 32MB catalog, create subdirectory (ProDOS) failed")
    apple2.EscapeKey()
    cii.WaitForMainMenu()
end)
