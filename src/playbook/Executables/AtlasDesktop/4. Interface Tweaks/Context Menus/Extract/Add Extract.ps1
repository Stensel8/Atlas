#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'ExtractContextMenu' -State 1 -ScriptPath $PSCommandPath

$blocked = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'
foreach ($clsid in @(
    '{b8cdcb65-b1bf-4b42-9428-1dfdb7ee92af}',
    '{BD472F60-27FA-11cf-B8B4-444553540000}',
    '{EE07CEF5-3441-4CFB-870A-4002C724783A}',
    '{D12E3394-DE4B-4777-93E9-DF0AC88F8584}'
)) {
    Remove-ItemProperty -LiteralPath $blocked -Name $clsid -ErrorAction SilentlyContinue
}

if ($Silent) { return }
Write-Output ''
Write-Output 'Extract context menu entries have been added.'
$null = Read-Host 'Press Enter to exit'
