#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'CpuIdleContextMenu' -State 0 -ScriptPath $PSCommandPath

$null = New-PSDrive -Name 'HKCR' -PSProvider Registry -Root 'HKEY_CLASSES_ROOT' -ErrorAction SilentlyContinue
Remove-Item -LiteralPath 'HKCR:\DesktopBackground\Shell\CpuIdle' -Recurse -Force -ErrorAction SilentlyContinue

if ($Silent) { return }
Write-Output ''
Write-Output 'CPU Idle desktop context menu has been removed.'
$null = Read-Host 'Press Enter to exit'
