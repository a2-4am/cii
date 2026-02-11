--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[ BEGINCONFIG ========================================

  DISKARGS="-flop1 $FLOPIMG -flop2 'filetypes.do'"

  ======================================== ENDCONFIG ]]

local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local last_line = {
  "COLORS.STD",
  "PRESS %[RETURN]",
}
local expected_files = {
  {
    "/FILETYPES",
    "   NAME           TYPE  BLKS  MODIFIED",
    "   SOUND%.SETTINGS  CFG     1  10%-FEB%-26",
    "   CHAR%.FST        FST     5  10%-FEB%-26",
    "   MELTDOWNSRC%.SHK LBR    18  30%-JAN%-18",
    "   MEMO%.PFS        PFS     5  16%-SEP%-85",
    "   TAIL            P8C     1  20%-FEB%-90",
    "   FTYPE%.HYPERCARD FTD     1  05%-DEC%-90",
    "   T40%.README      GWP     1  28%-AUG%-11",
    "   CAR%.PAYMENTS    GSS     6  01%-JUL%-94",
    "   AE%.PHONEBOOK    GDB     1  19%-MAR%-91",
    "   GS%.TEMPLATE     DRW    13  05%-NOV%-90",
    "   WORD%.PROCESSING GDP    23  29%-OCT%-91",
    "   HOME%.STACK      HMD     5  03%-DEC%-93",
    "   JOYSTICK%.DRVR   LDF     1  17%-FEB%-93",
    "   PIC2            ANI    13  31%-JUL%-88",
    "   COLORS%.STD      PAL     1  23%-OCT%-91",
  },
  {
    "/FILETYPES",
    "   COLORS%.STD      PAL     1  23%-OCT%-91",
    "   CUSTOM%.OBJS     OOG    11  15%-SEP%-88",
    "   GENERAL         CDV     1  10%-FEB%-26",
    "   AULD%.LANG%.SYNE  MUS    16  21%-JUL%-88",
    "   DEMO%.BNK        INS    12  07%-NOV%-90",
    "   HAPPY           MDI     6  19%-SEP%-89",
    "   SOSUMI          SND     1  04%-NOV%-91",
    "BLOCKS FREE:131   USED:149   TOTAL:280",
    "PRESS %[RETURN]",
  }
}

test.Step(
  "Catalog (ProDOS) shows new filetypes",
  function()
    cii.WaitForMainMenu()
    apple2.Type("C") -- Catalog
    cii.WaitForSelection("CATALOGNORMAL") -- two items are selected, Catalog and Normal
    apple2.ReturnKey()
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    for pagenum,lines in ipairs(expected_files) do
      apple2.ReturnKey()
      cii.WaitForScreenContains(last_line[pagenum])
      local pagetext = apple2.GrabTextScreen():upper()
      for dummy,line in ipairs(lines) do
        test.Expect(pagetext:find(line), "Catalog with new filetypes does not contain " .. line)
      end
    end
end)
