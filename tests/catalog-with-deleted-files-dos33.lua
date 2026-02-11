--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'DOS 3.3 System Master-deleted-files-by-v84.do'"

  ======================================== ENDCONFIG ]]

local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local last_line = {
  "START13",
  "PRESS %[RETURN]",
}
local expected_files = {
  {
    "DISK VOLUME 254",
    "  %*A 003 HELLO",
    "  %*I 003 APPLESOFT",
    "  %*B 006 LOADER%.OBJ0",
    "  %*B 042 FPBASIC",
    "  %*B 042 INTBASIC",
    "  %*A 003 MASTER",
    "  %*B 009 MASTER CREATE",
    "D %*I 009 COPY",
    "D %*B 003 COPY%.OBJ0",
    "D %*A 009 COPYA",
    "  %*B 003 CHAIN",
    "  %*A 014 RENUMBER",
    "  %*A 003 FILEM",
    "  %*B 020 FID",
    "  %*A 003 CONVERT13",
    "  %*B 027 MUFFIN",
    "  %*A 003 START13",
  },
  {
    "DISK VOLUME 254",
    "  %*B 007 BOOT13",
    "  %*A 004 SLOT#",
    "SECTORS FREE:304  USED:256   TOTAL:560",
    "PRESS %[RETURN]",
  }
}

test.Step(
  "Catalog w/Deleted Files (DOS 3.3) matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("C") -- Catalog
    cii.WaitForSelection("CATALOGNORMAL") -- two items are selected, Catalog and Normal
    apple2.Type("D") -- Deleted Files
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    for pagenum,lines in ipairs(expected_files) do
      apple2.ReturnKey()
      cii.WaitForScreenContains(last_line[pagenum])
      local pagetext = apple2.GrabTextScreen():upper()
      for dummy,line in ipairs(lines) do
        test.Expect(pagetext:find(line), "Catalog w/File Lengths does not contain " .. line)
      end
    end
end)
