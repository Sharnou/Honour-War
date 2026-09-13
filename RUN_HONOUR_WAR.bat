@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo ================================================
echo HONOUR WAR - HD GAME LAUNCHER
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
echo Starting the Honour War GAME in Compatibility/OpenGL mode.
echo The project production renderer remains Forward+.
echo.
rem IMPORTANT: do not use --editor here. This launcher runs the actual game.
rem The editor is opened separately when editing the project.
"%GODOT%" --path "%CD%" --rendering-method gl_compatibility --rendering-driver opengl3 %*
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
