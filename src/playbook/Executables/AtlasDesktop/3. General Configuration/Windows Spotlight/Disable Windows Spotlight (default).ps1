#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'WindowsSpotlight' -State 0 -ScriptPath $PSCommandPath

$cloudLm = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
if (-not (Test-Path -LiteralPath $cloudLm)) { New-Item -Path $cloudLm -Force | Out-Null }
New-ItemProperty -LiteralPath $cloudLm -Name 'DisableCloudOptimizedContent' -Value 1 -PropertyType DWord -Force | Out-Null

$cloudCu = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
if (-not (Test-Path -LiteralPath $cloudCu)) { New-Item -Path $cloudCu -Force | Out-Null }
New-ItemProperty -LiteralPath $cloudCu -Name 'DisableWindowsSpotlightFeatures'              -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $cloudCu -Name 'DisableWindowsSpotlightWindowsWelcomeExperience' -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $cloudCu -Name 'DisableWindowsSpotlightOnActionCenter'        -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $cloudCu -Name 'DisableWindowsSpotlightOnSettings'            -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $cloudCu -Name 'DisableThirdPartySuggestions'                 -Value 1 -PropertyType DWord -Force | Out-Null

$cdm = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
if (-not (Test-Path -LiteralPath $cdm)) { New-Item -Path $cdm -Force | Out-Null }
New-ItemProperty -LiteralPath $cdm -Name 'ContentDeliveryAllowed'            -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $cdm -Name 'FeatureManagementEnabled'          -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $cdm -Name 'SubscribedContentEnabled'          -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $cdm -Name 'SubscribedContent-338387Enabled'   -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $cdm -Name 'RotatingLockScreenOverlayEnabled'  -Value 0 -PropertyType DWord -Force | Out-Null

$iconKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel'
if (-not (Test-Path -LiteralPath $iconKey)) { New-Item -Path $iconKey -Force | Out-Null }
New-ItemProperty -LiteralPath $iconKey -Name '{2cc5ca98-6485-489a-920e-b3e88a6ccce3}' -Value 1 -PropertyType DWord -Force | Out-Null

if ($Silent) { return }
Write-Output ''
Write-Output 'Windows Spotlight has been disabled.'
$null = Read-Host 'Press Enter to exit'
