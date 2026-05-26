#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Remove Python Store Prompt
# Removes Python stub executables from WindowsApps that redirect to the Store.
# ============================================================================

param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

try {
    Write-Host '[>>] Removing Python store stub executables...' -ForegroundColor Yellow
    $stubPath = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
    $stubs = Get-ChildItem -Path $stubPath -Filter 'python*.exe' -ErrorAction SilentlyContinue
    foreach ($stub in $stubs) {
        Remove-Item -LiteralPath $stub.FullName -Force
    }

    if (-not $Silent) {
        if ($stubs.Count -gt 0) {
            Write-Host "[OK] Removed $($stubs.Count) Python stub executable(s) from WindowsApps." -ForegroundColor Green
        } else {
            Write-Host '[OK] No Python stub executables found.' -ForegroundColor Green
        }
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to remove Python stubs: $_" -ForegroundColor Red
    if (-not $Silent) { Read-Host 'Press Enter to exit' }
    exit 1
}
