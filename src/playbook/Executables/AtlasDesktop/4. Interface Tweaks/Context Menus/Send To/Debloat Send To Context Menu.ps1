#Requires -Version 5.1
param(
    [string[]]$Disable,
    [string[]]$Enable
)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @()
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

$internalScript = Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Helpers\Set-SendToContextMenu.ps1'
if (-not (Test-Path -LiteralPath $internalScript -PathType Leaf)) {
    throw "Atlas internal script '$internalScript' is missing."
}

& $internalScript -Disable $Disable -Enable $Enable
