#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'Animation' -State 0 -ScriptPath $PSCommandPath

$desktop    = 'HKCU:\Control Panel\Desktop'
$winMetrics = 'HKCU:\Control Panel\Desktop\WindowMetrics'
$adv        = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$vfx        = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
$dwm        = 'HKCU:\SOFTWARE\Microsoft\Windows\DWM'

foreach ($key in @($desktop, $winMetrics, $adv, $vfx, $dwm)) {
    if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
}

Set-ItemProperty -LiteralPath $desktop    -Name 'FontSmoothing'          -Value '2'
Set-ItemProperty -LiteralPath $desktop    -Name 'DragFullWindows'        -Value '1'
Set-ItemProperty -LiteralPath $winMetrics -Name 'MinAnimate'             -Value '0'
New-ItemProperty -LiteralPath $desktop -Name 'UserPreferencesMask' `
    -Value ([byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00)) -PropertyType Binary -Force | Out-Null
New-ItemProperty -LiteralPath $adv -Name 'ListviewAlphaSelect' -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $adv -Name 'IconsOnly'           -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $adv -Name 'TaskbarAnimations'   -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $adv -Name 'ListviewShadow'      -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $vfx -Name 'VisualFXSetting'     -Value 3 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $dwm -Name 'EnableAeroPeek'            -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $dwm -Name 'AlwaysHibernateThumbnails' -Value 0 -PropertyType DWord -Force | Out-Null

if ($Silent) { return }
Write-Output ''
$choice = $Host.UI.PromptForChoice('', 'Log out now to apply visual effects changes?', @('&Yes', '&No'), 1)
if ($choice -eq 0) { logoff.exe }
