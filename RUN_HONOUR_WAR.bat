@echo off
setlocal
cd /d "%~dp0"
call tools\run_honour_war_safe.bat %*
exit /b %errorlevel%
