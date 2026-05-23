#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'Sleep' -State 1 -ScriptPath $PSCommandPath

$sleepSubgroup = '238c9fa8-0aad-41ed-83f4-97be242c8f20'
& powercfg.exe /setacvalueindex scheme_current $sleepSubgroup '25dfa149-5dd1-4736-b5ab-e8a37b5b8187' 1
& powercfg.exe /setacvalueindex scheme_current $sleepSubgroup 'abfc2519-3608-4c2a-94ea-171b0ed546ab' 1
& powercfg.exe /setacvalueindex scheme_current $sleepSubgroup '94ac6d29-73ce-41a6-809f-6363ba21b47e' 1
& powercfg.exe /setacvalueindex scheme_current $sleepSubgroup '7bc4a2f9-d8fc-4469-b07b-33eb785aaca0' 120
& powercfg.exe /setacvalueindex scheme_current $sleepSubgroup 'bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d' 1
& powercfg.exe /setacvalueindex scheme_current '2e601130-5351-4d9d-8e04-252966bad054' 'd502f7ee-1dc7-4efd-a55d-f04b6f5c0545' 1
& powercfg.exe /setactive scheme_current

if ($Silent) { return }

$enableHibScript  = Join-Path $PSScriptRoot '..\Hibernation\Enable Hibernation.ps1'
$disableHibScript = Join-Path $PSScriptRoot '..\Hibernation\Disable Hibernation (default).ps1'
$choice = $Host.UI.PromptForChoice('', 'Would you like to enable hibernation?', @('&Yes', '&No'), 1)
if ($choice -eq 0 -and (Test-Path -LiteralPath $enableHibScript)) {
    & $enableHibScript -Silent
} elseif ($choice -ne 0 -and (Test-Path -LiteralPath $disableHibScript)) {
    & $disableHibScript -Silent
}

Write-Output ''
Write-Output 'Sleep has been enabled.'
$null = Read-Host 'Press Enter to exit'
