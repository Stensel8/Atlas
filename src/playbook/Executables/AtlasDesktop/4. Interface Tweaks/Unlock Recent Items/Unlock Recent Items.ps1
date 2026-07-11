#Requires -Version 5.1
param([switch]$Silent, [switch]$NoAction)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'RecentItems' -State 1 -ScriptPath $PSCommandPath

Write-Output 'Unlocking recent items...'

$polExp  = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
$polExpW = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
$polSys  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
$polSysW = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
$adv     = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

Remove-ItemProperty -LiteralPath $polExp  -Name 'NoInstrumentation'          -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath $polExp  -Name 'ClearRecentDocsOnExit'      -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath $polExp  -Name 'NoRecentDocsHistory'        -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath $polExpW -Name 'NoRemoteDestinations'       -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath $polSys  -Name 'NoStartMenuMFUprogramsList' -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath $polSys  -Name 'NoRecentDocsHistory'        -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath $polSysW -Name 'ShowOrHideMostUsedApps'     -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath $polSysW -Name 'HideRecentlyAddedApps'      -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath $adv)) { New-Item -Path $adv -Force | Out-Null }
New-ItemProperty -LiteralPath $adv -Name 'Start_TrackProgs' -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $adv -Name 'Start_TrackDocs'  -Value 1 -PropertyType DWord -Force | Out-Null

Invoke-AtlasSettingsPage -Operation unhide -Page 'privacy-general'

if (-not $NoAction) {
    Stop-Process -Name 'explorer'    -Force -ErrorAction SilentlyContinue
    Start-Process 'explorer.exe'
    Stop-Process -Name 'SettingsApp' -Force -ErrorAction SilentlyContinue
}

if ($Silent) { return }
Write-Output ''
Write-Output 'Recent items are now unlocked. Configure them in File Explorer options and Start/privacy settings.'
$null = Read-Host 'Press Enter to exit'
