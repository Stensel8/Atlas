#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'WindowsSpotlight' -State 1 -ScriptPath $PSCommandPath

Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' `
    -Name 'DisableCloudOptimizedContent' -ErrorAction SilentlyContinue

$cloudCu = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
foreach ($val in @(
    'DisableWindowsSpotlightFeatures'
    'DisableWindowsSpotlightWindowsWelcomeExperience'
    'DisableWindowsSpotlightOnActionCenter'
    'DisableWindowsSpotlightOnSettings'
    'DisableThirdPartySuggestions'
)) {
    Remove-ItemProperty -LiteralPath $cloudCu -Name $val -ErrorAction SilentlyContinue
}

$cdm = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
if (-not (Test-Path -LiteralPath $cdm)) { New-Item -Path $cdm -Force | Out-Null }
New-ItemProperty -LiteralPath $cdm -Name 'ContentDeliveryAllowed'           -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $cdm -Name 'FeatureManagementEnabled'         -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $cdm -Name 'SubscribedContentEnabled'         -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $cdm -Name 'SubscribedContent-338387Enabled'  -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $cdm -Name 'RotatingLockScreenOverlayEnabled' -Value 1 -PropertyType DWord -Force | Out-Null

$iconKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel'
if (-not (Test-Path -LiteralPath $iconKey)) { New-Item -Path $iconKey -Force | Out-Null }
New-ItemProperty -LiteralPath $iconKey -Name '{2cc5ca98-6485-489a-920e-b3e88a6ccce3}' -Value 0 -PropertyType DWord -Force | Out-Null

if ($Silent) { return }
Write-Output ''
Write-Output 'Windows Spotlight has been enabled.'
$null = Read-Host 'Press Enter to exit'
