#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

if (-not $Silent) {
    Write-Output 'This will repair and replace any corrupt Windows components and system files.'
    Write-Output 'For general issues, this might be a fix. Note that no components of Atlas is reverted with this.'
    Write-Output ''
    $null = Read-Host 'Press Enter to continue'
}

Write-Output 'This might take a while.'

Write-Output ''
Write-Output '---------------------------------------------'
Write-Output 'Restoring the component store...'
Write-Output '---------------------------------------------'
& dism.exe /online /cleanup-image /restorehealth

Write-Output ''
Write-Output '---------------------------------------------'
Write-Output 'Restoring system files...'
Write-Output '---------------------------------------------'
& sfc.exe /scannow

if ($Silent) { return }
Write-Output ''
Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
