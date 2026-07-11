#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

$internalScript = Join-Path $env:windir 'AtlasModules\Scripts\Helpers\Set-DefenderState.ps1'
if (-not (Test-Path -LiteralPath $internalScript -PathType Leaf)) {
    throw "Atlas internal script '$internalScript' is missing."
}

$passArgs = @()
if ($Silent) { $passArgs += '-Silent' }
& $internalScript @passArgs
