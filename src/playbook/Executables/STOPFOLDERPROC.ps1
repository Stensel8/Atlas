#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$internalScript = Join-Path -Path $PSScriptRoot -ChildPath 'AtlasModules\Scripts\Helpers\StopFolderProc.ps1'
if (-not (Test-Path -LiteralPath $internalScript -PathType Leaf)) {
    Write-Error "Atlas internal process cleanup script '$internalScript' is missing."
    exit 1
}

& $internalScript @args
if (-not $?) {
    exit 1
}

if ($null -ne $LASTEXITCODE) {
    exit $LASTEXITCODE
}

exit 0
