@echo off
setlocal EnableExtensions
cd /d "%~dp0.."

echo ================================================
echo HONOUR WAR - HD SAFE LAUNCHER
 echo ================================================
echo.

set "GODOT="

rem Try PATH first.
for /f "delims=" %%G in ('where godot.exe 2^>nul') do if not defined GODOT set "GODOT=%%G"

rem Try common locations.
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
echo Your PC reports that Godot 4.2.2 cannot initialize Vulkan.
echo The normal launcher will therefore use Compatibility/OpenGL.
echo This does NOT change the Honour War production renderer target.
echo.
echo Starting Honour War in Compatibility/OpenGL...
echo.

"%GODOT%" --path "%~dp0.." --rendering-method gl_compatibility --rendering-driver opengl3 %*
set "RESULT=%errorlevel%"

echo.
if "%RESULT%"=="0" (
  echo Honour War closed normally.
) else (
  echo Honour War exited with code %RESULT%.
)
echo.
pause
exit /b %RESULT%

:NO_GODOT
echo.
echo No Godot executable was supplied.
echo Honour War cannot start until Godot 4.2.2 is installed.
echo.
pause
exit /b 1
