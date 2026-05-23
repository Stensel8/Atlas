#Requires -Version 5.1
param([switch]$Silent, [switch]$JustContext)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'Hibernation' -State 0 -ScriptPath $PSCommandPath

& powercfg.exe /h off
$key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings'
if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
Set-ItemProperty -LiteralPath $key -Name 'ShowHibernateOption' -Value 0 -Type DWord

if ($JustContext -or $Silent) { return }

Write-Output ''
Write-Output 'Hibernation has been disabled.'
Write-Output ''
$choice = Read-Host 'Would you like to reboot now to apply changes? (Y/N)'
if ($choice -match '^[Yy]') {
    Restart-Computer -Force
}
$null = Read-Host 'Press Enter to exit'
