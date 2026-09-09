@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo ================================================
echo HONOUR WAR - HD SAFE LAUNCHER
echo ================================================
echo.
set "GODOT="
for /f "delims=" %%G in ('where godot.exe 2^>nul') do if not defined GODOT set "GODOT=%%G"
for /f "delims=" %%G in ('where godot_console.exe 2^>nul') do if not defined GODOT set "GODOT=%%G"
if not defined GODOT if exist "%~dp0Godot.exe" set "GODOT=%~dp0Godot.exe"
if not defined GODOT if exist "%~dp0Godot_v4.2.2-stable_win64.exe" set "GODOT=%~dp0Godot_v4.2.2-stable_win64.exe"
if not defined GODOT if exist "%~dp0Godot_v4.2.2-stable_win64_console.exe" set "GODOT=%~dp0Godot_v4.2.2-stable_win64_console.exe"
if not defined GODOT if exist "%LOCALAPPDATA%\Programs\Godot\Godot.exe" set "GODOT=%LOCALAPPDATA%\Programs\Godot\Godot.exe"
if not defined GODOT if exist "%LOCALAPPDATA%\Godot\Godot.exe" set "GODOT=%LOCALAPPDATA%\Godot\Godot.exe"
if not defined GODOT if exist "%ProgramFiles%\Godot\Godot.exe" set "GODOT=%ProgramFiles%\Godot\Godot.exe"
if not defined GODOT if exist "%ProgramFiles(x86)%\Godot\Godot.exe" set "GODOT=%ProgramFiles(x86)%\Godot\Godot.exe"
if not defined GODOT goto FAIL

echo Godot found:
echo %GODOT%
echo.
echo Starting Honour War using Compatibility/OpenGL for Godot 4.2.2.
echo The production renderer target remains Forward+.
echo.
rem Keep the executable and each argument separately quoted. Using %CD% avoids
rem the malformed quoted project path seen in older launcher versions.
"%GODOT%" --path "%CD%" --editor --rendering-method gl_compatibility --rendering-driver opengl3 %*
set "RESULT=%errorlevel%"
echo.
if not "%RESULT%"=="0" echo Honour War exited with code %RESULT%.
pause
exit /b %RESULT%

:FAIL
echo Godot was not found. Place Godot_v4.2.2-stable_win64.exe beside this file,
echo install Godot, or add godot.exe to PATH.
pause
exit /b 1
