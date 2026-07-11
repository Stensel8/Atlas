#Requires -Version 5.1
param([switch]$Silent, [switch]$JustContext)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'PowerSaving' -State 1 -ScriptPath $PSCommandPath

$internalScript = Join-Path $env:windir 'AtlasModules\Scripts\Helpers\Restore-PowerSavingDefaults.ps1'
if (-not (Test-Path -LiteralPath $internalScript -PathType Leaf)) {
    throw "Atlas internal script '$internalScript' is missing."
}

$passArgs = @()
if ($Silent)      { $passArgs += '-Silent' }
if ($JustContext) { $passArgs += '-JustContext' }
& $internalScript @passArgs

if ($JustContext -or $Silent) { return }
Write-Output ''
Write-Output 'Default power saving has been restored.'
$null = Read-Host 'Press Enter to exit'
