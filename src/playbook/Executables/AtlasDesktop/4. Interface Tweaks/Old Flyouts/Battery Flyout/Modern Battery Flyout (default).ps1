#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'ModernBatteryFlyout' -State 1 -ScriptPath $PSCommandPath

$imShell = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell'
if (-not (Test-Path -LiteralPath $imShell)) { New-Item -Path $imShell -Force | Out-Null }
New-ItemProperty -LiteralPath $imShell -Name 'UseWin32BatteryFlyout' -Value 0 -PropertyType DWord -Force | Out-Null

if ($Silent) { return }
Write-Output ''
Write-Output 'Battery flyout has been set to the modern style.'
$null = Read-Host 'Press Enter to exit'
