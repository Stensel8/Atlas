#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'UpdateNotifications' -State 0 -ScriptPath $PSCommandPath

$wuKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
if (-not (Test-Path -LiteralPath $wuKey)) { New-Item -Path $wuKey -Force | Out-Null }
New-ItemProperty -LiteralPath $wuKey -Name 'SetAutoRestartNotificationDisable' -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $wuKey -Name 'SetUpdateNotificationLevel'        -Value 2 -PropertyType DWord -Force | Out-Null

$uxKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
if (-not (Test-Path -LiteralPath $uxKey)) { New-Item -Path $uxKey -Force | Out-Null }
New-ItemProperty -LiteralPath $uxKey -Name 'RestartNotificationsAllowed2' -Value 0 -PropertyType DWord -Force | Out-Null

if ($Silent) { return }
Write-Output ''
Write-Output 'Update Notifications have been disabled.'
$null = Read-Host 'Press Enter to exit'
