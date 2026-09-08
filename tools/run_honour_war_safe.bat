@echo off
setlocal
cd /d "%~dp0.."

where godot >nul 2>&1
if errorlevel 1 (
  echo Godot was not found in PATH.
  echo Install Godot 4.2.2 and add it to PATH, or launch the project from the Godot editor.
  pause
  exit /b 1
)

echo ================================================
echo HONOUR WAR - HD SAFE LAUNCHER
echo ================================================
echo Attempting Forward+ Vulkan first.
echo If Windows has no compatible Vulkan ICD, the launcher will fall back to Compatibility.
echo.

godot --path . --rendering-method forward_plus --rendering-driver vulkan %*
if not errorlevel 1 exit /b 0

echo.
echo Forward+ could not initialize Vulkan on this machine.
echo Falling back to Godot Compatibility/OpenGL so the game can still launch.
echo.
godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 %*
exit /b %errorlevel%
