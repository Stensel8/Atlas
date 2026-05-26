#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'Location' -State 1 -ScriptPath $PSCommandPath

try {
    Write-Host '[>>] Enabling location services...' -ForegroundColor Yellow
    # lfsvc = Manual (demand), MapsBroker = Automatic
    Set-Service  -Name 'lfsvc'      -StartupType Manual    -ErrorAction SilentlyContinue
    Set-Service  -Name 'MapsBroker' -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name 'lfsvc'      -ErrorAction SilentlyContinue
    Start-Service -Name 'MapsBroker' -ErrorAction SilentlyContinue

    Invoke-AtlasSettingsPage -Operation unhide -Page 'privacy-location'

    $enableFMD = $false
    if (-not $Silent) {
        $choice = Read-Host 'Would you like to enable Find My Device? [Y/N]'
        $enableFMD = $choice -match '^[Yy]'
    }

    if ($enableFMD) {
        Write-Host '[>>] Enabling Find My Device...' -ForegroundColor Yellow
        Remove-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice' -Recurse -Force -ErrorAction SilentlyContinue
        Invoke-AtlasSettingsPage -Operation unhide -Page 'findmydevice'
    } else {
        $fmdKey = 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice'
        if (-not (Test-Path -LiteralPath $fmdKey)) { New-Item -Path $fmdKey -Force | Out-Null }
        Set-ItemProperty -Path $fmdKey -Name AllowFindMyDevice   -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $fmdKey -Name LocationSyncEnabled -Value 0 -Type DWord -Force
    }

    if (-not $Silent) {
        Write-Host '[OK] Location services enabled.' -ForegroundColor Green
        Start-Process 'ms-settings:privacy-location'
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to enable location services: $_" -ForegroundColor Red
    exit 1
}
