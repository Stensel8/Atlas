#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs @()

& bcdedit.exe /deletevalue '{current}' safeboot            2>&1 | Out-Null
& bcdedit.exe /deletevalue '{current}' safebootalternateshell 2>&1 | Out-Null

Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
