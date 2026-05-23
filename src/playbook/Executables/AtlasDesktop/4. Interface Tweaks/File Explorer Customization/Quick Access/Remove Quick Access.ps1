#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'QuickAccess' -State 0 -ScriptPath $PSCommandPath

$explorerKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
if (-not (Test-Path -LiteralPath $explorerKey)) { New-Item -Path $explorerKey -Force | Out-Null }
New-ItemProperty -LiteralPath $explorerKey -Name 'HubMode' -Value 1 -PropertyType DWord -Force | Out-Null

if ($Silent) { return }
Write-Output ''
Write-Output 'Quick Access has been removed from File Explorer.'
$null = Read-Host 'Press Enter to exit'
