@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo "Usage: compile_and_run.bat <file_list.txt> <run_binary>"
    exit /b 1
)

set file_list=%1
set run_binary=%2

if not exist %file_list% (
    echo File not found: %file_list%
    exit /b 1
)

if not exist build mkdir build

for /f %%a in (%file_list%) do (
    set input_file=%%~na
    echo Compiling: %%a
    ca65 --verbose src\%%a -o build\!input_file!.o --debug-info
    if !errorlevel! neq 0 exit /b !errorlevel!
)

set output_nes_name=dvd_logo

set files_to_link=
for /f %%a in (%file_list%) do (
    set input_file=%%~na
    set files_to_link=!files_to_link! build\!input_file!.o
)

echo Linking...
ld65 %files_to_link% -o build\!output_nes_name!.nes -C nes.cfg --dbgfile build\!output_nes_name!.dbg
if !errorlevel! neq 0 exit /b !errorlevel!

if "%run_binary%"=="true" (
    start "mesen" "build/!output_nes_name!.nes"
)

echo "Done."