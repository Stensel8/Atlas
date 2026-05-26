#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'AutomaticUpdates' -State 1 -ScriptPath $PSCommandPath

Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' `
    -Name 'AUOptions' -ErrorAction SilentlyContinue

# Remove balanced-mode deferral keys
$uxKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
foreach ($val in @('BranchReadinessLevel', 'DeferFeatureUpdatesPeriodInDays', 'DeferQualityUpdatesPeriodInDays')) {
    Remove-ItemProperty -LiteralPath $uxKey -Name $val -ErrorAction SilentlyContinue
}

if ($Silent) { return }
Write-Host ''
Write-Host '[OK] Automatic Updates have been enabled.' -ForegroundColor Green
$null = Read-Host 'Press Enter to exit'
