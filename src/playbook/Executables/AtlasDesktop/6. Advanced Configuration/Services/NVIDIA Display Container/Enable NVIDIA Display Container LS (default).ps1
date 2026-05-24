#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'NVidiaDisplayContainer' -State 1 -ScriptPath $PSCommandPath

Show-AtlasServiceWarning -Silent:$Silent

if (-not (Get-Service -Name 'NVDisplay.ContainerLocalSystem' -ErrorAction SilentlyContinue)) {
    if (-not $Silent) {
        Write-Output 'The NVIDIA Display Container LS service does not exist.'
        Write-Output 'You may not have NVIDIA drivers installed.'
        $null = Read-Host 'Press Enter to exit'
    }
    return
}

Set-AtlasServiceStartup -Name 'NVDisplay.ContainerLocalSystem' -Start 2
Start-Service -Name 'NVDisplay.ContainerLocalSystem' -ErrorAction SilentlyContinue

if ($Silent) { return }
Write-Output ''
Write-Output 'Finished, changes have been applied.'
$null = Read-Host 'Press Enter to exit'
