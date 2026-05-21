#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Disable Widgets (default)
# Disables News and Interests / Widgets via policy registry values and
# restarts Explorer to apply the change unless -NoAction is passed.
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
$stateValue  = 0
$scriptPath  = $PSCommandPath

try {
    $atlasKey = "HKLM:\SOFTWARE\AtlasOS\Services\$settingName"
    if (-not (Test-Path $atlasKey)) { New-Item -Path $atlasKey -Force | Out-Null }
    Set-ItemProperty -Path $atlasKey -Name 'state' -Value $stateValue -Type DWord  -Force
    Set-ItemProperty -Path $atlasKey -Name 'path'  -Value $scriptPath -Type String -Force

    $feedsKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds'
    if (-not (Test-Path $feedsKey)) { New-Item -Path $feedsKey -Force | Out-Null }
    Set-ItemProperty -Path $feedsKey -Name 'EnableFeeds' -Value 0 -Type DWord -Force

    $dshKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'
    if (-not (Test-Path $dshKey)) { New-Item -Path $dshKey -Force | Out-Null }
    Set-ItemProperty -Path $dshKey -Name 'AllowNewsAndInterests' -Value 0 -Type DWord -Force

    if (-not $NoAction) {
        Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
    }

    if (-not $Silent) {
        Write-Host '[OK] Widgets disabled.' -ForegroundColor Green
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to disable Widgets: $_" -ForegroundColor Red
    exit 1
}
