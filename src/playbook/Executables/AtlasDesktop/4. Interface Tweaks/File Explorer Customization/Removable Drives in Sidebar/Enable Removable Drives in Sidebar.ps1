#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'RemovableDrivesInSidebar' -State 1 -ScriptPath $PSCommandPath

$clsid  = '{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}'
$key1   = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\$clsid"
$key2   = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\$clsid\$clsid"

foreach ($k in @($key1, $key2)) {
    if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
    New-ItemProperty -LiteralPath $k -Name '(default)' -Value 'Removable Drives' -PropertyType String -Force | Out-Null
}

if ($Silent) { return }
Write-Output ''
Write-Output 'Removable drives have been shown in the sidebar.'
$null = Read-Host 'Press Enter to exit'
