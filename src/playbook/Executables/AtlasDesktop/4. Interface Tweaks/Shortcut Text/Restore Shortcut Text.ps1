#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'ShortcutText' -State 1 -ScriptPath $PSCommandPath

Remove-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates' `
    -Name 'ShortcutNameTemplate' -ErrorAction SilentlyContinue

if ($Silent) { return }
Write-Output ''
Write-Output 'Shortcut text has been restored.'
$null = Read-Host 'Press Enter to exit'
