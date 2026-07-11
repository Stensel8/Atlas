#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Add Terminals
# Adds all terminal entries (including Windows Terminal) to the right-click
# context menu by importing the 'enabled' registry file.
# ============================================================================

param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'ContextMenuTerminals' -State 1 -ScriptPath $PSCommandPath

try {
    Write-Host '[>>] Adding terminal context menu entries (with Windows Terminal)...' -ForegroundColor Yellow
    $regFile = Join-Path $env:windir 'AtlasModules\Scripts\Registry\Terminals\enabled.reg'
    & reg.exe import $regFile 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Registry import failed with exit code $LASTEXITCODE." }

    if (-not $Silent) {
        Write-Host '[OK] Terminal context menu entries added (with Windows Terminal).' -ForegroundColor Green
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to add terminal context menu: $_" -ForegroundColor Red
    exit 1
}
