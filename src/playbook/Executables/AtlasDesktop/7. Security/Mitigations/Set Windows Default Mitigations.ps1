#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'Mitigations' -State 1 -ScriptPath $PSCommandPath

$memMgmtKey  = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
$kernelKey   = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
$sessionKey  = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
$virtKey     = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization'

Remove-ItemProperty -LiteralPath $memMgmtKey -Name 'FeatureSettingsOverride'     -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath $memMgmtKey -Name 'FeatureSettingsOverrideMask' -ErrorAction SilentlyContinue

Remove-ItemProperty -LiteralPath $kernelKey -Name 'DisableExceptionChainValidation' -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath $kernelKey -Name 'MitigationAuditOptions'          -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath $kernelKey -Name 'MitigationOptions'               -ErrorAction SilentlyContinue

& bcdedit.exe /set nx OptIn | Out-Null

if (-not (Test-Path -LiteralPath $sessionKey)) { New-Item -Path $sessionKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $sessionKey -Name 'ProtectionMode' -Value 1 -Type DWord

Remove-ItemProperty -LiteralPath $virtKey -Name 'MinVmVersionForCpuBasedMitigations' -ErrorAction SilentlyContinue

if ($Silent) { return }
Write-Output ''
Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
