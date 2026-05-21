#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Add Terminals
# Adds all terminal entries (including Windows Terminal) to the right-click
# context menu by importing the 'enabled' registry file.
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

$settingName = 'ContextMenuTerminals'
$stateValue  = 1
$scriptPath  = $PSCommandPath

try {
    $atlasKey = "HKLM:\SOFTWARE\AtlasOS\Services\$settingName"
    if (-not (Test-Path $atlasKey)) { New-Item -Path $atlasKey -Force | Out-Null }
    Set-ItemProperty -Path $atlasKey -Name 'state' -Value $stateValue -Type DWord  -Force
    Set-ItemProperty -Path $atlasKey -Name 'path'  -Value $scriptPath -Type String -Force

    $regFile = Join-Path $env:windir 'AtlasModules\Scripts\Registry\Terminals\enabled.reg'
    & reg.exe import $regFile 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Registry import failed with exit code $LASTEXITCODE." }

    if (-not $Silent) {
        Write-Host '[OK] Terminal context menu entries added (with Windows Terminal).' -ForegroundColor Green
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to add terminal context menu: $_" -ForegroundColor Red
    exit 1
}
