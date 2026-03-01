--[[
  License:MIT
  Copyright (C) 2026 4am
]]

--[[ BEGINCONFIG ========================================

  MODEL="apple2p"
  MODELARGS="-sl0 'lang'"
  DISKARGS="-flop1 $FLOPIMG -flop2 'DOS 3.3 System Master.do'"
  CHECKAUXMEMORY="false"

  ======================================== ENDCONFIG ]]

local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]
local last_line = {
  "A672",
  "A3072",
  "SECTORS FREE"
}
local expected_files = {
  {
    "DISK VOLUME 254",
    "  %*A 003 HELLO",
    "       L419  %(L%$01A3%)",
    "  %*I 003 APPLESOFT",
    "       L412  %(L%$019C%)",
    "  %*B 006 LOADER%.OBJ0",
    "       A4096, L1092  %(A%$1000, L%$0444%)",
    "  %*B 042 FPBASIC",
    "       A53248, L10240  %(A%$D000, L%$2800%)",
    "  %*B 042 INTBASIC",
    "       A53248, L10240  %(A%$D000, L%$2800%)",
    "  %*A 003 MASTER",
    "       L460  %(L%$01CC%)",
    "  %*B 009 MASTER CREATE",
    "       A2048, L1791  %(A%$0800, L%$06FF%)",
    "  %*I 009 COPY",
    "       L1824  %(L%$0720%)",
    "  %*B 003 COPY%.OBJ0",
    "       A672, L299  %(A%$02A0, L%$012B%)",
  },
  {
    "DISK VOLUME 254",
    "  %*B 003 COPY%.OBJ0",
    "       A672, L299  %(A%$02A0, L%$012B%)",
    "  %*A 009 COPYA",
    "       L1834  %(L%$072A%)",
    "  %*B 003 CHAIN",
    "       A520, L453  %(A%$0208, L%$01C5%)",
    "  %*A 014 RENUMBER",
    "       L3071  %(L%$0BFF%)",
    "  %*A 003 FILEM",
    "       L430  %(L%$01AE%)",
    "  %*B 020 FID",
    "       A2051, L4687  %(A%$0803, L%$124F%)",
    "  %*A 003 CONVERT13",
    "       L439  %(L%$01B7%)",
    "  %*B 027 MUFFIN",
    "       A2051, L6397  %(A%$0803, L%$18FD%)",
    "  %*A 003 START13",
    "       L439  %(L%$01B7%)",
    "  %*B 007 BOOT13",
    "       A3072, L1280  %(A%$0C00, L%$0500%)",
  },
  {
    "DISK VOLUME 254",
    "  %*A 004 SLOT#",
    "       L526  %(L%$020E%)",
    "SECTORS FREE:283  USED:277   TOTAL:560",
  }
}

test.Step(
  "Catalog Disk w/File Lengths (DOS 3.3) on 40-column II+ matches v8.4 behavior",
  function()
    cii.WaitForMainMenu()
    apple2.Type("C") -- Catalog
    cii.WaitForSelection("CATALOG DISKNORMAL") -- two items are selected, Catalog Disk and Normal
    apple2.Type("F") -- File Lengths
    cii.WaitForScreenContains("SELECT DEVICE:")
    apple2.Type("62") -- Slot 6, Drive 2
    cii.WaitForSelection("SLOT 6  DRIVE 2")
    for pagenum,lines in ipairs(expected_files) do
      apple2.ReturnKey()
      cii.WaitForScreenContains(last_line[pagenum])
      local pagetext = apple2.GrabTextScreen():upper()
      for dummy,line in ipairs(lines) do
        test.Expect(pagetext:find(line), "Catalog Disk w/File Lengths does not contain " .. line)
      end
    end
end)
