#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'RunWithPriority' -State 0 -ScriptPath $PSCommandPath

$null = New-PSDrive -Name 'HKCR' -PSProvider Registry -Root 'HKEY_CLASSES_ROOT' -ErrorAction SilentlyContinue
Remove-Item -LiteralPath 'HKCR:\exefile\shell\Priority' -Recurse -Force -ErrorAction SilentlyContinue

if ($Silent) { return }
Write-Output ''
Write-Output 'Run With Priority has been removed from the context menu.'
$null = Read-Host 'Press Enter to exit'
