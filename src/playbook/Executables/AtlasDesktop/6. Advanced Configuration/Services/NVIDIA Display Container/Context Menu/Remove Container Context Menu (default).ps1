#Requires -Version 5.1
param([switch]$Silent, [switch]$NoAction)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force
Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Services\Atlas.Services.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'NVidiaDisplayContainerContextMenu' -State 0 -ScriptPath $PSCommandPath

Show-AtlasServiceWarning -Silent:$Silent

$null = New-PSDrive -Name 'HKCR' -PSProvider Registry -Root 'HKEY_CLASSES_ROOT' -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath 'HKCR:\DesktopBackground\Shell\NVIDIAContainer')) {
    Write-Output 'The context menu does not exist.'
    if (-not $Silent) { $null = Read-Host 'Press Enter to exit' }
    return
}

if (-not $Silent) {
    Write-Output 'Explorer will be restarted to ensure that the context menu is removed.'
    $null = Read-Host 'Press Enter to continue'
}

Remove-Item -LiteralPath 'HKCR:\DesktopBackground\Shell\NVIDIAContainer' -Recurse -Force -ErrorAction SilentlyContinue

if (-not $NoAction) {
    Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
    Start-Process 'explorer.exe'
}

if ($Silent) { return }
Write-Output ''
Write-Output 'Finished, changes have been applied.'
$null = Read-Host 'Press Enter to exit'
