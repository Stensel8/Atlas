#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

$indexConf = Join-Path $env:windir 'AtlasModules\Scripts\Set-SearchIndexConfig.ps1'
if (-not (Test-Path -LiteralPath $indexConf -PathType Leaf)) {
    if (-not $Silent) {
        Write-Output "The 'Set-SearchIndexConfig.ps1' script was not found in AtlasModules."
        $null = Read-Host 'Press Enter to exit'
    }
    exit 1
}

Set-AtlasSettingState -SettingName 'Indexing' -State 0 -ScriptPath $PSCommandPath

if (-not $Silent) { Write-Output 'Disabling search indexing...' }
& $indexConf -Stop

if ($Silent) { return }
Write-Output ''
Write-Output 'Search Indexing has been disabled.'
$null = Read-Host 'Press Enter to exit'
