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
PRODOS=PRODOS
CLOCK=CLOCK
MMO=$(BUILDDIR)/MM.O
MMX7=$(BUILDDIR)/MM.X7
MMVARS=$(BUILDDIR)/MM.VARS.S
DZX0TURBOO=$(BUILDDIR)/DZX0TURBO.O
DZX0TURBOVARS=$(BUILDDIR)/DZX0TURBO.VARS.S
FILERO=$(BUILDDIR)/FILER.O
FILERX=$(BUILDDIR)/FILER.X
FILERVARS=$(BUILDDIR)/FILER.VARS.S
COPYO=$(BUILDDIR)/COPY.O
COPYX7=$(BUILDDIR)/COPY.X7
COPYVARS=$(BUILDDIR)/COPY.VARS.S
DISKMAPO=$(BUILDDIR)/DISKMAP.O
DISKMAPX7=$(BUILDDIR)/DISKMAP.X7
DISKMAPVARS=$(BUILDDIR)/DISKMAP.VARS.S
QUITO=$(BUILDDIR)/QUIT.O
QUITX7=$(BUILDDIR)/QUIT.X7
QUITVARS=$(BUILDDIR)/QUIT.VARS.S
SETCLOCKO=$(BUILDDIR)/SETCLOCK.O
SETCLOCKX=$(BUILDDIR)/SETCLOCK.X
SETCLOCKVARS=$(BUILDDIR)/SETCLOCK.VARS.S
EXE=$(BUILDDIR)/$(SYSNAME)
VARS = (awk -F';' '$1 { printf "%s EQU %s\n", $$6, $$5 }' < "$2_Symbols.txt" | grep -v "_" | sed -e "s/00\//\$$/g" > "$@")

.PHONY: clean mount all

$(BUILDDISK): $(PRODOS) $(CLOCK) $(EXE)
	$(CADIUS) REPLACEFILE "$(BUILDDISK)" "/$(DISKVOLUME)/" "$(EXE)" -C

$(EXE): $(MMX7) $(FILERX) $(COPYX7) $(DISKMAPX7) $(QUITX7) $(SETCLOCKX) $(MMVARS) $(FILERVARS) $(COPYVARS) $(DISKMAPVARS) $(QUITVARS) $(SETCLOCKVARS) $(BUILDDIR)
	$(MERLIN) "$(SRCDIR)"/CII.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

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
# Filer (requires Memory Manager)(compressed)
#
$(FILERO): $(MMVARS)
	$(MERLIN) "$(SRCDIR)"/FILER.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(FILERVARS): $(FILERO)
	$(call VARS,!/;VARS;/,$(FILERO))

$(FILERX): $(FILERO)
	$(ZX0) "$(FILERO)" "$@"

#
# Copy module (requires Filer)(compressed)(self-decompressing)
#
$(COPYO): $(FILERVARS)
	$(MERLIN) "$(SRCDIR)"/COPY.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(COPYVARS): $(COPYO)
	$(call VARS,/;COPY.S;/,$(COPYO))

$(COPYX7): $(COPYO)
	$(call X7,$(COPYO))


#
# Disk Map module (requires Filer)(compressed)(self-decompressing)
#
$(DISKMAPO): $(FILERVARS) $(COPYVARS)
	$(MERLIN) "$(SRCDIR)"/DISKMAP.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(DISKMAPVARS): $(DISKMAPO)
	$(call VARS,/;DISKMAP.S;/,$(DISKMAPO))

$(DISKMAPX7): $(DISKMAPO)
	$(call X7,$(DISKMAPO))

#
# Quit module (requires Filer)(compressed)(self-decompressing)
#
$(QUITO): $(FILERVARS) $(DISKMAPVARS)
	$(MERLIN) "$(SRCDIR)"/QUIT.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(QUITVARS): $(QUITO)
	$(call VARS,/;QUIT.S;/,$(QUITO))

$(QUITX7): $(QUITO)
	$(call X7,$(QUITO))

#
# Set Clock (requires Filer)(compressed)(no vars)
#
$(SETCLOCKO): $(FILERVARS)
	$(MERLIN) "$(SRCDIR)"/SETCLOCK.S > "$(BUILDLOG)"
	$(call POSTMERLIN)

$(SETCLOCKX): $(SETCLOCKO)
	$(ZX0) "$(SETCLOCKO)" "$@"

$(SETCLOCKVARS): $(SETCLOCKO)
	$(call VARS,/;SETCLOCK.S;/,$(SETCLOCKO))

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
