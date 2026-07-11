#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force
Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Services\Atlas.Services.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'NVidiaDisplayContainerContextMenu' -State 1 -ScriptPath $PSCommandPath

Show-AtlasServiceWarning -Silent:$Silent

if (-not (Get-Service -Name 'NVDisplay.ContainerLocalSystem' -ErrorAction SilentlyContinue)) {
    Write-Output 'The NVIDIA Display Container LS service does not exist.'
    Write-Output 'You may not have NVIDIA drivers installed.'
    if (-not $Silent) { $null = Read-Host 'Press Enter to exit' }
    exit 1
}

if (-not $Silent) {
    Write-Output 'Explorer will be restarted to ensure that the context menu works.'
    $null = Read-Host 'Press Enter to continue'
}

$null = New-PSDrive -Name 'HKCR' -PSProvider Registry -Root 'HKEY_CLASSES_ROOT' -ErrorAction SilentlyContinue

$rootKey = 'HKCR:\DesktopBackground\Shell\NVIDIAContainer'
if (-not (Test-Path -LiteralPath $rootKey)) { New-Item -Path $rootKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $rootKey -Name 'Icon'        -Value 'NVIDIA.ico,0'
Set-ItemProperty -LiteralPath $rootKey -Name 'MUIVerb'     -Value 'NVIDIA Container'
Set-ItemProperty -LiteralPath $rootKey -Name 'Position'    -Value 'Bottom'
Set-ItemProperty -LiteralPath $rootKey -Name 'SubCommands' -Value ''

$enablePs1  = Join-Path $env:windir 'AtlasDesktop\6. Advanced Configuration\Services\NVIDIA Display Container\Enable NVIDIA Display Container LS (default).ps1'
$disablePs1 = Join-Path $env:windir 'AtlasDesktop\6. Advanced Configuration\Services\NVIDIA Display Container\Disable NVIDIA Display Container LS.ps1'

foreach ($item in @(
    @{ Key = "$rootKey\shell\NVIDIAContainer001"; Label = 'Enable NVIDIA Display Container LS';  Script = $enablePs1  }
    @{ Key = "$rootKey\shell\NVIDIAContainer002"; Label = 'Disable NVIDIA Display Container LS'; Script = $disablePs1 }
)) {
    $k = $item.Key
    $c = "$k\command"
    foreach ($p in @($k, $c)) {
        if (-not (Test-Path -LiteralPath $p)) { New-Item -Path $p -Force | Out-Null }
    }
    Set-ItemProperty -LiteralPath $k -Name 'HasLUAShield' -Value ''
    Set-ItemProperty -LiteralPath $k -Name 'MUIVerb'      -Value $item.Label
    Set-ItemProperty -LiteralPath $c -Name '(default)'    `
        -Value "powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File `"$($item.Script)`" -Silent"
}

if (-not $Silent) {
    Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
    Start-Process 'explorer.exe'
}

if ($Silent) { return }
Write-Output ''
Write-Output 'Finished, changes have been applied.'
$null = Read-Host 'Press Enter to exit'
