#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs @()

& bcdedit.exe /set '{current}' safeboot network | Out-Null

Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
