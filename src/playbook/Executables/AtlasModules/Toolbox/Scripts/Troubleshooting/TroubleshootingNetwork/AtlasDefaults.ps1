#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$target = Join-Path $env:windir 'AtlasDesktop\9. Troubleshooting\Network\Reset Network to Atlas Default.ps1'
if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Atlas script '$target' is missing." }
& $target
