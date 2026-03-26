@echo off
setlocal EnableExtensions DisableDelayedExpansion

if "%~3"=="" (
  echo Usage: flutter_win.cmd PROJECT_DIR OUTPUT_FILE ARGS_FILE [FLUTTER_EXE]
  exit /b 1
)

set "PROJECT_DIR=%~1"
set "OUTPUT_FILE=%~2"
set "ARGS_FILE=%~3"
set "FLUTTER_EXE=%~4"

if not defined FLUTTER_EXE (
  if defined FLUTTER_WIN_EXECUTABLE (
    set "FLUTTER_EXE=%FLUTTER_WIN_EXECUTABLE%"
  )
)

if not defined FLUTTER_EXE (
  for /f "delims=" %%F in ('where flutter 2^>nul') do (
    set "FLUTTER_EXE=%%F"
    goto :flutter_found
  )
)

if not defined FLUTTER_EXE if exist "C:\DEV\SDK\flutter\bin\flutter.bat" set "FLUTTER_EXE=C:\DEV\SDK\flutter\bin\flutter.bat"
if not defined FLUTTER_EXE if exist "C:\src\flutter\bin\flutter.bat" set "FLUTTER_EXE=C:\src\flutter\bin\flutter.bat"
if not defined FLUTTER_EXE if exist "C:\flutter\bin\flutter.bat" set "FLUTTER_EXE=C:\flutter\bin\flutter.bat"

:flutter_found
if not defined FLUTTER_EXE (
  echo Unable to locate flutter.bat on Windows. 1>&2
  exit /b 1
)

if not exist "%ARGS_FILE%" (
  echo Args file not found: %ARGS_FILE% 1>&2
  exit /b 1
)

set "COMMAND=flutter"
for /f "usebackq delims=" %%A in ("%ARGS_FILE%") do (
  call set "COMMAND=%%COMMAND%% %%A"
)

(
  echo timestamp=%DATE% %TIME%
  echo project_dir=%PROJECT_DIR%
  echo flutter_executable=%FLUTTER_EXE%
  echo command=%COMMAND%
  echo.
)> "%OUTPUT_FILE%"

cd /d "%PROJECT_DIR%" || exit /b 1

setlocal EnableDelayedExpansion
set "FLUTTER_ARGS="
for /f "usebackq delims=" %%A in ("%ARGS_FILE%") do (
  set "ARG=%%A"
  set "FLUTTER_ARGS=!FLUTTER_ARGS! "%%A""
)

call "%FLUTTER_EXE%" !FLUTTER_ARGS! >> "%OUTPUT_FILE%" 2>&1
set "EXIT_CODE=!ERRORLEVEL!"

>> "%OUTPUT_FILE%" echo.
>> "%OUTPUT_FILE%" echo exit_code=!EXIT_CODE!

exit /b !EXIT_CODE!
