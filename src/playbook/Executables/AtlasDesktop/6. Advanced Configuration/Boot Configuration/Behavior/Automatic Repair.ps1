#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @()
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

$stateKey = 'HKLM:\SOFTWARE\AtlasOS\Services\AutomaticRepair'
if (-not (Test-Path -LiteralPath $stateKey)) { New-Item -Path $stateKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $stateKey -Name 'path' -Value $PSCommandPath -Type String

Write-Output 'Automatic repair mostly does not do anything to help, and could cause issues.'
Write-Output ''

$choice = $Host.UI.PromptForChoice(
    '',
    'What would you like to do?',
    @('1. Disable automatic repair', '2. Enable automatic repair (default)'),
    1
)

if ($choice -eq 0) {
    & bcdedit.exe /set '{current}' bootstatuspolicy IgnoreAllFailures | Out-Null
    Set-ItemProperty -LiteralPath $stateKey -Name 'state' -Value 0 -Type DWord
} else {
    & bcdedit.exe /set '{current}' bootstatuspolicy DisplayAllFailures | Out-Null
    Set-ItemProperty -LiteralPath $stateKey -Name 'state' -Value 1 -Type DWord
}

Write-Output ''
Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
