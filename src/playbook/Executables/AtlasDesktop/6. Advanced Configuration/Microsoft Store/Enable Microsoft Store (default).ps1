#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'MicrosoftStore' -State 1 -ScriptPath $PSCommandPath

Get-AppxPackage -AllUsers 'Microsoft.WindowsStore' -ErrorAction SilentlyContinue | ForEach-Object {
    Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation 'AppXManifest.xml') -ErrorAction SilentlyContinue
}

if ($Silent) { return }
Write-Output ''
Write-Output 'Microsoft Store has been reinstalled/enabled.'
$null = Read-Host 'Press Enter to exit'
