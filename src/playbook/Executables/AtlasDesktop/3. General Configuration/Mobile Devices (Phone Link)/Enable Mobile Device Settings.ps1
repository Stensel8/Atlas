#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'PhoneLink' -State 1 -ScriptPath $PSCommandPath

Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' `
    -Name 'NoConnectedUser' -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' `
    -Name 'DisableWindowsConsumerFeatures' -ErrorAction SilentlyContinue

$cdr = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration'
if (-not (Test-Path -LiteralPath $cdr)) { New-Item -Path $cdr -Force | Out-Null }
New-ItemProperty -LiteralPath $cdr -Name 'IsResumeAllowed' -Value 1 -PropertyType DWord -Force | Out-Null

$pmgr = 'HKCU:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume'
if (-not (Test-Path -LiteralPath $pmgr)) { New-Item -Path $pmgr -Force | Out-Null }
New-ItemProperty -LiteralPath $pmgr -Name 'Value' -Value 0 -PropertyType DWord -Force | Out-Null

Set-AtlasServiceStartup -Name 'CDPSvc' -Start 3
Invoke-AtlasSettingsPage -Operation unhide -Page 'mobile-devices'

$storeKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate'
if (-not (Test-Path -LiteralPath $storeKey)) { New-Item -Path $storeKey -Force | Out-Null }
New-ItemProperty -LiteralPath $storeKey -Name 'AutoDownload' -Value 4 -PropertyType DWord -Force | Out-Null

if (-not $Silent) { Start-Process 'ms-settings:mobile-devices' }

if ($Silent) { return }
Write-Output ''
Write-Output 'Phone Link has been enabled. You can now sync your phone.'
$null = Read-Host 'Press Enter to exit'
