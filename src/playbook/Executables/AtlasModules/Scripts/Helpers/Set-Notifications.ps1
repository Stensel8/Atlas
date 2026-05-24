#Requires -Version 5.1
# Toggles Windows notifications: disables/enables Action Center, WPN services, and settings pages.
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet('Disable', 'Enable')]
    [string]$Mode
)

$ErrorActionPreference = 'Stop'

# helper: create key if missing then write value
function Write-AtlasRegistryValue {
    param (
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)]$Value,
        [Parameter(Mandatory = $true)][Microsoft.Win32.RegistryValueKind]$Type
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

# helper: silently remove a value if it exists
function Invoke-AtlasRegistryValueRemoval {
    param (
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name
    )

    Remove-ItemProperty -LiteralPath $Path -Name $Name -Force -ErrorAction SilentlyContinue
}

# helper: set service start type, uses Set-ServiceStartupType.ps1 if available
function Invoke-AtlasServiceStartChange {
    param (
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][int]$Start
    )

    $script = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Helpers\Set-ServiceStartupType.ps1'
    if (Test-Path -LiteralPath $script -PathType Leaf) {
        & $script -Name $Name -Start $Start
        return
    }

    $serviceKey = Join-Path -Path 'HKLM:\SYSTEM\CurrentControlSet\Services' -ChildPath $Name
    if (Test-Path -LiteralPath $serviceKey) {
        Set-ItemProperty -LiteralPath $serviceKey -Name 'Start' -Value $Start -Type DWord
    }
}

# helper: hide/unhide pages in the Settings app
function Invoke-AtlasSettingsPageVisibilityChange {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('hide', 'unhide')]
        [string]$Operation,
        [Parameter(Mandatory = $true)]
        [string[]]$Pages
    )

    $script = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Helpers\Set-SettingsPageVisibility.ps1'
    if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
        return
    }

    foreach ($page in $Pages) {
        & $script -Operation $Operation -Page $page -Silent
    }
}

# WpnUserService has per-session instances with a suffix (_xxxxx), clean those up too
if ($Mode -eq 'Disable') {
    Write-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener' -Name 'Value' -Value 'Deny' -Type String
    Write-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings' -Name 'NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND' -Value 0 -Type DWord
    Write-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications' -Name 'ToastEnabled' -Value 0 -Type DWord
    Write-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications' -Name 'NoCloudApplicationNotification' -Value 1 -Type DWord
    Write-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableNotificationCenter' -Value 1 -Type DWord

    Invoke-AtlasSettingsPageVisibilityChange -Operation 'hide' -Pages @('notifications', 'privacy-notifications')

    & sc.exe config WpnService start=disabled | Out-Null
    & sc.exe stop WpnService 2>$null | Out-Null
    Invoke-AtlasServiceStartChange -Name 'WpnUserService' -Start 4

    Get-ChildItem -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services' -ErrorAction SilentlyContinue |
        Where-Object { $_.PSChildName -like 'WpnUserService_*' } |
        ForEach-Object {
            Invoke-AtlasServiceStartChange -Name $_.PSChildName -Start 4
            & sc.exe stop $_.PSChildName 2>$null | Out-Null
            & sc.exe delete $_.PSChildName 2>$null | Out-Null
        }

    Write-Output 'Disabled notifications.'
    exit 0
}

Invoke-AtlasRegistryValueRemoval -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableNotificationCenter'
Write-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener' -Name 'Value' -Value 'Allow' -Type String
Write-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings' -Name 'NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND' -Value 1 -Type DWord
Write-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications' -Name 'ToastEnabled' -Value 1 -Type DWord
Invoke-AtlasRegistryValueRemoval -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications' -Name 'NoCloudApplicationNotification'

Invoke-AtlasSettingsPageVisibilityChange -Operation 'unhide' -Pages @('notifications', 'privacy-notifications')
Invoke-AtlasServiceStartChange -Name 'WpnUserService' -Start 2
& sc.exe config WpnService start=auto | Out-Null

Write-Output 'Enabled notifications.'
