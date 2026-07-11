#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force
Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Services\Atlas.Services.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'SuperFetch' -State 1 -ScriptPath $PSCommandPath

Show-AtlasServiceWarning -Silent:$Silent

$diskClassKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}'
try {
    $current = (Get-ItemProperty -LiteralPath $diskClassKey -Name 'LowerFilters' -ErrorAction Stop).LowerFilters
    if ($current -notcontains 'rdyboost') {
        Set-ItemProperty -LiteralPath $diskClassKey -Name 'LowerFilters' -Value ($current + 'rdyboost') -Type MultiString
    }
} catch {
    Set-ItemProperty -LiteralPath $diskClassKey -Name 'LowerFilters' -Value @('rdyboost') -Type MultiString
}

Set-AtlasServiceStartup -Name 'rdyboost' -Start 0

$null = New-PSDrive -Name 'HKCR' -PSProvider Registry -Root 'HKEY_CLASSES_ROOT' -ErrorAction SilentlyContinue
$readyBoostKey = 'HKCR:\Drive\shellex\PropertySheetHandlers\{55B3A0BD-4D28-42fe-8CFB-FA3EDFF969B8}'
if (-not (Test-Path -LiteralPath $readyBoostKey)) { New-Item -Path $readyBoostKey -Force | Out-Null }

Set-AtlasServiceStartup -Name 'SysMain' -Start 2

if ($Silent) { return }
Write-Output ''
Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
