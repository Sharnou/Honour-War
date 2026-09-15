@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo ================================================
echo HONOUR WAR - HD GAME LAUNCHER
echo Godot 4.7.x default (4.7.2 stable)
echo ================================================
echo.
set "GODOT="
rem Prefer the pinned Godot 4.7.2 stable executable for Honour War.
if exist "%~dp0Godot_v4.7.2-stable_win64.exe" set "GODOT=%~dp0Godot_v4.7.2-stable_win64.exe"
if not defined GODOT if exist "%~dp0Godot_v4.7.2-stable_win64_console.exe" set "GODOT=%~dp0Godot_v4.7.2-stable_win64_console.exe"
for /f "delims=" %%G in ('where godot.exe 2^>nul') do if not defined GODOT set "GODOT=%%G"
for /f "delims=" %%G in ('where godot_console.exe 2^>nul') do if not defined GODOT set "GODOT=%%G"
if not defined GODOT if exist "%~dp0Godot.exe" set "GODOT=%~dp0Godot.exe"
if not defined GODOT if exist "%LOCALAPPDATA%\Programs\Godot\Godot.exe" set "GODOT=%LOCALAPPDATA%\Programs\Godot\Godot.exe"
if not defined GODOT if exist "%LOCALAPPDATA%\Godot\Godot.exe" set "GODOT=%LOCALAPPDATA%\Godot\Godot.exe"
if not defined GODOT if exist "%ProgramFiles%\Godot\Godot.exe" set "GODOT=%ProgramFiles%\Godot\Godot.exe"
if not defined GODOT if exist "%ProgramFiles(x86)%\Godot\Godot.exe" set "GODOT=%ProgramFiles(x86)%\Godot\Godot.exe"
if not defined GODOT goto FAIL

echo Godot found:
echo %GODOT%
echo.
echo Honour War target engine: Godot 4.7.x (4.7.2 stable).
echo Starting Honour War with the project's production renderer (Forward+/Vulkan).
echo Compatibility/OpenGL is used only as an automatic fallback if production startup fails.
echo.
rem IMPORTANT: do not use --editor here. This launcher runs the actual game.
"%GODOT%" --path "%CD%" %*
set "RESULT=%errorlevel%"
if "%RESULT%"=="0" goto DONE

echo.
echo Forward+/Vulkan startup failed with code %RESULT%.
echo Retrying Honour War in Compatibility/OpenGL fallback mode...
echo.
"%GODOT%" --path "%CD%" --rendering-method gl_compatibility --rendering-driver opengl3 %*
set "RESULT=%errorlevel%"

:DONE
echo.
if not "%RESULT%"=="0" echo Honour War exited with code %RESULT%.
pause
exit /b %RESULT%

:FAIL
echo Godot 4.7.x was not found.
echo Preferred local executable: Godot_v4.7.2-stable_win64.exe
if exist "%~dp0Godot_v4.7.2-stable_win64.exe" goto DONE
pause
exit /b 1
