#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'ShortcutIcon' -State 1 -ScriptPath $PSCommandPath

$shellIcons = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons'
if (-not (Test-Path -LiteralPath $shellIcons)) { New-Item -Path $shellIcons -Force | Out-Null }
New-ItemProperty -LiteralPath $shellIcons -Name '29' `
    -Value 'C:\Windows\AtlasModules\Other\Classic.ico,0' -PropertyType String -Force | Out-Null

if ($Silent) { return }
Write-Output ''
Write-Output 'Shortcut icon has been set to the classic style.'
$null = Read-Host 'Press Enter to exit'
