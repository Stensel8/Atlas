#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Safe Mode
# Enables Safe Mode (minimal) on next reboot via bcdedit.
# ============================================================================

param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'SafeMode' -State 3 -ScriptPath $PSCommandPath

try {
    Write-Host '[>>] Configuring Safe Mode (minimal) boot entry...' -ForegroundColor Yellow
    & bcdedit.exe /set '{current}' safeboot minimal | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "bcdedit exited with code $LASTEXITCODE." }

    if (-not $Silent) {
        Write-Host '[OK] Safe Mode enabled. Reboot your device for changes to apply.' -ForegroundColor Green
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to enable Safe Mode: $_" -ForegroundColor Red
    exit 1
}
