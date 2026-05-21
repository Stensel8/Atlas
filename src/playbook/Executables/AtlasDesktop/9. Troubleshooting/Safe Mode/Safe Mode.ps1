#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Safe Mode
# Enables Safe Mode (minimal) on next reboot via bcdedit.
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

$settingName = 'SafeMode'
$stateValue  = 3
$scriptPath  = $PSCommandPath

try {
    $atlasKey = "HKLM:\SOFTWARE\AtlasOS\Services\$settingName"
    if (-not (Test-Path $atlasKey)) { New-Item -Path $atlasKey -Force | Out-Null }
    Set-ItemProperty -Path $atlasKey -Name 'state' -Value $stateValue -Type DWord  -Force
    Set-ItemProperty -Path $atlasKey -Name 'path'  -Value $scriptPath -Type String -Force

    & bcdedit.exe /set '{current}' safeboot minimal | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "bcdedit exited with code $LASTEXITCODE." }

    if (-not $Silent) {
        Write-Host '[OK] Safe Mode enabled. Reboot your device for changes to apply.' -ForegroundColor Green
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to enable Safe Mode: $_" -ForegroundColor Red
    exit 1
}
