#Requires -Version 5.1

# Atlas.Core - core framework module: privilege checks, settings state, device helpers and shared UI.
Set-StrictMode -Version 3.0

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Ui.ps1'
    'Privilege.ps1'
    'Settings.ps1'
    'Devices.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Core domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    # Privilege
    'Assert-AtlasAdminPrivilege'
    # Settings
    'Set-AtlasSettingState'
    'Invoke-AtlasSettingsPage'
    # Devices
    'Enable-AtlasDevice'
    'Disable-AtlasDevice'
    # UI
    'Write-Title'
    'Read-Pause'
    'Read-MessageBox'
)
