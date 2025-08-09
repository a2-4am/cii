DISKVOLUME=COPY.II.PLUS
SYSNAME=UTIL.SYSTEM

BUILDDIR=build
BUILDLOG=$(BUILDDIR)/log
BUILDDISK=$(BUILDDIR)/$(DISKVOLUME).po

# https://brutaldeluxe.fr/products/crossdevtools/merlin/
# https://github.com/lifepillar/homebrew-appleii/blob/HEAD/Formula/merlin32.rb
MERLINBIN=Merlin32
MERLINLIB=/opt/homebrew/opt/merlin32/lib
MERLIN=$(MERLINBIN) -V $(MERLINLIB)

# https://github.com/mach-kernel/cadius
CADIUS=cadius

# https://bitbucket.org/magli143/exomizer/src/master/
# note: flags set to decrunch backwards
EXOMIZER=exomizer mem -q -P23 -lnone

SRCDIR=src
SOURCES=$(wildcard src/*.S)
PRODOS=PRODOS
CLOCK=CLOCK
OBJMM=$(BUILDDIR)/OBJ.MM
OBJMMX=$(OBJMM).X
MMVARS=$(BUILDDIR)/MM.VARS.S
OBJBOOTSEC=$(BUILDDIR)/OBJ.BOOTSEC
OBJBOOTSECX=$(OBJBOOTSEC).X
BOOTSECVARS=$(BUILDDIR)/BOOTSEC.VARS.S
OBJFILER=$(BUILDDIR)/OBJ.FILER
OBJFILERX=$(OBJFILER).X
FILERVARS=$(BUILDDIR)/FILER.VARS.S
EXE=$(BUILDDIR)/$(SYSNAME)

.PHONY: clean mount all

$(BUILDDISK): $(PRODOS) $(CLOCK) $(EXE)
	$(CADIUS) REPLACEFILE "$(BUILDDISK)" "/$(DISKVOLUME)/" "$(EXE)" -C

$(EXE): $(OBJMMX) $(OBJBOOTSECX) $(OBJFILERX) $(FILERVARS) $(BUILDDIR)
	$(MERLIN) "$(SRCDIR)"/CII.S > "$(BUILDLOG)"
	mv "$(SRCDIR)/UTIL.SYSTEM_S01_Segment1_Output.txt" "$(BUILDDIR)"/
	mv "$(SRCDIR)/UTIL.SYSTEM_Symbols.txt" "$(BUILDDIR)"/

#
# compressors
#
# On program startup, the loader will decompress this into
# main memory and immediately copy it to auxmem.
$(OBJMMX): $(OBJMM)
	$(EXOMIZER) "$(BUILDDIR)/OBJ.MM@0x4D00" -o "$@"

# On program startup, the loader will decompress this into
# LCRAM and leave it there.
$(OBJBOOTSECX): $(OBJBOOTSEC)
	$(EXOMIZER) "$(BUILDDIR)/OBJ.BOOTSEC@0xD000" -o "$@"

# This address needs to match CODEADR in src/VARS.S
# because it will be decompressed into the address it runs from.
# /!\ This is not automatic! Ensure they stay in sync!
$(OBJFILERX): $(OBJFILER)
	$(EXOMIZER) "$(BUILDDIR)/OBJ.FILER@0x5C00" -o "$@"

#
# Memory Manager module (self-contained)
#
$(OBJMM): $(BUILDDIR)
	$(MERLIN) "$(SRCDIR)"/MM.CII.S > "$(BUILDLOG)"
	mv "$(SRCDIR)/OBJ.MM_S01_Segment1_Output.txt" "$(BUILDDIR)"/
	mv "$(SRCDIR)/OBJ.MM_Symbols.txt" "$(BUILDDIR)"/

$(MMVARS): $(OBJMM)
	awk -F';' '/MM.CII/ { printf "%s EQU %s\n", $$6, $$5 }' < "$(BUILDDIR)"/OBJ.MM_Symbols.txt | grep -v "_" | sed -e "s/00\//\$$/g" > "$@"

#
# DOS 3.3 boot sector image (self-contained)
#
$(OBJBOOTSEC): $(BUILDDIR)
	$(MERLIN) "$(SRCDIR)"/BOOTSEC.33.S > "$(BUILDLOG)"
	mv "$(SRCDIR)/OBJ.BOOTSEC_S01_Segment1_Output.txt" "$(BUILDDIR)"/
	mv "$(SRCDIR)/OBJ.BOOTSEC_Symbols.txt" "$(BUILDDIR)"/

$(BOOTSECVARS): $(OBJBOOTSEC)
	awk -F';' '/BOOTSEC.33/ { printf "%s EQU %s\n", $$6, $$5 }' < "$(BUILDDIR)"/OBJ.BOOTSEC_Symbols.txt | grep -v "_" | sed -e "s/00\//\$$/g" > "$@"

#
# Filer (requires Memory Manager and boot sector image)
#
$(OBJFILER): $(MMVARS) $(BOOTSECVARS)
	$(MERLIN) "$(SRCDIR)"/FILER.S > "$(BUILDLOG)"
	mv "$(SRCDIR)/OBJ.FILER_S01_Segment1_Output.txt" "$(BUILDDIR)"/
	mv "$(SRCDIR)/OBJ.FILER_Symbols.txt" "$(BUILDDIR)"/

$(FILERVARS): $(OBJFILER)
	awk -F';' '!/VARS;/ { printf "%s EQU %s\n", $$6, $$5 }' < "$(BUILDDIR)"/OBJ.FILER_Symbols.txt | grep -v "_" | sed -e "s/00\//\$$/g" > "$@"

# things that go in the root directory
$(PRODOS) $(CLOCK): $(BUILDDIR)
	$(CADIUS) ADDFOLDER "$(BUILDDISK)" "/$(DISKVOLUME)/" "$@" -C

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
