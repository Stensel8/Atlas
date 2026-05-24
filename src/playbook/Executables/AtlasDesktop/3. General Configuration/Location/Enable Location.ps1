#Requires -Version 5.1
param([switch]$Silent)

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
        Write-Host 'Administrator privileges are required.' -ForegroundColor Red
        if (-not $Silent) { Read-Host 'Press Enter to exit' }
        exit 1
    }
    exit 0
}

$atlasKey = 'HKLM:\SOFTWARE\AtlasOS\Services\Location'
if (-not (Test-Path -LiteralPath $atlasKey)) { New-Item -Path $atlasKey -Force | Out-Null }
Set-ItemProperty -Path $atlasKey -Name state -Value 1 -Type DWord -Force
Set-ItemProperty -Path $atlasKey -Name path  -Value $PSCommandPath -Type String -Force

# lfsvc = Manual (demand), MapsBroker = Automatic
Set-Service  -Name 'lfsvc'     -StartupType Manual    -ErrorAction SilentlyContinue
Set-Service  -Name 'MapsBroker' -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service -Name 'lfsvc'     -ErrorAction SilentlyContinue
Start-Service -Name 'MapsBroker' -ErrorAction SilentlyContinue

$settingsPages = Join-Path $env:windir 'AtlasModules\Scripts\Helpers\Set-SettingsPageVisibility.ps1'
if (Test-Path -LiteralPath $settingsPages) {
    & $settingsPages -Operation unhide -Page 'privacy-location' -Silent
}

$enableFMD = $false
if (-not $Silent) {
    $choice = Read-Host 'Would you like to enable Find My Device? [Y/N]'
    $enableFMD = $choice -match '^[Yy]'
}

if ($enableFMD) {
    Remove-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice' -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $settingsPages) {
        & $settingsPages -Operation unhide -Page 'findmydevice' -Silent
    }
} else {
    $fmdKey = 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice'
    if (-not (Test-Path -LiteralPath $fmdKey)) { New-Item -Path $fmdKey -Force | Out-Null }
    Set-ItemProperty -Path $fmdKey -Name AllowFindMyDevice  -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $fmdKey -Name LocationSyncEnabled -Value 0 -Type DWord -Force
}

if (-not $Silent) {
    Write-Host ''
    Write-Host 'Location services have been enabled.' -ForegroundColor Green
    Start-Process 'ms-settings:privacy-location'
    Read-Host 'Press Enter to exit'
}
