#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Show-AtlasServiceWarning -Silent:$Silent

Set-AtlasSettingState -SettingName 'PauseUpdates' -State 1 -ScriptPath $PSCommandPath

$stateKey = 'HKLM:\SOFTWARE\AtlasOS\Services\PauseUpdates'
if (-not (Test-Path -LiteralPath $stateKey)) { New-Item -Path $stateKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $stateKey -Name 'days' -Value 356000 -Type DWord

Write-Output 'Applying Windows Update pause policies...'

$policyKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings'
if (-not (Test-Path -LiteralPath $policyKey)) { New-Item -Path $policyKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $policyKey -Name 'PausedFeatureStatus' -Value 1 -Type DWord
Set-ItemProperty -LiteralPath $policyKey -Name 'PausedQualityStatus' -Value 1 -Type DWord

$uxKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
if (-not (Test-Path -LiteralPath $uxKey)) { New-Item -Path $uxKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $uxKey -Name 'FlightSettingsMaxPauseDays'      -Value 356000                -Type DWord
Set-ItemProperty -LiteralPath $uxKey -Name 'PauseFeatureUpdatesStartTime'    -Value '2001-10-25T10:03:37Z' -Type String
Set-ItemProperty -LiteralPath $uxKey -Name 'PauseQualityUpdatesStartTime'    -Value '2001-10-25T10:03:37Z' -Type String
Set-ItemProperty -LiteralPath $uxKey -Name 'PauseUpdatesStartTime'           -Value '2001-10-25T10:03:37Z' -Type String
Set-ItemProperty -LiteralPath $uxKey -Name 'PauseFeatureUpdatesEndTime'      -Value '3000-12-31T14:03:37Z' -Type String
Set-ItemProperty -LiteralPath $uxKey -Name 'PauseQualityUpdatesEndTime'      -Value '3000-12-31T14:03:37Z' -Type String
Set-ItemProperty -LiteralPath $uxKey -Name 'PauseUpdatesExpiryTime'          -Value '3000-12-31T14:03:37Z' -Type String
Set-ItemProperty -LiteralPath $uxKey -Name 'HideMCTLink'                     -Value 1                      -Type DWord
Set-ItemProperty -LiteralPath $uxKey -Name 'RestartNotificationsAllowed2'    -Value 0                      -Type DWord

$upgradeKey = 'HKLM:\SYSTEM\Setup\UpgradeNotification'
if (-not (Test-Path -LiteralPath $upgradeKey)) { New-Item -Path $upgradeKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $upgradeKey -Name 'UpgradeAvailable' -Value 0 -Type DWord

if ($Silent) { return }
Write-Output ''
Write-Output 'Windows Updates have been paused.'
$null = Read-Host 'Press Enter to exit'
