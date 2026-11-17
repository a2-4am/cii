# Building the code

## macOS / Linux

You will need
 - (macOS only) [Xcode command line tools](https://developer.apple.com/library/archive/technotes/tn2339/_index.html)
 - [Merlin32](https://brutaldeluxe.fr/products/crossdevtools/merlin/)
 - [Cadius](https://github.com/mach-kernel/cadius)
 - [ZX0](https://github.com/einar-saukas/ZX0)

As of this writing, most dependencies are installable via [Homebrew](https://brew.sh/), which is available on both macOS and Linux.

``` shell
$ brew tap lifepillar/appleii
$ brew trust lifepillar/appleii
$ brew install merlin32 mach-kernel-cadius
```
*Note*: an uninvestigated bug in cadius 1.4.5 prevents the COPY.II.REBOOT.po floppy from booting, with a "Check Disk Drive" message. Please use this fork for now: [Cadius](https://github.com/a2-4am/cadius).

You will need to compile `ZX0` manually.

``` shell
$ git clone https://github.com/einar-saukas/ZX0
$ cd ZX0/src
$ make
$ sudo mv ./zx0.exe /usr/local/bin/zx0
```

(`zx0` can go anywhere in your `$PATH`. I personally keep a `bin` directory in my home directory and put all manually compiled programs there, then update my `$PATH` to include that directory.)

*Note*: zx0 is built with Open Watcom, which is harder than it should be to install, and generates a segfaulting `zx0` at least on Ubuntu 26.04. If so, use [Salvador](https://github.com/emmanuel-marty/salvador) instead:

``` shell
$ git clone https://github.com/emmanuel-marty/salvador.git
$ cd salvador
$ make
$ sudo mv ./salvador /usr/local/bin/zx0
```


Then open a terminal window and type

``` shell
$ cd
$ git clone https://github.com/a2-4am/cii
$ cd cii
$ make all
```

If all goes well, the `build/` subdirectory will contain a `COPY.II.REBOOT.po` image which can be mounted in emulators like [OpenEmulator](https://archive.org/details/OpenEmulatorSnapshots), [Ample](https://github.com/ksherlock/ample), or [Virtual II](http://virtualii.com/).

If all does not go well, please [file a bug](https://github.com/a2-4am/cii/issues/new).
