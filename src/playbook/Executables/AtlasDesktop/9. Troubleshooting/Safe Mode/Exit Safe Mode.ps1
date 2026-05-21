#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Exit Safe Mode
# Removes Safe Mode boot entries and restores normal boot via bcdedit.
# Both safeboot and safebootalternateshell are cleared; errors are ignored
# since either value may not be set depending on which Safe Mode was used.
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
$stateValue  = 0
$scriptPath  = $PSCommandPath

try {
    $atlasKey = "HKLM:\SOFTWARE\AtlasOS\Services\$settingName"
    if (-not (Test-Path $atlasKey)) { New-Item -Path $atlasKey -Force | Out-Null }
    Set-ItemProperty -Path $atlasKey -Name 'state' -Value $stateValue -Type DWord  -Force
    Set-ItemProperty -Path $atlasKey -Name 'path'  -Value $scriptPath -Type String -Force

    & bcdedit.exe /deletevalue '{current}' safeboot            2>&1 | Out-Null
    & bcdedit.exe /deletevalue '{current}' safebootalternateshell 2>&1 | Out-Null

    if (-not $Silent) {
        Write-Host '[OK] Safe Mode cleared. Reboot your device for changes to apply.' -ForegroundColor Green
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to exit Safe Mode: $_" -ForegroundColor Red
    exit 1
}
