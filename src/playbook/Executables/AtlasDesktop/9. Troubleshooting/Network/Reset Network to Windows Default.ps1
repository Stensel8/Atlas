#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'DefaultAtlasNetwork' -State 0 -ScriptPath $PSCommandPath

Write-Output 'Resetting network settings to Windows defaults...'

& netsh.exe int ip reset         | Out-Null
& netsh.exe interface ipv4 reset | Out-Null
& netsh.exe interface ipv6 reset | Out-Null
& netsh.exe interface tcp reset  | Out-Null
& netsh.exe winsock reset        | Out-Null

Get-PnpDevice -Class Net -Status OK -ErrorAction SilentlyContinue |
    ForEach-Object { & pnputil.exe /remove-device $_.InstanceId | Out-Null }
& pnputil.exe /scan-devices | Out-Null

if ($Silent) { return }
Write-Output ''
Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
