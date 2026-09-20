@echo off
setlocal
set "UE_ROOT=%UNREAL_ENGINE_ROOT%"
if "%UE_ROOT%"=="" set "UE_ROOT=C:\Program Files\Epic Games\UE_5.8"
set "EDITOR=%UE_ROOT%\Engine\Binaries\Win64\UnrealEditor.exe"
if not exist "%EDITOR%" (
  echo Unreal Engine 5.8 was not found at:
  echo %UE_ROOT%
  exit /b 1
)
"%EDITOR%" "%~dp0..\HonourWar.uproject" -game -windowed -ResX=1920 -ResY=1080
