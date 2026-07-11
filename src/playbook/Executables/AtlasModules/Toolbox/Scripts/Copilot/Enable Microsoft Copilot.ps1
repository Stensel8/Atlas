#Requires -Version 5.1
param([switch]$NoAction)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs @()

$edgeCheck = Join-Path $env:windir 'AtlasModules\Scripts\Test-EdgeInstall.ps1'
if (-not (Test-Path -LiteralPath $edgeCheck -PathType Leaf)) {
    throw "Atlas script '$edgeCheck' is missing."
}
Write-Output ''
& $edgeCheck -EdgeOnly
if ($LASTEXITCODE -ne 0) { return }
Write-Output ''

Write-Output 'Enabling Copilot...'

$isCopilotAvailable = (Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\Shell\Copilot' `
    -Name 'IsCopilotAvailable' -ErrorAction SilentlyContinue).IsCopilotAvailable

$appText = ''
if ($isCopilotAvailable -eq 0) {
    Write-Output 'NOTE: Copilot on the taskbar is not available, the app will be installed instead.'
    $appText = 'You can find the Copilot app in your Start Menu.'

    $wingetCheck = Join-Path $env:windir 'AtlasModules\Scripts\Test-WingetReady.ps1'
    & $wingetCheck
    if ($LASTEXITCODE -ne 0) { return }

    Write-Output 'Installing Copilot...'
    & winget install -e --id '9NHT9RB2F4HD' --uninstall-previous -h `
        --accept-source-agreements --accept-package-agreements --force --disable-interactivity | Out-Null
} else {
    $advKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    Set-ItemProperty -LiteralPath $advKey -Name 'ShowCopilotButton' -Value 1 -Type DWord -Force
}

Remove-ItemProperty -LiteralPath 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' `
    -Name 'TurnOffWindowsCopilot' -ErrorAction SilentlyContinue

if (-not $NoAction) { Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue }

Write-Output ''
Write-Output "Finished, changes are applied. $appText"
$null = Read-Host 'Press any key to exit'
