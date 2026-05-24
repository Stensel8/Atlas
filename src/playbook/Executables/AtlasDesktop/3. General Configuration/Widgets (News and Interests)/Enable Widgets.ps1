#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Enable Widgets
# Re-enables News and Interests / Widgets by removing the policy keys.
# Requires Edge or WebView2 for Widgets to function (checked via Test-EdgeInstall.ps1).
# Restarts Explorer and opens the taskbar Settings page to let the user
# toggle the widget icon. -NoAction skips the Explorer restart.
# ============================================================================

param(
    [switch]$Silent,
    [switch]$NoAction
)

$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Silent)   { $argList += ' -Silent' }
    if ($NoAction) { $argList += ' -NoAction' }
    try {
        Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs -Wait
    } catch {
        Write-Host '[!!] Administrator privileges are required.' -ForegroundColor Red
        if (-not $Silent) { Read-Host 'Press Enter to exit' }
        exit 1
    }
    exit 0
}

$settingName = 'Widgets'
$stateValue  = 1
$scriptPath  = $PSCommandPath

try {
    $atlasKey = "HKLM:\SOFTWARE\AtlasOS\Services\$settingName"
    if (-not (Test-Path $atlasKey)) { New-Item -Path $atlasKey -Force | Out-Null }
    Set-ItemProperty -Path $atlasKey -Name 'state' -Value $stateValue -Type DWord  -Force
    Set-ItemProperty -Path $atlasKey -Name 'path'  -Value $scriptPath -Type String -Force

    $edgeCheck = Join-Path $env:windir 'AtlasModules\Scripts\Test-EdgeInstall.ps1'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $edgeCheck
    if ($LASTEXITCODE -ne 0) { exit 1 }

    Write-Host '[>>] Enabling Widgets...' -ForegroundColor Yellow

    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' `
        -Name 'EnableFeeds' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' `
        -Name 'AllowNewsAndInterests' -ErrorAction SilentlyContinue

    if (-not $NoAction) {
        Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        Start-Process 'ms-settings:taskbar'
    }

    if (-not $Silent) {
        Write-Host '[OK] Widgets enabled. Toggle the icon in the taskbar Settings page.' -ForegroundColor Green
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to enable Widgets: $_" -ForegroundColor Red
    exit 1
}
