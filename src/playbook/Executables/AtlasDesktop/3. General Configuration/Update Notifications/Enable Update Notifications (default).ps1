#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'UpdateNotifications' -State 1 -ScriptPath $PSCommandPath

$wuKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
Remove-ItemProperty -LiteralPath $wuKey -Name 'SetAutoRestartNotificationDisable' -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath $wuKey -Name 'SetUpdateNotificationLevel'        -ErrorAction SilentlyContinue

Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'RestartNotificationsAllowed2' -ErrorAction SilentlyContinue

if ($Silent) { return }
Write-Output ''
Write-Output 'Update Notifications have been enabled.'
$null = Read-Host 'Press Enter to exit'
