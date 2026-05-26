#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Exit Safe Mode
# Removes Safe Mode boot entries and restores normal boot via bcdedit.
# Both safeboot and safebootalternateshell are cleared; errors are ignored
# since either value may not be set depending on which Safe Mode was used.
# ============================================================================

param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'SafeMode' -State 0 -ScriptPath $PSCommandPath

try {
    Write-Host '[>>] Clearing Safe Mode boot entries...' -ForegroundColor Yellow
    & bcdedit.exe /deletevalue '{current}' safeboot               2>&1 | Out-Null
    & bcdedit.exe /deletevalue '{current}' safebootalternateshell 2>&1 | Out-Null

    if (-not $Silent) {
        Write-Host '[OK] Safe Mode cleared. Reboot your device for changes to apply.' -ForegroundColor Green
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to exit Safe Mode: $_" -ForegroundColor Red
    exit 1
}
