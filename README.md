# Building the code

## Mac OS X

You will need
 - [Xcode command line tools](https://developer.apple.com/library/archive/technotes/tn2339/_index.html)
 - [Merlin32 for MacOS](https://brutaldeluxe.fr/products/crossdevtools/merlin/)
 - [Cadius](https://github.com/mach-kernel/cadius)

As of this writing, all of the non-Xcode programs are installable via [Homebrew](https://brew.sh/).

``` shell
$ brew tap lifepillar/appleii
$ brew install merlin32 mach-kernel-cadius
```

Then open a terminal window and type

``` shell
$ cd cii/
$ make
```

If all goes well, the `build/` subdirectory will contain a `COPY.II.PLUS.po` image which can be mounted in emulators like [OpenEmulator](https://archive.org/details/OpenEmulatorSnapshots), [Ample](https://github.com/ksherlock/ample), or [Virtual II](http://virtualii.com/).

If all does not go well, try doing a clean build (`make clean && make`)

If that fails, please [file a bug](https://github.com/a2-4am/cii/issues/new).

## Windows

You will need
 - [ACME](https://sourceforge.net/projects/acme-crossass/)
 - [Merlin32 for Windows](https://brutaldeluxe.fr/products/crossdevtools/merlin/)
 - [Cadius for Windows](https://brutaldeluxe.fr/products/crossdevtools/cadius/)

...TODO

## Linux

You will need
 - [Merlin32 for Linux](https://brutaldeluxe.fr/products/crossdevtools/merlin/)
 - [Cadius](https://github.com/mach-kernel/cadius)

...TODO
