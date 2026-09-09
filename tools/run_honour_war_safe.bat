@echo off
setlocal EnableExtensions
cd /d "%~dp0.."

echo ================================================
echo HONOUR WAR - HD SAFE LAUNCHER
echo ================================================
echo.

set "GODOT="

rem Prefer the normal windowed Godot executable so no black console remains.
for /f "delims=" %%G in ('where godot.exe 2^>nul') do if not defined GODOT set "GODOT=%%G"
if not defined GODOT if exist "%~dp0..\Godot_v4.2.2-stable_win64.exe" set "GODOT=%~dp0..\Godot_v4.2.2-stable_win64.exe"
if not defined GODOT if exist "%~dp0..\Godot_v4.2.2-stable_win64_console.exe" set "GODOT=%~dp0..\Godot_v4.2.2-stable_win64_console.exe"
if not defined GODOT if exist "%LOCALAPPDATA%\Programs\Godot\Godot.exe" set "GODOT=%LOCALAPPDATA%\Programs\Godot\Godot.exe"
if not defined GODOT if exist "%LOCALAPPDATA%\Godot\Godot.exe" set "GODOT=%LOCALAPPDATA%\Godot\Godot.exe"
if not defined GODOT if exist "%ProgramFiles%\Godot\Godot.exe" set "GODOT=%ProgramFiles%\Godot\Godot.exe"
if not defined GODOT if exist "%ProgramFiles(x86)%\Godot\Godot.exe" set "GODOT=%ProgramFiles(x86)%\Godot\Godot.exe"

if defined GODOT goto FOUND

echo Godot was not found automatically.
echo.
echo Enter the FULL path to your Godot executable.
echo Example:
echo C:\Godot\Godot_v4.2.2-stable_win64.exe
echo.
set /p "GODOT=Godot.exe path: "
set "GODOT=%GODOT:"=%"
if not defined GODOT goto NO_GODOT
if exist "%GODOT%" goto FOUND

echo.
echo ERROR: That file does not exist:
echo %GODOT%
echo.
pause
exit /b 1

:FOUND
echo Godot found:
echo %GODOT%
echo.
echo Starting Honour War in Compatibility/OpenGL for Godot 4.2.2.
echo The production project renderer remains Forward+.
echo.

for %%G in ("%GODOT%") do set "GODOT_NAME=%%~nxG"
if /I "%GODOT_NAME%"=="Godot_v4.2.2-stable_win64_console.exe" goto CONSOLE_START

"%GODOT%" --path "%~dp0.." --rendering-method gl_compatibility --rendering-driver opengl3 %*
set "RESULT=%errorlevel%"
goto DONE

:CONSOLE_START
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Start-Process -FilePath '%GODOT%' -ArgumentList '--path','%~dp0..','--rendering-method','gl_compatibility','--rendering-driver','opengl3' -WindowStyle Hidden"
set "RESULT=%errorlevel%"

:DONE
if not "%RESULT%"=="0" echo Honour War launcher exited with code %RESULT%.
exit /b %RESULT%

:NO_GODOT
echo.
echo No Godot executable was supplied.
echo Honour War cannot start until Godot 4.2.2 is installed.
pause
exit /b 1
