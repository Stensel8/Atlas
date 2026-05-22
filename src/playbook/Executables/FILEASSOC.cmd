@echo off
set "script=%~dp0AtlasModules\Scripts\fileAssoc.ps1"

if not exist "%script%" (
    echo Script not found: "%script%"
    exit /b 1
)

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%script%" %*
exit /b %errorlevel%
