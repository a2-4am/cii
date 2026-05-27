--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[
  This tests View Files as Text on a text file from a ProDOS formatted disk, matching v8.4 behavior.
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'lorem.do'"

  ======================================== ENDCONFIG ]]

test.Step(
  "View Files as Text on text file (ProDOS) matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("V") -- View Files
    cii.WaitForSelection("VALUESVIEW FILES") -- two items are selected, Values and View Files
    apple2.Type("T") -- Text
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    apple2.ReturnKey()
    cii.WaitForScreenContains("%[E]NTER FILENAME, %[G]O, %[ESC]%-EXIT")
    -- disk only has 1 file so it should already be selected
    apple2.Type("G") -- enter view mode
    cii.WaitForScreenContains("%[RETURN]%-CONTINUE, %[ESC]%-EXIT")
    test.ExpectIMatch(apple2.GrabTextScreen(), "648", "View Files as Text behavior does not match v8.4") -- visible byte offset
    test.ExpectIMatch(apple2.GrabTextScreen(), "UAT VITAE, ELEIFEND AC,ENIM%. ALIQUAM LOR", "View Files as Text behavior does not match v8.4")
    apple2.ReturnKey() -- next page
    cii.WaitForScreenContains("1296") -- visible byte offset
    test.ExpectIMatch(apple2.GrabTextScreen(), "T,IMPERDIET A, VENENATIS VITAE, JUSTO%. N", "View Files as Text behavior does not match v8.4")
    apple2.ReturnKey() -- next page
    cii.WaitForScreenContains("1944") -- visible byte offset
    test.ExpectIMatch(apple2.GrabTextScreen(), ", NASCETUR RIDICULUS MUS%. DONEC QUAM FEL", "View Files as Text behavior does not match v8.4")
    apple2.ReturnKey() -- next page
    cii.WaitForScreenContains("2592") -- visible byte offset
    test.ExpectIMatch(apple2.GrabTextScreen(), "E%. CURABITUR ULLAMCORPER ULTRICIES NISI%.", "View Files as Text behavior does not match v8.4")
    apple2.ReturnKey() -- next page
    cii.WaitForScreenContains("3241") -- visible byte offset
    test.ExpectIMatch(apple2.GrabTextScreen(), "TOR EU, CONSEQUAT VITAE, ELEIFEND AC,ENI", "View Files as Text behavior does not match v8.4")
    apple2.ReturnKey() -- next page
    cii.WaitForScreenContains("3889") -- visible byte offset
    test.ExpectIMatch(apple2.GrabTextScreen(), "STO, RHONCUS UT,IMPERDIET A, VENENATIS V", "View Files as Text behavior does not match v8.4")
    apple2.ReturnKey() -- next page
    cii.WaitForScreenContains("4537") -- visible byte offset
    test.ExpectIMatch(apple2.GrabTextScreen(), "RTURIENTMONTES, NASCETUR RIDICULUS MUS%. ", "View Files as Text behavior does not match v8.4")
    apple2.ReturnKey() -- next page
    cii.WaitForScreenContains("5185") -- visible byte offset
    test.ExpectIMatch(apple2.GrabTextScreen(), " NISI VEL AUGUE. CURABITUR ULLAMCORPER U", "View Files as Text behavior does not match v8.4")
    apple2.ReturnKey() -- next page
    cii.WaitForScreenContains("5833") -- visible byte offset
    test.ExpectIMatch(apple2.GrabTextScreen(), "LIGULA, PORTTITOR EU, CONSEQUAT VITAE, E", "View Files as Text behavior does not match v8.4")
    apple2.ReturnKey() -- last page
    cii.WaitForScreenContains("6656") -- visible byte offset
    test.ExpectIMatch(apple2.GrabTextScreen(), "C QUAM FELIS, ULTRICIES NEC, PELLENTESQU", "View Files as Text behavior does not match v8.4")
    apple2.ReturnKey() -- back to file selection
    cii.WaitForScreenContains("%[E]NTER FILENAME, %[G]O, %[ESC]%-EXIT")
    apple2.EscapeKey() -- back to main menu
    cii.WaitForMainMenu()
end)
