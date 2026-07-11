#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'AppStoreArchiving' -State 1 -ScriptPath $PSCommandPath

$key = 'HKLM:\Software\Policies\Microsoft\Windows\Appx'
if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
New-ItemProperty -LiteralPath $key -Name 'AllowAutomaticAppArchiving' -Value 1 -PropertyType DWord -Force | Out-Null

if ($Silent) { return }
Write-Output ''
Write-Output 'App Store Archiving has been enabled.'
$null = Read-Host 'Press Enter to exit'
