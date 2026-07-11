#Requires -Version 5.1
param([switch]$NoAction)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs @()

Write-Output 'Disabling and uninstalling Copilot...'

Get-AppxPackage -AllUsers 'Microsoft.Copilot*' -ErrorAction SilentlyContinue |
    Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

$advKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-ItemProperty -LiteralPath $advKey -Name 'ShowCopilotButton' -Value 0 -Type DWord -Force

$polKey = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot'
if (-not (Test-Path -LiteralPath $polKey)) { New-Item -Path $polKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $polKey -Name 'TurnOffWindowsCopilot' -Value 1 -Type DWord -Force

if (-not $NoAction) { Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue }

Write-Output ''
Write-Output 'Finished, changes are applied.'
$null = Read-Host 'Press any key to exit'
