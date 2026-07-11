#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @()
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

& bcdedit.exe /enum '{current}'

Write-Output ''
$null = Read-Host 'Press Enter to exit'
