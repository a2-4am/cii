@echo off
rem
rem cii Makefile for Windows
rem assembles source code, optionally builds a disk image
rem note: non-Windows users should probably use Makefile instead
rem
rem a qkumba monstrosity from 2018-10-29
rem

setlocal enabledelayedexpansion
set DISKVOLUME=COPY.II.PLUS
set SYSNAME=UTIL.SYSTEM

set BUILDDIR=build
set BUILDLOG=%BUILDDIR%\log
set BUILDDISK=%BUILDDIR%\%DISKVOLUME%.po

rem third-party tools required to build (must be in path)

rem https://brutaldeluxe.fr/products/crossdevtools/merlin/
rem version 1.2 or later
set MERLIN=merlin32 -V .

rem https://github.com/mach-kernel/cadius
rem version 1.4.6 or later
set CADIUS=cadius

set SRCDIR=src

if "%1" equ "exe" (
call :builddir
cd "%SRCDIR%" & %MERLIN% CII.S > ..\"%BUILDLOG%" & cd ..
1>nul move /y "%SRCDIR%\%SYSNAME%" "%BUILDDIR%"\
1>nul move /y "%SRCDIR%\%SYSNAME%_S01_Segment1_Output.txt" "%BUILDDIR%"\
1>nul move /y "%SRCDIR%\%SYSNAME%_Symbols.txt" "%BUILDDIR%"\
1>nul attrib -h "%SRCDIR%\_FileInformation.txt"
1>nul move /y "%SRCDIR%\_FileInformation.txt" "%BUILDDIR%"\
1>nul %CADIUS% REPLACEFILE "%BUILDDISK%" "/%DISKVOLUME%/" "%BUILDDIR%"\%SYSNAME% -C
goto :EOF
)

if "%1" equ "data" (
1>nul %CADIUS% REPLACEFILE "%BUILDDISK%" "/%DISKVOLUME%/" "%BUILDDIR%"\%SYSNAME% -C
goto :EOF
)

if "%1" equ "clean" (
echo y|1>nul 2>nul rd %BUILDDIR% /s
goto :EOF
)

:builddir
2>nul md %BUILDDIR%
1>nul %CADIUS% CREATEVOLUME "%BUILDDISK%" "%DISKVOLUME%" 140KB -C
goto :EOF

echo usage: %0 clean / exe / data
goto :EOF
