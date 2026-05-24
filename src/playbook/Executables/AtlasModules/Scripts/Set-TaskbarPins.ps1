#Requires -Version 5.1
param (
    [string]$Browser
)
$ErrorActionPreference = 'Stop'

$internalScript = Join-Path -Path $PSScriptRoot -ChildPath 'Helpers\Set-TaskbarPins.ps1'
if (-not (Test-Path -LiteralPath $internalScript -PathType Leaf)) {
    Write-Error "Taskbar pin script '$internalScript' is missing."
    exit 1
}

& $internalScript @PSBoundParameters
if (-not $?) {
    exit 1
}

if ($null -ne $LASTEXITCODE) {
    exit $LASTEXITCODE
}

exit 0
