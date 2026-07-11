#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
# Atlas.Core domain functions: Devices

function Enable-AtlasDevice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$Pattern,
        [switch]$Silent
    )

    $foundDevices = @(Get-PnpDevice -FriendlyName $Pattern -ErrorAction SilentlyContinue)
    foreach ($device in $foundDevices) {
        try {
            $device | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
        } catch {
            Write-Output "Something went wrong enabling device: $($device.FriendlyName)"
            Write-Output $_
        }
    }
    if (-not $Silent) {
        Write-Output 'Enabled the matched specified devices:'
        foreach ($device in $foundDevices.FriendlyName) { Write-Output " - $device" }
    }
}

function Disable-AtlasDevice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$Pattern,
        [switch]$Silent
    )

    $foundDevices = @(Get-PnpDevice -FriendlyName $Pattern -ErrorAction SilentlyContinue)
    foreach ($device in $foundDevices) {
        try {
            $device | Disable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
        } catch {
            Write-Output "Something went wrong disabling device: $($device.FriendlyName)"
            Write-Output $_
        }
    }
    if (-not $Silent) {
        Write-Output 'Disabled the matched specified devices:'
        foreach ($device in $foundDevices.FriendlyName) { Write-Output " - $device" }
    }
}
