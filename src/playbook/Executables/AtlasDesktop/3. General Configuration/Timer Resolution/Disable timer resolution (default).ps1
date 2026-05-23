#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Show-AtlasServiceWarning -Silent:$Silent

Remove-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' `
    -Name 'GlobalTimerResolutionRequests' -ErrorAction SilentlyContinue

Stop-Process -Name 'SetTimerResolution' -Force -ErrorAction SilentlyContinue
& schtasks.exe /delete /tn 'Force Timer Resolution' /f 2>$null | Out-Null

if ($Silent) { return }
Write-Output ''
Write-Output 'Timer resolution has been reset to default.'
$null = Read-Host 'Press Enter to exit'
