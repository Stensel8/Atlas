#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'RemovableDrivesInSidebar' -State 0 -ScriptPath $PSCommandPath

$clsid = '{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}'
Remove-Item -LiteralPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\$clsid" `
    -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\$clsid\$clsid" `
    -Recurse -Force -ErrorAction SilentlyContinue

if ($Silent) { return }
Write-Output ''
Write-Output 'Removable drives have been hidden from the sidebar.'
$null = Read-Host 'Press Enter to exit'
