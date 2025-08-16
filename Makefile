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
MMO=$(BUILDDIR)/MM.O
MMX=$(BUILDDIR)/MM.X
MMVARS=$(BUILDDIR)/MM.VARS.S
DZX0TURBOO=$(BUILDDIR)/DZX0TURBO.O
DZX0TURBOVARS=$(BUILDDIR)/DZX0TURBO.VARS.S
FILERO=$(BUILDDIR)/FILER.O
FILERX=$(BUILDDIR)/FILER.X
FILERVARS=$(BUILDDIR)/FILER.VARS.S
DISKMAPO=$(BUILDDIR)/DISKMAP.O
DISKMAPX7=$(BUILDDIR)/DISKMAP.X7
DISKMAPVARS=$(BUILDDIR)/DISKMAP.VARS.S
SETCLOCKO=$(BUILDDIR)/SETCLOCK.O
SETCLOCKX=$(BUILDDIR)/SETCLOCK.X
SETCLOCKVARS=$(BUILDDIR)/SETCLOCK.VARS.S
EXE=$(BUILDDIR)/$(SYSNAME)

.PHONY: clean mount all

$(BUILDDISK): $(PRODOS) $(CLOCK) $(EXE)
	$(CADIUS) REPLACEFILE "$(BUILDDISK)" "/$(DISKVOLUME)/" "$(EXE)" -C

$(EXE): $(MMX) $(FILERX) $(DISKMAPX7) $(SETCLOCKX) $(MMVARS) $(FILERVARS) $(DISKMAPVARS) $(SETCLOCKVARS) $(BUILDDIR)
	$(MERLIN) "$(SRCDIR)"/CII.S > "$(BUILDLOG)"
	mv "$(SRCDIR)/UTIL.SYSTEM_S01_Segment1_Output.txt" "$(BUILDDIR)"/
	mv "$(SRCDIR)/UTIL.SYSTEM_Symbols.txt" "$(BUILDDIR)"/

#
# Memory Manager module (self-contained)(compressed)
#
$(MMO): $(BUILDDIR)
	$(MERLIN) "$(SRCDIR)"/MM.CII.S > "$(BUILDLOG)"
	mv "$(SRCDIR)/MM.O_S01_Segment1_Output.txt" "$(BUILDDIR)"/
	mv "$(SRCDIR)/MM.O_Symbols.txt" "$(BUILDDIR)"/

$(MMX): $(MMO)
	$(ZX0) "$(MMO)" "$@"

$(MMVARS): $(MMO)
	awk -F';' '/MM.CII/ { printf "%s EQU %s\n", $$6, $$5 }' < "$(BUILDDIR)"/MM.O_Symbols.txt | grep -v "_" | sed -e "s/00\//\$$/g" > "$@"

#
# ZX0 unpacker module (self-contained)(not compressed)
#
$(DZX0TURBOO): $(BUILDDIR)
	$(MERLIN) "$(SRCDIR)"/DZX0TURBO.S > "$(BUILDLOG)"
	mv "$(SRCDIR)/DZX0TURBO.O_S01_Segment1_Output.txt" "$(BUILDDIR)"/
	mv "$(SRCDIR)/DZX0TURBO.O_Symbols.txt" "$(BUILDDIR)"/

$(DZX0TURBOVARS): $(DZX0TURBOO)
	awk -F';' '/DZX0TURBO/ { printf "%s EQU %s\n", $$6, $$5 }' < "$(BUILDDIR)"/DZX0TURBO.O_Symbols.txt | grep -v "_" | sed -e "s/00\//\$$/g" > "$@"

#
# Filer (requires Memory Manager)(compressed)
#
$(FILERO): $(MMVARS)
	$(MERLIN) "$(SRCDIR)"/FILER.S > "$(BUILDLOG)"
	mv "$(SRCDIR)/FILER.O_S01_Segment1_Output.txt" "$(BUILDDIR)"/
	mv "$(SRCDIR)/FILER.O_Symbols.txt" "$(BUILDDIR)"/

$(FILERVARS): $(FILERO)
	awk -F';' '!/VARS;/ { printf "%s EQU %s\n", $$6, $$5 }' < "$(BUILDDIR)"/FILER.O_Symbols.txt | grep -v "_" | sed -e "s/00\//\$$/g" > "$@"

$(FILERX): $(FILERO)
	$(ZX0) "$(FILERO)" "$@"

#
# Disk Map module (requires Filer)(compressed)(self-decompressing)
#
$(DISKMAPO): $(FILERVARS)
	$(MERLIN) "$(SRCDIR)"/DISKMAP.S > "$(BUILDLOG)"
	mv "$(SRCDIR)/DISKMAP.O_S01_Segment1_Output.txt" "$(BUILDDIR)"/
	mv "$(SRCDIR)/DISKMAP.O_Symbols.txt" "$(BUILDDIR)"/

$(DISKMAPVARS): $(DISKMAPO)
	awk -F';' '/DISKMAP/ { printf "%s EQU %s\n", $$6, $$5 }' < "$(BUILDDIR)"/DISKMAP.O_Symbols.txt | grep -v "_" | sed -e "s/00\//\$$/g" > "$@"

$(DISKMAPX7): $(DISKMAPO)
	$(ZX0) "$(DISKMAPO)" "$(BUILDDIR)/DISKMAP.X"
	dd if="$(BUILDDIR)/DISKMAP.X" of="$(BUILDDIR)/DISKMAP.X.HEAD" bs=1 count=7
	dd if="$(BUILDDIR)/DISKMAP.X" of="$(BUILDDIR)/DISKMAP.X.TAIL" bs=1 skip=7
	cat "$(BUILDDIR)/DISKMAP.X.TAIL" "$(BUILDDIR)/DISKMAP.X.HEAD" > "$@"

#
# Set Clock (requires Filer)(compressed)(no vars)
#
$(SETCLOCKO): $(FILERVARS)
	$(MERLIN) "$(SRCDIR)"/SETCLOCK.S > "$(BUILDLOG)"
	mv "$(SRCDIR)/SETCLOCK.O_S01_Segment1_Output.txt" "$(BUILDDIR)"/
	mv "$(SRCDIR)/SETCLOCK.O_Symbols.txt" "$(BUILDDIR)"/

$(SETCLOCKX): $(SETCLOCKO)
	$(ZX0) "$(SETCLOCKO)" "$@"

$(SETCLOCKVARS): $(SETCLOCKO)
	awk -F';' '/SETCLOCK/ { printf "%s EQU %s\n", $$6, $$5 }' < "$(BUILDDIR)"/SETCLOCK.O_Symbols.txt | grep -v "_" | sed -e "s/00\//\$$/g" > "$@"

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
