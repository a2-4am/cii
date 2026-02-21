DISKVOLUME=COPY.II.REBOOT
SYSNAME=UTIL.SYSTEM

BUILDDIR=build
BUILDLOG=$(BUILDDIR)/log
BUILDDISK=$(BUILDDIR)/$(DISKVOLUME).po

# https://brutaldeluxe.fr/products/crossdevtools/merlin/
# https://github.com/lifepillar/homebrew-appleii/blob/HEAD/Formula/merlin32.rb
MERLINBIN=Merlin32
MERLINLIB=/opt/homebrew/opt/merlin32/lib
MERLIN=$(MERLINBIN) -V $(MERLINLIB)
POSTMERLIN = (mv "$(SRCDIR)/$(notdir $@)_S01_Segment1_Output.txt" "$(BUILDDIR)"/ && mv "$(SRCDIR)/$(notdir $@)_Symbols.txt" "$(BUILDDIR)"/)

# https://github.com/mach-kernel/cadius
CADIUS=cadius

# https://github.com/einar-saukas/ZX0
# note: -b flag to pack backwards
# you can also add a -q flag during development
# to do worse compression at a more reasonable speed
# (does not affect format, so unpacker still works)
ZX0=zx0 -b

# macro to compress file with ZX0 then transpose first 7 bytes to end of file
# (used for self-decompressing modules)
X7 = ($(ZX0) "$1" "$@" && dd if="$@" of="$@.HEAD" bs=1 count=7 && dd if="$@" of="$@.TAIL" bs=1 skip=7 && cat "$@.TAIL" "$@.HEAD" > "$@")

SRCDIR=src
SOURCES=$(wildcard src/*.S)
MMO=$(BUILDDIR)/MM.O
MMX7=$(BUILDDIR)/MM.X7
MMVARS=$(BUILDDIR)/MM.VARS.S
DZX0TURBOO=$(BUILDDIR)/DZX0TURBO.O
DZX0TURBOVARS=$(BUILDDIR)/DZX0TURBO.VARS.S
BOOTSEC33O=$(BUILDDIR)/BOOTSEC.33.O
BOOTSEC33VARS=$(BUILDDIR)/BOOTSEC.33.VARS.S
BOOTSECPROO=$(BUILDDIR)/BOOTSEC.PRO.O
BOOTSECPROVARS=$(BUILDDIR)/BOOTSEC.PRO.VARS.S
PHRWTSO=$(BUILDDIR)/PHRWTS.O
PHRWTSX7=$(BUILDDIR)/PHRWTS.X7
PHRWTSVARS=$(BUILDDIR)/PHRWTS.VARS.S
MESSAGES2O=$(BUILDDIR)/MESSAGES2.O
MESSAGES2X7=$(BUILDDIR)/MESSAGES2.X7
MESSAGES2VARS=$(BUILDDIR)/MESSAGES2.VARS.S
FILERO=$(BUILDDIR)/FILER.O
FILERX=$(BUILDDIR)/FILER.X
FILERVARS=$(BUILDDIR)/FILER.VARS.S
RDDATAO=$(BUILDDIR)/RDDATA.O
RDDATAX7=$(BUILDDIR)/RDDATA.X7
RDDATAVARS=$(BUILDDIR)/RDDATA.VARS.S
CATLIBO=$(BUILDDIR)/CATLIB.O
CATLIBX7=$(BUILDDIR)/CATLIB.X7
CATLIBVARS=$(BUILDDIR)/CATLIB.VARS.S
DODEVO=$(BUILDDIR)/DODEV.O
DODEVX7=$(BUILDDIR)/DODEV.X7
DODEVVARS=$(BUILDDIR)/DODEV.VARS.S
DOTREEO=$(BUILDDIR)/DOTREE.O
DOTREEX7=$(BUILDDIR)/DOTREE.X7
DOTREEVARS=$(BUILDDIR)/DOTREE.VARS.S
COPYO=$(BUILDDIR)/COPY.O
COPYX7=$(BUILDDIR)/COPY.X7
COPYVARS=$(BUILDDIR)/COPY.VARS.S
CATALOGO=$(BUILDDIR)/CATALOG.O
CATALOGX7=$(BUILDDIR)/CATALOG.X7
CATALOGVARS=$(BUILDDIR)/CATALOG.VARS.S
DELLIBO=$(BUILDDIR)/DELLIB.O
DELLIBX7=$(BUILDDIR)/DELLIB.X7
DELLIBVARS=$(BUILDDIR)/DELLIB.VARS.S
VERIFYO=$(BUILDDIR)/VERIFY.O
VERIFYX7=$(BUILDDIR)/VERIFY.X7
VERIFYVARS=$(BUILDDIR)/VERIFY.VARS.S
DISKMAPO=$(BUILDDIR)/DISKMAP.O
DISKMAPX7=$(BUILDDIR)/DISKMAP.X7
DISKMAPVARS=$(BUILDDIR)/DISKMAP.VARS.S
UNDELETEO=$(BUILDDIR)/UNDELETE.O
UNDELETEX7=$(BUILDDIR)/UNDELETE.X7
UNDELETEVARS=$(BUILDDIR)/UNDELETE.VARS.S
MISCLIBO=$(BUILDDIR)/MISCLIB.O
MISCLIBX7=$(BUILDDIR)/MISCLIB.X7
MISCLIBVARS=$(BUILDDIR)/MISCLIB.VARS.S
EXE=$(BUILDDIR)/$(SYSNAME)
PRODOS=res/PRODOS\#FF0000
MANUAL=$(BUILDDIR)/REBOOT.MANUAL\#040000
VARS = (awk -F';' '$1 { printf "%s EQU %s\n", $$6, $$5 }' < "$2_Symbols.txt" | grep -v "_" | sed -e "s/00\//\$$/g" > "$@")

.PHONY: clean mount all

$(EXE): $(MMX7) $(PHRWTSX7) $(MESSAGES2X7) $(FILERX) $(RDDATAX7) $(CATLIBX7) $(DODEVX7) $(DOTREEX7) $(COPYX7) $(CATALOGX7) $(DELLIBX7) $(VERIFYX7) $(DISKMAPX7) $(UNDELETEX7) $(MISCLIBX7) $(MMVARS) $(PHRWTSVARS) $(MESSAGES2VARS) $(FILERVARS) $(RDDATAVARS) $(CATLIBVARS) $(DODEVVARS) $(DOTREEVARS) $(COPYVARS) $(CATALOGVARS) $(DELLIBVARS) $(VERIFYVARS) $(DISKMAPVARS) $(UNDELETEVARS) $(MISCLIBVARS) $(BUILDDIR)
	$(MERLIN) "$(SRCDIR)"/CII.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(MANUAL): $(BUILDDIR)
	tr "\n" "\r" < docs/manual.txt > "$(MANUAL)"

$(BUILDDISK): $(EXE) $(MANUAL)
	$(CADIUS) REPLACEFILE "$(BUILDDISK)" "/$(DISKVOLUME)/" "$(PRODOS)" -C
	$(CADIUS) REPLACEFILE "$(BUILDDISK)" "/$(DISKVOLUME)/" "$(EXE)" -C
	$(CADIUS) REPLACEFILE "$(BUILDDISK)" "/$(DISKVOLUME)/" "$(MANUAL)" -C

#
# Memory Manager module (self-contained)(compressed)
#
$(MMO): $(BUILDDIR)
	$(MERLIN) "$(SRCDIR)"/MM.CII.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(MMX7): $(MMO)
	$(call X7,$(MMO))

$(MMVARS): $(MMO)
	$(call VARS,/;MM.CII.S;/,$(MMO))

#
# ZX0 unpacker module (self-contained)(not compressed)
#
$(DZX0TURBOO): $(BUILDDIR)
	$(MERLIN) "$(SRCDIR)"/DZX0TURBO.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(DZX0TURBOVARS): $(DZX0TURBOO)
	$(call VARS,/;DZX0TURBO.S;/,$(DZX0TURBOO))

#
# DOS 3.3 Boot Sector module
#
$(BOOTSEC33O): $(BUILDDIR)
	$(MERLIN) "$(SRCDIR)"/BOOTSEC.33.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(BOOTSEC33VARS): $(BOOTSEC33O)
	$(call VARS,/;BOOTSEC.33.S;/,$(BOOTSEC33O))

#
# ProDOS Boot Sector module
#
$(BOOTSECPROO): $(BUILDDIR)
	$(MERLIN) "$(SRCDIR)"/BOOTSEC.PRO.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(BOOTSECPROVARS): $(BOOTSECPROO)
	$(call VARS,/;BOOTSEC.PRO.S;/,$(BOOTSECPROO))

#
# PHRWTS module (compressed)(self-decompressing)
#
$(PHRWTSO): $(BUILDDIR)
	$(MERLIN) "$(SRCDIR)"/PHRWTS.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(PHRWTSVARS): $(PHRWTSO)
	$(call VARS,/;PHRWTS.S;/,$(PHRWTSO))

$(PHRWTSX7): $(PHRWTSO)
	$(call X7,$(PHRWTSO))

#
# MESSAGES2 module (compressed)(self-decompressing)
# contains less-common message strings
#
$(MESSAGES2O): $(PHRWTSVARS)
	$(MERLIN) "$(SRCDIR)"/MESSAGES2.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(MESSAGES2VARS): $(MESSAGES2O)
	$(call VARS,/;MESSAGES2.S;/,$(MESSAGES2O))

$(MESSAGES2X7): $(MESSAGES2O)
	$(call X7,$(MESSAGES2O))

#
# Filer (requires Memory Manager, DOS 3.3 Boot Sector)(compressed)
#
$(FILERO): $(MMVARS) $(PHRWTSVARS) $(MESSAGES2VARS) $(BOOTSEC33VARS)
	$(MERLIN) "$(SRCDIR)"/FILER.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(FILERVARS): $(FILERO)
	$(call VARS,!/;VARS;/,$(FILERO))

$(FILERX): $(FILERO)
	$(ZX0) "$(FILERO)" "$@"

#
# RDData module (requires PHRWTS,Filer)(compressed)(self-decompressing)
#
$(RDDATAO): $(PHRWTSVARS) $(FILERVARS)
	$(MERLIN) "$(SRCDIR)"/RDDATA.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(RDDATAVARS): $(RDDATAO)
	$(call VARS,/;RDDATA.S;/,$(RDDATAO))

$(RDDATAX7): $(RDDATAO)
	$(call X7,$(RDDATAO))

#
# Catalog Library module (requires PHRWTS,Filer)(compressed)(self-decompressing)
#
$(CATLIBO): $(PHRWTSVARS) $(FILERVARS) $(RDDATAVARS)
	$(MERLIN) "$(SRCDIR)"/CATLIB.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(CATLIBVARS): $(CATLIBO)
	$(call VARS,/;CATLIB.S;/,$(CATLIBO))

$(CATLIBX7): $(CATLIBO)
	$(call X7,$(CATLIBO))

#
# DoDev module (requires Filer)(compressed)(self-decompressing)
#
$(DODEVO): $(FILERVARS) $(CATLIBVARS)
	$(MERLIN) "$(SRCDIR)"/DODEV.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(DODEVVARS): $(DODEVO)
	$(call VARS,/;DODEV.S;/,$(DODEVO))

$(DODEVX7): $(DODEVO)
	$(call X7,$(DODEVO))

#
# DoTree module (requires PHRWTS,Filer)(compressed)(self-decompressing)
#
$(DOTREEO): $(PHRWTSVARS) $(FILERVARS) $(DODEVVARS)
	$(MERLIN) "$(SRCDIR)"/DOTREE.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(DOTREEVARS): $(DOTREEO)
	$(call VARS,/;DOTREE.S;/,$(DOTREEO))

$(DOTREEX7): $(DOTREEO)
	$(call X7,$(DOTREEO))

#
# Copy module (requires PHRWTS,Filer)(compressed)(self-decompressing)
#
$(COPYO): $(PHRWTSVARS) $(FILERVARS) $(MMVARS) $(DOTREEVARS)
	$(MERLIN) "$(SRCDIR)"/COPY.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(COPYVARS): $(COPYO)
	$(call VARS,/;COPY.S;/,$(COPYO))

$(COPYX7): $(COPYO)
	$(call X7,$(COPYO))

#
# Catalog module (requires Filer)(compressed)(self-decompressing)
#
$(CATALOGO): $(FILERVARS) $(COPYVARS)
	$(MERLIN) "$(SRCDIR)"/CATALOG.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(CATALOGVARS): $(CATALOGO)
	$(call VARS,/;CATALOG.S;/,$(CATALOGO))

$(CATALOGX7): $(CATALOGO)
	$(call X7,$(CATALOGO))

#
# Delete module (requires PHRWTS,Filer)(compressed)(self-decompressing)
#
$(DELLIBO): $(PHRWTSVARS) $(FILERVARS) $(CATALOGVARS) $(BOOTSECPROVARS)
	$(MERLIN) "$(SRCDIR)"/DELLIB.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(DELLIBVARS): $(DELLIBO)
	$(call VARS,/;DELLIB.S;/,$(DELLIBO))

$(DELLIBX7): $(DELLIBO)
	$(call X7,$(DELLIBO))

#
# Verify module (requires PHRWTS,Filer)(compressed)(self-decompressing)
#
$(VERIFYO): $(PHRWTSVARS) $(FILERVARS) $(DELLIBVARS)
	$(MERLIN) "$(SRCDIR)"/VERIFY.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(VERIFYVARS): $(VERIFYO)
	$(call VARS,/;VERIFY.S;/,$(VERIFYO))

$(VERIFYX7): $(VERIFYO)
	$(call X7,$(VERIFYO))

#
# Disk Map module (requires Filer)(compressed)(self-decompressing)
#
$(DISKMAPO): $(FILERVARS) $(VERIFYVARS)
	$(MERLIN) "$(SRCDIR)"/DISKMAP.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(DISKMAPVARS): $(DISKMAPO)
	$(call VARS,/;DISKMAP.S;/,$(DISKMAPO))

$(DISKMAPX7): $(DISKMAPO)
	$(call X7,$(DISKMAPO))

#
# Undelete module (requires Filer)(compressed)(self-decompressing)
#
$(UNDELETEO): $(FILERVARS) $(DISKMAPVARS)
	$(MERLIN) "$(SRCDIR)"/UNDELETE.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(UNDELETEVARS): $(UNDELETEO)
	$(call VARS,/;UNDELETE.S;/,$(UNDELETEO))

$(UNDELETEX7): $(UNDELETEO)
	$(call X7,$(UNDELETEO))

#
# Miscellaneous module (requires Filer,RDDATA)(compressed)(self-decompressing)
# contains several less-common features like
# Make Subdirectory, Change Boot Program, Alphabetize Catalog, &c.
#
$(MISCLIBO): $(FILERVARS) $(RDDATAVARS) $(UNDELETEVARS)
	$(MERLIN) "$(SRCDIR)"/MISCLIB.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(MISCLIBVARS): $(MISCLIBO)
	$(call VARS,/;MISCLIB.S;/,$(MISCLIBO))

$(MISCLIBX7): $(MISCLIBO)
	$(call X7,$(MISCLIBO))

mount: $(BUILDDISK)
	@open "$(BUILDDISK)"

clean:
	rm -rf "$(BUILDDIR)"

$(BUILDDIR):
	mkdir -p "$@"
	touch "$(BUILDLOG)"
	$(CADIUS) CREATEVOLUME "$(BUILDDISK)" "$(DISKVOLUME)" 140KB -C

all: clean mount

.NOTPARALLEL:
