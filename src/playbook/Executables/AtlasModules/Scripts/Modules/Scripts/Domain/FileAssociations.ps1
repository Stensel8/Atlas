#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
# System script domain functions: FileAssociations

function Set-FileAssociations {
    param (
        [string]$Browser
    )

    $fileAssoc = Join-Path $env:windir 'AtlasModules\Scripts\Set-BrowserFileAssociations.ps1'

    if ($Browser -in @("Brave", "LibreWolf", "Firefox", "Google Chrome")) {
        & $fileAssoc -Browser $Browser
    } else {
        & $fileAssoc
    }
}
