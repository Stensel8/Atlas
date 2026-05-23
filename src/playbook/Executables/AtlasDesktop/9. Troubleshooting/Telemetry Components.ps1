#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @()
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

$internalScript = Join-Path $env:windir 'AtlasModules\Scripts\Helpers\TelemetryComponents.ps1'
if (-not (Test-Path -LiteralPath $internalScript -PathType Leaf)) {
    throw "Atlas internal script '$internalScript' is missing."
}
& $internalScript
