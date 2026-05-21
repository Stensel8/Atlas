#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Install Software
# Launches the Atlas software installer from AtlasModules.
# ============================================================================

param(
    [switch]$Silent
)

$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Silent) { $argList += ' -Silent' }
    try {
        Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs -Wait
    } catch {
        Write-Host '[!!] Administrator privileges are required.' -ForegroundColor Red
        if (-not $Silent) { Read-Host 'Press Enter to exit' }
        exit 1
    }
    exit 0
}

$script = Join-Path $env:windir 'AtlasModules\Scripts\ScriptWrappers\InstallSoftware.ps1'
if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
    Write-Host "[!!] Script not found: '$script'" -ForegroundColor Red
    if (-not $Silent) { Read-Host 'Press Enter to exit' }
    exit 1
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script @args
exit $LASTEXITCODE
