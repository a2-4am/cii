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

# https://github.com/einar-saukas/ZX0
# note: -b flag to pack backwards
# you can also add a -q flag during development
# to do worse compression at a more reasonable speed
# (does not affect format, so unpacker still works)
ZX0=zx0 -b

SRCDIR=src
SOURCES=$(wildcard src/*.S)
PRODOS=PRODOS
CLOCK=CLOCK
OBJMM=$(BUILDDIR)/OBJ.MM
OBJMMX=$(OBJMM).X
MMVARS=$(BUILDDIR)/MM.VARS.S
OBJBOOTSEC=$(BUILDDIR)/OBJ.BOOTSEC
OBJFILER=$(BUILDDIR)/OBJ.FILER
OBJFILERX=$(OBJFILER).X
FILERVARS=$(BUILDDIR)/FILER.VARS.S
EXE=$(BUILDDIR)/$(SYSNAME)

.PHONY: clean mount all

$(BUILDDISK): $(PRODOS) $(CLOCK) $(EXE)
	$(CADIUS) REPLACEFILE "$(BUILDDISK)" "/$(DISKVOLUME)/" "$(EXE)" -C

$(EXE): $(OBJMMX) $(OBJFILERX) $(FILERVARS) $(BUILDDIR)
	$(MERLIN) "$(SRCDIR)"/CII.S > "$(BUILDLOG)"
	mv "$(SRCDIR)/UTIL.SYSTEM_S01_Segment1_Output.txt" "$(BUILDDIR)"/
	mv "$(SRCDIR)/UTIL.SYSTEM_Symbols.txt" "$(BUILDDIR)"/

#
# compressors
#
$(OBJMMX): $(OBJMM)
	$(ZX0) "$(BUILDDIR)/OBJ.MM" "$@"

$(OBJFILERX): $(OBJFILER)
	$(ZX0) "$(BUILDDIR)/OBJ.FILER" "$@"

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

#
# Filer (requires Memory Manager and boot sector image)
#
$(OBJFILER): $(MMVARS)
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
