#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'RunWithPriority' -State 1 -ScriptPath $PSCommandPath

$null = New-PSDrive -Name 'HKCR' -PSProvider Registry -Root 'HKEY_CLASSES_ROOT' -ErrorAction SilentlyContinue

$entries = @(
    @{ Key = '001flyout'; Label = 'Realtime';      Cmd = 'powershell start -file ''cmd'' -args ''/c start """Realtime App""" /Realtime """%1"""'' -verb runas' }
    @{ Key = '002flyout'; Label = 'High';           Cmd = 'cmd /c start "" /High "%1"' }
    @{ Key = '003flyout'; Label = 'Above normal';   Cmd = 'cmd /c start "" /AboveNormal "%1"' }
    @{ Key = '004flyout'; Label = 'Normal';         Cmd = 'cmd /c start "" /Normal "%1"' }
    @{ Key = '005flyout'; Label = 'Below normal';   Cmd = 'cmd /c start "" /BelowNormal "%1"' }
    @{ Key = '006flyout'; Label = 'Low';            Cmd = 'cmd /c start "" /Low "%1"' }
)

foreach ($entry in $entries) {
    $flyoutKey = "HKCR:\exefile\Shell\Priority\shell\$($entry.Key)"
    $cmdKey    = "$flyoutKey\command"
    if (-not (Test-Path -LiteralPath $flyoutKey)) { New-Item -Path $flyoutKey -Force | Out-Null }
    if (-not (Test-Path -LiteralPath $cmdKey))    { New-Item -Path $cmdKey    -Force | Out-Null }
    Set-ItemProperty -LiteralPath $flyoutKey -Name '(default)' -Value $entry.Label
    Set-ItemProperty -LiteralPath $cmdKey    -Name '(default)' -Value $entry.Cmd
}

if ($Silent) { return }
Write-Output ''
Write-Output 'Run With Priority has been added to the context menu.'
$null = Read-Host 'Press Enter to exit'
