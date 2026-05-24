#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args"
    exit
}

$script = Join-Path $env:windir 'AtlasModules\Scripts\Install-AtlasToolbox.ps1'
if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
    Write-Error "Script not found: '$script'"
    Read-Host 'Press Enter to exit'
    exit 1
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script @args
