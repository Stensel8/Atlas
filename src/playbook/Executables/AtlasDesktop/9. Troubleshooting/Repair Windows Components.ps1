#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

if (-not $Silent) {
    Write-Host 'This will repair and replace any corrupt Windows components and system files.' -ForegroundColor White
    Write-Host 'For general issues, this might be a fix. Note that no Atlas components are reverted.' -ForegroundColor White
    Write-Host ''
    $null = Read-Host 'Press Enter to continue'
}

try {
    Write-Host ''
    Write-Host '[>>] Restoring the component store (DISM)...' -ForegroundColor Yellow
    & dism.exe /online /cleanup-image /restorehealth

    Write-Host ''
    Write-Host '[>>] Restoring system files (SFC)...' -ForegroundColor Yellow
    & sfc.exe /scannow

    if (-not $Silent) {
        Write-Host ''
        Write-Host '[OK] Repair complete. Please reboot your device for changes to apply.' -ForegroundColor Green
        $null = Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Repair failed: $_" -ForegroundColor Red
    exit 1
}
