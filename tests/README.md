Testing harness based on work by @inexorabletash in the A2D project:

https://github.com/a2stuff/a2d/tree/main/tests

This readme is based on the A2D testing readme, edited to remove A2D-specific features:

Run in a terminal with:

```sh
make all                          # build latest

export MAMEDIR=<path to your MAME directory>
export MAMEEXE=<path to your MAME executable>

bin/mametest tests/SCRIPTNAME.lua
```

Options:

* `--only PATTERN` - run only matching named test steps (`*` and `?` are wildcards, `|` to separate multiple patterns); useful for fast iteration
* `--skip N` - skip the first N tests
* `--count N` - run at most N tests
* `--visible` - show the emulator window (default is headless)
* `--audible` - play the emulator audio (default is silent)
* `--nosnaps` - don't generate snapshots
* `--console` - don't ask MAME to run the script (but do load its config, see below), launch the Lua console instead
* `--slow` - run at normal speed (default is unthrottled)
* `--debug` - run with MAME's debugger
* `--listmedia` - print MAME's list of drive options
* `--listslots` - print MAME's list of slot options

## Configuration

The default system configuration is:

* Apple IIe Enhanced (`apple2ee`)
* Aux: Extended 80 Column Card (MAME default for `apple2ee`)
* Slot 6: Disk II Controller w/ 2 (empty) drives (MAME default for `apple2ee`)
* No-Slot Clock under system ROM (MAME default for `apple2ee`)

Tests can define custom MAME configurations. The contents of an optional config block are executed by `mametest` to override environment variable that are used when MAME launches.

* `MODEL` - the system type, e.g. `"apple2ee"`, `"apple2gsr1"` etc
* `MODELARGS` - slot and other configuration, e.g. `"-sl2 mouse"`
  * A slot can be emptied with empty single-quoted string, e.g. `-sl6 ''`
  * Note that MAME's defaults for each model are different. See the [MAMEDEV Page](https://wiki.mamedev.org/index.php/Driver:Apple_II#The_default_configurations) for specifics.
* `DISKARGS` - disk configuration, e.g. `"-sl1 'ramfactor'"`
  * NOTE: This is parsed as space-delimited pairs and the second argument is copied from `tests/images` to a temp directory so that the original disk images are not modified
  * These environment variables can be used.
    * `FLOPIMG` has the path to the 140K Copy ][ Reboot disk image
* `CHECKAUXMEMORY` - defaults to `true`; set it to `false` for the tests that run on an Apple ][+ or Apple IIe without an 80 column card

# Files

## `lib/` - Libraries

This directory is part of the package path, so scripts can just `apple2 = require("apple2")`, etc. But shouldn't need to.

* `lib/autoboot.lua` - the file that MAME is actually launched with. It has boilerplate to simplify test scripts.
* `lib/test.lua` - basic test infrastructure; exposed as a `test` global.
* `lib/apple2.lua` - utilities for driving Apple II systems in MAME; exposed as an `apple2` global.

# Tips For Authoring Tests

* Apple IIc and IIc+ models are slow in MAME. @mgcaret points out that on real hardware the processor slows to 1MHZ when accessing 800K drives. Prefer using a `superdrive` card in an Apple IIe instead.
* Drive assignments are a pain, especialy with SCSI cards. See the [MAMEDEV Page](https://wiki.mamedev.org/index.php/Driver:Apple_II#More_configuration) for some notes. Basically, MAME does things bottom-up, whereas the Apple II ("autostart ROM") and SCSI do things top-down.
* Access to virtual disk drives is via the `manager.machine.images` collection.
  * The accessed objects provide:
    * `drive.filename` - get the current image path
    * `drive:load(name)` - insert/replace a disk image
    * `drive:unload()` - eject a disk image
  * The keys in `images` depend heavily on the configuration:
    * For a Disk II controller in Slot 6:
      * `local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]`
      * `local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]`
    * For a Superdrive controller in Slot 5:
      * `local s5d1 = manager.machine.images[":sl5:superdrive:fdc:0:35hd"]`
      * `local s5d2 = manager.machine.images[":sl5:superdrive:fdc:1:35hd"]`
    * For a SCSI controller in Slot 7:
      * `local s7d1 = manager.machine.images[":sl7:scsi:scsibus:6:harddisk:image"]`
      * Additional SCSI devices require more command line configuration
    * For an Apple IIgs or Apple IIc+
      * `local s6d1 = manager.machine.images[":fdc:0:525"]`
      * `local s6d2 = manager.machine.images[":fdc:1:525"]`
      * `local s5d1 = manager.machine.images[":fdc:2:35dd"]`
      * `local s5d2 = manager.machine.images[":fdc:3:35dd"]`
  * ... and so on. Since this depends so heavily on the configuration which varies between tests, no abstraction is (currently) provided for this. The convention is to provide this mapping at the top of the test file for tests that do interact with the virtual drives.
