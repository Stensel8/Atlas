#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

# -------------------------------------------------------------------
# Tweaks: each entry lists RegistryKeyword variants to try (first
# match wins) and DisplayValue candidates in preference order.
# DisplayValue matching is vendor-agnostic, avoids hardcoding
# integers that differ between Intel, MediaTek, Qualcomm, etc.
# -------------------------------------------------------------------
$tweaks = @(
    @{
        Name   = 'U-APSD Support — Disabled'
        Note   = 'WMM power save; disabling reduces latency'
        Keys   = @('*uAPSDSupport', 'uAPSDSupport')
        Values = @('Disabled', 'Disable', '0. Disabled', '0')
    }
    @{
        Name   = 'Roaming Aggressiveness — Medium-High'
        Note   = 'Faster AP handoff without constant re-scanning'
        Keys   = @('*RoamingPreference', 'RoamingAggressiveness', 'RoamAggr', 'RoamingPreference')
        Values = @('4. Medium-High', 'Medium-High', '4. High', 'High', '4')
    }
    @{
        Name   = 'Preferred Band — 5 GHz'
        Note   = 'Avoids congested 2.4 GHz band'
        Keys   = @('*PreferredBand', 'PreferredBand', 'PrefBand', 'Band', 'BandPreference')
        Values = @('5 GHz Preferred', '5 GHz', '5GHz', '5G', '2. 5 GHz', '2')
    }
    @{
        Name   = 'Power Saving — Disabled'
        Note   = 'Maximum adapter performance'
        Keys   = @('*PowerSavingMode', 'PowerSaveMode', 'PowerSavingMode', 'PowerMode')
        Values = @('Disabled', 'Maximum Performance', 'Off', '0. Disabled', '0')
    }
    @{
        Name   = 'Transmit Power — Highest'
        Note   = 'Best signal quality and range'
        Keys   = @('*TransmitPower', 'TransmitPowerLevel', 'TransmitPower')
        Values = @('Highest', '1. Highest', '5. Highest', 'Maximum', '100%', '5')
    }
    @{
        Name   = 'Throughput Booster — Enabled'
        Note   = 'Intel-specific; increases throughput via packet aggregation'
        Keys   = @('*ThroughputBoosterEnabled', 'ThroughputBooster')
        Values = @('Enabled', 'Enable', '1')
    }
    @{
        Name   = 'AMSDU Tx — Enabled'
        Note   = 'Frame aggregation; higher throughput'
        Keys   = @('*AMSDUTx', 'AMSDUTx', 'AMSDU_Tx', 'AMSDU-Tx')
        Values = @('Enabled', 'Enable', '1')
    }
    @{
        Name   = 'ARP Offload for WOWLAN — Disabled'
        Note   = 'Not needed without Wake-on-WLAN'
        Keys   = @('*ARPOffload', 'ARPOffloadEnable', 'ARPOffloadforWoWLAN')
        Values = @('Disabled', 'Disable', '0. Disabled', '0')
    }
    @{
        Name   = 'NS Offload for WOWLAN — Disabled'
        Note   = 'Not needed without Wake-on-WLAN'
        Keys   = @('*NSOffload', 'NSOffloadEnable', 'NSOffloadforWoWLAN')
        Values = @('Disabled', 'Disable', '0. Disabled', '0')
    }
    @{
        Name   = 'GTK Rekey for WOWLAN — Disabled'
        Note   = 'Not needed without Wake-on-WLAN'
        Keys   = @('*GTKOffload', 'GTKOffloadEnable', 'GTKRekeyforWoWLAN')
        Values = @('Disabled', 'Disable', '0. Disabled', '0')
    }
)

function Invoke-WifiAdapterTweak {
    param(
        [object]$AdapterProps,
        [hashtable]$Tweak,
        [switch]$Silent
    )

    $prop = $null
    foreach ($kw in $Tweak.Keys) {
        $prop = $AdapterProps | Where-Object { $_.RegistryKeyword -ieq $kw } | Select-Object -First 1
        if ($prop) { break }
    }
    if (-not $prop) { return 'skipped' }

    $targetValue = $null
    foreach ($candidate in $Tweak.Values) {
        if ($prop.ValidDisplayValues -and $prop.ValidDisplayValues -icontains $candidate) {
            $targetValue = $candidate
            break
        }
    }
    if (-not $targetValue) { return 'no-match' }

    try {
        $prop | Set-NetAdapterAdvancedProperty -DisplayValue $targetValue -ErrorAction Stop
        return $targetValue
    } catch {
        return "error: $($_.Exception.Message)"
    }
}

# Find Wi-Fi adapters
$wifiAdapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue |
    Where-Object {
        $_.MediaType -eq '802.11' -or
        $_.PhysicalMediaType -match '802\.11|NativeWifi|Native 802' -or
        $_.InterfaceDescription -match 'Wi-Fi|Wireless|WLAN|802\.11|WiFi'
    }

if (-not $wifiAdapters) {
    if (-not $Silent) {
        Write-Output 'No Wi-Fi adapters found, nothing to do.'
        $null = Read-Host 'Press Enter to exit'
    }
    exit 0
}

$totalApplied = 0
$totalSkipped = 0

foreach ($adapter in $wifiAdapters) {
    if (-not $Silent) { Write-Output "`nAdapter: $($adapter.InterfaceDescription)" }

    $adapterProps = $adapter | Get-NetAdapterAdvancedProperty -ErrorAction SilentlyContinue

    foreach ($tweak in $tweaks) {
        $result = Invoke-WifiAdapterTweak -AdapterProps $adapterProps -Tweak $tweak -Silent:$Silent
        switch -Wildcard ($result) {
            'skipped'   { $totalSkipped++; continue }
            'no-match'  { $totalSkipped++; continue }
            'error: *'  {
                if (-not $Silent) { Write-Output "  FAIL  $($tweak.Name) - $($result.Substring(7))" }
                $totalSkipped++
            }
            default     {
                if (-not $Silent) { Write-Output "  SET   $($tweak.Name) = $result" }
                $totalApplied++
            }
        }
    }
}

if (-not $Silent) {
    Write-Output "`nApplied $totalApplied settings, skipped $totalSkipped (not available on this adapter)."
    $null = Read-Host 'Press Enter to exit'
}
