#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @()
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

$stateKey = 'HKLM:\SOFTWARE\AtlasOS\Services\AdvancedBootOptions'
if (-not (Test-Path -LiteralPath $stateKey)) { New-Item -Path $stateKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $stateKey -Name 'path' -Value $PSCommandPath -Type String

Write-Output 'This tweak enables the advanced boot options to be shown on each boot.'
Write-Output ''

$choice = $Host.UI.PromptForChoice(
    '',
    'What would you like to do?',
    @('1. Disable always going to the advanced boot options (default)', '2. Enable always going to the advanced boot options'),
    0
)

if ($choice -eq 0) {
    & bcdedit.exe /deletevalue '{globalsettings}' advancedoptions 2>$null | Out-Null
    Set-ItemProperty -LiteralPath $stateKey -Name 'state' -Value 0 -Type DWord
} else {
    & bcdedit.exe /set '{globalsettings}' advancedoptions true | Out-Null
    Set-ItemProperty -LiteralPath $stateKey -Name 'state' -Value 1 -Type DWord
}

Write-Output ''
Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
