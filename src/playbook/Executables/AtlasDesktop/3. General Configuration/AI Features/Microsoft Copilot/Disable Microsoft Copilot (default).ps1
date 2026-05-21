#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Disable Microsoft Copilot (default)
# Removes the Copilot AppX package (all users), hides the taskbar button,
# and enforces the WindowsCopilot policy. Restarts Explorer to apply UI
# changes unless -NoAction is passed (e.g. when called by another script).
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

$settingName = 'Copilot'
$stateValue  = 0
$scriptPath  = $PSCommandPath

try {
    $atlasKey = "HKLM:\SOFTWARE\AtlasOS\Services\$settingName"
    if (-not (Test-Path $atlasKey)) { New-Item -Path $atlasKey -Force | Out-Null }
    Set-ItemProperty -Path $atlasKey -Name 'state' -Value $stateValue -Type DWord  -Force
    Set-ItemProperty -Path $atlasKey -Name 'path'  -Value $scriptPath -Type String -Force

    Write-Host '[>>] Disabling and uninstalling Copilot...' -ForegroundColor Yellow
    Get-AppxPackage -AllUsers 'Microsoft.Copilot*' | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

    $advKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    if (-not (Test-Path $advKey)) { New-Item -Path $advKey -Force | Out-Null }
    Set-ItemProperty -Path $advKey -Name 'ShowCopilotButton' -Value 0 -Type DWord -Force

    $policyKey = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot'
    if (-not (Test-Path $policyKey)) { New-Item -Path $policyKey -Force | Out-Null }
    Set-ItemProperty -Path $policyKey -Name 'TurnOffWindowsCopilot' -Value 1 -Type DWord -Force

    if (-not $NoAction) {
        Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
    }

    if (-not $Silent) {
        Write-Host '[OK] Copilot disabled.' -ForegroundColor Green
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to disable Copilot: $_" -ForegroundColor Red
    exit 1
}
