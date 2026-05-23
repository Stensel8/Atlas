#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'TakeOwnership' -State 0 -ScriptPath $PSCommandPath

& reg.exe import (Join-Path $env:windir 'AtlasModules\Scripts\Registry\TakeOwnership\remove.reg') 2>&1 | Out-Null

if ($Silent) { return }
Write-Output ''
Write-Output 'Take Ownership has been removed from the context menu.'
$null = Read-Host 'Press Enter to exit'
