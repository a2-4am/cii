DISKVOLUME=COPY.II.REBOOT
SYSNAME=UTIL.SYSTEM
SOURCE_DATE_UTC := $(shell TZ=UTC0 git show -s --date='format-local:%Y-%m-%dT%H:%M:%SZ' --format="%cd")
export SOURCE_DATE_EPOCH = $(shell git show -s --format=%ct)

BUILDDIR=build
BUILDLOG=$(BUILDDIR)/log
BUILDDISK=$(BUILDDIR)/$(DISKVOLUME).po

# ANSI escape sequences
OBJ_COLOR   = \033[0;38m
OK_COLOR    = \033[0;32m
ERROR_COLOR = \033[0;31m
NO_COLOR    = \033[m

CHECKOK = \
	RESULT=$$?; \
	if [ $$RESULT -ne 0 ]; then \
	printf "%b" "$(ERROR_COLOR)[ERROR]$(NO_COLOR)\n"; \
	else \
		printf "%b" "$(OK_COLOR)[OK]$(NO_COLOR)\n"; \
	fi; \
	exit $$RESULT

# https://brutaldeluxe.fr/products/crossdevtools/merlin/
# https://github.com/lifepillar/homebrew-appleii/blob/HEAD/Formula/merlin32.rb
MERLINBIN=Merlin32
MERLINLIB=/opt/homebrew/opt/merlin32/lib
MERLIN = (\
	printf "%-10b%-30b %s %-35b" "Assemble" "$(OBJ_COLOR)$1$(NO_COLOR)" "->" "$(OBJ_COLOR)$@$(NO_COLOR)"; \
	$(MERLINBIN) -V $(MERLINLIB) "$1" >> $(BUILDLOG); \
	exit 0)
POSTMERLIN = (\
	mv "$(SRCDIR)/$(notdir $@)_S01_Segment1_Output.txt" "$(BUILDDIR)"/ 2>/dev/null && \
	mv "$(SRCDIR)/$(notdir $@)_Symbols.txt" "$(BUILDDIR)"/ 2>/dev/null; \
	$(CHECKOK))

# https://github.com/mach-kernel/cadius
CADIUS=TZ=UTC0 cadius
COPY = (\
	printf "%-10b%-30b %s %-35b" "Copy" "$(OBJ_COLOR)`echo $1|cut -d\# -f1`$(NO_COLOR)" "->" "$(OBJ_COLOR)$(BUILDDISK)$(NO_COLOR)"; \
	touch -d"$(SOURCE_DATE_UTC)" "$1"; \
	$(CADIUS) REPLACEFILE "$(BUILDDISK)" "/$(DISKVOLUME)/" "$1" -C >> $(BUILDLOG); \
	$(CHECKOK))

# https://github.com/einar-saukas/ZX0
# note: -b flag to pack backwards
# you can also add a -q flag during development
# to do worse compression at a more reasonable speed
# (does not affect format, so unpacker still works)
ZX0BIN=zx0 -b
ZX0 = (\
	printf "%-10b%-30b %s %-35b" "Compress" "$(OBJ_COLOR)`echo $1|sed s/\.O\.O/.O/g`$(NO_COLOR)" "->" "$(OBJ_COLOR)$@$(NO_COLOR)"; \
	rm -f "$@"; \
	$(ZX0BIN) "$1" "$@" 2>/dev/null >> $(BUILDLOG); \
	$(CHECKOK))

# macro to compress file with ZX0 then transpose first N bytes to end of file
# (used for self-decompressing modules)
X7 = (\
	dd if="$1" of="$1.JMP" bs=1 count=$$((6*$2)) 2>> $(BUILDLOG) && \
	dd if="$1" of="$1.O" bs=1 skip=$$((6*$2)) 2>> $(BUILDLOG) && \
	$(call ZX0,"$1.O") && \
	dd if="$@" of="$@.HEAD" bs=1 count=7 2>> $(BUILDLOG) && \
	dd if="$@" of="$@.TAIL" bs=1 skip=7 2>> $(BUILDLOG) && \
	cat "$@.TAIL" "$@.HEAD" > "$@")

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
MESSAGESO=$(BUILDDIR)/MESSAGES.O
MESSAGESVARS=$(BUILDDIR)/MESSAGES.VARS.S
DRIVE35O=$(BUILDDIR)/DRIVE35.O
DRIVE35VARS=$(BUILDDIR)/DRIVE35.VARS.S
IOO=$(BUILDDIR)/IO.O
IOVARS=$(BUILDDIR)/IO.VARS.S
PRODOSO=$(BUILDDIR)/PRODOS.O
PRODOSVARS=$(BUILDDIR)/PRODOS.VARS.S
ERRORSO=$(BUILDDIR)/ERRORS.O
ERRORSVARS=$(BUILDDIR)/ERRORS.VARS.S
QUITO=$(BUILDDIR)/QUIT.O
QUITVARS=$(BUILDDIR)/QUIT.VARS.S
PROPACKO=$(BUILDDIR)/PROPACK.O
PROPACKX7=$(BUILDDIR)/PROPACK.X7
PROPACKVARS=$(BUILDDIR)/PROPACK.VARS.S
LINEINPUTO=$(BUILDDIR)/LINEINPUT.O
LINEINPUTVARS=$(BUILDDIR)/LINEINPUT.VARS.S
UILIBO=$(BUILDDIR)/UILIB.O
UILIBVARS=$(BUILDDIR)/UILIB.VARS.S
DISKLIBO=$(BUILDDIR)/DISKLIB.O
DISKLIBVARS=$(BUILDDIR)/DISKLIB.VARS.S
CATLIBO=$(BUILDDIR)/CATLIB.O
CATLIBVARS=$(BUILDDIR)/CATLIB.VARS.S
TREELIBO=$(BUILDDIR)/TREELIB.O
TREELIBVARS=$(BUILDDIR)/TREELIB.VARS.S
MENUO=$(BUILDDIR)/MENU.O
MENUVARS=$(BUILDDIR)/MENU.VARS.S
MAINPACKO=$(BUILDDIR)/MAINPACK.O
MAINPACKX=$(BUILDDIR)/MAINPACK.X
MAINPACKVARS=$(BUILDDIR)/MAINPACK.VARS.S
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
VERIFYVARS=$(BUILDDIR)/VERIFY.VARS.S
DISKMAPO=$(BUILDDIR)/DISKMAP.O
DISKMAPVARS=$(BUILDDIR)/DISKMAP.VARS.S
UNDELETEO=$(BUILDDIR)/UNDELETE.O
UNDELETEVARS=$(BUILDDIR)/UNDELETE.VARS.S
VERPACKO=$(BUILDDIR)/VERPACK.O
VERPACKX7=$(BUILDDIR)/VERPACK.X7
VERPACKVARS=$(BUILDDIR)/VERPACK.VARS.S
ALPHAPACKO=$(BUILDDIR)/ALPHAPACK.O
ALPHAPACKX7=$(BUILDDIR)/ALPHAPACK.X7
ALPHAPACKVARS=$(BUILDDIR)/ALPHAPACK.VARS.S
EXE=$(BUILDDIR)/$(SYSNAME)
FLOW=res/FLOW.SYSTEM\#FF2000
PRODOS=res/PRODOS\#FF0000
MANUAL=$(BUILDDIR)/REBOOT.MANUAL\#040000
VARS = (\
	awk -F';' '$1 { printf "%s EQU %s\n", $$6, $$5 }' < "$2_Symbols.txt" \
	| grep -v "_" \
	| grep -v "Name EQU Address" \
	| sed -e "s/00\//\$$/g" \
	> "$@")

.PHONY: clean mount all

$(EXE): $(MMX7) $(PHRWTSX7) $(MESSAGES2X7) $(MAINPACKX) $(PROPACKX7) $(COPYX7) $(CATALOGX7) $(DELLIBX7) $(VERPACKX7) $(ALPHAPACKX7) $(MMVARS) $(PHRWTSVARS) $(BOOTSEC33VARS) $(MAINPACKVARS) $(PROPACKVARS) $(UILIBVARS) $(TREELIBVARS) $(DISKLIBVARS) $(CATLIBVARS) $(COPYVARS) $(CATALOGVARS) $(DELLIBVARS) $(VERPACKVARS) $(ALPHAPACKVARS) $(BUILDDIR)
	@$(call MERLIN,"$(SRCDIR)/CII.S")
	@$(call POSTMERLIN)

$(MANUAL): $(BUILDDIR)
	@tr "\n" "\r" < docs/manual.txt > "$(MANUAL)"

$(BUILDDISK): $(EXE) $(MANUAL)
	@$(call COPY,"$(PRODOS)")
	@$(call COPY,"$(EXE)")
	@$(call COPY,"$(FLOW)")
	@$(call COPY,"$(MANUAL)")

#
# Memory Manager module (self-contained)(compressed)
#
$(MMO): $(BUILDDIR)
	@$(call MERLIN,"$(SRCDIR)/MM.CII.S")
	@$(call POSTMERLIN)

$(MMX7): $(MMO)
	@$(call X7,$(MMO),0)

$(MMVARS): $(MMO)
	@$(call VARS,/;MM.CII.S;/,$(MMO))

#
# ZX0 unpacker module (self-contained)(not compressed)
#
$(DZX0TURBOO): $(BUILDDIR)
	@$(call MERLIN,"$(SRCDIR)/DZX0TURBO.S")
	@$(call POSTMERLIN)

$(DZX0TURBOVARS): $(DZX0TURBOO)
	@$(call VARS,/;DZX0TURBO.S;/,$(DZX0TURBOO))

#
# DOS 3.3 Boot Sector module
#
$(BOOTSEC33O): $(BUILDDIR)
	@$(call MERLIN,"$(SRCDIR)/BOOTSEC.33.S")
	@$(call POSTMERLIN)

$(BOOTSEC33VARS): $(BOOTSEC33O)
	@$(call VARS,/;BOOTSEC.33.S;/,$(BOOTSEC33O))

#
# ProDOS Boot Sector module
#
$(BOOTSECPROO): $(BUILDDIR)
	@$(call MERLIN,"$(SRCDIR)/BOOTSEC.PRO.S")
	@$(call POSTMERLIN)

$(BOOTSECPROVARS): $(BOOTSECPROO)
	@$(call VARS,/;BOOTSEC.PRO.S;/,$(BOOTSECPROO))

#
# PHRWTS module (compressed)(self-decompressing)
#
$(PHRWTSO): $(BUILDDIR)
	@$(call MERLIN,"$(SRCDIR)/PHRWTS.S")
	@$(call POSTMERLIN)

$(PHRWTSVARS): $(PHRWTSO)
	@$(call VARS,/;PHRWTS.S;/,$(PHRWTSO))

$(PHRWTSX7): $(PHRWTSO)
	@$(call X7,$(PHRWTSO),3)

#
# MESSAGES2 module (compressed)(self-decompressing)
# contains less-common message strings
#
$(MESSAGES2O): $(PHRWTSVARS)
	@$(call MERLIN,"$(SRCDIR)/MESSAGES2.S")
	@$(call POSTMERLIN)

$(MESSAGES2VARS): $(MESSAGES2O)
	@$(call VARS,/;MESSAGES2.S;/,$(MESSAGES2O))

$(MESSAGES2X7): $(MESSAGES2O)
	@$(call X7,$(MESSAGES2O),0)

#
# MESSAGES module
# contains message strings
#
$(MESSAGESO): $(MESSAGES2VARS)
	@$(call MERLIN,"$(SRCDIR)/MESSAGES.S")
	@$(call POSTMERLIN)

$(MESSAGESVARS): $(MESSAGESO)
	@$(call VARS,/;MESSAGES.S;/,$(MESSAGESO))

#
# DRIVE35 module
# contains low-level hardware routines for 3.5-inch drives
#
$(DRIVE35O): $(MESSAGESVARS)
	@$(call MERLIN,"$(SRCDIR)/DRIVE35.S")
	@$(call POSTMERLIN)

$(DRIVE35VARS): $(DRIVE35O)
	@$(call VARS,!/;VARS;/,$(DRIVE35O))

#
# I/O module
# contains low-level text handling routines
#
$(IOO): $(MESSAGES2VARS) $(MESSAGESVARS) $(DRIVE35VARS)
	@$(call MERLIN,"$(SRCDIR)/IO.S")
	@$(call POSTMERLIN)

$(IOVARS): $(IOO)
	@$(call VARS,!/;VARS;/,$(IOO))

#
# MENU module
# contains main menu and submenu routines
#
$(MENUO): $(MMVARS) $(DRIVE35VARS) $(IOVARS)
	@$(call MERLIN,"$(SRCDIR)/MENU.S")
	@$(call POSTMERLIN)

$(MENUVARS): $(MENUO)
	@$(call VARS,!/;VARS;/,$(MENUO))

#
# PRODOS module
# contains low-level ProDOS routines
#
$(PRODOSO): $(DRIVE35VARS) $(MENUVARS)
	@$(call MERLIN,"$(SRCDIR)/PRODOS.S")
	@$(call POSTMERLIN)

$(PRODOSVARS): $(PRODOSO)
	@$(call VARS,!/;VARS;/,$(PRODOSO))

#
# ERRORS
# contains error handling routines
#
$(ERRORSO): $(IOVARS) $(PRODOSVARS)
	@$(call MERLIN,"$(SRCDIR)/ERRORS.S")
	@$(call POSTMERLIN)

$(ERRORSVARS): $(ERRORSO)
	@$(call VARS,!/;VARS;/,$(ERRORSO))

#
# QUIT module
# contains quit code
#
$(QUITO): $(PRODOSVARS) $(ERRORSVARS)
	@$(call MERLIN,"$(SRCDIR)/QUIT.S")
	@$(call POSTMERLIN)

$(QUITVARS): $(QUITO)
	@$(call VARS,!/;VARS;/,$(QUITO))

#
# LINEINPUT module
# contains text input handling routines
#
$(LINEINPUTO): $(IOVARS) $(QUITVARS)
	@$(call MERLIN,"$(SRCDIR)/LINEINPUT.S")
	@$(call POSTMERLIN)

$(LINEINPUTVARS): $(LINEINPUTO)
	@$(call VARS,!/;VARS;/,$(LINEINPUTO))

#
# UILIB module
# contains higher-level text routines
#
$(UILIBO): $(PHRWTSVARS) $(PRODOSVARS) $(IOVARS) $(LINEINPUTVARS)
	@$(call MERLIN,"$(SRCDIR)/UILIB.S")
	@$(call POSTMERLIN)

$(UILIBVARS): $(UILIBO)
	@$(call VARS,!/;VARS;/,$(UILIBO))

#
# DISKLIB module
#
$(DISKLIBO): $(PHRWTSVARS) $(PRODOSVARS) $(IOVARS) $(ERRORSVARS) $(LINEINPUTVARS) $(UILIBVARS)
	@$(call MERLIN,"$(SRCDIR)/DISKLIB.S")
	@$(call POSTMERLIN)

$(DISKLIBVARS): $(DISKLIBO)
	@$(call VARS,!/;VARS;/,$(DISKLIBO))

#
# Catalog Library module (compressed)(self-decompressing)
#
$(CATLIBO): $(PHRWTSVARS) $(PRODOSVARS) $(IOVARS) $(ERRORSVARS) $(LINEINPUTVARS) $(UILIBVARS) $(DISKLIBVARS)
	@$(call MERLIN,"$(SRCDIR)/CATLIB.S")
	@$(call POSTMERLIN)

$(CATLIBVARS): $(CATLIBO)
	@$(call VARS,/;CATLIB.S;/,$(CATLIBO))

$(CATLIBX7): $(CATLIBO)
	@$(call X7,$(CATLIBO),0)

#
# TREELIB module (compressed)(self-decompressing)
#
$(TREELIBO): $(PHRWTSVARS) $(IOVARS) $(ERRORSVARS) $(UILIBVARS) $(DISKLIBVARS) $(CATLIBVARS)
	@$(call MERLIN,"$(SRCDIR)/TREELIB.S")
	@$(call POSTMERLIN)

$(TREELIBVARS): $(TREELIBO)
	@$(call VARS,!/;VARS;/,$(TREELIBO))

#
# PROPACK module (compressed,self-decompressing)
# contains PRODOS,ERRORS,QUIT,LINEINPUT,UILIB,DISKLIB,CATLIB,TREELIB
#
$(PROPACKO): $(MAINPACKVARS) $(PRODOSVARS) $(ERRORSVARS) $(QUITVARS) $(LINEINPUTVARS) $(UILIBVARS) $(DISKLIBVARS) $(CATLIBVARS) $(TREELIBVARS)
	@$(call MERLIN,"$(SRCDIR)/PROPACK.S")
	@$(call POSTMERLIN)

$(PROPACKVARS): $(PROPACKO)
	@$(call VARS,!/;VARS;/,$(PROPACKO))

$(PROPACKX7): $(PROPACKO)
	@$(call X7,$(PROPACKO),0)

#
# MAINPACK module (compressed)
# contains MESSAGES,DRIVE35,IO,MENU
#
$(MAINPACKO): $(PHRWTSVARS) $(MESSAGES2VARS) $(BOOTSEC33VARS) $(MESSAGESVARS) $(DRIVE35VARS) $(PRODOSVARS) $(IOVARS) $(MENUVARS)
	@$(call MERLIN,"$(SRCDIR)/MAINPACK.S")
	@$(call POSTMERLIN)

$(MAINPACKVARS): $(MAINPACKO)
	@$(call VARS,!/;VARS;/,$(MAINPACKO))

$(MAINPACKX): $(MAINPACKO)
	@$(call ZX0,"$(MAINPACKO)")

#
# Copy module (compressed)(self-decompressing)
#
$(COPYO): $(PHRWTSVARS) $(DRIVE35VARS) $(PRODOSVARS) $(IOVARS) $(ERRORSVARS) $(LINEINPUTVARS) $(UILIBVARS) $(MMVARS) $(DISKLIBVARS) $(CATLIBVARS) $(TREELIBVARS) $(DELLIBVARS)
	@$(call MERLIN,"$(SRCDIR)/COPY.S")
	@$(call POSTMERLIN)

$(COPYVARS): $(COPYO)
	@$(call VARS,/;COPY.S;/,$(COPYO))

$(COPYX7): $(COPYO)
	@$(call X7,$(COPYO),0)

#
# Catalog module (compressed)(self-decompressing)
#
$(CATALOGO): $(PRODOSVARS) $(IOVARS) $(ERRORSVARS) $(UILIBVARS) $(DISKLIBVARS) $(CATLIBVARS) $(TREELIBVARS) $(COPYVARS)
	@$(call MERLIN,"$(SRCDIR)/CATALOG.S")
	@$(call POSTMERLIN)

$(CATALOGVARS): $(CATALOGO)
	@$(call VARS,/;CATALOG.S;/,$(CATALOGO))

$(CATALOGX7): $(CATALOGO)
	@$(call X7,$(CATALOGO),0)

#
# DELLIB module (compressed)(self-decompressing)
# contains Delete, Format
#
$(DELLIBO): $(BOOTSECPROVARS) $(PHRWTSVARS) $(PRODOSVARS) $(IOVARS) $(ERRORSVARS) $(LINEINPUTVARS) $(UILIBVARS) $(DISKLIBVARS) $(CATLIBVARS) $(TREELIBVARS)
	@$(call MERLIN,"$(SRCDIR)/DELLIB.S")
	@$(call POSTMERLIN)

$(DELLIBVARS): $(DELLIBO)
	@$(call VARS,/;DELLIB.S;/,$(DELLIBO))

$(DELLIBX7): $(DELLIBO)
	@$(call X7,$(DELLIBO),7)

#
# VERIFY module
# contains Verify option
#
$(VERIFYO): $(PHRWTSVARS) $(PRODOSVARS) $(IOVARS) $(ERRORSVARS) $(UILIBVARS) $(DISKLIBVARS) $(CATLIBVARS) $(TREELIBVARS) $(CATALOGVARS)
	@$(call MERLIN,"$(SRCDIR)/VERIFY.S")
	@$(call POSTMERLIN)

$(VERIFYVARS): $(VERIFYO)
	@$(call VARS,/;VERIFY.S;/,$(VERIFYO))

#
# DISKMAP module
# contains Map Disk option
#
$(DISKMAPO): $(PRODOSVARS) $(IOVARS) $(ERRORSVARS) $(UILIBVARS) $(DISKLIBVARS) $(CATLIBVARS) $(TREELIBVARS) $(VERIFYVARS)
	@$(call MERLIN,"$(SRCDIR)/DISKMAP.S")
	@$(call POSTMERLIN)

$(DISKMAPVARS): $(DISKMAPO)
	@$(call VARS,/;DISKMAP.S;/,$(DISKMAPO))

#
# UNDELETE module
# Contains Undelete option
#
$(UNDELETEO): $(PRODOSVARS) $(IOVARS) $(ERRORSVARS) $(UILIBVARS) $(DISKLIBVARS) $(CATLIBVARS) $(TREELIBVARS) $(DISKMAPVARS)
	@$(call MERLIN,"$(SRCDIR)/UNDELETE.S")
	@$(call POSTMERLIN)

$(UNDELETEVARS): $(UNDELETEO)
	@$(call VARS,/;UNDELETE.S;/,$(UNDELETEO))

#
# VERPACK module (compressed)(self-decompressing)
# contains Verify, Map Disk, Undelete
#
$(VERPACKO): $(VERIFYVARS) $(DISKMAPVARS) $(UNDELETEVARS) $(CATALOGVARS)
	@$(call MERLIN,"$(SRCDIR)/VERPACK.S")
	@$(call POSTMERLIN)

$(VERPACKVARS): $(VERPACKO)
	@$(call VARS,/;VERPACK.S;/,$(VERPACKO))

$(VERPACKX7): $(VERPACKO)
	@$(call X7,$(VERPACKO),3)

#
# ALPHAPACK module (compressed)(self-decompressing)
# contains several less-common features like
# Make Subdirectory, Change Boot Program, Alphabetize Catalog, &c.
#
$(ALPHAPACKO): $(PRODOSVARS) $(IOVARS) $(ERRORSVARS) $(LINEINPUTVARS) $(UILIBVARS) $(DISKLIBVARS) $(CATLIBVARS) $(TREELIBVARS) $(VERPACKVARS)
	@$(call MERLIN,"$(SRCDIR)/ALPHAPACK.S")
	@$(call POSTMERLIN)

$(ALPHAPACKVARS): $(ALPHAPACKO)
	@$(call VARS,/;ALPHAPACK.S;/,$(ALPHAPACKO))

$(ALPHAPACKX7): $(ALPHAPACKO)
	@$(call X7,$(ALPHAPACKO),7)

mount: $(BUILDDISK)
	@open "$(BUILDDISK)" &

clean:
	@rm -rf "$(BUILDDIR)"

$(BUILDDIR):
	@mkdir -p "$@"
	@touch "$(BUILDLOG)"
	@$(CADIUS) CREATEVOLUME "$(BUILDDISK)" "$(DISKVOLUME)" 140KB -C > $(BUILDLOG)

all: clean mount

.NOTPARALLEL:
