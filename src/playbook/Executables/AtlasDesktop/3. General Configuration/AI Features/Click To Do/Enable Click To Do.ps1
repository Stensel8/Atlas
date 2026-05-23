#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'ClickToDo' -State 1 -ScriptPath $PSCommandPath

Remove-ItemProperty -LiteralPath 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' `
    -Name 'DisableClickToDo' -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' `
    -Name 'DisableClickToDo' -ErrorAction SilentlyContinue

if ($Silent) { return }
Write-Output ''
Write-Output 'Click To Do has been enabled.'
$null = Read-Host 'Press Enter to exit'
