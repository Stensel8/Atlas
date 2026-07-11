#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'SecurityHealthTray' -State 1 -ScriptPath $PSCommandPath

$regFile = Join-Path $env:windir 'AtlasModules\Scripts\Registry\SecurityHealthTray\enable.reg'
& reg.exe import $regFile | Out-Null

if ($Silent) { return }
Write-Output 'Changes applied successfully.'
$null = Read-Host 'Press Enter to exit'
