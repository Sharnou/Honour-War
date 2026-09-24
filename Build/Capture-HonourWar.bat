@echo off
setlocal
set "UE_ROOT=%UNREAL_ENGINE_ROOT%"
if "%UE_ROOT%"=="" set "UE_ROOT=C:\Program Files\Epic Games\UE_5.8"
set "ROOT=%~dp0.."
powershell -ExecutionPolicy Bypass -File "%ROOT%\Build\Build-HonourWar.ps1" -Package
if errorlevel 1 exit /b %errorlevel%
powershell -ExecutionPolicy Bypass -File "%ROOT%\Build\Capture-HonourWar.ps1"
if errorlevel 1 exit /b %errorlevel%
echo REAL GAMEPLAY SCREENSHOT: %ROOT%\Build\HonourWar-real-runtime.png
