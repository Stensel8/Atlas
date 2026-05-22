#Requires -Version 5.1
param([switch]$Silent, [switch]$JustContext)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'ExtractContextMenu' -State 0 -ScriptPath $PSCommandPath

$blockedKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'
if (-not (Test-Path -LiteralPath $blockedKey)) { New-Item -Path $blockedKey -Force | Out-Null }
foreach ($clsid in @(
    '{b8cdcb65-b1bf-4b42-9428-1dfdb7ee92af}'
    '{BD472F60-27FA-11cf-B8B4-444553540000}'
    '{EE07CEF5-3441-4CFB-870A-4002C724783A}'
    '{D12E3394-DE4B-4777-93E9-DF0AC88F8584}'
)) {
    New-ItemProperty -LiteralPath $blockedKey -Name $clsid -Value '' -PropertyType String -Force | Out-Null
}

if ($JustContext -or $Silent) { return }

Write-Output 'Changes applied successfully.'
$null = Read-Host 'Press Enter to exit'
