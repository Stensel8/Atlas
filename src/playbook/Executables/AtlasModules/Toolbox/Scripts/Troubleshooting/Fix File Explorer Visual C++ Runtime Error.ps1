#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$target = Join-Path $env:windir 'AtlasDesktop\9. Troubleshooting\Fix File Explorer Visual C++ Runtime Error.ps1'
if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Atlas script '$target' is missing." }
& $target
