#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

$indexConf = Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Set-SearchIndexConfig.ps1'
if (-not (Test-Path -LiteralPath $indexConf -PathType Leaf)) {
    if (-not $Silent) {
        Write-Output "The 'Set-SearchIndexConfig.ps1' script was not found in AtlasModules."
        $null = Read-Host 'Press Enter to exit'
    }
    exit 1
}

Set-AtlasSettingState -SettingName 'Indexing' -State 1 -ScriptPath $PSCommandPath

if (-not $Silent) { Write-Output 'Configuring minimal search indexing...' }

& $indexConf -Stop
& $indexConf -CleanPolicies
& $indexConf -Include -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
& $indexConf -Include -Path "$env:windir\AtlasDesktop"
& $indexConf -Exclude -Path "$env:SystemDrive\Users"

$gatherKey = 'HKLM:\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex'
if (-not (Test-Path -LiteralPath $gatherKey)) { New-Item -Path $gatherKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $gatherKey -Name 'RespectPowerModes' -Value 1 -Type DWord

& $indexConf -Start

$searchKey = 'HKLM:\SOFTWARE\Microsoft\Windows Search'
if (-not (Test-Path -LiteralPath $searchKey)) { New-Item -Path $searchKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $searchKey -Name 'SetupCompletedSuccessfully' -Value 0 -Type DWord

if ($Silent) { return }

Write-Output ''
Write-Output 'Minimal Search Indexing has been configured.'
$null = Read-Host 'Press Enter to exit'
