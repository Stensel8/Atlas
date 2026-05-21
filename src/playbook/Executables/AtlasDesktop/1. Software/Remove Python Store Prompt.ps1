#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Remove Python Store Prompt
# Removes Python stub executables from WindowsApps that redirect to the Store.
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

try {
    $stubPath = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
    $stubs = Get-ChildItem -Path $stubPath -Filter 'python*.exe' -ErrorAction SilentlyContinue
    foreach ($stub in $stubs) {
        Remove-Item -LiteralPath $stub.FullName -Force
    }

    if (-not $Silent) {
        if ($stubs.Count -gt 0) {
            Write-Host "[OK] Removed $($stubs.Count) Python stub executable(s) from WindowsApps." -ForegroundColor Green
        } else {
            Write-Host '[OK] No Python stub executables found.' -ForegroundColor Green
        }
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to remove Python stubs: $_" -ForegroundColor Red
    if (-not $Silent) { Read-Host 'Press Enter to exit' }
    exit 1
}
