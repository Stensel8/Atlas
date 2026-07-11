#Requires -Version 5.1

# Atlas.Registry - registry and user path helper module.
Set-StrictMode -Version 3.0

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'UserPaths.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Registry domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Get-RegUserPaths'
    'Get-UserPath'
    'Get-SystemDrive'
)
