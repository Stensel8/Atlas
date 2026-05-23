#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'GiveAccessToMenu' -State 0 -ScriptPath $PSCommandPath

$null = New-PSDrive -Name 'HKCR' -PSProvider Registry -Root 'HKEY_CLASSES_ROOT' -ErrorAction SilentlyContinue

foreach ($path in @(
    'HKCR:\*\shellex\ContextMenuHandlers\Sharing'
    'HKCR:\Directory\Background\shellex\ContextMenuHandlers\Sharing'
    'HKCR:\Directory\shellex\ContextMenuHandlers\Sharing'
    'HKCR:\Drive\shellex\ContextMenuHandlers\Sharing'
    'HKCR:\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing'
    'HKCR:\UserLibraryFolder\shellex\ContextMenuHandlers\Sharing'
)) {
    Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
}

if ($Silent) { return }
Write-Output ''
Write-Output "'Give Access To' menu is now disabled."
$null = Read-Host 'Press Enter to exit'
