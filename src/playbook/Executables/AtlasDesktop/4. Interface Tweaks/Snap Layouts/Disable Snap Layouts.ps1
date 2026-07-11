#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'SnapLayouts' -State 0 -ScriptPath $PSCommandPath

$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
if (-not (Test-Path -LiteralPath $adv)) { New-Item -Path $adv -Force | Out-Null }
New-ItemProperty -LiteralPath $adv -Name 'EnableSnapAssistFlyout' -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $adv -Name 'EnableSnapBar'          -Value 0 -PropertyType DWord -Force | Out-Null

if ($Silent) { return }
Write-Output ''
Write-Output 'Snap layouts have been disabled.'
$null = Read-Host 'Press Enter to exit'
