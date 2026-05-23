#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'SuperFetch' -State 0 -ScriptPath $PSCommandPath

Show-AtlasServiceWarning -Silent:$Silent

$diskClassKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}'
try {
    $current = (Get-ItemProperty -LiteralPath $diskClassKey -Name 'LowerFilters' -ErrorAction Stop).LowerFilters
    $updated = $current | Where-Object { $_ -ne 'rdyboost' }
    if ($updated.Count -gt 0) {
        Set-ItemProperty -LiteralPath $diskClassKey -Name 'LowerFilters' -Value $updated -Type MultiString
    } else {
        Remove-ItemProperty -LiteralPath $diskClassKey -Name 'LowerFilters' -ErrorAction SilentlyContinue
    }
} catch {
    Write-Verbose 'LowerFilters not found; skipping rdyboost removal'
}

Set-AtlasServiceStartup -Name 'rdyboost' -Start 4

$null = New-PSDrive -Name 'HKCR' -PSProvider Registry -Root 'HKEY_CLASSES_ROOT' -ErrorAction SilentlyContinue
Remove-Item -LiteralPath 'HKCR:\Drive\shellex\PropertySheetHandlers\{55B3A0BD-4D28-42fe-8CFB-FA3EDFF969B8}' `
    -Recurse -Force -ErrorAction SilentlyContinue

Set-AtlasServiceStartup -Name 'SysMain' -Start 4

if ($Silent) { return }
Write-Output ''
Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
