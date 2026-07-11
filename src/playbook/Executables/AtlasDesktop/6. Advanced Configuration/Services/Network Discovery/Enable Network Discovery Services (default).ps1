#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force
Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Services\Atlas.Services.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'NetworkDiscovery' -State 1 -ScriptPath $PSCommandPath

Show-AtlasServiceWarning -Silent:$Silent

$lanmanScript = Join-Path $env:windir 'AtlasDesktop\6. Advanced Configuration\Services\Lanman Workstation (SMB)\Enable Lanman Workstation (default).ps1'
if (Test-Path -LiteralPath $lanmanScript) {
    & $lanmanScript -Silent
}

Set-AtlasServiceStartup -Name 'eventlog' -Start 2
Set-AtlasServiceStartup -Name 'fdPHost'  -Start 3
Set-AtlasServiceStartup -Name 'FDResPub' -Start 3
Set-AtlasServiceStartup -Name 'lmhosts'  -Start 3
Set-AtlasServiceStartup -Name 'netman'   -Start 3

$build = [System.Environment]::OSVersion.Version.Build
$nlaSvcStart = if ($build -ge 22000) { 3 } else { 2 }
Set-AtlasServiceStartup -Name 'NlaSvc'   -Start $nlaSvcStart

Set-AtlasServiceStartup -Name 'SSDPSRV'  -Start 3

if ($Silent) { return }
Write-Output ''
Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
