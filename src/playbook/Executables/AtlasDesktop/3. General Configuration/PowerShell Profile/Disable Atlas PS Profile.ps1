#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'PSProfile' -State 0 -ScriptPath $PSCommandPath

$ps7Profile = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
$backup     = "$ps7Profile.atlasbak"

if (Test-Path -LiteralPath $backup) {
    Copy-Item -LiteralPath $backup -Destination $ps7Profile -Force
    Remove-Item -LiteralPath $backup -Force
    Write-Output 'Previous profile restored.'
} elseif (Test-Path -LiteralPath $ps7Profile) {
    Remove-Item -LiteralPath $ps7Profile -Force
    Write-Output 'Atlas profile removed (no backup to restore).'
}

# Remove OMP theme from AppData
$ompDest = Join-Path $env:APPDATA 'AtlasOS\atlas.omp.json'
if (Test-Path -LiteralPath $ompDest) { Remove-Item -LiteralPath $ompDest -Force }

if ($Silent) { return }

Write-Output ''
Write-Output 'Atlas PowerShell profile disabled.'
Write-Output '  Restart PowerShell 7 to apply.'
$null = Read-Host 'Press Enter to exit'
