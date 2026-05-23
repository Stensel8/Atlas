#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @()
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

$folder = Join-Path $env:windir 'Temp'

Write-Output 'This script will fix errors 2502 and 2503 with Windows installers by resetting the Windows TEMP folder permissions.'
Write-Output 'This issue is not related to Atlas.'
Write-Output ''
$null = Read-Host 'Press Enter to continue'
Write-Output ''

Write-Output 'Taking ownership of TEMP folder...'
& takeown.exe /f $folder /r /d y | Out-Null

Write-Output 'Clearing all current permissions...'
& icacls.exe $folder /inheritance:e | Out-Null
& icacls.exe $folder /reset         | Out-Null
& icacls.exe $folder /inheritance:r | Out-Null

Write-Output 'Setting default permissions...'
& icacls.exe $env:windir\Temp `
    '/grant:r' '*S-1-5-32-545:(OI)(CI)F' `
    '/grant:r' '*S-1-5-18:(OI)(CI)F' `
    '/grant:r' '*S-1-3-0:(OI)(CI)F' `
    '/grant:r' '*S-1-5-11:(OI)(CI)(X,AD,WD)' `
    /t | Out-Null

Write-Output 'Clearing Windows temporary files...'
Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

Write-Output ''
Write-Output 'Completed.'
$null = Read-Host 'Press Enter to exit'
