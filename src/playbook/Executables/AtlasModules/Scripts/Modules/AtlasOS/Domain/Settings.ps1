#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
# AtlasOS domain functions: Settings

function Set-AtlasSettingState {
    param(
        [Parameter(Mandatory)][string]$SettingName,
        [Parameter(Mandatory)][int]$State,
        [Parameter(Mandatory)][string]$ScriptPath
    )

    if ($env:ATLAS_USER_CONTEXT -eq '1') { return }

    $root = Join-Path -Path 'HKLM:\SOFTWARE\AtlasOS\Services' -ChildPath $SettingName
    if (-not (Test-Path -LiteralPath $root)) {
        New-Item -Path $root -Force | Out-Null
    }
    New-ItemProperty -LiteralPath $root -Name 'state' -Value $State       -PropertyType DWord  -Force | Out-Null
    New-ItemProperty -LiteralPath $root -Name 'path'  -Value $ScriptPath  -PropertyType String -Force | Out-Null
}

function Invoke-AtlasSettingsPage {
    param(
        [Parameter(Mandatory)][ValidateSet('hide', 'unhide')][string]$Operation,
        [Parameter(Mandatory)][string]$Page
    )

    $scriptPath = Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Helpers\Set-SettingsPageVisibility.ps1'
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) { return }
    & $scriptPath -Operation $Operation -Page $Page -Silent
}
