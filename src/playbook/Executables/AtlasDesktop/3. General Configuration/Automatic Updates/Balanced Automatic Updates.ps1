#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'AutomaticUpdates' -State 2 -ScriptPath $PSCommandPath

# Allow auto-updates but remove full-disable flag
Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' `
    -Name 'AUOptions' -ErrorAction SilentlyContinue

# Semi-Annual Channel, defer feature 365 days, defer quality 4 days
$uxKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
if (-not (Test-Path -LiteralPath $uxKey)) { New-Item -Path $uxKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $uxKey -Name 'BranchReadinessLevel'           -Value 20  -Type DWord
Set-ItemProperty -LiteralPath $uxKey -Name 'DeferFeatureUpdatesPeriodInDays' -Value 365 -Type DWord
Set-ItemProperty -LiteralPath $uxKey -Name 'DeferQualityUpdatesPeriodInDays' -Value 4   -Type DWord

if ($Silent) { return }

Write-Host ''
Write-Host '[OK] Balanced Automatic Updates enabled.' -ForegroundColor Green
Write-Host '     Feature updates deferred 365 days' -ForegroundColor DarkGray
Write-Host '     Quality/security updates deferred 4 days' -ForegroundColor DarkGray
$null = Read-Host 'Press Enter to exit'
