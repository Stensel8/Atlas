#Requires -Version 5.1

# Public system-script orchestration module.
Set-StrictMode -Version 3.0

# Atlas.Services and Atlas.Software supply the service backup and CBS update functions
# used by Invoke-AllSystemScripts. Import them explicitly so this module also works
# when PSModulePath has not been populated by initPowerShell.ps1 yet.
foreach ($requiredModule in @('Atlas.Services', 'Atlas.Software')) {
    if (-not (Get-Module -Name $requiredModule)) {
        Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "..\$requiredModule\$requiredModule.psd1")
    }
}

$script:AtlasWindowsDirectory = [Environment]::GetFolderPath('Windows')
$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Devices.ps1'
    'FileAssociations.ps1'
    'Orchestration.ps1'
    'Performance.ps1'
    'ProfilePictures.ps1'
    'Security.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required system-script domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Invoke-AllSystemScripts'
)
