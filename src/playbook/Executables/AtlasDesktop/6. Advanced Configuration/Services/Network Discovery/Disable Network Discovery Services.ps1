#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'NetworkDiscovery' -State 0 -ScriptPath $PSCommandPath

Show-AtlasServiceWarning -Silent:$Silent

$navPaneScript = Join-Path $env:windir 'AtlasDesktop\3. General Configuration\File Sharing\Network Navigation Pane\Disable Network Navigation Pane (default).ps1'
if (Test-Path -LiteralPath $navPaneScript) {
    & $navPaneScript -Silent
}

Set-AtlasServiceStartup -Name 'fdPHost'  -Start 4
Set-AtlasServiceStartup -Name 'FDResPub' -Start 4
Set-AtlasServiceStartup -Name 'lmhosts'  -Start 4
Set-AtlasServiceStartup -Name 'SSDPSRV'  -Start 4

if ($Silent) { return }
Write-Output ''
Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
