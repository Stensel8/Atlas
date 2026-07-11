#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'GiveAccessToMenu' -State 1 -ScriptPath $PSCommandPath

$null = New-PSDrive -Name 'HKCR' -PSProvider Registry -Root 'HKEY_CLASSES_ROOT' -ErrorAction SilentlyContinue

$clsid = '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}'
foreach ($path in @(
    'HKCR:\*\shellex\ContextMenuHandlers\Sharing'
    'HKCR:\Directory\Background\shellex\ContextMenuHandlers\Sharing'
    'HKCR:\Directory\shellex\ContextMenuHandlers\Sharing'
    'HKCR:\Drive\shellex\ContextMenuHandlers\Sharing'
    'HKCR:\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing'
    'HKCR:\UserLibraryFolder\shellex\ContextMenuHandlers\Sharing'
)) {
    if (-not (Test-Path -LiteralPath $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -LiteralPath $path -Name '(default)' -Value $clsid
}

if ($Silent) { return }
Write-Output ''
Write-Output "'Give Access To' menu is now enabled."
$null = Read-Host 'Press Enter to exit'
