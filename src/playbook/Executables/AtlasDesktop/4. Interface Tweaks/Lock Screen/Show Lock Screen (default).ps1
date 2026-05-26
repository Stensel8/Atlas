#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Show Lock Screen (default)
# Restores the Windows lock screen to its default (visible) state.
# Removes NoLockScreen and NoChangingLockScreen so Settings are no longer
# greyed out / "managed by your organization".
# ============================================================================

param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'LockScreen' -State 1 -ScriptPath $PSCommandPath

try {
    Write-Host '[>>] Restoring lock screen policy...' -ForegroundColor Yellow
    $policyKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'
    Remove-ItemProperty -Path $policyKey -Name 'NoLockScreen'         -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $policyKey -Name 'NoChangingLockScreen' -ErrorAction SilentlyContinue

    if (-not $Silent) {
        Write-Host '[OK] Lock screen restored.' -ForegroundColor Green
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to restore lock screen: $_" -ForegroundColor Red
    exit 1
}
