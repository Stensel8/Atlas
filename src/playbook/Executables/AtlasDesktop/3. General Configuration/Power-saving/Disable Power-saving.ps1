#Requires -Version 5.1
param([switch]$Silent, [switch]$JustContext)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'PowerSaving' -State 0 -ScriptPath $PSCommandPath

$internalScript = Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Helpers\DisablePowerSaving.ps1'
if (-not (Test-Path -LiteralPath $internalScript -PathType Leaf)) {
    throw "Atlas internal script '$internalScript' is missing."
}

$passArgs = @()
if ($Silent)      { $passArgs += '-Silent' }
if ($JustContext) { $passArgs += '-JustContext' }
& $internalScript @passArgs

if ($JustContext -or $Silent) { return }

Write-Output ''
Write-Output 'Power Saving has been disabled.'
$null = Read-Host 'Press Enter to exit'
