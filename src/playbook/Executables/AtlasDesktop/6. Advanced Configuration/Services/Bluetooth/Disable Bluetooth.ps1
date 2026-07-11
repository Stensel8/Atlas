#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force
Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Services\Atlas.Services.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'Bluetooth' -State 0 -ScriptPath $PSCommandPath

Show-AtlasServiceWarning -Silent:$Silent

Write-Output 'Disabling Bluetooth... This might take a minute.'

foreach ($svc in @(
    'BluetoothUserService', 'BTAGService', 'BthA2dp', 'BthAvctpSvc', 'BthEnum',
    'BthHFEnum', 'BthLEEnum', 'BthMini', 'BTHMODEM', 'BTHPORT', 'bthserv',
    'BTHUSB', 'HidBth', 'Microsoft_Bluetooth_AvrcpTransport', 'RFCOMM'
)) {
    Set-AtlasServiceStartup -Name $svc -Start 4
}
Set-AtlasServiceStartup -Name 'BthPan' -Start 4 -ErrorAction SilentlyContinue

Disable-AtlasDevice -Pattern '*Bluetooth*' -Silent

$sendToScript = Join-Path $env:windir 'AtlasDesktop\4. Interface Tweaks\Context Menus\Send To\Debloat Send To Context Menu.ps1'
if (Test-Path -LiteralPath $sendToScript) {
    & $sendToScript -Disable @('Bluetooth')
}

$policyKey = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\AllowBluetooth'
if (-not (Test-Path -LiteralPath $policyKey)) { New-Item -Path $policyKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $policyKey -Name 'value' -Value 0 -Type DWord

if ($Silent) { return }
Write-Output ''
Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
