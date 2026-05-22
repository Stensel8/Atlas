#Requires -Version 5.1
param([switch]$Silent, [switch]$JustContext)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'AppStoreArchiving' -State 0 -ScriptPath $PSCommandPath

$key = 'HKLM:\Software\Policies\Microsoft\Windows\Appx'
if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
Set-ItemProperty -LiteralPath $key -Name 'AllowAutomaticAppArchiving' -Value 0 -Type DWord

if ($JustContext -or $Silent) { return }

Write-Output ''
Write-Output 'App Store Archiving has been disabled.'
$null = Read-Host 'Press Enter to exit'
