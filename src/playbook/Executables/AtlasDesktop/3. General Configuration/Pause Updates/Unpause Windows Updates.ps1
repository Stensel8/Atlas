#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'PauseUpdates' -State 0 -ScriptPath $PSCommandPath

$stateKey = 'HKLM:\SOFTWARE\AtlasOS\Services\PauseUpdates'
if (-not (Test-Path -LiteralPath $stateKey)) { New-Item -Path $stateKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $stateKey -Name 'days' -Value 0 -Type DWord

Write-Output 'Resetting Windows Update pause policies...'

$wuKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
foreach ($name in @('DeferFeatureUpdates','DeferFeatureUpdatesPeriodInDays','DeferQualityUpdates',
    'DeferQualityUpdatesPeriodInDays','PauseFeatureUpdates','PauseFeatureUpdatesStartTime',
    'PauseQualityUpdates','PauseQualityUpdatesStartTime')) {
    Remove-ItemProperty -LiteralPath $wuKey -Name $name -ErrorAction SilentlyContinue
}

$policyKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings'
if (-not (Test-Path -LiteralPath $policyKey)) { New-Item -Path $policyKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $policyKey -Name 'PausedFeatureStatus' -Value 0 -Type DWord
Set-ItemProperty -LiteralPath $policyKey -Name 'PausedQualityStatus' -Value 0 -Type DWord

$uxKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
foreach ($name in @('PauseFeatureUpdatesStartTime','PauseFeatureUpdatesEndTime',
    'PauseQualityUpdatesStartTime','PauseQualityUpdatesEndTime','PauseUpdatesStartTime',
    'PauseUpdatesExpiryTime','PausedFeatureStatus','PausedQualityStatus',
    'FlightSettingsMaxPauseDays','HideMCTLink','RestartNotificationsAllowed2')) {
    Remove-ItemProperty -LiteralPath $uxKey -Name $name -ErrorAction SilentlyContinue
}

Remove-ItemProperty -LiteralPath 'HKLM:\SYSTEM\Setup\UpgradeNotification' `
    -Name 'UpgradeAvailable' -ErrorAction SilentlyContinue

if ($Silent) { return }
Write-Output ''
Write-Output 'Windows Updates have been unpaused.'
$null = Read-Host 'Press Enter to exit'
