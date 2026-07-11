#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'Location' -State 0 -ScriptPath $PSCommandPath

try {
    Write-Host '[>>] Disabling location services...' -ForegroundColor Yellow
    foreach ($svcName in @('lfsvc', 'MapsBroker')) {
        Set-Service  -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $svcName -Force               -ErrorAction SilentlyContinue
    }

    Write-Host '[>>] Applying Find My Device and consent store policies...' -ForegroundColor Yellow
    $fmdKey = 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice'
    if (-not (Test-Path -LiteralPath $fmdKey)) { New-Item -Path $fmdKey -Force | Out-Null }
    Set-ItemProperty -Path $fmdKey -Name AllowFindMyDevice   -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $fmdKey -Name LocationSyncEnabled -Value 0 -Type DWord -Force

    $consentKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'
    if (-not (Test-Path -LiteralPath $consentKey)) { New-Item -Path $consentKey -Force | Out-Null }
    Set-ItemProperty -Path $consentKey -Name ShowGlobalPrompts -Value 0 -Type DWord -Force

    Invoke-AtlasSettingsPage -Operation hide -Page 'privacy-location'
    Invoke-AtlasSettingsPage -Operation hide -Page 'findmydevice'

    if (-not $Silent) {
        Write-Host '[OK] Location services disabled.' -ForegroundColor Green
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to disable location services: $_" -ForegroundColor Red
    exit 1
}
