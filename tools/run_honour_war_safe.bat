@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0.."

echo ================================================
echo HONOUR WAR - HD SAFE LAUNCHER
echo ================================================
echo Looking for Godot 4.2.2...

set "GODOT="

rem 1. Use Godot already available in PATH.
for /f "delims=" %%G in ('where godot 2^>nul') do if not defined GODOT set "GODOT=%%G"

rem 2. Check common Godot installation/extraction locations.
if not defined GODOT if exist "%LOCALAPPDATA%\Programs\Godot\Godot.exe" set "GODOT=%LOCALAPPDATA%\Programs\Godot\Godot.exe"
if not defined GODOT if exist "%LOCALAPPDATA%\Godot\Godot.exe" set "GODOT=%LOCALAPPDATA%\Godot\Godot.exe"
if not defined GODOT if exist "%ProgramFiles%\Godot\Godot.exe" set "GODOT=%ProgramFiles%\Godot\Godot.exe"
if not defined GODOT if exist "%ProgramFiles(x86)%\Godot\Godot.exe" set "GODOT=%ProgramFiles(x86)%\Godot\Godot.exe"

rem 3. Search common user folders for a Godot executable.
if not defined GODOT for /f "delims=" %%G in ('where /r "%LOCALAPPDATA%\Programs" Godot*.exe 2^>nul') do if not defined GODOT set "GODOT=%%G"
if not defined GODOT for /f "delims=" %%G in ('where /r "%LOCALAPPDATA%" Godot_v4.2.2*.exe 2^>nul') do if not defined GODOT set "GODOT=%%G"
if not defined GODOT for /f "delims=" %%G in ('where /r "%USERPROFILE%\Desktop" Godot*.exe 2^>nul') do if not defined GODOT set "GODOT=%%G"
if not defined GODOT for /f "delims=" %%G in ('where /r "%USERPROFILE%\Downloads" Godot*.exe 2^>nul') do if not defined GODOT set "GODOT=%%G"

rem 4. If Godot is installed somewhere else, open a Windows file picker.
if not defined GODOT (
  echo.
  echo Godot was not found automatically.
  echo Please select your Godot 4.2.2 executable in the file picker.
  echo.
  for /f "usebackq delims=" %%G in (`powershell -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $d=New-Object System.Windows.Forms.OpenFileDialog; $d.Title='Select Godot 4.2.2 executable (Godot*.exe)'; $d.Filter='Godot executable|Godot*.exe|Executable files|*.exe'; $d.InitialDirectory=[Environment]::GetFolderPath('Desktop'); if($d.ShowDialog() -eq 'OK'){ $d.FileName }"`) do set "GODOT=%%G"
)

if not defined GODOT (
  echo.
  echo No Godot executable was selected.
  echo Honour War cannot start without Godot 4.2.2.
  echo.
  pause
  exit /b 1
)

if not exist "%GODOT%" (
  echo.
  echo The selected Godot executable could not be found:
  echo %GODOT%
  echo.
  pause
  exit /b 1
)

echo Found Godot:
echo %GODOT%
echo.
echo Attempting Forward+ Vulkan first.
echo If Windows has no compatible Vulkan ICD, the launcher will fall back to Compatibility/OpenGL.
echo.

"%GODOT%" --path . --rendering-method forward_plus --rendering-driver vulkan %*
if not errorlevel 1 exit /b 0

echo.
echo Forward+ could not initialize Vulkan on this machine.
echo Falling back to Godot Compatibility/OpenGL so the game can still launch.
echo.
"%GODOT%" --path . --rendering-method gl_compatibility --rendering-driver opengl3 %*
exit /b %errorlevel%
