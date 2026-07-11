#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'FSOGameBar' -State 1 -ScriptPath $PSCommandPath

$gcStore = 'HKCU:\System\GameConfigStore'
if (-not (Test-Path -LiteralPath $gcStore)) { New-Item -Path $gcStore -Force | Out-Null }
Remove-ItemProperty -LiteralPath $gcStore -Name 'GameDVR_DSEBehavior'  -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath $gcStore -Name 'GameDVR_FSEBehavior'  -ErrorAction SilentlyContinue
New-ItemProperty -LiteralPath $gcStore -Name 'GameDVR_DXGIHonorFSEWindowsCompatible' -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $gcStore -Name 'GameDVR_EFSEFeatureFlags'               -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $gcStore -Name 'GameDVR_FSEBehaviorMode'                -Value 2 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $gcStore -Name 'GameDVR_HonorUserFSEBehaviorMode'       -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $gcStore -Name 'GameDVR_Enabled'                        -Value 1 -PropertyType DWord -Force | Out-Null

Remove-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' `
    -Name '__COMPAT_LAYER' -ErrorAction SilentlyContinue

$gameBar = 'HKCU:\System\GameBar'
foreach ($val in @('GamePanelStartupTipIndex', 'ShowStartupPanel', 'UseNexusForGameBarEnabled')) {
    Remove-ItemProperty -LiteralPath $gameBar -Name $val -ErrorAction SilentlyContinue
}

# ActivatableClassId key may require TrustedInstaller on some systems
$actKey = 'HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter'
if (Test-Path -LiteralPath $actKey) {
    Set-ItemProperty -LiteralPath $actKey -Name 'ActivationType' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
}

Remove-Item -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Recurse -Force -ErrorAction SilentlyContinue

$pmgrDvr = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR'
if (-not (Test-Path -LiteralPath $pmgrDvr)) { New-Item -Path $pmgrDvr -Force | Out-Null }
New-ItemProperty -LiteralPath $pmgrDvr -Name 'value' -Value 1 -PropertyType DWord -Force | Out-Null

Remove-ItemProperty -LiteralPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' `
    -Name 'AppCaptureEnabled' -ErrorAction SilentlyContinue

& winget.exe install '9NZKPSTSNW4P' --accept-package-agreements --accept-source-agreements --silent 2>&1 | Out-Null

if ($Silent) { return }
Write-Output ''
Write-Output 'FSO and Game Bar have been enabled.'
$null = Read-Host 'Press Enter to exit'
