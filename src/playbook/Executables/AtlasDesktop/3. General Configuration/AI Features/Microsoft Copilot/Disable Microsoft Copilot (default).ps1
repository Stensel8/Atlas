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

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'Copilot' -State 0 -ScriptPath $PSCommandPath

try {
    Write-Host '[>>] Disabling and uninstalling Copilot...' -ForegroundColor Yellow
    Get-AppxPackage -AllUsers 'Microsoft.Copilot*' | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

    $advKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    if (-not (Test-Path $advKey)) { New-Item -Path $advKey -Force | Out-Null }
    Set-ItemProperty -Path $advKey -Name 'ShowCopilotButton' -Value 0 -Type DWord -Force

    $policyKey = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot'
    if (-not (Test-Path $policyKey)) { New-Item -Path $policyKey -Force | Out-Null }
    Set-ItemProperty -Path $policyKey -Name 'TurnOffWindowsCopilot' -Value 1 -Type DWord -Force

    if (-not $NoAction) {
        Write-Host '[>>] Restarting Explorer...' -ForegroundColor Yellow
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
