#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'NVidiaDisplayContainer' -State 0 -ScriptPath $PSCommandPath

Show-AtlasServiceWarning -Silent:$Silent

if (-not (Get-Service -Name 'NVDisplay.ContainerLocalSystem' -ErrorAction SilentlyContinue)) {
    Write-Output 'The NVIDIA Display Container LS service does not exist.'
    Write-Output 'You may not have NVIDIA drivers installed.'
    if (-not $Silent) { $null = Read-Host 'Press Enter to exit' }
    exit 1
}

if (-not $Silent) {
    Write-Output "Disabling the 'NVIDIA Display Container LS' service will stop the NVIDIA Control Panel from working."
    Write-Output 'It will most likely break other NVIDIA driver features as well.'
    Write-Output 'These scripts are aimed at users that have a stripped driver, and people that barely touch the NVIDIA Control Panel.'
    Write-Output ''
    Write-Output 'You can enable the NVIDIA Control Panel and the service again by running the enable script.'
    Write-Output 'Additionally, you can add a context menu to the desktop with another script in the Atlas folder.'
    Write-Output ''
    $null = Read-Host 'Press Enter to continue'
}

Set-AtlasServiceStartup -Name 'NVDisplay.ContainerLocalSystem' -Start 4
Stop-Service -Name 'NVDisplay.ContainerLocalSystem' -Force -ErrorAction SilentlyContinue

if ($Silent) { return }
Write-Output ''
Write-Output 'Finished, changes have been applied.'
$null = Read-Host 'Press Enter to exit'
