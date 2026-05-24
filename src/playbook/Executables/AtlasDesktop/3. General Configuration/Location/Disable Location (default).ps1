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
Set-ItemProperty -Path $atlasKey -Name state -Value 0 -Type DWord -Force
Set-ItemProperty -Path $atlasKey -Name path  -Value $PSCommandPath -Type String -Force

foreach ($svcName in @('lfsvc', 'MapsBroker')) {
    Set-Service  -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service -Name $svcName -Force               -ErrorAction SilentlyContinue
}

$fmdKey = 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice'
if (-not (Test-Path -LiteralPath $fmdKey)) { New-Item -Path $fmdKey -Force | Out-Null }
Set-ItemProperty -Path $fmdKey -Name AllowFindMyDevice  -Value 0 -Type DWord -Force
Set-ItemProperty -Path $fmdKey -Name LocationSyncEnabled -Value 0 -Type DWord -Force

$consentKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'
if (-not (Test-Path -LiteralPath $consentKey)) { New-Item -Path $consentKey -Force | Out-Null }
Set-ItemProperty -Path $consentKey -Name ShowGlobalPrompts -Value 0 -Type DWord -Force

$settingsPages = Join-Path $env:windir 'AtlasModules\Scripts\Helpers\Set-SettingsPageVisibility.ps1'
if (Test-Path -LiteralPath $settingsPages) {
    foreach ($page in @('privacy-location', 'findmydevice')) {
        & $settingsPages -Operation hide -Page $page -Silent
    }
}

if (-not $Silent) {
    Write-Host ''
    Write-Host 'Location services have been disabled.' -ForegroundColor Green
    Read-Host 'Press Enter to exit'
}
