#Requires -Version 5.1
param([switch]$Silent, [switch]$JustContext)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'Home' -State 1 -ScriptPath $PSCommandPath

$nsKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}'
if (-not (Test-Path -LiteralPath $nsKey)) { New-Item -Path $nsKey -Force | Out-Null }
$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
if (-not (Test-Path -LiteralPath $adv)) { New-Item -Path $adv -Force | Out-Null }
Set-ItemProperty -LiteralPath $adv -Name 'LaunchTo' -Value 0 -Type DWord

if ($JustContext -or $Silent) { return }

Write-Output 'Home has been enabled in File Explorer.'
$null = Read-Host 'Press Enter to exit'
