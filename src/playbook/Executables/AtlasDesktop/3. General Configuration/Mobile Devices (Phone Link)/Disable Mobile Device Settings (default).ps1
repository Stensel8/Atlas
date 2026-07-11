#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force
Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Services\Atlas.Services.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'PhoneLink' -State 0 -ScriptPath $PSCommandPath

$polSys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
if (-not (Test-Path -LiteralPath $polSys)) { New-Item -Path $polSys -Force | Out-Null }
New-ItemProperty -LiteralPath $polSys -Name 'NoConnectedUser' -Value 1 -PropertyType DWord -Force | Out-Null

$cdp = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP'
if (-not (Test-Path -LiteralPath $cdp)) { New-Item -Path $cdp -Force | Out-Null }
New-ItemProperty -LiteralPath $cdp -Name 'NearShareChannelUserAuthzPolicy' -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $cdp -Name 'CdpSessionUserAuthzPolicy'       -Value 1 -PropertyType DWord -Force | Out-Null

$cdpSettings = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP\SettingsPage'
if (-not (Test-Path -LiteralPath $cdpSettings)) { New-Item -Path $cdpSettings -Force | Out-Null }
New-ItemProperty -LiteralPath $cdpSettings -Name 'BluetoothLastDisabledNearShare' -Value 0 -PropertyType DWord -Force | Out-Null

$cdr = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration'
if (-not (Test-Path -LiteralPath $cdr)) { New-Item -Path $cdr -Force | Out-Null }
New-ItemProperty -LiteralPath $cdr -Name 'IsResumeAllowed' -Value 0 -PropertyType DWord -Force | Out-Null

$pmgr = 'HKCU:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume'
if (-not (Test-Path -LiteralPath $pmgr)) { New-Item -Path $pmgr -Force | Out-Null }
New-ItemProperty -LiteralPath $pmgr -Name 'Value' -Value 1 -PropertyType DWord -Force | Out-Null

Invoke-AtlasSettingsPage -Operation hide -Page 'mobile-devices'
Set-AtlasServiceStartup -Name 'CDPSvc' -Start 4

Stop-Process -Name 'RuntimeBroker'      -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'PhoneExperienceHost' -Force -ErrorAction SilentlyContinue
Get-AppxPackage -AllUsers 'Microsoft.YourPhone*' | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
Get-AppxProvisionedPackage -Online |
    Where-Object { $_.DisplayName -eq 'Microsoft.YourPhone' } |
    Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

if ($Silent) { return }

$choice = $Host.UI.PromptForChoice('', 'Attempt Phone Link removal again?', @('&Yes', '&No'), 1)
if ($choice -eq 0) {
    Get-AppxPackage -AllUsers 'Microsoft.YourPhone*' | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
}

$storeKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate'
if (-not (Test-Path -LiteralPath $storeKey)) { New-Item -Path $storeKey -Force | Out-Null }
$autoChoice = $Host.UI.PromptForChoice('', 'Disable Store auto-updates?', @('&Yes', '&No'), 1)
$autoValue = if ($autoChoice -eq 0) { 2 } else { 4 }
New-ItemProperty -LiteralPath $storeKey -Name 'AutoDownload' -Value $autoValue -PropertyType DWord -Force | Out-Null

Write-Output ''
Write-Output 'Phone Link has been disabled.'
$null = Read-Host 'Press Enter to exit'
