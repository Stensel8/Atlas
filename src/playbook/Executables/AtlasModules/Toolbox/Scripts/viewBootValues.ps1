#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs @()

& bcdedit.exe /enum '{current}' | Select-Object -Skip 3 | Write-Output

Write-Output ''
$null = Read-Host 'Press Enter to exit'
