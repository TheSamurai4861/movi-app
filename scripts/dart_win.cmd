@echo off
setlocal EnableExtensions DisableDelayedExpansion

if "%~3"=="" (
  echo Usage: dart_win.cmd PROJECT_DIR OUTPUT_FILE ARGS_FILE [DART_EXE]
  exit /b 1
)

set "PROJECT_DIR=%~1"
set "OUTPUT_FILE=%~2"
set "ARGS_FILE=%~3"
set "DART_EXE=%~4"

if not defined DART_EXE (
  if defined DART_WIN_EXECUTABLE (
    set "DART_EXE=%DART_WIN_EXECUTABLE%"
  )
)

if not defined DART_EXE (
  for /f "delims=" %%D in ('where dart.bat 2^>nul') do (
    set "DART_EXE=%%D"
    goto :dart_found
  )
)

if not defined DART_EXE (
  for /f "delims=" %%D in ('where dart 2^>nul') do (
    set "DART_EXE=%%D"
    goto :dart_found
  )
)

if not defined DART_EXE if exist "C:\DEV\SDK\flutter\bin\dart.bat" set "DART_EXE=C:\DEV\SDK\flutter\bin\dart.bat"
if not defined DART_EXE if exist "C:\src\flutter\bin\dart.bat" set "DART_EXE=C:\src\flutter\bin\dart.bat"
if not defined DART_EXE if exist "C:\flutter\bin\dart.bat" set "DART_EXE=C:\flutter\bin\dart.bat"

:dart_found
if not defined DART_EXE (
  echo Unable to locate dart.bat on Windows. 1>&2
  exit /b 1
)

if not exist "%ARGS_FILE%" (
  echo Args file not found: %ARGS_FILE% 1>&2
  exit /b 1
)

set "COMMAND=dart"
for /f "usebackq delims=" %%A in ("%ARGS_FILE%") do (
  call set "COMMAND=%%COMMAND%% %%A"
)

(
  echo timestamp=%DATE% %TIME%
  echo project_dir=%PROJECT_DIR%
  echo dart_executable=%DART_EXE%
  echo command=%COMMAND%
  echo.
)> "%OUTPUT_FILE%"

cd /d "%PROJECT_DIR%" || exit /b 1

setlocal EnableDelayedExpansion
set "DART_ARGS="
for /f "usebackq delims=" %%A in ("%ARGS_FILE%") do (
  set "ARG=%%A"
  set "DART_ARGS=!DART_ARGS! "%%A""
)

call "%DART_EXE%" !DART_ARGS! >> "%OUTPUT_FILE%" 2>&1
set "EXIT_CODE=!ERRORLEVEL!"

>> "%OUTPUT_FILE%" echo.
>> "%OUTPUT_FILE%" echo exit_code=!EXIT_CODE!

exit /b !EXIT_CODE!
