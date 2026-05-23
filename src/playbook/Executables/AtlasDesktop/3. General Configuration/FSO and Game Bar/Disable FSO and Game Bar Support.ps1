#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'FSOGameBar' -State 0 -ScriptPath $PSCommandPath

$gcStore = 'HKCU:\System\GameConfigStore'
if (-not (Test-Path -LiteralPath $gcStore)) { New-Item -Path $gcStore -Force | Out-Null }
New-ItemProperty -LiteralPath $gcStore -Name 'GameDVR_DSEBehavior'                 -Value 2 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $gcStore -Name 'GameDVR_DXGIHonorFSEWindowsCompatible' -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $gcStore -Name 'GameDVR_EFSEFeatureFlags'             -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $gcStore -Name 'GameDVR_FSEBehavior'                  -Value 2 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $gcStore -Name 'GameDVR_FSEBehaviorMode'              -Value 2 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $gcStore -Name 'GameDVR_HonorUserFSEBehaviorMode'     -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $gcStore -Name 'GameDVR_Enabled'                      -Value 0 -PropertyType DWord -Force | Out-Null

$envKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
New-ItemProperty -LiteralPath $envKey -Name '__COMPAT_LAYER' -Value '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' -PropertyType String -Force | Out-Null

$gameBar = 'HKCU:\System\GameBar'
if (-not (Test-Path -LiteralPath $gameBar)) { New-Item -Path $gameBar -Force | Out-Null }
New-ItemProperty -LiteralPath $gameBar -Name 'GamePanelStartupTipIndex'       -Value 3 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $gameBar -Name 'ShowStartupPanel'               -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $gameBar -Name 'UseNexusForGameBarEnabled'      -Value 0 -PropertyType DWord -Force | Out-Null

# ActivatableClassId key may require TrustedInstaller on some systems
$actKey = 'HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter'
if (Test-Path -LiteralPath $actKey) {
    Set-ItemProperty -LiteralPath $actKey -Name 'ActivationType' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
}

$gameDvrPol = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'
if (-not (Test-Path -LiteralPath $gameDvrPol)) { New-Item -Path $gameDvrPol -Force | Out-Null }
New-ItemProperty -LiteralPath $gameDvrPol -Name 'AllowGameDVR' -Value 0 -PropertyType DWord -Force | Out-Null

$pmgrDvr = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR'
if (-not (Test-Path -LiteralPath $pmgrDvr)) { New-Item -Path $pmgrDvr -Force | Out-Null }
New-ItemProperty -LiteralPath $pmgrDvr -Name 'value' -Value 0 -PropertyType DWord -Force | Out-Null

$gameDvrKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'
if (-not (Test-Path -LiteralPath $gameDvrKey)) { New-Item -Path $gameDvrKey -Force | Out-Null }
New-ItemProperty -LiteralPath $gameDvrKey -Name 'AppCaptureEnabled' -Value 0 -PropertyType DWord -Force | Out-Null

Get-AppxPackage -AllUsers '*xboxgamingoverlay*' | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

if ($Silent) { return }
Write-Output ''
Write-Output 'FSO and Game Bar have been disabled.'
$null = Read-Host 'Press Enter to exit'
