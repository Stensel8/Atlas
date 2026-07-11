#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'DefaultAtlasNetwork' -State 1 -ScriptPath $PSCommandPath

try {
    Write-Host '[>>] Locating network adapter driver key...' -ForegroundColor Yellow
    $netKey = $null
    $pnpIds = (Get-CimInstance -Class Win32_NetworkAdapter -ErrorAction SilentlyContinue).PNPDeviceID |
        Where-Object { $_ -match 'PCI\\VEN_' }

    foreach ($pnpId in $pnpIds) {
        $driver = (Get-ItemProperty -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Enum\$pnpId" -Name 'Driver' -ErrorAction SilentlyContinue).Driver
        if ($driver) {
            $netKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\$driver"
            break
        }
    }

    if ($netKey -and (Test-Path -LiteralPath $netKey)) {
        Write-Host '[>>] Applying Atlas network adapter settings...' -ForegroundColor Yellow
        # rem --------------------------
        # rem Unknown benefit
        # rem --------------------------
        # rem "LargeSendOffload", "LargeSendOffloadJumboCombo", "LsoV1IPv4", "LsoV2IPv4", "LsoV2IPv6",
        # rem "LogLevelWarn", "AlternateSemaphoreDelay", "DeviceSleepOnDisconnect", "EnableModernStandby",
        # rem "PriorityVLANTag", "Node", "MPC", "PowerDownPll", "PMWiFiRekeyOffload",
        # rem "ARPOffloadEnable", "bAdvancedLPs", "NSOffloadEnable", "GTKOffloadEnable",
        # rem "Enable9KJFTpt", "EnableEDT", "GPPSW", "MasterSlave", "PacketCoalescing"
        # rem Could cause dropped network frames: "FlowControl", "FlowControlCap"

        foreach ($setting in @(
            'AutoDisableGigabit'   # Don't disable gigabit
            'ApCompatMode'         # Access Point Compatibility Mode, 0 = High Performance
            'SipsEnabled'          # About reducing link speed
            'ReduceSpeedOnPowerDown'
            'DMACoalescing'        # 'may increase latency'
        )) {
            foreach ($name in @($setting, "*$setting")) {
                $existing = Get-ItemProperty -LiteralPath $netKey -Name $name -ErrorAction SilentlyContinue
                if ($null -ne $existing) {
                    Set-ItemProperty -LiteralPath $netKey -Name $name -Value '0' -Type String -ErrorAction SilentlyContinue
                }
            }
        }
    }

    if (-not $Silent) {
        Write-Host '[OK] Network settings set to Atlas defaults.' -ForegroundColor Green
        Write-Host ''
        Write-Host 'Please reboot your device for changes to apply.' -ForegroundColor White
        $null = Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to apply Atlas network defaults: $_" -ForegroundColor Red
    exit 1
}
