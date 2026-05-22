#Requires -Version 5.1
# AtlasOS domain functions: Devices

function Enable-AtlasDevice {
    param(
        [Parameter(Mandatory)][string[]]$FriendlyName,
        [switch]$Silent
    )

    $foundDevices = @(Get-PnpDevice -FriendlyName $FriendlyName -ErrorAction SilentlyContinue)
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
    param(
        [Parameter(Mandatory)][string[]]$FriendlyName,
        [switch]$Silent
    )

    $foundDevices = @(Get-PnpDevice -FriendlyName $FriendlyName -ErrorAction SilentlyContinue)
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
