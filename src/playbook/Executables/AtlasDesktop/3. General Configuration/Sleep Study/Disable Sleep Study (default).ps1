#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'SleepStudy' -State 0 -ScriptPath $PSCommandPath

foreach ($channel in @(
    'Microsoft-Windows-SleepStudy/Diagnostic'
    'Microsoft-Windows-Kernel-Processor-Power/Diagnostic'
    'Microsoft-Windows-UserModePowerService/Diagnostic'
)) {
    & wevtutil.exe sl $channel /q:false
}

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Power Efficiency Diagnostics\' -TaskName 'AnalyzeSystem' -ErrorAction SilentlyContinue | Out-Null

if ($Silent) { return }
Write-Output ''
Write-Output 'Sleep Study has been disabled.'
$null = Read-Host 'Press Enter to exit'
