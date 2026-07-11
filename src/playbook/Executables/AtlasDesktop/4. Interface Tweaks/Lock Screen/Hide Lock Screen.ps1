#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Hide Lock Screen
# Disables the Windows lock screen via registry policy.
# Sets NoLockScreen and NoChangingLockScreen so Settings stay accessible
# (prevents the "managed by your organization" greyed-out state).
# ============================================================================

param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'LockScreen' -State 0 -ScriptPath $PSCommandPath

try {
    Write-Host '[>>] Applying lock screen policy...' -ForegroundColor Yellow
    $policyKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'
    if (-not (Test-Path $policyKey)) { New-Item -Path $policyKey -Force | Out-Null }
    Set-ItemProperty -Path $policyKey -Name 'NoLockScreen'         -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $policyKey -Name 'NoChangingLockScreen' -Value 1 -Type DWord -Force

    if (-not $Silent) {
        Write-Host '[OK] Lock screen hidden.' -ForegroundColor Green
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to hide lock screen: $_" -ForegroundColor Red
    exit 1
}
