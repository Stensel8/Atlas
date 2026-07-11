#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'NetworkNavigationPane' -State 1 -ScriptPath $PSCommandPath

Remove-ItemProperty -LiteralPath 'HKCU:\SOFTWARE\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}' `
    -Name 'System.IsPinnedToNameSpaceTree' -ErrorAction SilentlyContinue

if ($Silent) { return }
Write-Output ''
Write-Output 'Network Navigation Pane is now enabled.'
$null = Read-Host 'Press Enter to exit'
