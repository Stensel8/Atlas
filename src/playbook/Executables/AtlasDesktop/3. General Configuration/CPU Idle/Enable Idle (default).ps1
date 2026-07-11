#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'CpuIdle' -State 1 -ScriptPath $PSCommandPath

& powercfg.exe /setacvalueindex scheme_current sub_processor '5d76a2ca-e8c0-402f-a133-2158492d58ad' 0
& powercfg.exe /setactive scheme_current

if ($Silent) { return }
Write-Output ''
Write-Output 'CPU idle has been enabled.'
$null = Read-Host 'Press Enter to exit'
