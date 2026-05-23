#Requires -Version 5.1

# Public AtlasOS utilities module.
Set-StrictMode -Version 3.0

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Admin.ps1'
    'Settings.ps1'
    'Services.ps1'
    'Devices.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required AtlasOS domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function `
    Assert-AtlasAdminPrivilege, `
    Set-AtlasSettingState, `
    Invoke-AtlasSettingsPage, `
    Set-AtlasServiceStartup, `
    Show-AtlasServiceWarning, `
    Enable-AtlasDevice, `
    Disable-AtlasDevice
