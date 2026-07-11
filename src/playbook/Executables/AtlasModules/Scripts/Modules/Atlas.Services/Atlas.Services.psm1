#Requires -Version 5.1

# Atlas.Services - service and driver configuration module.
Set-StrictMode -Version 3.0

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Startup.ps1'
    'Backup.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Services domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Set-AtlasServiceStartup'
    'Show-AtlasServiceWarning'
    'Enable-NetworkDiscoveryServices'
    'Export-AtlasServicesBackup'
)
