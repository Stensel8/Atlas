#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'ShortcutText' -State 0 -ScriptPath $PSCommandPath

$namingKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates'
if (-not (Test-Path -LiteralPath $namingKey)) { New-Item -Path $namingKey -Force | Out-Null }
New-ItemProperty -LiteralPath $namingKey -Name 'ShortcutNameTemplate' -Value '"%s.lnk"' -PropertyType String -Force | Out-Null

if ($Silent) { return }
Write-Output ''
Write-Output 'Shortcut text has been disabled.'
$null = Read-Host 'Press Enter to exit'
