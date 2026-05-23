#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$target = Join-Path $env:windir 'AtlasDesktop\6. Advanced Configuration\Services\NVIDIA Display Container\Disable NVIDIA Display Container LS.ps1'
if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Atlas script '$target' is missing." }
& $target
