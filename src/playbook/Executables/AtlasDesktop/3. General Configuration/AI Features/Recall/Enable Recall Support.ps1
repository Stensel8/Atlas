#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'Recall' -State 1 -ScriptPath $PSCommandPath

$aiKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
Remove-ItemProperty -LiteralPath $aiKey -Name 'DisableAIDataAnalysis' -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath $aiKey -Name 'AllowRecallEnablement' -ErrorAction SilentlyContinue

if ($Silent) { return }
Write-Output ''
Write-Output 'Recall has been enabled.'
$null = Read-Host 'Press Enter to exit'
