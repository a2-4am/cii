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

SRCDIR=src
SOURCES=$(wildcard src/*.S)
DATA=$(wildcard res/*)
EXE=$(BUILDDIR)/$(SYSNAME)

.PHONY: clean mount all

$(BUILDDISK): $(EXE) $(DATA)

$(EXE): $(DATA) $(SOURCES) | $(BUILDDIR)
	cd "$(SRCDIR)" && $(MERLIN) CII.S > ../"$(BUILDLOG)"
	mv "$(SRCDIR)/$(SYSNAME)" "$(BUILDDIR)"/
	mv "$(SRCDIR)/$(SYSNAME)_S01_Segment1_Output.txt" "$(BUILDDIR)"/
	mv "$(SRCDIR)/$(SYSNAME)_Symbols.txt" "$(BUILDDIR)"/
	mv "$(SRCDIR)/_FileInformation.txt" "$(BUILDDIR)"/
	$(CADIUS) REPLACEFILE "$(BUILDDISK)" "/$(DISKVOLUME)/" "$@" -C
	@touch "$@"

$(DATA): $(BUILDDIR)
	$(CADIUS) REPLACEFILE "$(BUILDDISK)" "/$(DISKVOLUME)/" "$@" -C
	@touch "$@"

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
