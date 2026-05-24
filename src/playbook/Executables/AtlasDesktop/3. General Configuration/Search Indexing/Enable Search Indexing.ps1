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

Set-AtlasSettingState -SettingName 'Indexing' -State 2 -ScriptPath $PSCommandPath

if (-not $Silent) { Write-Output 'Enabling full search indexing...' }

& $indexConf -Stop
& $indexConf -CleanPolicies
& $indexConf -Include -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
& $indexConf -Include -Path "$env:windir\AtlasDesktop"
& $indexConf -Include -Path "$env:SystemDrive\Users"

foreach ($user in (Get-ChildItem "$env:SystemDrive\Users" -Directory -ErrorAction SilentlyContinue)) {
    foreach ($exclude in @('AppData', 'MicrosoftEdgeBackups')) {
        $path = Join-Path $user.FullName $exclude
        if (Test-Path -LiteralPath $path) {
            & $indexConf -Exclude -Path $path
        }
    }
}

& $indexConf -Start

$searchKey = 'HKLM:\SOFTWARE\Microsoft\Windows Search'
if (-not (Test-Path -LiteralPath $searchKey)) { New-Item -Path $searchKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $searchKey -Name 'SetupCompletedSuccessfully' -Value 0 -Type DWord

$gatherKey = 'HKLM:\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex'
if (-not (Test-Path -LiteralPath $gatherKey)) { New-Item -Path $gatherKey -Force | Out-Null }

if ($Silent) {
    Set-ItemProperty -LiteralPath $gatherKey -Name 'RespectPowerModes' -Value 0 -Type DWord
    return
}

$choice = $Host.UI.PromptForChoice(
    '',
    'Would you like indexing to disable itself when on battery or gaming?',
    @('&Yes', '&No'),
    1
)
Set-ItemProperty -LiteralPath $gatherKey -Name 'RespectPowerModes' -Value ([int]($choice -eq 0)) -Type DWord

Write-Output ''
Write-Output 'Full Search Indexing has been enabled.'
$null = Read-Host 'Press Enter to exit'
