#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'Workplace' -State 0 -ScriptPath $PSCommandPath

Invoke-AtlasSettingsPage -Operation hide -Page 'workplace'

if ($Silent) { return }
Write-Output ''
Write-Output 'Workplace settings page has been hidden.'
$null = Read-Host 'Press Enter to exit'
