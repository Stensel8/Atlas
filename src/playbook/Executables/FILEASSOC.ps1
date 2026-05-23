#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$script = Join-Path $PSScriptRoot 'AtlasModules\Scripts\fileAssoc.ps1'
if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
    throw "Script not found: '$script'"
}
& $script @args
exit $LASTEXITCODE
