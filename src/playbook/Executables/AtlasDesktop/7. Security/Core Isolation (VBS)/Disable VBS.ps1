#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'VbsState' -State 0 -ScriptPath $PSCommandPath

$hvciKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
if (-not (Test-Path -LiteralPath $hvciKey)) { New-Item -Path $hvciKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $hvciKey -Name 'Enabled' -Value 0 -Type DWord

$dgKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard'
if (-not (Test-Path -LiteralPath $dgKey)) { New-Item -Path $dgKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $dgKey -Name 'EnableVirtualizationBasedSecurity' -Value 0 -Type DWord

if ($Silent) { return }
Write-Output 'Changes applied successfully.'
$null = Read-Host 'Press Enter to exit'
