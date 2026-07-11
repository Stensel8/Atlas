#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'CpuIdleContextMenu' -State 1 -ScriptPath $PSCommandPath

$null = New-PSDrive -Name 'HKCR' -PSProvider Registry -Root 'HKEY_CLASSES_ROOT' -ErrorAction SilentlyContinue

$rootKey = 'HKCR:\DesktopBackground\Shell\CpuIdle'
if (-not (Test-Path -LiteralPath $rootKey)) { New-Item -Path $rootKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $rootKey -Name 'Icon'        -Value 'powercpl.dll'
Set-ItemProperty -LiteralPath $rootKey -Name 'SubCommands' -Value ''
Set-ItemProperty -LiteralPath $rootKey -Name 'Position'    -Value 'Bottom'
Set-ItemProperty -LiteralPath $rootKey -Name 'MUIVerb'     -Value 'CPU Idle'

$disableIdlePs1 = Join-Path $env:windir 'AtlasDesktop\3. General Configuration\CPU Idle\Disable Idle.ps1'
$enableIdlePs1  = Join-Path $env:windir 'AtlasDesktop\3. General Configuration\CPU Idle\Enable Idle (default).ps1'

$disableKey = "$rootKey\Shell\Disable Idle"
$enableKey  = "$rootKey\Shell\Enable Idle"

foreach ($k in @($disableKey, "$disableKey\command", $enableKey, "$enableKey\command")) {
    if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
}

Set-ItemProperty -LiteralPath $disableKey            -Name 'MUIVerb' -Value 'Disable Idle'
Set-ItemProperty -LiteralPath $disableKey            -Name 'Icon'    -Value 'powercpl.dll'
Set-ItemProperty -LiteralPath "$disableKey\command"  -Name '(default)' `
    -Value "powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File `"$disableIdlePs1`" -Silent"

Set-ItemProperty -LiteralPath $enableKey             -Name 'MUIVerb' -Value 'Enable Idle'
Set-ItemProperty -LiteralPath "$enableKey\command"   -Name '(default)' `
    -Value "powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File `"$enableIdlePs1`" -Silent"

if ($Silent) { return }
Write-Output ''
Write-Output 'CPU Idle desktop context menu has been added.'
$null = Read-Host 'Press Enter to exit'
