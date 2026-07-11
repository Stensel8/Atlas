#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'DefaultAtlasNetwork' -State 0 -ScriptPath $PSCommandPath

try {
    Write-Host '[>>] Resetting TCP/IP stack and Winsock...' -ForegroundColor Yellow
    & netsh.exe int ip reset         | Out-Null
    & netsh.exe interface ipv4 reset | Out-Null
    & netsh.exe interface ipv6 reset | Out-Null
    & netsh.exe interface tcp reset  | Out-Null
    & netsh.exe winsock reset        | Out-Null

    Write-Host '[>>] Re-scanning network devices...' -ForegroundColor Yellow
    Get-PnpDevice -Class Net -Status OK -ErrorAction SilentlyContinue |
        ForEach-Object { & pnputil.exe /remove-device $_.InstanceId | Out-Null }
    & pnputil.exe /scan-devices | Out-Null

    if (-not $Silent) {
        Write-Host '[OK] Network reset to Windows defaults.' -ForegroundColor Green
        Write-Host ''
        Write-Host 'Please reboot your device for changes to apply.' -ForegroundColor White
        $null = Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to reset network: $_" -ForegroundColor Red
    exit 1
}
